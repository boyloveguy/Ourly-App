import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/romantic_effects.dart';

class OnboardingStep2Screen extends StatefulWidget {
  final VoidCallback onEnterSpace;
  final VoidCallback onBack;

  const OnboardingStep2Screen({
    super.key,
    required this.onEnterSpace,
    required this.onBack,
  });

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  final _apiService = ApiService();
  String _inviteCode = 'LV-8K2M';
  final _acceptLinkController = TextEditingController();
  bool _isConnecting = false;

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
      return input.split('/invite/').last.trim();
    }
    return input;
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
    final user = _apiService.currentUser;
    if (user?.activeCoupleId != null) {
      try {
        final inv = await _apiService.createInvite(user!.activeCoupleId!);
        if (mounted) {
          setState(() {
            _inviteCode = inv.token;
          });
        }
        return;
      } catch (_) {}
    }
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

  @override
  Widget build(BuildContext context) {
    final user = _apiService.currentUser;
    final userName = user?.nickname.isNotEmpty == true ? user!.nickname : 'Bạn';
    final userAvatar = user?.avatar ?? (userName.isNotEmpty ? userName[0].toUpperCase() : 'B');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    const Text(
                      'BƯỚC 2/2 · CÙNG NHAU',
                      style: TextStyle(
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
                    const SizedBox(
                      width: 130,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OurlyAvatarView(
                            isPlaceholder: true,
                            size: 80,
                            backgroundColor: AppColors.avatarPinkBg,
                            textColor: AppColors.avatarPinkText,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Người ấy · chờ kết nối',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

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

                // Button: "Tôi sẽ làm điều này sau" (đổi từ "Vào không gian của chúng mình →")
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: widget.onEnterSpace,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2EAE4).withValues(alpha: 0.6),
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'Tôi sẽ làm điều này sau →',
                      style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
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
