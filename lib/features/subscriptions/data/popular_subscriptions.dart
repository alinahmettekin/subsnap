import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PopularSubscription {
  final String name;
  final IconData icon;
  final Color color;
  final String category;

  const PopularSubscription({required this.name, required this.icon, required this.color, required this.category});
}

final List<PopularSubscription> popularSubscriptions = [
  PopularSubscription(name: 'Netflix', icon: FontAwesomeIcons.film, color: Color(0xFFE50914), category: 'Eğlence'),
  PopularSubscription(name: 'Spotify', icon: FontAwesomeIcons.spotify, color: Color(0xFF1DB954), category: 'Müzik'),
  PopularSubscription(
    name: 'YouTube Premium',
    icon: FontAwesomeIcons.youtube,
    color: Color(0xFFFF0000),
    category: 'Eğlence',
  ),
  PopularSubscription(
    name: 'Amazon Prime',
    icon: FontAwesomeIcons.amazon,
    color: Color(0xFF00A8E1),
    category: 'Alışveriş',
  ),
  PopularSubscription(name: 'Apple Music', icon: FontAwesomeIcons.apple, color: Color(0xFFFA243C), category: 'Müzik'),
  PopularSubscription(
    name: 'Disney+',
    icon: FontAwesomeIcons.circlePlay,
    color: Color(0xFF113CCF),
    category: 'Eğlence',
  ),
  PopularSubscription(name: 'Exxen', icon: Icons.tv, color: Color(0xFFFFC600), category: 'Eğlence'),
  PopularSubscription(name: 'BluTV', icon: Icons.movie, color: Color(0xFF0096D6), category: 'Eğlence'),
  PopularSubscription(name: 'iCloud', icon: FontAwesomeIcons.cloud, color: Color(0xFF007AFF), category: 'Diğer'),
  PopularSubscription(name: 'Dropbox', icon: FontAwesomeIcons.dropbox, color: Color(0xFF0061FF), category: 'İş'),
  PopularSubscription(name: 'ChatGPT', icon: FontAwesomeIcons.robot, color: Color(0xFF10A37F), category: 'İş'),
  PopularSubscription(name: 'Claude', icon: FontAwesomeIcons.brain, color: Color(0xFFD08373), category: 'İş'),
  PopularSubscription(name: 'Gemini', icon: FontAwesomeIcons.google, color: Color(0xFF1A73E8), category: 'İş'),
  PopularSubscription(name: 'Adobe CC', icon: FontAwesomeIcons.palette, color: Color(0xFFDA1F26), category: 'İş'),
  PopularSubscription(name: 'Cursor', icon: FontAwesomeIcons.terminal, color: Color(0xFF000000), category: 'İş'),
  PopularSubscription(name: 'Antigravity', icon: FontAwesomeIcons.rocket, color: Color(0xFF6200EA), category: 'İş'),
];
