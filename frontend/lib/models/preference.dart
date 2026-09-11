enum PreferenceSource { selfDeclared, partnerObserved }

enum PreferenceVisibility { private, shared }

class PreferenceItem {
  final String id;
  final String subjectParticipantId;
  final String createdByUserId;
  final PreferenceSource source;
  final String type;
  final String value;
  final PreferenceVisibility visibility;
  final DateTime createdAt;
  final DateTime updatedAt;

  PreferenceItem({
    required this.id,
    required this.subjectParticipantId,
    required this.createdByUserId,
    required this.source,
    required this.type,
    required this.value,
    required this.visibility,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSurprise => type.toLowerCase() == 'surprise';

  factory PreferenceItem.fromJson(Map<String, dynamic> json) {
    return PreferenceItem(
      id: json['id'] as String,
      subjectParticipantId: json['subjectParticipantId'] as String? ?? '',
      createdByUserId: json['createdByUserId'] as String? ?? '',
      source: (json['source'] == 'selfDeclared')
          ? PreferenceSource.selfDeclared
          : PreferenceSource.partnerObserved,
      type: json['type'] as String? ?? 'General',
      value: json['value'] as String? ?? '',
      visibility: (json['visibility'] == 'shared')
          ? PreferenceVisibility.shared
          : PreferenceVisibility.private,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subjectParticipantId': subjectParticipantId,
    'createdByUserId': createdByUserId,
    'source': source == PreferenceSource.selfDeclared ? 'selfDeclared' : 'partnerObserved',
    'type': type,
    'value': value,
    'visibility': visibility == PreferenceVisibility.shared ? 'shared' : 'private',
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
