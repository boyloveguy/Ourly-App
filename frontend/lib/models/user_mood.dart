class UserMood {
  final String id;
  final String emoji;
  final String label;
  final String description;
  final String partnerHint;
  final String note;
  final DateTime? createdAt;

  const UserMood({
    required this.id,
    required this.emoji,
    required this.label,
    required this.description,
    required this.partnerHint,
    this.note = '',
    this.createdAt,
  });

  static const List<UserMood> defaultMoods = [
    UserMood(
      id: 'happy',
      emoji: '🥰',
      label: 'Hạnh phúc & Yêu đời',
      description: 'Tràn đầy năng lượng, rất nhớ người ấy',
      partnerHint: 'Người ấy đang ngập tràn hạnh phúc và nhớ bạn! Hãy gửi một tin nhắn ngọt ngào hoặc nụ hôn gió nhé 💕',
      createdAt: null as dynamic,
    ),
    UserMood(
      id: 'calm',
      emoji: '☕',
      label: 'Bình yên & Thảnh thơi',
      description: 'Một ngày êm dịu, muốn thảnh thơi dạo phố',
      partnerHint: 'Người ấy đang có một ngày bình yên. Rủ người ấy cùng đi dạo phố hoặc ngồi cafe ngắm hoàng hôn nhé ☕',
      createdAt: null as dynamic,
    ),
    UserMood(
      id: 'need_hug',
      emoji: '🥺',
      label: 'Cần được vỗ về',
      description: 'Hơi mệt mỏi một chút, muốn được ôm',
      partnerHint: 'Người ấy đang cảm thấy hơi mệt mỏi và cần một cái ôm. Hãy gọi điện hoặc chạy qua ôm người ấy một cái nhé 🥺',
      createdAt: null as dynamic,
    ),
    UserMood(
      id: 'busy',
      emoji: '💼',
      label: 'Bận rộn & Căng thẳng',
      description: 'Deadline ngập tràn, cần tiếp thêm sức mạnh',
      partnerHint: 'Người ấy đang bận rộn với nhiều công việc. Gửi một ly trà sữa hoặc lời nhắn "Cố lên em/anh yêu!" nhé 💼',
      createdAt: null as dynamic,
    ),
    UserMood(
      id: 'hungry',
      emoji: '🍕',
      label: 'Đói bụng & Thèm ăn',
      description: 'Muốn được dắt đi ăn món ngon',
      partnerHint: 'Bụng người ấy đang réo rắt thèm đồ ngon rồi đó! Dẫn người ấy đi ăn món khoái khẩu tối nay ngay thôi 🍕',
      createdAt: null as dynamic,
    ),
    UserMood(
      id: 'sad',
      emoji: '🌧️',
      label: 'Hơi buồn một chút',
      description: 'Cần một cái nắm tay ấm áp & lắng nghe',
      partnerHint: 'Tâm trạng người ấy đang chùng xuống một chút. Hãy ở bên cạnh, lắng nghe và nắm chặt tay người ấy nhé 🌧️',
      createdAt: null as dynamic,
    ),
  ];
}
