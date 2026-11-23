import 'package:supabase_flutter/supabase_flutter.dart';

enum RoleInscription { lecteur, auteur }

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

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