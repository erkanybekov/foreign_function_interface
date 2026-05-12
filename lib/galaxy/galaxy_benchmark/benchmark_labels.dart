part of '../galaxy_benchmark_page.dart';


// Human-readable backend names, tags, and icons.
//
// Part of the galaxy benchmark library; see `galaxy_benchmark_page.dart`.

String _backendLabel(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => 'Pure Dart',
    GalaxyComputeBackend.cFfi => 'C via FFI',
    GalaxyComputeBackend.rustFfi => 'Rust via FFI',
  };
}

String _backendShortLabel(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => 'Dart',
    GalaxyComputeBackend.cFfi => 'C FFI',
    GalaxyComputeBackend.rustFfi => 'Rust FFI',
  };
}

String _sceneTag(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => 'No FFI',
    GalaxyComputeBackend.cFfi => 'Native batch step',
    GalaxyComputeBackend.rustFfi => 'Rust crate step',
  };
}

IconData _backendIcon(GalaxyComputeBackend backend) {
  return switch (backend) {
    GalaxyComputeBackend.dart => Icons.code,
    GalaxyComputeBackend.cFfi => Icons.memory,
    GalaxyComputeBackend.rustFfi => Icons.hub,
  };
}
