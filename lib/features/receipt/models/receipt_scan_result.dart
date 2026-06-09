import 'package:equatable/equatable.dart';

/// Response DTO for `POST /api/transactions/receipt-scan`.
///
/// The backend uses AI (e.g. Google Gemini) to extract transaction data from
/// a receipt image or PDF. The returned draft contains the parsed fields that
/// can be used to pre-fill a [CreateTransactionRequest].
///
/// Backend response shape:
/// ```json
/// {
///   "message": "Receipt scanned successfully",
///   "data": {
///     "type": "expense",
///     "amount": 45000,
///     "note": "Makan siang di warung",
///     "date": "2025-06-07",
///     "category_suggestion": "Food",
///     "merchant_name": "Warung Pak Budi",
///     "items": [
///       { "name": "Nasi Goreng", "quantity": 1, "price": 25000 },
///       { "name": "Es Teh", "quantity": 2, "price": 10000 }
///     ],
///     "raw_text": "..."
///   }
/// }
/// ```
class ReceiptScanResult extends Equatable {
  const ReceiptScanResult({
    required this.type,
    required this.amount,
    this.note,
    this.date,
    this.categorySuggestion,
    this.merchantName,
    this.items = const [],
    this.rawText,
  });

  factory ReceiptScanResult.fromJson(Map<String, dynamic> json) {
    return ReceiptScanResult(
      type: json['type'] as String? ?? 'expense',
      amount: _toDouble(json['amount']),
      note: json['note'] as String?,
      date: json['date'] as String?,
      categorySuggestion: json['category_suggestion'] as String?,
      merchantName: json['merchant_name'] as String?,
      items: _parseItems(json['items']),
      rawText: json['raw_text'] as String?,
    );
  }

  /// Transaction type extracted by AI — typically `"expense"` or `"income"`.
  final String type;

  /// Total amount extracted from the receipt.
  final double amount;

  /// AI-generated description / note for the transaction.
  final String? note;

  /// Date extracted from the receipt in ISO-8601 format (`"YYYY-MM-DD"`).
  final String? date;

  /// AI-suggested category name (not an ID — needs to be matched client-side).
  final String? categorySuggestion;

  /// Merchant / store name extracted from the receipt.
  final String? merchantName;

  /// Itemised list of products/services found on the receipt.
  final List<ReceiptScanItem> items;

  /// Raw OCR text extracted from the receipt (useful for debugging).
  final String? rawText;

  Map<String, dynamic> toJson() => {
        'type': type,
        'amount': amount,
        if (note != null) 'note': note,
        if (date != null) 'date': date,
        if (categorySuggestion != null)
          'category_suggestion': categorySuggestion,
        if (merchantName != null) 'merchant_name': merchantName,
        if (items.isNotEmpty) 'items': items.map((i) => i.toJson()).toList(),
        if (rawText != null) 'raw_text': rawText,
      };

  @override
  List<Object?> get props => [
        type,
        amount,
        note,
        date,
        categorySuggestion,
        merchantName,
        items,
        rawText,
      ];

  // ---- helpers ---------------------------------------------------------------

  static double _toDouble(Object? value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse('$value') ?? 0.0;
  }

  static List<ReceiptScanItem> _parseItems(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(ReceiptScanItem.fromJson)
        .toList();
  }
}

/// A single line item extracted from a scanned receipt.
class ReceiptScanItem extends Equatable {
  const ReceiptScanItem({
    required this.name,
    this.quantity,
    this.price,
  });

  factory ReceiptScanItem.fromJson(Map<String, dynamic> json) {
    return ReceiptScanItem(
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] == null
          ? null
          : (json['quantity'] is int
              ? json['quantity'] as int
              : int.tryParse('${json['quantity']}')),
      price: json['price'] == null
          ? null
          : ReceiptScanResult._toDouble(json['price']),
    );
  }

  final String name;
  final int? quantity;
  final double? price;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (quantity != null) 'quantity': quantity,
        if (price != null) 'price': price,
      };

  @override
  List<Object?> get props => [name, quantity, price];
}
