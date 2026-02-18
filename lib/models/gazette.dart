class Gazette {
  final String id;
  final String familleId;
  final String mois; // format "2026-02"
  final String statut; // ouvert, ferme, imprime
  final DateTime? deadline;
  final DateTime createdAt;

  Gazette({
    required this.id,
    required this.familleId,
    required this.mois,
    required this.statut,
    this.deadline,
    required this.createdAt,
  });

  String get moisLabel {
    final parts = mois.split('-');
    if (parts.length < 2) return mois;
    final annee = parts[0];
    final m = int.tryParse(parts[1]) ?? 1;
    const moisLabels = ['', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai',
      'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return '${moisLabels[m]} $annee';
  }

  bool get estOuvert => statut == 'ouvert';
  bool get estFerme => statut == 'ferme';
  bool get estImprime => statut == 'imprime';

  factory Gazette.fromFirestore(Map<String, dynamic> data, String id) {
    return Gazette(
      id: id,
      familleId: data['famille_id'] ?? '',
      mois: data['mois'] ?? '',
      statut: data['statut'] ?? 'ouvert',
      deadline: (data['deadline'] as dynamic)?.toDate(),
      createdAt: (data['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'famille_id': familleId,
      'mois': mois,
      'statut': statut,
      'deadline': deadline,
      'created_at': createdAt,
    };
  }
}
