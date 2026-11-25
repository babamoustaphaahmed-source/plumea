import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

enum WorkType { roman, poeme, fable, theatre }

extension WorkTypeLabel on WorkType {
  String get label {
    switch (this) {
      case WorkType.roman:
        return 'Roman';
      case WorkType.poeme:
        return 'Poème';
      case WorkType.fable:
        return 'Fable';
      case WorkType.theatre:
        return 'Théâtre';
    }
  }
}

class WorkService {
  WorkService._();

  static final WorkService instance = WorkService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> saveWork({
    required String titre,
    required WorkType type,
    required String resume,
    required String langue,
    required bool droitsCertifies,
    required bool soumettre,
    Uint8List? coverBytes,
    bool coverIsPng = false,
    Uint8List? pdfBytes,
  }) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    // 1. Création de l'oeuvre en brouillon, pour obtenir son identifiant
    final created = await _client
        .from('works')
        .insert({
      'author_id': user.id,
      'titre': titre,
      'type': type.name,
      'resume': resume,
      'langue': langue,
      'droits_certifies': droitsCertifies,
      'statut': 'brouillon',
    })
        .select('id')
        .single();
    final id = created['id'] as String;

    try {
      final changes = <String, dynamic>{};

      // 2. Envoi de la couverture
      if (coverBytes != null) {
        final ext = coverIsPng ? 'png' : 'jpg';
        final path = '${user.id}/$id.$ext';
        await _client.storage.from('covers').uploadBinary(
          path,
          coverBytes,
          fileOptions: FileOptions(
            contentType: coverIsPng ? 'image/png' : 'image/jpeg',
          ),
        );
        changes['cover_path'] = path;
      }

      // 3. Envoi du PDF
      if (pdfBytes != null) {
        final path = '${user.id}/$id.pdf';
        await _client.storage.from('pdfs').uploadBinary(
          path,
          pdfBytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );
        changes['pdf_path'] = path;
      }

      // 4. Mise à jour de l'oeuvre : chemins des fichiers et statut
      if (soumettre) {
        changes['statut'] = 'en_attente';
      }
      if (changes.isNotEmpty) {
        await _client.from('works').update(changes).eq('id', id);
      }
    } catch (_) {
      // En cas d'échec, on supprime l'oeuvre à moitié créée
      await _client.from('works').delete().eq('id', id);
      rethrow;
    }
  }
}