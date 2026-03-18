import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/palm_reading_result.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final svc = context.read<HistoryService>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.arrow_back, color: AppTheme.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '분석 기록',
            style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold,
              shadows: [Shadow(color: AppTheme.gold.withValues(alpha: 0.2), blurRadius: 10)],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showClearDialog(context, svc),
            icon: Icon(Icons.delete_sweep_outlined, color: AppTheme.textMuted.withValues(alpha: 0.6), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Consumer<HistoryService>(
      builder: (context, svc, _) {
        final items = svc.histories;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 56, color: AppTheme.textMuted.withValues(alpha: 0.25)),
                const SizedBox(height: 16),
                Text('분석 기록이 없습니다',
                    style: TextStyle(fontSize: 15, color: AppTheme.textMuted.withValues(alpha: 0.5))),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final h = items[index];
            return Dismissible(
              key: Key(h.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppTheme.lifeLine.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline, color: AppTheme.lifeLine),
              ),
              onDismissed: (_) => svc.deleteHistory(h.id),
              child: GestureDetector(
                onTap: () {
                  final result = PalmReadingResult.fromJson(h.resultMap);
                  Navigator.of(context).pushNamed('/result', arguments: {
                    'imagePath': null,
                    'result': result,
                    'handType': h.handType ?? 'right',
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppTheme.gold.withValues(alpha: 0.6), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _fmt(h.analyzedAt),
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted.withValues(alpha: 0.7)),
                          ),
                          if (h.handType != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                h.handType == 'left' ? '왼손' : '오른손',
                                style: TextStyle(fontSize: 10, color: AppTheme.purple.withValues(alpha: 0.7)),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Icon(Icons.chevron_right, color: AppTheme.textMuted.withValues(alpha: 0.3), size: 18),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        h.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: AppTheme.textSecondary.withValues(alpha: 0.8), height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _showClearDialog(BuildContext context, HistoryService svc) {
    if (svc.histories.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 전체 삭제'),
        content: const Text('모든 분석 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('취소')),
          TextButton(
            onPressed: () { svc.clearAll(); Navigator.of(ctx).pop(); },
            child: const Text('삭제', style: TextStyle(color: AppTheme.lifeLine)),
          ),
        ],
      ),
    );
  }
}
