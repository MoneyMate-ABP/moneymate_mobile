import 'package:equatable/equatable.dart';

enum CategoryType {
  expense,
  income,
  both;

  static CategoryType fromJson(String value) {
    return switch (value) {
      'expense' => CategoryType.expense,
      'income' => CategoryType.income,
      'both' => CategoryType.both,
      _ => throw ArgumentError('Unknown CategoryType: "$value"'),
    };
  }

  String toJson() => name;

  String get label => switch (this) {
        CategoryType.expense => 'Pengeluaran',
        CategoryType.income => 'Pemasukan',
        CategoryType.both => 'Keduanya',
      };
}

class Category extends Equatable {
  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      name: '${json['name'] ?? ''}',
      type: CategoryType.fromJson('${json['type'] ?? 'expense'}'),
      createdAt: '${json['created_at'] ?? ''}',
    );
  }

  final int id;
  final int userId;
  final String name;
  final CategoryType type;
  final String createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'type': type.toJson(),
        'created_at': createdAt,
      };

  @override
  List<Object?> get props => [id, userId, name, type, createdAt];

  static int _toInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
