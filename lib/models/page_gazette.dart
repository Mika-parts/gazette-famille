class PageGazette {
  final String userId;
  final String gazetteId;
  final String layout; // 1photo, 2photos, 3photos, blanks
  final String? titre;
  final String? texte;
  final List<String> photos; // URLs Firebase Storage
  final String? humeur; // emoji
  final String? meilleurChose;
  final String? anticipation;
  // Champs "blanks" (textes à trous)
  final String? momentMagique;
  final String? activite;
  final String? repas;
  final bool soumis;
  final DateTime? updatedAt;

  // Métadonnées auteur (chargées séparément)
  String? auteurNom;
  String? auteurPhoto;

  PageGazette({
    required this.userId,
    required this.gazetteId,
    required this.layout,
    this.titre,
    this.texte,
    required this.photos,
    this.humeur,
    this.meilleurChose,
    this.anticipation,
    this.momentMagique,
    this.activite,
    this.repas,
    this.soumis = false,
    this.updatedAt,
    this.auteurNom,
    this.auteurPhoto,
  });

  String get layoutLabel {
    switch (layout) {
      case '2photos': return '2 photos + texte';
      case '3photos': return '3 photos + texte court';
      case 'blanks': return 'Texte à trous';
      default: return '1 photo + grand texte';
    }
  }

  String get layoutIcone {
    switch (layout) {
      case '2photos': return '🖼️🖼️';
      case '3photos': return '🖼️🖼️🖼️';
      case 'blanks': return '📝';
      default: return '🖼️';
    }
  }

  factory PageGazette.fromFirestore(Map<String, dynamic> data, String userId, String gazetteId) {
    return PageGazette(
      userId: userId,
      gazetteId: gazetteId,
      layout: data['layout'] ?? '1photo',
      titre: data['titre'],
      texte: data['texte'],
      photos: List<String>.from(data['photos'] ?? []),
      humeur: data['humeur'],
      meilleurChose: data['meilleur_chose'],
      anticipation: data['anticipation'],
      momentMagique: data['moment_magique'],
      activite: data['activite'],
      repas: data['repas'],
      soumis: data['soumis'] ?? false,
      updatedAt: (data['updated_at'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'layout': layout,
      'titre': titre,
      'texte': texte,
      'photos': photos,
      'humeur': humeur,
      'meilleur_chose': meilleurChose,
      'anticipation': anticipation,
      'moment_magique': momentMagique,
      'activite': activite,
      'repas': repas,
      'soumis': soumis,
      'updated_at': updatedAt ?? DateTime.now(),
    };
  }

  PageGazette copyWith({
    String? layout,
    String? titre,
    String? texte,
    List<String>? photos,
    String? humeur,
    String? meilleurChose,
    String? anticipation,
    String? momentMagique,
    String? activite,
    String? repas,
    bool? soumis,
  }) {
    return PageGazette(
      userId: userId,
      gazetteId: gazetteId,
      layout: layout ?? this.layout,
      titre: titre ?? this.titre,
      texte: texte ?? this.texte,
      photos: photos ?? this.photos,
      humeur: humeur ?? this.humeur,
      meilleurChose: meilleurChose ?? this.meilleurChose,
      anticipation: anticipation ?? this.anticipation,
      momentMagique: momentMagique ?? this.momentMagique,
      activite: activite ?? this.activite,
      repas: repas ?? this.repas,
      soumis: soumis ?? this.soumis,
      updatedAt: DateTime.now(),
      auteurNom: auteurNom,
      auteurPhoto: auteurPhoto,
    );
  }
}
