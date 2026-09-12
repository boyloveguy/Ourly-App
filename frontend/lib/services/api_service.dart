import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/couple_space.dart';
import '../models/preference.dart';
import '../models/invite.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:8000'),
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Active Session State
  AppUser? currentUser;
  String? currentToken;

  // In-memory fallback repository for offline resilience
  final Map<String, CoupleSpace> _mockCouples = {};
  final Map<String, String> _mockUserCouple = {};
  final Map<String, InviteItem> _mockInvites = {};
  final Map<String, List<PreferenceItem>> _mockPreferences = {};
  final Map<String, List<Map<String, dynamic>>> _mockChatHistory = {};

  ApiService._internal() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (currentToken != null) {
          options.headers['Authorization'] = 'Bearer $currentToken';
        }
        return handler.next(options);
      },
    ));
  }

  // --- AUTH METHODS ---
  Future<AppUser> register({
    required String email,
    required String password,
    String? nickname,
  }) async {
    final res = await _dio.post('/v1/auth/register', data: {
      'email': email.trim(),
      'password': password.trim(),
      if (nickname != null && nickname.trim().isNotEmpty) 'nickname': nickname.trim(),
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final userData = data['user'] as Map<String, dynamic>;

    currentToken = token;
    currentUser = AppUser.fromJson(userData);
    return currentUser!;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/v1/auth/login', data: {
      'email': email.trim(),
      'password': password.trim(),
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final userData = data['user'] as Map<String, dynamic>;

    currentToken = token;
    currentUser = AppUser.fromJson(userData);
    return currentUser!;
  }

  void logout() {
    currentUser = null;
    currentToken = null;
  }

  bool get isDemoUser => currentUser?.uid == 'demo-alex' || currentUser?.uid == 'demo-emma';

  Future<Map<String, dynamic>> demoContext() async => Map<String, dynamic>.from((await _dio.get('/v1/demo/context')).data);
  Future<List<Map<String, dynamic>>> recommendations() async {
    final res = await _dio.post('/v1/recommendations', data: {
      'partnerId': 'demo-participant-emma', 'occasion': 'Anniversary',
      'budget': {'amount': 500000, 'currency': 'VND'},
    });
    return (res.data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }
  Future<Map<String, dynamic>> createDemoPlan(String id) async => Map<String, dynamic>.from((await _dio.post('/v1/demo/plans', data: {'recommendationId': id})).data);
  Future<Map<String, dynamic>> updateDemoPlan(String id, Map<String, dynamic> data) async => Map<String, dynamic>.from((await _dio.patch('/v1/demo/plans/$id', data: data)).data);
  Future<Map<String, dynamic>> sendDemoHint(String id) async => Map<String, dynamic>.from((await _dio.post('/v1/demo/plans/$id/hint')).data);
  Future<List<Map<String, dynamic>>> notifications() async => ((await _dio.get('/v1/demo/notifications')).data as List).map((e) => Map<String, dynamic>.from(e)).toList();
  Future<void> readNotification(String id) async { await _dio.patch('/v1/demo/notifications/$id/read'); }
  Future<void> resetDemo() async { await _dio.post('/v1/demo/reset'); }

  Future<bool> updateCurrentUserProfile({
    String? nickname,
    String? avatar,
    String? birthday,
    bool clearAvatar = false,
  }) async {
    if (currentUser != null) {
      final newAvatar = clearAvatar ? '' : (avatar ?? currentUser!.avatar);
      currentUser = AppUser(
        uid: currentUser!.uid,
        email: currentUser!.email,
        nickname: nickname ?? currentUser!.nickname,
        activeCoupleId: currentUser!.activeCoupleId,
        avatar: newAvatar,
        birthday: birthday ?? currentUser!.birthday,
      );

      final data = <String, dynamic>{};
      if (nickname != null) data['nickname'] = nickname;
      if (clearAvatar) {
        data['avatar'] = '';
      } else if (avatar != null) {
        data['avatar'] = avatar;
      }
      if (birthday != null) data['birthday'] = birthday;

      if (data.isNotEmpty) {
        try {
          await _dio.patch('/v1/users/me', data: data);
          return true;
        } catch (e) {
          debugPrint('[ApiService] updateCurrentUserProfile sync error: $e');
          return false;
        }
      }
      return true;
    }
    return false;
  }

  Future<String?> uploadAvatar(String base64OrDataUri) async {
    try {
      final res = await _dio.post('/v1/users/avatar', data: {
        'data': base64OrDataUri,
      });
      if (res.statusCode == 200 && res.data != null) {
        final avatarUrl = res.data['avatar_url'] as String?;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          updateCurrentUserProfile(avatar: avatarUrl);
          return avatarUrl;
        }
      }
    } catch (e) {
      debugPrint('[ApiService] uploadAvatar error: $e');
    }
    return null;
  }

  // --- COUPLE SPACE ---
  Future<CoupleSpace> createSoloCouple({required String nickname, String? avatar, String? birthday}) async {
    final uid = currentUser?.uid ?? 'user-${DateTime.now().millisecondsSinceEpoch}';
    final currentAvatar = avatar ?? currentUser?.avatar;
    final currentBirthday = birthday ?? currentUser?.birthday;
    
    try {
      final res = await _dio.post('/v1/couples', queryParameters: {'nickname': nickname});
      if (res.statusCode == 200) {
        final space = CoupleSpace.fromJson(res.data as Map<String, dynamic>);
        currentUser = AppUser(
          uid: uid,
          email: currentUser?.email ?? '',
          nickname: nickname,
          activeCoupleId: space.id,
          avatar: currentAvatar,
          birthday: currentBirthday,
        );
        return space;
      }
    } catch (_) {
      // Fallback in-memory
    }

    // In-memory fallback
    final coupleId = 'couple-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final partA = Participant(
      id: 'part-a-$uid',
      linkedUserId: uid,
      nickname: nickname,
      role: ParticipantRole.creator,
      createdAt: now,
    );
    final partB = Participant(
      id: 'part-b-partner',
      linkedUserId: null,
      nickname: 'Partner',
      role: ParticipantRole.invitee,
      createdAt: now,
    );

    final space = CoupleSpace(
      id: coupleId,
      status: CoupleStatus.solo,
      participants: [partA, partB],
      createdAt: now,
      updatedAt: now,
    );

    _mockCouples[coupleId] = space;
    _mockUserCouple[uid] = coupleId;
    currentUser = AppUser(
      uid: uid,
      email: currentUser?.email ?? '',
      nickname: nickname,
      activeCoupleId: coupleId,
      avatar: currentAvatar,
      birthday: currentBirthday,
    );
    return space;
  }

  Future<CoupleSpace?> getCurrentCouple() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    try {
      final res = await _dio.get('/v1/couples/current');
      if (res.statusCode == 200) {
        return CoupleSpace.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback
    }

    final coupleId = _mockUserCouple[uid];
    if (coupleId != null && _mockCouples.containsKey(coupleId)) {
      return _mockCouples[coupleId];
    }
    return null;
  }

  // --- PREFERENCES ---
  Future<List<PreferenceItem>> getPreferences(String coupleId) async {
    final uid = currentUser?.uid ?? '';
    try {
      final res = await _dio.get('/v1/couples/$coupleId/preferences');
      if (res.statusCode == 200) {
        final list = (res.data as List<dynamic>)
            .map((e) => PreferenceItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
    } catch (_) {
      // Fallback
    }

    final all = _mockPreferences[coupleId] ?? [];
    // Filter according to contract: shared or private owned by user
    return all.where((p) {
      if (p.isSurprise) return p.createdByUserId == uid;
      if (p.visibility == PreferenceVisibility.shared) return true;
      return p.createdByUserId == uid;
    }).toList();
  }

  Future<PreferenceItem> createPreference({
    required String coupleId,
    required String subjectParticipantId,
    required String type,
    required String value,
    required PreferenceVisibility visibility,
  }) async {
    final uid = currentUser?.uid ?? 'anonymous';
    final payload = {
      'subjectParticipantId': subjectParticipantId,
      'type': type,
      'value': value,
      'visibility': visibility == PreferenceVisibility.shared ? 'shared' : 'private',
    };

    try {
      final res = await _dio.post('/v1/couples/$coupleId/preferences', data: payload);
      if (res.statusCode == 200) {
        return PreferenceItem.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback
    }

    final now = DateTime.now();
    final pref = PreferenceItem(
      id: 'pref-${DateTime.now().millisecondsSinceEpoch}',
      subjectParticipantId: subjectParticipantId,
      createdByUserId: uid,
      source: PreferenceSource.selfDeclared,
      type: type,
      value: value,
      visibility: type.toLowerCase() == 'surprise' ? PreferenceVisibility.private : visibility,
      createdAt: now,
      updatedAt: now,
    );

    _mockPreferences.putIfAbsent(coupleId, () => []).add(pref);
    return pref;
  }

  // --- INVITES ---
  Future<InviteItem> createInvite(String coupleId) async {
    try {
      final res = await _dio.post('/v1/couples/$coupleId/invites');
      if (res.statusCode == 200) {
        return InviteItem.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback
    }

    final token = 'LV-8K2M';
    final now = DateTime.now();
    final invite = InviteItem(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      coupleId: coupleId,
      token: token,
      status: InviteStatus.pending,
      expiresAt: now.add(const Duration(hours: 72)),
      createdAt: now,
    );
    _mockInvites[token] = invite;
    return invite;
  }

  Future<InvitePreview> previewInvite(String token) async {
    try {
      final res = await _dio.post('/v1/invites/preview', data: {'token': token});
      if (res.statusCode == 200) {
        return InvitePreview.fromJson(res.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback
    }

    final inv = _mockInvites[token];
    if (inv != null && _mockCouples.containsKey(inv.coupleId)) {
      final c = _mockCouples[inv.coupleId]!;
      final creator = c.creatorParticipant?.nickname ?? (currentUser?.nickname ?? 'Người ấy');
      return InvitePreview(
        inviterNickname: creator,
        status: inv.status,
        expiresAt: inv.expiresAt,
      );
    }

    return InvitePreview(
      inviterNickname: currentUser?.nickname ?? 'Người ấy',
      status: InviteStatus.pending,
      expiresAt: DateTime.now().add(const Duration(hours: 72)),
    );
  }

  Future<bool> acceptInvite({required String token, required String nickname}) async {
    final uid = currentUser?.uid ?? 'user-invitee-${DateTime.now().millisecondsSinceEpoch}';
    try {
      final res = await _dio.post(
        '/v1/invites/accept',
        queryParameters: {'nickname': nickname},
        data: {'token': token},
      );
      if (res.statusCode == 200) {
        final cid = res.data['coupleId'] as String;
        currentUser = AppUser(
          uid: uid,
          email: currentUser?.email ?? '',
          nickname: nickname,
          activeCoupleId: cid,
        );
        return true;
      }
    } catch (_) {
      // Fallback
    }

    final inv = _mockInvites[token];
    if (inv != null && _mockCouples.containsKey(inv.coupleId)) {
      final couple = _mockCouples[inv.coupleId]!;
      // Find placeholder
      final placeholder = couple.participants.firstWhere(
        (p) => p.linkedUserId == null,
        orElse: () => couple.participants.last,
      );

      final updatedParticipants = couple.participants.map((p) {
        if (p.id == placeholder.id) {
          return Participant(
            id: p.id,
            linkedUserId: uid,
            nickname: nickname,
            role: ParticipantRole.invitee,
            createdAt: p.createdAt,
          );
        }
        return p;
      }).toList();

      final updatedSpace = CoupleSpace(
        id: couple.id,
        status: CoupleStatus.connected,
        participants: updatedParticipants,
        createdAt: couple.createdAt,
        updatedAt: DateTime.now(),
      );

      _mockCouples[couple.id] = updatedSpace;
      _mockUserCouple[uid] = couple.id;
      currentUser = AppUser(
        uid: uid,
        email: currentUser?.email ?? '',
        nickname: nickname,
        activeCoupleId: couple.id,
      );
      return true;
    }
    return false;
  }

  // --- AI CHATBOT ADVISOR ---
  Future<Map<String, dynamic>> chatWithAdvisor({
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    try {
      final res = await _dio.post(
        '/v1/chat',
        data: {
          'message': message,
          'history': history,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data as Map<String, dynamic>;
      }
    } catch (_) {
      // Fallback if backend offline
    }

    final user = currentUser?.nickname ?? 'bạn';
    return {
      'reply': 'Chào $user! 💕 Quân sư luôn ở đây để lắng nghe và hỗ trợ bạn gắn kết tình cảm. '
          'Hãy chia sẻ thêm cho mình về cảm xúc hoặc điều bạn đang mong muốn nhé!',
      'suggestedFollowUps': [
        '🍷 Gợi ý buổi hẹn lãng mạn cuối tuần',
        '🎁 Ý tưởng bất ngờ làm người ấy vui',
        '💐 Gợi ý quà tặng kỷ niệm ý nghĩa',
      ],
      'options': [
        '🍷 Lên lịch hẹn hò lãng mạn',
        '🎁 Tư vấn quà tặng bất ngờ',
        '💬 Mẹo mở lời bắt chuyện',
        '🕊️ Cách làm hòa khi giận nhau',
      ],
    };
  }

  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final uid = currentUser?.uid ?? 'guest';
    try {
      final res = await _dio.get('/v1/chat/history');
      if (res.statusCode == 200 && res.data != null) {
        final list = (res.data['messages'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ?? [];
        _mockChatHistory[uid] = list;
        return list;
      }
    } catch (_) {
      // Fallback if offline
    }
    return _mockChatHistory[uid] ?? [];
  }

  Future<void> clearChatHistory() async {
    final uid = currentUser?.uid ?? 'guest';
    try {
      await _dio.delete('/v1/chat/history');
    } catch (_) {}
    _mockChatHistory[uid] = [];
  }
}
