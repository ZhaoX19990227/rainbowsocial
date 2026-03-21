class NearbyFilter {
  const NearbyFilter({
    this.minAge = 18,
    this.maxAge = 45,
    this.onlineOnly = false,
    this.tag = '',
  });

  final int minAge;
  final int maxAge;
  final bool onlineOnly;
  final String tag;

  NearbyFilter copyWith({
    int? minAge,
    int? maxAge,
    bool? onlineOnly,
    String? tag,
  }) {
    return NearbyFilter(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      tag: tag ?? this.tag,
    );
  }
}
