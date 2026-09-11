import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/couple_space.dart';
import '../models/preference.dart';
import 'accept_invite_dialog.dart';
import 'chatbot_screen.dart';
import '../widgets/romantic_effects.dart';
import '../widgets/ourly_date_picker.dart';

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

class _DashboardScreenState extends State<DashboardScreen> {
  final _apiService = ApiService();
  CoupleSpace? _couple;
  List<PreferenceItem> _preferences = [];
  bool _isLoading = true;
  String _activeFilter = 'all'; // all, self, partner, private, surprise

  @override
  void initState() {
    super.initState();
    _loadData();
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

  void _openAcceptInviteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AcceptInviteDialog(
        onAccepted: () {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Chúc mừng hai bạn đã kết nối Couple Space thành công!'),
              backgroundColor: AppColors.primary,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiService.currentUser;
    final isConnected = _couple?.status == CoupleStatus.connected;
    final myNickname = (user?.nickname.isNotEmpty == true ? user!.nickname : (_couple?.creatorParticipant?.nickname ?? 'Bạn'));
    final creatorName = myNickname;
    final partnerName = _couple?.partnerParticipant?.nickname ?? 'Người ấy';
    final currentUid = user?.uid ?? '';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _buildAngelRobotFab(),
      body: FloatingHeartsBackground(
        count: 14,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top App Bar
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Quick Love Sparkle Button
                            CuteBounceOnTap(
                              onTap: () {
                                LoveSparkleOverlay.show(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Text('💖', style: TextStyle(fontSize: 18)),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Đã gửi một triệu trái tim yêu thương đến người ấy! ✨🌸',
                                            style: TextStyle(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFFE85A42),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Tooltip(
                                message: 'Gửi triệu tim cho người ấy',
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFEEF0), Color(0xFFFFDDE2)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE85A42).withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text('💖', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Notification bell icon
                            CuteBounceOnTap(
                              onTap: () {},
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: AppShadows.pill3D,
                                ),
                                child: const Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(Icons.notifications_none_outlined, size: 20, color: AppColors.textSecondary),
                                    Positioned(
                                      top: 8,
                                      right: 9,
                                      child: CircleAvatar(radius: 3.5, backgroundColor: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Avatars (Overlapping circle badges) - Clickable to view profiles
                            HeartbeatPulse(
                              minScale: 0.96,
                              maxScale: 1.05,
                              child: CuteBounceOnTap(
                                onTap: _showProfileModal,
                                child: Tooltip(
                                  message: 'Xem thông tin cá nhân & người ấy',
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      OurlyAvatarView(
                                        avatar: user?.avatar,
                                        fallbackText: creatorName,
                                        size: 38,
                                        backgroundColor: AppColors.avatarBlueBg,
                                        textColor: AppColors.avatarBlueText,
                                      ),
                                      if (isConnected)
                                        Positioned(
                                          left: 24,
                                          child: OurlyAvatarView(
                                            avatar: null,
                                            fallbackText: partnerName,
                                            size: 38,
                                            backgroundColor: AppColors.avatarPinkBg,
                                            textColor: AppColors.avatarPinkText,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (isConnected) const SizedBox(width: 24),
                          ],
                        ),
                        const SizedBox(height: 20),

                      // Status Alert / Pending Invite Banner
                      if (!isConnected) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              const Text('⏳', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Đang ở chế độ Không gian riêng (Solo)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF856404))),
                                    Text('Chưa kết nối với người ấy. Hãy gửi liên kết mời hoặc nhập link từ đối phương.', style: TextStyle(fontSize: 11.5, color: Color(0xFF856404))),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: widget.onShowInvite,
                                child: const Text('Lấy link', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Button for Partner B to accept
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _openAcceptInviteDialog,
                            icon: const Icon(Icons.link, size: 18),
                            label: const Text('Nhập liên kết mời từ người ấy (Partner Accept)'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Notification Card 1 (Mockup: Cô ấy thích hoa...)
                      CuteBounceOnTap(
                        onTap: () {
                          LoveSparkleOverlay.show(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 10, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Text('🌷', style: TextStyle(fontSize: 18)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Cô ấy thích hoa. Bạn chưa mua. Chúng ta cần nói chuyện. 👀',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                ),
                              ),
                              Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Counter Card 2 (Mockup: 412 days together...)
                      CuteBounceOnTap(
                        onTap: () {
                          LoveSparkleOverlay.show(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: AppShadows.card3D,
                          ),
                          child: Row(
                            children: [
                              const HeartbeatPulse(
                                minScale: 0.9,
                                maxScale: 1.18,
                                child: Text('💖', style: TextStyle(fontSize: 18)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: '412 ngày ',
                                    style: AppTypography.script(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    children: const [
                                      TextSpan(text: 'bên nhau · Kỷ niệm trong 3 ngày nữa', style: TextStyle(fontWeight: FontWeight.normal, color: AppColors.textSecondary, fontSize: 12.5)),
                                    ],
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Love Advisor Hero Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFDE8E2), Color(0xFFF8DCE2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                          boxShadow: AppShadows.card3D,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('✦', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                                const SizedBox(width: 6),
                                Text(
                                  'Love Advisor',
                                  style: AppTypography.script(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '· Cố vấn Tình yêu Ourly',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.stepLabel),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Kỷ niệm 3 ngày nữa là đến rồi 💕\nOurly đã chuẩn bị sẵn kế hoạch hẹn hò cho hai bạn.',
                              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3),
                            ),
                            const SizedBox(height: 18),
                            CuteBounceOnTap(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                                );
                              },
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const ChatbotScreen()),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C1914),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  elevation: 0,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Xem gợi ý hẹn hò', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                    SizedBox(width: 6),
                                    Text('💌', style: TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // --- PREFERENCES SECTION ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sở thích & Kế hoạch',
                            style: AppTypography.script(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          CuteBounceOnTap(
                            onTap: _openAddPreferenceModal,
                            child: TextButton.icon(
                              onPressed: _openAddPreferenceModal,
                              icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
                              label: const Text('Thêm mới', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Filter Segment Tabs
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
                      const SizedBox(height: 14),

                      // Preferences Cards List
                      if (filteredPrefs.isEmpty)
                        const FrostedGlassBox(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                          blur: 14,
                          opacity: 0.55,
                          child: Column(
                            children: [
                              Text('🍃✨', style: TextStyle(fontSize: 28)),
                              SizedBox(height: 8),
                              Text(
                                'Chưa có thông tin nào trong mục này',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredPrefs.map((pref) => _buildPreferenceCard(pref, currentUid)),

                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'Ourly · Không gian tình yêu của hai bạn 💕✨',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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

  // --- FLOATING CUPID LOVE ADVISOR FAB ---
  Widget _buildAngelRobotFab() {
    return HeartbeatPulse(
      minScale: 0.96,
      maxScale: 1.04,
      duration: const Duration(milliseconds: 1600),
      child: CuteBounceOnTap(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ChatbotScreen()),
          );
        },
        child: Container(
          height: 54,
          padding: const EdgeInsets.only(left: 10, right: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE85A42), Color(0xFFFA7268)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE85A42).withValues(alpha: 0.45),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              WavingCupidWidget(size: 38, animate: true),
              SizedBox(width: 8),
              Text(
                'Quân sư tình yêu',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(width: 4),
              Text('✨', style: TextStyle(fontSize: 14)),
            ],
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
          final isConnected = _couple?.status == CoupleStatus.connected;
          final creator = _couple?.creatorParticipant;
          final partner = _couple?.partnerParticipant;
          final myNickname = (user?.nickname.isNotEmpty == true)
              ? user!.nickname
              : (creator?.nickname ?? 'Bạn');

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

                  // Card 2: Partner's Profile
                  if (isConnected) ...[
                    _buildProfileCard(
                      title: 'Hồ sơ người ấy',
                      name: partner?.nickname ?? 'Người ấy',
                      email: 'Người đồng hành kết nối',
                      birthday: 'Chưa cập nhật',
                      avatar: '',
                      avatarBg: AppColors.avatarPinkBg,
                      avatarText: AppColors.avatarPinkText,
                      role: 'Người đồng hành kết nối',
                      isSelf: false,
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
                                    widget.onShowInvite();
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
                                    _openAcceptInviteDialog();
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
                      onTap: () {
                        Navigator.of(ctx).pop();
                        widget.onLogout();
                      },
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
}
