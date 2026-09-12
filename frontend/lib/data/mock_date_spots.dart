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
    // 1. La Rive Bistro
    const DateSpot(
      id: 'spot-bistro',
      name: 'La Rive Bistro',
      category: '🌷 BỮA TỐI LÃNG MẠN',
      experienceType: 'ẨM THỰC LÃNG MẠN —',
      area: 'An Thượng',
      cost: 280000,
      costDisplay: '280K',
      distance: '1.2 km',
      fitScore: 96,
      tags: ['💖 Vibe lãng mạn', '🍰 Thích đồ ngọt', '🌊 View biển', '🍷 Rooftop & Vang'],
      activityTitle: 'Bữa tối ấm cúng bên mặt nước sông Hàn',
      timeSlotLabel: 'BẤT CỨ KHI NÀO HAI BẠN THẤY ĐÓI',
      aiNote: 'La Rive Bistro — bàn cạnh bờ sông yên ả, ánh nến lung linh đúng kiểu buổi tối lãng mạn.',
      secretIdea: 'Tặng bông hoa tulip nhỏ — người ấy sẽ bất ngờ vì bạn luôn nhớ điều này.',
      iconEmoji: '🍝',
      gradientColors: [Color(0xFFFFA585), Color(0xFFC38090), Color(0xFF78556D)],
      heroImageUrl: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
      imageAsset: 'assets/images/spot_bistro.jpg',
      galleryImages: [
        'assets/images/spot_bistro.jpg',
        'assets/images/spot_rooftop.jpg',
        'assets/images/spot_dessert.jpg',
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
      activities: [
        'Đặt trước bàn số 4 ban công hướng sông Hàn để đón trọn gió mát và ánh hoàng hôn buông xuống mặt nước.',
        'Gọi set bít tết sốt tiêu đen mềm mọng kèm đĩa mì Ý hải sản và 2 ly vang đỏ Merlot nhẹ độ.',
        'Trong lúc chờ món, cùng nhau ngắm nhìn dòng thuyền hoa trôi trên sông và chia sẻ về những điều thú vị trong ngày.',
      ],
      conversationTopics: [
        '“Điều gì ở em/anh trong lần đầu gặp gỡ khiến đối phương ấn tượng sâu đậm nhất?”',
        '“Nếu cùng nhau đi du lịch đến một vùng đất xa xôi trong năm nay, hai đứa mình sẽ đi đâu đầu tiên?”',
      ],
      caringTips: [
        'Kéo ghế cho người ấy trước khi ngồi, chủ động rót nước ấm và gắp phần ngon nhất cho đối phương.',
        'Chụp ảnh góc nghiêng tự nhiên lúc người ấy đang nhấp ngụm vang dưới ánh nến lung linh.',
      ],
      highlightQuote: 'Dưới ánh nến dịu êm, mọi ồn ào của thế giới bên ngoài đều nhường chỗ cho hai ta.',
    ),

    // 2. Pottery Studio Mộc
    const DateSpot(
      id: 'spot-pottery',
      name: 'Pottery Studio Mộc',
      category: '🎨 WORKSHOP GỐM THỦ CÔNG',
      experienceType: 'TRẢI NGHIỆM SÁNG TẠO —',
      area: 'Hải Châu',
      cost: 350000,
      costDisplay: '350K',
      distance: '1.8 km',
      fitScore: 89,
      tags: ['🎨 Workshop trải nghiệm', '☕ Quán cafe ấm cúng', '📷 Thích chụp ảnh', '🌙 Nơi yên tĩnh'],
      activityTitle: 'Tự tay làm đồ gốm cùng nhau',
      timeSlotLabel: 'KHOẢNH KHẮC SÁNG TẠO BUỔI CHIỀU',
      aiNote: 'Studio gốm nhỏ ven sông, ánh sáng tự nhiên, góc chụp ảnh rất thơ và nhiều kỷ niệm.',
      secretIdea: 'Khắc tên hoặc ngày kỷ niệm của hai bạn vào đáy chiếc cốc gốm.',
      iconEmoji: '🏺',
      gradientColors: [Color(0xFFE2A684), Color(0xFFC78477), Color(0xFF76555C)],
      heroImageUrl: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800&q=80',
      imageAsset: 'assets/images/spot_pottery.jpg',
      galleryImages: [
        'assets/images/spot_pottery.jpg',
        'assets/images/spot_painting.jpg',
        'assets/images/spot_dessert.jpg',
      ],
      fullAddress: '42 Trần Phú, Hải Châu, Đà Nẵng',
      description:
          'Studio gốm nhỏ ven sông, ánh sáng tự nhiên, có góc chụp hình đẹp. Hai bạn có thể tự tay nặn một món đồ nhỏ và cùng lưu lại một kỷ niệm đáng nhớ.',
      menuItems: [
        {'name': 'Gói 2 người · 1 sản phẩm gốm/người', 'price': '280K'},
        {'name': '+ Trà mộc hoa hồng mời', 'price': '70K'},
      ],
      aiReasons: [
        'Người ấy thích những hoạt động thủ công cùng làm và lưu giữ kỷ niệm.',
        'Phù hợp với vibe ấm cúng, sáng tạo và thích chụp ảnh lưu niệm.',
      ],
      activities: [
        'Đeo tạp dề đôi cho nhau, cùng ngồi bên bàn xoay gốm dưới ánh nắng chiều vàng ấm áp qua khung cửa sổ.',
        'Đặt tay lên tay đối phương cùng vuốt ve khối đất sét mềm, nặn chiếc ly uống nước đôi hoặc chiếc đĩa kỷ niệm.',
        'Dùng que nhọn khắc chữ cái đầu tên của hai bạn và ngày kỷ niệm vào đáy sản phẩm gốm.',
      ],
      conversationTopics: [
        '“Nếu so sánh tình yêu của tụi mình với một tác phẩm gốm, em/anh thấy nó đang ở giai đoạn tạo hình nào?”',
        '“Kỷ niệm nào bên nhau làm em/anh cảm thấy bình yên và được là chính mình nhất?”',
      ],
      caringTips: [
        'Nhẹ nhàng vén lọn tóc vướng bên má người ấy khi tay đối phương đang dính đất sét.',
        'Chụp lại khoảnh khắc hai bàn tay cùng lấm lem đất nhưng nở nụ cười rạng rỡ bên bàn xoay.',
      ],
      highlightQuote: 'Từng vòng xoay nhẫn nại tạo nên hình hài của kỷ niệm bền lâu.',
    ),

    // 3. Mochi & Cream Gelato
    const DateSpot(
      id: 'spot-dessert',
      name: 'Mochi & Cream Gelato',
      category: '🍰 TRÁNG MIỆNG NGỌT NGÀO',
      experienceType: 'TRÁNG MIỆNG NGỌT NGÀO —',
      area: 'Bạch Đằng',
      cost: 120000,
      costDisplay: '120K',
      distance: '0.6 km',
      fitScore: 92,
      tags: ['🍰 Thích đồ ngọt', '🌙 Nơi yên tĩnh', '📷 Thích chụp ảnh', '☕ Quán cafe ấm cúng'],
      activityTitle: 'Món tráng miệng ngọt ngào sau đó',
      timeSlotLabel: 'THONG THẢ ĐẾN NƠI, KHÔNG CẦN VỘI',
      aiNote: 'Mochi & Cream — cách đó 5 phút đi bộ ven sông Hàn. Nhớ để dành bụng ăn tráng miệng nhé.',
      secretIdea: 'Gọi phần mochi kem dâu tây hạt dẻ mà người ấy thích mê lần trước.',
      iconEmoji: '🍰',
      gradientColors: [Color(0xFFFFB085), Color(0xFFD68A88), Color(0xFF8A626E)],
      heroImageUrl: 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?w=800&q=80',
      imageAsset: 'assets/images/spot_dessert.jpg',
      galleryImages: [
        'assets/images/spot_dessert.jpg',
        'assets/images/spot_bistro.jpg',
        'assets/images/spot_acoustic.jpg',
      ],
      fullAddress: '86 Bạch Đằng, Hải Châu, Đà Nẵng',
      description:
          'Tiệm bánh mochi thủ công phong cách Nhật Bản, vỏ bánh dẻo thơm kết hợp kem gelato béo ngậy tan chảy trên đầu lưỡi, không gian pastel xinh xắn.',
      menuItems: [
        {'name': 'Mochi kem dâu tây & matcha gelato', 'price': '80K'},
        {'name': '+ Trà sen hoa hồng ấm', 'price': '40K'},
      ],
      aiReasons: [
        'Hương vị ngọt thanh không bị gắt, chụp hình đồ ngọt cực xinh.',
        'Không gian thanh tịnh ven sông Hàn mát mẻ, thích hợp tâm sự nhẹ.',
      ],
      activities: [
        'Đi bộ thong thả khoảng 5 phút ven bờ sông Hàn từ quán ăn sang tiệm mochi trong làn gió mát lành ban đêm.',
        'Chọn 2 vị kem gelato đặc trưng: mochi kem dâu tây chua ngọt và matcha thơm béo hạt dẻ.',
        'Ngồi tại góc bàn cửa kính nhìn ra phố đi bộ, cùng thưởng thức món tráng miệng ngọt mát.',
      ],
      conversationTopics: [
        '“Món ngọt nào làm em/anh liên tưởng đến hương vị tình yêu của hai đứa mình?”',
        '“Có thói quen nhỏ nào của anh/em mà làm đối phương vừa buồn cười vừa thấy thương không?”',
      ],
      caringTips: [
        'Chủ động dùng khăn giấy chấm nhẹ khóe môi nếu đối phương dính chút bột bánh mochi mềm.',
        'Đút cho người ấy thử muỗng kem đầu tiên để xem phản ứng thích thú của người ấy.',
      ],
      highlightQuote: 'Vị ngọt tan chảy trên đầu lưỡi, như những âu yếm không cần nói thành lời.',
    ),

    // 4. Sunset Deck Bãi Biển Mỹ Khê
    const DateSpot(
      id: 'spot-beach',
      name: 'Sunset Deck Biển Mỹ Khê',
      category: '🌊 DẠO BIỂN HOÀNG HÔN',
      experienceType: 'DẠO BIỂN HOÀNG HÔN —',
      area: 'Mỹ Khê',
      cost: 0,
      costDisplay: 'Miễn phí',
      distance: '3.0 km',
      fitScore: 94,
      tags: ['🌊 View biển', '📷 Thích chụp ảnh', '🌙 Nơi yên tĩnh', '🚗 Không đi xa'],
      activityTitle: 'Dạo bộ thong dong bên bờ biển',
      timeSlotLabel: 'KHOẢNH KHẮC HOÀNG HÔN BUÔNG XUỐNG',
      aiNote: 'Mỹ Khê đoạn cuối bờ biển — yên tĩnh và chụp ảnh đôi rất đẹp khi hoàng hôn nhuộm tím bầu trời.',
      secretIdea: 'Tháo dép, chạm chân xuống làn sóng chiều tà và nắm chặt tay nhau.',
      iconEmoji: '🌊',
      gradientColors: [Color(0xFFA5C4D4), Color(0xFFB593B0), Color(0xFF6B587B)],
      heroImageUrl: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',
      imageAsset: 'assets/images/spot_beach.jpg',
      galleryImages: [
        'assets/images/spot_beach.jpg',
        'assets/images/spot_rooftop.jpg',
        'assets/images/spot_bistro.jpg',
      ],
      fullAddress: 'Bãi biển Mỹ Khê, đường Võ Nguyên Giáp, Đà Nẵng',
      description:
          'Bãi cát mịn thoai thoải, tiếng sóng vỗ êm đềm và làn gió biển mát rượi. Khoảnh khắc hoàng hôn buông xuống nhuộm tím cả bầu trời tạo nên khung cảnh lãng mạn khó quên.',
      menuItems: [
        {'name': 'Dạo bộ bãi biển & ngắm hoàng hôn', 'price': '0K'},
        {'name': '+ Nước dừa xiêm tươi ướp lạnh (2 trái)', 'price': '50K'},
      ],
      aiReasons: [
        'Không khí thoáng đãng, tự nhiên, không gian riêng tư không ồn ào.',
        'Ánh sáng hoàng hôn tím hồng chụp ảnh chân dung rất đẹp.',
      ],
      activities: [
        'Cùng tháo giày dép, xách dép trên tay và để đôi chân trần chạm vào bãi cát mịn màng ven bờ sóng.',
        'Đi dạo chậm rãi men theo bờ mép nước lúc hoàng hôn tím hồng buông dần xuống chân trời vịnh Đà Nẵng.',
        'Cùng ngồi lại trên bậc thềm gỗ nghe tiếng sóng rì rào, nhấp ngụm nước dừa tươi ngọt mát.',
      ],
      conversationTopics: [
        '“Cảm giác đứng trước biển lớn mênh mông bên cạnh người mình thương mang lại cho em/anh điều gì?”',
        '“Nếu thời gian có thể ngừng lại ở một khoảnh khắc của hôm nay, em/anh muốn giữ lại phút giây nào?”',
      ],
      caringTips: [
        'Chủ động đưa tay ra đan chặt các ngón tay người ấy khi sóng biển vừa tràn qua mũi chân.',
        'Đứng chắn phía đón gió lạnh cho người ấy hoặc choàng áo khoác nhẹ nếu trời trở gió chiều.',
      ],
      highlightQuote: 'Biển có thể rộng lớn vô tận, nhưng bàn tay nắm chặt là cả thế giới thu nhỏ.',
    ),

    // 5. The Sky Deck 36 Rooftop
    const DateSpot(
      id: 'spot-rooftop',
      name: 'The Sky Deck 36 Rooftop',
      category: '🍸 ROOFTOP NGẮM PHỐ',
      experienceType: 'ROOFTOP NGẮM PHỐ —',
      area: 'Sơn Trà',
      cost: 350000,
      costDisplay: '350K',
      distance: '2.1 km',
      fitScore: 97,
      tags: ['💖 Vibe lãng mạn', '📷 Thích chụp ảnh', '🍷 Rooftop & Vang', '🌊 View biển'],
      activityTitle: 'Thưởng thức cocktail dưới ánh đèn thành phố',
      timeSlotLabel: 'KHI MÀN ĐÊM BUÔNG XUỐNG',
      aiNote: 'Ngắm trọn cầu Rồng và sông Hàn lấp lánh với ánh đèn lung linh dịu nhẹ từ tầng cao.',
      secretIdea: 'Thì thầm kỷ niệm đáng nhớ nhất của hai bạn khi ngắm thành phố lên đèn.',
      iconEmoji: '🍸',
      gradientColors: [Color(0xFFE2847A), Color(0xFF88608B), Color(0xFF383B64)],
      heroImageUrl: 'https://images.unsplash.com/photo-1514933651103-005eec06c04b?w=800&q=80',
      imageAsset: 'assets/images/spot_rooftop.jpg',
      galleryImages: [
        'assets/images/spot_rooftop.jpg',
        'assets/images/spot_bistro.jpg',
        'assets/images/spot_acoustic.jpg',
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
      activities: [
        'Lên tầng thượng ngắm trọn vẹn toàn cảnh thành phố Đà Nẵng lung linh ánh đèn và dòng sông Hàn uốn lượn.',
        'Gọi 2 ly mocktail / cocktail hoàng hôn với hương cam quế nhẹ nhàng và đĩa snack hạt phô mai.',
        'Ngồi bên chiếc ghế bọc nệm êm ái, cùng lắng nghe những bản nhạc jazz chill thư thái.',
      ],
      conversationTopics: [
        '“Từ trên cao nhìn xuống thế giới nhỏ bé này, em/anh thấy mục tiêu chung lớn nhất của hai đứa mình là gì?”',
        '“Hãy chấm điểm độ hiểu ý nhau của tụi mình sau thời gian bên nhau nhé!”',
      ],
      caringTips: [
        'Chọn vị trí ghế có tầm nhìn thoáng nhất nhường cho người ấy thưởng ngoạn trọn vẹn quang cảnh.',
        'Thì thầm vào tai người ấy một lời cảm ơn chân thành vì đã đồng hành cùng bạn.',
      ],
      highlightQuote: 'Giữa hàng triệu ánh đèn thành phố, ánh mắt người ấy vẫn là vì sao sáng nhất.',
    ),

    // 6. Góc Nhỏ Acoustic & Wine
    const DateSpot(
      id: 'spot-acoustic',
      name: 'Góc Nhỏ Acoustic & Wine',
      category: '🎵 NHẠC SỐNG ACOUSTIC',
      experienceType: 'NHẠC SỐNG ACOUSTIC —',
      area: 'Hải Châu',
      cost: 210000,
      costDisplay: '210K',
      distance: '1.5 km',
      fitScore: 95,
      tags: ['🎵 Nhạc acoustic', '🌙 Nơi yên tĩnh', '💖 Vibe lãng mạn', '🍷 Rooftop & Vang'],
      activityTitle: 'Những giai điệu ấm áp bên ánh nến',
      timeSlotLabel: 'KHI TIẾNG NHẠC VANG LÊN',
      aiNote: 'Gác gỗ nhỏ thắp nến ấm cúng, guitar mộc mạc và những bản tình ca êm dịu.',
      secretIdea: 'Yêu cầu ca sĩ hát bài tình ca hai bạn từng nghe trong buổi hẹn đầu.',
      iconEmoji: '🎵',
      gradientColors: [Color(0xFFE89A7A), Color(0xFFA66978), Color(0xFF5A445C)],
      heroImageUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&q=80',
      imageAsset: 'assets/images/spot_acoustic.jpg',
      galleryImages: [
        'assets/images/spot_acoustic.jpg',
        'assets/images/spot_bistro.jpg',
        'assets/images/spot_dessert.jpg',
      ],
      fullAddress: '32 Lê Đình Dương, Hải Châu, Đà Nẵng',
      description:
          'Gác gỗ nhỏ thắp nến ấm cúng, nơi những bản tình ca acoustic mộc mạc vang lên êm dịu, mang lại cảm giác bình yên và gần gũi cho hai bạn.',
      menuItems: [
        {'name': '2 Vé xem đêm nhạc acoustic ấm áp', 'price': '150K'},
        {'name': '+ 2 Ly vang nóng quế cam / đồ uống', 'price': '60K'},
      ],
      aiReasons: [
        'Cả hai đều yêu thích âm nhạc nhẹ nhàng và không gian ấm cúng.',
        'Ánh nến vàng ấm áp tạo bầu không khí thư thái sau ngày dài.',
      ],
      activities: [
        'Ngồi cạnh nhau trên chiếc ghế bọc da ấm cúng trong căn gác gỗ thắp nến thơm phảng phất hương thông.',
        'Thưởng thức 2 ly vang nóng quế cam ấm nồng và thả hồn theo những bản tình ca mộc mạc tiếng guitar.',
        'Yêu cầu ban nhạc gửi tặng bài hát ý nghĩa mà người ấy yêu thích nhất.',
      ],
      conversationTopics: [
        '“Bài hát nào mỗi khi cất lên giai điệu đều khiến em/anh nhớ ngay đến đối phương?”',
        '“Cảm xúc bình yên nhất mà em/anh từng cảm nhận khi ở bên cạnh người kia là gì?”',
      ],
      caringTips: [
        'Nhẹ nhàng tựa đầu hoặc đặt bàn tay ủ ấm lên tay người ấy theo từng nhịp điệu bài hát trữ tình.',
        'Lắng nghe chăm chú khi người ấy xúc động kể về một giai điệu tuổi thơ.',
      ],
      highlightQuote: 'Âm nhạc cất lên tiếng lòng, và ánh nến thắp sáng sự đồng điệu của hai tâm hồn.',
    ),

    // 7. L'Aura Scent Lab (Workshop Nước hoa)
    const DateSpot(
      id: 'spot-perfume',
      name: "L'Aura Scent Lab",
      category: '🌸 WORKSHOP NƯỚC HOA ĐÔI',
      experienceType: 'TRẢI NGHIỆM MÙI HƯƠNG —',
      area: 'Thanh Khê',
      cost: 390000,
      costDisplay: '390K',
      distance: '2.5 km',
      fitScore: 93,
      tags: ['🎨 Workshop trải nghiệm', '💖 Vibe lãng mạn', '🌙 Nơi yên tĩnh', '📷 Thích chụp ảnh'],
      activityTitle: 'Tự pha chế mùi hương nước hoa độc bản cho nhau',
      timeSlotLabel: 'TRẢI NGHIỆM TINH TẾ BUỔI CHIỀU',
      aiNote: "L'Aura Scent Lab — tự tay chọn nốt hương ngọt ngào và dán nhãn thông điệp bí mật gửi người ấy.",
      secretIdea: 'Đặt tên cho chai nước hoa bằng ngày hai bạn lần đầu gặp gỡ.',
      iconEmoji: '🧪',
      gradientColors: [Color(0xFFE8B4B8), Color(0xFFC08081), Color(0xFF674B57)],
      heroImageUrl: 'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?w=800&q=80',
      imageAsset: 'assets/images/spot_perfume.jpg',
      galleryImages: [
        'assets/images/spot_perfume.jpg',
        'assets/images/spot_pottery.jpg',
        'assets/images/spot_bistro.jpg',
      ],
      fullAddress: '78 Nguyễn Tri Phương, Thanh Khê, Đà Nẵng',
      description:
          'Không gian phòng thí nghiệm mùi hương đầy nghệ thuật, nơi hai bạn được hướng dẫn khám phá hơn 40 tinh dầu tự nhiên và tự tay phối trộn ra chai nước hoa kỷ niệm mang dấu ấn riêng của hai người.',
      menuItems: [
        {'name': 'Workshop chế tác 2 chai nước hoa 30ml', 'price': '340K'},
        {'name': '+ Hộp quà nhung & thiệp viết tay', 'price': '50K'},
      ],
      aiReasons: [
        'Một món quà lưu giữ kỷ niệm cực kỳ ý nghĩa và độc bản.',
        'Không gian thanh lịch, thơm ngát thảo mộc giúp thư giãn tinh thần.',
      ],
      activities: [
        'Khám phá bảng mùi với hơn 40 tầng hương thơm tự nhiên: hoa hồng Grasse, gỗ đàn hương, cam bergamot.',
        'Tự tay nhỏ từng giọt tinh dầu phối trộn nên công thức mùi hương độc bản phản ánh tính cách của người ấy.',
        'Dán nhãn tên và viết lời nhắn bí mật vào hộp quà nhung trao tặng đối phương.',
      ],
      conversationTopics: [
        '“Mùi hương nào khiến em/anh cảm thấy an toàn và được che chở nhất?”',
        '“Trong mắt em/anh, đối phương giống như một loài hoa hay nốt hương nào?”',
      ],
      caringTips: [
        'Để người ấy ngửi thử mùi hương trên mu bàn tay bạn để cả hai cùng cảm nhận sự hòa hợp.',
        'Tự tay xịt thử nhát hương đầu tiên lên cổ tay người ấy sau khi hoàn thiện chai nước hoa.',
      ],
      highlightQuote: 'Mùi hương là ký ức vô hình nhưng in đậm nhất trong trái tim người đang yêu.',
    ),

    // 8. Chợ Đêm Helio & Phố Ăn Vặt
    const DateSpot(
      id: 'spot-streetfood',
      name: 'Chợ Đêm Helio & Phố Ăn Vặt',
      category: '🍢 ĂN VẶT ĐƯỜNG PHỐ',
      experienceType: 'ẨM THỰC ĐƯỜNG PHỐ —',
      area: 'Hải Châu',
      cost: 150000,
      costDisplay: '150K',
      distance: '2.0 km',
      fitScore: 91,
      tags: ['🍜 Ăn vặt đường phố', '🚗 Không đi xa', '🍰 Thích đồ ngọt'],
      activityTitle: 'Cùng nhau càn quét món ngon đường phố',
      timeSlotLabel: 'BUỔI TỐI NHỘN NHỊP & RÔM RẢ',
      aiNote: 'Chợ đêm rực rỡ ánh đèn lồng, tha hồ thử bánh tráng nướng, nem lụi, kem bơ béo ngậy.',
      secretIdea: 'Đút cho người ấy thử muỗng kem bơ dừa sáp đầu tiên.',
      iconEmoji: '🍢',
      gradientColors: [Color(0xFFFF9A8B), Color(0xFFFF6A88), Color(0xFFFF99AC)],
      heroImageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
      imageAsset: 'assets/images/spot_streetfood.jpg',
      galleryImages: [
        'assets/images/spot_streetfood.jpg',
        'assets/images/spot_dessert.jpg',
        'assets/images/spot_acoustic.jpg',
      ],
      fullAddress: 'Đường 2 Tháng 9, Hòa Cường Nam, Hải Châu, Đà Nẵng',
      description:
          'Khu chợ đêm lớn và đẹp nhất Đà Nẵng với hàng trăm gian hàng ẩm thực hấp dẫn, âm nhạc sôi động và không khí trẻ trung đầy năng lượng.',
      menuItems: [
        {'name': 'Combo bánh tráng nướng & xiên que nướng', 'price': '90K'},
        {'name': '+ 2 Ly kem bơ sầu riêng Cô Vân', 'price': '60K'},
      ],
      aiReasons: [
        'Thích hợp với các cặp đôi mê ăn vặt đường phố ngon - bổ - rẻ.',
        'Không khí vui tươi, gắn kết tự nhiên không gò bó.',
      ],
      activities: [
        'Cùng tay trong tay dạo quanh các gian hàng rực rỡ sắc màu và thơm nức mùi đồ ăn nướng than hoa.',
        'Thưởng thức combo bánh tráng nướng giòn rụm, xiên que đậm vị và tráng miệng bằng kem bơ béo ngậy.',
        'Tham gia một trò chơi ném bóng hoặc bắn cung trúng gấu bông để tặng người ấy.',
      ],
      conversationTopics: [
        '“Ngày bé em/anh thích được dẫn đi chơi chợ đêm hay thích được mua món quà gì nhất?”',
        '“Những khoảnh khắc giản dị như thế này có làm em/anh cảm thấy hạnh phúc không?”',
      ],
      caringTips: [
        'Chủ động đi phía làn đường bên ngoài để che chắn cho người ấy khi phố chợ đông đúc.',
        'Cầm hết đồ đạc và cốc nước cho người ấy rảnh tay thưởng thức các món ăn vặt.',
      ],
      highlightQuote: 'Hạnh phúc đôi khi chỉ là cùng nhau ăn những món giản dị giữa dòng người tấp nập.',
    ),

    // 9. Art & Wine Painting Studio
    const DateSpot(
      id: 'spot-painting',
      name: 'Art & Wine Painting Studio',
      category: '🎨 VẼ TRANH & RƯỢU VANG',
      experienceType: 'WORKSHOP NGHỆ THUẬT —',
      area: 'Hải Châu',
      cost: 320000,
      costDisplay: '320K',
      distance: '1.4 km',
      fitScore: 90,
      tags: ['🎨 Workshop trải nghiệm', '🍷 Rooftop & Vang', '💖 Vibe lãng mạn', '📷 Thích chụp ảnh'],
      activityTitle: 'Cùng vẽ tranh hoàng hôn và nhâm nhi vang trắng',
      timeSlotLabel: 'CHIỀU TÀ ĐẦY CẢM XÚC',
      aiNote: 'Không cần biết vẽ trước, họa sĩ sẽ hướng dẫn hai bạn vẽ bức tranh đôi kỷ niệm mang về.',
      secretIdea: 'Vẽ một chi tiết bí mật nhỏ chỉ riêng hai người hiểu lên góc tranh.',
      iconEmoji: '🎨',
      gradientColors: [Color(0xFFF39060), Color(0xFFC45A65), Color(0xFF6B3A5A)],
      heroImageUrl: 'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=800&q=80',
      imageAsset: 'assets/images/spot_painting.jpg',
      galleryImages: [
        'assets/images/spot_painting.jpg',
        'assets/images/spot_pottery.jpg',
        'assets/images/spot_bistro.jpg',
      ],
      fullAddress: '15 Lê Hồng Phong, Hải Châu, Đà Nẵng',
      description:
          'Không gian xưởng vẽ tranh ấm áp ngập tràn ánh đèn vàng mộc mạc. Hai bạn vừa vẽ tranh, vừa thưởng thức ly vang thơm dịu và trò chuyện thư thái.',
      menuItems: [
        {'name': 'Vé vẽ tranh 2 người (toàn bộ họa phẩm + toan tranh)', 'price': '260K'},
        {'name': '+ 2 Ly vang trắng ướp lạnh & phô mai', 'price': '60K'},
      ],
      aiReasons: [
        'Bức tranh hoàn thiện là món quà kỷ niệm vô giá hai bạn tự tạo ra.',
        'Không gian nghệ thuật tinh tế, riêng tư và giàu cảm xúc.',
      ],
      activities: [
        'Ngồi cạnh nhau bên hai giá vẽ gỗ, chuẩn bị cọ và pha những tông màu hoàng hôn ấm áp.',
        'Dưới sự hướng dẫn tận tình của họa sĩ, cùng tạo nên bức tranh đôi ghép lại thành một khung cảnh hoàn chỉnh.',
        'Thưởng thức ly vang trắng thơm mát trong lúc chờ lớp sơn dầu khô tự nhiên.',
      ],
      conversationTopics: [
        '“Nếu vẽ nên bức tranh tương lai 5 năm nữa của hai đứa mình, em/anh sẽ dùng màu sắc chủ đạo nào?”',
        '“Điều gì ở em/anh làm cho cuộc sống của đối phương trở nên rực rỡ và nhiều sắc màu hơn?”',
      ],
      caringTips: [
        'Khen ngợi bức tranh của người ấy một cách chân thành và đáng yêu, không ngần ngại chấm nhẹ chút màu lên chóp mũi đối phương.',
        'Ký tên chung của hai bạn vào góc phải bức tranh kỷ niệm mang về.',
      ],
      highlightQuote: 'Mỗi nét cọ là một nhịp đập, cùng nhau vẽ nên câu chuyện tình yêu đầy sắc màu.',
    ),

    // 10. Le Comptoir Steak & Wine
    const DateSpot(
      id: 'spot-lecomptoir',
      name: 'Le Comptoir Steak & Wine',
      category: '🍷 BÍT TẾT & VANG THƯỢNG HẠNG',
      experienceType: 'ẨM THỰC CAO CẤP —',
      area: 'Sơn Trà',
      cost: 480000,
      costDisplay: '480K',
      distance: '1.9 km',
      fitScore: 96,
      tags: ['💖 Vibe lãng mạn', '🍷 Rooftop & Vang', '🌙 Nơi yên tĩnh', '🔊 Tránh nơi ồn ào'],
      activityTitle: 'Bữa tối bít tết bò mềm thượng hạng bên ánh nến',
      timeSlotLabel: 'DÀNH CHO NGÀY KỶ NIỆM ĐẶC BIỆT',
      aiNote: 'Le Comptoir — nhà hàng chuẩn Pháp nổi tiếng nhất Đà Nẵng về độ lãng mạn và tinh tế.',
      secretIdea: 'Đặt bàn trước ở góc sân vườn để có không gian hoàn toàn riêng tư.',
      iconEmoji: '🥩',
      gradientColors: [Color(0xFF9E3D3F), Color(0xFF60232E), Color(0xFF2C1018)],
      heroImageUrl: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
      imageAsset: 'assets/images/spot_bistro.jpg',
      galleryImages: [
        'assets/images/spot_bistro.jpg',
        'assets/images/spot_rooftop.jpg',
        'assets/images/spot_dessert.jpg',
      ],
      fullAddress: '16 Chế Lan Viên, Bắc Mỹ An, Ngũ Hành Sơn, Đà Nẵng',
      description:
          'Không gian cổ điển châu Âu ấm áp với ánh nến vàng, phục vụ những lát bít tết bò nướng hoàn hảo cùng các dòng vang chọn lọc từ nước Pháp.',
      menuItems: [
        {'name': 'Phần Bít tết bò Angus thượng hạng 2 người', 'price': '400K'},
        {'name': '+ 2 Ly vang đỏ Bordeaux', 'price': '80K'},
      ],
      aiReasons: [
        'Rất thích hợp cho các dịp kỷ niệm lớn hoặc sinh nhật quan trọng.',
        'Dịch vụ chu đáo, riêng tư tuyệt đối, món ăn đẳng cấp.',
      ],
    ),

    // 11. Brilliant Top Bar Sông Hàn
    const DateSpot(
      id: 'spot-brilliant',
      name: 'Brilliant Top Bar Sông Hàn',
      category: '🍸 ROOFTOP NGẮM SÔNG HÀN',
      experienceType: 'ROOFTOP & ÂM NHẠC —',
      area: 'Hải Châu',
      cost: 260000,
      costDisplay: '260K',
      distance: '0.8 km',
      fitScore: 94,
      tags: ['🍷 Rooftop & Vang', '🌊 View biển', '🎵 Nhạc acoustic', '💖 Vibe lãng mạn'],
      activityTitle: 'Ngắm dòng sông Hàn về đêm từ tầng thượng',
      timeSlotLabel: 'KHI CẦU RỒNG BẬT SÁNG',
      aiNote: 'Tầm nhìn trực diện cầu Rồng và cầu quay sông Hàn, gió sông mát rượi.',
      secretIdea: 'Đến vào tối thứ 7 hoặc chủ nhật để xem cầu Rồng phun lửa từ trên cao.',
      iconEmoji: '🌉',
      gradientColors: [Color(0xFF5B6990), Color(0xFF384364), Color(0xFF1E2238)],
      heroImageUrl: 'https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=800&q=80',
      imageAsset: 'assets/images/spot_rooftop.jpg',
      galleryImages: [
        'assets/images/spot_rooftop.jpg',
        'assets/images/spot_acoustic.jpg',
        'assets/images/spot_bistro.jpg',
      ],
      fullAddress: '162 Bạch Đằng, Hải Châu, Đà Nẵng',
      description:
          'Rooftop bar thoáng đãng bên bờ sông Hàn, địa điểm hoàn hảo để thưởng thức đồ uống ngon và chiêm ngưỡng toàn cảnh thành phố về đêm.',
      menuItems: [
        {'name': '2 Ly Cocktail đặc trưng Đà Nẵng Hoàng Hôn', 'price': '210K'},
        {'name': '+ Snack khoai tây chiên giòn', 'price': '50K'},
      ],
      aiReasons: [
        'Vị trí đắc địa ngay trung tâm, ngắm trọn sông Hàn lung linh.',
        'Mức giá rất hợp lý cho trải nghiệm rooftop view đẹp.',
      ],
    ),

    // 12. Wonderlust Glasshouse Cafe
    const DateSpot(
      id: 'spot-wonderlust',
      name: 'Wonderlust Glasshouse Cafe',
      category: '☕ CAFE NHÀ KÍNH THƠ MỘNG',
      experienceType: 'CAFE SỐNG ẢO & BÁNH —',
      area: 'Hải Châu',
      cost: 95000,
      costDisplay: '95K',
      distance: '1.0 km',
      fitScore: 92,
      tags: ['☕ Quán cafe ấm cúng', '📷 Thích chụp ảnh', '🍰 Thích đồ ngọt', '🌙 Nơi yên tĩnh'],
      activityTitle: 'Nhâm nhi cafe và chụp những tấm ảnh đôi thật xinh',
      timeSlotLabel: 'BUỔI SÁNG HOẶC ĐẦU GIỜ CHIỀU',
      aiNote: 'Nhà kính tràn ngập ánh sáng tự nhiên và cây xanh, góc nào lên hình cũng trong trẻo.',
      secretIdea: 'Chụp cho người ấy bức ảnh ngược sáng bên vòm kính giếng trời.',
      iconEmoji: '🌿',
      gradientColors: [Color(0xFFA8C3A0), Color(0xFF7E9F76), Color(0xFF4A6644)],
      heroImageUrl: 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=800&q=80',
      imageAsset: 'assets/images/spot_dessert.jpg',
      galleryImages: [
        'assets/images/spot_dessert.jpg',
        'assets/images/spot_pottery.jpg',
        'assets/images/spot_bistro.jpg',
      ],
      fullAddress: '96 Trần Phú, Hải Châu, Đà Nẵng',
      description:
          'Khu tổ hợp cafe nhà kính trắng tinh khôi với giếng trời ngập nắng, nhiều cây xanh nhiệt đới và những món bánh ngọt nướng mới mỗi ngày.',
      menuItems: [
        {'name': '2 Phần Cafe muối & Trà đào cam sả', 'price': '65K'},
        {'name': '+ Bánh sừng bò nướng bơ tỏi', 'price': '30K'},
      ],
      aiReasons: [
        'Góc chụp hình cực đẹp, ánh sáng tôn da cho các bạn gái.',
        'Bánh ngọt ngon, không gian nhẹ nhàng không xô bồ.',
      ],
    ),

    // 13. Sound Cafe Live Acoustic
    const DateSpot(
      id: 'spot-soundcafe',
      name: 'Sound Cafe Live Acoustic',
      category: '🎵 CAFE ACOUSTIC CUỐI TUẦN',
      experienceType: 'NHẠC SỐNG ACOUSTIC —',
      area: 'Hải Châu',
      cost: 140000,
      costDisplay: '140K',
      distance: '1.3 km',
      fitScore: 93,
      tags: ['🎵 Nhạc acoustic', '☕ Quán cafe ấm cúng', '💖 Vibe lãng mạn'],
      activityTitle: 'Lắng nghe những bản tình ca mộc mạc',
      timeSlotLabel: 'TỐI THỨ 6, THỨ 7 VÀ CHỦ NHẬT',
      aiNote: 'Ban nhạc live acoustic mộc mạc, những bản hit V-pop nhẹ nhàng chạm đến cảm xúc.',
      secretIdea: 'Gửi lời nhắn bí mật qua MC nhờ ban nhạc gửi tặng người ấy bài hát.',
      iconEmoji: '🎸',
      gradientColors: [Color(0xFFDE935F), Color(0xFFB56A3D), Color(0xFF6B3A1C)],
      heroImageUrl: 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=800&q=80',
      imageAsset: 'assets/images/spot_acoustic.jpg',
      galleryImages: [
        'assets/images/spot_acoustic.jpg',
        'assets/images/spot_bistro.jpg',
        'assets/images/spot_rooftop.jpg',
      ],
      fullAddress: '150 Lê Đình Dương, Hải Châu, Đà Nẵng',
      description:
          'Không gian mộc mạc đậm chất nghệ sĩ với tiếng đàn guitar thùng và giọng hát mộc ấm áp, thích hợp cho những cặp đôi thích hòa mình vào âm nhạc.',
      menuItems: [
        {'name': '2 Ly Nước uống kèm vé đêm nhạc', 'price': '110K'},
        {'name': '+ Đĩa hướng dương & hạt sen sấy', 'price': '30K'},
      ],
      aiReasons: [
        'Đúng sở thích nghe nhạc acoustic sống động nhưng gần gũi.',
        'Chi phí rất mềm, không gian ấm cúng.',
      ],
    ),

    // 14. Bếp Cuốn Ẩm Thực Đà Nẵng
    const DateSpot(
      id: 'spot-bepcuon',
      name: 'Bếp Cuốn Ẩm Thực Đà Nẵng',
      category: '🍜 ẨM THỰC VIỆT ẤM CÚNG',
      experienceType: 'ẨM THỰC VIỆT —',
      area: 'Ngũ Hành Sơn',
      cost: 160000,
      costDisplay: '160K',
      distance: '1.6 km',
      fitScore: 90,
      tags: ['🍜 Ăn vặt đường phố', '🚗 Không đi xa', '☕ Quán cafe ấm cúng'],
      activityTitle: 'Cùng nhau thưởng thức mâm cuốn đặc sản',
      timeSlotLabel: 'BỮA TRƯA HOẶC TỐI THÂN MẬT',
      aiNote: 'Quán decor gạch bông xưa ấm áp, đồ ăn chuẩn vị miền Trung, hợp khẩu vị cả hai.',
      secretIdea: 'Tự tay cuốn một cuốn bánh tráng thịt heo thật ngon đút cho đối phương.',
      iconEmoji: '🥢',
      gradientColors: [Color(0xFFE89A5F), Color(0xFFC46A36), Color(0xFF7A3E1E)],
      heroImageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80',
      imageAsset: 'assets/images/spot_streetfood.jpg',
      galleryImages: [
        'assets/images/spot_streetfood.jpg',
        'assets/images/spot_bistro.jpg',
        'assets/images/spot_dessert.jpg',
      ],
      fullAddress: '54 Nguyễn Văn Thoại, Ngũ Hành Sơn, Đà Nẵng',
      description:
          'Không gian hoài niệm mộc mạc với mẹt cuốn đa dạng từ bánh tráng cuốn thịt heo hai đầu da đến bánh xèo giòn rụm và nước chấm mắm nêm đậm đà.',
      menuItems: [
        {'name': 'Mẹt cuốn bánh tráng đặc biệt 2 người', 'price': '130K'},
        {'name': '+ 2 Ly trà sâm dứa hạt chia', 'price': '30K'},
      ],
      aiReasons: [
        'Ẩm thực thơm ngon, không gian ấm cúng thân mật dễ gần.',
        'Món ăn cùng cuốn giúp hai bạn gắn kết tự nhiên.',
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

    // Chuẩn hóa preferences sạch (loại bỏ emoji)
    final cleanPrefs = selectedPreferences.map((p) {
      return p.replaceAll(RegExp(r'[^\w\sÀ-ỹ]'), '').trim().toLowerCase();
    }).where((p) => p.isNotEmpty).toList();

    final wishLower = customWish.trim().toLowerCase();

    // Tính điểm phù hợp cho từng quán
    final scored = <DateSpot>[];

    for (final spot in spots) {
      int score = spot.fitScore;
      int matchCount = 0;
      final spotTagsClean = spot.tags.map((t) => t.replaceAll(RegExp(r'[^\w\sÀ-ỹ]'), '').trim().toLowerCase()).toList();
      final spotNameClean = spot.name.toLowerCase();
      final spotDescClean = spot.description.toLowerCase();
      final spotCategoryClean = spot.category.toLowerCase();

      // 1. Kiểm tra ngân sách
      bool budgetOk = true;
      if (spot.cost <= maxBudgetVnd) {
        score += 5;
        matchCount++;
      } else if (spot.cost <= maxBudgetVnd * 1.25) {
        score -= 2; // Vượt nhẹ ngân sách, cho phép nếu các tiêu chí khác rất khớp
      } else {
        // Vượt quá ngân sách hơn 25%
        budgetOk = false;
        score -= 25;
      }

      // 2. So khớp sở thích của user
      for (final pref in cleanPrefs) {
        bool prefMatched = false;
        for (final tag in spotTagsClean) {
          if (tag.contains(pref) || pref.contains(tag)) {
            score += 8;
            matchCount += 2;
            prefMatched = true;
            break;
          }
        }
        if (!prefMatched) {
          if (spotNameClean.contains(pref) || spotDescClean.contains(pref) || spotCategoryClean.contains(pref)) {
            score += 5;
            matchCount++;
          }
        }
      }

      // 3. So khớp bối cảnh (Occasion)
      if (occasionId == 'anniversary') {
        if (spot.tags.any((t) => t.contains('lãng mạn') || t.contains('Lãng mạn'))) {
          score += 6;
          matchCount++;
        }
        if (spot.tags.any((t) => t.contains('Workshop') || t.contains('workshop'))) {
          score += 4;
        }
      } else if (occasionId == 'birthday') {
        if (spot.tags.any((t) => t.contains('ngọt') || t.contains('Rooftop'))) {
          score += 6;
          matchCount++;
        }
      } else if (occasionId == 'weekend_chill' || occasionId == 'just_because') {
        if (spot.tags.any((t) => t.contains('yên tĩnh') || t.contains('biển') || t.contains('cafe') || t.contains('ăn vặt'))) {
          score += 5;
          matchCount++;
        }
      }

      // 4. So khớp mong muốn tùy chỉnh (Custom wish)
      if (wishLower.isNotEmpty) {
        final keywords = ['rooftop', 'biển', 'gốm', 'nước hoa', 'yên tĩnh', 'vang', 'rượu', 'acoustic', 'đồ ngọt', 'bánh', 'chụp ảnh', 'bít tết', 'steak', 'ăn vặt', 'hải sản', 'chill', 'cafe'];
        for (final kw in keywords) {
          if (wishLower.contains(kw)) {
            if (spotNameClean.contains(kw) || spotTagsClean.any((t) => t.contains(kw)) || spotDescClean.contains(kw) || spotCategoryClean.contains(kw)) {
              score += 15;
              matchCount += 3;
            }
          }
        }
      }

      // 5. Điều kiện lọc thực chất (Filter Out Unrelated Spots):
      // Nếu user có chọn sở thích hoặc có nhập mong muốn:
      // Quán BẮT BUỘC phải khớp ít nhất 1 tiêu chí sở thích/mong muốn và ngân sách không vượt quá đà
      if (cleanPrefs.isNotEmpty || wishLower.isNotEmpty) {
        if (matchCount < 2 && !budgetOk) {
          continue; // Bỏ qua địa điểm không liên quan
        }
        if (matchCount == 0) {
          continue; // Bỏ qua địa điểm không có bất kỳ điểm chạm nào với yêu cầu
        }
      }

      // Tạo lý do AI gợi ý động bám sát lựa chọn của người dùng
      final dynamicReasons = <String>[];
      for (final pref in selectedPreferences) {
        final clean = pref.replaceAll(RegExp(r'[^\w\sÀ-ỹ]'), '').trim();
        if (spot.tags.any((t) => t.toLowerCase().contains(clean.toLowerCase()))) {
          dynamicReasons.add('Khớp chuẩn sở thích "$clean" hai bạn đã chọn.');
        }
      }
      if (spot.cost <= maxBudgetVnd) {
        dynamicReasons.add('Chi phí ${spot.costDisplay} vừa vặn ngân sách ${maxBudgetVnd ~/ 1000}K của hai bạn.');
      }
      if (wishLower.isNotEmpty && (spotNameClean.contains(wishLower) || spotDescClean.contains(wishLower))) {
        dynamicReasons.add('Phù hợp đúng mong muốn riêng: "$customWish".');
      }
      if (dynamicReasons.isEmpty) {
        dynamicReasons.addAll(spot.aiReasons);
      }

      final clamped = score.clamp(78, 99);
      scored.add(DateSpot(
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
        imageAsset: spot.imageAsset,
        galleryImages: spot.galleryImages,
        fullAddress: spot.fullAddress,
        description: spot.description,
        menuItems: spot.menuItems,
        aiReasons: dynamicReasons.take(2).toList(),
      ));
    }

    // Nếu bộ lọc quá chặt khiến không có quán nào, trả về top 3 quán gần nhất
    if (scored.isEmpty) {
      return spots.take(4).toList();
    }

    // Sắp xếp điểm phù hợp từ cao xuống thấp
    scored.sort((a, b) => b.fitScore.compareTo(a.fitScore));
    return scored;
  }
}
