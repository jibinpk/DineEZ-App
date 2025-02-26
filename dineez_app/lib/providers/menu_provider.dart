import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';
import '../services/firestore_service.dart';

// Reuse the firestore service provider from restaurant_provider.dart
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Menu items for a restaurant provider
final menuItemsProvider = FutureProvider.family<List<MenuItemModel>, String>((ref, restaurantId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getMenuItems(restaurantId);
});

// Menu items by category provider
final menuItemsByCategoryProvider = FutureProvider.family<List<MenuItemModel>, ({String restaurantId, String category})>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getMenuItems(params.restaurantId, category: params.category);
});

// Menu item by ID provider
final menuItemByIdProvider = FutureProvider.family<MenuItemModel?, ({String restaurantId, String menuItemId})>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getMenuItemById(params.restaurantId, params.menuItemId);
});

// Menu state for operations
class MenuState {
  final bool isLoading;
  final String? errorMessage;
  final List<MenuItemModel> menuItems;
  final MenuItemModel? currentMenuItem;
  final List<String> categories;
  
  MenuState({
    this.isLoading = false,
    this.errorMessage,
    this.menuItems = const [],
    this.currentMenuItem,
    this.categories = const [],
  });
  
  MenuState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<MenuItemModel>? menuItems,
    MenuItemModel? currentMenuItem,
    List<String>? categories,
  }) {
    return MenuState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      menuItems: menuItems ?? this.menuItems,
      currentMenuItem: currentMenuItem ?? this.currentMenuItem,
      categories: categories ?? this.categories,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final FirestoreService _firestoreService;
  
  MenuNotifier(this._firestoreService) : super(MenuState());
  
  // Load all menu items for a restaurant
  Future<void> loadMenuItems(String restaurantId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final menuItems = await _firestoreService.getMenuItems(restaurantId);
      
      // Extract unique categories
      final Set<String> categorySet = {};
      for (final item in menuItems) {
        categorySet.add(item.category);
      }
      
      state = state.copyWith(
        isLoading: false,
        menuItems: menuItems,
        categories: categorySet.toList()..sort(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Load menu items by category
  Future<void> loadMenuItemsByCategory(String restaurantId, String category) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final menuItems = await _firestoreService.getMenuItems(restaurantId, category: category);
      
      state = state.copyWith(
        isLoading: false,
        menuItems: menuItems,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Load a menu item by ID
  Future<void> loadMenuItem(String restaurantId, String menuItemId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final menuItem = await _firestoreService.getMenuItemById(restaurantId, menuItemId);
      
      state = state.copyWith(
        isLoading: false,
        currentMenuItem: menuItem,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Create a new menu item
  Future<MenuItemModel?> createMenuItem(String restaurantId, MenuItemModel menuItem) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final docRef = await _firestoreService.createMenuItem(restaurantId, menuItem);
      
      // Get the created menu item with the ID
      final createdMenuItem = menuItem.copyWith(id: docRef.id);
      
      // Update the menu items list and check if we need to add a new category
      final updatedMenuItems = [...state.menuItems, createdMenuItem];
      final updatedCategories = state.categories.contains(menuItem.category)
          ? state.categories
          : [...state.categories, menuItem.category]..sort();
      
      state = state.copyWith(
        isLoading: false,
        menuItems: updatedMenuItems,
        categories: updatedCategories,
        currentMenuItem: createdMenuItem,
      );
      
      return createdMenuItem;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
  
  // Update a menu item
  Future<bool> updateMenuItem(String restaurantId, String menuItemId, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await _firestoreService.updateMenuItem(restaurantId, menuItemId, data);
      
      // Find and update the menu item in our local state
      final updatedMenuItems = state.menuItems.map((item) {
        if (item.id == menuItemId) {
          // Create an updated menu item - note that this is a simplified approach
          // In a real app, you'd want to properly handle all fields
          return item.copyWith(
            name: data['name'] ?? item.name,
            description: data['description'] ?? item.description,
            price: data['price'] != null ? (data['price'] as num).toDouble() : item.price,
            category: data['category'] ?? item.category,
            image: data['image'] ?? item.image,
            isAvailable: data['isAvailable'] ?? item.isAvailable,
            isVegetarian: data['isVegetarian'] ?? item.isVegetarian,
            isVegan: data['isVegan'] ?? item.isVegan,
            isGlutenFree: data['isGlutenFree'] ?? item.isGlutenFree,
            isSpicy: data['isSpicy'] ?? item.isSpicy,
            isFeatured: data['isFeatured'] ?? item.isFeatured,
          );
        }
        return item;
      }).toList();
      
      // Check if we need to update categories due to a category change
      Set<String> categorySet = {};
      for (final item in updatedMenuItems) {
        categorySet.add(item.category);
      }
      
      // If the current menu item is the one we're updating, update it
      MenuItemModel? updatedCurrentMenuItem = state.currentMenuItem;
      if (state.currentMenuItem?.id == menuItemId) {
        final currentItem = state.currentMenuItem!;
        updatedCurrentMenuItem = currentItem.copyWith(
          name: data['name'] ?? currentItem.name,
          description: data['description'] ?? currentItem.description,
          price: data['price'] != null ? (data['price'] as num).toDouble() : currentItem.price,
          category: data['category'] ?? currentItem.category,
          image: data['image'] ?? currentItem.image,
          isAvailable: data['isAvailable'] ?? currentItem.isAvailable,
          isVegetarian: data['isVegetarian'] ?? currentItem.isVegetarian,
          isVegan: data['isVegan'] ?? currentItem.isVegan,
          isGlutenFree: data['isGlutenFree'] ?? currentItem.isGlutenFree,
          isSpicy: data['isSpicy'] ?? currentItem.isSpicy,
          isFeatured: data['isFeatured'] ?? currentItem.isFeatured,
        );
      }
      
      state = state.copyWith(
        isLoading: false,
        menuItems: updatedMenuItems,
        categories: categorySet.toList()..sort(),
        currentMenuItem: updatedCurrentMenuItem,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Delete a menu item
  Future<bool> deleteMenuItem(String restaurantId, String menuItemId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await _firestoreService.deleteMenuItem(restaurantId, menuItemId);
      
      // Remove the item from our local state
      final updatedMenuItems = state.menuItems.where((item) => item.id != menuItemId).toList();
      
      // Recalculate categories
      Set<String> categorySet = {};
      for (final item in updatedMenuItems) {
        categorySet.add(item.category);
      }
      
      state = state.copyWith(
        isLoading: false,
        menuItems: updatedMenuItems,
        categories: categorySet.toList()..sort(),
        currentMenuItem: state.currentMenuItem?.id == menuItemId ? null : state.currentMenuItem,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Toggle menu item availability
  Future<bool> toggleMenuItemAvailability(String restaurantId, String menuItemId) async {
    try {
      // Find the current availability status
      final menuItem = state.menuItems.firstWhere(
        (item) => item.id == menuItemId,
        orElse: () => throw Exception('Menu item not found'),
      );
      
      // Toggle the availability
      final newAvailability = !menuItem.isAvailable;
      
      return await updateMenuItem(
        restaurantId, 
        menuItemId, 
        {'isAvailable': newAvailability},
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Get featured menu items
  List<MenuItemModel> getFeaturedItems() {
    return state.menuItems.where((item) => item.isFeatured).toList();
  }
  
  // Get menu items by category
  List<MenuItemModel> getItemsByCategory(String category) {
    return state.menuItems.where((item) => item.category == category).toList();
  }
  
  // Clear the current menu item selection
  void clearCurrentMenuItem() {
    state = state.copyWith(currentMenuItem: null);
  }
}

// Menu notifier provider
final menuProvider = StateNotifierProvider<MenuNotifier, MenuState>((ref) {
  return MenuNotifier(ref.watch(firestoreServiceProvider));
}); 