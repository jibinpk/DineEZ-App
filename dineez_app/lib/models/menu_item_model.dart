import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String category;
  final String? image;
  final bool isAvailable;
  final int preparationTime; // in minutes
  final List<String>? ingredients;
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isSpicy;
  final double? discountPrice;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.image,
    required this.isAvailable,
    required this.preparationTime,
    this.ingredients,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.isSpicy = false,
    this.discountPrice,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return MenuItemModel(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      category: data['category'] ?? '',
      image: data['image'],
      isAvailable: data['isAvailable'] ?? true,
      preparationTime: data['preparationTime'] ?? 15,
      ingredients: data['ingredients'] != null ? List<String>.from(data['ingredients']) : null,
      isVegetarian: data['isVegetarian'] ?? false,
      isVegan: data['isVegan'] ?? false,
      isGlutenFree: data['isGlutenFree'] ?? false,
      isSpicy: data['isSpicy'] ?? false,
      discountPrice: data['discountPrice']?.toDouble(),
      isFeatured: data['isFeatured'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image': image,
      'isAvailable': isAvailable,
      'preparationTime': preparationTime,
      'ingredients': ingredients,
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'isSpicy': isSpicy,
      'discountPrice': discountPrice,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
  
  MenuItemModel copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    double? price,
    String? category,
    String? image,
    bool? isAvailable,
    int? preparationTime,
    List<String>? ingredients,
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    bool? isSpicy,
    double? discountPrice,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      image: image ?? this.image,
      isAvailable: isAvailable ?? this.isAvailable,
      preparationTime: preparationTime ?? this.preparationTime,
      ingredients: ingredients ?? this.ingredients,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      isSpicy: isSpicy ?? this.isSpicy,
      discountPrice: discountPrice ?? this.discountPrice,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Get effective price (considering discount if available)
  double get effectivePrice => discountPrice != null ? discountPrice! : price;
  
  // Check if item has a discount
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  
  // Calculate discount percentage
  double? get discountPercentage {
    if (hasDiscount) {
      return ((price - discountPrice!) / price) * 100;
    }
    return null;
  }
} 