import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current Firebase user provider
final firebaseAuthUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current user data provider (Firestore data)
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUserData();
});

// Auth state notifier
class AuthState {
  final bool isLoading;
  final String? errorMessage;
  final UserModel? user;
  
  AuthState({
    this.isLoading = false,
    this.errorMessage,
    this.user,
  });
  
  AuthState copyWith({
    bool? isLoading,
    String? errorMessage,
    UserModel? user,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(AuthState());
  
  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await _authService.signInWithEmailAndPassword(email, password);
      final user = await _authService.getCurrentUserData();
      
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Register with email and password
  Future<bool> registerWithEmailAndPassword(
    String email, 
    String password,
    String name,
    String phone,
    UserRole role,
    {String? restaurantId}
  ) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await _authService.registerWithEmailAndPassword(
        email, 
        password, 
        name, 
        phone, 
        role,
        restaurantId: restaurantId,
      );
      
      final user = await _authService.getCurrentUserData();
      
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await _authService.signOut();
      
      state = state.copyWith(isLoading: false, user: null);
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: e.toString(),
      );
    }
  }
  
  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await _authService.resetPassword(email);
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: e.toString(),
      );
      return false;
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? phone,
    String? profileImageUrl,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await _authService.updateUserProfile(
        name: name,
        phone: phone,
        profileImageUrl: profileImageUrl,
      );
      
      final updatedUser = await _authService.getCurrentUserData();
      
      state = state.copyWith(isLoading: false, user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false, 
        errorMessage: e.toString(),
      );
      return false;
    }
  }
}

// Auth notifier provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
}); 