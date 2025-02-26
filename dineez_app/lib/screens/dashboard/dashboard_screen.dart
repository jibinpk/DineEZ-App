import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../providers/providers.dart';
import '../../models/restaurant_model.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_display.dart';
import '../../providers/order_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;
  
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  @override
  void initState() {
    super.initState();
    
    // Log screen viewing
    ref.read(logInfoProvider)('Dashboard screen viewed', source: 'DashboardScreen');
    
    // Initialize necessary data
    _loadInitialData();
  }
  
  Future<void> _loadInitialData() async {
    // Set global loading state
    ref.read(globalLoadingProvider.notifier).state = true;
    
    try {
      // Load user data if needed
      final userData = await ref.read(currentUserProvider.future);
      
      if (userData == null) {
        // Handle missing user data
        ref.read(globalErrorProvider.notifier).state = 'Unable to load user data';
        return;
      }
      
      // Load list of restaurants
      await ref.read(allRestaurantsProvider.future);
      
      // Clear any previous error
      ref.read(globalErrorProvider.notifier).state = null;
    } catch (e) {
      // Log error
      ref.read(logErrorProvider)('Error loading dashboard data', 
          source: 'DashboardScreen', data: e);
      
      // Set error message
      ref.read(globalErrorProvider.notifier).state = 'Error loading data: $e';
    } finally {
      // Clear loading state
      ref.read(globalLoadingProvider.notifier).state = false;
    }
  }
  
  // Handle sign out
  Future<void> _signOut() async {
    try {
      ref.read(globalLoadingProvider.notifier).state = true;
      
      // Log the action
      ref.read(logInfoProvider)('User signing out', source: 'DashboardScreen');
      
      // Sign out using auth provider
      await ref.read(authProvider.notifier).signOut();
      
      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppConstants.routeLogin);
      }
    } catch (e) {
      ref.read(logErrorProvider)('Error signing out', source: 'DashboardScreen', data: e);
      ref.read(globalErrorProvider.notifier).state = 'Error signing out: $e';
    } finally {
      ref.read(globalLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for theme changes
    final themeState = ref.watch(themeProvider);
    
    // Watch for network connectivity
    final isOnline = ref.watch(isOnlineProvider);
    
    // Listen to the current user
    final userAsync = ref.watch(currentUserProvider);
    
    // Listen to restaurants data
    final restaurantsAsync = ref.watch(allRestaurantsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('DineEZ Dashboard'),
        actions: [
          // Theme toggle
          IconButton(
            icon: Icon(themeState.themeMode == ThemeMode.dark 
                ? Icons.light_mode 
                : Icons.dark_mode),
            onPressed: () => ref.read(themeProvider.notifier).toggleThemeMode(),
          ),
          
          // User profile
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeProfile),
          ),
        ],
      ),
      
      // Main body content
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('User not authenticated'),
            );
          }
          
          // Build main content based on selected tab
          Widget content;
          
          switch (_currentIndex) {
            case 0: // Home tab
              content = _buildCustomerDashboard(context, user);
              break;
            case 1: // Restaurants tab
              content = _buildRestaurantsTab(restaurantsAsync);
              break;
            case 2: // Orders tab
              content = _buildOrdersTab();
              break;
            case 3: // Settings tab
              content = _buildSettingsTab();
              break;
            default:
              content = const Center(child: Text('Unknown tab'));
          }
          
          return Column(
            children: [
              // Offline indicator
              if (!isOnline)
                Container(
                  width: double.infinity,
                  color: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text(
                    'You are offline. Some features may not be available.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                
              // Main content
              Expanded(
                child: content,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
      
      // Floating action button for QR scanning
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppConstants.routeQrScanner),
        child: const Icon(Icons.qr_code_scanner),
      ),
      
      // Bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Restaurants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  
  Widget _buildCustomerDashboard(BuildContext context, UserModel? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(context, user),
          const SizedBox(height: 24.0),
          _buildSectionHeader(context, 'Quick Actions'),
          const SizedBox(height: 16.0),
          _buildQuickActionsGrid(context),
          const SizedBox(height: 24.0),
          _buildRecentOrdersSection(context),
          const SizedBox(height: 24.0),
          _buildSectionHeader(context, 'Explore Restaurants'),
          const SizedBox(height: 16.0),
          _buildRestaurantList(context),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeCard(BuildContext context, UserModel? user) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${user?.name}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan a QR code to start ordering, or browse restaurants near you.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeQrScanner),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildQuickActionsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildActionCard(
          'Find Restaurants',
          Icons.restaurant,
          Colors.blue,
          () => Navigator.pushNamed(context, AppConstants.routeRestaurantList),
          context,
        ),
        _buildActionCard(
          'Scan QR Code',
          Icons.qr_code_scanner,
          Colors.orange,
          () => Navigator.pushNamed(context, AppConstants.routeQrScanner),
          context,
        ),
        _buildActionCard(
          'Order History',
          Icons.history,
          Colors.purple,
          () => Navigator.pushNamed(context, AppConstants.routeOrderHistory),
          context,
        ),
        _buildActionCard(
          'My Profile',
          Icons.person,
          Colors.teal,
          () => Navigator.pushNamed(context, AppConstants.routeProfile),
          context,
        ),
      ],
    );
  }
  
  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRestaurantsTab(AsyncValue<List<RestaurantModel>> restaurantsAsync) {
    return restaurantsAsync.when(
      data: (restaurants) {
        if (restaurants.isEmpty) {
          return const Center(
            child: Text('No restaurants found'),
          );
        }
        return ListView.builder(
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return ListTile(
              leading: restaurant.logo != null
                ? Image.network(
                    restaurant.logo!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.restaurant),
              title: Text(restaurant.name),
              subtitle: Text(restaurant.description),
              trailing: restaurant.isActive
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.error, color: Colors.red),
              onTap: () => Navigator.pushNamed(
                context,
                AppConstants.routeRestaurantDetails,
                arguments: restaurant,
              ),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stackTrace) => ErrorDisplay(
        message: 'Error loading restaurants: $error',
        onRetry: () => ref.refresh(allRestaurantsProvider),
      ),
    );
  }
  
  Widget _buildOrdersTab() {
    final ordersAsync = ref.watch(orderHistoryProvider);
    
    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return const Center(
            child: Text('No orders found'),
          );
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return ListTile(
              title: Text('Order #${order.orderNumber}'),
              subtitle: Text('${order.restaurantName} - ${order.status.name}'),
              trailing: Text('\$${order.totalAmount.toStringAsFixed(2)}'),
              onTap: () => Navigator.pushNamed(
                context,
                AppConstants.routeOrderDetails,
                arguments: {
                  'restaurantId': order.restaurantId,
                  'orderId': order.id,
                },
              ),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stackTrace) => ErrorDisplay(
        message: 'Error loading orders: $error',
        onRetry: () => ref.refresh(orderHistoryProvider),
      ),
    );
  }
  
  Widget _buildSettingsTab() {
    return ListView(
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile'),
          onTap: () => Navigator.pushNamed(context, AppConstants.routeProfile),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          onTap: () {
            // TODO: Implement notifications settings
          },
        ),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: const Text('Theme'),
          trailing: Switch(
            value: ref.watch(themeProvider).themeMode == ThemeMode.dark,
            onChanged: (_) => ref.read(themeProvider.notifier).toggleThemeMode(),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign Out'),
          onTap: _signOut,
        ),
      ],
    );
  }
  
  Widget _buildRecentOrdersSection(BuildContext context) {
    final recentOrdersAsync = ref.watch(orderHistoryProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Recent Orders'),
        const SizedBox(height: 16),
        recentOrdersAsync.when(
          data: (orders) {
            if (orders.isEmpty) {
              return const Center(
                child: Text('No recent orders'),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.take(3).length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text('Order #${order.orderNumber}'),
                  subtitle: Text('${order.restaurantName} - ${order.status.name}'),
                  trailing: Text('\$${order.totalAmount.toStringAsFixed(2)}'),
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppConstants.routeOrderDetails,
                    arguments: {
                      'restaurantId': order.restaurantId,
                      'orderId': order.id,
                    },
                  ),
                );
              },
            );
          },
          loading: () => const LoadingIndicator(),
          error: (error, stackTrace) => ErrorDisplay(
            message: 'Error loading recent orders: $error',
            onRetry: () => ref.refresh(orderHistoryProvider),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRestaurantList(BuildContext context) {
    final restaurantsAsync = ref.watch(allRestaurantsProvider);
    
    return restaurantsAsync.when(
      data: (restaurants) {
        if (restaurants.isEmpty) {
          return const Center(
            child: Text('No restaurants found'),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: restaurants.take(5).length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return ListTile(
              leading: restaurant.logo != null
                ? Image.network(
                    restaurant.logo!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.restaurant),
              title: Text(restaurant.name),
              subtitle: Text(restaurant.description),
              trailing: restaurant.isActive
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.error, color: Colors.red),
              onTap: () => Navigator.pushNamed(
                context,
                AppConstants.routeRestaurantDetails,
                arguments: restaurant,
              ),
            );
          },
        );
      },
      loading: () => const LoadingIndicator(),
      error: (error, stackTrace) => ErrorDisplay(
        message: 'Error loading restaurants: $error',
        onRetry: () => ref.refresh(allRestaurantsProvider),
      ),
    );
  }
} 