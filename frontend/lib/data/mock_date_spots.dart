import 'package:flutter/material.dart';
import '../models/date_spot.dart';

class MockDateSpotsData {
  static const List<DateOccasion> occasions = [
    DateOccasion(
      id: 'anniversary',
      label: 'Kỷ niệm',
      emoji: '💖',
      titlePrompt: '"Lên kế hoạch ngày kỷ niệm"',
    ),
    DateOccasion(
      id: 'birthday',
      label: 'Sinh nhật',
      emoji: '🎂',
      titlePrompt: '"Lên kế hoạch sinh nhật người ấy"',
    ),
    DateOccasion(
      id: 'just_because',
      label: 'Ngẫu hứng',
      emoji: '🌷',
      titlePrompt: '"Lên kèo hẹn hò ngọt ngào"',
    ),
    DateOccasion(
      id: 'first_date',
      label: 'Buổi hẹn đầu',
      emoji: '🥂',
      titlePrompt: '"Buổi hẹn đầu đáng nhớ"',
    ),
    DateOccasion(
      id: 'weekend_chill',
      label: 'Cuối tuần chill',
      emoji: '🌙',
      titlePrompt: '"Kèo cuối tuần thư giãn"',
    ),
  ];

  static const List<String> defaultPreferenceTags = [
    '🍰 Thích đồ ngọt',
    '🌙 Nơi yên tĩnh',
    '📷 Thích chụp ảnh',
    '🌊 View biển',
    '🔊 Tránh nơi ồn ào',
    '🚗 Không đi xa',
    '💖 Vibe lãng mạn',
    '🍜 Ăn vặt đường phố',
    '🎵 Nhạc acoustic',
    '☕ Quán cafe ấm cúng',
    '🎨 Workshop trải nghiệm',
    '🍷 Rooftop & Vang',
  ];

  static final List<DateSpot> allSpots = [
    // Spot 0: Pottery Workshop (Khớp chuẩn ảnh mẫu chi tiết)
    const DateSpot(
      id: 'spot-pottery',
      name: 'Pottery Workshop',
      category: '🎨 WORKSHOP SÁNG TẠO',
      experienceType: 'TRẢI NGHIỆM —',
      area: 'Hải Châu',
      cost: 350000,
      costDisplay: '350K',
      distance: '1.8 km',
      fitScore: 89,
      tags: ['☕ Ấm cúng', '🎨 Sáng tạo', '📷 Chụp ảnh'],
      activityTitle: 'Tự tay làm đồ gốm cùng nhau',
      timeSlotLabel: 'KHOẢNH KHẮC SÁNG TẠO BUỔI CHIỀU',
      aiNote: 'Studio gốm nhỏ ven sông, ánh sáng tự nhiên, góc chụp ảnh rất thơ.',
      secretIdea: 'Khắc tên hoặc ngày kỷ niệm của hai bạn vào đáy chiếc cốc gốm.',
      iconEmoji: '🏺',
      gradientColors: [Color(0xFFE2A684), Color(0xFFC78477), Color(0xFF76555C)],
      heroImageUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1578749556568-bc2c40e68b61?w=500&q=80',
        'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=500&q=80',
        'https://images.unsplash.com/photo-1610701596007-11502861dcfa?w=500&q=80',
      ],
      fullAddress: '42 Trần Phú, Hải Châu, Đà Nẵng',
      description:
          'Studio gốm nhỏ ven sông, ánh sáng tự nhiên, có góc chụp hình đẹp. Hai bạn có thể tự tay nặn một món đồ nhỏ và cùng lưu lại một kỷ niệm đáng nhớ.',
      menuItems: [
        {'name': 'Gói 2 người · 1 sản phẩm/người', 'price': '280K'},
        {'name': '+ Trà / nước mời', 'price': '70K'},
      ],
      aiReasons: [
        'Người ấy thích những activity có thể cùng làm và lưu lại kỷ niệm.',
        'Phù hợp với vibe ấm cúng, sáng tạo và thích chụp ảnh.',
      ],
    ),

    // Spot 1: La Rive Bistro
    const DateSpot(
      id: 'spot-1',
      name: 'La Rive Bistro',
      category: '🌷 BỮA TỐI & TRÁNG MIỆNG HOÀNG HÔN',
      experienceType: 'ẨM THỰC LÃNG MẠN —',
      area: 'An Thượng',
      cost: 280000,
      costDisplay: '280K',
      distance: '1.2 km',
      fitScore: 96,
      tags: ['💖 Lãng mạn', '🍰 Đồ ngọt', '🌊 View biển'],
      activityTitle: 'Bữa tối ấm cúng bên mặt nước',
      timeSlotLabel: 'BẤT CỨ KHI NÀO HAI BẠN THẤY ĐÓI',
      aiNote: 'La Rive Bistro — bàn cạnh bờ sông yên ả, đúng kiểu buổi tối người ấy thích nhất.',
      secretIdea: 'Hoa tulip — người ấy sẽ bất ngờ vì bạn vẫn nhớ sở thích này.',
      iconEmoji: '🍝',
      gradientColors: [Color(0xFFFFA585), Color(0xFFC38090), Color(0xFF78556D)],
      heroImageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1550966871-3ed3cdb5ed0c?w=500&q=80',
        'https://images.unsplash.com/photo-1544025162-d76694265947?w=500&q=80',
        'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=500&q=80',
      ],
      fullAddress: '18 An Thượng 4, Ngũ Hành Sơn, Đà Nẵng',
      description:
          'Nhà hàng phong cách bistro Pháp nép mình bên hàng cây xanh, ban công lộng gió biển, ánh nến lung linh dịu êm thích hợp cho những buổi tối tâm sự ngọt ngào.',
      menuItems: [
        {'name': 'Set Dinner 2 người · Pasta & Bít tết', 'price': '240K'},
        {'name': '+ 2 Ly vang đỏ Merlot', 'price': '40K'},
      ],
      aiReasons: [
        'Bàn view đẹp bên ngoài yên tĩnh, đúng gu nói chuyện nhẹ nhàng.',
        'Món tráng miệng panna cotta dâu tây rất được lòng các bạn nữ.',
      ],
    ),

    // Spot 2: Mochi & Cream
    const DateSpot(
      id: 'spot-2',
      name: 'Mochi & Cream',
      category: '🍰 QUÁN TRÁNG MIỆNG NGỌT NGÀO',
      experienceType: 'TRÁNG MIỆNG NGỌT NGÀO —',
      area: 'Bạch Đằng',
      cost: 120000,
      costDisplay: '120K',
      distance: '0.6 km',
      fitScore: 89,
      tags: ['🍰 Đồ ngọt', '🌙 Yên tĩnh'],
      activityTitle: 'Món tráng miệng ngọt ngào sau đó',
      timeSlotLabel: 'THONG THẢ ĐẾN NƠI, KHÔNG CẦN VỘI',
      aiNote: 'Mochi & Cream — cách đó 5 phút đi bộ. Nhớ để dành bụng ăn tráng miệng nhé.',
      secretIdea: 'Gọi phần mochi hạt dẻ nướng mà người ấy thích mê lần trước.',
      iconEmoji: '🍰',
      gradientColors: [Color(0xFFFFB085), Color(0xFFD68A88), Color(0xFF8A626E)],
      heroImageUrl: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=500&q=80',
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&q=80',
        'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?w=500&q=80',
      ],
      fullAddress: '86 Bạch Đằng, Hải Châu, Đà Nẵng',
      description:
          'Tiệm bánh mochi thủ công phong cách Nhật Bản, vỏ bánh dẻo thơm kết hợp kem gelato béo ngậy tan chảy trên đầu lưỡi, không gian pastel xinh xắn.',
      menuItems: [
        {'name': 'Mochi kem hạt dẻ rang & matcha', 'price': '80K'},
        {'name': '+ Trà sen hoa hồng ấm', 'price': '40K'},
      ],
      aiReasons: [
        'Cách chỗ ăn tối chỉ 5 phút đi bộ ven sông Hàn mát mẻ.',
        'Hương vị ngọt thanh không bị gắt, chụp hình đồ ngọt cực xinh.',
      ],
    ),

    // Spot 3: Sunset Deck Beach Walk
    const DateSpot(
      id: 'spot-3',
      name: 'Sunset Deck Beach Walk',
      category: '🌊 DẠO BỜ BIỂN',
      experienceType: 'DẠO BIỂN HOÀNG HÔN —',
      area: 'Mỹ Khê',
      cost: 0,
      costDisplay: 'Miễn phí',
      distance: '3.0 km',
      fitScore: 84,
      tags: ['🌊 View biển', '📷 Chụp ảnh', '🌙 Yên tĩnh'],
      activityTitle: 'Dạo bộ thong dong bên bờ biển',
      timeSlotLabel: 'CỨ Ở LẠI BAO LÂU TÙY THÍCH',
      aiNote: 'Mỹ Khê đoạn cuối bờ biển — yên tĩnh và chụp ảnh đôi rất đẹp nếu người ấy muốn.',
      secretIdea: 'Tháo dép, chạm chân xuống làn sóng chiều tà và nắm chặt tay nhau.',
      iconEmoji: '🌊',
      gradientColors: [Color(0xFFA5C4D4), Color(0xFFB593B0), Color(0xFF6B587B)],
      heroImageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1519046904884-53103b34b206?w=500&q=80',
        'https://images.unsplash.com/photo-1471922694855-fa59acdb3e3d?w=500&q=80',
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=500&q=80',
      ],
      fullAddress: 'Bãi biển Mỹ Khê, đoạn cuối đường Võ Nguyên Giáp, Đà Nẵng',
      description:
          'Bãi cát mịn thoai thoải, tiếng sóng vỗ êm đềm và làn gió biển mát rượi. Khoảnh khắc hoàng hôn buông xuống nhuộm tím cả bầu trời tạo nên khung cảnh lãng mạn khó quên.',
      menuItems: [
        {'name': 'Vé vào cửa bãi biển', 'price': 'Miễn phí'},
        {'name': 'Ngắm hoàng hôn & chụp ảnh kỉ niệm', 'price': '0K'},
      ],
      aiReasons: [
        'Không khí thoáng đãng, tự nhiên, không gian riêng tư không ồn ào.',
        'Ánh sáng hoàng hôn tím hồng chụp ảnh chân dung rất đẹp.',
      ],
    ),

    // Spot 4: The Sky Deck 36
    const DateSpot(
      id: 'spot-4',
      name: 'The Sky Deck 36',
      category: '🍸 ROOFTOP & NGẮM THÀNH PHỐ',
      experienceType: 'ROOFTOP NGẮM PHỐ —',
      area: 'Sơn Trà',
      cost: 350000,
      costDisplay: '350K',
      distance: '2.1 km',
      fitScore: 95,
      tags: ['💖 Lãng mạn', '📷 Chụp ảnh', '🍷 Rooftop & Vang'],
      activityTitle: 'Thưởng thức cocktail dưới ánh đèn thành phố',
      timeSlotLabel: 'KHI MÀN ĐÊM BUÔNG XUỐNG',
      aiNote: 'Ngắm trọn cầu Rồng và sông Hàn lấp lánh với ánh đèn lung linh dịu nhẹ.',
      secretIdea: 'Thì thầm kỷ niệm đáng nhớ nhất của hai bạn khi ngắm thành phố lên đèn.',
      iconEmoji: '🍸',
      gradientColors: [Color(0xFFE2847A), Color(0xFF88608B), Color(0xFF383B64)],
      heroImageUrl: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=500&q=80',
        'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?w=500&q=80',
        'https://images.unsplash.com/photo-1470337458703-46ad1756a187?w=500&q=80',
      ],
      fullAddress: 'Tầng 36, Khách sạn Novotel, Bạch Đằng, Đà Nẵng',
      description:
          'Tọa độ ngắm trọn thành phố Đà Nẵng từ trên cao. Cầu Rồng rực sáng và dòng sông Hàn lấp lánh phản chiếu ánh đèn tạo nên trải nghiệm đẳng cấp và lãng mạn.',
      menuItems: [
        {'name': '2 Ly Mocktail / Cocktail hoàng hôn', 'price': '280K'},
        {'name': '+ Snack hạt ô-liu & phô mai que', 'price': '70K'},
      ],
      aiReasons: [
        'Góc ngắm toàn cảnh sông Hàn về đêm cực kỳ lãng mạn.',
        'Nhạc chill nhẹ nhàng, ghế bọc nệm riêng tư cho 2 người.',
      ],
    ),

    // Spot 5: Góc Nhỏ Acoustic & Wine
    const DateSpot(
      id: 'spot-5',
      name: 'Góc Nhỏ Acoustic & Wine',
      category: '🎵 KHÔNG GIAN ACOUSTIC & VANG',
      experienceType: 'NHẠC SỐNG ACOUSTIC —',
      area: 'Hải Châu',
      cost: 210000,
      costDisplay: '210K',
      distance: '1.5 km',
      fitScore: 92,
      tags: ['🎵 Nhạc acoustic', '🌙 Yên tĩnh', '💖 Lãng mạn'],
      activityTitle: 'Những giai điệu ấm áp bên ánh nến',
      timeSlotLabel: 'KHI TIẾNG NHẠC VANG LÊN',
      aiNote: 'Gác gỗ nhỏ thắp nến ấm cúng, guitar mộc mạc và những bản tình ca êm dịu.',
      secretIdea: 'Yêu cầu bài hát indie từng bật trong chuyến đi chơi đầu tiên.',
      iconEmoji: '🎵',
      gradientColors: [Color(0xFFE89A7A), Color(0xFFA66978), Color(0xFF5A445C)],
      heroImageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&q=80',
      galleryImages: [
        'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=500&q=80',
        'https://images.unsplash.com/photo-1525268771113-32d9e9021a97?w=500&q=80',
        'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500&q=80',
      ],
      fullAddress: '32 Lê Đình Dương, Hải Châu, Đà Nẵng',
      description:
          'Gác gỗ nhỏ thắp nến ấm cúng, nơi những bản tình ca acoustic mộc mạc vang lên êm dịu, mang lại cảm giác bình yên và gần gũi cho hai bạn.',
      menuItems: [
        {'name': '2 Vé xem đêm nhạc acoustic ấm áp', 'price': '150K'},
        {'name': '+ 2 Ly đồ uống đặc biệt', 'price': '60K'},
      ],
      aiReasons: [
        'Cả hai đều yêu thích âm nhạc nhẹ nhàng và không gian ấm cúng.',
        'Ánh nến vàng ấm áp tạo bầu không khí thư thái sau ngày dài.',
      ],
    ),
  ];

  /// Smart filter & rank based on budget, occasion, and preferences
  static List<DateSpot> filterAndRank({
    required int maxBudgetVnd,
    required String occasionId,
    required Set<String> selectedPreferences,
    String customWish = '',
  }) {
    final spots = List<DateSpot>.from(allSpots);

    // Compute dynamic fit score
    final scored = spots.map((spot) {
      int score = spot.fitScore;

      // Budget check
      if (spot.cost <= maxBudgetVnd) {
        score += 4;
      } else if (spot.cost > maxBudgetVnd * 1.3) {
        score -= 10;
      }

      // Preference match
      for (final pref in selectedPreferences) {
        final cleanPref = pref.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
        for (final tag in spot.tags) {
          final cleanTag = tag.replaceAll(RegExp(r'[^\w\s]'), '').trim().toLowerCase();
          if (cleanTag.contains(cleanPref) || cleanPref.contains(cleanTag)) {
            score += 3;
          }
        }
      }

      // Occasion match
      if (occasionId == 'anniversary' && spot.tags.any((t) => t.contains('Lãng mạn'))) {
        score += 5;
      } else if (occasionId == 'birthday' && spot.tags.any((t) => t.contains('ngọt'))) {
        score += 4;
      }

      // Custom wish keyword match
      if (customWish.isNotEmpty) {
        final wishLower = customWish.toLowerCase();
        if (wishLower.contains('gốm') || wishLower.contains('workshop')) {
          if (spot.id == 'spot-pottery') score += 15;
        }
        if (wishLower.contains('yên tĩnh') && spot.tags.any((t) => t.contains('Yên tĩnh'))) score += 5;
        if (wishLower.contains('biển') && spot.tags.any((t) => t.contains('biển'))) score += 5;
        if (wishLower.contains('ăn') && (spot.category.contains('BỮA TỐI') || spot.category.contains('ẨM THỰC'))) score += 4;
        if (wishLower.contains('ngọt') && spot.tags.any((t) => t.contains('ngọt'))) score += 4;
        if (wishLower.contains('ảnh') && spot.tags.any((t) => t.contains('ảnh'))) score += 4;
      }

      final clamped = score.clamp(75, 99);
      return DateSpot(
        id: spot.id,
        name: spot.name,
        category: spot.category,
        experienceType: spot.experienceType,
        area: spot.area,
        cost: spot.cost,
        costDisplay: spot.costDisplay,
        distance: spot.distance,
        fitScore: clamped,
        tags: spot.tags,
        activityTitle: spot.activityTitle,
        timeSlotLabel: spot.timeSlotLabel,
        aiNote: spot.aiNote,
        secretIdea: spot.secretIdea,
        iconEmoji: spot.iconEmoji,
        gradientColors: spot.gradientColors,
        heroImageUrl: spot.heroImageUrl,
        galleryImages: spot.galleryImages,
        fullAddress: spot.fullAddress,
        description: spot.description,
        menuItems: spot.menuItems,
        aiReasons: spot.aiReasons,
      );
    }).toList();

    // Sort descending by fitScore
    scored.sort((a, b) => b.fitScore.compareTo(a.fitScore));
    return scored;
  }
}
