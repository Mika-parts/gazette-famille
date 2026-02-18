class Famille {
  final String id;
  final String nom;
  final String createurId;
  final String plan; // starter, famille, etendu, maxi, custom
  final int maxFoyers;
  final List<String> membreIds;
  final DateTime createdAt;

  Famille({
    required this.id,
    required this.nom,
    required this.createurId,
    required this.plan,
    required this.maxFoyers,
    required this.membreIds,
    required this.createdAt,
  });

  int get maxFoyersPlan {
    switch (plan) {
      case 'famille': return 6;
      case 'etendu': return 8;
      case 'maxi': return 10;
      default: return 4; // starter
    }
  }

  String get planLabel {
    switch (plan) {
      case 'famille': return 'Famille (6 foyers)';
      case 'etendu': return 'Étendu (8 foyers)';
      case 'maxi': return 'Maxi (10 foyers)';
      default: return 'Starter (4 foyers)';
    }
  }

  String get prixMensuel {
    switch (plan) {
      case 'famille': return '4,99€/mois';
      case 'etendu': return '6,99€/mois';
      case 'maxi': return '8,99€/mois';
      default: return '2,99€/mois';
    }
  }

  factory Famille.fromFirestore(Map<String, dynamic> data, String id) {
    return Famille(
      id: id,
      nom: data['nom'] ?? '',
      createurId: data['createur_id'] ?? '',
      plan: data['plan'] ?? 'starter',
      maxFoyers: data['max_foyers'] ?? 4,
      membreIds: List<String>.from(data['membre_ids'] ?? []),
      createdAt: (data['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nom': nom,
      'createur_id': createurId,
      'plan': plan,
      'max_foyers': maxFoyers,
      'membre_ids': membreIds,
      'created_at': createdAt,
    };
  }
}
