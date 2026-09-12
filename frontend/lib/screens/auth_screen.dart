import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../widgets/romantic_effects.dart';

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthScreen({super.key, required this.onAuthenticated});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  final _apiService = ApiService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth({String? email, String? password}) async {
    final targetEmail = (email ?? _emailController.text).trim();
    final targetPassword = (password ?? _passwordController.text).trim();
    final targetNickname = _nicknameController.text.trim();

    if (targetEmail.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập địa chỉ email.';
      });
      return;
    }

    // Email regex validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(targetEmail)) {
      setState(() {
        _errorMessage = 'Địa chỉ email không đúng định dạng (ví dụ: name@email.com).';
      });
      return;
    }

    if (targetPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng nhập mật khẩu.';
      });
      return;
    }

    if (targetPassword.length < 6) {
      setState(() {
        _errorMessage = 'Mật khẩu phải có ít nhất 6 ký tự.';
      });
      return;
    }

    // Confirm password check when registering
    if (!_isLogin) {
      final targetConfirm = _confirmPasswordController.text.trim();
      if (targetConfirm.isEmpty) {
        setState(() {
          _errorMessage = 'Vui lòng xác nhận lại mật khẩu.';
        });
        return;
      }
      if (targetPassword != targetConfirm) {
        setState(() {
          _errorMessage = 'Mật khẩu xác nhận không trùng khớp. Vui lòng kiểm tra lại.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await _apiService.login(
          email: targetEmail,
          password: targetPassword,
        );
      } else {
        await _apiService.register(
          email: targetEmail,
          password: targetPassword,
          nickname: targetNickname.isNotEmpty ? targetNickname : null,
        );
      }
      widget.onAuthenticated();
    } catch (e) {
      String message = _isLogin ? 'Đăng nhập không thành công.' : 'Đăng ký không thành công.';
      if (e is DioException) {
        if (e.response != null && e.response!.data != null) {
          final data = e.response!.data;
          if (data is Map) {
            if (data['error'] != null && data['error'] is Map) {
              final errMap = data['error'] as Map;
              message = (errMap['message'] ?? errMap['detail'] ?? message).toString();
            } else if (data['detail'] != null) {
              message = data['detail'].toString();
            }
          }
        } else if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
          message = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại kết nối mạng.';
        }
      }
      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FloatingHeartsBackground(
        count: 16,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28.0, 28.0, 28.0, 20.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // Glowing Center Orb & 3D Heart Logo (Matching reference)
                    HeartbeatPulse(
                      minScale: 0.96,
                      maxScale: 1.06,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Soft circular glowing aura as in reference image 2
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF090A0).withValues(alpha: 0.20),
                                  blurRadius: 32,
                                  spreadRadius: 8,
                                ),
                                BoxShadow(
                                  color: const Color(0xFFFCE6EE).withValues(alpha: 0.85),
                                  blurRadius: 18,
                                  spreadRadius: 4,
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  offset: Offset(-1.5, -1.5),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                ),
                              ],
                              gradient: const RadialGradient(
                                colors: [Color(0xFFF9E8EE), Color(0xFFF3D9E2)],
                              ),
                            ),
                          ),
                          // 3D Tactile Heart Logo
                          Image.asset(
                            'assets/images/heart_3d.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text('❤️', style: TextStyle(fontSize: 40)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                  // App Title
                  Text(
                    'Ourly',
                    style: AppTypography.script(
                      fontSize: 54,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 10),

                  // Tagline
                  Text(
                    "Chúng tôi không yêu thay bạn.\nChúng tôi giúp bạn yêu tốt hơn.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                  const SizedBox(height: 36),

                  // Optional Nickname when Registering (3D Raised Container)
                  if (!_isLogin) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: AppShadows.input3D,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TÊN BẠN HOẶC BIỆT DANH (TÙY CHỌN)',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                          TextField(
                            controller: _nicknameController,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.only(top: 4, bottom: 2),
                              border: InputBorder.none,
                              hintText: 'VD: Cún con, Bé iu...',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted.withValues(alpha: 0.45),
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Input: Email (3D Raised Container)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: AppShadows.input3D,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ĐỊA CHỈ EMAIL',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.textMuted,
                          ),
                        ),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.only(top: 4, bottom: 2),
                            border: InputBorder.none,
                            hintText: 'email@ourly.app',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.45),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input: Password (3D Raised Container with Show/Hide toggle)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: AppShadows.input3D,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isLogin ? 'MẬT KHẨU' : 'MẬT KHẨU (TỐI THIỂU 6 KÝ TỰ)',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                onSubmitted: (_) => _handleAuth(),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.only(top: 4, bottom: 2),
                                  border: InputBorder.none,
                                  hintText: _isLogin ? 'Nhập mật khẩu' : 'Mật khẩu từ 6 ký tự trở lên',
                                  hintStyle: TextStyle(
                                    color: AppColors.textMuted.withValues(alpha: 0.45),
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            CuteBounceOnTap(
                              onTap: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6.0),
                                child: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: _obscurePassword ? AppColors.textMuted : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Input: Confirm Password (Only when Registering)
                  if (!_isLogin) ...[
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: AppShadows.input3D,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'XÁC NHẬN MẬT KHẨU',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  onSubmitted: (_) => _handleAuth(),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.only(top: 4, bottom: 2),
                                    border: InputBorder.none,
                                    hintText: 'Nhập lại mật khẩu vừa đặt',
                                    hintStyle: TextStyle(
                                      color: AppColors.textMuted.withValues(alpha: 0.45),
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              CuteBounceOnTap(
                                onTap: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 6.0),
                                  child: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 20,
                                    color: _obscureConfirmPassword ? AppColors.textMuted : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 20, color: Color(0xFFD32F2F)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Continue Button with 3D Embossed Depth & Cute Bounce
                  CuteBounceOnTap(
                    onTap: _isLoading ? null : () => _handleAuth(),
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6D55), Color(0xFFE85A42)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                        boxShadow: AppShadows.button3D,
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isLogin ? 'Đăng nhập vào Ourly' : 'Đăng ký & Bắt đầu yêu',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('💘', style: TextStyle(fontSize: 16)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle Login/Register
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                        _confirmPasswordController.clear();
                      });
                    },
                    child: Text.rich(
                      TextSpan(
                        text: _isLogin ? "Bạn mới dùng Ourly? " : "Đã có tài khoản? ",
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        children: [
                          TextSpan(
                            text: _isLogin ? 'Tạo tài khoản mới' : 'Đăng nhập ngay',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
    ),
  );
}
}
