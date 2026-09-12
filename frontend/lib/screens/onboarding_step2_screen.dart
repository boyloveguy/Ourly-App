import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/couple_space.dart';
import '../widgets/romantic_effects.dart';
import '../widgets/ourly_date_picker.dart';

class OnboardingStep2Screen extends StatefulWidget {
  final VoidCallback onEnterSpace;
  final VoidCallback onBack;
  final bool isFromDashboard;

  const OnboardingStep2Screen({
    super.key,
    required this.onEnterSpace,
    required this.onBack,
    this.isFromDashboard = false,
  });

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  final _apiService = ApiService();
  String _inviteCode = 'LV-8K2M';
  final _acceptLinkController = TextEditingController();
  bool _isConnecting = false;
  CoupleSpace? _couple;

  @override
  void initState() {
    super.initState();
    _loadOrCreateInvite();
  }

  @override
  void dispose() {
    _acceptLinkController.dispose();
    super.dispose();
  }

  String _extractToken(String input) {
    input = input.trim();
    if (input.contains('/invite/')) {
      input = input.split('/invite/').last.trim();
    }
    if (input.contains('/INVITE/')) {
      input = input.split('/INVITE/').last.trim();
    }
    if (input.contains('?')) {
      input = input.split('?').first.trim();
    }
    if (input.contains('#')) {
      input = input.split('#').first.trim();
    }
    while (input.endsWith('/')) {
      input = input.substring(0, input.length - 1).trim();
    }
    input = input.toUpperCase();
    if (input.length == 4 && !input.startsWith('LV-')) {
      input = 'LV-$input';
    }
    return input;
  }

  Future<void> _checkClipboardForInviteLink() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isNotEmpty) {
        if (text.contains('ourly.app/invite/') || text.startsWith('LV-') || text.startsWith('lv-') || (text.length == 4 && !text.contains(' '))) {
          final token = _extractToken(text);
          if (token.isNotEmpty && token != _inviteCode && _acceptLinkController.text.isEmpty) {
            _acceptLinkController.text = text;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã nhận diện liên kết mời từ bộ nhớ tạm: $token 💕'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.isNotEmpty) {
        setState(() {
          _acceptLinkController.text = text;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleConnectPartnerLink() async {
    final token = _extractToken(_acceptLinkController.text);
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng dán liên kết mời từ người ấy.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final nickname = _apiService.currentUser?.nickname ?? 'Bạn';
      final ok = await _apiService.acceptInvite(token: token, nickname: nickname);
      if (ok) {
        if (mounted) {
          final updatedCouple = await _apiService.getCurrentCouple();
          setState(() {
            _couple = updatedCouple;
          });
          LoveSparkleOverlay.show(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Chúc mừng hai bạn đã kết nối Couple Space thành công!'),
              backgroundColor: AppColors.primary,
            ),
          );
          widget.onEnterSpace();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể chấp nhận lời mời. Liên kết không hợp lệ hoặc đã hết hạn.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _loadOrCreateInvite() async {
    try {
      final c = await _apiService.getCurrentCouple();
      if (mounted) {
        setState(() => _couple = c);
      }
    } catch (_) {}

    final user = _apiService.currentUser;
    final coupleId = user?.activeCoupleId ?? _couple?.id;
    if (coupleId != null) {
      try {
        final inv = await _apiService.createInvite(coupleId);
        if (mounted) {
          setState(() {
            _inviteCode = inv.token;
          });
        }
      } catch (_) {}
    }

    _checkClipboardForInviteLink();
  }

  String get _inviteLink => 'https://ourly.app/invite/$_inviteCode';

  void _copyInviteLink() {
    Clipboard.setData(ClipboardData(text: _inviteLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép liên kết mời: $_inviteLink\nHãy gửi cho người ấy nhé! 💕'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickDatingStartDate() async {
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
        _apiService.setDatingStartDate(picked);
      });
      if (mounted) {
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
                Text('Đã lưu ngày bắt đầu hẹn hò: $formatted ($days ngày bên nhau) 💕'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _apiService.currentUser;
    final userName = user?.nickname.isNotEmpty == true ? user!.nickname : 'Bạn';
    final userAvatar = user?.avatar ?? (userName.isNotEmpty ? userName[0].toUpperCase() : 'B');

    final currentUid = user?.uid ?? '';
    final isConnected = _couple?.status == CoupleStatus.connected;

    // UID-based lookup: avoids self-match for invitee users
    final partnerParticipant = _couple != null && currentUid.isNotEmpty
        ? _couple!.participants.firstWhere(
            (p) => p.linkedUserId != currentUid,
            orElse: () => _couple!.participants.last,
          )
        : null;
    final partnerName = isConnected
        ? (partnerParticipant?.nickname ?? 'Người ấy')
        : 'Người ấy';
    final partnerAvatar = isConnected && partnerName.isNotEmpty
        ? partnerName[0].toUpperCase()
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 44, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Back Button
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Quay lại',
                      onPressed: widget.onBack,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isFromDashboard ? 'KẾT NỐI VỚI NGƯỜI ẤY' : 'BƯỚC 2/2 · CÙNG NHAU',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.stepLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Main Title
                Text(
                  'Hai tài khoản,\nmột thế giới nhỏ',
                  style: AppTypography.script(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                const Text(
                  'Kết nối với người ấy để Ourly có thể lên kế hoạch cho cả hai bạn.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Two Avatars Row (Symmetrically aligned and vertically centered with avatar circles)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User A Avatar column with fixed width for symmetrical balance
                    SizedBox(
                      width: 130,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OurlyAvatarView(
                            avatar: userAvatar,
                            size: 80,
                            backgroundColor: AppColors.avatarBlueBg,
                            textColor: AppColors.avatarBlueText,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$userName · bạn',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // Heart icon in center - exactly centered with 80px avatar circles
                    Container(
                      height: 80,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: const HeartbeatPulse(
                        minScale: 0.9,
                        maxScale: 1.18,
                        child: Text('💞', style: TextStyle(fontSize: 26)),
                      ),
                    ),

                    // Partner Placeholder Avatar column with matching width
                    SizedBox(
                      width: 130,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OurlyAvatarView(
                            isPlaceholder: !isConnected,
                            avatar: isConnected ? partnerAvatar : '',
                            size: 80,
                            backgroundColor: AppColors.avatarPinkBg,
                            textColor: AppColors.avatarPinkText,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isConnected ? '$partnerName · đã kết nối 💕' : 'Người ấy · chờ kết nối',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                              color: isConnected ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Card chọn ngày bắt đầu hẹn hò (Yêu cầu 2)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: AppShadows.card3D,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                                  'NGÀY BẮT ĐẦU HẸN HÒ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: AppColors.stepLabel,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Builder(
                                  builder: (context) {
                                    final datingStart = _apiService.getDatingStartDate();
                                    final daysTogether = _apiService.getDaysTogether();
                                    return Text(
                                      datingStart != null
                                          ? '${OurlyDatePicker.formatDate(datingStart)} · ($daysTogether ngày)'
                                          : 'Chưa thiết lập ngày hẹn hò',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: datingStart != null ? const Color(0xFF2C1914) : const Color(0xFF9E8E89),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          CuteBounceOnTap(
                            onTap: _pickDatingStartDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF1654C), Color(0xFFDD4B34)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE85A42).withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 5),
                                  Text(
                                    _apiService.hasDatingStartDate ? 'Đổi ngày' : 'Chọn ngày',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Cùng ghi dấu ngày hai bạn chính thức yêu nhau để Ourly đếm chuỗi ngày bên nhau và chuẩn bị những bất ngờ kỷ niệm ♡',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (isConnected) ...[
                  // Connected Celebration Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: AppShadows.card3D,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    child: Column(
                      children: [
                        const HeartbeatPulse(
                          minScale: 0.95,
                          maxScale: 1.15,
                          child: Text('🎉', style: TextStyle(fontSize: 42)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Hai bạn đã kết nối thành công!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Thế giới của $userName & $partnerName đã hòa làm một 💕\nHãy cùng nhau khám phá sở thích và lên những kế hoạch hẹn hò ngọt ngào nhất!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: widget.onEnterSpace,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Vào không gian của hai bạn 💖', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Couple Invite Link Card (3D Raised Container)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: AppShadows.card3D,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                    child: Column(
                      children: [
                        const Text(
                          'LIÊN KẾT MỜI NGƯỜI ẤY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.stepLabel,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Link display container (3D depth)
                        InkWell(
                          onTap: _copyInviteLink,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppShadows.input3D,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.link, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SelectableText(
                                    _inviteLink,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18, color: AppColors.textMuted),
                                  tooltip: 'Sao chép liên kết',
                                  onPressed: _copyInviteLink,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Text(
                          'Chia sẻ liên kết này với người ấy. Liên kết có hiệu lực trong 72 giờ.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 18),

                        const Text(
                          'HOẶC NHẬP LIÊN KẾT TỪ NGƯỜI ẤY',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.stepLabel,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ô nhập liên kết từ người ấy
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.input3D,
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.link_rounded, color: AppColors.primary, size: 20),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _acceptLinkController,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Dán liên kết mời từ người ấy...',
                                    hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.content_paste_rounded, size: 18, color: AppColors.textMuted),
                                tooltip: 'Dán từ bộ nhớ tạm',
                                onPressed: _pasteFromClipboard,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ElevatedButton(
                                  onPressed: _isConnecting ? null : _handleConnectPartnerLink,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isConnecting
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Text(
                                          'Kết nối',
                                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Privacy Note Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🔒', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Sở thích và ghi nhớ của mỗi người đều được giữ riêng tư. Ourly chỉ sử dụng điểm chung để gợi ý những khoảnh khắc tuyệt vời.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Button: "Tôi sẽ làm điều này sau" hoặc "Quay lại trang chủ" nếu mở từ Dashboard
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: widget.isFromDashboard ? widget.onBack : widget.onEnterSpace,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2EAE4).withValues(alpha: 0.6),
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Text(
                      widget.isFromDashboard ? 'Quay lại trang chủ' : 'Tôi sẽ làm điều này sau →',
                      style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
