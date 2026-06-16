import 'package:equatable/equatable.dart';

class NotificationHistory extends Equatable {
  const NotificationHistory({
    required this.id,
    required this.title,
    required this.body,
    this.budgetPeriodName,
    required this.effectiveBudget,
    required this.carryOver,
    required this.isRead,
    required this.sentAt,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) {
    return NotificationHistory(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      budgetPeriodName: json['budget_period_name'] as String?,
      effectiveBudget: _toDouble(json['effective_budget']),
      carryOver: _toDouble(json['carry_over']),
      isRead: json['is_read'] as bool? ?? false,
      sentAt: json['sent_at'] as String? ?? '',
    );
  }

  final int id;
  final String title;
  final String body;
  final String? budgetPeriodName;
  final double effectiveBudget;
  final double carryOver;
  final bool isRead;
  final String sentAt;

  NotificationHistory copyWith({
    int? id,
    String? title,
    String? body,
    String? budgetPeriodName,
    double? effectiveBudget,
    double? carryOver,
    bool? isRead,
    String? sentAt,
  }) {
    return NotificationHistory(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      budgetPeriodName: budgetPeriodName ?? this.budgetPeriodName,
      effectiveBudget: effectiveBudget ?? this.effectiveBudget,
      carryOver: carryOver ?? this.carryOver,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        if (budgetPeriodName != null) 'budget_period_name': budgetPeriodName,
        'effective_budget': effectiveBudget,
        'carry_over': carryOver,
        'is_read': isRead,
        'sent_at': sentAt,
      };

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        budgetPeriodName,
        effectiveBudget,
        carryOver,
        isRead,
        sentAt,
      ];

  static double _toDouble(Object? val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse('$val') ?? 0.0;
  }
}

class NotificationHistoryResponse extends Equatable {
  const NotificationHistoryResponse({
    required this.data,
    required this.unreadCount,
  });

  factory NotificationHistoryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['data'] as List? ?? const [];
    return NotificationHistoryResponse(
      data: list
          .whereType<Map<String, dynamic>>()
          .map(NotificationHistory.fromJson)
          .toList(),
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  final List<NotificationHistory> data;
  final int unreadCount;

  @override
  List<Object?> get props => [data, unreadCount];
}
