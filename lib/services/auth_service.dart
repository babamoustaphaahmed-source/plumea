import 'package:supabase_flutter/supabase_flutter.dart';

enum RoleInscription { lecteur, auteur }

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signUp({
    required String nom,
    required String email,
    required String password,
    required RoleInscription role,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'nom': nom, 'role': role.name},
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}