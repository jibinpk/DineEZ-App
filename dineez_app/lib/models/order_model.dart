import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/constants.dart';

enum OrderStatus { 
  new_, 
  preparing, 
  ready, 
  served, 
  completed, 
  cancelled 
}

extension OrderStatusExtension on OrderStatus {
  String get name {
    switch (this) {
      case OrderStatus.new_:
        return 'new';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.served:
        return 'served';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
      default:
        return 'unknown';
    }
  }
  
  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return OrderStatus.new_;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'served':
        return OrderStatus.served;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.new_;
    }
  }
}

enum PaymentStatus { pending, completed, failed, refunded }

extension PaymentStatusExtension on PaymentStatus {
  String get name {
    switch (this) {
      case PaymentStatus.pending:
        return AppConstants.paymentStatusPending;
      case PaymentStatus.completed:
        return AppConstants.paymentStatusCompleted;
      case PaymentStatus.failed:
        return AppConstants.paymentStatusFailed;
      case PaymentStatus.refunded:
        return 'refunded';
      default:
        return AppConstants.paymentStatusPending;
    }
  }
  
  static PaymentStatus fromString(String status) {
    switch (status) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }
}

class OrderItemModel {
  final String id;
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? notes;
  final String? specialInstructions;
  final String? image;
  final bool? isVegetarian;
  final Map<String, dynamic>? customizations;
  
  OrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.notes,
    this.specialInstructions,
    this.image,
    this.isVegetarian,
    this.customizations,
  });
  
  factory OrderItemModel.fromFirestore(Map<String, dynamic> data) {
    return OrderItemModel(
      id: data['id'] ?? '',
      menuItemId: data['menuItemId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
      notes: data['notes'],
      specialInstructions: data['specialInstructions'],
      image: data['image'],
      isVegetarian: data['isVegetarian'],
      customizations: data['customizations'],
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'notes': notes,
      'specialInstructions': specialInstructions,
      'image': image,
      'isVegetarian': isVegetarian,
      'customizations': customizations,
    };
  }
  
  OrderItemModel copyWith({
    String? id,
    String? menuItemId,
    String? name,
    double? price,
    int? quantity,
    String? notes,
    String? specialInstructions,
    String? image,
    bool? isVegetarian,
    Map<String, dynamic>? customizations,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      image: image ?? this.image,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      customizations: customizations ?? this.customizations,
    );
  }
  
  double get totalPrice => price * quantity;
}

class OrderModel {
  final String id;
  final String restaurantId;
  final String restaurantName;
  final String? customerId;
  final String? tableId;
  final List<OrderItemModel> items;
  final OrderStatus status;
  final double subtotal;
  final double? taxAmount;
  final double? tipAmount;
  final double totalAmount;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime? preparedAt;
  final DateTime? servedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;
  
  OrderModel({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    this.customerId,
    this.tableId,
    required this.items,
    required this.status,
    required this.subtotal,
    this.taxAmount,
    this.tipAmount,
    required this.totalAmount,
    this.specialInstructions,
    required this.createdAt,
    this.preparedAt,
    this.servedAt,
    this.completedAt,
    required this.updatedAt,
  });
  
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    List<OrderItemModel> items = [];
    if (data['items'] != null) {
      items = (data['items'] as List)
          .map((item) => OrderItemModel.fromFirestore(item))
          .toList();
    }
    
    return OrderModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      customerId: data['customerId'],
      tableId: data['tableId'],
      items: items,
      status: OrderStatusExtension.fromString(data['status'] ?? 'new'),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      taxAmount: data['taxAmount']?.toDouble(),
      tipAmount: data['tipAmount']?.toDouble(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      specialInstructions: data['specialInstructions'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      preparedAt: data['preparedAt'] != null 
          ? (data['preparedAt'] as Timestamp).toDate() 
          : null,
      servedAt: data['servedAt'] != null 
          ? (data['servedAt'] as Timestamp).toDate() 
          : null,
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'customerId': customerId,
      'tableId': tableId,
      'items': items.map((item) => item.toFirestore()).toList(),
      'status': status.name,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'tipAmount': tipAmount,
      'totalAmount': totalAmount,
      'specialInstructions': specialInstructions,
      'createdAt': Timestamp.fromDate(createdAt),
      'preparedAt': preparedAt != null ? Timestamp.fromDate(preparedAt!) : null,
      'servedAt': servedAt != null ? Timestamp.fromDate(servedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  OrderModel copyWith({
    String? id,
    String? restaurantId,
    String? restaurantName,
    String? customerId,
    String? tableId,
    List<OrderItemModel>? items,
    OrderStatus? status,
    double? subtotal,
    double? taxAmount,
    double? tipAmount,
    double? totalAmount,
    String? specialInstructions,
    DateTime? createdAt,
    DateTime? preparedAt,
    DateTime? servedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      customerId: customerId ?? this.customerId,
      tableId: tableId ?? this.tableId,
      items: items ?? this.items,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      createdAt: createdAt ?? this.createdAt,
      preparedAt: preparedAt ?? this.preparedAt,
      servedAt: servedAt ?? this.servedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Helper methods
  bool get isPaid => status == OrderStatus.completed;
  bool get isInProgress => status != OrderStatus.completed && status != OrderStatus.cancelled;
  
  // Calculate order time
  Duration get orderDuration {
    return updatedAt.difference(createdAt);
  }
  
  // Get total items count
  int get totalItemsCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
  
  // Helper getters
  String get orderNumber => id.substring(0, 8).toUpperCase();
  
  bool get canBeCancelled => status == OrderStatus.new_ || status == OrderStatus.preparing;
  
  DateTime? get preparingAt => status.index >= OrderStatus.preparing.index ? updatedAt : null;
  DateTime? get readyAt => status.index >= OrderStatus.ready.index ? updatedAt : null;
  DateTime? get lastServedAt => status.index >= OrderStatus.served.index ? updatedAt : null;
  DateTime? get lastCompletedAt => status == OrderStatus.completed ? updatedAt : null;
} 