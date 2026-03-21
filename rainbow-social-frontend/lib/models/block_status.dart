class BlockStatus {
  const BlockStatus({
    required this.isBlocked,
    required this.blockedByMe,
    required this.blockedByTarget,
    this.reason = '',
  });

  final bool isBlocked;
  final bool blockedByMe;
  final bool blockedByTarget;
  final String reason;

  factory BlockStatus.fromJson(Map<String, dynamic> json) {
    return BlockStatus(
      isBlocked: json['is_blocked'] == true,
      blockedByMe: json['blocked_by_me'] == true,
      blockedByTarget: json['blocked_by_target'] == true,
      reason: '${json['reason'] ?? ''}',
    );
  }

  const BlockStatus.none()
      : isBlocked = false,
        blockedByMe = false,
        blockedByTarget = false,
        reason = '';
}
