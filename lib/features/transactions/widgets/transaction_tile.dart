import 'package:flutter/material.dart';
import '../../../app/theme/moneymate_theme.dart';
import '../../../core/utils/formatter.dart';
import '../models/models.dart';
import '../screens/transaction_detail_screen.dart';

class TransactionTile extends StatefulWidget {
  const TransactionTile({required this.transaction, super.key});
  
  final Transaction transaction;

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.type == TransactionType.income;
    final color = isIncome ? MoneyMateTheme.success : MoneyMateTheme.danger;
    final sign = isIncome ? '+' : '-';
    final categoryLabel = widget.transaction.categoryName ?? 'Kategori #${widget.transaction.categoryId}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.97),
        onTapUp: (_) => setState(() => _scale = 1.0),
        onTapCancel: () => setState(() => _scale = 1.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transactionId: widget.transaction.id),
            ),
          );
        },
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.025),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      color: color,
                    ),
                    Expanded(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
                          ),
                          child: Icon(
                            isIncome ? Icons.south_east_rounded : Icons.north_east_rounded,
                            color: color,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          categoryLabel,
                          style: const TextStyle(
                            color: MoneyMateTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: widget.transaction.note != null && widget.transaction.note!.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  widget.transaction.note!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: MoneyMateTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : null,
                        trailing: Text(
                          '$sign${Formatter.formatRupiah(widget.transaction.amount)}',
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
