import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/famille.dart';
import '../../utils/colors.dart';

// ignore: unused_element

class InviteScreen extends StatefulWidget {
  final Famille famille;

  const InviteScreen({super.key, required this.famille});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  String? _lienInvite;
  bool _loading = false;

  String get _lienWeb =>
      'https://gazette.cenaia-labs.com/invite/${widget.famille.id}';

  Future<void> _genererLien() async {
    setState(() => _loading = true);
    // Stocker le token d'invitation dans Firestore
    await FirebaseFirestore.instance
        .collection('familles')
        .doc(widget.famille.id)
        .update({
      'invite_token': widget.famille.id, // Simple : l'ID suffit pour V1
      'invite_updated_at': FieldValue.serverTimestamp(),
    });
    setState(() {
      _lienInvite = _lienWeb;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _genererLien();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inviter des membres')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info famille
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.family_restroom,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.famille.nom,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                          '${widget.famille.membreIds.length}/${widget.famille.maxFoyers} foyers',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          const Text('Lien d\'invitation',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text(
              'Partagez ce lien avec vos proches. Ils pourront rejoindre la famille et contribuer à la gazette.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),

          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_lienInvite != null) ...[
            // Lien copiable
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _lienInvite!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _lienInvite!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('✅ Lien copié !'),
                            backgroundColor: AppColors.success),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Boutons de partage
            ElevatedButton.icon(
              onPressed: () => Share.share(
                '🗞️ Rejoins notre Gazette Famille "${widget.famille.nom}" !\n\n$_lienInvite',
              ),
              icon: const Icon(Icons.share),
              label: const Text('Partager le lien'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                final msg =
                    '🗞️ Rejoins notre Gazette Famille "${widget.famille.nom}" !\n\nClique ici : $_lienInvite';
                Share.share(msg);
              },
              icon: const Icon(Icons.message_outlined),
              label: const Text('Envoyer par SMS / WhatsApp'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
            ),
          ],
          const SizedBox(height: 28),

          // Instructions
          const Text('Comment ça marche ?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          _buildStep('1', 'Partagez le lien avec votre famille'),
          _buildStep('2', 'Chacun crée son compte et rejoint la famille'),
          _buildStep('3', 'Tout le monde peut contribuer à la gazette du mois'),
          _buildStep('4', 'À la fin du mois, la gazette est prête à imprimer ! 🎉'),
          const SizedBox(height: 24),

          // Limite foyers
          if (widget.famille.membreIds.length >= widget.famille.maxFoyers)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_outlined,
                      color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        'Limite de foyers atteinte. Passez au plan supérieur pour inviter plus de membres.',
                        style: TextStyle(
                            color: AppColors.warning, fontSize: 12)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(text,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}
