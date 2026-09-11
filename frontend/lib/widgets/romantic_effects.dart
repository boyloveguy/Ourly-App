import 'dart:math' as math;
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

/// 1. Floating Romantic Petals & Hearts Background
class FloatingHeartsBackground extends StatefulWidget {
  final Widget child;
  final int count;
  final bool enabled;

  const FloatingHeartsBackground({
    super.key,
    required this.child,
    this.count = 14,
    this.enabled = true,
  });

  @override
  State<FloatingHeartsBackground> createState() => _FloatingHeartsBackgroundState();
}

class _FloatingHeartsBackgroundState extends State<FloatingHeartsBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  final List<String> _emojis = ['🌸', '💖', '✨', '💕', '🌷', '💌', '🤍'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < widget.count; i++) {
      _particles.add(_generateParticle(initial: true));
    }
  }

  _Particle _generateParticle({bool initial = false}) {
    return _Particle(
      x: _random.nextDouble(),
      y: initial ? _random.nextDouble() : 1.1 + _random.nextDouble() * 0.2,
      speed: 0.04 + _random.nextDouble() * 0.05,
      scale: 0.6 + _random.nextDouble() * 0.7,
      rotation: _random.nextDouble() * 2 * math.pi,
      rotationSpeed: (_random.nextDouble() - 0.5) * 0.02,
      driftFreq: 1.0 + _random.nextDouble() * 2.0,
      driftAmp: 0.02 + _random.nextDouble() * 0.03,
      opacity: 0.25 + _random.nextDouble() * 0.45,
      emoji: _emojis[_random.nextInt(_emojis.length)],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Stack(
      children: [
        // Background particles
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(particles: _particles, dt: 0.016),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double speed;
  double scale;
  double rotation;
  double rotationSpeed;
  double driftFreq;
  double driftAmp;
  double opacity;
  String emoji;

  _Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.scale,
    required this.rotation,
    required this.rotationSpeed,
    required this.driftFreq,
    required this.driftAmp,
    required this.opacity,
    required this.emoji,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double dt;

  _ParticlePainter({required this.particles, required this.dt});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    for (final p in particles) {
      p.y -= p.speed * dt;
      p.rotation += p.rotationSpeed;
      final waveX = p.x + math.sin(p.y * p.driftFreq * 6.28) * p.driftAmp;

      if (p.y < -0.1) {
        p.y = 1.1;
        p.x = math.Random().nextDouble();
      }

      final textSpan = TextSpan(
        text: p.emoji,
        style: TextStyle(
          fontSize: 16 * p.scale,
          color: Colors.white.withValues(alpha: p.opacity),
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final renderX = waveX * size.width;
      final renderY = p.y * size.height;

      canvas.save();
      canvas.translate(renderX, renderY);
      canvas.rotate(p.rotation);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

/// 2. Heartbeat Pulsing Animation (lub-dub rhythm)
class HeartbeatPulse extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const HeartbeatPulse({
    super.key,
    required this.child,
    this.minScale = 0.95,
    this.maxScale = 1.14,
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<HeartbeatPulse> createState() => _HeartbeatPulseState();
}

class _HeartbeatPulseState extends State<HeartbeatPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();

    // Double beat pulse simulation
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.minScale, end: widget.maxScale)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.maxScale, end: widget.minScale + 0.03)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.minScale + 0.03, end: widget.maxScale * 1.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.maxScale * 1.05, end: widget.minScale)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(widget.minScale),
        weight: 30, // Resting pause between heartbeats
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

/// 3. Interactive Love Sparkle Burst (Tap to fly hearts upwards!)
class LoveSparkleOverlay {
  static void show(BuildContext context, {Offset? origin}) {
    final overlayState = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final targetPos = origin ?? (renderBox != null
        ? renderBox.localToGlobal(Offset(renderBox.size.width / 2, renderBox.size.height / 2))
        : const Offset(200, 400));

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _LoveBurstWidget(
        origin: targetPos,
        onComplete: () => entry.remove(),
      ),
    );
    overlayState.insert(entry);
  }
}

class _LoveBurstWidget extends StatefulWidget {
  final Offset origin;
  final VoidCallback onComplete;

  const _LoveBurstWidget({required this.origin, required this.onComplete});

  @override
  State<_LoveBurstWidget> createState() => _LoveBurstWidgetState();
}

class _LoveBurstWidgetState extends State<_LoveBurstWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_BurstItem> _items = [];
  final math.Random _random = math.Random();
  final List<String> _loveIcons = ['💖', '💕', '💘', '🌸', '✨', '💐', '🥰'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward().then((_) => widget.onComplete());

    for (int i = 0; i < 16; i++) {
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * 1.4;
      final speed = 120 + _random.nextDouble() * 200;
      _items.add(
        _BurstItem(
          icon: _loveIcons[_random.nextInt(_loveIcons.length)],
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: 16 + _random.nextDouble() * 18,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final opacity = (1.0 - t).clamp(0.0, 1.0);

          return Stack(
            children: _items.map((item) {
              final x = widget.origin.dx + item.vx * t;
              final y = widget.origin.dy + item.vy * t + 80 * t * t; // gentle gravity
              return Positioned(
                left: x - item.size / 2,
                top: y - item.size / 2,
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: 0.8 + 0.5 * math.sin(t * math.pi),
                    child: Text(
                      item.icon,
                      style: TextStyle(fontSize: item.size),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _BurstItem {
  final String icon;
  final double vx;
  final double vy;
  final double size;

  _BurstItem({
    required this.icon,
    required this.vx,
    required this.vy,
    required this.size,
  });
}

/// 4. Cute Bouncing Typing Hearts for Chatbot
class CuteBouncingHeartsIndicator extends StatefulWidget {
  const CuteBouncingHeartsIndicator({super.key});

  @override
  State<CuteBouncingHeartsIndicator> createState() => _CuteBouncingHeartsIndicatorState();
}

class _CuteBouncingHeartsIndicatorState extends State<CuteBouncingHeartsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeart(0, '💖'),
            const SizedBox(width: 6),
            _buildHeart(1, '💕'),
            const SizedBox(width: 6),
            _buildHeart(2, '🌸'),
          ],
        );
      },
    );
  }

  Widget _buildHeart(int index, String emoji) {
    final progress = (_controller.value - index * 0.2) % 1.0;
    final bounce = math.sin(progress * math.pi).clamp(0.0, 1.0);
    final offsetY = -8.0 * bounce;
    final scale = 0.85 + 0.3 * bounce;

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        child: Text(emoji, style: const TextStyle(fontSize: 15)),
      ),
    );
  }
}

/// 5. Animated Romantic Voice Waveform Bars
class AnimatedRomanticWaveform extends StatefulWidget {
  final bool isSpeaking;
  final Color color;

  const AnimatedRomanticWaveform({
    super.key,
    required this.isSpeaking,
    this.color = AppColors.primary,
  });

  @override
  State<AnimatedRomanticWaveform> createState() => _AnimatedRomanticWaveformState();
}

class _AnimatedRomanticWaveformState extends State<AnimatedRomanticWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isSpeaking) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant AnimatedRomanticWaveform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _controller.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _controller.stop();
      _controller.animateTo(0.3);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(5, (index) {
            final wave = widget.isSpeaking
                ? (0.3 + 0.7 * math.sin((t + index * 0.25) * math.pi).abs())
                : 0.3;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.8),
              width: 3.5,
              height: 18 * wave,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

/// 6. Cute Bouncy Interactive Wrapper for Cards & Buttons
class CuteBounceOnTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const CuteBounceOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
  });

  @override
  State<CuteBounceOnTap> createState() => _CuteBounceOnTapState();
}

class _CuteBounceOnTapState extends State<CuteBounceOnTap> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? widget.scaleDown : (_isHovered ? 1.02 : 1.0);

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.onTap != null ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutQuad,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 7. Frosted Glass Box (Làm mờ nền kính)
class FrostedGlassBox extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Border? border;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;

  const FrostedGlassBox({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.65,
    this.borderRadius,
    this.border,
    this.color,
    this.padding,
    this.margin,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(20);
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withValues(alpha: opacity),
              borderRadius: br,
              border: border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 8. Device Avatar Picker Helper (Chọn ảnh trực tiếp từ máy tính / thiết bị / thư viện)
class AvatarPickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAvatarFromDevice() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final ext = file.name.split('.').last.toLowerCase();
          final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
          final base64Str = base64Encode(bytes);
          final dataUri = 'data:$mime;base64,$base64Str';

          try {
            final cloudUrl = await ApiService().uploadAvatar(dataUri);
            if (cloudUrl != null && cloudUrl.isNotEmpty && cloudUrl.startsWith('http')) {
              return cloudUrl;
            }
          } catch (e) {
            debugPrint('Cloud upload fallback: $e');
          }
          return dataUri;
        }
      }
    } catch (e) {
      debugPrint('AvatarPickerHelper error: $e');
    }

    return null;
  }
}

/// 9. Universal Ourly Avatar with Frosted Blur Placeholder & Device Image Support
class OurlyAvatarView extends StatelessWidget {
  final String? avatar;
  final String fallbackText;
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final bool isPlaceholder;
  final VoidCallback? onTap;

  const OurlyAvatarView({
    super.key,
    this.avatar,
    this.fallbackText = 'U',
    this.size = 40,
    this.backgroundColor = AppColors.avatarBlueBg,
    this.textColor = AppColors.avatarBlueText,
    this.isPlaceholder = false,
    this.onTap,
  });

  /// Check if a string is an emoji
  static bool isEmoji(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) return false;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('data:image')) {
      return false;
    }
    for (final rune in trimmed.runes) {
      if ((rune >= 0x1F300 && rune <= 0x1FAFF) ||
          (rune >= 0x1F600 && rune <= 0x1F64F) ||
          (rune >= 0x2600 && rune <= 0x27BF) ||
          (rune >= 0x2B50 && rune <= 0x2B55) ||
          (rune >= 0x2300 && rune <= 0x23FF) ||
          (rune >= 0xFE00 && rune <= 0xFE0F)) {
        return true;
      }
    }
    return false;
  }

  /// Extracts strictly the first letter/character (chữ cái đầu tiên) of nickname or text
  static String getInitialLetter(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'U';
    final it = trimmed.characters.iterator;
    if (it.moveNext()) {
      return it.current.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (isPlaceholder) {
      return GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor.withValues(alpha: 0.4),
                border: Border.all(
                  color: textColor.withValues(alpha: 0.35),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '?',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontStyle: FontStyle.italic,
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final trimmedAvatar = avatar?.trim() ?? '';
    final hasCustomAvatar = trimmedAvatar.isNotEmpty;

    // Check if base64 data URI
    Uint8List? imageBytes;
    if (hasCustomAvatar && trimmedAvatar.startsWith('data:image')) {
      try {
        final commaIndex = trimmedAvatar.indexOf(',');
        if (commaIndex != -1) {
          imageBytes = base64Decode(trimmedAvatar.substring(commaIndex + 1));
        }
      } catch (_) {}
    }

    Widget content;
    if (imageBytes != null) {
      content = Image.memory(
        imageBytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (hasCustomAvatar && (trimmedAvatar.startsWith('http://') || trimmedAvatar.startsWith('https://'))) {
      content = CachedNetworkImage(
        imageUrl: trimmedAvatar,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: backgroundColor.withValues(alpha: 0.3),
          child: Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => _buildInitialLetter(getInitialLetter(fallbackText)),
      );
    } else if (hasCustomAvatar && isEmoji(trimmedAvatar)) {
      content = Center(
        child: Text(
          trimmedAvatar,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: size * 0.52),
        ),
      );
    } else {
      // User hasn't chosen an avatar or has chosen a single initial letter.
      // ALWAYS display strictly the first initial letter of user's nickname!
      final letterSource = (hasCustomAvatar && trimmedAvatar.characters.length == 1)
          ? trimmedAvatar
          : fallbackText;
      content = _buildInitialLetter(getInitialLetter(letterSource));
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: content,
      ),
    );
  }

  Widget _buildInitialLetter(String letter) {
    return Center(
      child: Text(
        letter,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'serif',
          fontStyle: FontStyle.italic,
          fontSize: size * 0.46,
          fontWeight: FontWeight.bold,
          color: textColor,
          height: 1.0,
        ),
      ),
    );
  }
}

/// 10. Animated Waving Cupid Mascot Widget (Quân sư tình yêu Ourly)
class WavingCupidWidget extends StatefulWidget {
  final double size;
  final bool animate;
  final VoidCallback? onTap;

  const WavingCupidWidget({
    super.key,
    this.size = 48,
    this.animate = true,
    this.onTap,
  });

  @override
  State<WavingCupidWidget> createState() => _WavingCupidWidgetState();
}

class _WavingCupidWidgetState extends State<WavingCupidWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _rotation = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _float = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Image.asset(
      'assets/images/cupid.png',
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
    );

    if (widget.animate) {
      content = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _float.value),
            child: Transform.rotate(
              angle: _rotation.value,
              alignment: const Alignment(0.1, 0.4),
              child: child,
            ),
          );
        },
        child: content,
      );
    }

    if (widget.onTap != null) {
      content = GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }

    return content;
  }
}


