import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/couple_space.dart';
import '../models/preference.dart';
import 'chatbot_screen.dart';
import '../widgets/romantic_effects.dart';
import '../widgets/ourly_date_picker.dart';
import '../widgets/ourly_toast.dart';
import '../widgets/daily_mood_dialog.dart';
import '../models/user_mood.dart';
import '../services/notification_service.dart';
import 'dating_plan_flow.dart';
import 'dating_history_screen.dart';
import 'onboarding_step2_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onShowInvite;

  const DashboardScreen({
    super.key,
    required this.onLogout,
    required this.onShowInvite,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class ImportantDateInfo {
  final String title;
  final int daysUntil;
  final String occasionId;
  final String headline;
  final String description;

  const ImportantDateInfo({
    required this.title,
    required this.daysUntil,
    required this.occasionId,
    required this.headline,
    required this.description,
  });
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  CoupleSpace? _couple;
  List<PreferenceItem> _preferences = [];
  bool _isLoading = true;
  String _activeFilter = 'all'; // all, self, partner, private, surprise
  bool _showAllPreferences = false;

  // Ngày kỷ niệm của cặp đôi (dùng cho override/thử nghiệm, nếu null thì lấy theo ngày bắt đầu hẹn hò)
  DateTime? _anniversaryDate;

  /// Lấy thông tin ngày quan trọng nếu sắp đến trong vòng 3 ngày (0, 1, 2, 3 ngày)
  ImportantDateInfo? _getUpcomingImportantDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Kiểm tra ngày kỷ niệm của cặp đôi:
    // QUAN TRỌNG: Nếu user chưa có "ngày bắt đầu hẹn hò" VÀ không có test override thì KHÔNG HIỆN CARD KỶ NIỆM!
    final datingStart = _apiService.getDatingStartDate();
    final anniv = _anniversaryDate ?? datingStart;

    if (anniv != null) {
      DateTime nextAnniv = DateTime(today.year, anniv.month, anniv.day);
      if (nextAnniv.isBefore(today)) {
        nextAnniv = DateTime(today.year + 1, anniv.month, anniv.day);
      }
      final daysUntilAnniv = nextAnniv.difference(today).inDays;

      // Chỉ xuất hiện khi sắp đến ngày quan trọng trong vòng 7 ngày (0, 1, ..., 7 ngày)
      if (daysUntilAnniv >= 0 && daysUntilAnniv <= 7) {
        String headline;
        if (daysUntilAnniv == 0) {
          headline = 'Hôm nay là ngày kỷ niệm của hai bạn! 🎉💕';
        } else if (daysUntilAnniv == 1) {
          headline = 'Kỷ niệm ngày mai là đến rồi 💕';
        } else if (daysUntilAnniv == 2) {
          headline = 'Kỷ niệm 2 ngày nữa là đến rồi 💕';
        } else {
          headline = 'Kỷ niệm còn $daysUntilAnniv ngày nữa 💕 Hãy chuẩn bị bất ngờ nhé! ✨';
        }

        return ImportantDateInfo(
          title: 'Kỷ niệm',
          daysUntil: daysUntilAnniv,
          occasionId: 'anniversary',
          headline: headline,
          description: 'Ourly đã chuẩn bị sẵn kế hoạch hẹn hò và gợi ý quà tặng cho hai bạn.',
        );
      }
    }

    // 2. Kiểm tra ngày sinh nhật nếu có
    final bdayStr = _apiService.currentUser?.birthday;
    if (bdayStr != null) {
      final parsed = OurlyDatePicker.parseDate(bdayStr);
      if (parsed != null) {
        DateTime nextBday = DateTime(today.year, parsed.month, parsed.day);
        if (nextBday.isBefore(today)) {
          nextBday = DateTime(today.year + 1, parsed.month, parsed.day);
        }
        final daysUntilBday = nextBday.difference(today).inDays;
        if (daysUntilBday >= 0 && daysUntilBday <= 7) {
          String headline;
          if (daysUntilBday == 0) {
            headline = 'Hôm nay là sinh nhật người ấy! 🎂🎉';
          } else if (daysUntilBday == 1) {
            headline = 'Sinh nhật người ấy ngày mai là đến rồi 🎂';
          } else {
            headline = 'Sinh nhật người ấy còn $daysUntilBday ngày nữa 🎂';
          }

          return ImportantDateInfo(
            title: 'Sinh nhật',
            daysUntil: daysUntilBday,
            occasionId: 'birthday',
            headline: headline,
            description: 'Ourly đã chuẩn bị sẵn kế hoạch hẹn hò sinh nhật cho hai bạn.',
          );
        }
      }
    }

    return null;
  }

  void _openInviteScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OnboardingStep2Screen(
          isFromDashboard: true,
          onBack: () => Navigator.of(context).pop(),
          onEnterSpace: () {
            Navigator.of(context).pop();
            _loadData();
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.requestPermission();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final c = await _apiService.getCurrentCouple();
      if (c != null) {
        final prefs = await _apiService.getPreferences(c.id);
        setState(() {
          _couple = c;
          _preferences = prefs;
          _isLoading = false;
        });
        // Show daily mood popup only when user has a connected partner
        final isConnected = c.status == CoupleStatus.connected;
        if (isConnected && !_apiService.hasCheckedInToday() && mounted) {
          final uid = _apiService.currentUser?.uid ?? '';
          final partnerParticipant = c.participants.firstWhere(
            (p) => p.linkedUserId != uid,
            orElse: () => c.participants.last,
          );
          final partnerName = partnerParticipant.nickname;
          Future.delayed(const Duration(milliseconds: 700), () {
            if (mounted) {
              DailyMoodDialog.show(
                context,
                partnerName: partnerName,
                onMoodSubmitted: (UserMood mood) {
                  if (mounted) setState(() {});
                },
              );
            }
          });
        }
        return;
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _pickBirthdayForSelf(BuildContext context, [StateSetter? setModalState]) async {
    final currentBday = _apiService.currentUser?.birthday;
    final parsed = OurlyDatePicker.parseDate(currentBday);
    final picked = await OurlyDatePicker.pickDate(
      context: context,
      initialDate: parsed ?? DateTime(2000, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'CẬP NHẬT NGÀY SINH',
    );
    if (picked != null) {
      final formatted = OurlyDatePicker.formatDate(picked);
      await _apiService.updateCurrentUserProfile(birthday: formatted);
      if (setModalState != null) {
        setModalState(() {});
      }
      setState(() {});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.cake_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Đã cập nhật ngày sinh: $formatted'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }


  Future<void> _pickDatingStartDate(BuildContext context, [StateSetter? setModalState]) async {
    final current = _apiService.getDatingStartDate() ?? DateTime.now();
    final picked = await OurlyDatePicker.pickDate(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'CHỌN NGÀY BẮT ĐẦU HẸN HÒ',
    );
    if (picked != null) {
      setState(() {
        _anniversaryDate = null; // QUAN TRỌNG: Reset override để ngày thật có hiệu lực ngay!
        _apiService.setDatingStartDate(picked);
      });
      if (setModalState != null) {
        setModalState(() {});
      }
      if (context.mounted) {
        final formatted = OurlyDatePicker.formatDate(picked);
        final days = _apiService.getDaysTogether() ?? 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Đã cập nhật ngày bắt đầu hẹn hò: $formatted ($days ngày bên nhau) 💕'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildQuickResetDateChip(StateSetter? setModalState) {
    final isReal = _anniversaryDate == null;
    return CuteBounceOnTap(
      onTap: () {
        setState(() {
          _anniversaryDate = null;
        });
        if (setModalState != null) {
          setModalState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isReal ? const Color(0xFF2C1914) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isReal ? const Color(0xFF2C1914) : const Color(0xFFEADFD8),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restart_alt_rounded, size: 13, color: isReal ? Colors.white : const Color(0xFF5A4842)),
            const SizedBox(width: 4),
            Text(
              'Dùng ngày thực tế',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isReal ? FontWeight.w700 : FontWeight.w500,
                color: isReal ? Colors.white : const Color(0xFF5A4842),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickTestDateChip(String label, int days, StateSetter? setModalState) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = today.add(Duration(days: days));

    final datingStart = _apiService.getDatingStartDate();
    final anniv = _anniversaryDate ?? datingStart;
    bool isSelected = false;
    if (anniv != null) {
      DateTime nextAnniv = DateTime(today.year, anniv.month, anniv.day);
      if (nextAnniv.isBefore(today)) {
        nextAnniv = DateTime(today.year + 1, anniv.month, anniv.day);
      }
      final currentDays = nextAnniv.difference(today).inDays;
      isSelected = currentDays == days;
    }

    return CuteBounceOnTap(
      onTap: () {
        setState(() {
          _anniversaryDate = targetDate;
        });
        if (setModalState != null) {
          setModalState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE85A42) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFE85A42) : const Color(0xFFEADFD8),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF5A4842),
          ),
        ),
      ),
    );
  }

  void _openAddPreferenceModal({StateSetter? setParentModalState}) {
    final typeController = TextEditingController(text: 'Ăn uống');
    final valueController = TextEditingController();
    PreferenceVisibility visibility = PreferenceVisibility.shared;
    bool isSurprise = false;
    String subjectId = _couple?.participants.first.id ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 24,
              left: 24,
              right: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Thêm sở thích / Kế hoạch mới',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  const Text('DANH MỤC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Ăn uống', 'Thức uống', 'Không gian', 'Hoạt động', 'Surprise'].map((t) {
                      final isSel = typeController.text == t;
                      final label = t == 'Surprise' ? '🎁 Kế hoạch bất ngờ' : t;
                      return ChoiceChip(
                        label: Text(label),
                        selected: isSel,
                        selectedColor: t == 'Surprise' ? AppColors.surpriseBadgeBg : AppColors.tagSelectedBg,
                        labelStyle: TextStyle(
                          color: isSel
                              ? (t == 'Surprise' ? AppColors.surpriseBadgeText : AppColors.tagSelectedText)
                              : AppColors.textPrimary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          setModalState(() {
                            typeController.text = t;
                            if (t == 'Surprise') {
                              isSurprise = true;
                              visibility = PreferenceVisibility.private;
                            } else {
                              isSurprise = false;
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Value input
                  TextField(
                    controller: valueController,
                    decoration: InputDecoration(
                      labelText: isSurprise ? 'Nội dung kế hoạch bất ngờ bí mật' : 'Chi tiết sở thích',
                      hintText: isSurprise ? 'Ví dụ: Đặt bàn ăn tối ngắm hoàng hôn bên bờ biển' : 'Ví dụ: Trà sữa ít đường, bánh cheesecake',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Visibility Switch (if not surprise)
                  if (!isSurprise) ...[
                    const Text('QUYỀN XEM (CHIA SẺ)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => visibility = PreferenceVisibility.shared),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: visibility == PreferenceVisibility.shared ? AppColors.sharedBadgeBg : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: visibility == PreferenceVisibility.shared ? AppColors.sharedBadgeText : Colors.transparent,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Text('🌟 Chia sẻ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.sharedBadgeText)),
                                  SizedBox(height: 2),
                                  Text('Cả hai đều thấy', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => visibility = PreferenceVisibility.private),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: visibility == PreferenceVisibility.private ? AppColors.privateBadgeBg : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: visibility == PreferenceVisibility.private ? AppColors.privateBadgeText : Colors.transparent,
                                ),
                              ),
                              child: const Column(
                                children: [
                                  Text('🔒 Riêng tư', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.privateBadgeText)),
                                  SizedBox(height: 2),
                                  Text('Chỉ mình bạn thấy', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surpriseBadgeBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Text('🎁', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Kế hoạch bất ngờ được tự động bảo vệ riêng tư. Người ấy tuyệt đối không thể thấy!',
                              style: TextStyle(fontSize: 12, color: AppColors.surpriseBadgeText, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final val = valueController.text.trim();
                        if (val.isEmpty || _couple == null) return;
                        Navigator.of(context).pop();

                        await _apiService.createPreference(
                          coupleId: _couple!.id,
                          subjectParticipantId: subjectId,
                          type: typeController.text,
                          value: val,
                          visibility: visibility,
                        );
                        await _loadData();
                        if (setParentModalState != null) {
                          setParentModalState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: const Text('Lưu thông tin', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openDatingPlanFlow({String? occasionId}) async {
    final partnerName = _couple?.partnerParticipant?.nickname ?? 'Người ấy';
    final userPrefs = _preferences.map((p) => p.value).toList();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DatingPlanFlow(
          initialPreferences: userPrefs,
          partnerNickname: partnerName,
          initialOccasionId: occasionId,
        ),
      ),
    );
    if (mounted) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiService.currentUser;
    final currentUid = user?.uid ?? '';
    final isConnected = _couple?.status == CoupleStatus.connected;

    // Compute my participant vs partner participant based on current user uid
    // This avoids the self-match bug where an invitee sees themselves as partner
    final myParticipant = _couple?.participantForUser(currentUid);
    final partnerParticipant = _couple != null && currentUid.isNotEmpty
        ? _couple!.participants.firstWhere(
            (p) => p.linkedUserId != currentUid,
            orElse: () => _couple!.participants.last,
          )
        : null;

    final creatorName = user != null && user.nickname.isNotEmpty
        ? user.nickname
        : (myParticipant?.nickname ?? 'Bạn');
    final partnerName = isConnected
        ? (partnerParticipant?.nickname ?? 'Người ấy')
        : 'Người ấy';

    // Title string
    final spaceTitle = isConnected
        ? '$creatorName & $partnerName'
        : '$creatorName · Không gian riêng';

    // Filtered preferences
    final filteredPrefs = _preferences.where((p) {
      if (_activeFilter == 'self') return p.createdByUserId == currentUid && p.visibility == PreferenceVisibility.shared;
      if (_activeFilter == 'partner') return p.createdByUserId != currentUid && p.visibility == PreferenceVisibility.shared;
      if (_activeFilter == 'private') return p.visibility == PreferenceVisibility.private && !p.isSurprise;
      if (_activeFilter == 'surprise') return p.isSurprise;
      return true;
    }).toList();

    // Kiểm tra ngày quan trọng sắp tới (chỉ hiển thị thẻ nếu trong vòng 3 ngày)
    final upcomingDate = _getUpcomingImportantDate();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _buildAngelRobotFab(),
      body: FloatingHeartsBackground(
        count: 14,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 44, 20, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top App Bar Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'KHÔNG GIAN CỦA CHÚNG MÌNH',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                      color: AppColors.stepLabel,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    spaceTitle,
                                    style: AppTypography.script(
                                      fontSize: 29,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Cùng nhau, mọi ngày đều đặc biệt ♡',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Top Right Action Buttons (Notification Bell & Animated Avatar Button)
                            Row(
                              children: [
                                // 1. Nút chuông thông báo (Bell icon with red badge)
                                CuteBounceOnTap(
                                  onTap: _showNotificationsSheet,
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        const Center(
                                          child: Icon(
                                            Icons.notifications_none_rounded,
                                            size: 22,
                                            color: Color(0xFF5A443E),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            width: 8.5,
                                            height: 8.5,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE85A42),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: Colors.white, width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // 2. Nút Avatar có animation (Ảnh 2: 2 avatar lồng nhau khi có partner, 1 avatar khi chưa match)
                                CuteBounceOnTap(
                                  onTap: _showProfileModal,
                                  child: HeartbeatPulse(
                                    minScale: 0.95,
                                    maxScale: 1.05,
                                    child: _buildHeaderAvatarButton(isConnected, creatorName, partnerName),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Hero Area: Pill Badge on Left + Couple Chibi Illustration on Right
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Pill Counter: X ngày bên nhau > HOẶC Thiết lập ngày yêu >
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Builder(
                                  builder: (context) {
                                    final daysTogether = _apiService.getDaysTogether();
                                    if (daysTogether != null) {
                                      return CuteBounceOnTap(
                                        onTap: () {
                                          LoveSparkleOverlay.show(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('💕 $daysTogether ngày ngọt ngào bên nhau! Cùng tạo thêm nhiều kỷ niệm đẹp nhé! ✨'),
                                              backgroundColor: const Color(0xFFE85A42),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Colors.white, Color(0xFFFFF7F4)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(26),
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFE85A42).withValues(alpha: 0.10),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                              ),
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.03),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFFFFEDEB), Color(0xFFFFDCD7)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFFE85A42).withValues(alpha: 0.2),
                                                      blurRadius: 6,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: const Center(
                                                  child: HeartbeatPulse(
                                                    minScale: 0.88,
                                                    maxScale: 1.15,
                                                    duration: Duration(milliseconds: 1400),
                                                    child: Text('💖', style: TextStyle(fontSize: 18)),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        '$daysTogether',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 21,
                                                          fontWeight: FontWeight.w900,
                                                          color: const Color(0xFFE85A42),
                                                          height: 1.05,
                                                          letterSpacing: -0.5,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'ngày',
                                                        style: GoogleFonts.plusJakartaSans(
                                                          fontSize: 13.5,
                                                          fontWeight: FontWeight.w800,
                                                          color: const Color(0xFFE85A42),
                                                          height: 1.1,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFFECE9),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text(
                                                          'YÊU THƯƠNG',
                                                          style: TextStyle(
                                                            fontSize: 8.5,
                                                            fontWeight: FontWeight.w800,
                                                            letterSpacing: 0.6,
                                                            color: Color(0xFFE85A42),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'bên nhau mỗi ngày',
                                                        style: TextStyle(
                                                          fontSize: 11.5,
                                                          fontWeight: FontWeight.w500,
                                                          color: Color(0xFF7A6862),
                                                        ),
                                                      ),
                                                      SizedBox(width: 3),
                                                      Icon(
                                                        Icons.chevron_right_rounded,
                                                        size: 15,
                                                        color: Color(0xFFB09E98),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }

                                    // Trường hợp chưa có ngày bắt đầu hẹn hò:
                                    return CuteBounceOnTap(
                                      onTap: () => _pickDatingStartDate(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Colors.white, Color(0xFFFFF7F4)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(26),
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFE85A42).withValues(alpha: 0.10),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.03),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 38,
                                              height: 38,
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFFFFEDEB), Color(0xFFFFDCD7)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Center(
                                                child: HeartbeatPulse(
                                                  minScale: 0.88,
                                                  maxScale: 1.15,
                                                  duration: Duration(milliseconds: 1400),
                                                  child: Text('💖', style: TextStyle(fontSize: 18)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Thiết lập ngày yêu',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontSize: 14.5,
                                                        fontWeight: FontWeight.w800,
                                                        color: const Color(0xFFE85A42),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFE85A42)),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                const Text(
                                                  'Bắt đầu đếm ngày bên nhau ✨',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF8C7B75),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Couple Chibi Illustration in a beautiful rounded floating card
                            CuteBounceOnTap(
                              onTap: () {
                                LoveSparkleOverlay.show(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✨ Hai bạn thật đẹp đôi! Chúc hai bạn luôn ngập tràn hạnh phúc! 💕'),
                                    backgroundColor: Color(0xFFE85A42),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: HeartbeatPulse(
                                minScale: 0.98,
                                maxScale: 1.02,
                                duration: const Duration(milliseconds: 2400),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    // Soft warm aura glow behind illustration
                                    Container(
                                      width: 116,
                                      height: 116,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFFD5CD).withValues(alpha: 0.5),
                                            blurRadius: 22,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Rounded porcelain card frame
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(26),
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE85A42).withValues(alpha: 0.12),
                                            blurRadius: 18,
                                            offset: const Offset(0, 6),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.04),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(23),
                                        child: Image.asset(
                                          'assets/images/couple_illustration.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),

                                    // Floating sticker sparkles on top-right corner
                                    Positioned(
                                      top: -5,
                                      right: -5,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFFFE3DC), width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFE85A42).withValues(alpha: 0.2),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Text('✨', style: TextStyle(fontSize: 11)),
                                      ),
                                    ),

                                    // Floating mini heart on bottom-left corner
                                    Positioned(
                                      bottom: -3,
                                      left: -3,
                                      child: Container(
                                        padding: const EdgeInsets.all(3.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFECE9),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFE85A42).withValues(alpha: 0.18),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Text('💕', style: TextStyle(fontSize: 10)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Widget Tín hiệu tâm trạng hôm nay (Daily Mood) - chỉ hiện khi có partner
                        if (isConnected) _buildDailyMoodWidget(partnerName),

                        // Two Quick Action Cards Row (Side-by-side)
                        Row(
                          children: [
                            // Card 1: Liên kết với người ấy (White card)
                            Expanded(
                              child: CuteBounceOnTap(
                                onTap: _openInviteScreen,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: Colors.white, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE85A42).withValues(alpha: 0.07),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFECE9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            isConnected ? Icons.favorite_rounded : Icons.link_rounded,
                                            color: const Color(0xFFE85A42),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              isConnected ? 'Không gian' : 'Liên kết',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2C1914),
                                                height: 1.15,
                                              ),
                                            ),
                                            Text(
                                              isConnected ? 'của hai bạn' : 'với người ấy',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2C1914),
                                                height: 1.15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Card 2: Lên kèo hẹn hò (Coral Gradient card)
                            Expanded(
                              child: CuteBounceOnTap(
                                onTap: _openDatingPlanFlow,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFF1664F), Color(0xFFE44E38)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE44E38).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.22),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Lên kèo',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                height: 1.15,
                                              ),
                                            ),
                                            Text(
                                              'hẹn hò',
                                              style: TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                height: 1.15,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Love Advisor Hero Card (Chỉ xuất hiện khi sắp đến ngày quan trọng trước 3 ngày)
                        if (upcomingDate != null) ...[
                          CuteBounceOnTap(
                            onTap: () => _openDatingPlanFlow(occasionId: upcomingDate.occasionId),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFF0EC), Color(0xFFFFE3E8)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE85A42).withValues(alpha: 0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('✦', style: TextStyle(color: Color(0xFFE85A42), fontSize: 13)),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Love Advisor',
                                        style: AppTypography.script(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFE85A42),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        '· Cố vấn Tình yêu Ourly',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFB57062),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    upcomingDate.headline,
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2C1914),
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    upcomingDate.description,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Color(0xFF2C1914),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF231815),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Xem gợi ý hẹn hò',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Text('💌', style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // --- SỞ THÍCH & KẾ HOẠCH SECTION ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: 'Sở thích & Kế hoạch ',
                                style: AppTypography.script(fontSize: 24, color: AppColors.textPrimary),
                                children: const [
                                  TextSpan(text: '♡', style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal, color: AppColors.primary)),
                                ],
                              ),
                            ),
                            CuteBounceOnTap(
                              onTap: () {
                                setState(() => _showAllPreferences = !_showAllPreferences);
                              },
                              child: Text(
                                _showAllPreferences ? 'Thu gọn ‹' : 'Xem thêm ›',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Chips Row matching mockup (Coffee, Travel + Preferences)
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            _buildStyleChip('☕', 'Cà phê cuối tuần'),
                            _buildStyleChip('✈️', 'Du lịch cùng nhau'),
                            ..._preferences.take(4).map((p) => _buildPrefChipFromItem(p)),
                          ],
                        ),

                        // Expandable Preferences Detail List
                        if (_showAllPreferences) ...[
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Chi tiết sở thích',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              CuteBounceOnTap(
                                onTap: _openAddPreferenceModal,
                                child: TextButton.icon(
                                  onPressed: _openAddPreferenceModal,
                                  icon: const Icon(Icons.add_circle_outline, size: 16, color: AppColors.primary),
                                  label: const Text('Thêm mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('all', 'Tất cả (${_preferences.length})'),
                                _buildFilterChip('self', '🌟 Bạn chia sẻ'),
                                _buildFilterChip('partner', '💕 Người ấy chia sẻ'),
                                _buildFilterChip('private', '🔒 Ghi nhớ riêng'),
                                _buildFilterChip('surprise', '🎁 Kế hoạch bất ngờ'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (filteredPrefs.isEmpty)
                            const FrostedGlassBox(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              blur: 14,
                              opacity: 0.55,
                              child: Column(
                                children: [
                                  Text('🍃✨', style: TextStyle(fontSize: 24)),
                                  SizedBox(height: 6),
                                  Text(
                                    'Chưa có thông tin nào trong mục này',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...filteredPrefs.map((pref) => _buildPreferenceCard(pref, currentUid)),
                        ],

                        // Quote at bottom-left as in Image 3
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 12),
                          child: Text(
                            'Những điều nhỏ bé\nlàm nên chúng mình\n♡',
                            style: AppTypography.script(
                              fontSize: 15.5,
                              color: const Color(0xFFC4867C),
                              height: 1.3,
                            ),
                          ),
                        ),

                        // Section: Open our space (Không gian đôi lứa - Ảnh 2 & 3)
                        _buildOpenOurSpaceSection(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildOpenOurSpaceSection() {
    final history = _apiService.getDatePlanHistory();
    final historyCount = history.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề & Mascot chú thỏ xinh xắn
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Open our space',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C1914),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Không gian đôi lứa · Kỷ niệm & Lịch trình',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E847C),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Lưới 2x2 các thẻ chức năng (Love Streak, Favorite places, Date history, Gifts chosen)
        Row(
          children: [
            // Thẻ 1: Chuỗi yêu thương
            Builder(
              builder: (context) {
                final daysTogether = _apiService.getDaysTogether();
                return _buildSpaceCard(
                  emoji: '🔥',
                  title: 'Chuỗi yêu thương',
                  subtitle: daysTogether != null ? '$daysTogether ngày bên nhau' : 'Chưa thiết lập ngày',
                  englishLabel: 'Love Streak',
                  gradientColors: const [Color(0xFFFFF2EE), Color(0xFFFFE6DE)],
                  onTap: () {
                    if (daysTogether != null) {
                      LoveSparkleOverlay.show(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF2C1914),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          content: Row(
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text('Chuỗi yêu thương $daysTogether ngày! Giữ vững ngọn lửa này nhé! 💕'),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } else {
                      _pickDatingStartDate(context);
                    }
                  },
                );
              },
            ),
            const SizedBox(width: 12),

            // Thẻ 2: Địa điểm yêu thích
            _buildSpaceCard(
              emoji: '📍',
              title: 'Địa điểm yêu thích',
              subtitle: '7 điểm đã lưu',
              englishLabel: 'Favorite places',
              gradientColors: const [Color(0xFFEFF3FF), Color(0xFFE5EEFF)],
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF2C1914),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    content: const Row(
                      children: [
                        Text('📍', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text('Bạn đã lưu 7 địa điểm hẹn hò lãng mạn cho hai người!'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // Thẻ 3: LỊCH SỬ HẸN HÒ (Date history) -> Nhấn vào xem danh sách & chi tiết!
            _buildSpaceCard(
              emoji: '🗺️',
              title: 'Lịch sử hẹn hò',
              subtitle: '$historyCount buổi hẹn đã lên',
              englishLabel: 'Date history · Xem chi tiết ›',
              gradientColors: const [Color(0xFFF9EFFD), Color(0xFFEFE4FA)],
              isHighlighted: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const DatingHistoryScreen()),
                ).then((_) {
                  setState(() {});
                });
              },
            ),
            const SizedBox(width: 12),

            // Thẻ 4: Quà tặng đã chọn
            _buildSpaceCard(
              emoji: '🎁',
              title: 'Quà tặng đã chọn',
              subtitle: '3 món quà ngọt ngào',
              englishLabel: 'Gifts chosen',
              gradientColors: const [Color(0xFFFFF6EB), Color(0xFFFFEFE2)],
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF2C1914),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    content: const Row(
                      children: [
                        Text('🎁', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 8),
                        Text('Đã có 3 món quà bất ngờ được gửi gắm cho người ấy!'),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpaceCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String englishLabel,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: CuteBounceOnTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isHighlighted
                  ? const Color(0xFFDABCF6)
                  : Colors.white.withValues(alpha: 0.85),
              width: isHighlighted ? 1.5 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C1810),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7A655E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                englishLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isHighlighted ? const Color(0xFF9C42E8) : const Color(0xFFB57062),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSel = _activeFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSel,
        selectedColor: AppColors.tagSelectedBg,
        backgroundColor: Colors.white,
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
          color: isSel ? AppColors.tagSelectedText : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isSel ? AppColors.tagSelectedBorder : AppColors.border),
        ),
        onSelected: (val) => setState(() => _activeFilter = key),
      ),
    );
  }

  Widget _buildPreferenceCard(PreferenceItem pref, String currentUid) {
    final isOwn = pref.createdByUserId == currentUid;
    String badgeText = '🌟 Bạn tự chia sẻ';
    Color badgeBg = AppColors.sharedBadgeBg;
    Color badgeColor = AppColors.sharedBadgeText;

    if (pref.isSurprise) {
      badgeText = '🎁 Kế hoạch bất ngờ (Bảo vệ bí mật)';
      badgeBg = AppColors.surpriseBadgeBg;
      badgeColor = AppColors.surpriseBadgeText;
    } else if (pref.visibility == PreferenceVisibility.private) {
      badgeText = '🔒 Điều bạn ghi nhớ riêng';
      badgeBg = AppColors.privateBadgeBg;
      badgeColor = AppColors.privateBadgeText;
    } else if (!isOwn) {
      badgeText = '💕 Người ấy chia sẻ';
      badgeBg = AppColors.avatarPinkBg;
      badgeColor = AppColors.avatarPinkText;
    }

    return CuteBounceOnTap(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: AppShadows.card3D,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                  ),
                ),
                const Spacer(),
                Text(
                  pref.type,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              pref.value,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleChip(String emoji, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2EAE4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C1914),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefChipFromItem(PreferenceItem item) {
    String emoji = '🌟';
    if (item.type.contains('Ăn') || item.type.contains('Uống')) emoji = '🍽️';
    if (item.type.contains('Phim') || item.type.contains('Nhạc')) emoji = '🎬';
    if (item.type.contains('Du lịch')) emoji = '✈️';
    if (item.type.contains('Cà phê')) emoji = '☕';
    if (item.isSurprise) emoji = '🎁';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2EAE4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(
            item.value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C1914),
            ),
          ),
        ],
      ),
    );
  }

  // --- FLOATING CUPID LOVE ADVISOR FAB ---
  Widget _buildAngelRobotFab() {
    return HeartbeatPulse(
      minScale: 0.94,
      maxScale: 1.06,
      duration: const Duration(milliseconds: 1600),
      child: CuteBounceOnTap(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE85A42), Color(0xFFFA7268)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE85A42).withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
          ),
          child: const Center(
            child: WavingCupidWidget(size: 38, animate: true),
          ),
        ),
      ),
    );
  }

  // --- PROFILE MODAL (SELF & PARTNER) ---
  void _showProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final user = _apiService.currentUser;
          final currentUid = user?.uid ?? '';
          final isConnected = _couple?.status == CoupleStatus.connected;

          // Use UID-based participant lookup (same as build() method)
          // Avoids self-match bug for invitee users
          final myParticipantInModal = _couple?.participantForUser(currentUid);
          final partnerParticipantInModal = _couple != null && currentUid.isNotEmpty
              ? _couple!.participants.firstWhere(
                  (p) => p.linkedUserId != currentUid,
                  orElse: () => _couple!.participants.last,
                )
              : null;

          final myNickname = (user?.nickname.isNotEmpty == true)
              ? user!.nickname
              : (myParticipantInModal?.nickname ?? 'Bạn');
          final partnerInModal = isConnected ? partnerParticipantInModal : null;

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.only(top: 16, left: 22, right: 22, bottom: 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isConnected ? 'Hồ sơ của hai bạn 💕' : 'Hồ sơ cá nhân',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isConnected ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isConnected ? Colors.green.shade200 : Colors.amber.shade300,
                          ),
                        ),
                        child: Text(
                          isConnected ? '🟢 Đã ghép đôi' : '🟡 Không gian riêng',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? Colors.green.shade700 : Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Card 1: Your Profile
                  _buildProfileCard(
                    title: 'Hồ sơ của bạn',
                    name: myNickname,
                    email: user?.email ?? 'Chưa cập nhật email',
                    birthday: user?.birthday ?? 'Chưa cập nhật',
                    gender: user?.gender,
                    avatar: user?.avatar ?? '',
                    avatarBg: AppColors.avatarBlueBg,
                    avatarText: AppColors.avatarBlueText,
                    role: 'Người khởi tạo không gian',
                    isSelf: true,
                    onEdit: () => _openEditProfileModal(context, setModalState),
                    onAvatarTap: () => _openAvatarPickerModal(context, setModalState),
                    onBirthdayTap: () => _pickBirthdayForSelf(context, setModalState),
                    onAddPreference: () => _openAddPreferenceModal(setParentModalState: setModalState),
                  ),
                  const SizedBox(height: 16),

                  // Setting Ngày kỷ niệm của hai bạn
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFF3E7DF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE85A42).withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFEEF1),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text('💑', style: TextStyle(fontSize: 19)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ngày bắt đầu hẹn hò 💕',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Builder(
                                    builder: (context) {
                                      final datingStart = _apiService.getDatingStartDate();
                                      final daysTogether = _apiService.getDaysTogether();
                                      return Text(
                                        datingStart != null
                                            ? '${OurlyDatePicker.formatDate(datingStart)} · ($daysTogether ngày bên nhau)'
                                            : 'Chưa thiết lập ngày hẹn hò',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: datingStart != null
                                              ? const Color(0xFF7A6B65)
                                              : const Color(0xFF9E8E89),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            CuteBounceOnTap(
                              onTap: () => _pickDatingStartDate(context, setModalState),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECE9),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  _apiService.hasDatingStartDate ? 'Đổi ngày' : 'Chọn ngày',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE85A42),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF3E7DF)),
                        const SizedBox(height: 10),
                        const Text(
                          'Thử nghiệm hiển thị card Love Advisor trên Home:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8C7A74)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildQuickResetDateChip(setModalState),
                            _buildQuickTestDateChip('3 ngày nữa', 3, setModalState),
                            _buildQuickTestDateChip('1 ngày nữa', 1, setModalState),
                            _buildQuickTestDateChip('Hôm nay', 0, setModalState),
                            _buildQuickTestDateChip('7 ngày (Ẩn card)', 7, setModalState),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Card 2: Partner's Profile
                  if (isConnected) ...[
                    _buildProfileCard(
                      title: 'Hồ sơ người ấy',
                      name: partnerInModal?.nickname ?? 'Người ấy',
                      email: 'Người đồng hành kết nối',
                      birthday: 'Chưa cập nhật',
                      avatar: '',
                      avatarBg: AppColors.avatarPinkBg,
                      avatarText: AppColors.avatarPinkText,
                      role: 'Người đồng hành kết nối',
                      isSelf: false,
                    ),
                    const SizedBox(height: 12),
                    CuteBounceOnTap(
                      onTap: () => _showUnlinkPartnerConfirmDialog(ctx, setModalState),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFD5CD), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.link_off_rounded, size: 18, color: Color(0xFFD94841)),
                            const SizedBox(width: 8),
                            Text(
                              'Huỷ liên kết với người ấy',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFD94841),
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    FrostedGlassBox(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      blur: 12,
                      opacity: 0.6,
                      child: Column(
                        children: [
                          const Text('💞', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          const Text(
                            'Chưa kết nối với người ấy',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Sau khi người ấy tham gia qua liên kết mời, thông tin của đối phương sẽ hiển thị tại đây.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _openInviteScreen();
                                  },
                                  icon: const Icon(Icons.link, size: 16),
                                  label: const Text('Lấy link mời'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _openInviteScreen();
                                  },
                                  icon: const Icon(Icons.favorite_border, size: 16),
                                  label: const Text('Nhập link'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CuteBounceOnTap(
                      onTap: () => _showLogoutConfirmDialog(ctx),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text(
                              'Đăng xuất tài khoản',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TOP-RIGHT ANIMATED AVATAR BUTTON (Ảnh 2) ---
  Widget _buildHeaderAvatarButton(bool isConnected, String creatorName, String partnerName) {
    final userInitial = creatorName.trim().isNotEmpty ? creatorName.trim()[0].toUpperCase() : 'M';
    final partnerInitial = partnerName.trim().isNotEmpty ? partnerName.trim()[0].toUpperCase() : 'E';

    if (isConnected) {
      // Case có partner: Hiển thị 2 avatar lồng vào nhau (M & E) như Ảnh 2
      return SizedBox(
        height: 42,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar Bạn (Màu xanh dương pastel như ảnh 2)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFDFE9FF), Color(0xFFC7D8FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                userInitial,
                style: AppTypography.script(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2B5CB8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            // Avatar Người ấy (Màu hồng đào pastel lồng vào)
            Transform.translate(
              offset: const Offset(-10, 0),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFDFE8), Color(0xFFFFD1DC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  partnerInitial,
                  style: AppTypography.script(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE85A42),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Case chưa match partner: Hiển thị 1 avatar đơn của user
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFDFE9FF), Color(0xFFC7D8FE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          userInitial,
          style: AppTypography.script(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2B5CB8),
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
  }

  // --- NOTIFICATIONS BOTTOM SHEET (Nút chuông thông báo) ---
  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.notifications_active_rounded, color: Color(0xFFE85A42), size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thông báo yêu thương',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2C1914),
                        ),
                      ),
                      Text(
                        'Các cập nhật và khoảnh khắc đáng nhớ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF8C7A74),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Builder(
              builder: (context) {
                final daysTogether = _apiService.getDaysTogether();
                final upcoming = _getUpcomingImportantDate();
                return Column(
                  children: [
                    if (upcoming != null)
                      _buildNotiItem(
                        emoji: '🔔',
                        title: '${upcoming.title} sắp đến!',
                        content: upcoming.headline,
                        time: 'Vừa xong',
                        isHighlight: true,
                      )
                    else
                      _buildNotiItem(
                        emoji: '✨',
                        title: 'Chào mừng đến với Ourly',
                        content: 'Hãy thiết lập ngày hẹn hò để ghi dấu những khoảnh khắc ngọt ngào bên nhau!',
                        time: 'Vừa xong',
                        isHighlight: true,
                      ),
                    const SizedBox(height: 10),
                    _buildNotiItem(
                      emoji: '💖',
                      title: 'Chuỗi yêu thương rực rỡ',
                      content: daysTogether != null
                          ? 'Hai bạn đã đạt $daysTogether ngày bên nhau tràn đầy hạnh phúc!'
                          : 'Bắt đầu đếm chuỗi ngày yêu thương ngay khi thiết lập ngày hẹn hò.',
                      time: 'Hôm nay',
                      isHighlight: false,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            _buildNotiItem(
              emoji: '💡',
              title: 'Gợi ý hẹn hò tuần này',
              content: 'Ourly vừa cập nhật các quán cà phê và workshop đôi mới nhất.',
              time: 'Hôm qua',
              isHighlight: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotiItem({
    required String emoji,
    required String title,
    required String content,
    required String time,
    required bool isHighlight,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFFF6F3) : const Color(0xFFFAF6F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlight ? const Color(0xFFFFDDD2) : const Color(0xFFF1EAE4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C1914),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF9E8E89),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF6B5852),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- LOGOUT CONFIRMATION DIALOG (Yêu cầu 3) ---
  void _showLogoutConfirmDialog(BuildContext parentModalContext) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.logout_rounded, color: Colors.redAccent, size: 26),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Xác nhận đăng xuất?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C1914),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn có chắc chắn muốn đăng xuất khỏi Ourly không? Hai bạn sẽ tạm thời không nhận được thông báo về các cột mốc quan trọng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A6B65),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5A443E),
                        side: const BorderSide(color: Color(0xFFE5DCD5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Ở lại', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        Navigator.of(parentModalContext).pop();
                        widget.onLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UNLINK PARTNER CONFIRMATION DIALOG (Yêu cầu 3) ---
  void _showUnlinkPartnerConfirmDialog(BuildContext parentModalContext, StateSetter parentSetModalState) {
    final partnerName = _couple?.partnerParticipant?.nickname ?? 'Người ấy';
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEEEE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.link_off_rounded, color: Color(0xFFD94841), size: 26),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Huỷ liên kết với $partnerName?',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2C1914),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn có chắc chắn muốn huỷ liên kết đôi lứa với $partnerName không?\n\nSau khi huỷ, không gian sẽ trở về chế độ riêng tư (Solo) và dữ liệu chung sẽ tạm ngừng đồng bộ. Bạn có thể tạo mã mời mới bất cứ lúc nào.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: const Color(0xFF7A6B65),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Giữ liên kết',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A6B65),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(dialogCtx).pop(); // Close confirm dialog
                        Navigator.of(parentModalContext).pop(); // Close profile sheet

                        if (_couple != null) {
                          final updated = await _apiService.unlinkPartner(_couple!.id);
                          if (mounted) {
                            setState(() {
                              if (updated != null) {
                                _couple = updated;
                              }
                            });
                            _loadData();
                            OurlyToast.showInfo(
                              context,
                              'Đã huỷ liên kết với partner. Không gian đã chuyển về chế độ riêng tư.',
                              title: 'Đã ngắt kết nối',
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD94841),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Xác nhận huỷ',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET TÍN HIỆU TÂM TRẠNG HÔM NAY (Yêu cầu 5) ---
  Widget _buildDailyMoodWidget(String partnerName) {
    final userMood = _apiService.getTodayUserMood();
    final partnerMood = _apiService.getTodayPartnerMood();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF9F5), Color(0xFFFFF0EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFDED4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE85A42).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECE6),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🌤️', style: TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TÍN HIỆU TÂM TRẠNG HÔM NAY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFFE85A42),
                    ),
                  ),
                ],
              ),
              CuteBounceOnTap(
                onTap: () {
                  DailyMoodDialog.show(
                    context,
                    partnerName: partnerName,
                    onMoodSubmitted: (_) {
                      if (mounted) setState(() {});
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD5C7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userMood != null ? 'Đổi tâm trạng' : 'Check-in ngay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE85A42),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFE85A42)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mood Status Cards Row (2 Cards: Bạn & Người ấy)
          Row(
            children: [
              // 1. Tâm trạng của bạn
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3E7DF)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        userMood?.emoji ?? '💭',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bạn',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9E8E89),
                              ),
                            ),
                            Text(
                              userMood?.label ?? 'Chưa cập nhật',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2C1914),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Tâm trạng của người ấy
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3E7DF)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        partnerMood?.emoji ?? '🥰',
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partnerName,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9E8E89),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              partnerMood?.label ?? 'Đang yêu đời',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2C1914),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Lời khuyên quan tâm cho bạn
          if (partnerMood != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      partnerMood.partnerHint,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B453D),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- AVATAR PICKER SHEET ---
  void _openAvatarPickerModal(BuildContext context, StateSetter parentSetModalState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chọn ảnh đại diện ✨',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tải ảnh từ máy lên Cloudinary hoặc chọn biểu tượng đáng yêu',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Option 1: Pick from device (Cloudinary upload)
            CuteBounceOnTap(
              onTap: () async {
                Navigator.of(ctx).pop();
                final picked = await AvatarPickerHelper.pickAvatarFromDevice();
                if (picked != null) {
                  await _apiService.updateCurrentUserProfile(avatar: picked);
                  parentSetModalState(() {});
                  setState(() {});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Đã cập nhật ảnh đại diện thành công! ✨'),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF7E79), Color(0xFFFF5252)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.button3D,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tải ảnh từ thiết bị (Cloudinary)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Option 2: Choose preset emoji
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'HOẶC CHỌN BIỂU TƯỢNG ĐÁNG YÊU',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                '🐶', '🐱', '🦊', '🐰', '🐼', '🐨',
                '🌸', '🍓', '🥑', '🌟', '💖', '🐻',
                '🐧', '🦁', '🐯', '🦄', '🎀', '🎈',
              ].map((emoji) {
                return CuteBounceOnTap(
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await _apiService.updateCurrentUserProfile(avatar: emoji);
                    parentSetModalState(() {});
                    setState(() {});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: Row(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              const Text('Đã cập nhật ảnh đại diện biểu tượng!'),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Option 3: Reset to initial letter
            CuteBounceOnTap(
              onTap: () async {
                Navigator.of(ctx).pop();
                await _apiService.updateCurrentUserProfile(clearAvatar: true);
                parentSetModalState(() {});
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      content: const Row(
                        children: [
                          Icon(Icons.text_fields_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text('Đã đặt về chữ cái đầu tiên của tên bạn!'),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Dùng chữ cái đầu tên: ${OurlyAvatarView.getInitialLetter(_apiService.currentUser?.nickname ?? "B")}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- EDIT PROFILE MODAL ---
  void _openEditProfileModal(BuildContext context, StateSetter parentSetModalState) {
    final currentUser = _apiService.currentUser;
    final nameController = TextEditingController(text: currentUser?.nickname ?? '');
    String currentBirthday = currentUser?.birthday ?? '';
    String? currentGender = currentUser?.gender;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setEditState) {
          final effectiveName = nameController.text.trim().isNotEmpty ? nameController.text.trim() : (currentUser?.nickname ?? 'Bạn');

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 24,
              top: 16,
              left: 22,
              right: 22,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Chỉnh sửa thông tin cá nhân 💕',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Avatar preview with tap to change
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        OurlyAvatarView(
                          avatar: _apiService.currentUser?.avatar,
                          fallbackText: effectiveName,
                          size: 72,
                          backgroundColor: AppColors.avatarBlueBg,
                          textColor: AppColors.avatarBlueText,
                          onTap: () {
                            _openAvatarPickerModal(context, (fn) {
                              parentSetModalState(fn);
                              setEditState(fn);
                            });
                          },
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CuteBounceOnTap(
                            onTap: () {
                              _openAvatarPickerModal(context, (fn) {
                                parentSetModalState(fn);
                                setEditState(fn);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: AppShadows.subtle3D,
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        _openAvatarPickerModal(context, (fn) {
                          parentSetModalState(fn);
                          setEditState(fn);
                        });
                      },
                      icon: const Icon(Icons.image_outlined, size: 16, color: AppColors.primary),
                      label: const Text('Đổi ảnh đại diện', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nickname input
                  const Text('TÊN / BIỆT DANH CỦA BẠN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tên hiển thị của bạn...',
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (_) => setEditState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Birthday picker
                  const Text('NGÀY SINH CỦA BẠN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () async {
                      final parsed = OurlyDatePicker.parseDate(currentBirthday);
                      final picked = await OurlyDatePicker.pickDate(
                        context: dialogCtx,
                        initialDate: parsed ?? DateTime(2000, 1, 1),
                        lastDate: DateTime.now(),
                        helpText: 'CẬP NHẬT NGÀY SINH',
                      );
                      if (picked != null) {
                        final formatted = OurlyDatePicker.formatDate(picked);
                        setEditState(() => currentBirthday = formatted);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cake_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentBirthday.isNotEmpty ? currentBirthday : 'Chưa cập nhật ngày sinh',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: currentBirthday.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                                color: currentBirthday.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gender selector
                  const Text('GIỚI TÍNH CỦA BẠN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModalGenderOption('male', 'Nam', '👨', currentGender, (g) {
                          setEditState(() => currentGender = g);
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildModalGenderOption('female', 'Nữ', '👩', currentGender, (g) {
                          setEditState(() => currentGender = g);
                        }),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildModalGenderOption('other', 'Khác', '✨', currentGender, (g) {
                          setEditState(() => currentGender = g);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Email (read-only display)
                  const Text('EMAIL TÀI KHOẢN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.email_outlined, color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          currentUser?.email ?? 'Chưa cập nhật email',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CuteBounceOnTap(
                      onTap: () async {
                        final newName = nameController.text.trim();
                        if (newName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập tên của bạn')),
                          );
                          return;
                        }
                        Navigator.of(dialogCtx).pop();

                        await _apiService.updateCurrentUserProfile(
                          nickname: newName,
                          birthday: currentBirthday.isNotEmpty ? currentBirthday : null,
                          gender: currentGender,
                        );

                        await _loadData();

                        parentSetModalState(() {});
                        setState(() {});

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Đã cập nhật thông tin thành công! 🎉'),
                                ],
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF7E79), Color(0xFFFF5252)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: AppShadows.button3D,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Lưu thay đổi',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required String name,
    required String email,
    required String birthday,
    String? gender,
    required String avatar,
    required Color avatarBg,
    required Color avatarText,
    required String role,
    required bool isSelf,
    VoidCallback? onEdit,
    VoidCallback? onAvatarTap,
    VoidCallback? onBirthdayTap,
    VoidCallback? onAddPreference,
  }) {
    final userPrefs = _preferences.where((p) => isSelf ? p.createdByUserId == (_apiService.currentUser?.uid ?? '') : p.createdByUserId != (_apiService.currentUser?.uid ?? '')).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: AppShadows.card3D,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              if (isSelf)
                CuteBounceOnTap(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Sửa thông tin',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  OurlyAvatarView(
                    avatar: avatar,
                    fallbackText: name,
                    size: 58,
                    backgroundColor: avatarBg,
                    textColor: avatarText,
                    onTap: isSelf ? onAvatarTap : null,
                  ),
                  if (isSelf)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: CuteBounceOnTap(
                        onTap: onAvatarTap,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF7E79), Color(0xFFFF5252)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: AppShadows.subtle3D,
                          ),
                          child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: isSelf ? onEdit : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              if (isSelf) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_rounded, size: 13, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.avatarBlueBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Bạn', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.avatarBlueText)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),

          // Detail rows: Birthday
          Row(
            children: [
              const Icon(Icons.cake_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('Ngày sinh: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                birthday.isNotEmpty ? birthday : 'Chưa cập nhật',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              if (isSelf) ...[
                const SizedBox(width: 8),
                CuteBounceOnTap(
                  onTap: onBirthdayTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 12, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Đổi ngày',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Detail row: Giới tính
          if (isSelf || (gender != null && gender.isNotEmpty)) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.wc_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Giới tính: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(
                  _formatGender(gender),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                if (isSelf) ...[
                  const SizedBox(width: 8),
                  CuteBounceOnTap(
                    onTap: onEdit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined, size: 12, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text(
                            'Đổi',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (userPrefs.isNotEmpty || isSelf) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sở thích đã chia sẻ:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                if (isSelf)
                  CuteBounceOnTap(
                    onTap: onAddPreference,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 12, color: AppColors.primary),
                          SizedBox(width: 2),
                          Text('Thêm', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...userPrefs.take(4).map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(p.value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                )),
              ],
            ),
          ],

          // Prominent Edit Profile Button (Full Width)
          if (isSelf) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: CuteBounceOnTap(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7E79), Color(0xFFFF5252)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppShadows.subtle3D,
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, size: 15, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Chỉnh sửa tên & thông tin cá nhân',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatGender(String? gender) {
    if (gender == 'male') return 'Nam 👨';
    if (gender == 'female') return 'Nữ 👩';
    if (gender == 'other') return 'Khác ✨';
    return 'Chưa cập nhật';
  }

  Widget _buildModalGenderOption(String value, String label, String emoji, String? currentGender, ValueChanged<String> onSelected) {
    final isSelected = currentGender == value;
    return CuteBounceOnTap(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFECE9) : const Color(0xFFF9F5F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFE85A42) : const Color(0xFFEFE8E3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE85A42).withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFFE85A42) : const Color(0xFF5A4842),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
