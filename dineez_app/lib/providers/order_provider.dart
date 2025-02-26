import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/menu_item_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

// Reuse the firestore service provider from restaurant_provider.dart
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Orders for a restaurant provider
final restaurantOrdersProvider = FutureProvider.family<List<OrderModel>, String>((ref, restaurantId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getOrders(restaurantId);
});

// Active orders for a restaurant provider (new, preparing, ready)
final activeOrdersProvider = FutureProvider.family<List<OrderModel>, String>((ref, restaurantId) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final orders = await firestoreService.getOrders(restaurantId);
  
  return orders.where((order) => 
    order.status == OrderStatus.new_ || 
    order.status == OrderStatus.preparing || 
    order.status == OrderStatus.ready ||
    order.status == OrderStatus.served
  ).toList();
});

// Order by ID provider
final orderByIdProvider = FutureProvider.family<OrderModel?, ({String restaurantId, String orderId})>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getOrderById(params.restaurantId, params.orderId);
});

// Active order for a table provider
final activeOrderForTableProvider = FutureProvider.family<OrderModel?, ({String restaurantId, String tableId})>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getActiveOrderForTable(params.restaurantId, params.tableId);
});

// Provider for fetching a single order's details
final orderDetailsProvider = FutureProvider.family<OrderModel, Map<String, String>>((ref, params) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getOrderById(params['restaurantId']!, params['orderId']!);
});

// Order state for operations
class OrderState {
  final bool isLoading;
  final String? errorMessage;
  final List<OrderModel> orders;
  final OrderModel? selectedOrder;
  final List<OrderItemModel> cartItems;
  final String? selectedTableId;
  final String? selectedRestaurantId;
  final OrderStatus? filterStatus;
  final bool hasMoreOrders;
  final DocumentSnapshot? lastDocument;
  
  OrderState({
    this.isLoading = false,
    this.errorMessage,
    this.orders = const [],
    this.selectedOrder,
    this.cartItems = const [],
    this.selectedTableId,
    this.selectedRestaurantId,
    this.filterStatus,
    this.hasMoreOrders = true,
    this.lastDocument,
  });
  
  OrderState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<OrderModel>? orders,
    OrderModel? selectedOrder,
    List<OrderItemModel>? cartItems,
    String? selectedTableId,
    String? selectedRestaurantId,
    OrderStatus? filterStatus,
    bool? hasMoreOrders,
    DocumentSnapshot? lastDocument,
  }) {
    return OrderState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      orders: orders ?? this.orders,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      cartItems: cartItems ?? this.cartItems,
      selectedTableId: selectedTableId ?? this.selectedTableId,
      selectedRestaurantId: selectedRestaurantId ?? this.selectedRestaurantId,
      filterStatus: filterStatus ?? this.filterStatus,
      hasMoreOrders: hasMoreOrders ?? this.hasMoreOrders,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
  
  // Calculate cart total
  double get cartTotal {
    return cartItems.fold(0, (total, item) => total + (item.price * item.quantity));
  }
  
  // Check if cart is empty
  bool get isCartEmpty => cartItems.isEmpty;
  
  // Get total items in cart
  int get cartItemCount {
    return cartItems.fold(0, (total, item) => total + item.quantity);
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;
  
  OrderNotifier(this._firestoreService, this._notificationService) : super(OrderState());
  
  // Load orders for a restaurant
  Future<void> loadOrders(String restaurantId, {OrderStatus? status}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final orders = await _firestoreService.getOrders(restaurantId, status: status);
      
      state = state.copyWith(
        isLoading: false,
        orders: orders,
        selectedRestaurantId: restaurantId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Load a specific order
  Future<void> loadOrder(String restaurantId, String orderId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final order = await _firestoreService.getOrderById(restaurantId, orderId);
      
      state = state.copyWith(
        isLoading: false,
        selectedOrder: order,
        selectedRestaurantId: restaurantId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Load active order for a table
  Future<void> loadActiveOrderForTable(String restaurantId, String tableId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final order = await _firestoreService.getActiveOrderForTable(restaurantId, tableId);
      
      state = state.copyWith(
        isLoading: false,
        selectedOrder: order,
        selectedTableId: tableId,
        selectedRestaurantId: restaurantId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Set selected table
  void setSelectedTable(String restaurantId, String tableId) {
    state = state.copyWith(
      selectedTableId: tableId,
      selectedRestaurantId: restaurantId,
    );
  }
  
  // Add item to cart
  void addToCart(MenuItemModel menuItem, {int quantity = 1, String? specialInstructions}) {
    // Check if item already exists in cart
    final existingItemIndex = state.cartItems.indexWhere(
      (item) => item.menuItemId == menuItem.id && 
                (item.specialInstructions == specialInstructions)
    );
    
    if (existingItemIndex >= 0) {
      // Update existing item quantity
      final existingItem = state.cartItems[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      
      final updatedCartItems = [...state.cartItems];
      updatedCartItems[existingItemIndex] = updatedItem;
      
      state = state.copyWith(cartItems: updatedCartItems);
    } else {
      // Add new item to cart
      final newItem = OrderItemModel(
        id: DateTime.now().toIso8601String(), // Generate a temporary ID
        menuItemId: menuItem.id,
        name: menuItem.name,
        quantity: quantity,
        price: menuItem.effectivePrice,
        specialInstructions: specialInstructions,
        image: menuItem.image,
        isVegetarian: menuItem.isVegetarian,
      );
      
      state = state.copyWith(cartItems: [...state.cartItems, newItem]);
    }
  }
  
  // Update cart item quantity
  void updateCartItemQuantity(String menuItemId, int quantity) {
    if (quantity <= 0) {
      // Remove item if quantity is 0 or less
      removeFromCart(menuItemId);
      return;
    }
    
    final updatedCartItems = state.cartItems.map((item) {
      if (item.menuItemId == menuItemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    
    state = state.copyWith(cartItems: updatedCartItems);
  }
  
  // Remove item from cart
  void removeFromCart(String menuItemId) {
    final updatedCartItems = state.cartItems.where(
      (item) => item.menuItemId != menuItemId
    ).toList();
    
    state = state.copyWith(cartItems: updatedCartItems);
  }
  
  // Clear cart
  void clearCart() {
    state = state.copyWith(cartItems: []);
  }
  
  // Create a new order
  Future<OrderModel?> createOrder(String restaurantId, String tableId, String? customerId) async {
    try {
      if (state.cartItems.isEmpty) {
        state = state.copyWith(errorMessage: 'Cart is empty');
        return null;
      }
      
      if (restaurantId.isEmpty || tableId.isEmpty) {
        state = state.copyWith(errorMessage: 'Restaurant or table not selected');
        return null;
      }
      
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final now = DateTime.now();
      final totalAmount = state.cartTotal;
      
      // Create order model
      final newOrder = OrderModel(
        id: '', // Will be replaced with Firestore document ID
        restaurantId: restaurantId,
        restaurantName: 'Restaurant', // This will be updated by the server
        tableId: tableId,
        customerId: customerId,
        items: List.from(state.cartItems),
        status: OrderStatus.new_,
        subtotal: totalAmount,
        totalAmount: totalAmount,
        taxAmount: totalAmount * 0.1, // Example: 10% tax
        tipAmount: 0, // Tip will be added later during payment
        createdAt: now,
        updatedAt: now,
      );
      
      // Save to Firestore
      final docRef = await _firestoreService.createOrder(restaurantId, newOrder);
      
      // Get created order with ID
      final createdOrder = newOrder.copyWith(id: docRef.id);
      
      // Update table with order ID
      await _firestoreService.updateTable(
        restaurantId, 
        tableId, 
        {
          'isOccupied': true,
          'currentOrderId': docRef.id,
          'occupiedSince': now,
        },
      );
      
      // Send notification for new order
      await _notificationService.sendOrderStatusNotification(
        orderId: docRef.id,
        status: OrderStatus.new_.name,
        restaurantName: 'Restaurant', // Ideally get the restaurant name
      );
      
      // Clear cart and update state
      state = state.copyWith(
        isLoading: false,
        cartItems: [],
        selectedOrder: createdOrder,
      );
      
      return createdOrder;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }
  
  // Load user's orders
  Future<void> loadUserOrders(String userId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Get all restaurants (we'll need to filter all orders across restaurants)
      final restaurants = await _firestoreService.getAllRestaurants();
      
      List<OrderModel> allOrders = [];
      
      // Fetch orders for each restaurant where customerId matches
      for (final restaurant in restaurants) {
        final orders = await _firestoreService.getOrders(
          restaurant.id,
          customerId: userId,
        );
        
        allOrders.addAll(orders);
      }
      
      // Sort by creation time (newest first)
      allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      state = state.copyWith(
        isLoading: false,
        orders: allOrders,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Update order status
  Future<void> updateOrderStatus(
    String restaurantId,
    String orderId,
    OrderStatus newStatus,
  ) async {
    try {
      await _firestoreService.updateOrder(
        restaurantId,
        orderId,
        {
          'status': newStatus.name,
          'updatedAt': DateTime.now(),
        },
      );
      
      // Reload the order to get updated data
      await loadOrder(restaurantId, orderId);
      
      // Get restaurant name for notification
      final restaurant = await _firestoreService.getRestaurantById(restaurantId);
      final restaurantName = restaurant?.name ?? 'Restaurant';
      
      // Send notification about status change
      _notificationService.sendOrderStatusNotification(
        orderId: orderId,
        status: newStatus.name,
        restaurantName: restaurantName,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Update payment status
  Future<bool> updatePaymentStatus(
    String restaurantId, 
    String orderId, 
    PaymentStatus newStatus,
    {String? paymentId, String? paymentMethod}
  ) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final updateData = {
        'paymentStatus': newStatus.name,
      };
      
      if (paymentId != null) {
        updateData['paymentId'] = paymentId;
      }
      
      if (paymentMethod != null) {
        updateData['paymentMethod'] = paymentMethod;
      }
      
      await _firestoreService.updateOrder(restaurantId, orderId, updateData);
      
      // If payment is completed, mark the order as completed if it was served
      final order = state.selectedOrder ?? 
          await _firestoreService.getOrderById(restaurantId, orderId);
          
      if (order != null && 
          newStatus == PaymentStatus.completed && 
          order.status == OrderStatus.served) {
        await updateOrderStatus(restaurantId, orderId, OrderStatus.completed);
      }
      
      // Reload the order
      await loadOrder(restaurantId, orderId);
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Add items to an existing order
  Future<bool> addItemsToOrder(String restaurantId, String orderId, List<OrderItemModel> newItems) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Get current order
      final order = state.selectedOrder ?? 
          await _firestoreService.getOrderById(restaurantId, orderId);
          
      if (order == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Order not found',
        );
        return false;
      }
      
      // Combine existing and new items
      final Map<String, OrderItemModel> itemsMap = {};
      
      // Add existing items to map
      for (final item in order.items) {
        itemsMap[item.menuItemId + (item.specialInstructions ?? '')] = item;
      }
      
      // Add or update with new items
      for (final newItem in newItems) {
        final key = newItem.menuItemId + (newItem.specialInstructions ?? '');
        
        if (itemsMap.containsKey(key)) {
          // Update existing item quantity
          final existingItem = itemsMap[key]!;
          itemsMap[key] = existingItem.copyWith(
            quantity: existingItem.quantity + newItem.quantity,
          );
        } else {
          // Add new item
          itemsMap[key] = newItem;
        }
      }
      
      // Calculate new total
      final updatedItems = itemsMap.values.toList();
      final newTotal = updatedItems.fold(
        0.0, 
        (total, item) => total + (item.price * item.quantity)
      );
      
      // Update order in Firestore
      await _firestoreService.updateOrder(
        restaurantId, 
        orderId, 
        {
          'items': updatedItems.map((item) => item.toFirestore()).toList(),
          'totalAmount': newTotal,
          'taxAmount': newTotal * 0.1, // Example: 10% tax
          'updatedAt': DateTime.now(),
        },
      );
      
      // Reload the order
      await loadOrder(restaurantId, orderId);
      
      // Clear cart after adding items
      state = state.copyWith(cartItems: []);
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Load more orders
  Future<void> loadMoreOrders() async {
    if (!state.hasMoreOrders || state.isLoading) return;
    
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      final moreOrders = await _firestoreService.getOrders(
        state.selectedRestaurantId!,
        status: state.filterStatus,
        lastDocument: state.lastDocument,
      );
      
      if (moreOrders.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasMoreOrders: false,
        );
        return;
      }
      
      state = state.copyWith(
        isLoading: false,
        orders: [...state.orders, ...moreOrders],
        lastDocument: moreOrders.isNotEmpty 
            ? (moreOrders.last as dynamic).reference 
            : state.lastDocument,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  
  // Filter orders by status
  void filterByStatus(OrderStatus? status) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        filterStatus: status,
        lastDocument: null,
        hasMoreOrders: true,
      );
      
      final filteredOrders = await _firestoreService.getOrders(
        state.selectedRestaurantId!,
        status: status,
      );
      
      state = state.copyWith(
        isLoading: false,
        orders: filteredOrders,
        lastDocument: filteredOrders.isNotEmpty 
            ? (filteredOrders.last as dynamic).reference 
            : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

// Order notifier provider
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(notificationServiceProvider),
  );
}); 