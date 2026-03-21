class NearbyFilter {
  const NearbyFilter({
    this.minAge = 18,
    this.maxAge = 45,
    this.onlineOnly = false,
    this.tag = '',
    this.mbtiType = '',
    this.zodiacSign = '',
  });

  final int minAge;
  final int maxAge;
  final bool onlineOnly;
  final String tag;
  final String mbtiType;
  final String zodiacSign;

  NearbyFilter copyWith({
    int? minAge,
    int? maxAge,
    bool? onlineOnly,
    String? tag,
    String? mbtiType,
    String? zodiacSign,
  }) {
    return NearbyFilter(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      tag: tag ?? this.tag,
      mbtiType: mbtiType ?? this.mbtiType,
      zodiacSign: zodiacSign ?? this.zodiacSign,
    );
  }
}
