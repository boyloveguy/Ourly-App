import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/date_spot.dart';

class DateTimelineStepDetails extends StatelessWidget {
  final DateTimelineStep step;

  const DateTimelineStepDetails({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    // Chuẩn bị fallback nếu data chưa có danh sách
    final activities = step.activities.isNotEmpty
        ? step.activities
        : [
            'Thong thả tận hưởng không gian và gọi món yêu thích cùng người ấy.',
            'Dành trọn vẹn sự chú ý cho đối phương, hạn chế nhìn vào điện thoại.',
          ];

    final topics = step.conversationTopics.isNotEmpty
        ? step.conversationTopics
        : [
            'Hỏi người ấy về khoảnh khắc làm họ mỉm cười nhiều nhất trong tuần qua.',
            'Cùng chia sẻ một mong ước nhỏ mà hai bạn muốn thực hiện cùng nhau sắp tới.',
          ];

    final tips = step.caringTips.isNotEmpty
        ? step.caringTips
        : [
            'Chủ động quan sát, kéo ghế hoặc gắp món tráng miệng cho người ấy.',
            'Chụp góc nghiêng lúc người ấy cười tự nhiên dưới ánh nến lung linh.',
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Tóm tắt cảm xúc ban đầu
        if (step.description.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF4EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1E4DA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5A443E),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 2. Khối Hoạt Động Cụ Thể (Chi tiết người dùng làm gì)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9F5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFE6D8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    'HOẠT ĐỘNG & TRẢI NGHIỆM GỢI Ý',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: const Color(0xFFE85A42),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...activities.map((act) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE85A42),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            act,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF402E29),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        // 3. Khối Chủ Đề Tâm Sự & Gắn Kết
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF7FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEFE2FD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    'CHỦ ĐỀ GỢI MỞ TÂM SỰ NGỌT NGÀO',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: const Color(0xFF7A4BB8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...topics.map((tpc) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💭 ', style: TextStyle(fontSize: 11)),
                        Expanded(
                          child: Text(
                            tpc,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF4B3263),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        // 4. Khối Cử Chỉ Tinh Tế Ghi Điểm
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4F6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFFD5DD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    'CỬ CHỈ TINH TẾ KHIẾN NGƯỜI ẤY TAN CHẢY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: const Color(0xFFD94868),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...tips.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🌸 ', style: TextStyle(fontSize: 11)),
                        Expanded(
                          child: Text(
                            tip,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5A2A37),
                              height: 1.38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),

        // 5. Highlight Quote nếu có
        if (step.highlightQuote.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFE0D6), width: 0.8),
            ),
            child: Text(
              '“${step.highlightQuote}”',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFC2523C),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
