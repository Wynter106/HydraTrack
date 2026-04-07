import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  
  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // sign up
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Generate Auth user
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) return 'Sign up failed';

      // notifyListeners() 호출 안 함 — sign up 직후 Consumer가 HomeScreen으로
      // 날리는 걸 방지. LoginScreen에서 ProfileSetupScreen으로 직접 navigate함.
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Log in
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return null; 
    } catch (e) {
      return e.toString();
    }
  }

  // Log out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }
}