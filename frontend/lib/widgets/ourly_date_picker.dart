import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OurlyDatePicker {
  /// Open an aesthetic romantic date picker dialog themed for Ourly
  static Future<DateTime?> pickDate({
    required BuildContext context,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String helpText = 'CHỌN NGÀY',
    String cancelText = 'ĐÓNG',
    String confirmText = 'CHỌN',
    DatePickerMode initialDatePickerMode = DatePickerMode.day,
  }) async {
    // Unfocus any active text field to close keyboard
    FocusScope.of(context).unfocus();

    final now = DateTime.now();
    final effectiveFirst = firstDate ?? DateTime(1920, 1, 1);
    final effectiveLast = lastDate ?? now;
    DateTime effectiveInitial = initialDate ?? DateTime(2000, 1, 1);

    if (effectiveInitial.isAfter(effectiveLast)) {
      effectiveInitial = effectiveLast;
    }
    if (effectiveInitial.isBefore(effectiveFirst)) {
      effectiveInitial = effectiveFirst;
    }

    return await showDatePicker(
      context: context,
      initialDate: effectiveInitial,
      firstDate: effectiveFirst,
      lastDate: effectiveLast,
      initialDatePickerMode: initialDatePickerMode,
      initialEntryMode: DatePickerEntryMode.calendarOnly, // Avoid manual typing mode completely
      helpText: helpText,
      cancelText: cancelText,
      confirmText: confirmText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
              secondary: AppColors.primaryLight,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 12,
              backgroundColor: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: AppColors.primary,
              headerForegroundColor: Colors.white,
              headerHeadlineStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              headerHelpStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
                color: Colors.white70,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              dayStyle: const TextStyle(fontWeight: FontWeight.w600),
              yearStyle: const TextStyle(fontWeight: FontWeight.w600),
              todayForegroundColor: WidgetStateProperty.all(AppColors.primary),
              todayBorder: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// Formats date to standard dd/MM/yyyy
  static String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  /// Parses dd/MM/yyyy or yyyy-MM-dd string into DateTime safely
  static DateTime? parseDate(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    final trimmed = text.trim();

    // Check for yyyy-MM-dd format
    if (RegExp(r'^\d{4}-\d{1,2}-\d{1,2}').hasMatch(trimmed)) {
      return DateTime.tryParse(trimmed);
    }

    // Check for dd/MM/yyyy or dd-MM-yyyy or dd.MM.yyyy
    try {
      final parts = trimmed.split(RegExp(r'[/.-]'));
      if (parts.length == 3) {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        // Simple sanity check
        if (m >= 1 && m <= 12 && d >= 1 && d <= 31 && y > 1900) {
          return DateTime(y, m, d);
        }
      }
    } catch (_) {}

    return null;
  }
}
