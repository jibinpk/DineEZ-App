import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys for preferences
class PreferenceKeys {
  static const String languageCode = 'language_code';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String savedRestaurantId = 'saved_restaurant_id';
  static const String lastVisitedTableId = 'last_visited_table_id';
  static const String taxRate = 'tax_rate';
  static const String defaultTipPercentage = 'default_tip_percentage';
  static const String analyticsEnabled = 'analytics_enabled';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String refreshInterval = 'refresh_interval';
  static const String lastEmail = 'last_email';
}

// App preferences state
class AppPreferencesState {
  final bool isLoading;
  final String? errorMessage;
  final String languageCode;
  final bool notificationsEnabled;
  final String? savedRestaurantId;
  final String? lastVisitedTableId;
  final double taxRate;
  final double defaultTipPercentage;
  final bool analyticsEnabled;
  final bool onboardingCompleted;
  final int refreshInterval; // in seconds
  final String? lastEmail;
  
  AppPreferencesState({
    this.isLoading = false,
    this.errorMessage,
    this.languageCode = 'en',
    this.notificationsEnabled = true,
    this.savedRestaurantId,
    this.lastVisitedTableId,
    this.taxRate = 0.1, // 10% default tax rate
    this.defaultTipPercentage = 0.15, // 15% default tip
    this.analyticsEnabled = true,
    this.onboardingCompleted = false,
    this.refreshInterval = 30, // 30 seconds default refresh interval
    this.lastEmail,
  });
  
  AppPreferencesState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? languageCode,
    bool? notificationsEnabled,
    String? savedRestaurantId,
    String? lastVisitedTableId,
    double? taxRate,
    double? defaultTipPercentage,
    bool? analyticsEnabled,
    bool? onboardingCompleted,
    int? refreshInterval,
    String? lastEmail,
  }) {
    return AppPreferencesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      languageCode: languageCode ?? this.languageCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      savedRestaurantId: savedRestaurantId ?? this.savedRestaurantId,
      lastVisitedTableId: lastVisitedTableId ?? this.lastVisitedTableId,
      taxRate: taxRate ?? this.taxRate,
      defaultTipPercentage: defaultTipPercentage ?? this.defaultTipPercentage,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      lastEmail: lastEmail ?? this.lastEmail,
    );
  }
  
  // Function to clear restaurant and table specific preferences
  AppPreferencesState clearRestaurantPreferences() {
    return copyWith(
      savedRestaurantId: null,
      lastVisitedTableId: null,
    );
  }
}

class AppPreferencesNotifier extends StateNotifier<AppPreferencesState> {
  AppPreferencesNotifier() : super(AppPreferencesState()) {
    _loadPreferences();
  }
  
  // Load all preferences from storage
  Future<void> _loadPreferences() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final prefs = await SharedPreferences.getInstance();
      
      state = state.copyWith(
        isLoading: false,
        languageCode: prefs.getString(PreferenceKeys.languageCode) ?? 'en',
        notificationsEnabled: prefs.getBool(PreferenceKeys.notificationsEnabled) ?? true,
        savedRestaurantId: prefs.getString(PreferenceKeys.savedRestaurantId),
        lastVisitedTableId: prefs.getString(PreferenceKeys.lastVisitedTableId),
        taxRate: prefs.getDouble(PreferenceKeys.taxRate) ?? 0.1,
        defaultTipPercentage: prefs.getDouble(PreferenceKeys.defaultTipPercentage) ?? 0.15,
        analyticsEnabled: prefs.getBool(PreferenceKeys.analyticsEnabled) ?? true,
        onboardingCompleted: prefs.getBool(PreferenceKeys.onboardingCompleted) ?? false,
        refreshInterval: prefs.getInt(PreferenceKeys.refreshInterval) ?? 30,
        lastEmail: prefs.getString(PreferenceKeys.lastEmail),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Save language preference
  Future<void> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PreferenceKeys.languageCode, languageCode);
      state = state.copyWith(languageCode: languageCode);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
  
  // Toggle notifications
  Future<void> toggleNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newValue = !state.notificationsEnabled;
      await prefs.setBool(PreferenceKeys.notificationsEnabled, newValue);
      state = state.copyWith(notificationsEnabled: newValue);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
  
  // Save restaurant ID
  Future<void> saveRestaurantId(String? restaurantId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (restaurantId != null) {
        await prefs.setString(PreferenceKeys.savedRestaurantId, restaurantId);
      } else {
        await prefs.remove(PreferenceKeys.savedRestaurantId);
      }
      state = state.copyWith(savedRestaurantId: restaurantId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
  
  // Save last visited table ID
  Future<void> saveTableId(String? tableId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (tableId != null) {
        await prefs.setString(PreferenceKeys.lastVisitedTableId, tableId);
      } else {
        await prefs.remove(PreferenceKeys.lastVisitedTableId);
      }
      state = state.copyWith(lastVisitedTableId: tableId);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
  
  // Update tax rate
  Future<void> setTaxRate(double taxRate) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(PreferenceKeys.taxRate, taxRate);
      state = state.copyWith(taxRate: taxRate);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
  
  // Update default tip percentage
  Future<void> setDefaultTip(double tipPercentage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(PreferenceKeys.defaultTipPercentage, tipPercentage);
      state = state.copyWith(defaultTipPercentage: tipPercentage);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
  
  // Toggle analytics
  Future<void> toggleAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newValue = !state.analyticsEnabled;
      await prefs.setBool(PreferenceKeys.analyticsEnabled, newValue);
      state = state.copyWith(analyticsEnabled: newValue);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
  
  // Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PreferenceKeys.onboardingCompleted, true);
      state = state.copyWith(onboardingCompleted: true);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
  
  // Set refresh interval
  Future<void> setRefreshInterval(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PreferenceKeys.refreshInterval, seconds);
      state = state.copyWith(refreshInterval: seconds);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }
  
  // Save email for remember me feature
  Future<void> saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PreferenceKeys.lastEmail, email);
      
      state = state.copyWith(lastEmail: email);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to save email: $e',
      );
    }
  }
  
  // Clear saved credentials for remember me feature
  Future<void> clearSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PreferenceKeys.lastEmail);
      
      state = state.copyWith(lastEmail: null);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to clear credentials: $e',
      );
    }
  }
  
  // Clear all preferences
  Future<void> resetAllPreferences() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      state = AppPreferencesState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

// App preferences provider
final appPreferencesProvider = StateNotifierProvider<AppPreferencesNotifier, AppPreferencesState>((ref) {
  return AppPreferencesNotifier();
}); 