import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF666666),
      surface: Color(0xFFF7F8FA),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF111111),
      onSurface: Color(0xFF111111),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F6F8),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE8EAF0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black87),
    ),
    iconTheme: const IconThemeData(color: Colors.black87),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.black54,
      textColor: Colors.black87,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF2563EB)
            : Colors.grey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF93C5FD)
            : Colors.grey,
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF60A5FA),
      secondary: Color(0xFF94A3B8),
      surface: Color(0xFF1E293B),
      onPrimary: Colors.white,
      onSecondary: Colors.white70,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardColor: const Color(0xFF1E293B),
    dividerColor: const Color(0xFF334155),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111827),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white70,
      textColor: Colors.white70,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF60A5FA)
            : Colors.grey,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF1E40AF)
            : Colors.grey,
      ),
    ),
  );
}
