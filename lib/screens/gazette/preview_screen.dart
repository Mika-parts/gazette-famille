import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../models/gazette.dart';
import '../../models/famille.dart';
import '../../models/page_gazette.dart';
import '../../utils/colors.dart';

class PreviewScreen extends StatefulWidget {
  final Gazette gazette;
  final Famille famille;

  const PreviewScreen({super.key, required this.gazette, required this.famille});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final _db = FirebaseFirestore.instance;
  List<PageGazette> _pages = [];
  final Map<String, String> _nomsAuteurs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages() async {
    setState(() => _loading = true);
    final snap = await _db
        .collection('gazettes')
        .doc(widget.gazette.id)
        .collection('pages')
        .where('soumis', isEqualTo: true)
        .get();

    _pages = snap.docs.map((d) =>
        PageGazette.fromFirestore(d.data(), d.id, widget.gazette.id)).toList();

    // Charger les noms des auteurs
    for (final page in _pages) {
      try {
        final userDoc = await _db.collection('users').doc(page.userId).get();
        if (userDoc.exists) {
          _nomsAuteurs[page.userId] = userDoc.data()?['displayName'] ?? page.userId;
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gazette — ${widget.gazette.moisLabel}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pages.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pages.length,
                  itemBuilder: (context, i) => _buildPageCard(_pages[i]),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.newspaper, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Aucune page soumise pour l\'instant',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('La gazette sera visible une fois que\nla famille aura contribué.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPageCard(PageGazette page) {
    final auteur = _nomsAuteurs[page.userId] ?? 'Membre';
    final isMe = page.userId == FirebaseAuth.instance.currentUser?.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header auteur
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.primary,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white24,
                  child: Text(
                    auteur.isNotEmpty ? auteur[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isMe ? 'Moi ($auteur)' : auteur,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(page.layoutIcone,
                    style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),

          // Photos
          if (page.photos.isNotEmpty)
            _buildPhotos(page),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                if (page.titre != null && page.titre!.isNotEmpty) ...[
                  Text(page.titre!,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17)),
                  const SizedBox(height: 8),
                ],

                // Texte principal
                if (page.texte != null && page.texte!.isNotEmpty) ...[
                  Text(page.texte!,
                      style: const TextStyle(
                          height: 1.5, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                ],

                // Mode blanks
                if (page.momentMagique != null) ...[
                  _buildBlankDisplay('🌟 Moment magique', page.momentMagique!),
                ],
                if (page.activite != null) ...[
                  _buildBlankDisplay('🎯 Ce que j\'ai fait', page.activite!),
                ],
                if (page.repas != null) ...[
                  _buildBlankDisplay('🍽️ Mon bon repas', page.repas!),
                ],

                // Humeur
                if (page.humeur != null) ...[
                  const Divider(),
                  Row(
                    children: [
                      Text(page.humeur!,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 8),
                      const Text('Humeur du mois',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ],

                // Meilleur + anticipation
                if (page.meilleurChose != null) ...[
                  const SizedBox(height: 8),
                  _buildHighlight('✨ Meilleure chose du mois', page.meilleurChose!),
                ],
                if (page.anticipation != null) ...[
                  const SizedBox(height: 6),
                  _buildHighlight('🔮 J\'attends', page.anticipation!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotos(PageGazette page) {
    if (page.photos.length == 1) {
      return CachedNetworkImage(
        imageUrl: page.photos[0],
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 220, color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 220, color: Colors.grey[200],
          child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 150,
      child: Row(
        children: page.photos.map((url) => Expanded(
          child: CachedNetworkImage(
            imageUrl: url,
            height: 150,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildBlankDisplay(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.split(' ')[0], style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.substring(label.indexOf(' ') + 1),
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                Text(value,
                    style: const TextStyle(color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlight(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.split(' ')[0], style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.substring(label.indexOf(' ') + 1),
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportPdf() async {
    setState(() => _loading = true);
    try {
      final doc = pw.Document();

      // ── Page de couverture ──────────────────────────────────────────
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(
                'Gazette Famille',
                style: pw.TextStyle(
                    fontSize: 38, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 2),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  widget.gazette.moisLabel.toUpperCase(),
                  style: const pw.TextStyle(
                      fontSize: 22, letterSpacing: 3),
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                widget.famille.nom,
                style: pw.TextStyle(
                    fontSize: 16, fontStyle: pw.FontStyle.italic),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                '${_pages.length} page${_pages.length > 1 ? 's' : ''}',
                style: const pw.TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ));

      // ── Page par contributeur ────────────────────────────────────────
      for (final page in _pages) {
        final auteur = _nomsAuteurs[page.userId] ?? 'Membre';

        // Téléchargement des photos
        final List<pw.ImageProvider> images = [];
        for (final url in page.photos) {
          try {
            final resp = await http.get(Uri.parse(url))
                .timeout(const Duration(seconds: 10));
            if (resp.statusCode == 200) {
              images.add(pw.MemoryImage(resp.bodyBytes));
            }
          } catch (_) {
            // Ignore erreurs réseau — la page reste sans photo
          }
        }

        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (pw.Context ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête auteur
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                color: PdfColors.blue800,
                child: pw.Text(
                  auteur,
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 14),

              // Photos
              if (images.isNotEmpty) ...[
                if (images.length == 1)
                  pw.ClipRRect(
                    verticalRadius: 6,
                    horizontalRadius: 6,
                    child: pw.Image(images[0],
                        height: 200, fit: pw.BoxFit.cover,
                        width: double.infinity),
                  ),
                if (images.length > 1)
                  pw.Row(
                    children: images
                        .map((img) => pw.Expanded(
                              child: pw.Padding(
                                padding:
                                    const pw.EdgeInsets.only(right: 4),
                                child: pw.Image(img,
                                    height: 140,
                                    fit: pw.BoxFit.cover),
                              ),
                            ))
                        .toList(),
                  ),
                pw.SizedBox(height: 12),
              ],

              // Titre
              if (page.titre != null && page.titre!.isNotEmpty) ...[
                pw.Text(page.titre!,
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
              ],

              // Texte principal
              if (page.texte != null && page.texte!.isNotEmpty) ...[
                pw.Text(page.texte!,
                    style: const pw.TextStyle(
                        fontSize: 11, lineSpacing: 3)),
                pw.SizedBox(height: 8),
              ],

              // Mode blancs
              if (page.momentMagique != null) ...[
                _pdfLigne('Moment magique', page.momentMagique!),
              ],
              if (page.activite != null) ...[
                _pdfLigne('Ce que j\'ai fait', page.activite!),
              ],
              if (page.repas != null) ...[
                _pdfLigne('Mon bon repas', page.repas!),
              ],

              // Séparateur humeur/highlights
              if (page.humeur != null ||
                  page.meilleurChose != null ||
                  page.anticipation != null) ...[
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 6),
                if (page.humeur != null)
                  pw.Text('Humeur du mois : ${page.humeur!}',
                      style: const pw.TextStyle(fontSize: 12)),
                if (page.meilleurChose != null)
                  _pdfLigne('Meilleure chose', page.meilleurChose!),
                if (page.anticipation != null)
                  _pdfLigne('J\'attends', page.anticipation!),
              ],
            ],
          ),
        ));
      }

      // Partage / impression
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'gazette_${widget.gazette.mois}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur PDF: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  pw.Widget _pdfLigne(String label, String valeur) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text('$label :',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(valeur,
                style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
