import 'package:flutter/material.dart';

class AppColors {
  // Prevenir instanciación
  AppColors._();

  // ============= COLORES PRINCIPALES =============

  // Rojo - Color primario de la marca
  static const Color primary = Color(0xFFCC0000); // Rojo Enfocados
  static const Color primaryLight = Color(0xFFFF5252);
  static const Color primaryDark = Color(0xFF990000);

  // Dorado - Color secundario
  static const Color gold = Color(0xFFFFD700); // Dorado
  static const Color goldLight = Color(0xFFFFE54C);
  static const Color goldDark = Color(0xFFC7A600);

  // ============= COLORES BASE =============

  // Blancos y Negros
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color blackSoft = Color(0xFF1A1A1A);

  // ============= TEMA CLARO =============

  // Backgrounds
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFAFAFA);

  // Textos
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFFE0E0E0);

  // Bordes y Divisores
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Inputs
  static const Color inputFill = Color(0xFFF5F5F5);
  static const Color inputBorder = Color(0xFFE0E0E0);

  // ============= TEMA OSCURO =============

  // Backgrounds Dark
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2C);

  // Textos Dark
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);
  static const Color textHintDark = Color(0xFF666666);
  static const Color textDisabledDark = Color(0xFF404040);

  // Bordes y Divisores Dark
  static const Color borderDark = Color(0xFF333333);
  static const Color dividerDark = Color(0xFF2A2A2A);

  // Inputs Dark
  static const Color inputFillDark = Color(0xFF2C2C2C);
  static const Color inputBorderDark = Color(0xFF404040);

  // ============= COLORES DE ESTADO =============

  // Success
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  // Error
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFEF5350);
  static const Color errorDark = Color(0xFFC62828);

  // Warning
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFEF6C00);

  // Info
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1565C0);

  // ============= COLORES ESPECIALES =============

  // Gradientes principales
  static const List<Color> primaryGradient = [
    Color(0xFFCC0000),
    Color(0xFFFF5252),
  ];

  static const List<Color> goldGradient = [
    Color(0xFFFFD700),
    Color(0xFFFFE54C),
    Color(0xFFFFC107),
  ];

  static const List<Color> verseGradient = [
    Color(0xFFFFD700), // Gold
    Color(0xFFFF6B6B), // Red light
    Color(0xFFFF8C00), // Orange
  ];

  // Colores para subrayado bíblico
  static const Color highlightYellow = Color(0x80FFEB3B);
  static const Color highlightGreen = Color(0x804CAF50);
  static const Color highlightBlue = Color(0x802196F3);
  static const Color highlightPink = Color(0x80E91E63);
  static const Color highlightOrange = Color(0x80FF9800);
  static const Color highlightPurple = Color(0x809C27B0);

  // Overlay y Modal
  static const Color overlay = Color(0x80000000); // 50% negro
  static const Color modalBackground = Color(0xFFFFFFFF);
  static const Color modalBackgroundDark = Color(0xFF2C2C2C);

  // Skeleton loading
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF333333);
  static const Color shimmerHighlightDark = Color(0xFF444444);

  // Chips y Tags
  static const Color chipBackground = Color(0xFFEEEEEE);
  static const Color chipBackgroundDark = Color(0xFF333333);
  static const Color chipSelected = primary;

  // Iconos
  static const Color icon = Color(0xFF757575);
  static const Color iconDark = Color(0xFFB3B3B3);
  static const Color iconSelected = primary;

  // Disabled states
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color disabledDark = Color(0xFF616161);

  // ============= COLORES DE CATEGORÍAS =============

  // Categorías de videos
  static const Color categoryDebate = Color(0xFF9C27B0);
  static const Color categoryPredica = Color(0xFF3F51B5);
  static const Color categoryEntrevista = Color(0xFF009688);
  static const Color categoryCurso = Color(0xFFFF5722);
  static const Color categoryTestimonio = Color(0xFF795548);

  // Niveles de cursos
  static const Color levelBeginner = Color(0xFF4CAF50);
  static const Color levelIntermediate = Color(0xFFFF9800);
  static const Color levelAdvanced = Color(0xFFF44336);

  // ============= MÉTODOS HELPER =============

  /// Obtiene el color de subrayado basado en el índice
  static Color getHighlightColor(int index) {
    const colors = [
      highlightYellow,
      highlightGreen,
      highlightBlue,
      highlightPink,
      highlightOrange,
      highlightPurple,
    ];
    return colors[index % colors.length];
  }

  /// Obtiene el color de categoría de video
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'debate':
      case 'debates':
        return categoryDebate;
      case 'predica':
      case 'predicas':
      case 'predicación':
        return categoryPredica;
      case 'entrevista':
      case 'entrevistas':
        return categoryEntrevista;
      case 'curso':
      case 'cursos':
        return categoryCurso;
      case 'testimonio':
      case 'testimonios':
        return categoryTestimonio;
      default:
        return primary;
    }
  }

  /// Obtiene el color del nivel del curso
  static Color getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
      case 'principiante':
      case 'básico':
        return levelBeginner;
      case 'intermediate':
      case 'intermedio':
        return levelIntermediate;
      case 'advanced':
      case 'avanzado':
        return levelAdvanced;
      default:
        return textSecondary;
    }
  }

  /// Crea un MaterialColor desde un Color
  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}