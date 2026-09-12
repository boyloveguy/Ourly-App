import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/date_spot.dart';
import '../widgets/romantic_effects.dart';

class DatingPlaceDetailScreen extends StatefulWidget {
  final DateSpot spot;
  final bool isPicked;
  final String partnerName;
  final ValueChanged<bool> onPickChanged;

  const DatingPlaceDetailScreen({
    super.key,
    required this.spot,
    required this.isPicked,
    this.partnerName = 'Người ấy',
    required this.onPickChanged,
  });

  @override
  State<DatingPlaceDetailScreen> createState() => _DatingPlaceDetailScreenState();
}

class _DatingPlaceDetailScreenState extends State<DatingPlaceDetailScreen> {
  late bool _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.isPicked;
  }

  void _handlePickToggle() {
    setState(() {
      _picked = !_picked;
    });
    widget.onPickChanged(_picked);
    if (_picked) {
      LoveSparkleOverlay.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF5EE),
      body: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Image / Banner Header
                _buildHeroBanner(spot),

                // 2. Main Content Body
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Gallery (3 photos side by side)
                      _buildGalleryRow(spot),
                      const SizedBox(height: 16),

                      // Tags Row
                      _buildTagsRow(spot),
                      const SizedBox(height: 18),

                      // Location & Google Maps
                      _buildLocationSection(spot),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        spot.description.isNotEmpty
                            ? spot.description
                            : 'Không gian ấm cúng, riêng tư với ánh sáng dịu nhẹ và góc chụp hình kỉ niệm tuyệt đẹp cho hai bạn.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4A342D),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Menu tham khảo Card
                      _buildMenuCard(spot),
                      const SizedBox(height: 16),

                      // Expected Cost Summary
                      Row(
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          RichText(
                            text: TextSpan(
                              text: 'Chi phí dự kiến: ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4A342D),
                              ),
                              children: [
                                TextSpan(
                                  text: '~${spot.costDisplay == 'free' ? '0K (Miễn phí)' : spot.costDisplay}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2C1810),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Vì sao gợi ý này? (AI Reasoning Card)
                      _buildAiReasonCard(spot),
                      const SizedBox(height: 100), // Spacing for bottom button
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Top Navigation Floating Bar (Back & Fit %)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back Button
                CuteBounceOnTap(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: Color(0xFF2C1810),
                    ),
                  ),
                ),

                // Fit % Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFDED6)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE85A42).withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💖', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                      Text(
                        'Phù hợp ${spot.fitScore}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFD34830),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Button: "Chọn option này 💖"
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: CuteBounceOnTap(
              onTap: () {
                _handlePickToggle();
                Navigator.of(context).pop();
              },
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF1654C), Color(0xFFDD4B34)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE85A42).withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Text(
                      _picked ? 'Đã chọn option này 💖' : 'Chọn option này 💖',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _picked ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Hero Image / Banner
  Widget _buildHeroBanner(DateSpot spot) {
    return Stack(
      children: [
        // Image or fallback gradient
        Container(
          height: 270,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: spot.gradientColors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: spot.imageAsset.isNotEmpty
              ? Image.asset(
                  spot.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => spot.heroImageUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: spot.heroImageUrl, fit: BoxFit.cover)
                      : Center(child: Text(spot.iconEmoji, style: const TextStyle(fontSize: 60))),
                )
              : (spot.heroImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: spot.heroImageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: spot.gradientColors,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Text(spot.iconEmoji, style: const TextStyle(fontSize: 60)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(spot.iconEmoji, style: const TextStyle(fontSize: 60)),
                    )),
        ),

        // Dark gradient overlay for text readability
        Container(
          height: 270,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.65),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Category & Title inside banner (Bottom Left)
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spot.experienceType,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                spot.name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Photo Gallery (3 rounded photos side-by-side)
  Widget _buildGalleryRow(DateSpot spot) {
    final images = spot.galleryImages;
    if (images.isEmpty) return const SizedBox.shrink();

    return Row(
      children: List.generate(3, (index) {
        final imgUrl = index < images.length ? images[index] : images.first;
        final isAsset = imgUrl.startsWith('assets/');

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == 2 ? 0 : 4,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: isAsset
                    ? Image.asset(imgUrl, fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: const Color(0xFFF0E5DE),
                          child: Center(
                            child: Text(
                              index == 0 ? '📷' : (index == 1 ? '✨' : '🌸'),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // 3. Tags Row
  Widget _buildTagsRow(DateSpot spot) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: spot.tags.map((tag) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFDCD2)),
              ),
              child: Text(
                tag,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5A443E),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. Location & Google Maps
  Widget _buildLocationSection(DateSpot spot) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text('📍', style: TextStyle(fontSize: 18)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                spot.fullAddress.isNotEmpty
                    ? spot.fullAddress
                    : '${spot.area}, Đà Nẵng',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C1810),
                ),
              ),
              const SizedBox(height: 3),
              CuteBounceOnTap(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF2C1914),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      content: Text(
                        'Đang mở chỉ đường tới ${spot.name}... 🗺️',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Mở trên Google Maps →',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFE85A42),
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFFE85A42),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Menu tham khảo Card
  Widget _buildMenuCard(DateSpot spot) {
    final menuList = spot.menuItems.isNotEmpty
        ? spot.menuItems
        : [
            {'name': 'Gói trải nghiệm cho 2 người', 'price': spot.costDisplay},
            {'name': '+ Nước uống & tráng miệng', 'price': 'Miễn phí'},
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF3E7DF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
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
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFECE5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('☕', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Text(
                'MENU THAM KHẢO',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: const Color(0xFFE85A42),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF5ECE6), height: 1),
          const SizedBox(height: 12),
          ...menuList.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['name'] ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4A342D),
                      ),
                    ),
                  ),
                  Text(
                    item['price'] ?? '',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2C1810),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 6. Vì sao gợi ý này? (AI Reasoning Card)
  Widget _buildAiReasonCard(DateSpot spot) {
    final reasons = spot.aiReasons.isNotEmpty
        ? spot.aiReasons
        : [
            '${widget.partnerName} thích những activity có thể cùng làm và lưu lại kỷ niệm.',
            'Phù hợp với vibe cozy, sáng tạo và thích chụp ảnh.',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFE5DC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE85A42).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFECE5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('💖', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Text(
                'VÌ SAO GỢI Ý NÀY?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: const Color(0xFFE85A42),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...reasons.map((reason) {
            // Replace placeholder name if needed
            final formattedReason = reason.replaceAll('Người ấy', widget.partnerName);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECE5),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Color(0xFFE85A42),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      formattedReason,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4A342D),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
