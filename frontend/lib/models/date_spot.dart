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
  final String imageAsset;
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
    this.imageAsset = '',
    this.galleryImages = const [],
    this.fullAddress = '',
    this.description = '',
    this.menuItems = const [],
    this.aiReasons = const [],
    this.activities = const [],
    this.conversationTopics = const [],
    this.caringTips = const [],
    this.highlightQuote = '',
  });

  final List<String> activities;
  final List<String> conversationTopics;
  final List<String> caringTips;
  final String highlightQuote;
}

class DateTimelineStep {
  final String iconEmoji;
  final String timeLabel;
  final String title;
  final String description;
  final Color nodeBgColor;
  final String imageAsset;
  final String categoryTag;
  final String locationName;
  final List<String> activities;
  final List<String> conversationTopics;
  final List<String> caringTips;
  final String highlightQuote;

  const DateTimelineStep({
    required this.iconEmoji,
    required this.timeLabel,
    required this.title,
    required this.description,
    required this.nodeBgColor,
    this.imageAsset = '',
    this.categoryTag = '',
    this.locationName = '',
    this.activities = const [],
    this.conversationTopics = const [],
    this.caringTips = const [],
    this.highlightQuote = '',
  });
}

class DatingPlanHistoryItem {
  final String id;
  final String title;
  final String occasionLabel;
  final String occasionEmoji;
  final DateTime createdAt;
  final int totalCost;
  final String totalCostDisplay;
  final List<DateSpot> spots;
  final List<DateTimelineStep> timelineSteps;
  final String secretIdeaTitle;
  final String secretIdeaDesc;
  final String customWish;
  final String partnerName;
  final bool isCompleted;

  const DatingPlanHistoryItem({
    required this.id,
    required this.title,
    required this.occasionLabel,
    required this.occasionEmoji,
    required this.createdAt,
    required this.totalCost,
    required this.totalCostDisplay,
    required this.spots,
    required this.timelineSteps,
    required this.secretIdeaTitle,
    required this.secretIdeaDesc,
    this.customWish = '',
    this.partnerName = 'Người ấy',
    this.isCompleted = false,
  });
}
