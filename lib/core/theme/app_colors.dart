import 'package:flutter/material.dart';

abstract final class AppColors {
  static const emerald = Color(0xFF0B6B53);
  static const emeraldBright = Color(0xFF16A37E);
  static const emeraldSoft = Color(0xFFDDF5EC);
  static const navy = Color(0xFF0D1F2D);
  static const navySoft = Color(0xFF173446);
  static const gold = Color(0xFFC99A43);
  static const goldSoft = Color(0xFFFFF2D6);

  static const lightBackground = Color(0xFFF3F7F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceMuted = Color(0xFFEAF1EE);
  static const lightText = Color(0xFF14231E);
  static const lightTextMuted = Color(0xFF62736C);

  static const darkBackground = Color(0xFF071510);
  static const darkSurface = Color(0xFF10231C);
  static const darkSurfaceMuted = Color(0xFF173128);
  static const darkText = Color(0xFFF1F8F5);
  static const darkTextMuted = Color(0xFFA9BDB5);

  static const success = Color(0xFF15966F);
  static const warning = Color(0xFFD4912D);
  static const danger = Color(0xFFCA4B52);
  static const info = Color(0xFF3776A8);
  static const shamCash = Color(0xFF122B43);

  static LinearGradient heroGradient(Brightness brightness) => LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: brightness == Brightness.dark
        ? const [Color(0xFF173E32), Color(0xFF0B211A), Color(0xFF081A2A)]
        : const [Color(0xFF0B6B53), Color(0xFF0F8067), Color(0xFF173D51)],
  );

  static LinearGradient pageGlow(Brightness brightness) => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: brightness == Brightness.dark
        ? const [Color(0xFF0D241C), darkBackground]
        : const [Color(0xFFE2F3EC), lightBackground],
  );
}
