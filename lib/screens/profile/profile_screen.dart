import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _nomCtrl = TextEditingController();
  bool _saving = false;
  String? _email;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _email = user.email;
    final doc = await _db.collection('users').doc(user.uid).get();
    if (doc.exists) {
      _nomCtrl.text = doc.data()?['displayName'] ?? user.displayName ?? '';
    } else {
      _nomCtrl.text = user.displayName ?? '';
    }
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);

    final nom = _nomCtrl.text.trim();

    try {
      // Mettre à jour Firebase Auth
      await user.updateDisplayName(nom);

      // Mettre à jour Firestore
      await _db.collection('users').doc(user.uid).set({
        'displayName': nom,
        'email': user.email,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Profil mis à jour !'),
              backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
            'Vous serez redirigé vers l\'écran de connexion.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Déconnexion',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      await _auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                _nomCtrl.text.isNotEmpty
                    ? _nomCtrl.text[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontSize: 40,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Email (non modifiable)
          if (_email != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email_outlined,
                      color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_email!,
                        style: const TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                  const Text('Email',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textLight)),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Nom affiché
          TextFormField(
            controller: _nomCtrl,
            decoration: InputDecoration(
              labelText: 'Votre prénom / pseudo',
              hintText: 'Ex: Mamie Josette, Papa, Marie...',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              helperText:
                  'Ce nom sera affiché dans la gazette',
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('Enregistrer'),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48)),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Infos app
          ListTile(
            leading: const Icon(Icons.info_outline,
                color: AppColors.textSecondary),
            title: const Text('Gazette Famille'),
            subtitle: Text(
                'Version 1.0.0\nUID: ${user?.uid.substring(0, 8) ?? "—"}...'),
            isThreeLine: true,
          ),

          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _deconnecter,
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: const Text('Se déconnecter',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
