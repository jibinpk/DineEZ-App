// DineEZ App Constants

class AppConstants {
  // App Information
  static const String appName = 'DineEZ';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String restaurantsCollection = 'restaurants';
  static const String menuItemsCollection = 'menuItems';
  static const String tablesCollection = 'tables';
  static const String ordersCollection = 'orders';
  static const String paymentsCollection = 'payments';
  
  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleStaff = 'staff';
  static const String roleRestaurantAdmin = 'restaurantAdmin';
  static const String roleSuperAdmin = 'superAdmin';
  
  // Order Status
  static const String orderStatusNew = 'new';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusServed = 'served';
  static const String orderStatusCompleted = 'completed';
  
  // Payment Status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';
  
  // Routes
  static const String routeInitial = '/';
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeOnboarding = '/onboarding';
  static const String routeDashboard = '/dashboard';
  static const String routeCustomerHome = '/customer/home';
  static const String routeStaffHome = '/staff/home';
  static const String routeRestaurantAdminHome = '/restaurant-admin/home';
  static const String routeSuperAdminHome = '/super-admin/home';
  static const String routeScanQR = '/scan-qr';
  static const String routeMenu = '/menu';
  static const String routeCart = '/cart';
  static const String routeOrderTracking = '/order-tracking';
  static const String routePayment = '/payment';
  static const String routeProfile = '/profile';
  static const String routeRestaurantList = '/restaurants';
  static const String routeRestaurantDetails = '/restaurant-details';
  static const String routeCheckout = '/checkout';
  static const String routeOrderHistory = '/order-history';
  static const String routeOrderDetails = '/order-details';
  static const String routeQrScanner = '/qr-scanner';
  static const String routeSettings = '/settings';
  
  // API Keys (These would be stored securely in production)
  static const String razorpayKeyId = 'YOUR_RAZORPAY_KEY_ID';
  
  // Animations
  static const int animationDuration = 300; // milliseconds
  
  // Defaults
  static const int defaultPageSize = 20;
  static const double defaultTaxRate = 0.18; // 18%
  static const double defaultTipPercentage = 0.10; // 10%
  
  // Storage Paths
  static const String profileImagePath = 'profile_images';
  static const String menuItemImagePath = 'menu_item_images';
  static const String restaurantImagePath = 'restaurant_images';
  
  // Preferences Keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLanguage = 'language';
  static const String prefNotifications = 'notifications';
  static const String prefLastRestaurant = 'last_restaurant';
  static const String prefLastTable = 'last_table';
  
  // Time Constants
  static const int sessionTimeoutMinutes = 30;
  static const int orderRefreshIntervalSeconds = 15;
  static const int paymentTimeoutSeconds = 300; // 5 minutes
  
  // Error Messages
  static const String errorNetworkUnavailable = 'Network unavailable. Please check your connection.';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorAuthFailed = 'Authentication failed. Please check your credentials.';
  static const String errorPaymentFailed = 'Payment processing failed. Please try again.';
} 