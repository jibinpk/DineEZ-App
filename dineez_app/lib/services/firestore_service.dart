import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/restaurant_model.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import '../models/payment_model.dart';
import '../config/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections
  CollectionReference get usersCollection => 
      _firestore.collection(AppConstants.usersCollection);
  
  CollectionReference get restaurantsCollection => 
      _firestore.collection(AppConstants.restaurantsCollection);
  
  // Get restaurant subcollections
  CollectionReference menuItemsCollection(String restaurantId) => 
      restaurantsCollection.doc(restaurantId)
          .collection(AppConstants.menuItemsCollection);
  
  CollectionReference tablesCollection(String restaurantId) => 
      restaurantsCollection.doc(restaurantId)
          .collection(AppConstants.tablesCollection);
  
  CollectionReference ordersCollection(String restaurantId) => 
      restaurantsCollection.doc(restaurantId)
          .collection(AppConstants.ordersCollection);
  
  // USER OPERATIONS
  
  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await usersCollection.doc(userId).get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      QuerySnapshot snapshot = await usersCollection
          .where('role', isEqualTo: role.name)
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Get restaurant staff
  Future<List<UserModel>> getRestaurantStaff(String restaurantId) async {
    try {
      QuerySnapshot snapshot = await usersCollection
          .where('restaurantId', isEqualTo: restaurantId)
          .where('role', whereIn: [
            UserRole.staff.name, 
            UserRole.restaurantAdmin.name
          ])
          .get();
      
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // RESTAURANT OPERATIONS
  
  // Create restaurant
  Future<DocumentReference> createRestaurant(RestaurantModel restaurant) async {
    try {
      return await restaurantsCollection.add(restaurant.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  // Get restaurant by ID
  Future<RestaurantModel?> getRestaurantById(String restaurantId) async {
    try {
      DocumentSnapshot doc = await restaurantsCollection.doc(restaurantId).get();
      
      if (doc.exists) {
        return RestaurantModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get all restaurants
  Future<List<RestaurantModel>> getAllRestaurants() async {
    try {
      QuerySnapshot snapshot = await restaurantsCollection.get();
      
      return snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Get restaurants by owner
  Future<List<RestaurantModel>> getRestaurantsByOwner(String ownerId) async {
    try {
      QuerySnapshot snapshot = await restaurantsCollection
          .where('ownerId', isEqualTo: ownerId)
          .get();
      
      return snapshot.docs
          .map((doc) => RestaurantModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Update restaurant
  Future<void> updateRestaurant(String restaurantId, Map<String, dynamic> data) async {
    try {
      // Add updatedAt field
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await restaurantsCollection.doc(restaurantId).update(data);
    } catch (e) {
      rethrow;
    }
  }
  
  // MENU ITEM OPERATIONS
  
  // Create menu item
  Future<DocumentReference> createMenuItem(String restaurantId, MenuItemModel menuItem) async {
    try {
      return await menuItemsCollection(restaurantId).add(menuItem.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  // Get menu items for a restaurant
  Future<List<MenuItemModel>> getMenuItems(String restaurantId, {String? category}) async {
    try {
      Query query = menuItemsCollection(restaurantId);
      
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => MenuItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Get menu item by ID
  Future<MenuItemModel?> getMenuItemById(String restaurantId, String menuItemId) async {
    try {
      DocumentSnapshot doc = await menuItemsCollection(restaurantId).doc(menuItemId).get();
      
      if (doc.exists) {
        return MenuItemModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update menu item
  Future<void> updateMenuItem(
    String restaurantId, 
    String menuItemId, 
    Map<String, dynamic> data
  ) async {
    try {
      // Add updatedAt field
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await menuItemsCollection(restaurantId).doc(menuItemId).update(data);
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete menu item
  Future<void> deleteMenuItem(String restaurantId, String menuItemId) async {
    try {
      await menuItemsCollection(restaurantId).doc(menuItemId).delete();
    } catch (e) {
      rethrow;
    }
  }
  
  // TABLE OPERATIONS
  
  // Create table
  Future<DocumentReference> createTable(String restaurantId, TableModel table) async {
    try {
      return await tablesCollection(restaurantId).add(table.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  // Get tables for a restaurant
  Future<List<TableModel>> getTables(String restaurantId, {bool? isAvailable}) async {
    try {
      Query query = tablesCollection(restaurantId);
      
      if (isAvailable != null) {
        query = query.where('isOccupied', isEqualTo: !isAvailable)
                     .where('isReserved', isEqualTo: !isAvailable);
      }
      
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => TableModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Get table by ID
  Future<TableModel?> getTableById(String restaurantId, String tableId) async {
    try {
      DocumentSnapshot doc = await tablesCollection(restaurantId).doc(tableId).get();
      
      if (doc.exists) {
        return TableModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // Update table
  Future<void> updateTable(
    String restaurantId, 
    String tableId, 
    Map<String, dynamic> data
  ) async {
    try {
      // Add updatedAt field
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await tablesCollection(restaurantId).doc(tableId).update(data);
    } catch (e) {
      rethrow;
    }
  }
  
  // ORDER OPERATIONS
  
  // Create order
  Future<DocumentReference> createOrder(String restaurantId, OrderModel order) async {
    try {
      return await ordersCollection(restaurantId).add(order.toFirestore());
    } catch (e) {
      rethrow;
    }
  }
  
  // Get orders for a restaurant
  Future<List<OrderModel>> getOrders(
    String restaurantId, {
    OrderStatus? status,
    String? tableId,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    DocumentSnapshot? lastDocument,
    int limit = 10,
  }) async {
    try {
      Query query = ordersCollection(restaurantId);
      
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      
      if (tableId != null) {
        query = query.where('tableId', isEqualTo: tableId);
      }
      
      if (customerId != null) {
        query = query.where('customerId', isEqualTo: customerId);
      }
      
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      // Order by creation time (newest first)
      query = query.orderBy('createdAt', descending: true);
      
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }
      
      query = query.limit(limit);
      
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Get a single order by ID
  Future<OrderModel> getOrderById(String restaurantId, String orderId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.restaurantsCollection)
          .doc(restaurantId)
          .collection(AppConstants.ordersCollection)
          .doc(orderId)
          .get();
      
      if (!doc.exists) {
        throw Exception('Order not found');
      }
      
      return OrderModel.fromFirestore(doc);
    } catch (e) {
      rethrow;
    }
  }
  
  // Update order
  Future<void> updateOrder(
    String restaurantId, 
    String orderId, 
    Map<String, dynamic> data
  ) async {
    try {
      // Add updatedAt field
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      await ordersCollection(restaurantId).doc(orderId).update(data);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get active orders for a table
  Future<OrderModel?> getActiveOrderForTable(String restaurantId, String tableId) async {
    try {
      QuerySnapshot snapshot = await ordersCollection(restaurantId)
          .where('tableId', isEqualTo: tableId)
          .where('status', whereIn: [
            OrderStatus.new_.name,
            OrderStatus.preparing.name,
            OrderStatus.ready.name,
            OrderStatus.served.name,
          ])
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return OrderModel.fromFirestore(snapshot.docs.first);
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // UTILITY METHODS
  
  // Transaction to update multiple documents
  Future<void> runTransaction(Function(Transaction) updateFunction) async {
    try {
      await _firestore.runTransaction((transaction) async {
        return await updateFunction(transaction);
      });
    } catch (e) {
      rethrow;
    }
  }
  
  // Batch operations
  Future<void> runBatch(Function(WriteBatch) batchFunction) async {
    try {
      WriteBatch batch = _firestore.batch();
      await batchFunction(batch);
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }
} 