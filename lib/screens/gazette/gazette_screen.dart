import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/famille.dart';
import '../../models/gazette.dart';
import '../../utils/colors.dart';
import '../contribution/contribution_screen.dart';
import '../famille/invite_screen.dart';
import 'preview_screen.dart';

class GazetteScreen extends StatefulWidget {
  final Famille famille;

  const GazetteScreen({super.key, required this.famille});

  @override
  State<GazetteScreen> createState() => _GazetteScreenState();
}

class _GazetteScreenState extends State<GazetteScreen> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final moisActuel = DateFormat('yyyy-MM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.famille.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Inviter',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => InviteScreen(famille: widget.famille)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('gazettes')
            .where('famille_id', isEqualTo: widget.famille.id)
            .orderBy('mois', descending: true)
            .limit(6)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final gazettes = snap.data?.docs
              .map((d) => Gazette.fromFirestore(d.data() as Map<String, dynamic>, d.id))
              .toList() ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Gazette du mois
              _buildMoisActuel(moisActuel, gazettes),
              const SizedBox(height: 24),

              // Historique
              if (gazettes.isNotEmpty) ...[
                const Text('Historique',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...gazettes.map((g) => _buildGazetteCard(g)),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createGazetteMois(moisActuel),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle gazette'),
      ),
    );
  }

  Widget _buildMoisActuel(String moisActuel, List<Gazette> gazettes) {
    final gazetteActuelle = gazettes.where((g) => g.mois == moisActuel).firstOrNull;

    if (gazetteActuelle == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.newspaper, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text('Gazette du mois non créée',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Lancez la gazette de ce mois pour que la famille commence à contribuer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _createGazetteMois(moisActuel),
                icon: const Icon(Icons.add),
                label: const Text('Créer la gazette du mois'),
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44)),
              ),
            ],
          ),
        ),
      );
    }

    return _buildGazetteCard(gazetteActuelle, isActuelle: true);
  }

  Widget _buildGazetteCard(Gazette gazette, {bool isActuelle = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (gazette.estOuvert) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ContributionScreen(
                  gazette: gazette,
                  famille: widget.famille,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PreviewScreen(
                  gazette: gazette,
                  famille: widget.famille,
                ),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statutColor(gazette.statut).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(gazette.moisLabel,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _statutColor(gazette.statut))),
                  ),
                  const Spacer(),
                  _buildStatutBadge(gazette.statut),
                ],
              ),
              if (gazette.deadline != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Deadline : ${DateFormat('d MMM', 'fr_FR').format(gazette.deadline!)}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
              if (gazette.estOuvert) ...[
                const SizedBox(height: 12),
                // Progress pages soumises
                StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('gazettes')
                      .doc(gazette.id)
                      .collection('pages')
                      .where('soumis', isEqualTo: true)
                      .snapshots(),
                  builder: (context, pSnap) {
                    final pages = pSnap.data?.docs.length ?? 0;
                    final total = widget.famille.maxFoyers;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('$pages/$total pages soumises',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary)),
                            if (pages > 0)
                              Text('${(pages / total * 100).toInt()}%',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: total > 0 ? pages / total : 0,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.success),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatutBadge(String statut) {
    String label;
    Color color;
    switch (statut) {
      case 'ferme':
        label = 'Fermée';
        color = AppColors.warning;
        break;
      case 'imprime':
        label = 'Imprimée';
        color = AppColors.success;
        break;
      default:
        label = 'Ouverte';
        color = AppColors.success;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'ferme': return AppColors.warning;
      case 'imprime': return AppColors.success;
      default: return AppColors.primary;
    }
  }

  Future<void> _createGazetteMois(String mois) async {
    try {
      await _db.collection('gazettes').add({
        'famille_id': widget.famille.id,
        'mois': mois,
        'statut': 'ouvert',
        'deadline': DateTime.now().add(const Duration(days: 25)),
        'created_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📰 Gazette du mois créée ! La famille peut contribuer.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }
}
