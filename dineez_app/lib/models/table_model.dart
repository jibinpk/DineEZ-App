import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  final String id;
  final String restaurantId;
  final int tableNumber;
  final String qrCodeUrl;
  final int capacity;
  final bool isOccupied;
  final bool isReserved;
  final String? currentOrderId;
  final DateTime? occupiedSince;
  final String? location; // e.g., "indoor", "outdoor", "private room"
  final DateTime createdAt;
  final DateTime updatedAt;
  
  TableModel({
    required this.id,
    required this.restaurantId,
    required this.tableNumber,
    required this.qrCodeUrl,
    required this.capacity,
    this.isOccupied = false,
    this.isReserved = false,
    this.currentOrderId,
    this.occupiedSince,
    this.location,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return TableModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      tableNumber: data['tableNumber'] ?? 0,
      qrCodeUrl: data['qrCodeUrl'] ?? '',
      capacity: data['capacity'] ?? 2,
      isOccupied: data['isOccupied'] ?? false,
      isReserved: data['isReserved'] ?? false,
      currentOrderId: data['currentOrderId'],
      occupiedSince: data['occupiedSince'] != null 
          ? (data['occupiedSince'] as Timestamp).toDate() 
          : null,
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'tableNumber': tableNumber,
      'qrCodeUrl': qrCodeUrl,
      'capacity': capacity,
      'isOccupied': isOccupied,
      'isReserved': isReserved,
      'currentOrderId': currentOrderId,
      'occupiedSince': occupiedSince != null 
          ? Timestamp.fromDate(occupiedSince!) 
          : null,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  TableModel copyWith({
    String? id,
    String? restaurantId,
    int? tableNumber,
    String? qrCodeUrl,
    int? capacity,
    bool? isOccupied,
    bool? isReserved,
    String? currentOrderId,
    DateTime? occupiedSince,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      tableNumber: tableNumber ?? this.tableNumber,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      capacity: capacity ?? this.capacity,
      isOccupied: isOccupied ?? this.isOccupied,
      isReserved: isReserved ?? this.isReserved,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      occupiedSince: occupiedSince ?? this.occupiedSince,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Helper method to check table availability
  bool get isAvailable => !isOccupied && !isReserved;
  
  // Calculate how long the table has been occupied
  Duration? get occupationDuration {
    if (isOccupied && occupiedSince != null) {
      return DateTime.now().difference(occupiedSince!);
    }
    return null;
  }
  
  // Table display name
  String get displayName => 'Table $tableNumber';
  
  // Table status text
  String get statusText {
    if (isReserved) return 'Reserved';
    if (isOccupied) return 'Occupied';
    return 'Available';
  }
} 