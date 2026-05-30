import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class AppText {
  static TextStyle h1({Color? color}) => GoogleFonts.spaceGrotesk(
    fontSize: 27,
    height: 1.12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color ?? AppColors.ink,
  );
  static TextStyle h2({Color? color}) => GoogleFonts.spaceGrotesk(
    fontSize: 21,
    height: 1.18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color ?? AppColors.ink,
  );
  static TextStyle h3({Color? color}) => GoogleFonts.spaceGrotesk(
    fontSize: 17,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: color ?? AppColors.ink,
  );
  static TextStyle eyebrow({Color? color}) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    color: color ?? AppColors.teal,
  );
  static TextStyle body({Color? color}) => GoogleFonts.inter(
    fontSize: 15,
    height: 1.5,
    color: color ?? AppColors.ink2,
  );
  static TextStyle sm({Color? color, FontWeight? weight}) => GoogleFonts.inter(
    fontSize: 13,
    height: 1.45,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? AppColors.ink2,
  );
  static TextStyle xs({Color? color, FontWeight? weight}) => GoogleFonts.inter(
    fontSize: 11.5,
    height: 1.4,
    fontWeight: weight ?? FontWeight.w400,
    color: color ?? AppColors.ink3,
  );
  static TextStyle btn({Color? color}) => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color ?? Colors.white,
  );
}
