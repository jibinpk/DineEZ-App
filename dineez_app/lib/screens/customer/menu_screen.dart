import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../models/menu_item_model.dart';
import '../../providers/providers.dart';
import '../../services/firestore_service.dart';

// Define necessary providers if not exported by providers.dart
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final menuItemByIdProvider = FutureProvider.family<MenuItemModel?, ({String restaurantId, String menuItemId})>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getMenuItemById(params.restaurantId, params.menuItemId);
});

// Simple cart provider for demo purposes
class CartState {
  final Map<String, CartItem> items;
  
  CartState({this.items = const {}});
  
  double get total => items.values.fold(0, (sum, item) => sum + (item.menuItem.effectivePrice * item.quantity));
  
  int get itemCount => items.values.fold(0, (sum, item) => sum + item.quantity);
  
  CartState copyWith({Map<String, CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartItem {
  final MenuItemModel menuItem;
  final int quantity;
  
  CartItem({required this.menuItem, required this.quantity});
  
  double get subtotal => menuItem.effectivePrice * quantity;
  
  CartItem copyWith({MenuItemModel? menuItem, int? quantity}) {
    return CartItem(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());
  
  void addItem(MenuItemModel menuItem, int quantity) {
    final currentItems = Map<String, CartItem>.from(state.items);
    
    if (currentItems.containsKey(menuItem.id)) {
      // Update existing item
      final currentItem = currentItems[menuItem.id]!;
      currentItems[menuItem.id] = currentItem.copyWith(
        quantity: currentItem.quantity + quantity
      );
    } else {
      // Add new item
      currentItems[menuItem.id] = CartItem(
        menuItem: menuItem,
        quantity: quantity,
      );
    }
    
    state = state.copyWith(items: currentItems);
  }
  
  void removeItem(String menuItemId) {
    final currentItems = Map<String, CartItem>.from(state.items);
    currentItems.remove(menuItemId);
    state = state.copyWith(items: currentItems);
  }
  
  void updateQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      removeItem(menuItemId);
      return;
    }
    
    final currentItems = Map<String, CartItem>.from(state.items);
    if (currentItems.containsKey(menuItemId)) {
      final currentItem = currentItems[menuItemId]!;
      currentItems[menuItemId] = currentItem.copyWith(quantity: quantity);
      state = state.copyWith(items: currentItems);
    }
  }
  
  void clearCart() {
    state = CartState();
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class MenuScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final String? category;
  final String? menuItemId;
  
  const MenuScreen({
    Key? key, 
    required this.restaurantId,
    this.category,
    this.menuItemId,
  }) : super(key: key);

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showVegetarianOnly = false;
  bool _showVeganOnly = false;
  
  @override
  void initState() {
    super.initState();
    
    // Set initial selected category if provided
    _selectedCategory = widget.category;
    
    // Log screen view
    ref.read(logInfoProvider)('Menu Screen Viewed', 
        source: 'MenuScreen', 
        data: {
          'restaurantId': widget.restaurantId,
          'category': widget.category,
          'menuItemId': widget.menuItemId
        });
    
    // If specific menu item was requested, show it
    if (widget.menuItemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMenuItemDetails(widget.menuItemId!);
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _showMenuItemDetails(String menuItemId) {
    final params = (restaurantId: widget.restaurantId, menuItemId: menuItemId);
    
    // Read menu item details
    ref.read(menuItemByIdProvider(params)).whenData((menuItem) {
      if (menuItem != null) {
        _showItemDetailsDialog(menuItem);
      }
    });
  }
  
  List<MenuItemModel> _filterMenuItems(List<MenuItemModel> menuItems) {
    return menuItems.where((item) {
      // Apply category filter
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      
      // Apply search filter
      final matchesSearch = _searchQuery.isEmpty || 
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Apply dietary filters
      final matchesDietary = 
          (!_showVegetarianOnly || item.isVegetarian) &&
          (!_showVeganOnly || item.isVegan);
          
      return matchesCategory && matchesSearch && matchesDietary;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    // Watch for the restaurant to get its name from the restaurant ID
    final restaurantAsync = ref.watch(restaurantProvider);
    final restaurantName = restaurantAsync.isLoading 
        ? 'Menu' 
        : restaurantAsync.errorMessage != null 
            ? 'Menu' 
            : restaurantAsync.currentRestaurant?.name ?? 'Menu';
    
    // Watch for menu items
    final menuItemsAsync = ref.watch(menuItemsProvider(widget.restaurantId));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantName),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show the filter dialog
              _showFiltersDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
                suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Category chips
          menuItemsAsync.when(
            data: (menuItems) {
              // Extract unique categories
              final Set<String> categories = {};
              for (final item in menuItems) {
                categories.add(item.category);
              }
              
              final sortedCategories = categories.toList()..sort();
              
              return SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = null;
                          });
                        },
                      ),
                    ),
                    ...sortedCategories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: _selectedCategory == category,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = selected ? category : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 40),
            error: (_, __) => const SizedBox(height: 40),
          ),
          
          // Menu items list
          Expanded(
            child: menuItemsAsync.when(
              data: (menuItems) {
                final filteredItems = _filterMenuItems(menuItems);
                
                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No menu items found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Try adjusting your filters or search query',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildMenuItemCard(context, item);
                  },
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
                      'Failed to load menu items',
                      style: Theme.of(context).textTheme.titleLarge,
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
                        ref.refresh(menuItemsProvider(widget.restaurantId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to cart
          Navigator.pushNamed(
            context, 
            AppConstants.routeCart,
            arguments: {'restaurantId': widget.restaurantId},
          );
        },
        icon: const Icon(Icons.shopping_cart),
        label: const Text('View Cart'),
      ),
    );
  }
  
  Widget _buildMenuItemCard(BuildContext context, MenuItemModel item) {
    final priceFormatter = NumberFormat.currency(symbol: '\$');
    
    return InkWell(
      onTap: () => _showItemDetailsDialog(item),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: item.image != null && item.image!.isNotEmpty
                  ? Image.network(
                      item.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.restaurant, size: 40),
                        ),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.restaurant, size: 40),
                    ),
              ),
              const SizedBox(width: 16),
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Item name
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        // Dietary badges
                        if (item.isVegetarian)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.eco, color: Colors.green, size: 16),
                          ),
                        if (item.isVegan)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.spa, color: Colors.green, size: 16),
                          ),
                        if (item.isGlutenFree)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text('GF', style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Item description
                    Text(
                      item.description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Price and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.hasDiscount)
                              Row(
                                children: [
                                  Text(
                                    priceFormatter.format(item.price),
                                    style: TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      '${item.discountPercentage?.toStringAsFixed(0)}% OFF',
                                      style: TextStyle(
                                        color: Colors.red.shade800,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            Text(
                              priceFormatter.format(item.effectivePrice),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: item.hasDiscount ? 16 : 14,
                                color: item.hasDiscount ? Colors.red.shade700 : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        // Add to cart button
                        item.isAvailable 
                          ? ElevatedButton.icon(
                              onPressed: () {
                                // Add to cart logic
                                _addToCart(item);
                              },
                              icon: const Icon(Icons.add_shopping_cart, size: 16),
                              label: const Text('Add'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            )
                          : OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text('Unavailable'),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showItemDetailsDialog(MenuItemModel item) {
    final priceFormatter = NumberFormat.currency(symbol: '\$');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Item image
              AspectRatio(
                aspectRatio: 16/9,
                child: item.image != null && item.image!.isNotEmpty
                  ? Image.network(
                      item.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.restaurant, size: 64),
                        ),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.restaurant, size: 64),
                    ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item name
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Dietary badges row
                            Row(
                              children: [
                                if (item.isVegetarian)
                                  Tooltip(
                                    message: 'Vegetarian',
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.eco, color: Colors.green, size: 16),
                                    ),
                                  ),
                                if (item.isVegan)
                                  Tooltip(
                                    message: 'Vegan',
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.spa, color: Colors.green, size: 16),
                                    ),
                                  ),
                                if (item.isGlutenFree)
                                  Tooltip(
                                    message: 'Gluten Free',
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'GF',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (item.isSpicy)
                                  Tooltip(
                                    message: 'Spicy',
                                    child: Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.whatshot, color: Colors.red, size: 16),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Category
                        Text(
                          item.category,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Price section
                        Row(
                          children: [
                            if (item.hasDiscount) ...[
                              Text(
                                priceFormatter.format(item.price),
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.discountPercentage?.toStringAsFixed(0)}% OFF',
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              priceFormatter.format(item.effectivePrice),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: item.hasDiscount ? Colors.red.shade700 : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Description
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Ingredients
                        if (item.ingredients != null && item.ingredients!.isNotEmpty) ...[
                          const Text(
                            'Ingredients',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: item.ingredients!.map((ingredient) {
                              return Chip(
                                label: Text(ingredient),
                                backgroundColor: Colors.grey.shade200,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Preparation time
                        Row(
                          children: [
                            const Icon(Icons.timer, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Preparation time: ${item.preparationTime} minutes',
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Add to cart section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: item.isAvailable
                    ? Row(
                        children: [
                          // Quantity control
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    // Decrement quantity logic
                                  },
                                  icon: const Icon(Icons.remove),
                                  iconSize: 20,
                                ),
                                const SizedBox(
                                  width: 40,
                                  child: Text(
                                    '1',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    // Increment quantity logic
                                  },
                                  icon: const Icon(Icons.add),
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Add to cart button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Add to cart logic
                                _addToCart(item);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Add to Cart'),
                            ),
                          ),
                        ],
                      )
                    : OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Currently Unavailable'),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filters'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dietary Preferences',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Vegetarian Only'),
                  value: _showVegetarianOnly,
                  onChanged: (value) {
                    setState(() {
                      _showVegetarianOnly = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  title: const Text('Vegan Only'),
                  value: _showVeganOnly,
                  onChanged: (value) {
                    setState(() {
                      _showVeganOnly = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Reset filters
                  this.setState(() {
                    _showVegetarianOnly = false;
                    _showVeganOnly = false;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
              TextButton(
                onPressed: () {
                  // Apply changes
                  this.setState(() {
                    _showVegetarianOnly = _showVegetarianOnly;
                    _showVeganOnly = _showVeganOnly;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _addToCart(MenuItemModel item) {
    // Add item to cart with quantity 1
    ref.read(cartProvider.notifier).addItem(item, 1);
    
    // Show confirmation snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart'),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () {
            Navigator.pushNamed(
              context, 
              AppConstants.routeCart,
              arguments: {'restaurantId': widget.restaurantId},
            );
          },
        ),
      ),
    );
  }
} 