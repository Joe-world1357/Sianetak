import 'package:flutter/material.dart';

/// Maps backend `iconKey` values to Material icons, with a generic fallback.
IconData iconForCategory(String? key) => switch (key) {
  'plumbing' => Icons.plumbing,
  'electrical' => Icons.electrical_services,
  'air_conditioning' => Icons.ac_unit,
  'carpentry' => Icons.carpenter,
  'painting' => Icons.format_paint,
  'appliances' => Icons.kitchen,
  _ => Icons.home_repair_service,
};
