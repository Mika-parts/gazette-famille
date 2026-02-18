import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/famille.dart';
import '../../models/gazette.dart';
import '../../utils/colors.dart';
import '../gazette/gazette_screen.dart';
import '../famille/create_famille_screen.dart';
import '../contribution/contribution_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  List<Famille> _familles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilles();
  }

  Future<void> _loadFamilles() async {
    setState(() => _loading = true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final snap = await _db
          .collection('familles')
          .where('membre_ids', arrayContains: uid)
          .get();
      _familles = snap.docs
          .map((d) => Famille.fromFirestore(d.data(), d.id))
          .toList();
    } catch (e) {
      debugPrint('Erreur chargement familles: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final prenom = user?.displayName?.split(' ').first ?? 'Vous';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gazette Famille'),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
            tooltip: 'Mon profil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadFamilles,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bonjour
                    Text('Bonjour, $prenom 👋',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    if (_familles.isEmpty)
                      _buildEmptyState()
                    else
                      ..._familles.map((f) => _buildFamilleCard(f)),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateFamilleScreen()),
        ).then((_) => _loadFamilles()),
        icon: const Icon(Icons.add),
        label: const Text('Créer une famille'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.newspaper, size: 50, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('Bienvenue dans Gazette Famille!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text(
              'Créez votre première famille ou\nattendez une invitation.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateFamilleScreen()),
              ).then((_) => _loadFamilles()),
              icon: const Icon(Icons.add),
              label: const Text('Créer une famille'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilleCard(Famille famille) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GazetteScreen(famille: famille)),
        ).then((_) => _loadFamilles()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.family_restroom,
                        color: AppColors.primary, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(famille.nom,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(famille.planLabel,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textLight),
                ],
              ),
              const SizedBox(height: 12),
              _buildGazetteMoisCard(famille),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGazetteMoisCard(Famille famille) {
    final moisActuel = DateFormat('yyyy-MM').format(DateTime.now());

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('gazettes')
          .where('famille_id', isEqualTo: famille.id)
          .where('mois', isEqualTo: moisActuel)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const LinearProgressIndicator();
        }

        final uid = _auth.currentUser?.uid ?? '';

        if (snap.data!.docs.isEmpty) {
          // Pas encore de gazette ce mois
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.hourglass_empty,
                    color: AppColors.warning, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Gazette pas encore créée ce mois',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          );
        }

        final gazetteDoc = snap.data!.docs.first;
        final gazette = Gazette.fromFirestore(
            gazetteDoc.data() as Map<String, dynamic>, gazetteDoc.id);

        // Check si l'utilisateur a déjà contribué
        return StreamBuilder<DocumentSnapshot>(
          stream: _db
              .collection('gazettes')
              .doc(gazette.id)
              .collection('pages')
              .doc(uid)
              .snapshots(),
          builder: (context, pageSnap) {
            final aContribue = pageSnap.data?.exists == true &&
                (pageSnap.data?.data() as Map?)?['soumis'] == true;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: aContribue
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    aContribue ? Icons.check_circle : Icons.edit_note,
                    color: aContribue ? AppColors.success : AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      aContribue
                          ? '✅ Ta page du mois est soumise!'
                          : '📝 Ta page du mois n\'est pas encore faite',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (!aContribue)
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContributionScreen(
                            gazette: gazette,
                            famille: famille,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          textStyle: const TextStyle(fontSize: 12)),
                      child: const Text('Écrire'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
