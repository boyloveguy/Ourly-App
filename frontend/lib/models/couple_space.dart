enum CoupleStatus { solo, connected, archived }

enum ParticipantRole { creator, invitee }

class Participant {
  final String id;
  final String? linkedUserId;
  final String nickname;
  final ParticipantRole role;
  final DateTime createdAt;

  Participant({
    required this.id,
    this.linkedUserId,
    required this.nickname,
    required this.role,
    required this.createdAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String,
      linkedUserId: json['linkedUserId'] as String?,
      nickname: json['nickname'] as String? ?? 'Partner',
      role: (json['role'] == 'creator') ? ParticipantRole.creator : ParticipantRole.invitee,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'linkedUserId': linkedUserId,
    'nickname': nickname,
    'role': role == ParticipantRole.creator ? 'creator' : 'invitee',
    'createdAt': createdAt.toIso8601String(),
  };
}

class CoupleSpace {
  final String id;
  final CoupleStatus status;
  final List<Participant> participants;
  final DateTime createdAt;
  final DateTime updatedAt;

  CoupleSpace({
    required this.id,
    required this.status,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CoupleSpace.fromJson(Map<String, dynamic> json) {
    CoupleStatus parseStatus(String? s) {
      if (s == 'connected') return CoupleStatus.connected;
      if (s == 'archived') return CoupleStatus.archived;
      return CoupleStatus.solo;
    }

    return CoupleSpace(
      id: json['id'] as String,
      status: parseStatus(json['status'] as String?),
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((p) => Participant.fromJson(p as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Participant? get creatorParticipant =>
      participants.firstWhere((p) => p.role == ParticipantRole.creator, orElse: () => participants.first);

  Participant? get partnerParticipant =>
      participants.firstWhere((p) => p.role == ParticipantRole.invitee, orElse: () => participants.last);

  Participant? participantForUser(String uid) {
    for (final p in participants) {
      if (p.linkedUserId == uid) return p;
    }
    return null;
  }
}
