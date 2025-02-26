import 'package:cloud_firestore/cloud_firestore.dart';

enum RestaurantStatus { active, inactive, pending }

extension RestaurantStatusExtension on RestaurantStatus {
  String get name {
    switch (this) {
      case RestaurantStatus.active:
        return 'active';
      case RestaurantStatus.inactive:
        return 'inactive';
      case RestaurantStatus.pending:
        return 'pending';
      default:
        return 'inactive';
    }
  }
  
  static RestaurantStatus fromString(String status) {
    switch (status) {
      case 'active':
        return RestaurantStatus.active;
      case 'inactive':
        return RestaurantStatus.inactive;
      case 'pending':
        return RestaurantStatus.pending;
      default:
        return RestaurantStatus.inactive;
    }
  }
}

class RestaurantModel {
  final String id;
  final String name;
  final String address;
  final String? logo;
  final String description;
  final RestaurantStatus status;
  final String ownerId;
  final List<String>? cuisineTypes;
  final String? phone;
  final String? email;
  final Map<String, dynamic>? businessHours;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  RestaurantModel({
    required this.id,
    required this.name,
    required this.address,
    this.logo,
    required this.description,
    required this.status,
    required this.ownerId,
    this.cuisineTypes,
    this.phone,
    this.email,
    this.businessHours,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return RestaurantModel(
      id: doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      logo: data['logo'],
      description: data['description'] ?? '',
      status: RestaurantStatusExtension.fromString(data['status'] ?? 'inactive'),
      ownerId: data['ownerId'] ?? '',
      cuisineTypes: data['cuisineTypes'] != null ? List<String>.from(data['cuisineTypes']) : null,
      phone: data['phone'],
      email: data['email'],
      businessHours: data['businessHours'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'logo': logo,
      'description': description,
      'status': status.name,
      'ownerId': ownerId,
      'cuisineTypes': cuisineTypes,
      'phone': phone,
      'email': email,
      'businessHours': businessHours,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  RestaurantModel copyWith({
    String? id,
    String? name,
    String? address,
    String? logo,
    String? description,
    RestaurantStatus? status,
    String? ownerId,
    List<String>? cuisineTypes,
    String? phone,
    String? email,
    Map<String, dynamic>? businessHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      logo: logo ?? this.logo,
      description: description ?? this.description,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      businessHours: businessHours ?? this.businessHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  bool get isActive => status == RestaurantStatus.active;
} 