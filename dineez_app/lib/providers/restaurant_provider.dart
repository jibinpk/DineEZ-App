import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_model.dart';
import '../services/firestore_service.dart';
import '../models/table_model.dart';

// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// All restaurants provider
final allRestaurantsProvider = FutureProvider<List<RestaurantModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getAllRestaurants();
});

// Restaurant by ID provider
final restaurantByIdProvider = FutureProvider.family<RestaurantModel?, String>((ref, restaurantId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getRestaurantById(restaurantId);
});

// Restaurants by owner provider
final restaurantsByOwnerProvider = FutureProvider.family<List<RestaurantModel>, String>((ref, ownerId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getRestaurantsByOwner(ownerId);
});

// Restaurant state for operations
class RestaurantState {
  final bool isLoading;
  final String? errorMessage;
  final RestaurantModel? currentRestaurant;
  final List<TableModel> tables;
  
  RestaurantState({
    this.isLoading = false,
    this.errorMessage,
    this.currentRestaurant,
    this.tables = const [],
  });
  
  RestaurantState copyWith({
    bool? isLoading,
    String? errorMessage,
    RestaurantModel? currentRestaurant,
    List<TableModel>? tables,
  }) {
    return RestaurantState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      currentRestaurant: currentRestaurant ?? this.currentRestaurant,
      tables: tables ?? this.tables,
    );
  }
}

class RestaurantNotifier extends StateNotifier<RestaurantState> {
  final FirestoreService _firestoreService;
  
  RestaurantNotifier(this._firestoreService) : super(RestaurantState());
  
  // Load a restaurant by ID
  Future<void> loadRestaurant(String restaurantId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final restaurant = await _firestoreService.getRestaurantById(restaurantId);
      
      if (restaurant != null) {
        final tables = await _firestoreService.getTables(restaurantId);
        state = state.copyWith(
          isLoading: false, 
          currentRestaurant: restaurant,
          tables: tables,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Restaurant not found',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Create a new restaurant
  Future<RestaurantModel?> createRestaurant(RestaurantModel restaurant) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final docRef = await _firestoreService.createRestaurant(restaurant);
      
      // Get the created restaurant with the ID
      final createdRestaurant = restaurant.copyWith(id: docRef.id);
      
      state = state.copyWith(
        isLoading: false,
        currentRestaurant: createdRestaurant,
      );
      
      return createdRestaurant;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
  
  // Update restaurant details
  Future<bool> updateRestaurant(String restaurantId, Map<String, dynamic> data) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await _firestoreService.updateRestaurant(restaurantId, data);
      
      // Reload the restaurant data
      await loadRestaurant(restaurantId);
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Create a new table
  Future<TableModel?> createTable(String restaurantId, TableModel table) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final docRef = await _firestoreService.createTable(restaurantId, table);
      
      // Get the created table with the ID
      final createdTable = table.copyWith(id: docRef.id);
      
      // Update the tables list
      final updatedTables = [...state.tables, createdTable];
      
      state = state.copyWith(
        isLoading: false,
        tables: updatedTables,
      );
      
      return createdTable;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
  
  // Update table status
  Future<bool> updateTableStatus(
    String restaurantId, 
    String tableId, 
    {bool? isOccupied, bool? isReserved, String? currentOrderId}
  ) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final updateData = <String, dynamic>{};
      
      if (isOccupied != null) {
        updateData['isOccupied'] = isOccupied;
        if (isOccupied) {
          updateData['occupiedSince'] = DateTime.now();
        } else {
          updateData['occupiedSince'] = null;
          updateData['currentOrderId'] = null;
        }
      }
      
      if (isReserved != null) {
        updateData['isReserved'] = isReserved;
      }
      
      if (currentOrderId != null) {
        updateData['currentOrderId'] = currentOrderId;
      }
      
      await _firestoreService.updateTable(restaurantId, tableId, updateData);
      
      // Reload the tables
      final updatedTables = await _firestoreService.getTables(restaurantId);
      
      state = state.copyWith(
        isLoading: false,
        tables: updatedTables,
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
  
  // Load tables for a restaurant
  Future<void> loadTables(String restaurantId, {bool? isAvailable}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final tables = await _firestoreService.getTables(restaurantId, isAvailable: isAvailable);
      
      state = state.copyWith(
        isLoading: false,
        tables: tables,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

// Restaurant notifier provider
final restaurantProvider = StateNotifierProvider<RestaurantNotifier, RestaurantState>((ref) {
  return RestaurantNotifier(ref.watch(firestoreServiceProvider));
}); 