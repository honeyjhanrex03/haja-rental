import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../services/email_service.dart';

// User role enum
enum UserRole { customer, seller, admin }

// User model
class User {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final String? contactNumber;
  final String? address;
  
  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.contactNumber,
    this.address,
  });
}

// Authentication state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });
  
  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Authentication provider
class AuthProvider extends Notifier<AuthState> {
  sb.SupabaseClient get _supabase => sb.Supabase.instance.client;

  @override
  AuthState build() => const AuthState();
  
  // Clear Error
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  // Login
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        await _loadProfile(response.user!.id);
      }
    } on sb.AuthException catch (e) {
      String message = e.message;
      if (message.contains('Invalid login credentials')) {
        message = 'Incorrect email or password. Please try again.';
      } else if (message.contains('Email not confirmed')) {
        message = 'Please verify your email address before logging in.';
      }
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred. Please try again later.',
      );
    }
  }
  
  // Sign up
  Future<void> signUp({
    required String email, 
    required String password, 
    required String fullName, 
    required UserRole role,
    String? contactNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': role.name,
          'contact_number': contactNumber,
        },
      );
      
      if (response.user != null) {
        await _loadProfile(response.user!.id);
        
        // Send Welcome Email
        await EmailService().sendEmail(
          toEmail: email,
          toName: fullName,
          subject: 'Welcome to HAJA Rental!',
          htmlContent: EmailService().getWelcomeTemplate(fullName),
        );
      }
    } on sb.AuthException catch (e) {
      String message = e.message;
      if (message.contains('User already registered')) {
        message = 'An account with this email already exists.';
      } else if (message.contains('Password should be at least 6 characters')) {
        message = 'Password is too weak. Use at least 6 characters.';
      }
      state = state.copyWith(isLoading: false, error: message);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please check your details and try again.',
      );
    }
  }
  
  Future<void> _loadProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
          
      final currentUser = _supabase.auth.currentUser;
      final metaRole = currentUser?.userMetadata?['role'] as String?;
      final metaName = currentUser?.userMetadata?['full_name'] as String?;
      
      Map<String, dynamic> data;
      
      if (response == null) {
        // Create profile if missing
        data = {
          'id': userId,
          'full_name': metaName ?? 'New User',
          'role': metaRole ?? 'customer',
          'created_at': DateTime.now().toIso8601String(),
        };
        try {
          await _supabase.from('profiles').insert(data);
        } catch (e) {
          // Ignore insert errors
        }
      } else {
        data = response;
        // Sync if metadata has a more specific role (e.g. seller) but DB is still default
        if (data['role'] == 'customer' && metaRole != null && metaRole != 'customer') {
          try {
            await _supabase.from('profiles').update({'role': metaRole}).eq('id', userId);
            data['role'] = metaRole;
          } catch (e) {
            // Ignore update errors
          }
        }
      }
          
      final roleStr = data['role'] as String? ?? 'customer';
      final role = UserRole.values.firstWhere(
        (e) => e.name == roleStr,
        orElse: () => UserRole.customer,
      );
      
      final email = currentUser?.email ?? 'No Email';
      
      final user = User(
        id: userId,
        email: email,
        fullName: data['full_name'] ?? 'New User',
        role: role,
        avatarUrl: data['avatar_url'],
        contactNumber: data['contact_number'],
        address: data['address'],
      );
      
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load profile: ${e.toString()}',
      );
    }
  }
  
  // Update Profile
  Future<void> updateProfile({
    String? fullName,
    String? address,
    String? contactNumber,
  }) async {
    if (state.user == null) return;
    
    final userId = state.user!.id;
    state = state.copyWith(isLoading: true);
    
    try {
      await _supabase
          .from('profiles')
          .upsert({
            'id': userId,
            'full_name': fullName ?? state.user!.fullName,
            'address': address ?? state.user!.address,
            'contact_number': contactNumber ?? state.user!.contactNumber,
            'role': state.user!.role.name,
          });
      
      final updatedUser = User(
        id: userId,
        email: state.user!.email,
        fullName: fullName ?? state.user!.fullName,
        role: state.user!.role,
        avatarUrl: state.user!.avatarUrl,
        contactNumber: contactNumber ?? state.user!.contactNumber,
        address: address ?? state.user!.address,
      );
      
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: ${e.toString()}',
      );
      rethrow;
    }
  }

  // Update Avatar
  Future<void> updateAvatar(String url) async {
    if (state.user == null) return;
    
    final userId = state.user!.id;
    state = state.copyWith(isLoading: true);
    
    try {
      // Use upsert to ensure the profile exists even if trigger hasn't run
      await _supabase
          .from('profiles')
          .upsert({
            'id': userId,
            'avatar_url': url,
            'full_name': state.user!.fullName,
            'role': state.user!.role.name,
          });
      
      final updatedUser = User(
        id: userId,
        email: state.user!.email,
        fullName: state.user!.fullName,
        role: state.user!.role,
        avatarUrl: url,
        contactNumber: state.user!.contactNumber,
        address: state.user!.address,
      );
      
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        error: null,
      );
      
      // Verification log
      debugPrint('Avatar successfully updated to: $url');
    } catch (e) {
      debugPrint('Error updating avatar: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to save avatar: ${e.toString()}',
      );
    }
  }
  
  // Logout
  Future<void> logout() async {
    await _supabase.auth.signOut();
    state = const AuthState();
  }
  
  // Check auth status
  Future<void> checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _loadProfile(session.user.id);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Riverpod providers
final authProvider = NotifierProvider<AuthProvider, AuthState>(() {
  return AuthProvider();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.error;
});
