import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }
  
  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email, 
    String password, 
    String name, 
    String phone, 
    UserRole role, 
    {String? restaurantId}
  ) async {
    try {
      // Create user in Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      // Create user document in Firestore
      await _createUserInFirestore(
        userCredential.user!.uid,
        name,
        email,
        phone,
        role,
        restaurantId,
      );
      
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }
  
  // Create user document in Firestore
  Future<void> _createUserInFirestore(
    String uid, 
    String name, 
    String email, 
    String phone, 
    UserRole role, 
    String? restaurantId,
  ) async {
    final DateTime now = DateTime.now();
    
    final UserModel newUser = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      role: role,
      restaurantId: restaurantId,
      createdAt: now,
      updatedAt: now,
    );
    
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .set(newUser.toFirestore());
  }
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  // Get current user data from Firestore
  Future<UserModel?> getCurrentUserData() async {
    if (currentUser == null) return null;
    
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user data: $e');
      }
      return null;
    }
  }
  
  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    if (currentUser == null) return;
    
    try {
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) {
        updateData['name'] = name;
        await currentUser!.updateDisplayName(name);
      }
      
      if (phone != null) updateData['phone'] = phone;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .update(updateData);
    } catch (e) {
      rethrow;
    }
  }
  
  // Update user role (admin only)
  Future<void> updateUserRole(String userId, UserRole newRole, {String? restaurantId}) async {
    try {
      final Map<String, dynamic> updateData = {
        'role': newRole.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (restaurantId != null) {
        updateData['restaurantId'] = restaurantId;
      } else if (newRole != UserRole.restaurantAdmin && newRole != UserRole.staff) {
        // Remove restaurantId if the new role is not restaurant-related
        updateData['restaurantId'] = FieldValue.delete();
      }
      
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updateData);
    } catch (e) {
      rethrow;
    }
  }
  
  // Delete user account
  Future<void> deleteUserAccount() async {
    if (currentUser == null) return;
    
    try {
      // Delete user document from Firestore
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(currentUser!.uid)
          .delete();
      
      // Delete user from Firebase Auth
      await currentUser!.delete();
    } catch (e) {
      rethrow;
    }
  }
} 