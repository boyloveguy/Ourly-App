import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../widgets/romantic_effects.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> options;
  String? selectedOption;

  ChatMessage({
    required this.text,
    required this.isUser,
    List<String>? options,
    this.selectedOption,
    DateTime? timestamp,
  })  : options = options ?? [],
        timestamp = timestamp ?? DateTime.now();
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _apiService = ApiService();
  final _voiceService = VoiceService();

  bool _isTyping = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  int? _speakingMessageIndex;
  bool _autoSpeakEnabled = true;
  bool _isLoadingHistory = true;

  final List<ChatMessage> _messages = [];

  final List<String> _quickSuggestions = [
    '🍷 Gợi ý buổi hẹn lãng mạn cuối tuần',
    '🎁 Ý tưởng bất ngờ làm người ấy vui',
    '💐 Gợi ý quà tặng kỷ niệm ý nghĩa',
    '💬 Cách làm lành khi người ấy im lặng',
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await _apiService.getChatHistory();
    if (!mounted) return;

    final user = _apiService.currentUser;
    final userName = user?.nickname.isNotEmpty == true ? user!.nickname : 'bạn';

    if (history.isEmpty) {
      _messages.clear();
      _messages.add(
        ChatMessage(
          text: 'Chào $userName! 🪽 Mình là Quân sư Tình yêu Ourly.\n\n'
              'Mình ở đây để giúp hai bạn gắn kết hơn, gợi ý những buổi hẹn hò khó quên, chuẩn bị bất ngờ ngọt ngào hoặc lắng nghe những tâm tư của bạn.\n\n'
              'Bạn có thể gõ phím, chọn nhanh các gợi ý bên dưới hoặc nhấn Micro 🎙️ để trò chuyện cùng mình nhé! 💕',
          isUser: false,
          options: [
            '🍷 Lên lịch hẹn hò lãng mạn',
            '🎁 Tư vấn quà tặng bất ngờ',
            '💬 Mẹo mở lời bắt chuyện',
            '🕊️ Cách làm lành khi người ấy dỗi',
          ],
        ),
      );
    } else {
      _messages.clear();
      for (final m in history) {
        final optionsList = (m['options'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        _messages.add(
          ChatMessage(
            text: m['text']?.toString() ?? '',
            isUser: m['isUser'] == true,
            options: optionsList,
            selectedOption: m['selectedOption']?.toString(),
            timestamp: DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
          ),
        );
      }
    }

    setState(() => _isLoadingHistory = false);
    _scrollToBottom();
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.delete_sweep_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Xóa lịch sử chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Bạn có muốn xóa toàn bộ lịch sử trò chuyện với Quân sư không?\n\nSau khi xóa, cuộc trò chuyện sẽ bắt đầu lại từ đầu.',
          style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _apiService.clearChatHistory();
              _loadChatHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Xóa ngay'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- VOICE SPEECH-TO-TEXT (STT) ---
  void _toggleListening() {
    if (_isListening) {
      _voiceService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      // If AI is speaking, stop it when user wants to talk
      if (_isSpeaking) {
        _voiceService.stopSpeaking();
        setState(() {
          _isSpeaking = false;
          _speakingMessageIndex = null;
        });
      }

      final started = _voiceService.startListening(
        onStart: () {
          setState(() {
            _isListening = true;
          });
        },
        onResult: (text, isFinal) {
          setState(() {
            _textController.text = text;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
          });
          // If final sentence detected and not empty, can optionally let user press send
        },
        onEnd: () {
          setState(() {
            _isListening = false;
          });
        },
        onError: (err) {
          setState(() {
            _isListening = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Chưa thể nhận diện giọng nói: $err'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      );

      if (!started && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trình duyệt chưa hỗ trợ hoặc bạn chưa cấp quyền Micro.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // --- VOICE TEXT-TO-SPEECH (TTS) ---
  void _toggleSpeakMessage(int index, String text) {
    if (_speakingMessageIndex == index && _isSpeaking) {
      _voiceService.stopSpeaking();
      setState(() {
        _isSpeaking = false;
        _speakingMessageIndex = null;
      });
    } else {
      _voiceService.stopSpeaking();
      _voiceService.speak(
        text,
        onStart: () {
          setState(() {
            _isSpeaking = true;
            _speakingMessageIndex = index;
          });
        },
        onEnd: () {
          setState(() {
            _isSpeaking = false;
            _speakingMessageIndex = null;
          });
        },
        onError: (_) {
          setState(() {
            _isSpeaking = false;
            _speakingMessageIndex = null;
          });
        },
      );
    }
  }

  Future<void> _sendMessage([String? promptText]) async {
    final query = (promptText ?? _textController.text).trim();
    if (query.isEmpty) return;

    if (_isListening) {
      _voiceService.stopListening();
      _isListening = false;
    }

    if (_isSpeaking) {
      _voiceService.stopSpeaking();
      _isSpeaking = false;
      _speakingMessageIndex = null;
    }

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: query, isUser: true));
      _isTyping = true;
    });

    _scrollToBottom();

    // Prepare conversation history
    final history = _messages
        .take(_messages.length - 1)
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    try {
      final res = await _apiService.chatWithAdvisor(
        message: query,
        history: history,
      );

      if (!mounted) return;
      final reply = res['reply'] as String? ?? _generateAIResponse(query);
      final followUps = (res['suggestedFollowUps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final options = (res['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          _generateAIOptions(query);

      final newMsgIndex = _messages.length;
      setState(() {
        _messages.add(ChatMessage(
          text: reply,
          isUser: false,
          options: options,
        ));
        _isTyping = false;
        if (followUps.isNotEmpty) {
          _quickSuggestions.clear();
          _quickSuggestions.addAll(followUps);
        }
      });
      _scrollToBottom();

      // Auto-read response if enabled
      if (_autoSpeakEnabled) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _toggleSpeakMessage(newMsgIndex, reply);
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      final reply = _generateAIResponse(query);
      final options = _generateAIOptions(query);
      final newMsgIndex = _messages.length;
      setState(() {
        _messages.add(ChatMessage(
          text: reply,
          isUser: false,
          options: options,
        ));
        _isTyping = false;
      });
      _scrollToBottom();

      if (_autoSpeakEnabled) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _toggleSpeakMessage(newMsgIndex, reply);
          }
        });
      }
    }
  }

  String _generateAIResponse(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('hẹn') || lower.contains('cuối tuần') || lower.contains('đi đâu')) {
      return '✨ **Ý tưởng hẹn hò ngọt ngào cuối tuần này cho hai bạn:**\n\n'
          '1. **Chiều tà (17:30):** Dạo bước ngắm hoàng hôn bên bờ biển, cùng uống nước dừa và trò chuyện về một tuần vừa qua.\n'
          '2. **Tối (19:00):** Cùng thưởng thức món ăn vặt đường phố hoặc quán nướng ấm cúng hai người đều mê.\n'
          '3. **Đêm (20:30):** Ghé một quán cafe acoustic nhạc nhẹ, lắng nghe giai điệu yêu thích trong không gian mộc mạc.\n\n'
          '💡 *Mẹo của Quân sư:* Hãy chuẩn bị trước một câu hỏi sâu lắng như: "Khoảnh khắc nào trong tuần này làm em/anh thấy ấm lòng nhất?" 💕';
    }

    if (lower.contains('bất ngờ') || lower.contains('surprise')) {
      return '🎁 **Bí kíp tạo bất ngờ khiến người ấy tan chảy:**\n\n'
          '• **Món quà bí mật:** Tạo một thẻ "Kế hoạch bất ngờ" ngay trong Ourly (chỉ mình bạn thấy) để lên kế hoạch trước.\n'
          '• **Bức thư tay nhỏ:** Viết một mảnh giấy note để trong túi áo khoác hoặc ví của người ấy với dòng chữ: "Chúc em một ngày ngọt ngào, có anh luôn ở đây."\n'
          '• **Giao đồ ăn yêu thích bất ngờ:** Đặt đúng món trà sữa ít đường hoặc món ăn vặt người ấy hay nhắc lúc người ấy đang bận rộn.\n\n'
          'Sự quan tâm chân thành từ những chi tiết nhỏ luôn có sức mạnh lớn nhất! ✨';
    }

    if (lower.contains('quà') || lower.contains('kỷ niệm')) {
      return '💐 **Gợi ý quà tặng kỷ niệm tinh tế & ý nghĩa:**\n\n'
          '1. **Album ảnh kỷ niệm thu nhỏ:** In 10 bức ảnh đẹp nhất của hai bạn kèm chú thích từng kỷ niệm đáng nhớ.\n'
          '2. **Hương thơm quen thuộc:** Một lọ nến thơm mùi gỗ ấm hoặc tinh dầu hai bạn cùng thích khi ở cạnh nhau.\n'
          '3. **Một trải nghiệm chung:** Vé xem một đêm nhạc hoặc workshop làm gốm/vẽ tranh cùng nhau.\n\n'
          'Nhớ kèm theo một bó hoa nhỏ và lời chúc chân thành từ trái tim nhé! 🌷';
    }

    if (lower.contains('giận') || lower.contains('im lặng') || lower.contains('cãi nhau') || lower.contains('làm lành')) {
      return '🕊️ **Quân sư chia sẻ 3 bước hóa giải im lặng & giận dỗi:**\n\n'
          '1. **Hạ cái tôi xuống:** Mục tiêu không phải là "ai thắng ai thua", mà là bảo vệ tình cảm của hai bạn.\n'
          '2. **Hành động quan tâm thầm lặng:** Đừng ép người ấy nói ngay nếu đang căng thẳng. Hãy mang cho người ấy một cốc nước ấm hoặc món ăn vặt yêu thích.\n'
          '3. **Mở lời chân thành:** Thử nhắn tin nhẹ nhàng: "Anh/em biết vừa rồi tụi mình chưa hiểu nhau. Anh/em rất trân trọng em và muốn lắng nghe cảm xúc của em khi em sẵn sàng."\n\n'
          'Sự dịu dàng luôn là liều thuốc chữa lành tốt nhất! 🌸';
    }

    return '💖 Cảm ơn bạn đã chia sẻ với Quân sư Ourly!\n\n'
        'Tình yêu đẹp không phải là không bao giờ có sóng gió, mà là sau mỗi lần trò chuyện, hai bạn lại hiểu và thương nhau nhiều hơn.\n\n'
        'Nếu bạn cần lên lịch hẹn hò cụ thể hoặc muốn mình gợi ý thêm điều gì, cứ nhắn cho mình bất cứ lúc nào nhé! 🪽';
  }

  List<String> _generateAIOptions(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('hẹn') || lower.contains('cuối tuần') || lower.contains('đi đâu') || lower.contains('date') || lower.contains('chơi')) {
      return [
        '🥂 Lãng mạn, ấm cúng',
        '☕ Quán cafe acoustic',
        '🍜 Ăn vặt dạo phố về đêm',
        '🏕️ Dã ngoại ngoài trời',
      ];
    }
    if (lower.contains('quà') || lower.contains('kỷ niệm') || lower.contains('bất ngờ') || lower.contains('sinh nhật') || lower.contains('tặng')) {
      return [
        '🎁 Quà sinh nhật ý nghĩa',
        '💐 Kỷ niệm ngày yêu',
        '💝 Món quà bất ngờ nhỏ',
        '💵 Ngân sách dưới 500k',
        '💎 Ngân sách 500k - 1.5tr',
      ];
    }
    if (lower.contains('người yêu') || lower.contains('tán') || lower.contains('cưa') || lower.contains('crush') || lower.contains('làm quen')) {
      return [
        '👀 Mới quen, chưa nói chuyện',
        '💬 Đang nhắn tin làm quen',
        '☕ Đã từng đi cafe riêng',
        '🤝 Bạn thân muốn tiến tới',
      ];
    }
    if (lower.contains('giận') || lower.contains('im lặng') || lower.contains('cãi nhau') || lower.contains('làm lành') || lower.contains('dỗi')) {
      return [
        '📱 Người ấy im lặng không nhắn',
        '⚡ Cãi nhau vì bất đồng quan điểm',
        '⏰ Quên lịch hẹn / kỷ niệm',
        '🥺 Giận dỗi vu vơ',
      ];
    }
    return [
      '🍷 Lên lịch hẹn hò lãng mạn',
      '🎁 Gợi ý quà tặng người ấy',
      '💬 Cách mở lời tự nhiên',
      '💕 Bí kíp gắn kết tình cảm',
    ];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Quay lại',
        ),
        title: Row(
          children: [
            // Angel Robot Avatar with Heartbeat Pulse
            HeartbeatPulse(
              minScale: 0.94,
              maxScale: 1.08,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFFDFD3), Color(0xFFFDE8E4)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const WavingCupidWidget(size: 34, animate: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Quân sư Tình yêu',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Ourly AI ✨',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      CircleAvatar(radius: 3.5, backgroundColor: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'AI đàm thoại · Giọng nói tiếng Việt',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Auto-Speak Toggle Button
          IconButton(
            icon: Icon(
              _autoSpeakEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _autoSpeakEnabled ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            tooltip: _autoSpeakEnabled ? 'Tự động đọc lời khuyên: Bật' : 'Tự động đọc lời khuyên: Tắt',
            onPressed: () {
              setState(() {
                _autoSpeakEnabled = !_autoSpeakEnabled;
                if (!_autoSpeakEnabled && _isSpeaking) {
                  _voiceService.stopSpeaking();
                  _isSpeaking = false;
                  _speakingMessageIndex = null;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_autoSpeakEnabled ? '🔊 Đã bật tự động đọc lời khuyên của AI' : '🔈 Đã tắt tự động đọc'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          // Clear History Action Button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 21),
            tooltip: 'Xóa lịch sử chat',
            onPressed: _confirmClearHistory,
          ),
        ],
      ),
      body: FloatingHeartsBackground(
        count: 10,
        child: SafeArea(
          child: Column(
          children: [
            // Chat messages list
            Expanded(
              child: _isLoadingHistory
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isTyping) {
                          return _buildTypingIndicator();
                        }
                        final msg = _messages[index];
                        return _buildMessageBubble(msg, index);
                      },
                    ),
            ),

            // Quick Suggestions Carousel
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickSuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final suggestion = _quickSuggestions[idx];
                  return ActionChip(
                    label: Text(
                      suggestion,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () => _sendMessage(suggestion),
                  );
                },
              ),
            ),

            // Real-time Voice Listening Banner (STT)
            if (_isListening)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.record_voice_over_rounded, size: 20, color: Color(0xFFE11D48)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Đang lắng nghe bạn nói... 💕',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                    ),
                    const AnimatedRomanticWaveform(isSpeaking: true, color: Color(0xFFE11D48)),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _toggleListening,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Dừng',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: AppShadows.card3D,
              ),
              child: Row(
                children: [
                  // Text Input Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isListening ? const Color(0xFFE11D48) : AppColors.border,
                        ),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _isListening ? 'Đang nhận diện giọng nói...' : 'Nhắn hoặc nói cho quân sư tình yêu...',
                          hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (val) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Microphone Button (Speech-to-Text)
                  GestureDetector(
                    onTap: _toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isListening ? const Color(0xFFE11D48) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening ? const Color(0xFFE11D48) : AppColors.primary,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? const Color(0xFFE11D48) : AppColors.primary).withValues(alpha: _isListening ? 0.45 : 0.15),
                            blurRadius: _isListening ? 12 : 6,
                            spreadRadius: _isListening ? 2 : 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.white : AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send Button
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildMessageBubble(ChatMessage msg, int index) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6D55), Color(0xFFE85A42)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.0),
            boxShadow: AppShadows.button3D,
          ),
          child: Text(
            msg.text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final isThisSpeaking = _speakingMessageIndex == index && _isSpeaking;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 36),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(top: 2, right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFDE8E4),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/cupid.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: isThisSpeaking ? AppColors.primary : Colors.white,
                    width: isThisSpeaking ? 1.5 : 1.2,
                  ),
                  boxShadow: AppShadows.floating3D,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      msg.text,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // TTS Audio Action Button
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _toggleSpeakMessage(index, msg.text),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isThisSpeaking ? AppColors.primary.withValues(alpha: 0.1) : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isThisSpeaking ? AppColors.primary : AppColors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isThisSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                              size: 15,
                              color: isThisSpeaking ? AppColors.primary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isThisSpeaking ? 'Đang đọc (Bấm dừng)' : 'Nghe AI đọc 🎙️',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isThisSpeaking ? FontWeight.w600 : FontWeight.w500,
                                color: isThisSpeaking ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Interactive Option Buttons Container (when AI needs user choice/info)
                    if (msg.options.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFDCD4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('✨', style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 6),
                                Text(
                                  msg.selectedOption != null
                                      ? 'Bạn đã chọn:'
                                      : 'Bấm chọn nhanh để quân sư hiểu bạn hơn:',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: msg.options.map((option) {
                                final isSelected = msg.selectedOption == option;
                                return InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    setState(() {
                                      msg.selectedOption = option;
                                    });
                                    _sendMessage(option);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : const Color(0xFFF0B3A6),
                                        width: 1.2,
                                      ),
                                       boxShadow: isSelected
                                          ? AppShadows.pill3D
                                          : [
                                              BoxShadow(
                                                color: const Color(0xFFE85A42).withValues(alpha: 0.08),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                              const BoxShadow(
                                                color: Colors.white,
                                                offset: Offset(-1, -1),
                                                blurRadius: 2,
                                                spreadRadius: 0.5,
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected) ...[
                                          const Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                                          const SizedBox(width: 5),
                                        ],
                                        Text(
                                          option,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                            color: isSelected ? Colors.white : AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFDE8E4),
                border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5), width: 1),
              ),
              alignment: Alignment.center,
              child: ClipOval(
                child: Image.asset(
                  'assets/images/cupid.png',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Quân sư đang suy nghĩ...',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(width: 8),
                  CuteBouncingHeartsIndicator(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
