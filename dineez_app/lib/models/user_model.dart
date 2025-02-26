import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, staff, restaurantAdmin, superAdmin }

extension UserRoleExtension on UserRole {
  String get name {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.staff:
        return 'staff';
      case UserRole.restaurantAdmin:
        return 'restaurantAdmin';
      case UserRole.superAdmin:
        return 'superAdmin';
      default:
        return 'customer';
    }
  }
  
  static UserRole fromString(String role) {
    switch (role) {
      case 'customer':
        return UserRole.customer;
      case 'staff':
        return UserRole.staff;
      case 'restaurantAdmin':
        return UserRole.restaurantAdmin;
      case 'superAdmin':
        return UserRole.superAdmin;
      default:
        return UserRole.customer;
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? restaurantId;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.restaurantId,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRoleExtension.fromString(data['role'] ?? 'customer'),
      restaurantId: data['restaurantId'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'restaurantId': restaurantId,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? restaurantId,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      restaurantId: restaurantId ?? this.restaurantId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  bool get isCustomer => role == UserRole.customer;
  bool get isStaff => role == UserRole.staff;
  bool get isRestaurantAdmin => role == UserRole.restaurantAdmin;
  bool get isSuperAdmin => role == UserRole.superAdmin;
} 