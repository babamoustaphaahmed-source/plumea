import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomController;
  late final TextEditingController _bioController;
  String? _photoUrl;
  bool _loading = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(
      text: (widget.profile['nom'] as String?) ?? '',
    );
    _bioController = TextEditingController(
      text: (widget.profile['bio'] as String?) ?? '',
    );
    _photoUrl = widget.profile['photo_url'] as String?;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickPhoto() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final isPng = file.name.toLowerCase().endsWith('.png');
      final path = '${user.id}/avatar';
      final storage = Supabase.instance.client.storage.from('avatars');

      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: isPng ? 'image/png' : 'image/jpeg',
          upsert: true,
        ),
      );

      final url =
          '${storage.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
      await Supabase.instance.client
          .from('profiles')
          .update({'photo_url': url}).eq('id', user.id);

      if (!mounted) return;
      setState(() => _photoUrl = url);
    } on StorageException catch (e) {
      _showError(e.message);
    } on PostgrestException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Impossible d\'envoyer la photo. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final bio = _bioController.text.trim();
      await Supabase.instance.client.from('profiles').update({
        'nom': _nomController.text.trim(),
        'bio': bio.isEmpty ? null : bio,
      }).eq('id', user.id);
      if (!mounted) return;
      context.pop(true);
    } on PostgrestException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Une erreur est survenue. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundImage:
                        _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                        child: _photoUrl == null
                            ? const Icon(Icons.person, size: 56)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: IconButton.filled(
                          onPressed: _uploading ? null : _pickPhoto,
                          icon: _uploading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.camera_alt),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nomController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nom complet',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entrez votre nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLength: 300,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Biographie',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}