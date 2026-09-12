import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/couple_space.dart';
import '../models/preference.dart';
import '../models/invite.dart';
import '../models/date_spot.dart';
import '../models/user_mood.dart';
import '../data/mock_date_spots.dart';
import '../widgets/ourly_date_picker.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static const String defaultBaseUrl = 'https://apricot-freezable-chemicals.ngrok-free.dev';
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: defaultBaseUrl);

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 35),
    headers: {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
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
  final List<DatingPlanHistoryItem> _datePlanHistory = [];
  DateTime? _datingStartDate;

  // Quản lý tâm trạng hàng ngày (Daily Mood)
  UserMood? _todayUserMood;
  UserMood? _todayPartnerMood;
  DateTime? _lastMoodCheckInDate;

  bool get hasDatingStartDate => getDatingStartDate() != null;

  DateTime? getDatingStartDate() {
    if (_datingStartDate != null) return _datingStartDate;
    if (currentUser?.datingStartDate != null && currentUser!.datingStartDate!.isNotEmpty) {
      _datingStartDate = OurlyDatePicker.parseDate(currentUser!.datingStartDate!);
    }
    return _datingStartDate;
  }

  void setDatingStartDate(DateTime? date) {
    _datingStartDate = date;
    if (date != null) {
      final formatted = OurlyDatePicker.formatDate(date);
      updateCurrentUserProfile(datingStartDate: formatted);
    }
  }

  void clearDatingStartDate() {
    _datingStartDate = null;
    updateCurrentUserProfile(datingStartDate: '');
  }

  int? getDaysTogether() {
    if (_datingStartDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = DateTime(_datingStartDate!.year, _datingStartDate!.month, _datingStartDate!.day);
    final diff = today.difference(startDate).inDays;
    return diff < 1 ? 1 : diff;
  }

  bool hasCheckedInToday() {
    if (_lastMoodCheckInDate == null || _todayUserMood == null) return false;
    final now = DateTime.now();
    return _lastMoodCheckInDate!.year == now.year &&
        _lastMoodCheckInDate!.month == now.month &&
        _lastMoodCheckInDate!.day == now.day;
  }

  void saveTodayMood(UserMood mood) {
    _todayUserMood = mood;
    _lastMoodCheckInDate = DateTime.now();

    if (_todayPartnerMood == null) {
      _todayPartnerMood = const UserMood(
        id: 'calm',
        emoji: '🥰',
        label: 'Nhớ bạn & Hạnh phúc',
        description: 'Vừa hoàn thành công việc, đang nhớ đến bạn',
        partnerHint: 'Người ấy đang ngập tràn hạnh phúc và nhớ bạn! Hãy gửi một tin nhắn bất ngờ nhé 💕',
      );
    }
  }

  UserMood? getTodayUserMood() => _todayUserMood;
  UserMood? getTodayPartnerMood() => _todayPartnerMood;
  void setTodayPartnerMood(UserMood mood) => _todayPartnerMood = mood;

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
    String? gender,
  }) async {
    final res = await _dio.post('/v1/auth/register', data: {
      'email': email.trim(),
      'password': password.trim(),
      if (nickname != null && nickname.trim().isNotEmpty) 'nickname': nickname.trim(),
      if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final userData = data['user'] as Map<String, dynamic>;

    currentToken = token;
    currentUser = AppUser.fromJson(userData);
    if (currentUser?.datingStartDate != null && currentUser!.datingStartDate!.isNotEmpty) {
      _datingStartDate = OurlyDatePicker.parseDate(currentUser!.datingStartDate!);
    }
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
    if (currentUser?.datingStartDate != null && currentUser!.datingStartDate!.isNotEmpty) {
      _datingStartDate = OurlyDatePicker.parseDate(currentUser!.datingStartDate!);
    }
    return currentUser!;
  }

  void logout() {
    currentUser = null;
    currentToken = null;
  }

  Future<bool> updateCurrentUserProfile({
    String? nickname,
    String? avatar,
    String? birthday,
    String? gender,
    String? datingStartDate,
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
        gender: gender ?? currentUser!.gender,
        datingStartDate: datingStartDate ?? currentUser!.datingStartDate,
      );

      final data = <String, dynamic>{};
      if (nickname != null) data['nickname'] = nickname;
      if (clearAvatar) {
        data['avatar'] = '';
      } else if (avatar != null) {
        data['avatar'] = avatar;
      }
      if (birthday != null) data['birthday'] = birthday;
      if (gender != null) data['gender'] = gender;
      if (datingStartDate != null) data['datingStartDate'] = datingStartDate;

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
      final queryParams = <String, dynamic>{'nickname': nickname};
      if (currentAvatar != null && currentAvatar.isNotEmpty) queryParams['avatar'] = currentAvatar;
      if (currentBirthday != null && currentBirthday.isNotEmpty) queryParams['birthday'] = currentBirthday;

      final res = await _dio.post('/v1/couples', queryParameters: queryParams);
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

  CoupleSpace? get currentCouple {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    final coupleId = _mockUserCouple[uid];
    if (coupleId != null && _mockCouples.containsKey(coupleId)) {
      return _mockCouples[coupleId];
    }
    return null;
  }

  Future<CoupleSpace?> getCurrentCouple() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;

    try {
      final res = await _dio.get('/v1/couples/current');
      if (res.statusCode == 200) {
        final space = CoupleSpace.fromJson(res.data as Map<String, dynamic>);
        _mockCouples[space.id] = space;
        _mockUserCouple[uid] = space.id;
        return space;
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

  Future<CoupleSpace?> unlinkPartner(String coupleId) async {
    try {
      final res = await _dio.post('/v1/couples/$coupleId/unlink');
      if (res.statusCode == 200) {
        final updated = CoupleSpace.fromJson(res.data as Map<String, dynamic>);
        _mockCouples[coupleId] = updated;
        return updated;
      }
    } catch (_) {
      // Fallback
    }

    if (_mockCouples.containsKey(coupleId)) {
      final existing = _mockCouples[coupleId]!;
      final updatedParticipants = existing.participants.map((p) {
        if (p.role == ParticipantRole.invitee) {
          return Participant(
            id: p.id,
            linkedUserId: null,
            nickname: 'Partner',
            role: ParticipantRole.invitee,
            createdAt: p.createdAt,
          );
        }
        return p;
      }).toList();

      final updated = CoupleSpace(
        id: existing.id,
        status: CoupleStatus.solo,
        participants: updatedParticipants,
        createdAt: existing.createdAt,
        updatedAt: DateTime.now(),
      );
      _mockCouples[coupleId] = updated;
      return updated;
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
    String cleanToken = token.trim().toUpperCase();
    if (cleanToken.contains('/INVITE/')) {
      cleanToken = cleanToken.split('/INVITE/').last.trim();
    }
    if (cleanToken.contains('?')) {
      cleanToken = cleanToken.split('?').first.trim();
    }
    if (cleanToken.contains('#')) {
      cleanToken = cleanToken.split('#').first.trim();
    }
    while (cleanToken.endsWith('/')) {
      cleanToken = cleanToken.substring(0, cleanToken.length - 1).trim();
    }
    if (cleanToken.length == 4 && !cleanToken.startsWith('LV-')) {
      cleanToken = 'LV-$cleanToken';
    }

    try {
      final res = await _dio.post(
        '/v1/invites/accept',
        queryParameters: {
          'nickname': nickname,
          'archive_solo': 'true',
        },
        data: {'token': cleanToken},
      );
      if (res.statusCode == 200) {
        final cid = res.data['coupleId'] as String;
        currentUser = AppUser(
          uid: uid,
          email: currentUser?.email ?? '',
          nickname: nickname,
          activeCoupleId: cid,
          avatar: currentUser?.avatar,
          birthday: currentUser?.birthday,
        );
        // Refresh couple space cache
        await getCurrentCouple();
        return true;
      }
    } catch (e) {
      debugPrint('[ApiService] acceptInvite backend error: $e');
    }

    final inv = _mockInvites[cleanToken] ?? _mockInvites[token];
    String? coupleIdToLink = inv?.coupleId;
    if (coupleIdToLink == null && _mockCouples.isNotEmpty) {
      coupleIdToLink = _mockCouples.keys.first;
    }

    if (coupleIdToLink != null && _mockCouples.containsKey(coupleIdToLink)) {
      final couple = _mockCouples[coupleIdToLink]!;

      // Prevent self-match: check if user is already the creator of this couple
      final isCreator = couple.participants.any(
        (p) => p.linkedUserId == uid && p.role == ParticipantRole.creator,
      );
      if (isCreator) {
        debugPrint('[ApiService] acceptInvite: Blocked self-match - user is already the creator.');
        return false;
      };
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
        avatar: currentUser?.avatar,
        birthday: currentUser?.birthday,
      );
      return true;
    }
    return false;
  }

  // --- AI CHATBOT ADVISOR ---
  Future<Map<String, dynamic>> chatWithAdvisor({
    required String message,
    List<Map<String, String>> history = const [],
    Map<String, dynamic>? clientContext,
  }) async {
    try {
      final payload = <String, dynamic>{
        'message': message,
        'history': history,
      };
      if (clientContext != null) {
        payload['clientContext'] = clientContext;
      }
      final res = await _dio.post(
        '/v1/chat',
        data: payload,
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[ApiService] chatWithAdvisor error: $e');
    }

    return {};
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

  // --- DATE PLAN HISTORY ---
  void saveDatePlan(DatingPlanHistoryItem plan) {
    if (_datePlanHistory.isEmpty) {
      _initMockDateHistory();
    }
    _datePlanHistory.insert(0, plan);
  }

  List<DatingPlanHistoryItem> getDatePlanHistory() {
    if (_datePlanHistory.isEmpty) {
      _initMockDateHistory();
    }
    return List.unmodifiable(_datePlanHistory);
  }

  void _initMockDateHistory() {
    if (_datePlanHistory.isNotEmpty) return;

    final spotBistro = MockDateSpotsData.allSpots.firstWhere(
      (s) => s.id == 'spot-bistro',
      orElse: () => MockDateSpotsData.allSpots.first,
    );
    final spotDessert = MockDateSpotsData.allSpots.firstWhere(
      (s) => s.id == 'spot-dessert',
      orElse: () => MockDateSpotsData.allSpots[1],
    );
    final spotPottery = MockDateSpotsData.allSpots.firstWhere(
      (s) => s.id == 'spot-pottery',
      orElse: () => MockDateSpotsData.allSpots[1],
    );

    _datePlanHistory.addAll([
      DatingPlanHistoryItem(
        id: 'history-1',
        title: 'Bữa tối ven sông & Mochi ngọt ngào',
        occasionLabel: 'Kỷ niệm',
        occasionEmoji: '💖',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        totalCost: 400000,
        totalCostDisplay: '400K',
        spots: [spotBistro, spotDessert],
        timelineSteps: [
          DateTimelineStep(
            iconEmoji: '🌅',
            timeLabel: '17:00 - 17:45 · HOÀNG HÔN DỊU ÊM',
            title: 'Dạo bộ ngắm Cầu Rồng & Sông Hàn',
            description: 'Dạo bước thong thả đón gió sông mát lành trước khi vào tiệc.',
            nodeBgColor: const Color(0xFFFFE7DD),
            imageAsset: 'assets/images/spot_beach.jpg',
            categoryTag: 'DẠO MÁT HOÀNG HÔN',
            locationName: 'Bờ Đông Sông Hàn',
          ),
          DateTimelineStep(
            iconEmoji: '🍝',
            timeLabel: '18:00 - 19:30 · BỮA TỐI ÁNH NẾN',
            title: 'Bữa tối bít tết & pasta tại La Rive Bistro',
            description: 'Bàn cạnh bờ sông yên ả, ánh nến lung linh đúng kiểu buổi tối lãng mạn.',
            nodeBgColor: const Color(0xFFFFDFE8),
            imageAsset: 'assets/images/spot_bistro.jpg',
            categoryTag: 'ẨM THỰC LÃNG MẠN',
            locationName: 'La Rive Bistro · An Thượng',
          ),
          DateTimelineStep(
            iconEmoji: '🍰',
            timeLabel: '19:45 - 20:45 · TRÁNG MIỆNG NGỌT NGÀO',
            title: 'Mochi dâu tây & matcha tại Mochi & Cream',
            description: 'Đi bộ 5 phút ven sông, nếm vị kem gelato béo ngậy tan chảy trên đầu lưỡi.',
            nodeBgColor: const Color(0xFFDBECF8),
            imageAsset: 'assets/images/spot_dessert.jpg',
            categoryTag: 'TRÁNG MIỆNG',
            locationName: 'Mochi & Cream · Bạch Đằng',
          ),
          const DateTimelineStep(
            iconEmoji: '💌',
            timeLabel: 'BẤT CỨ LÚC NÀO TRONG BUỔI HẸN',
            title: 'Bí mật ngọt ngào dành riêng',
            description: 'Tặng bông hoa tulip và trao tay bức thư tình viết tay.',
            nodeBgColor: Color(0xFFFFE0E8),
            categoryTag: 'BẤT NGỜ',
            locationName: 'Trao gửi yêu thương',
          ),
        ],
        secretIdeaTitle: 'Mang theo loài hoa người ấy thích',
        secretIdeaDesc: 'Hoa Tulip. Người ấy từng chụp ảnh hoa này và chia sẻ trong hồ sơ bí mật.',
        partnerName: 'Người ấy',
        isCompleted: true,
      ),
      DatingPlanHistoryItem(
        id: 'history-2',
        title: 'Workshop gốm thủ công & Cafe nhà kính',
        occasionLabel: 'Cuối tuần chill',
        occasionEmoji: '🌙',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        totalCost: 445000,
        totalCostDisplay: '445K',
        spots: [spotPottery],
        timelineSteps: [
          DateTimelineStep(
            iconEmoji: '🏺',
            timeLabel: '15:00 - 17:00 · SÁNG TẠO ĐÔI',
            title: 'Tự tay làm đồ gốm tại Pottery Studio Mộc',
            description: 'Cùng nặn chiếc cốc đôi kỷ niệm, lưu lại dấu ấn riêng của hai bạn.',
            nodeBgColor: const Color(0xFFFFE7DD),
            imageAsset: 'assets/images/spot_pottery.jpg',
            categoryTag: 'WORKSHOP GỐM',
            locationName: 'Studio Mộc · Hải Châu',
          ),
          DateTimelineStep(
            iconEmoji: '☕',
            timeLabel: '17:15 - 18:30 · THƯ THÁI',
            title: 'Uống cafe muối & ngắm hoàng hôn giếng trời',
            description: 'Ghé quán cafe nhà kính ngập nắng ấm, chụp vài tấm ảnh đôi xinh xắn.',
            nodeBgColor: const Color(0xFFDBECF8),
            imageAsset: 'assets/images/spot_dessert.jpg',
            categoryTag: 'CAFE NHÀ KÍNH',
            locationName: 'Wonderlust Cafe · Trần Phú',
          ),
          const DateTimelineStep(
            iconEmoji: '💌',
            timeLabel: 'KHI MÓN GỐM HOÀN TẤT',
            title: 'Khắc thông điệp bí mật',
            description: 'Khắc ngày hai bạn lần đầu gặp nhau vào đáy chiếc cốc gốm.',
            nodeBgColor: Color(0xFFFFE0E8),
            categoryTag: 'BÍ MẬT',
            locationName: 'Kỷ niệm vĩnh cửu',
          ),
        ],
        secretIdeaTitle: 'Khắc ngày kỷ niệm lên chiếc cốc gốm',
        secretIdeaDesc: 'Cùng giữ chiếc cốc kỷ niệm để mỗi buổi sáng đều nhớ về nhau.',
        partnerName: 'Người ấy',
        isCompleted: true,
      ),
    ]);
  }
}

