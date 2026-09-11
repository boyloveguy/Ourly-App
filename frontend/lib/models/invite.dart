enum InviteStatus { pending, accepted, declined, revoked, expired }

class InviteItem {
  final String id;
  final String coupleId;
  final String token;
  final InviteStatus status;
  final DateTime expiresAt;
  final DateTime createdAt;

  InviteItem({
    required this.id,
    required this.coupleId,
    required this.token,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory InviteItem.fromJson(Map<String, dynamic> json) {
    InviteStatus parseStatus(String? s) {
      if (s == 'accepted') return InviteStatus.accepted;
      if (s == 'declined') return InviteStatus.declined;
      if (s == 'revoked') return InviteStatus.revoked;
      if (s == 'expired') return InviteStatus.expired;
      return InviteStatus.pending;
    }

    return InviteItem(
      id: json['id'] as String,
      coupleId: json['coupleId'] as String,
      token: json['tokenHash'] as String? ?? json['token'] as String? ?? '',
      status: parseStatus(json['status'] as String?),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class InvitePreview {
  final String inviterNickname;
  final InviteStatus status;
  final DateTime expiresAt;

  InvitePreview({
    required this.inviterNickname,
    required this.status,
    required this.expiresAt,
  });

  factory InvitePreview.fromJson(Map<String, dynamic> json) {
    InviteStatus parseStatus(String? s) {
      if (s == 'accepted') return InviteStatus.accepted;
      if (s == 'declined') return InviteStatus.declined;
      if (s == 'revoked') return InviteStatus.revoked;
      if (s == 'expired') return InviteStatus.expired;
      return InviteStatus.pending;
    }

    return InvitePreview(
      inviterNickname: json['inviterNickname'] as String? ?? 'Người ấy',
      status: parseStatus(json['status'] as String?),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
