import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetProgressCard extends StatelessWidget {
  final double spend;
  final double budget;
  final VoidCallback onTap;

  const BudgetProgressCard({
    super.key,
    required this.spend,
    required this.budget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₦', decimalDigits: 0);
    final pct = budget <= 0 ? 0.0 : (spend / budget).clamp(0.0, 1.5);
    final over = spend > budget;
    final near = !over && pct >= 0.85;

    final barColor = over
        ? Colors.red.shade400
        : near
            ? Colors.orange.shade400
            : Colors.green.shade400;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monthly Budget', style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${currency.format(spend)} / ${currency.format(budget)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct > 1.0 ? 1.0 : pct,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            if (over || near) ...[
              const SizedBox(height: 8),
              Text(
                over
                    ? 'You\'ve gone ${currency.format(spend - budget)} over budget this month'
                    : 'You\'re close to your monthly budget',
                style: TextStyle(color: barColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
