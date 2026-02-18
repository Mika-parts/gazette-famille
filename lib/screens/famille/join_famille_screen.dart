import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';

/// Écran pour rejoindre une famille via un lien d'invitation.
/// Appelé quand l'utilisateur clique sur le deep link gazette://invite/{familleId}
class JoinFamilleScreen extends StatefulWidget {
  final String familleId;

  const JoinFamilleScreen({super.key, required this.familleId});

  @override
  State<JoinFamilleScreen> createState() => _JoinFamilleScreenState();
}

class _JoinFamilleScreenState extends State<JoinFamilleScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _loading = true;
  bool _joining = false;
  String? _error;
  Map<String, dynamic>? _familleData;

  @override
  void initState() {
    super.initState();
    _loadFamille();
  }

  Future<void> _loadFamille() async {
    try {
      final doc = await _db.collection('familles').doc(widget.familleId).get();
      if (!doc.exists) {
        setState(() {
          _error = 'Invitation invalide ou expirée.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _familleData = doc.data();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur : $e';
        _loading = false;
      });
    }
  }

  Future<void> _rejoindre() async {
    if (_familleData == null) return;
    setState(() => _joining = true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) throw Exception('Non connecté');

      final membres = List<String>.from(_familleData!['membre_ids'] ?? []);

      // Déjà membre ?
      if (membres.contains(uid)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Vous êtes déjà membre de cette famille !'),
                backgroundColor: AppColors.info),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Vérifier limite
      final maxFoyers = _familleData!['max_foyers'] ?? 4;
      if (membres.length >= maxFoyers) {
        setState(() {
          _error = 'Cette famille a atteint sa limite de $maxFoyers foyers.';
          _joining = false;
        });
        return;
      }

      // Ajouter le membre
      await _db.collection('familles').doc(widget.familleId).update({
        'membre_ids': FieldValue.arrayUnion([uid]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Bienvenue dans "${_familleData!['nom']}" !'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // true = rejoint avec succès
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la jonction : $e';
        _joining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _buildInvite(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 16)),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvite() {
    final nom = _familleData!['nom'] ?? 'Famille';
    final membres = List.from(_familleData!['membre_ids'] ?? []);
    final maxFoyers = _familleData!['max_foyers'] ?? 4;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.family_restroom,
                size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 24),

          const Text('Invitation',
              style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(nom,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          const Text(
            'Rejoignez cette famille pour contribuer à la gazette mensuelle !',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            '${membres.length}/$maxFoyers foyers',
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),

          ElevatedButton.icon(
            onPressed: _joining ? null : _rejoindre,
            icon: _joining
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.group_add),
            label: const Text('Rejoindre la famille'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Pas maintenant'),
          ),
        ],
      ),
    );
  }
}
