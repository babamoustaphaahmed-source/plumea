import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profile;

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

  Future<void> _edit(Map<String, dynamic> profile) async {
    await context.push<bool>('/modifier-profil', extra: profile);
    if (mounted) {
      setState(() => _profile = _loadProfile());
    }
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
          final bio = (profile['bio'] as String?) ?? '';
          final photoUrl = profile['photo_url'] as String?;
          final estAuteur = profile['role'] == 'auteur';
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, size: 56)
                      : null,
                ),
              ),
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
              ListTile(
                leading: const Icon(Icons.notes_outlined),
                title: const Text('Biographie'),
                subtitle: Text(bio.isEmpty ? 'Non renseignée' : bio),
              ),
              const SizedBox(height: 24),
              if (estAuteur) ...[
                FilledButton.icon(
                  onPressed: () => context.push('/publier'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Publier une œuvre'),
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: () => _edit(profile),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Modifier le profil'),
              ),
              const SizedBox(height: 12),
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