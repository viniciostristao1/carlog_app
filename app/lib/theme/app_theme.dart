import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema do CarLog (ponto único de verdade visual). Aplica a paleta do [tema]
/// escolhido — inclusive o brilho (Madeira é claro; os demais, escuros).
/// Cantos arredondados, campos preenchidos, visual de "painel" moderno.
ThemeData buildAppTheme(TemaApp tema) {
  // Define a paleta atual ANTES de ler os tokens (fundo/superfície/texto).
  AppColors.aplicarTema(tema);
  final scheme = ColorScheme(
    brightness: AppColors.brilho,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: AppColors.accent,
    onSecondary: AppColors.onAccent,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: AppColors.brilho,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    fontFamily: null,
    splashFactory: InkRipple.splashFactory,
    iconTheme: IconThemeData(color: AppColors.text),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    dividerTheme: DividerThemeData(color: AppColors.line, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      hintStyle: TextStyle(color: AppColors.dim2),
      labelStyle: TextStyle(color: AppColors.dim),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: TextStyle(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
    ),
    listTileTheme: ListTileThemeData(iconColor: AppColors.dim),
  );
}
