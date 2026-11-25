import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/work_service.dart';

class PublishWorkScreen extends StatefulWidget {
  const PublishWorkScreen({super.key});

  @override
  State<PublishWorkScreen> createState() => _PublishWorkScreenState();
}

class _PublishWorkScreenState extends State<PublishWorkScreen> {
  static const int _maxPdfBytes = 20 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _resumeController = TextEditingController();

  WorkType _type = WorkType.roman;
  String _langue = 'fr';
  Uint8List? _coverBytes;
  bool _coverIsPng = false;
  Uint8List? _pdfBytes;
  String? _pdfName;
  bool _droits = false;
  bool _loading = false;

  @override
  void dispose() {
    _titreController.dispose();
    _resumeController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isPng(Uint8List b) =>
      b.length > 4 &&
          b[0] == 0x89 &&
          b[1] == 0x50 &&
          b[2] == 0x4E &&
          b[3] == 0x47;

  bool _isJpeg(Uint8List b) => b.length > 3 && b[0] == 0xFF && b[1] == 0xD8;

  Future<void> _pickCover() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!_isPng(bytes) && !_isJpeg(bytes)) {
      _showError(
        'Format d\'image non pris en charge. Choisissez un JPG ou un PNG.',
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _coverBytes = bytes;
      _coverIsPng = _isPng(bytes);
    });
  }

  Future<void> _pickPdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (bytes.length > _maxPdfBytes) {
      _showError('Le fichier PDF dépasse 20 Mo.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _pdfBytes = bytes;
      _pdfName = file.name;
    });
  }

  Future<void> _save({required bool soumettre}) async {
    if (!_formKey.currentState!.validate()) return;

    if (soumettre) {
      if (_resumeController.text.trim().isEmpty) {
        _showError('Ajoutez un résumé pour soumettre l\'œuvre.');
        return;
      }
      if (_coverBytes == null) {
        _showError('Choisissez une image de couverture.');
        return;
      }
      if (_pdfBytes == null) {
        _showError('Choisissez le fichier PDF de l\'œuvre.');
        return;
      }
      if (!_droits) {
        _showError('Cochez la certification des droits d\'auteur.');
        return;
      }
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _loading = true);
    try {
      await WorkService.instance.saveWork(
        titre: _titreController.text.trim(),
        type: _type,
        resume: _resumeController.text.trim(),
        langue: _langue,
        droitsCertifies: _droits,
        soumettre: soumettre,
        coverBytes: _coverBytes,
        coverIsPng: _coverIsPng,
        pdfBytes: _pdfBytes,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            soumettre
                ? 'Œuvre envoyée pour validation.'
                : 'Brouillon enregistré.',
          ),
        ),
      );
      router.pop(true);
    } on StorageException catch (e) {
      _showError(e.message);
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
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Publier une œuvre')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titreController,
                  maxLength: 150,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entrez le titre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Type d\'œuvre', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: WorkType.values
                      .map(
                        (t) => ChoiceChip(
                      label: Text(t.label),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                  )
                      .toList(),
                ),
                const SizedBox(height: 16),
                Text('Langue', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'fr', label: Text('Français')),
                    ButtonSegment(value: 'en', label: Text('Anglais')),
                  ],
                  selected: {_langue},
                  onSelectionChanged: (selection) =>
                      setState(() => _langue = selection.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _resumeController,
                  maxLength: 2000,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Résumé',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Couverture', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 90,
                      height: 120,
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _coverBytes == null
                          ? const Icon(Icons.image_outlined, size: 40)
                          : Image.memory(
                        _coverBytes!,
                        width: 90,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickCover,
                        icon: const Icon(Icons.image),
                        label: Text(
                          _coverBytes == null
                              ? 'Choisir la couverture'
                              : 'Changer la couverture',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Fichier PDF', style: textTheme.titleMedium),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.picture_as_pdf),
                  title: Text(
                    _pdfName ?? 'Aucun fichier choisi',
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: TextButton(
                    onPressed: _pickPdf,
                    child: Text(_pdfName == null ? 'Choisir' : 'Changer'),
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _droits,
                  onChanged: (value) =>
                      setState(() => _droits = value ?? false),
                  title: const Text(
                    'Je certifie être titulaire des droits sur cette œuvre',
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _loading ? null : () => _save(soumettre: false),
                  child: const Text('Enregistrer en brouillon'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _loading ? null : () => _save(soumettre: true),
                  child: _loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Soumettre pour validation'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}