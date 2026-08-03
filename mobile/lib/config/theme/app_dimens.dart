import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Radius scale from the web `@theme` block (`--radius-sm` … `--radius-2xl`).
class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

/// 4px-based spacing, matching Tailwind's default scale used across the web app.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  /// Standard page gutter — the web app uses p-4 on small screens.
  static const EdgeInsets page = EdgeInsets.all(lg);
  static const EdgeInsets pageBottom = EdgeInsets.fromLTRB(lg, lg, lg, 32);
}

/// Elevation tokens (`--shadow-sm` / `--shadow-md` / `--shadow-lg`).
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> sm = <BoxShadow>[
    BoxShadow(color: Color(0x0D101828), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> md = <BoxShadow>[
    BoxShadow(color: Color(0x14101828), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> lg = <BoxShadow>[
    BoxShadow(color: Color(0x1F101828), blurRadius: 24, offset: Offset(0, 12)),
  ];
}

/// Control heights matching `components/ui/Button.jsx` and `Input.jsx`.
class AppSizes {
  const AppSizes._();

  static const double buttonSm = 32;
  static const double buttonMd = 40;
  static const double buttonLg = 48;
  static const double inputHeight = 44;
}

/// The blue brand gradient used by the web `AuthLayout` hero panel.
const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: <Color>[
    AppColors.primary600,
    AppColors.primary700,
    AppColors.primary800,
    AppColors.primary900,
  ],
  stops: <double>[0.0, 0.35, 0.65, 1.0],
);
