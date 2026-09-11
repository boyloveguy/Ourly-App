import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/invite.dart';

class AcceptInviteDialog extends StatefulWidget {
  final VoidCallback onAccepted;

  const AcceptInviteDialog({super.key, required this.onAccepted});

  @override
  State<AcceptInviteDialog> createState() => _AcceptInviteDialogState();
}

class _AcceptInviteDialogState extends State<AcceptInviteDialog> {
  final _linkController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  InvitePreview? _preview;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_apiService.currentUser != null && _apiService.currentUser!.nickname.isNotEmpty && _apiService.currentUser!.nickname != 'User') {
      _nicknameController.text = _apiService.currentUser!.nickname;
    }
    if (_linkController.text.isNotEmpty) {
      _checkPreview();
    }
  }

  String _extractToken(String input) {
    input = input.trim();
    if (input.contains('/invite/')) {
      return input.split('/invite/').last.trim();
    }
    return input;
  }

  Future<void> _checkPreview() async {
    final token = _extractToken(_linkController.text);
    if (token.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prev = await _apiService.previewInvite(token);
      setState(() {
        _preview = prev;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _preview = null;
        _errorMessage = 'Liên kết mời không hợp lệ hoặc đã hết hạn.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAccept() async {
    final token = _extractToken(_linkController.text);
    final nickname = _nicknameController.text.trim();
    if (token.isEmpty || nickname.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final ok = await _apiService.acceptInvite(token: token, nickname: nickname);
      if (ok) {
        if (mounted) {
          Navigator.of(context).pop();
          widget.onAccepted();
        }
      } else {
        setState(() => _errorMessage = 'Không thể chấp nhận lời mời. Vui lòng thử lại.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Header
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                ),
                alignment: Alignment.center,
                child: const Text('💌', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(height: 14),

              const Text(
                'Tham gia không gian Ourly',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              if (_preview != null) ...[
                Text.rich(
                  TextSpan(
                    text: '${_preview!.inviterNickname} ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    children: const [
                      TextSpan(
                        text: 'đã gửi liên kết kết nối cùng bạn!',
                        style: TextStyle(fontWeight: FontWeight.normal, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 14),
              ],

              // Notice card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  '“Khi kết nối, hai bạn có thể xem những thông tin được chọn chia sẻ. Ghi chú riêng và kế hoạch bất ngờ vẫn được giữ riêng tư.”',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Link input
              TextField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: 'LIÊN KẾT MỜI',
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  hintText: 'https://ourly.app/invite/LV-8K2M',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _checkPreview,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Nickname input
              TextField(
                controller: _nicknameController,
                decoration: InputDecoration(
                  labelText: 'TÊN CỦA BẠN (BIỆT DANH)',
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                  hintText: 'Ví dụ: Mai, Lan, Hoàng...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Tham gia không gian 💕', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Để sau', style: TextStyle(color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
