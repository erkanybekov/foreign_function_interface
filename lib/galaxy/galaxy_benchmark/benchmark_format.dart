part of '../galaxy_benchmark_page.dart';

// Number formatting helpers for metric labels.
//
// Part of the galaxy benchmark library; see `galaxy_benchmark_page.dart`.

String _formatCompactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final thousands = value / 1000;
    return thousands >= 10
        ? '${thousands.toStringAsFixed(0)}k'
        : '${thousands.toStringAsFixed(1)}k';
  }
  return value.toString();
}

double _fractional(double value) => value - value.floorToDouble();
