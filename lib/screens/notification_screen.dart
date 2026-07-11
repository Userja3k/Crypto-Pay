import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/animated_icon_badge.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notifications'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vos dernières alertes',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (notifications.isEmpty)
              GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: 24,
                opacity: 0.08,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Aucune notification récente',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Toutes vos activités sont à jour. Nous vous informerons dès qu’il y aura une nouvelle alerte.',
                      style: TextStyle(
                          color: Colors.white60, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              )
            else
              ...notifications.map((n) {
                final title = n['title'] ?? 'Notification';
                final body = n['body'] ?? '';
                final created = n['created_at'] ?? '';
                final isRead = n['is_read'] ?? false;
                final metadata = n['metadata'] as Map<String, dynamic>?;
                final tech = _parseTech(metadata?['tech']?.toString());
                final isPayment =
                    (n['type']?.toString() ?? '').contains('payment');

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 16,
                    opacity: isRead ? 0.03 : 0.1,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPayment && tech != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: AnimatedIconBadge(
                              tech: tech,
                              size: 40,
                              showPulse: !isRead,
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: isRead ? Colors.white54 : Colors.white,
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                body,
                                style: TextStyle(
                                  color:
                                      isRead ? Colors.white38 : Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDate(created.toString()),
                                style: const TextStyle(
                                  color: Colors.white24,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: LiquidGlassTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  PaymentTech? _parseTech(String? tech) {
    if (tech == null) return null;
    try {
      return PaymentTech.values.firstWhere(
        (e) => e.toString().split('.').last == tech,
      );
    } catch (_) {
      return null;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 7) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (diff.inDays > 0) {
        return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
      } else if (diff.inHours > 0) {
        return 'Il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
      } else if (diff.inMinutes > 0) {
        return 'Il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'À l\'instant';
      }
    } catch (_) {
      return dateStr;
    }
  }
}
