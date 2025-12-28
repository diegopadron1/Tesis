import 'package:flutter/material.dart';

class ThemeNotifier {
  // Empezamos en dark como ya la tienes
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  static void toggleTheme() {
    themeMode.value = (themeMode.value == ThemeMode.dark) 
        ? ThemeMode.light 
        : ThemeMode.dark;
  }
}