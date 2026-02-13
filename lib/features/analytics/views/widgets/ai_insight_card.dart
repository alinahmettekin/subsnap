import 'package:flutter/material.dart';
import 'package:subsnap/features/subscriptions/models/subscription.dart';

class AIInsightCard extends StatelessWidget {
  final List<Subscription> subscriptions;

  const AIInsightCard({super.key, required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6366F1).withValues(alpha: 0.1), const Color(0xFFA855F7).withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          if (insights.isEmpty)
            const Text('Şu an için yeni bir analiz bulunmuyor.', style: TextStyle(color: Colors.white54, fontSize: 14)),
          ...insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•', style: TextStyle(color: Color(0xFFA855F7), fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SavingsMeter(subscriptions: subscriptions),
        ],
      ),
    );
  }

  List<String> _generateInsights() {
    final insights = <String>[];

    // Heuristic 1: Multiple music/video services (Mock check for keywords)
    final apps = subscriptions.map((s) => s.name.toLowerCase()).toList();
    if (apps.contains('spotify') && apps.contains('apple music')) {
      insights.add('Hem Spotify hem Apple Music kullanıyorsun. Birini iptal ederek tasarruf edebilirsin.');
    }
    if (apps.contains('netflix') && apps.contains('disney')) {
      insights.add('Video servislerinde bu ay harcaman yüksek. Kullanmadığın paketleri düşürmeyi düşünebilirsin.');
    }

    // Heuristic 2: Total count
    if (subscriptions.length > 5) {
      insights.add('Abonelik sayın ortalamanın üzerinde. Aktif kullanmadığın yan uygulamaları gözden geçir.');
    }

    // Heuristic 3: Trend (Static for now as we don't have deep history)
    insights.add('Harcamaların son 3 ayda dengeli seyrediyor.');

    return insights;
  }
}

class _SavingsMeter extends StatelessWidget {
  final List<Subscription> subscriptions;

  const _SavingsMeter({required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    // Top 2 cheapest subscriptions as "potential savings"
    final potentialSavings = subscriptions.length > 2
        ? subscriptions.map((e) => e.price).reduce((a, b) => a < b ? a : b) + 50
        : 0.0;

    if (potentialSavings == 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: Colors.white10),
        const SizedBox(height: 16),
        const Text('🔥 Tasarruf Potansiyeli', style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.6,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA855F7)),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '₺${potentialSavings.toStringAsFixed(0)} / Ay',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
