import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';
import '../models/date_spot.dart';
import '../widgets/romantic_effects.dart';
import 'dating_plan_detail_view_screen.dart';
import 'dating_plan_flow.dart';

class DatingHistoryScreen extends StatefulWidget {
  const DatingHistoryScreen({super.key});

  @override
  State<DatingHistoryScreen> createState() => _DatingHistoryScreenState();
}

class _DatingHistoryScreenState extends State<DatingHistoryScreen> {
  final ApiService _apiService = ApiService();
  late List<DatingPlanHistoryItem> _history;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _history = _apiService.getDatePlanHistory();
    });
  }

  void _openDetail(DatingPlanHistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DatingPlanDetailViewScreen(plan: item),
      ),
    );
  }

  void _createNewPlan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DatingPlanFlow(),
      ),
    ).then((_) => _loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final count = _history.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF4EE),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: Row(
                children: [
                  CuteBounceOnTap(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KHÔNG GIAN CỦA CHÚNG MÌNH',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Color(0xFFE85A42),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lịch sử buổi hẹn',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2C1810),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECE5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$count buổi hẹn',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE85A42),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Body
            Expanded(
              child: _history.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🗺️✨', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có buổi hẹn nào được lưu',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2C1810),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy cùng lên kế hoạch cho buổi hẹn đầu tiên ngọt ngào của hai bạn nhé!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF7A645D),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            CuteBounceOnTap(
                              onTap: _createNewPlan,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFF1654C), Color(0xFFDD4B34)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE85A42).withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Lên kèo hẹn hò ngay 💖',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: _history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return _buildHistoryCard(item)
                            .animate()
                            .fadeIn(duration: 350.ms, delay: (80 * index).ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DatingPlanHistoryItem item) {
    final dateStr = '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}';

    return CuteBounceOnTap(
      onTap: () => _openDetail(item),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF3E7DF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Occasion badge & Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.occasionEmoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        item.occasionLabel,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE85A42),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF9E8E89),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.isCompleted ? '✓ Hoàn thành' : '📅 Đã lên plan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: item.isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Plan Title
            Text(
              item.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2C1810),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),

            // Spots Photos / Icons Preview Row
            if (item.spots.isNotEmpty) ...[
              Row(
                children: [
                  ...item.spots.take(3).map((spot) {
                    return Container(
                      width: 46,
                      height: 46,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFDED3), width: 1.5),
                        color: const Color(0xFFFFF3EE),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: spot.imageAsset.isNotEmpty
                          ? Image.asset(spot.imageAsset, fit: BoxFit.cover)
                          : Center(child: Text(spot.iconEmoji, style: const TextStyle(fontSize: 22))),
                    );
                  }),
                  if (item.spots.length > 3)
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECE5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '+${item.spots.length - 3}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE85A42),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            const Divider(height: 1, color: Color(0xFFF3E7DF)),
            const SizedBox(height: 10),

            // Bottom row: Total cost & Chevron link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    Text(
                      'Chi phí: ~${item.totalCostDisplay}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5A443E),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'Xem chi tiết lộ trình',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE85A42),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFE85A42)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
