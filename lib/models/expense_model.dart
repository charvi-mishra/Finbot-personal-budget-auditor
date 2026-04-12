import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String category;
  final String description;
  final DateTime date;
  final String rawMessage;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.category,
    required this.description,
    required this.date,
    required this.rawMessage,
  });

  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      userId: map['userId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'INR',
      category: map['category'] ?? 'Other',
      description: map['description'] ?? '',
      date: map['date'] is Timestamp
          ? (map['date'] as Timestamp).toDate()
          : DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      rawMessage: map['rawMessage'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'category': category,
        'description': description,
        'date': Timestamp.fromDate(date),
        'rawMessage': rawMessage,
      };

  String get categoryEmoji {
    const Map<String, String> emojiMap = {
      'food': '🍔',
      'groceries': '🛒',
      'milk': '🥛',
      'clothes': '👕',
      'clothing': '👕',
      'fashion': '👗',
      'transport': '🚗',
      'travel': '✈️',
      'entertainment': '🎬',
      'health': '💊',
      'medical': '🏥',
      'education': '📚',
      'utilities': '💡',
      'rent': '🏠',
      'housing': '🏠',
      'shopping': '🛍️',
      'restaurant': '🍽️',
      'coffee': '☕',
      'fuel': '⛽',
      'gym': '💪',
      'subscription': '📱',
      'electronics': '💻',
      'gifts': '🎁',
      'savings': '💰',
      'investment': '📈',
      'other': '💸',
    };
    final key = category.toLowerCase();
    return emojiMap.entries
            .firstWhere((e) => key.contains(e.key),
                orElse: () => const MapEntry('other', '💸'))
            .value;
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Expense? linkedExpense;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.linkedExpense,
  });
}
