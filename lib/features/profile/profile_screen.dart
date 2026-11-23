import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<Map<String, dynamic>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return data;
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Impossible de charger le profil.'),
            );
          }
          final profile = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.account_circle, size: 96),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Nom'),
                subtitle: Text(profile['nom'] as String),
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('E-mail'),
                subtitle: Text(email),
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Rôle'),
                subtitle: Text(_capitalize(profile['role'] as String)),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => AuthService.instance.signOut(),
                child: const Text('Se déconnecter'),
              ),
            ],
          );
        },
      ),
    );
  }
}