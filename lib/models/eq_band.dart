class EqBand {
  final int index;
  final int centerFrequency; // in Hz
  final double gainLevel; // in millibels (-1500 to +1500)

  const EqBand({
    required this.index,
    required this.centerFrequency,
    required this.gainLevel,
  });

  EqBand copyWith({
    int? index,
    int? centerFrequency,
    double? gainLevel,
  }) {
    return EqBand(
      index: index ?? this.index,
      centerFrequency: centerFrequency ?? this.centerFrequency,
      gainLevel: gainLevel ?? this.gainLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'centerFrequency': centerFrequency,
      'gainLevel': gainLevel,
    };
  }

  factory EqBand.fromJson(Map<String, dynamic> json) {
    return EqBand(
      index: json['index'] as int,
      centerFrequency: json['centerFrequency'] as int,
      gainLevel: (json['gainLevel'] as num).toDouble(),
    );
  }
}
