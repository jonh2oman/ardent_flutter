import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system, sea, army, air, nightVision }

class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'theme_pref';
  AppThemeMode _themeMode = AppThemeMode.system;

  AppThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? themeStr = prefs.getString(_themePrefKey);
    if (themeStr != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (e) => e.toString() == themeStr,
        orElse: () => AppThemeMode.system,
      );
      notifyListeners();
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, mode.toString());
    notifyListeners();
  }

  ThemeData getThemeData(BuildContext context) {
    // If system, we resolve to Light or Dark based on MediaQuery
    Brightness platformBrightness = MediaQuery.platformBrightnessOf(context);
    AppThemeMode effectiveMode = _themeMode;
    
    if (effectiveMode == AppThemeMode.system) {
      effectiveMode = platformBrightness == Brightness.dark ? AppThemeMode.dark : AppThemeMode.light;
    }

    switch (effectiveMode) {
      case AppThemeMode.light:
        return _buildTheme(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF6366F1), // Indigo
          scaffoldColor: const Color(0xFFF8FAFC), // Slate 50
          surfaceColor: const Color(0xFFFFFFFF), // White
          seedColor: const Color(0xFF6366F1),
        );
      case AppThemeMode.dark:
        return _buildTheme(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF6366F1), // Indigo
          scaffoldColor: const Color(0xFF0F172A), // Slate 900
          surfaceColor: const Color(0xFF1E293B), // Slate 800
          seedColor: const Color(0xFF6366F1),
        );
      case AppThemeMode.sea:
        return _buildTheme(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFD4AF37), // Gold
          scaffoldColor: const Color(0xFF0A192F), // Deep Navy
          surfaceColor: const Color(0xFF112240), // Lighter Navy
          seedColor: const Color(0xFF0077B6), // Teal
        );
      case AppThemeMode.army:
        return _buildTheme(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFFC3B091), // Khaki
          scaffoldColor: const Color(0xFF2C3524), // Olive Drab
          surfaceColor: const Color(0xFF3B4431), // Lighter Olive
          seedColor: const Color(0xFF4B5320), // Army Green
        );
      case AppThemeMode.air:
        return _buildTheme(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF87CEEB), // Sky Blue
          scaffoldColor: const Color(0xFF1A2634), // Slate Grey
          surfaceColor: const Color(0xFF233245), // Lighter Slate
          seedColor: const Color(0xFF4682B4), // Steel Blue
        );
      case AppThemeMode.nightVision:
        return _buildNightVisionTheme();
      default:
        return _buildTheme(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF6366F1),
          scaffoldColor: const Color(0xFF0F172A),
          surfaceColor: const Color(0xFF1E293B),
          seedColor: const Color(0xFF6366F1),
        );
    }
  }

  ThemeData _buildTheme({
    required Brightness brightness,
    required Color primaryColor,
    required Color scaffoldColor,
    required Color surfaceColor,
    required Color seedColor,
  }) {
    final baseTheme = ThemeData(brightness: brightness);
    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldColor,
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: brightness == Brightness.dark ? Colors.white : Colors.black87,
        displayColor: brightness == Brightness.dark ? Colors.white : Colors.black87,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        primary: primaryColor,
        surface: surfaceColor,
      ),
      cardColor: surfaceColor,
      dialogBackgroundColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: GoogleFonts.inter(
          color: brightness == Brightness.dark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildNightVisionTheme() {
    final baseTheme = ThemeData(brightness: Brightness.dark);
    const nvGreen = Color(0xFF39FF14); // Neon Green
    const nvDark = Color(0xFF000000);  // Pure Black
    const nvSurface = Color(0xFF051505); // Very Dark Green
    
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: nvGreen,
      scaffoldBackgroundColor: nvDark,
      textTheme: GoogleFonts.firaCodeTextTheme(baseTheme.textTheme).apply(
        bodyColor: nvGreen,
        displayColor: nvGreen,
      ),
      colorScheme: ColorScheme.dark(
        primary: nvGreen,
        secondary: nvGreen,
        surface: nvSurface,
        background: nvDark,
        onPrimary: nvDark,
        onSecondary: nvDark,
        onSurface: nvGreen,
        onBackground: nvGreen,
      ),
      cardColor: nvSurface,
      dialogBackgroundColor: nvSurface,
      iconTheme: const IconThemeData(color: nvGreen),
      dividerColor: nvGreen.withOpacity(0.3),
      appBarTheme: AppBarTheme(
        backgroundColor: nvDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: nvGreen),
        titleTextStyle: GoogleFonts.firaCode(
          color: nvGreen,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      useMaterial3: true,
    );
  }
}
