import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/expense_model.dart';
import '../models/user_model.dart';
import 'expense_service.dart';
import 'auth_service.dart';
import '../config/secrets.dart';

class ParsedExpense {
  final double amount;
  final String currency;
  final String category;
  final String description;
  final DateTime date;
  final bool isExpense;

  ParsedExpense({
    required this.amount,
    required this.currency,
    required this.category,
    required this.description,
    required this.date,
    required this.isExpense,
  });

  factory ParsedExpense.fromJson(Map<String, dynamic> json) {
    return ParsedExpense(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] ?? 'INR',
      category: json['category'] ?? 'Other',
      description: json['description'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      isExpense: json['isExpense'] ?? true,
    );
  }
}

class ChatService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  final ExpenseService _expenseService = ExpenseService();
  final AuthService _authService = AuthService();

  // Stores conversation as Gemini expects: role is 'user' or 'model'
  final List<Map<String, dynamic>> _conversationHistory = [];

  String _buildSystemPrompt(UserModel user) => '''
You are Finbot 🐷, a friendly personal finance budget auditor to ${user.name}.
You help them track expenses through casual conversation.

Today's date is ${DateTime.now().toIso8601String().substring(0, 10)}.
User's country: ${user.country}, Occupation: ${user.occupation}
Monthly income: ${user.monthlyIncome ?? 'Not set'}, Current savings: ${user.currentSavings ?? 0}

YOUR BEHAVIOR:
1. If the user mentions spending money (e.g., "I spent 500 on clothes", "bought milk for 105 INR", "paid 2000 for taxi"), extract expense details and respond in this EXACT JSON format embedded in your reply:
   
   EXPENSE_DATA:{"amount": 500, "currency": "INR", "category": "Clothing", "description": "clothes from Savana", "date": "2024-01-15", "isExpense": true}:END_EXPENSE_DATA
   
   Then continue with a friendly acknowledgment like "Got it! I've logged ₹500 for clothes 🛍️. Your savings have been updated!"

2. If no expense is mentioned, just chat warmly as a supportive financial friend.
3. For ambiguous currency, use INR as default if user is from India.
4. Categories should be one of: Food, Groceries, Clothing, Transport, Entertainment, Health, Education, Utilities, Rent, Shopping, Coffee, Fuel, Gym, Subscriptions, Electronics, Gifts, Other
5. Be concise, warm, and encouraging. Use relevant emojis.
6. If asked about spending habits, you can give encouraging advice.
7. Never be preachy. Be like a caring friend, not a financial advisor.
8. When user receives money or has a positive financial event, add it as a negative expense (income) with "isExpense": false in the JSON, and respond with a cheerful message like "Yay! I've noted your income of ₹2000 🎉. Your savings have been updated!"
''';

  Future<String> sendMessage({
    required String userMessage,
    required UserModel user,
  }) async {
    final apiUrl = '$_baseUrl?key=${Secrets.geminiApiKey}';

    // On first message, prepend system prompt to user message
    final messageToSend = _conversationHistory.isEmpty
        ? '${_buildSystemPrompt(user)}\n\nUser: $userMessage'
        : userMessage;

    _conversationHistory.add({
      'role': 'user',
      'parts': [{'text': messageToSend}],
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': _conversationHistory}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
                'Sorry, I had trouble understanding that.';

        _conversationHistory.add({
          'role': 'model',
          'parts': [{'text': assistantMessage}],
        });

        await _processExpenseFromResponse(assistantMessage, user, userMessage);

        return _cleanMessage(assistantMessage);
      } else {
        // Remove the user message we just added since the request failed
        _conversationHistory.removeLast();
        return 'Hmm, I\'m having trouble connecting right now 😅. Please try again in a moment!';
      }
    } catch (e) {
      _conversationHistory.removeLast();
      return 'Oops! Something went wrong: ${e.toString()}. Please check your connection!';
    }
  }

  Future<void> _processExpenseFromResponse(
    String response,
    UserModel user,
    String rawMessage,
  ) async {
    final expenseRegex =
        RegExp(r'EXPENSE_DATA:(.*?):END_EXPENSE_DATA', dotAll: true);
    final match = expenseRegex.firstMatch(response);
    if (match == null) return;

    try {
      final jsonStr = match.group(1)?.trim() ?? '';
      final parsed = ParsedExpense.fromJson(jsonDecode(jsonStr));

      if (parsed.amount <= 0) return;

      // Always fetch fresh user data to avoid stale savings value
      final freshUser = await _authService.getUser(user.uid);
      final currentSavings =
          freshUser?.currentSavings ?? user.currentSavings ?? 0;

      if (parsed.isExpense) {
        // Save expense to Firestore
        final expense = Expense(
          id: '',
          userId: user.uid,
          amount: parsed.amount,
          currency: parsed.currency,
          category: parsed.category,
          description: parsed.description,
          date: parsed.date,
          rawMessage: rawMessage,
        );
        await _expenseService.addExpense(expense);

        // Subtract expense from fresh savings
        final newSavings = currentSavings - parsed.amount;
        await _authService.updateSavings(
            user.uid, newSavings < 0 ? 0 : newSavings);
      } else {
        // Save income entry to Firestore
        final income = Expense(
          id: '',
          userId: user.uid,
          amount: parsed.amount,
          currency: parsed.currency,
          category: 'Income',
          description: parsed.description,
          date: parsed.date,
          rawMessage: rawMessage,
        );
        await _expenseService.addExpense(income);

        // Add income to fresh savings
        final newSavings = currentSavings + parsed.amount;
        await _authService.updateSavings(user.uid, newSavings);
      }
    } catch (e) {
      // Parsing failed silently - the message still shows
    }
  }

  String _cleanMessage(String message) {
    return message
        .replaceAll(
            RegExp(r'EXPENSE_DATA:.*?:END_EXPENSE_DATA', dotAll: true), '')
        .trim();
  }

  void clearHistory() => _conversationHistory.clear();
}