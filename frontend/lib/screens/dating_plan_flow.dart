import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../models/date_spot.dart';
import '../data/mock_date_spots.dart';
import '../widgets/romantic_effects.dart';
import 'dating_place_detail_screen.dart';

/// Dating Plan Navigator Flow (Giao diện Lên kèo hẹn hò Tiếng Việt)
class DatingPlanFlow extends StatefulWidget {
  final List<String> initialPreferences;
  final String? partnerNickname;

  const DatingPlanFlow({
    super.key,
    this.initialPreferences = const [],
    this.partnerNickname,
  });

  @override
  State<DatingPlanFlow> createState() => _DatingPlanFlowState();
}

class _DatingPlanFlowState extends State<DatingPlanFlow> {
  int _currentScreenIndex = 0; // 0: Bối cảnh, 1: Loading, 2: Gợi ý quán, 3: Timeline

  // Lựa chọn của người dùng
  late DateOccasion _selectedOccasion;
  double _budgetAmount = 500000; // Mặc định 500K VND
  final Set<String> _selectedPreferences = {};
  final TextEditingController _customWishController = TextEditingController();

  // Kết quả AI
  List<DateSpot> _filteredSpots = [];
  final Set<String> _pickedSpotIds = {'spot-1', 'spot-2'}; // Mặc định chọn 2 quán

  @override
  void initState() {
    super.initState();
    _selectedOccasion = MockDateSpotsData.occasions.first;

    // Tải sở thích đã lưu của user
    if (widget.initialPreferences.isNotEmpty) {
      _selectedPreferences.addAll(widget.initialPreferences);
    } else {
      _selectedPreferences.addAll([
        '🍰 Thích đồ ngọt',
        '🌙 Nơi yên tĩnh',
        '📷 Thích chụp ảnh',
        '🌊 View biển',
      ]);
    }
  }

  @override
  void dispose() {
    _customWishController.dispose();
    super.dispose();
  }

  void _startAiSearch() {
    setState(() {
      _currentScreenIndex = 1; // Chuyển sang màn Loading
    });
  }

  void _onAiLoadingComplete() {
    final spots = MockDateSpotsData.filterAndRank(
      maxBudgetVnd: _budgetAmount.round(),
      occasionId: _selectedOccasion.id,
      selectedPreferences: _selectedPreferences,
      customWish: _customWishController.text,
    );

    setState(() {
      _filteredSpots = spots;
      if (_pickedSpotIds.isEmpty && spots.isNotEmpty) {
        _pickedSpotIds.add(spots.first.id);
        if (spots.length > 1) _pickedSpotIds.add(spots[1].id);
      }
      _currentScreenIndex = 2; // Chuyển sang màn Danh sách gợi ý
    });
  }

  void _togglePickSpot(String spotId) {
    setState(() {
      if (_pickedSpotIds.contains(spotId)) {
        _pickedSpotIds.remove(spotId);
      } else {
        _pickedSpotIds.add(spotId);
      }
    });
  }

  void _openSpotDetail(DateSpot spot, bool isPicked) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DatingPlaceDetailScreen(
          spot: spot,
          isPicked: isPicked,
          partnerName: widget.partnerNickname ?? 'Người ấy',
          onPickChanged: (picked) {
            setState(() {
              if (picked) {
                _pickedSpotIds.add(spot.id);
              } else {
                _pickedSpotIds.remove(spot.id);
              }
            });
          },
        ),
      ),
    );
  }

  void _createDatePlan() {
    if (_pickedSpotIds.isEmpty && _filteredSpots.isNotEmpty) {
      _pickedSpotIds.add(_filteredSpots.first.id);
    }
    setState(() {
      _currentScreenIndex = 3; // Chuyển sang màn Timeline
    });
  }

  void _goBack() {
    if (_currentScreenIndex > 0) {
      if (_currentScreenIndex == 2) {
        setState(() => _currentScreenIndex = 0);
      } else if (_currentScreenIndex == 3) {
        setState(() => _currentScreenIndex = 2);
      } else {
        setState(() => _currentScreenIndex--);
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentScreenIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF5EE),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildCurrentScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreenIndex) {
      case 0:
        return _buildContextScreen();
      case 1:
        return DatingAiLoadingScreen(
          onComplete: _onAiLoadingComplete,
          partnerNickname: widget.partnerNickname,
        );
      case 2:
        return _buildPlacesScreen();
      case 3:
        return _buildTimelineScreen();
      default:
        return _buildContextScreen();
    }
  }

  // ==========================================
  // MÀN HÌNH 2: BỐI CẢNH & THIẾT LẬP KÈO
  // ==========================================
  Widget _buildContextScreen() {
    final formatBudget = '${(_budgetAmount / 1000).round()}K';

    return Column(
      key: const ValueKey('ContextScreen'),
      children: [
        // Thanh trên cùng
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              CuteBounceOnTap(
                onTap: _goBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
              const Spacer(),
            ],
          ),
        ),

        // Thân màn hình cuộn
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nhãn danh mục
                Text(
                  'THÊM MỘT CHÚT THÔNG TIN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.6,
                    color: const Color(0xFFB87860),
                  ),
                ),
                const SizedBox(height: 6),
                // Tiêu đề
                Text(
                  _selectedOccasion.titlePrompt,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2C1810),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Phần 1: Dịp hẹn hò
                Text(
                  'Dịp hẹn hò của hai bạn?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C1810),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: MockDateSpotsData.occasions.map((occ) {
                      final isSelected = occ.id == _selectedOccasion.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: CuteBounceOnTap(
                          onTap: () {
                            setState(() => _selectedOccasion = occ);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFECE5) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFFB29D) : const Color(0xFFF1E6DF),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFE85A42).withValues(alpha: 0.18),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(occ.emoji, style: const TextStyle(fontSize: 18)),
                                const SizedBox(height: 6),
                                Text(
                                  occ.label,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? const Color(0xFFD34830) : const Color(0xFF5A4943),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Phần 2: Tài chính hiện có
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF3E7DF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE85A42).withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bạn dự định chi bao nhiêu?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3B2720),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            formatBudget,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFE85A42),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'VND',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFA28D85),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFFE85A42),
                          inactiveTrackColor: const Color(0xFFF3E5DD),
                          thumbColor: const Color(0xFFE85A42),
                          overlayColor: const Color(0xFFE85A42).withValues(alpha: 0.15),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10,
                            elevation: 4,
                          ),
                        ),
                        child: Slider(
                          value: _budgetAmount,
                          min: 100000,
                          max: 2500000,
                          divisions: 24,
                          onChanged: (val) {
                            setState(() => _budgetAmount = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Phần 3: Sở thích & Điều cần biết
                Text(
                  'Điều gì mình nên biết trước?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C1810),
                  ),
                ),
                const SizedBox(height: 12),

                // Thẻ sở thích dạng chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MockDateSpotsData.defaultPreferenceTags.map((tag) {
                    final isSelected = _selectedPreferences.contains(tag);
                    return CuteBounceOnTap(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedPreferences.remove(tag);
                          } else {
                            _selectedPreferences.add(tag);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFECE5) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFB4A2) : const Color(0xFFF1E6E0),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? const Color(0xFFE85A42).withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? const Color(0xFFD34830) : const Color(0xFF53413B),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Ô nhập mong muốn thêm của người dùng
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1E6DF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _customWishController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF2C1810),
                    ),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Nhập thêm mong muốn (ví dụ: muốn quán có rooftop lãng mạn, nhạc acoustic, không ăn cay...)',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFFA5928B),
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('💭', style: TextStyle(fontSize: 18)),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Card nhắc nhở từ AI
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF7EF), Color(0xFFFCEDF4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFFE2D7)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '✦',
                        style: TextStyle(fontSize: 18, color: Color(0xFF2C1810)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ourly AI đã ghi nhớ sở thích của hai bạn. Bạn không cần phải chọn lại những gì đã lưu nhé.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B554E),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Nút tìm kiếm lớn
                CuteBounceOnTap(
                  onTap: _startAiSearch,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF1654C), Color(0xFFDD4B34)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE85A42).withValues(alpha: 0.38),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Tìm địa điểm cho tụi mình 💖',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MÀN HÌNH 4: DANH SÁCH GỢI Ý ĐỊA ĐIỂM
  // ==========================================
  Widget _buildPlacesScreen() {
    final pickedCount = _pickedSpotIds.length;

    return Column(
      key: const ValueKey('PlacesScreen'),
      children: [
        // Thanh trên cùng
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              CuteBounceOnTap(
                onTap: _goBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
              const Spacer(),
              // Icon chuyển chế độ xem
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.view_agenda_rounded, size: 18, color: Color(0xFFE85A42)),
                    SizedBox(width: 10),
                    Icon(Icons.map_outlined, size: 18, color: Color(0xFF9E8780)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Dòng phụ đề số quán đã chọn
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$pickedCount địa điểm đã chọn · Chọn bao nhiêu tùy thích, AI sẽ kết nối thành một buổi hẹn trọn vẹn',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7A645D),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Danh sách quán gợi ý
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _filteredSpots.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final spot = _filteredSpots[index];
              final isPicked = _pickedSpotIds.contains(spot.id);

              return _buildSpotCard(spot, isPicked);
            },
          ),
        ),

        // Nút ở cuối màn hình: "Tạo buổi hẹn từ các điểm này"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFCF5EE).withValues(alpha: 0.95),
            border: const Border(top: BorderSide(color: Color(0xFFF3E7DF))),
          ),
          child: CuteBounceOnTap(
            onTap: _createDatePlan,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF1654C), Color(0xFFDD4B34)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE85A42).withValues(alpha: 0.38),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'Tạo buổi hẹn từ các điểm này 💖 · $pickedCount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpotCard(DateSpot spot, bool isPicked) {
    return CuteBounceOnTap(
      onTap: () => _openSpotDetail(spot, isPicked),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isPicked ? const Color(0xFFF4644B) : const Color(0xFFF1E6DF),
            width: isPicked ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isPicked
                  ? const Color(0xFFE85A42).withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner ảnh thumbnail kết hợp gradient hoàng hôn
            Container(
              height: 155,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: spot.gradientColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Ảnh thumbnail thực tế của quán
                  if (spot.heroImageUrl.isNotEmpty)
                    CachedNetworkImage(
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
                          child: Text(spot.iconEmoji, style: const TextStyle(fontSize: 48)),
                        ),
                      ),
                    ),

                  // Lớp phủ Gradient tối màu để text luôn rõ nét và nổi bật
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Nội dung thông tin trên banner
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Hàng trên: Phân loại & Phù hợp %
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                spot.category,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '✦ Phù hợp ${spot.fitScore}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2C1810),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Tên quán & Thông tin
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${spot.area} · ${spot.costDisplay} · ${spot.distance}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.95),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Phần dưới: Tags & Nút Chọn
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Thẻ tag
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: spot.tags.map((tag) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF6F3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFECE5)),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5A443E),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút Chọn / Đã chọn
                  CuteBounceOnTap(
                    onTap: () => _togglePickSpot(spot.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: isPicked ? const Color(0xFFE85A42) : const Color(0xFFFFF5F1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPicked ? const Color(0xFFE85A42) : const Color(0xFFFFDED3),
                        ),
                        boxShadow: isPicked
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFE85A42).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isPicked ? '✓ Đã chọn' : '+ Chọn',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: isPicked ? Colors.white : const Color(0xFFE85A42),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MÀN HÌNH 5: TIMELINE LỘ TRÌNH HẸN HÒ
  // ==========================================
  Widget _buildTimelineScreen() {
    final pickedSpots = _filteredSpots.where((s) => _pickedSpotIds.contains(s.id)).toList();
    if (pickedSpots.isEmpty && _filteredSpots.isNotEmpty) {
      pickedSpots.add(_filteredSpots.first);
    }

    // Xây dựng các bước timeline
    final timelineSteps = <DateTimelineStep>[];
    for (int i = 0; i < pickedSpots.length; i++) {
      final s = pickedSpots[i];
      Color nodeColor = const Color(0xFFFFE7DD);
      if (i == 1) nodeColor = const Color(0xFFFFDFE8);
      if (i >= 2) nodeColor = const Color(0xFFDBECF8);

      timelineSteps.add(DateTimelineStep(
        iconEmoji: s.iconEmoji,
        timeLabel: s.timeSlotLabel,
        title: s.activityTitle,
        description: s.aiNote,
        nodeBgColor: nodeColor,
      ));
    }

    // Bước bí mật ngọt ngào
    timelineSteps.add(const DateTimelineStep(
      iconEmoji: '💌',
      timeLabel: 'BẤT CỨ LÚC NÀO TRƯỚC KHI GẶP NGƯỜI ẤY',
      title: 'Bí mật ngọt ngào',
      description: 'Hoa Tulip — người ấy sẽ bất ngờ vì bạn vẫn nhớ sở thích này.',
      nodeBgColor: Color(0xFFFFE0E8),
    ));

    // Tính toán chi phí
    int totalCost = 0;
    for (final s in pickedSpots) {
      totalCost += s.cost;
    }
    if (totalCost == 0) totalCost = 480000;
    final totalCostK = '${(totalCost / 1000).round()}K';

    return Column(
      key: const ValueKey('TimelineScreen'),
      children: [
        // Thanh trên cùng
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              CuteBounceOnTap(
                onTap: _goBack,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
              const Spacer(),
            ],
          ),
        ),

        // Nội dung timeline cuộn
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dòng giới thiệu mở đầu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Không cần xem đồng hồ. Cứ thong thả tận hưởng từng khoảnh khắc theo cách tự nhiên nhất.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A645D),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Trục Timeline dọc
                Stack(
                  children: [
                    // Đường kẻ nối các điểm
                    Positioned(
                      left: 23,
                      top: 24,
                      bottom: 40,
                      child: Container(
                        width: 2.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFB5A0).withValues(alpha: 0.8),
                              const Color(0xFFD3A4CF).withValues(alpha: 0.6),
                              const Color(0xFFA0C6E8).withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Cột các bước
                    Column(
                      children: timelineSteps.map((step) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon tròn node
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: step.nodeBgColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE85A42).withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(step.iconEmoji, style: const TextStyle(fontSize: 20)),
                              ),
                              const SizedBox(width: 14),

                              // Thẻ nội dung
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: const Color(0xFFF4E8E1)),
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
                                      Text(
                                        step.timeLabel,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 0.8,
                                          color: const Color(0xFFB87860),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        step.title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2C1810),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        step.description,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF6B554E),
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Thẻ bí mật: BẬT MÍ NHỎ DÀNH RIÊNG CHO BẠN
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFF4EB), Color(0xFFFCEDF4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFDFC9)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE85A42).withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Text(
                          '💌',
                          style: TextStyle(
                            fontSize: 48,
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BẬT MÍ NHỎ DÀNH RIÊNG CHO BẠN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: const Color(0xFFB87860),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mang theo loài hoa người ấy thích.',
                            style: AppTypography.script(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2C1810),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hoa Tulip. Người ấy từng chụp ảnh hoa này vào mùa xuân năm ngoái.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B554E),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Dự toán ngân sách
                Center(
                  child: Text(
                    'khoảng $totalCostK, trọn vẹn từng khoảnh khắc',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9E847C),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nút hoàn tất & Nút tim
                Row(
                  children: [
                    Expanded(
                      child: CuteBounceOnTap(
                        onTap: () {
                          LoveSparkleOverlay.show(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF2C1914),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              content: const Row(
                                children: [
                                  Text('💖', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Buổi hẹn đã được lên kế hoạch hoàn hảo! Chúc hai bạn có những khoảnh khắc ngọt ngào.',
                                      style: TextStyle(color: Colors.white, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF1654C), Color(0xFFDD4B34)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE85A42).withValues(alpha: 0.38),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Lưu buổi hẹn hoàn hảo 💖',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Nút Bookmark trái tim
                    CuteBounceOnTap(
                      onTap: () {
                        LoveSparkleOverlay.show(context);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFF1E6DF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          size: 24,
                          color: Color(0xFFB87860),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================
// MÀN HÌNH 3: AI LOADING
// ==========================================
class DatingAiLoadingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final String? partnerNickname;

  const DatingAiLoadingScreen({
    super.key,
    required this.onComplete,
    this.partnerNickname,
  });

  @override
  State<DatingAiLoadingScreen> createState() => _DatingAiLoadingScreenState();
}

class _DatingAiLoadingScreenState extends State<DatingAiLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _timer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (widget.partnerNickname != null && widget.partnerNickname!.isNotEmpty)
        ? widget.partnerNickname!
        : "người ấy";

    return Container(
      key: const ValueKey('AiLoadingScreen'),
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFDF5EF), Color(0xFFFCEAE4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Vòng tròn phát sáng nhịp nhàng với ngôi sao 4 cánh
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final scale = 1.0 + _animController.value * 0.12;
              final glowOpacity = 0.2 + _animController.value * 0.25;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF6D6E8),
                        const Color(0xFFFFD4C8).withValues(alpha: glowOpacity),
                        Colors.transparent,
                      ],
                      stops: const [0.3, 0.7, 1.0],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFE0EB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE85A42).withValues(alpha: 0.18),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '✦',
                      style: TextStyle(
                        fontSize: 32,
                        color: Color(0xFF2C1810),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 38),

          // Thông điệp AI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Hmm... Mình biết chính xác $displayName sẽ thích gì rồi ✨',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2C1810),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3 chấm nhảy nhịp nhàng
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE85A42),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(0.7, 0.7),
                      end: const Offset(1.4, 1.4),
                      duration: const Duration(milliseconds: 600),
                      delay: Duration(milliseconds: i * 200),
                    )
                    .fadeIn(duration: const Duration(milliseconds: 300)),
              );
            }),
          ),
          const SizedBox(height: 28),

          // Thanh tiến trình
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB5A0)),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
