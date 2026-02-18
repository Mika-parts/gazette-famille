import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';

class CreateFamilleScreen extends StatefulWidget {
  const CreateFamilleScreen({super.key});

  @override
  State<CreateFamilleScreen> createState() => _CreateFamilleScreenState();
}

class _CreateFamilleScreenState extends State<CreateFamilleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  String _plan = 'starter';
  bool _saving = false;

  final List<Map<String, dynamic>> _plans = [
    {'value': 'starter', 'label': 'Starter', 'foyers': 4, 'prix': '2,99€/mois', 'color': AppColors.planStarter},
    {'value': 'famille', 'label': 'Famille', 'foyers': 6, 'prix': '4,99€/mois', 'color': AppColors.planFamille},
    {'value': 'etendu', 'label': 'Étendu', 'foyers': 8, 'prix': '6,99€/mois', 'color': AppColors.planEtendu},
    {'value': 'maxi', 'label': 'Maxi', 'foyers': 10, 'prix': '8,99€/mois', 'color': AppColors.planMaxi},
  ];

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final plan = _plans.firstWhere((p) => p['value'] == _plan);

    try {
      final ref = FirebaseFirestore.instance.collection('familles').doc();
      await ref.set({
        'nom': _nomCtrl.text.trim(),
        'createur_id': uid,
        'plan': _plan,
        'max_foyers': plan['foyers'],
        'membre_ids': [uid],
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Famille créée ! Invitez vos proches.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Créer une famille')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Nom de votre famille',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomCtrl,
              decoration: InputDecoration(
                hintText: 'Famille Martin, Clan Dupont...',
                prefixIcon: const Icon(Icons.family_restroom),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 24),

            const Text('Choisissez votre forfait',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),

            ...List.generate(_plans.length, (i) {
              final plan = _plans[i];
              final selected = _plan == plan['value'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () => setState(() => _plan = plan['value'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? (plan['color'] as Color)
                            : Colors.grey[300]!,
                        width: selected ? 2 : 1,
                      ),
                      color: selected
                          ? (plan['color'] as Color).withValues(alpha: 0.06)
                          : Colors.white,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: (plan['color'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text('${plan['foyers']}',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: plan['color'] as Color)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Plan ${plan['label']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              Text('Jusqu\'à ${plan['foyers']} foyers',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(plan['prix'] as String,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: plan['color'] as Color)),
                            if (selected)
                              Icon(Icons.check_circle,
                                  color: plan['color'] as Color, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plus de 10 foyers ? Contactez-nous à gazette@cenaia-labs.com',
                      style: TextStyle(color: AppColors.info, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _saving ? null : _create,
              icon: _saving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.newspaper),
              label: const Text('Créer la famille'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
