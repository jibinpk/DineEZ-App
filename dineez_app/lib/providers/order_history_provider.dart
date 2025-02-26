import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'providers.dart';
import 'restaurant_provider.dart';

// Order history provider
final orderHistoryProvider = FutureProvider<List<OrderModel>>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authState = ref.watch(authProvider);
  
  if (authState.user == null) {
    return [];
  }
  
  // Get all restaurants
  final restaurants = await firestoreService.getAllRestaurants();
  
  List<OrderModel> allOrders = [];
  
  // Fetch orders for each restaurant where customerId matches
  for (final restaurant in restaurants) {
    final orders = await firestoreService.getOrders(
      restaurant.id,
      customerId: authState.user!.id,
    );
    
    allOrders.addAll(orders);
  }
  
  // Sort by creation time (newest first)
  allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  
  return allOrders;
}); 