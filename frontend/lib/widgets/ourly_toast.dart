import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum OurlyToastType {
  love,
  success,
  error,
  info,
}

/// Hệ thống Toast UI hiện đại, bóng bẩy và sang trọng cho Ourly
class OurlyToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showLove(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Ngọt ngào 💕',
      type: OurlyToastType.love,
      icon: '💖',
      duration: duration,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Thành công ✨',
      type: OurlyToastType.success,
      icon: '✨',
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Lưu ý',
      type: OurlyToastType.error,
      icon: '💫',
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      title: title ?? 'Thông báo',
      type: OurlyToastType.info,
      icon: '💌',
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    OurlyToastType type = OurlyToastType.love,
    String icon = '✨',
    Duration duration = const Duration(seconds: 3),
  }) {
    // Ẩn toast cũ nếu đang hiển thị
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context, rootOverlay: true);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _OurlyToastWidget(
        message: message,
        title: title,
        type: type,
        icon: icon,
        onDismiss: () {
          _dismissTimer?.cancel();
          entry.remove();
          if (_currentEntry == entry) {
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}

class _OurlyToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final OurlyToastType type;
  final String icon;
  final VoidCallback onDismiss;

  const _OurlyToastWidget({
    required this.message,
    this.title,
    required this.type,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_OurlyToastWidget> createState() => _OurlyToastWidgetState();
}

class _OurlyToastWidgetState extends State<_OurlyToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Color _getPrimaryColor() {
    switch (widget.type) {
      case OurlyToastType.love:
        return const Color(0xFFE85A42);
      case OurlyToastType.success:
        return const Color(0xFF2E8B57);
      case OurlyToastType.error:
        return const Color(0xFFD9383A);
      case OurlyToastType.info:
        return const Color(0xFF6B4FA0);
    }
  }

  List<Color> _getGradientBackground() {
    switch (widget.type) {
      case OurlyToastType.love:
        return [
          const Color(0xFFFFF7F4),
          const Color(0xFFFFECE6),
        ];
      case OurlyToastType.success:
        return [
          const Color(0xFFF4FBF6),
          const Color(0xFFE6F7ED),
        ];
      case OurlyToastType.error:
        return [
          const Color(0xFFFFF5F5),
          const Color(0xFFFFEAEA),
        ];
      case OurlyToastType.info:
        return [
          const Color(0xFFF7F5FC),
          const Color(0xFFECE7F8),
        ];
    }
  }

  Color _getBorderColor() {
    switch (widget.type) {
      case OurlyToastType.love:
        return const Color(0xFFFFC7B5);
      case OurlyToastType.success:
        return const Color(0xFFA8E0BA);
      case OurlyToastType.error:
        return const Color(0xFFFFB3B3);
      case OurlyToastType.info:
        return const Color(0xFFD4C4F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final primaryColor = _getPrimaryColor();
    final borderColor = _getBorderColor();
    final bgGradients = _getGradientBackground();

    return Positioned(
      top: topPadding + 14,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onTap: _handleDismiss,
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -4) {
                  _handleDismiss();
                }
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: bgGradients,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderColor, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon tròn lấp lánh
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                widget.icon,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Nội dung
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (widget.title != null) ...[
                                    Text(
                                      widget.title!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    widget.message,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF2C1914),
                                      height: 1.35,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 6),
                            // Nút đóng nhỏ
                            GestureDetector(
                              onTap: _handleDismiss,
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Colors.black.withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
