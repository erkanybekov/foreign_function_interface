#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${HOME:-}" && -f "${HOME}/.cargo/env" ]]; then
  # Xcode build phases run with a narrow PATH and often miss rustup.
  # shellcheck source=/dev/null
  source "${HOME}/.cargo/env"
fi

if [[ -n "${HOME:-}" ]]; then
  export PATH="${HOME}/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:${PATH:-}"
else
  export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH:-}"
fi

CARGO_BIN="${CARGO:-}"
if [[ -z "${CARGO_BIN}" ]]; then
  CARGO_BIN="$(command -v cargo || true)"
fi

if [[ -z "${CARGO_BIN}" ]]; then
  echo "error: cargo is required to build the bank_core_ffi Rust backend." >&2
  echo "Install Rust, then rebuild the Flutter target:" >&2
  echo "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh" >&2
  echo "  rustup target add aarch64-apple-darwin x86_64-apple-darwin" >&2
  echo "For iOS simulator builds, also run:" >&2
  echo "  rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RUST_DIR="${PLUGIN_DIR}/rust"
TARGET_ROOT="${RUST_DIR}/target"
APPLE_OUTPUT_DIR="${TARGET_ROOT}/apple/${CONFIGURATION:-Debug}${EFFECTIVE_PLATFORM_NAME:-}"
APPLE_OUTPUT_LIBRARY="${APPLE_OUTPUT_DIR}/libbank_core_ffi_rust.a"

case "${CONFIGURATION:-Debug}" in
  Release|Profile)
    CARGO_PROFILE="release"
    CARGO_PROFILE_FLAG="--release"
    ;;
  *)
    CARGO_PROFILE="debug"
    CARGO_PROFILE_FLAG=""
    ;;
esac

target_for_arch() {
  local arch="$1"
  local sdk_name="${SDK_NAME:-macosx}"

  case "${sdk_name}:${arch}" in
    macosx*:arm64) echo "aarch64-apple-darwin" ;;
    macosx*:x86_64) echo "x86_64-apple-darwin" ;;
    iphoneos*:arm64) echo "aarch64-apple-ios" ;;
    iphonesimulator*:arm64) echo "aarch64-apple-ios-sim" ;;
    iphonesimulator*:x86_64) echo "x86_64-apple-ios" ;;
    *)
      echo "error: unsupported Rust Apple target for SDK_NAME=${sdk_name} ARCH=${arch}" >&2
      return 1
      ;;
  esac
}

if [[ -n "${ARCHS:-}" ]]; then
  read -r -a ARCH_ARRAY <<< "${ARCHS}"
else
  HOST_ARCH="$(uname -m)"
  if [[ "${HOST_ARCH}" == "arm64" ]]; then
    ARCH_ARRAY=("arm64")
  else
    ARCH_ARRAY=("x86_64")
  fi
fi

TARGETS=""
for arch in "${ARCH_ARRAY[@]}"; do
  target="$(target_for_arch "${arch}")"
  case " ${TARGETS} " in
    *" ${target} "*) ;;
    *) TARGETS="${TARGETS} ${target}" ;;
  esac
done

BUILT_LIBRARIES=""
BUILT_LIBRARY_COUNT=0
for target in ${TARGETS}; do
  "${CARGO_BIN}" build \
    ${CARGO_PROFILE_FLAG} \
    --manifest-path "${RUST_DIR}/Cargo.toml" \
    --target-dir "${TARGET_ROOT}" \
    --target "${target}"

  built_library="${TARGET_ROOT}/${target}/${CARGO_PROFILE}/libbank_core_ffi_rust.a"
  BUILT_LIBRARIES="${BUILT_LIBRARIES} ${built_library}"
  BUILT_LIBRARY_COUNT=$((BUILT_LIBRARY_COUNT + 1))
done

mkdir -p "${APPLE_OUTPUT_DIR}"
if [[ "${BUILT_LIBRARY_COUNT}" -eq 1 ]]; then
  cp ${BUILT_LIBRARIES} "${APPLE_OUTPUT_LIBRARY}"
else
  lipo -create ${BUILT_LIBRARIES} -output "${APPLE_OUTPUT_LIBRARY}"
fi

echo "Built ${APPLE_OUTPUT_LIBRARY}"
