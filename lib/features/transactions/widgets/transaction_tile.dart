import 'package:flutter/material.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../../core/utils/formatter.dart';
import '../models/models.dart';
import '../screens/transaction_detail_screen.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({required this.transaction, super.key});
  
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final color = isIncome ? MoneyMateTheme.success : MoneyMateTheme.danger;
    final sign = isIncome ? '+' : '-';
    final categoryLabel = transaction.categoryName ?? 'Kategori #${transaction.categoryId}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(transactionId: transaction.id),
              ),
            );
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: 18,
            ),
          ),
          title: Text(
            categoryLabel,
            style: const TextStyle(
              color: MoneyMateTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: transaction.note != null && transaction.note!.isNotEmpty
              ? Text(
                  transaction.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MoneyMateTheme.textSecondary,
                    fontSize: 12,
                  ),
                )
              : null,
          trailing: Text(
            '$sign${Formatter.formatRupiah(transaction.amount)}',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
