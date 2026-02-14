import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class IconHelper {
  static IconData getIcon(String? iconName) {
    if (iconName == null) return Icons.category_rounded;

    switch (iconName.toLowerCase()) {
      // Entertainment
      case 'film':
      case 'netflix':
        return FontAwesomeIcons.film;
      case 'spotify':
        return FontAwesomeIcons.spotify;
      case 'youtube':
        return FontAwesomeIcons.youtube;
      case 'amazon':
        return FontAwesomeIcons.amazon;
      case 'apple':
        return FontAwesomeIcons.apple;
      case 'circleplay':
      case 'disney':
        return FontAwesomeIcons.circlePlay;
      case 'tv':
      case 'exxen':
        return Icons.tv;
      case 'movie':
      case 'blutv':
        return Icons.movie;

      // Cloud/Work
      case 'cloud':
      case 'icloud':
        return FontAwesomeIcons.cloud;
      case 'dropbox':
        return FontAwesomeIcons.dropbox;
      case 'robot':
      case 'chatgpt':
        return FontAwesomeIcons.robot;
      case 'brain':
      case 'claude':
        return FontAwesomeIcons.brain;
      case 'google':
      case 'gemini':
        return FontAwesomeIcons.google;
      case 'palette':
      case 'adobe':
        return FontAwesomeIcons.palette;
      case 'terminal':
      case 'cursor':
        return FontAwesomeIcons.terminal;
      case 'rocket':
        return FontAwesomeIcons.rocket;

      // Generic
      case 'music':
        return Icons.music_note_rounded;
      case 'game':
        return Icons.games_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;

      default:
        return Icons.category_rounded;
    }
  }

  static Color getColor(String? colorHex) {
    if (colorHex == null || colorHex.isEmpty) return Colors.grey;
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
