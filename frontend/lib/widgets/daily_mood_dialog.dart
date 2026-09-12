import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/user_mood.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'ourly_toast.dart';
import 'romantic_effects.dart';

class DailyMoodDialog extends StatefulWidget {
  final String partnerName;
  final Function(UserMood mood)? onMoodSubmitted;

  const DailyMoodDialog({
    super.key,
    required this.partnerName,
    this.onMoodSubmitted,
  });

  static Future<UserMood?> show(
    BuildContext context, {
    required String partnerName,
    Function(UserMood mood)? onMoodSubmitted,
  }) {
    return showDialog<UserMood>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DailyMoodDialog(
        partnerName: partnerName,
        onMoodSubmitted: onMoodSubmitted,
      ),
    );
  }

  @override
  State<DailyMoodDialog> createState() => _DailyMoodDialogState();
}

class _DailyMoodDialogState extends State<DailyMoodDialog> {
  UserMood _selectedMood = UserMood.defaultMoods.first;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentMood = ApiService().getTodayUserMood();
    if (currentMood != null) {
      _selectedMood = UserMood.defaultMoods.firstWhere(
        (m) => m.id == currentMood.id,
        orElse: () => UserMood.defaultMoods.first,
      );
      _noteController.text = currentMood.note;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final note = _noteController.text.trim();
    final submittedMood = UserMood(
      id: _selectedMood.id,
      emoji: _selectedMood.emoji,
      label: _selectedMood.label,
      description: _selectedMood.description,
      partnerHint: _selectedMood.partnerHint,
      note: note,
      createdAt: DateTime.now(),
    );

    ApiService().saveTodayMood(submittedMood);

    // Bắn thông báo ra ngoài màn hình điện thoại / máy tính
    NotificationService.sendScreenNotification(
      title: 'Ourly 💕: Tín hiệu tâm trạng đã gửi!',
      body: 'Gợi ý quan tâm đã được chuyển đến ${widget.partnerName}: ${_selectedMood.partnerHint}',
    );

    // Hiệu ứng pháo hoa tình yêu và Toast nổi
    LoveSparkleOverlay.show(context);
    OurlyToast.showLove(
      context,
      'Đã chia sẻ tâm trạng hôm nay đến ${widget.partnerName}! 💕',
      title: 'Tín hiệu yêu thương ✨',
    );

    widget.onMoodSubmitted?.call(submittedMood);
    Navigator.of(context).pop(submittedMood);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.92,
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFFECE6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE85A42).withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFECE6),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('🌤️', style: TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TÂM TRẠNG HÔM NAY',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: const Color(0xFFE85A42),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bạn đang cảm thấy thế nào? ♡',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2C1914),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFF8C7973)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Chia sẻ nhanh để Ourly gửi gợi ý quan tâm ngọt ngào đến ${widget.partnerName} nhé!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7A6863),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),

              // Mood Options Grid
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.28,
                        ),
                        itemCount: UserMood.defaultMoods.length,
                        itemBuilder: (context, index) {
                          final mood = UserMood.defaultMoods[index];
                          final isSelected = _selectedMood.id == mood.id;

                          return CuteBounceOnTap(
                            onTap: () => setState(() => _selectedMood = mood),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFFF2EE) : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFE85A42) : const Color(0xFFF1E4DA),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFFE85A42).withValues(alpha: 0.14),
                                          blurRadius: 10,
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(mood.emoji, style: const TextStyle(fontSize: 28)),
                                  const SizedBox(height: 4),
                                  Text(
                                    mood.label,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                      color: isSelected ? const Color(0xFFE85A42) : const Color(0xFF2C1810),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mood.description,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF8C7973),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Gợi ý hint sẽ gửi cho partner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF9F5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFE5D8)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💌', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gợi ý Ourly sẽ gửi cho ${widget.partnerName}:',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFC75D49),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedMood.partnerHint,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFF5A443E),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Note tuỳ ý
                      TextField(
                        controller: _noteController,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Thêm lời nhắn nhỏ (ví dụ: hôm nay muốn ăn đồ ngọt...)',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFFAAA09D),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAF5F0),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFF1E4DA)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFF1E4DA)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE85A42), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Nút Gửi tín hiệu
              CuteBounceOnTap(
                onTap: _handleSubmit,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF1654C), Color(0xFFDD4B34)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE85A42).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Gửi tín hiệu đến ${widget.partnerName} 💕',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(
            duration: 350.ms,
            curve: Curves.easeOutBack,
            begin: const Offset(0.85, 0.85),
            end: const Offset(1.0, 1.0),
          ).fadeIn(duration: 250.ms),
    );
  }
}
