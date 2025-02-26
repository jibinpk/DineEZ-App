import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/themes.dart';

// Theme mode enum for preference storage
enum ThemePreference { system, light, dark }

// Theme state
class ThemeState {
  final ThemeMode themeMode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final bool isLoading;
  final String? errorMessage;
  
  ThemeState({
    this.themeMode = ThemeMode.system,
    required this.lightTheme,
    required this.darkTheme,
    this.isLoading = false,
    this.errorMessage,
  });
  
  ThemeState copyWith({
    ThemeMode? themeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeModeKey = 'theme_mode';
  
  ThemeNotifier() : super(
    ThemeState(
      lightTheme: AppTheme.lightTheme,
      // Since AppTheme.darkTheme doesn't exist yet, create a dark theme based on light theme
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: AppTheme.lightTheme.primaryColor,
        colorScheme: ColorScheme.dark(
          primary: AppTheme.lightTheme.colorScheme.primary,
          secondary: AppTheme.lightTheme.colorScheme.secondary,
        ),
      ),
    )
  ) {
    _loadThemePreference();
  }
  
  // Load theme preference from storage
  Future<void> _loadThemePreference() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final prefs = await SharedPreferences.getInstance();
      final savedThemeMode = prefs.getString(_themeModeKey);
      
      ThemeMode themeMode;
      if (savedThemeMode != null) {
        switch (savedThemeMode) {
          case 'light':
            themeMode = ThemeMode.light;
            break;
          case 'dark':
            themeMode = ThemeMode.dark;
            break;
          default:
            themeMode = ThemeMode.system;
        }
      } else {
        themeMode = ThemeMode.system;
      }
      
      state = state.copyWith(
        isLoading: false,
        themeMode: themeMode,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Set theme mode and save to preferences
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final prefs = await SharedPreferences.getInstance();
      String themeModeString;
      
      switch (mode) {
        case ThemeMode.light:
          themeModeString = 'light';
          break;
        case ThemeMode.dark:
          themeModeString = 'dark';
          break;
        default:
          themeModeString = 'system';
      }
      
      await prefs.setString(_themeModeKey, themeModeString);
      
      state = state.copyWith(
        isLoading: false,
        themeMode: mode,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Toggle between light and dark mode
  Future<void> toggleThemeMode() async {
    final newMode = state.themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    await setThemeMode(newMode);
  }
  
  // Reset to system default
  Future<void> resetToSystemDefault() async {
    await setThemeMode(ThemeMode.system);
  }
  
  // Check if dark mode is active
  bool get isDarkMode => state.themeMode == ThemeMode.dark;
  
  // Get current theme data based on mode and platform brightness
  ThemeData getThemeData(Brightness platformBrightness) {
    switch (state.themeMode) {
      case ThemeMode.light:
        return state.lightTheme;
      case ThemeMode.dark:
        return state.darkTheme;
      default:
        // Use platform brightness to determine theme
        return platformBrightness == Brightness.dark 
            ? state.darkTheme 
            : state.lightTheme;
    }
  }
}

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
}); 