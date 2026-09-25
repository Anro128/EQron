class EqPreset {
  final String id;
  final String name;
  final int bandCount;
  final List<double> gains;
  final bool isDefault;

  const EqPreset({
    required this.id,
    required this.name,
    required this.bandCount,
    required this.gains,
    this.isDefault = false,
  });

  EqPreset copyWith({
    String? id,
    String? name,
    int? bandCount,
    List<double>? gains,
    bool? isDefault,
  }) {
    return EqPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      bandCount: bandCount ?? this.bandCount,
      gains: gains ?? this.gains,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bandCount': bandCount,
      'gains': gains,
      'isDefault': isDefault,
    };
  }

  factory EqPreset.fromJson(Map<String, dynamic> json) {
    return EqPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      bandCount: json['bandCount'] as int,
      gains: (json['gains'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  static List<EqPreset> getDefaultPresets() {
    return const [
      EqPreset(id: 'flat_3', name: 'Flat', bandCount: 3, gains: [0, 0, 0], isDefault: true),
      EqPreset(id: 'pop_3', name: 'Pop', bandCount: 3, gains: [300, 0, 300], isDefault: true),
      EqPreset(id: 'rock_3', name: 'Rock', bandCount: 3, gains: [500, 200, 0], isDefault: true),
      EqPreset(id: 'jazz_3', name: 'Jazz', bandCount: 3, gains: [400, -200, 400], isDefault: true),
      EqPreset(id: 'acoustic_3', name: 'Acoustic', bandCount: 3, gains: [200, 100, 300], isDefault: true),
      EqPreset(id: 'bass_boost_3', name: 'Bass Boost', bandCount: 3, gains: [800, 0, 0], isDefault: true),
      EqPreset(id: 'treble_boost_3', name: 'Treble Boost', bandCount: 3, gains: [0, 0, 800], isDefault: true),
      EqPreset(id: 'vocal_3', name: 'Vocal', bandCount: 3, gains: [0, 500, 0], isDefault: true),
      EqPreset(id: 'movie_3', name: 'Movie 🎬', bandCount: 3, gains: [600, 300, 400], isDefault: true),

      EqPreset(id: 'flat_5', name: 'Flat', bandCount: 5, gains: [0, 0, 0, 0, 0], isDefault: true),
      EqPreset(id: 'pop_5', name: 'Pop', bandCount: 5, gains: [300, 100, 0, 100, 300], isDefault: true),
      EqPreset(id: 'rock_5', name: 'Rock', bandCount: 5, gains: [500, 300, 0, 200, 400], isDefault: true),
      EqPreset(id: 'jazz_5', name: 'Jazz', bandCount: 5, gains: [400, 200, -200, 200, 400], isDefault: true),
      EqPreset(id: 'acoustic_5', name: 'Acoustic', bandCount: 5, gains: [200, 100, 0, 100, 300], isDefault: true),
      EqPreset(id: 'bass_boost_5', name: 'Bass Boost', bandCount: 5, gains: [800, 400, 0, 0, 0], isDefault: true),
      EqPreset(id: 'treble_boost_5', name: 'Treble Boost', bandCount: 5, gains: [0, 0, 0, 400, 800], isDefault: true),
      EqPreset(id: 'vocal_5', name: 'Vocal', bandCount: 5, gains: [-100, 200, 500, 200, -100], isDefault: true),
      EqPreset(id: 'movie_5', name: 'Movie 🎬', bandCount: 5, gains: [600, 300, 400, 300, 500], isDefault: true),

      EqPreset(id: 'flat_7', name: 'Flat', bandCount: 7, gains: [0, 0, 0, 0, 0, 0, 0], isDefault: true),
      EqPreset(id: 'pop_7', name: 'Pop', bandCount: 7, gains: [300, 200, 100, 0, 100, 200, 300], isDefault: true),
      EqPreset(id: 'rock_7', name: 'Rock', bandCount: 7, gains: [500, 400, 200, 0, 100, 300, 400], isDefault: true),
      EqPreset(id: 'movie_7', name: 'Movie 🎬', bandCount: 7, gains: [700, 500, 200, 400, 300, 400, 600], isDefault: true),

      EqPreset(id: 'flat_10', name: 'Flat', bandCount: 10, gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], isDefault: true),
      EqPreset(id: 'pop_10', name: 'Pop', bandCount: 10, gains: [300, 200, 150, 100, 0, 0, 100, 150, 200, 300], isDefault: true),
      EqPreset(id: 'rock_10', name: 'Rock', bandCount: 10, gains: [500, 400, 300, 150, 0, 0, 150, 300, 400, 400], isDefault: true),
      EqPreset(id: 'movie_10', name: 'Movie 🎬', bandCount: 10, gains: [700, 600, 400, 200, 300, 400, 300, 400, 500, 600], isDefault: true),

      EqPreset(id: 'flat_15', name: 'Flat', bandCount: 15, gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], isDefault: true),
      EqPreset(id: 'pop_15', name: 'Pop', bandCount: 15, gains: [300, 250, 200, 150, 100, 50, 0, 0, 50, 100, 150, 200, 250, 300, 300], isDefault: true),
      EqPreset(id: 'rock_15', name: 'Rock', bandCount: 15, gains: [500, 450, 400, 350, 250, 150, 50, 0, 50, 150, 250, 350, 400, 450, 450], isDefault: true),
      EqPreset(id: 'movie_15', name: 'Movie 🎬', bandCount: 15, gains: [800, 700, 600, 400, 200, 200, 300, 400, 400, 300, 300, 400, 500, 600, 700], isDefault: true),
    ];
  }
}
