# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(bank_core_ffi_library VERSION 0.0.1 LANGUAGES C)

add_library(bank_core_ffi SHARED
  "bank_core_ffi.c"
)

set_target_properties(bank_core_ffi PROPERTIES
  PUBLIC_HEADER bank_core_ffi.h
  OUTPUT_NAME "bank_core_ffi"
)

target_compile_definitions(bank_core_ffi PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(bank_core_ffi PRIVATE "-Wl,-z,max-page-size=16384")
endif()

option(BANK_CORE_FFI_ENABLE_RUST "Build Rust-backed galaxy symbols when Cargo is available" ON)

if (BANK_CORE_FFI_ENABLE_RUST AND NOT ANDROID)
  find_program(CARGO_EXECUTABLE cargo)
  if (CARGO_EXECUTABLE)
    set(RUST_PROFILE_DIR "debug")
    set(RUST_BUILD_FLAGS "")
    if (CMAKE_BUILD_TYPE STREQUAL "Release" OR
        CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo" OR
        CMAKE_BUILD_TYPE STREQUAL "MinSizeRel")
      set(RUST_PROFILE_DIR "release")
      set(RUST_BUILD_FLAGS "--release")
    endif()

    set(RUST_TARGET_DIR "${CMAKE_CURRENT_BINARY_DIR}/cargo")
    if (WIN32)
      set(RUST_STATIC_LIBRARY "${RUST_TARGET_DIR}/${RUST_PROFILE_DIR}/bank_core_ffi_rust.lib")
    else()
      set(RUST_STATIC_LIBRARY "${RUST_TARGET_DIR}/${RUST_PROFILE_DIR}/libbank_core_ffi_rust.a")
    endif()

    add_custom_command(
      OUTPUT "${RUST_STATIC_LIBRARY}"
      COMMAND "${CARGO_EXECUTABLE}" build ${RUST_BUILD_FLAGS}
        --manifest-path "${CMAKE_CURRENT_LIST_DIR}/../rust/Cargo.toml"
        --target-dir "${RUST_TARGET_DIR}"
      WORKING_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}/../rust"
      VERBATIM
    )
    add_custom_target(bank_core_ffi_rust_build DEPENDS "${RUST_STATIC_LIBRARY}")
    add_dependencies(bank_core_ffi bank_core_ffi_rust_build)

    if (APPLE)
      target_link_libraries(bank_core_ffi PRIVATE "-Wl,-force_load,${RUST_STATIC_LIBRARY}")
    elseif (WIN32)
      target_link_options(bank_core_ffi PRIVATE "/WHOLEARCHIVE:${RUST_STATIC_LIBRARY}")
      target_link_libraries(bank_core_ffi PRIVATE "${RUST_STATIC_LIBRARY}")
    elseif (UNIX)
      target_link_libraries(
        bank_core_ffi
        PRIVATE
        "-Wl,--whole-archive"
        "${RUST_STATIC_LIBRARY}"
        "-Wl,--no-whole-archive"
        dl
        pthread
        m
      )
    endif()
  else()
    message(STATUS "Cargo not found; Rust ABI symbols will not be exported.")
  endif()
endif()
