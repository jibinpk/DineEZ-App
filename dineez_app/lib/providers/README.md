# DineEZ App Providers

This directory contains all the providers used in the DineEZ app using Riverpod for state management. The providers are organized into separate files based on their functionality, and a central registry (`providers.dart`) makes them easily accessible throughout the app.

## Provider Structure

The app follows a structured approach for state management:

1. **State Classes**: Define immutable data models with `copyWith` methods for state updates
2. **Notifier Classes**: Extend `StateNotifier` to manipulate state and handle business logic
3. **Provider Definitions**: Create and export providers using Riverpod's provider system

## Available Providers

### Authentication Provider (`auth_provider.dart`)

Manages user authentication state and operations:
- Sign in/sign up functionality
- User profile management
- Authentication state tracking

```dart
// Usage example
final authState = ref.watch(authProvider);
final currentUser = ref.watch(currentUserProvider);

// Perform authentication
ref.read(authProvider.notifier).signIn(email, password);
```

### Restaurant Provider (`restaurant_provider.dart`)

Handles restaurant data operations:
- Fetching restaurant details
- Managing restaurant list
- Restaurant CRUD operations

```dart
// Usage example
final restaurants = ref.watch(allRestaurantsProvider);
final selectedRestaurant = ref.watch(restaurantDetailsProvider(restaurantId));

// Fetch restaurants
ref.read(restaurantProvider.notifier).fetchRestaurants();
```

### Menu Provider (`menu_provider.dart`)

Manages menu items and categories:
- Menu item CRUD operations
- Category management
- Menu filtering and searching

```dart
// Usage example
final menuItems = ref.watch(menuItemsProvider(restaurantId));
final categories = ref.watch(menuCategoriesProvider(restaurantId));

// Add menu item
ref.read(menuProvider.notifier).addMenuItem(newMenuItem);
```

### Order Provider (`order_provider.dart`)

Handles order management:
- Cart functionality
- Order processing
- Order history

```dart
// Usage example
final currentOrder = ref.watch(currentOrderProvider);
final orderHistory = ref.watch(orderHistoryProvider(userId));

// Add item to cart
ref.read(orderProvider.notifier).addToCart(menuItem, quantity);
```

### Payment Provider (`payment_provider.dart`)

Manages payment processing:
- Payment method handling
- Transaction processing
- Payment history

```dart
// Usage example
final paymentState = ref.watch(paymentProvider);

// Process payment
ref.read(paymentProvider.notifier).processPayment(order, paymentMethod);
```

### QR Code Provider (`qr_code_provider.dart`)

Handles QR code operations:
- QR code generation
- QR code scanning and validation
- Table association

```dart
// Usage example
final qrCodeState = ref.watch(qrCodeProvider);

// Generate QR code for table
ref.read(qrCodeProvider.notifier).generateQRForTable(tableId);
```

### Theme Provider (`theme_provider.dart`)

Manages app theme settings:
- Light/dark mode
- Theme customization
- Persistent theme preferences

```dart
// Usage example
final themeState = ref.watch(themeProvider);

// Toggle dark mode
ref.read(themeProvider.notifier).toggleDarkMode();
```

### App Preferences Provider (`app_preferences_provider.dart`)

Manages app-wide preferences:
- Language settings
- Notification preferences
- User-specific settings

```dart
// Usage example
final preferences = ref.watch(appPreferencesProvider);

// Update language
ref.read(appPreferencesProvider.notifier).setLanguage('en');
```

### Network Provider (`network_provider.dart`)

Manages network connectivity state:
- Online/offline status
- Connection type detection
- Network state change monitoring

```dart
// Usage example
final isOnline = ref.watch(isOnlineProvider);
final isWifi = ref.watch(isWifiProvider);

// Check connectivity
ref.read(networkProvider.notifier).checkConnectivity();
```

### Log Provider (`log_provider.dart`)

Handles application logging:
- Multi-level logging (debug, info, warning, error, critical)
- Log storage and retrieval
- Log export functionality

```dart
// Usage example
final logs = ref.watch(logProvider).logs;

// Log events
ref.read(logDebugProvider)('Debug message', source: 'LoginScreen');
ref.read(logErrorProvider)('Error occurred', source: 'PaymentService', data: error);
```

### Global Providers (`providers.dart`)

Additional global providers:
- `globalLoadingProvider`: Manages app-wide loading state
- `globalErrorProvider`: Handles global error messages

```dart
// Usage example
final isLoading = ref.watch(globalLoadingProvider);
final errorMessage = ref.watch(globalErrorProvider);

// Update global state
ref.read(globalLoadingProvider.notifier).state = true;
ref.read(globalErrorProvider.notifier).state = 'An error occurred';
```

## Best Practices

1. **Provider Dependencies**: Use `ref.watch` for providers that depend on other providers
2. **State Updates**: Always use the `copyWith` pattern for immutable state updates
3. **Error Handling**: Include proper error handling in provider methods
4. **Provider Scope**: Use `ProviderScope` at the app root to initialize all providers
5. **Provider Override**: Use `ProviderScope.overrides` for testing and dependency injection

## Example App Structure

```dart
void main() {
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    
    return MaterialApp(
      theme: themeState.currentTheme,
      home: ref.watch(authProvider).user != null 
          ? HomeScreen() 
          : LoginScreen(),
    );
  }
}
```

## Provider Overrides for Testing

```dart
testWidgets('Test with overridden providers', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWithValue(
          AuthState(isAuthenticated: true, user: mockUser),
        ),
      ],
      child: MyApp(),
    ),
  );
  
  // Your test assertions here
});
```

## Logging in Providers

Add logging to your providers for better debugging:

```dart
// Inside a provider method
Future<void> signIn(String email, String password) async {
  try {
    state = state.copyWith(isLoading: true, errorMessage: null);
    ref.read(logInfoProvider)('Signing in user', source: 'AuthProvider', data: {'email': email});
    
    // Authentication logic...
    
    ref.read(logInfoProvider)('User signed in successfully', source: 'AuthProvider');
  } catch (e) {
    ref.read(logErrorProvider)('Sign in failed', source: 'AuthProvider', data: e);
    state = state.copyWith(isLoading: false, errorMessage: e.toString());
  }
}
``` 