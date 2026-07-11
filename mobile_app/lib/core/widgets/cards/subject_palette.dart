import 'package:flutter/material.dart';

const List<Color> _kSubjectPalette = [
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF0EA5E9),
  Color(0xFFF97316),
  Color(0xFF6366F1),
];

Color subjectColorAt(int index) =>
    _kSubjectPalette[index % _kSubjectPalette.length];
