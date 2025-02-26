import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_item_model.dart';
import '../../models/table_model.dart';
import '../../providers/providers.dart';

class RestaurantDetailsScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  
  const RestaurantDetailsScreen({
    Key? key, 
    required this.restaurantId,
  }) : super(key: key);

  @override
  ConsumerState<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends ConsumerState<RestaurantDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load restaurant data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(restaurantProvider.notifier).loadRestaurant(widget.restaurantId);
      ref.read(logInfoProvider)('Restaurant Details Screen Viewed', 
          source: 'RestaurantDetailsScreen', 
          data: {'restaurantId': widget.restaurantId});
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantAsync = ref.watch(allRestaurantsProvider).whenData(
      (restaurants) {
        try {
          return restaurants.firstWhere((r) => r.id == widget.restaurantId);
        } catch (e) {
          return null;
        }
      }
    );
    final restaurantState = ref.watch(restaurantProvider);
    
    return Scaffold(
      body: restaurantAsync.when(
        data: (restaurant) {
          if (restaurant == null) {
            return const Center(
              child: Text('Restaurant not found'),
            );
          }
          
          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      restaurant.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 3.0,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                    background: restaurant.logo != null && restaurant.logo!.isNotEmpty
                      ? Image.network(
                          restaurant.logo!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            Container(
                              color: Colors.grey.shade800,
                              child: const Center(
                                child: Icon(Icons.restaurant, size: 64, color: Colors.white),
                              ),
                            ),
                        )
                      : Container(
                          color: Colors.grey.shade800,
                          child: const Center(
                            child: Icon(Icons.restaurant, size: 64, color: Colors.white),
                          ),
                        ),
                  ),
                  actions: [
                    if (restaurant.status == RestaurantStatus.active)
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          Navigator.pushNamed(
                            context, 
                            AppConstants.routeScanQR,
                            arguments: {'restaurantId': restaurant.id},
                          );
                        },
                        tooltip: 'Scan QR code to order',
                      ),
                    IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
                        // Implement favorite functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to favorites'),
                          ),
                        );
                      },
                      tooltip: 'Add to favorites',
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _buildRestaurantHeader(context, restaurant),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'MENU'),
                        Tab(text: 'INFO'),
                        Tab(text: 'TABLES'),
                      ],
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).primaryColor,
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildMenuTab(context, restaurant),
                _buildInfoTab(context, restaurant),
                _buildTablesTab(context, restaurant),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Failed to load restaurant details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(restaurantProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: restaurantAsync.hasValue && restaurantAsync.value != null
          ? FloatingActionButton.extended(
              onPressed: () {
                // Navigate to menu screen
                Navigator.pushNamed(
                  context, 
                  AppConstants.routeMenu,
                  arguments: {'restaurantId': widget.restaurantId},
                );
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Text('Full Menu'),
            )
          : null,
    );
  }
  
  Widget _buildRestaurantHeader(BuildContext context, RestaurantModel restaurant) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and cuisine types
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: restaurant.status == RestaurantStatus.active
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  restaurant.status == RestaurantStatus.active ? 'Open' : 'Closed',
                  style: TextStyle(
                    color: restaurant.status == RestaurantStatus.active
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (restaurant.cuisineTypes != null && restaurant.cuisineTypes!.isNotEmpty)
                Expanded(
                  child: Text(
                    restaurant.cuisineTypes!.join(' • '),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Description
          Text(
            restaurant.description,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          
          // Contact info
          Row(
            children: [
              if (restaurant.phone != null && restaurant.phone!.isNotEmpty)
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.phone,
                    text: restaurant.phone!,
                    onTap: () {
                      // Implement phone call
                    },
                  ),
                ),
              if (restaurant.email != null && restaurant.email!.isNotEmpty)
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.email,
                    text: restaurant.email!,
                    onTap: () {
                      // Implement email
                    },
                  ),
                ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.location_on,
                  text: 'View Map',
                  onTap: () {
                    // Implement map view
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuTab(BuildContext context, RestaurantModel restaurant) {
    final menuItemsAsync = ref.watch(menuItemsProvider(restaurant.id));
    
    return menuItemsAsync.when(
      data: (menuItems) {
        if (menuItems.isEmpty) {
          return const Center(
            child: Text('No menu items available'),
          );
        }
        
        // Group menu items by category
        final Map<String, List<MenuItemModel>> categorizedItems = {};
        for (final item in menuItems) {
          if (!categorizedItems.containsKey(item.category)) {
            categorizedItems[item.category] = [];
          }
          categorizedItems[item.category]!.add(item);
        }
        
        // Get category names and sort them
        final categories = categorizedItems.keys.toList()..sort();
        
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final items = categorizedItems[category]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0) const SizedBox(height: 16),
                
                // Category header
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Category items
                ...items.take(3).map((item) => _buildMenuItem(context, item)).toList(),
                
                // Show more button if there are more than 3 items
                if (items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextButton(
                      onPressed: () {
                        // Navigate to category items
                        Navigator.pushNamed(
                          context, 
                          AppConstants.routeMenu,
                          arguments: {
                            'restaurantId': restaurant.id,
                            'category': category,
                          },
                        );
                      },
                      child: Text('${items.length - 3} more items'),
                    ),
                  ),
                
                const Divider(),
              ],
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('Failed to load menu: ${error.toString()}'),
      ),
    );
  }
  
  Widget _buildMenuItem(BuildContext context, MenuItemModel item) {
    final priceFormatter = NumberFormat.currency(symbol: '\$');
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        item.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        item.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            priceFormatter.format(item.price),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (item.isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Available',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Unavailable',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        // Navigate to item details
        Navigator.pushNamed(
          context, 
          AppConstants.routeMenu,
          arguments: {
            'restaurantId': item.restaurantId,
            'menuItemId': item.id,
          },
        );
      },
    );
  }
  
  Widget _buildInfoTab(BuildContext context, RestaurantModel restaurant) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Address
        _buildInfoSection(
          title: 'Address',
          content: restaurant.address,
          icon: Icons.location_on,
        ),
        const SizedBox(height: 16),
        
        // Business hours
        _buildInfoSection(
          title: 'Business Hours',
          content: _formatBusinessHours(restaurant.businessHours),
          icon: Icons.access_time,
        ),
        const SizedBox(height: 16),
        
        // Cuisine types
        if (restaurant.cuisineTypes != null && restaurant.cuisineTypes!.isNotEmpty)
          _buildInfoSection(
            title: 'Cuisine Types',
            content: restaurant.cuisineTypes!.join(', '),
            icon: Icons.restaurant,
          ),
        if (restaurant.cuisineTypes != null && restaurant.cuisineTypes!.isNotEmpty)
          const SizedBox(height: 16),
        
        // About
        _buildInfoSection(
          title: 'About',
          content: restaurant.description,
          icon: Icons.info,
        ),
      ],
    );
  }
  
  Widget _buildInfoSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Text(
            content,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
  
  String _formatBusinessHours(Map<String, dynamic>? businessHours) {
    if (businessHours == null || businessHours.isEmpty) {
      return 'Hours not available';
    }
    
    final StringBuffer buffer = StringBuffer();
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    
    for (final day in days) {
      if (businessHours.containsKey(day)) {
        final hours = businessHours[day];
        if (hours is Map<String, dynamic>) {
          final open = hours['open'];
          final close = hours['close'];
          if (open != null && close != null) {
            buffer.writeln('$day: $open - $close');
          } else {
            buffer.writeln('$day: Closed');
          }
        } else {
          buffer.writeln('$day: Closed');
        }
      } else {
        buffer.writeln('$day: Closed');
      }
    }
    
    return buffer.toString();
  }
  
  Widget _buildTablesTab(BuildContext context, RestaurantModel restaurant) {
    final tableState = ref.watch(restaurantProvider);
    
    if (tableState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (tableState.tables.isEmpty) {
      return const Center(
        child: Text('No tables available'),
      );
    }
    
    // Group tables by status
    final availableTables = tableState.tables.where((table) => !table.isOccupied && !table.isReserved).toList();
    final occupiedTables = tableState.tables.where((table) => table.isOccupied).toList();
    final reservedTables = tableState.tables.where((table) => !table.isOccupied && table.isReserved).toList();
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Available tables
        _buildTableSection(
          title: 'Available Tables',
          tables: availableTables,
          icon: Icons.check_circle,
          iconColor: Colors.green,
        ),
        const SizedBox(height: 16),
        
        // Reserved tables
        _buildTableSection(
          title: 'Reserved Tables',
          tables: reservedTables,
          icon: Icons.access_time,
          iconColor: Colors.orange,
        ),
        const SizedBox(height: 16),
        
        // Occupied tables
        _buildTableSection(
          title: 'Occupied Tables',
          tables: occupiedTables,
          icon: Icons.people,
          iconColor: Colors.red,
        ),
      ],
    );
  }
  
  Widget _buildTableSection({
    required String title,
    required List<TableModel> tables,
    required IconData icon,
    required Color iconColor,
  }) {
    if (tables.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 28.0),
            child: Text('None'),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tables.map((table) => 
            Chip(
              label: Text('Table ${table.tableNumber}'),
              backgroundColor: iconColor.withOpacity(0.1),
              avatar: Icon(icon, size: 16, color: iconColor),
            ),
          ).toList(),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
} 