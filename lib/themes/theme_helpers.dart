import 'package:flutter/material.dart';

extension AppThemeColors on BuildContext {
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get cardColor => Theme.of(this).cardColor;
  Color get borderColor => Theme.of(this).dividerColor;
  Color get primaryTextColor => Theme.of(this).colorScheme.onSurface;
  Color get secondaryTextColor =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.82);
  Color get mutedTextColor =>
      Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.65);
  Color get accentBackground => Theme.of(this).colorScheme.primaryContainer;
}
