import 'package:flutter/material.dart';

/// Design tokens lifted from the Claude design handoff (respace.css).
class AppColors {
  // neutrals
  static const bg = Color(0xFFEEF3F4);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFF3F7F8);
  static const surface3 = Color(0xFFE9F0F1);
  static const ink = Color(0xFF0F1E29);
  static const ink2 = Color(0xFF566873);
  static const ink3 = Color(0xFF8DA0A9);
  static const border = Color(0xFFE1E9EC);
  static const border2 = Color(0xFFD2DDE1);

  // teal accent
  static const teal = Color(0xFF0E9E8C);
  static const tealStrong = Color(0xFF0B7E70);
  static const tealTint = Color(0xFFE2F4F0);
  static const tealTint2 = Color(0xFFD2EDE7);
  static const tealInk = Color(0xFF0A5F54);

  // warm (redesign)
  static const warm = Color(0xFFE59A3C);
  static const warmTint = Color(0xFFFBEFDD);
  static const warmInk = Color(0xFF9A6314);

  // semantics
  static const ok = Color(0xFF1B9E6B);
  static const okTint = Color(0xFFE2F3EB);
  static const warn = Color(0xFFE0962F);
  static const warnTint = Color(0xFFFBEEDB);
  static const danger = Color(0xFFDB4A4A);
  static const dangerTint = Color(0xFFFBE6E6);

  // difficulty
  static const diffEasy = Color(0xFF1B9E6B);
  static const diffMed = Color(0xFFE0962F);
  static const diffHard = Color(0xFFDB6A3C);
}

class AppRadii {
  static const xs = 8.0;
  static const sm = 12.0;
  static const r = 16.0;
  static const lg = 20.0;
  static const xl = 26.0;
  static const pill = 999.0;
}

class AppShadows {
  static const sh = [
    BoxShadow(
      color: Color(0x29152E29),
      blurRadius: 20,
      offset: Offset(0, 6),
      spreadRadius: -8,
    ),
    BoxShadow(color: Color(0x0D152E29), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static const sm = [
    BoxShadow(color: Color(0x0F152E29), blurRadius: 3, offset: Offset(0, 1)),
  ];
  static const teal = [
    BoxShadow(
      color: Color(0x8C0E9E8C),
      blurRadius: 30,
      offset: Offset(0, 10),
      spreadRadius: -10,
    ),
  ];
}
