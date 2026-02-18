import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/gazette.dart';
import '../../models/famille.dart';
import '../../utils/colors.dart';

class ContributionScreen extends StatefulWidget {
  final Gazette gazette;
  final Famille famille;

  const ContributionScreen({
    super.key,
    required this.gazette,
    required this.famille,
  });

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = FirebaseAuth.instance;
  final _picker = ImagePicker();

  String _layout = '1photo';
  final _texteCtrl = TextEditingController();
  final _titreCtrl = TextEditingController();
  final _meilleurCtrl = TextEditingController();
  final _anticipationCtrl = TextEditingController();
  // Blanks
  final _momentCtrl = TextEditingController();
  final _activiteCtrl = TextEditingController();
  final _repasCtrl = TextEditingController();

  String? _humeur;
  final List<File> _photos = [];
  bool _saving = false;

  final List<String> _humeurs = ['😊', '😄', '😌', '🥰', '😢', '😤', '🤔', '🎉'];

  int get _maxPhotos {
    switch (_layout) {
      case '2photos': return 2;
      case '3photos': return 3;
      case 'blanks': return 1;
      default: return 1;
    }
  }

  @override
  void dispose() {
    _texteCtrl.dispose();
    _titreCtrl.dispose();
    _meilleurCtrl.dispose();
    _anticipationCtrl.dispose();
    _momentCtrl.dispose();
    _activiteCtrl.dispose();
    _repasCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= _maxPhotos) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 75);
    if (file != null) setState(() => _photos.add(File(file.path)));
  }

  Future<List<String>> _uploadPhotos() async {
    final uid = _auth.currentUser?.uid ?? 'unknown';
    final List<String> urls = [];
    for (int i = 0; i < _photos.length; i++) {
      final ref = _storage.ref()
          .child('gazettes/${widget.gazette.id}/$uid/photo_$i.jpg');
      await ref.putFile(_photos[i]);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _submit({bool brouillon = false}) async {
    setState(() => _saving = true);
    try {
      final uid = _auth.currentUser?.uid ?? '';
      final photoUrls = await _uploadPhotos();

      final data = {
        'layout': _layout,
        'titre': _titreCtrl.text.trim().isNotEmpty ? _titreCtrl.text.trim() : null,
        'texte': _texteCtrl.text.trim().isNotEmpty ? _texteCtrl.text.trim() : null,
        'photos': photoUrls,
        'humeur': _humeur,
        'meilleur_chose': _meilleurCtrl.text.trim().isNotEmpty ? _meilleurCtrl.text.trim() : null,
        'anticipation': _anticipationCtrl.text.trim().isNotEmpty ? _anticipationCtrl.text.trim() : null,
        'moment_magique': _momentCtrl.text.trim().isNotEmpty ? _momentCtrl.text.trim() : null,
        'activite': _activiteCtrl.text.trim().isNotEmpty ? _activiteCtrl.text.trim() : null,
        'repas': _repasCtrl.text.trim().isNotEmpty ? _repasCtrl.text.trim() : null,
        'soumis': !brouillon,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _db
          .collection('gazettes')
          .doc(widget.gazette.id)
          .collection('pages')
          .doc(uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(brouillon
                ? '💾 Brouillon sauvegardé'
                : '🎉 Page soumise! La famille peut la voir.'),
            backgroundColor: brouillon ? AppColors.info : AppColors.success,
          ),
        );
        if (!brouillon) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma page du mois'),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _submit(brouillon: true),
            child: const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Gazette info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('📰 ${widget.gazette.moisLabel} — ${widget.famille.nom}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          // Layout
          const Text('Choisissez votre mise en page',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          _buildLayoutPicker(),
          const SizedBox(height: 20),

          // Photos
          if (_layout != 'blanks') ...[
            Text('Photos (${_photos.length}/$_maxPhotos)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            _buildPhotoPicker(),
            const SizedBox(height: 20),
          ],

          // Titre (optionnel)
          TextFormField(
            controller: _titreCtrl,
            decoration: InputDecoration(
              labelText: 'Titre de votre page (optionnel)',
              prefixIcon: const Icon(Icons.title),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'Ex: "Un mois riche en émotions"',
            ),
          ),
          const SizedBox(height: 16),

          // Contenu selon layout
          if (_layout == 'blanks')
            _buildBlanksForm()
          else
            _buildTexteForm(),

          const SizedBox(height: 20),

          // Humeur
          const Text('Votre humeur du mois',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: _humeurs.map((h) {
              final selected = _humeur == h;
              return GestureDetector(
                onTap: () => setState(() => _humeur = selected ? null : h),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: EdgeInsets.all(selected ? 10 : 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(h,
                      style: TextStyle(fontSize: selected ? 32 : 28)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Meilleure chose + anticipation
          TextFormField(
            controller: _meilleurCtrl,
            decoration: InputDecoration(
              labelText: '✨ Ma meilleure chose ce mois',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              hintText: 'Ce qui m\'a rendu heureux...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _anticipationCtrl,
            decoration: InputDecoration(
              labelText: '🔮 Ce que j\'attends le mois prochain',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          // Submit
          ElevatedButton.icon(
            onPressed: _saving ? null : () => _submit(),
            icon: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Soumettre ma page'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLayoutPicker() {
    final layouts = [
      {'value': '1photo', 'label': '1 photo', 'desc': 'Grand texte (300 mots)', 'icone': '🖼️'},
      {'value': '2photos', 'label': '2 photos', 'desc': 'Texte moyen (200 mots)', 'icone': '🖼️🖼️'},
      {'value': '3photos', 'label': '3 photos', 'desc': 'Texte court (100 mots)', 'icone': '🖼️🖼️🖼️'},
      {'value': 'blanks', 'label': 'Texte à trous', 'desc': 'Facile pour maman 😊', 'icone': '📝'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: layouts.map((l) {
        final selected = _layout == l['value'];
        return GestureDetector(
          onTap: () => setState(() {
            _layout = l['value']!;
            _photos.clear();
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected ? AppColors.primary : Colors.grey[300]!,
                  width: selected ? 2 : 1),
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.06)
                  : Colors.white,
            ),
            child: Column(
              children: [
                Text(l['icone']!, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 2),
                Text(l['label']!,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: selected ? AppColors.primary : AppColors.textPrimary)),
                Text(l['desc']!,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoPicker() {
    return SizedBox(
      height: 100,
      child: Row(
        children: [
          ..._photos.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(e.value,
                          width: 90, height: 90, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _photos.removeAt(e.key)),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          if (_photos.length < _maxPhotos)
            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                  color: Colors.grey[100],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate,
                        color: Colors.grey[400], size: 30),
                    Text('Ajouter',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 11)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTexteForm() {
    final maxWords = _layout == '1photo' ? 300 : (_layout == '2photos' ? 200 : 100);
    return TextFormField(
      controller: _texteCtrl,
      maxLines: _layout == '1photo' ? 8 : 5,
      decoration: InputDecoration(
        labelText: 'Votre texte (max $maxWords mots)',
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: 'Racontez votre mois...',
      ),
    );
  }

  Widget _buildBlanksForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Remplissez les blancs 📝',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        _buildBlankField(_momentCtrl, 'Le moment magique du mois 🌟',
            'Une belle surprise, une rencontre...'),
        const SizedBox(height: 12),
        _buildBlankField(_activiteCtrl, 'Ce que j\'ai fait 🎯',
            'Promenade, cinéma, jardinage...'),
        const SizedBox(height: 12),
        _buildBlankField(_repasCtrl, 'Mon bon repas du mois 🍽️',
            'Un plat que j\'ai adoré...'),
        const SizedBox(height: 12),
        // Suggestions rapides
        const Text('Ou choisissez une phrase prête :',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '👋 Bisou à toute la famille',
            '🏠 Journée tranquille à la maison',
            '🌳 Promenade au parc',
            '📺 Film en famille',
          ].map((s) => GestureDetector(
            onTap: () => setState(() => _momentCtrl.text = s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(s, style: const TextStyle(fontSize: 12)),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildBlankField(
      TextEditingController ctrl, String label, String hint) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
