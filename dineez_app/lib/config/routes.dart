import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../screens/splash_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/customer/restaurant_list_screen.dart';
import '../screens/customer/restaurant_details_screen.dart';
import '../screens/customer/menu_screen.dart';
import '../screens/customer/cart_screen.dart';
import '../screens/customer/qr_scanner_screen.dart';
import '../screens/order/checkout_screen.dart';
import '../screens/order/order_history_screen.dart';
import '../screens/order/order_details_screen.dart';

// Import screen files (to be created later)
// import '../screens/onboarding/onboarding_screen.dart';
// import '../screens/customer/customer_home_screen.dart';
// import '../screens/staff/staff_home_screen.dart';
// import '../screens/restaurant_admin/restaurant_admin_home_screen.dart';
// import '../screens/super_admin/super_admin_home_screen.dart';
// import '../screens/customer/scan_qr_screen.dart';
// import '../screens/customer/payment_screen.dart';
// import '../screens/profile/profile_screen.dart';
// import '../screens/settings/settings_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Extract arguments if available
    final args = settings.arguments;
    
    switch (settings.name) {
      case AppConstants.routeInitial:
      case AppConstants.routeSplash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      
      case AppConstants.routeLogin:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      
      case AppConstants.routeRegister:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );
      
      case AppConstants.routeForgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
        );
        
      case AppConstants.routeOnboarding:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Onboarding Screen')),
          ),
        );
        
      case AppConstants.routeDashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
        );
      
      case AppConstants.routeRestaurantList:
        return MaterialPageRoute(
          builder: (_) => const RestaurantListScreen(),
        );
      
      case AppConstants.routeRestaurantDetails:
        // Check if arguments are provided and contain a restaurantId
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => RestaurantDetailsScreen(restaurantId: args),
          );
        } else if (args is Map<String, dynamic> && args.containsKey('restaurantId')) {
          return MaterialPageRoute(
            builder: (_) => RestaurantDetailsScreen(restaurantId: args['restaurantId']),
          );
        }
        // Fallback if no arguments provided
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Restaurant ID is required')),
          ),
        );
      
      case AppConstants.routeCustomerHome:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Customer Home Screen')),
          ),
        );
      
      case AppConstants.routeStaffHome:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Staff Home Screen')),
          ),
        );
      
      case AppConstants.routeRestaurantAdminHome:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Restaurant Admin Home Screen')),
          ),
        );
      
      case AppConstants.routeSuperAdminHome:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Super Admin Home Screen')),
          ),
        );
      
      case AppConstants.routeScanQR:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Scan QR Screen')),
          ),
        );
      
      case AppConstants.routeMenu:
        // Check if arguments contain restaurantId which is required
        if (args is Map<String, dynamic> && args.containsKey('restaurantId')) {
          return MaterialPageRoute(
            builder: (_) => MenuScreen(
              restaurantId: args['restaurantId'],
              category: args['category'],
              menuItemId: args['menuItemId'],
            ),
          );
        }
        // Fallback if no restaurantId provided
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Restaurant ID is required for menu')),
          ),
        );
        
      case AppConstants.routeCart:
        // Check if arguments contain restaurantId which is required
        if (args is Map<String, dynamic> && args.containsKey('restaurantId')) {
          return MaterialPageRoute(
            builder: (_) => CartScreen(
              restaurantId: args['restaurantId'],
            ),
          );
        }
        // Fallback if no restaurantId provided
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Restaurant ID is required for cart')),
          ),
        );
        
      case AppConstants.routeCheckout:
        // Check if arguments contain restaurantId which is required
        if (args is Map<String, dynamic> && args.containsKey('restaurantId')) {
          return MaterialPageRoute(
            builder: (_) => CheckoutScreen(
              restaurantId: args['restaurantId'],
              specialInstructions: args['specialInstructions'],
            ),
          );
        }
        // Fallback if no restaurantId provided
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Restaurant ID is required for checkout')),
          ),
        );
        
      case AppConstants.routeOrderHistory:
        return MaterialPageRoute(
          builder: (_) => const OrderHistoryScreen(),
        );
      
      case AppConstants.routeOrderDetails:
        // Check if arguments contain restaurantId and orderId which are required
        if (args is Map<String, dynamic> && 
            args.containsKey('restaurantId') && 
            args.containsKey('orderId')) {
          return MaterialPageRoute(
            builder: (_) => OrderDetailsScreen(
              restaurantId: args['restaurantId'],
              orderId: args['orderId'],
            ),
          );
        }
        // Fallback if required parameters are not provided
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Restaurant ID and Order ID are required')),
          ),
        );
        
      case AppConstants.routeQrScanner:
        return MaterialPageRoute(
          builder: (_) => const QRScannerScreen(),
        );
        
      // Handle other routes with placeholder screens
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Not Found')),
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
} 