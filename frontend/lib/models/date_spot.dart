import 'package:flutter/material.dart';

class DateOccasion {
  final String id;
  final String label;
  final String emoji;
  final String titlePrompt;

  const DateOccasion({
    required this.id,
    required this.label,
    required this.emoji,
    required this.titlePrompt,
  });
}

class DateSpot {
  final String id;
  final String name;
  final String category;
  final String experienceType;
  final String area;
  final int cost;
  final String costDisplay;
  final String distance;
  final int fitScore;
  final List<String> tags;
  final String activityTitle;
  final String timeSlotLabel;
  final String aiNote;
  final String secretIdea;
  final String iconEmoji;
  final List<Color> gradientColors;
  final String heroImageUrl;
  final List<String> galleryImages;
  final String fullAddress;
  final String description;
  final List<Map<String, String>> menuItems;
  final List<String> aiReasons;

  const DateSpot({
    required this.id,
    required this.name,
    required this.category,
    this.experienceType = 'TRẢI NGHIỆM —',
    required this.area,
    required this.cost,
    required this.costDisplay,
    required this.distance,
    required this.fitScore,
    required this.tags,
    required this.activityTitle,
    required this.timeSlotLabel,
    required this.aiNote,
    required this.secretIdea,
    required this.iconEmoji,
    required this.gradientColors,
    this.heroImageUrl = '',
    this.galleryImages = const [],
    this.fullAddress = '',
    this.description = '',
    this.menuItems = const [],
    this.aiReasons = const [],
  });
}

class DateTimelineStep {
  final String iconEmoji;
  final String timeLabel;
  final String title;
  final String description;
  final Color nodeBgColor;

  const DateTimelineStep({
    required this.iconEmoji,
    required this.timeLabel,
    required this.title,
    required this.description,
    required this.nodeBgColor,
  });
}
