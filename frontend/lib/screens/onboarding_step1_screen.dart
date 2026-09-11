import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';
import '../models/preference.dart';
import '../widgets/romantic_effects.dart';
import '../widgets/ourly_date_picker.dart';

class OnboardingStep1Screen extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onSkipToHome;
  final VoidCallback? onBack;

  const OnboardingStep1Screen({
    super.key,
    required this.onNext,
    required this.onSkipToHome,
    this.onBack,
  });

  @override
  State<OnboardingStep1Screen> createState() => _OnboardingStep1ScreenState();
}

class _OnboardingStep1ScreenState extends State<OnboardingStep1Screen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _cityController = TextEditingController();
  final _customPrefController = TextEditingController();

  final List<Map<String, String>> _availableTags = [
    {'label': 'Ăn vặt đường phố', 'emoji': '🍜'},
    {'label': 'Bãi biển', 'emoji': '🌊'},
    {'label': 'Nhạc acoustic', 'emoji': '🎵'},
    {'label': 'Quán cafe ấm cúng', 'emoji': '☕'},
    {'label': 'Bia thủ công', 'emoji': '🍺'},
    {'label': 'Dã ngoại ngoài trời', 'emoji': '🏕️'},
  ];

  final Set<String> _selectedTags = {'Ăn vặt đường phố', 'Bãi biển', 'Quán cafe ấm cúng'};
  bool _isCustomPrefActive = false;
  bool _isLoading = false;
  String _selectedAvatar = 'M';
  final _apiService = ApiService();

  final List<String> _avatarPresets = [
    '🐱', '🐶', '🐰', '🦊', '🐻',
    '🐼', '🌸', '🥑', '☕', '🎮',
    '🎨', '🎧', '🌟', '🍀', '🍓',
    '🧸', '🐬', '💖',
  ];

  @override
  void initState() {
    super.initState();
    if (_apiService.currentUser != null) {
      if (_apiService.currentUser!.nickname.isNotEmpty) {
        _nameController.text = _apiService.currentUser!.nickname;
      }
      if (_apiService.currentUser!.avatar != null && _apiService.currentUser!.avatar!.isNotEmpty) {
        _selectedAvatar = _apiService.currentUser!.avatar!;
      } else if (_nameController.text.isNotEmpty) {
        _selectedAvatar = _nameController.text[0].toUpperCase();
      }
      if (_apiService.currentUser!.birthday != null && _apiService.currentUser!.birthday!.isNotEmpty) {
        _dobController.text = _apiService.currentUser!.birthday!;
      }
    }
  }

  Future<void> _pickBirthday() async {
    final parsed = OurlyDatePicker.parseDate(_dobController.text);
    final picked = await OurlyDatePicker.pickDate(
      context: context,
      initialDate: parsed ?? DateTime(2000, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'CHỌN NGÀY SINH CỦA BẠN',
    );
    if (picked != null) {
      setState(() {
        _dobController.text = OurlyDatePicker.formatDate(picked);
      });
    }
  }

  void _openAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        bool isPicking = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Chọn ảnh đại diện của bạn',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Chọn biểu tượng cảm xúc hoặc chữ cái đại diện cho phong cách của bạn:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),

                  // Device Image Picker Button with guaranteed Material InkWell and Feedback State
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: isPicking
                          ? null
                          : () async {
                              setModalState(() => isPicking = true);
                              try {
                                final picked = await AvatarPickerHelper.pickAvatarFromDevice();
                                if (picked != null) {
                                  setState(() => _selectedAvatar = picked);
                                  _apiService.updateCurrentUserProfile(avatar: picked);
                                  if (ctx.mounted) {
                                    Navigator.of(ctx).pop();
                                  }
                                }
                              } catch (e) {
                                debugPrint('Device avatar picker error: $e');
                              } finally {
                                if (ctx.mounted) {
                                  setModalState(() => isPicking = false);
                                }
                              }
                            },
                      child: Ink(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF0F3), Color(0xFFFFE3E8)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPicking) ...[
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Đang mở hộp thoại chọn ảnh...',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ] else ...[
                              const Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 22),
                              const SizedBox(width: 10),
                              const Text(
                                'Tải ảnh từ thiết bị (Thư viện / Camera)',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

              // Presets Grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Default initial letter chip
                  GestureDetector(
                    onTap: () {
                      final letter = _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'M';
                      setState(() => _selectedAvatar = letter);
                      _apiService.updateCurrentUserProfile(avatar: letter);
                      Navigator.of(ctx).pop();
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.avatarBlueBg,
                        border: Border.all(
                          color: _selectedAvatar == (_nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'M')
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'M',
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontStyle: FontStyle.italic,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.avatarBlueText,
                        ),
                      ),
                    ),
                  ),

                  // Emoji list
                  ..._avatarPresets.map((emoji) {
                    final isSel = _selectedAvatar == emoji;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedAvatar = emoji);
                        _apiService.updateCurrentUserProfile(avatar: emoji);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel ? AppColors.tagSelectedBg : AppColors.background,
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.border,
                            width: isSel ? 2.5 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  },
);
}

  Future<void> _saveProfileAndPreferences() async {
    final nickname = _nameController.text.trim();
    final name = nickname.isNotEmpty
        ? nickname
        : (_apiService.currentUser?.nickname.isNotEmpty == true && _apiService.currentUser!.nickname != 'User'
            ? _apiService.currentUser!.nickname
            : 'Bạn');

    // 1. Create solo space
    final space = await _apiService.createSoloCouple(
      nickname: name,
      avatar: _selectedAvatar,
      birthday: _dobController.text.trim(),
    );

    // 2. Add self-declared preferences for Participant A (shared)
    final partA = space.participants.firstWhere(
      (p) => p.linkedUserId == _apiService.currentUser?.uid,
      orElse: () => space.participants.first,
    );

    // Save selected preset tags
    for (final tag in _selectedTags) {
      await _apiService.createPreference(
        coupleId: space.id,
        subjectParticipantId: partA.id,
        type: 'Sở thích',
        value: tag,
        visibility: PreferenceVisibility.shared,
      );
    }

    // Save custom preference if entered
    final customVal = _customPrefController.text.trim();
    if (customVal.isNotEmpty) {
      await _apiService.createPreference(
        coupleId: space.id,
        subjectParticipantId: partA.id,
        type: 'Sở thích',
        value: customVal,
        visibility: PreferenceVisibility.shared,
      );
    }
  }

  Future<void> _handleNext() async {
    setState(() => _isLoading = true);
    try {
      await _saveProfileAndPreferences();
      widget.onNext();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo hồ sơ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSkipToHome() async {
    setState(() => _isLoading = true);
    try {
      await _saveProfileAndPreferences();
      widget.onSkipToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi vào trang chủ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Back Button
                Row(
                  children: [
                    if (widget.onBack != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Quay lại',
                        onPressed: widget.onBack,
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'BƯỚC 1/2 · VỀ BẠN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.stepLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Main Title
                Text(
                  'Trước tiên, hãy kể\nvề bạn nhé',
                  style: AppTypography.script(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                const Text(
                  'Vừa đủ để Ourly hiểu được góc nhìn và sở thích của bạn.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Interactive Center Avatar
                Center(
                  child: Column(
                    children: [
                      CuteBounceOnTap(
                        onTap: _openAvatarPicker,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            OurlyAvatarView(
                              avatar: _selectedAvatar,
                              fallbackText: _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'M',
                              size: 92,
                              backgroundColor: AppColors.avatarBlueBg,
                              textColor: AppColors.avatarBlueText,
                              onTap: _openAvatarPicker,
                            ),
                            // Camera/Edit Badge
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _openAvatarPicker,
                        child: const Text(
                          'Chạm để đổi ảnh đại diện ✎',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0), curve: Curves.easeOutBack),
                const SizedBox(height: 24),

                // Input Card: Your Name
                _buildInputCard(
                  'TÊN CỦA BẠN',
                  _nameController,
                  hint: 'Ví dụ: Tuấn, Linh...',
                  onChanged: (val) {
                    if (!_isEmojiAvatarSelected() && val.isNotEmpty) {
                      setState(() {
                        _selectedAvatar = val[0].toUpperCase();
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),

                // Input Card: Birthday with Calendar Picker (Tránh tự nhập tay)
                _buildInputCard(
                  'NGÀY SINH',
                  _dobController,
                  hint: 'Chọn ngày sinh từ lịch',
                  readOnly: true,
                  onTap: _pickBirthday,
                  trailing: CuteBounceOnTap(
                    onTap: _pickBirthday,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Input Card: City
                _buildInputCard('THÀNH PHỐ', _cityController, hint: 'Ví dụ: Đà Nẵng'),
                const SizedBox(height: 24),

                // Tags Section Header
                const Text(
                  'Một vài điều bạn yêu thích',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Tag Chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ..._availableTags.map((tag) {
                      final label = tag['label']!;
                      final emoji = tag['emoji']!;
                      final isSelected = _selectedTags.contains(label);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTags.remove(label);
                            } else {
                              _selectedTags.add(label);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.tagSelectedBg : AppColors.tagUnselectedBg,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isSelected ? AppColors.tagSelectedBorder : AppColors.tagUnselectedBorder,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? AppColors.tagSelectedText : AppColors.tagUnselectedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Option "Khác / Tự nhập"
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCustomPrefActive = !_isCustomPrefActive;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _isCustomPrefActive ? AppColors.tagSelectedBg : AppColors.tagUnselectedBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: _isCustomPrefActive ? AppColors.tagSelectedBorder : AppColors.tagUnselectedBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('✍️', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '+ Tự nhập khác',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _isCustomPrefActive ? FontWeight.w600 : FontWeight.w500,
                                color: _isCustomPrefActive ? AppColors.tagSelectedText : AppColors.tagUnselectedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Custom Preference Input Box (Max 100 characters)
                if (_isCustomPrefActive) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'SỞ THÍCH KHÁC CỦA BẠN (TỰ NHẬP)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: AppColors.primary,
                              ),
                            ),
                            ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _customPrefController,
                              builder: (context, value, _) {
                                return Text(
                                  '${value.text.length}/100',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: value.text.length >= 95 ? Colors.red : AppColors.textMuted,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        TextField(
                          controller: _customPrefController,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: 'Ví dụ: Đọc sách cùng nhau, du lịch khám phá, nấu ăn...',
                            contentPadding: EdgeInsets.only(top: 8, bottom: 4),
                            border: InputBorder.none,
                            counterText: '', // hidden default counter
                          ),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 36),

                // Next Button with 3D Embossed Depth
                CuteBounceOnTap(
                  onTap: _isLoading ? null : _handleNext,
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6D55), Color(0xFFE85A42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                      boxShadow: AppShadows.button3D,
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'Tiếp theo: Kết nối người ấy →',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              Text('💕', style: TextStyle(fontSize: 15)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Button: Hiện tại tôi chưa có người ấy -> vào thẳng trang chủ
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleSkipToHome,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Hiện tại tôi chưa có người ấy',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isEmojiAvatarSelected() {
    return _avatarPresets.contains(_selectedAvatar);
  }

  Widget _buildInputCard(
    String label,
    TextEditingController controller, {
    required String hint,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: AppShadows.input3D,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: AppColors.textMuted,
                    ),
                  ),
                  TextField(
                    controller: controller,
                    readOnly: readOnly,
                    onTap: onTap,
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: hint,
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.45),
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                      contentPadding: const EdgeInsets.only(top: 4, bottom: 2),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }
}
