// This file serves as a central registry for all providers
// It exports all providers for easy access throughout the app

// Import and re-export specific providers
export 'auth_provider.dart' show authProvider, currentUserProvider, firebaseAuthUserProvider, AuthState, AuthNotifier;
export 'restaurant_provider.dart' show restaurantProvider, allRestaurantsProvider, restaurantDetailsProvider, RestaurantState, firestoreServiceProvider;
export 'menu_provider.dart' show menuProvider, menuItemsProvider, menuCategoriesProvider, MenuState;
export 'order_provider.dart' show orderProvider, currentOrderProvider, orderDetailsProvider, OrderState;
export 'order_history_provider.dart' show orderHistoryProvider;
export 'payment_provider.dart' show paymentProvider, PaymentState;
export 'qr_code_provider.dart' show qrCodeProvider, QRCodeState, QRCodeNotifier;
export 'theme_provider.dart' show themeProvider, ThemeState, ThemeNotifier;
export 'app_preferences_provider.dart' show appPreferencesProvider, AppPreferencesState;
export 'network_provider.dart' show networkProvider, isOnlineProvider, connectionTypeProvider, isWifiProvider, isMobileDataProvider, NetworkState;
export 'log_provider.dart' show logProvider, logDebugProvider, logInfoProvider, logWarningProvider, logErrorProvider, logCriticalProvider, LogState, LogLevel;

// Import Riverpod for global providers
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Global loading state provider
final globalLoadingProvider = StateProvider<bool>((ref) => false);

// Global error message provider
final globalErrorProvider = StateProvider<String?>((ref) => null); 