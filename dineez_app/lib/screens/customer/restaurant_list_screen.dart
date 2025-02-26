import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../models/restaurant_model.dart';
import '../../providers/providers.dart';
import '../../utils/validators.dart';

class RestaurantListScreen extends ConsumerStatefulWidget {
  const RestaurantListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends ConsumerState<RestaurantListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedCuisines = {};
  RestaurantStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    ref.read(logInfoProvider)('Restaurant List Screen Viewed', source: 'RestaurantListScreen');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter restaurants based on search query and filters
  List<RestaurantModel> _filterRestaurants(List<RestaurantModel> restaurants) {
    return restaurants.where((restaurant) {
      // Filter by search query
      final matchesSearch = _searchQuery.isEmpty || 
          restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          restaurant.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Filter by cuisine type
      final matchesCuisine = _selectedCuisines.isEmpty || 
          (restaurant.cuisineTypes != null && 
           restaurant.cuisineTypes!.any((cuisine) => _selectedCuisines.contains(cuisine)));
      
      // Filter by status
      final matchesStatus = _selectedStatus == null || restaurant.status == _selectedStatus;
      
      return matchesSearch && matchesCuisine && matchesStatus;
    }).toList();
  }

  // Extract all unique cuisine types from restaurants
  Set<String> _extractCuisineTypes(List<RestaurantModel> restaurants) {
    final Set<String> cuisines = {};
    for (final restaurant in restaurants) {
      if (restaurant.cuisineTypes != null) {
        cuisines.addAll(restaurant.cuisineTypes!);
      }
    }
    return cuisines;
  }

  @override
  Widget build(BuildContext context) {
    // Watch the restaurants data
    final restaurantsAsync = ref.watch(allRestaurantsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Only show filter dialog if we have restaurants
              if (restaurantsAsync.hasValue) {
                _showFilterDialog(context, _extractCuisineTypes(restaurantsAsync.value!));
              }
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
                hintText: 'Search restaurants...',
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
          
          // Filter chips for selected cuisines
          if (_selectedCuisines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _selectedCuisines.map((cuisine) => 
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(cuisine),
                        onDeleted: () {
                          setState(() {
                            _selectedCuisines.remove(cuisine);
                          });
                        },
                      ),
                    )
                  ).toList(),
                ),
              ),
            ),
          
          // Restaurant list
          Expanded(
            child: restaurantsAsync.when(
              data: (restaurants) {
                final filteredRestaurants = _filterRestaurants(restaurants);
                
                if (filteredRestaurants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No restaurants found',
                          style: Theme.of(context).textTheme.headlineSmall,
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
                
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredRestaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = filteredRestaurants[index];
                    return _buildRestaurantCard(context, restaurant);
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
                      'Failed to load restaurants',
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
                        ref.refresh(allRestaurantsProvider);
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
    );
  }

  Widget _buildRestaurantCard(BuildContext context, RestaurantModel restaurant) {
    return GestureDetector(
      onTap: () {
        // Navigate to restaurant details
        Navigator.pushNamed(
          context, 
          AppConstants.routeRestaurantDetails,
          arguments: restaurant.id,
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image
            AspectRatio(
              aspectRatio: 1.5,
              child: restaurant.logo != null && restaurant.logo!.isNotEmpty
                ? Image.network(
                    restaurant.logo!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.restaurant, size: 50),
                      ),
                  )
                : Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.restaurant, size: 50),
                  ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant name
                    Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Cuisine types
                    if (restaurant.cuisineTypes != null && restaurant.cuisineTypes!.isNotEmpty)
                      Text(
                        restaurant.cuisineTypes!.join(', '),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                    const SizedBox(height: 4),
                    
                    // Status indicator
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
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, Set<String> availableCuisines) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Filter Restaurants'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuisine Types',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: availableCuisines.map((cuisine) => 
                      FilterChip(
                        label: Text(cuisine),
                        selected: _selectedCuisines.contains(cuisine),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCuisines.add(cuisine);
                            } else {
                              _selectedCuisines.remove(cuisine);
                            }
                          });
                        },
                      )
                    ).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedStatus == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Open'),
                        selected: _selectedStatus == RestaurantStatus.active,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected 
                                ? RestaurantStatus.active 
                                : null;
                          });
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Closed'),
                        selected: _selectedStatus == RestaurantStatus.inactive,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected 
                                ? RestaurantStatus.inactive 
                                : null;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Clear all filters
                  this.setState(() {
                    _selectedCuisines = {};
                    _selectedStatus = null;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
              TextButton(
                onPressed: () {
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
} 