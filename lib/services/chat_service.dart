import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  static const String _geminiHost = 'generativelanguage.googleapis.com';
  static const int _maxRetries = 3;
  static const List<String> _models = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];

  final ExpenseService _expenseService = ExpenseService();
  final AuthService _authService = AuthService();

  // Stores conversation as Gemini expects: role is 'user' or 'model'
  final List<Map<String, dynamic>> _conversationHistory = [];

  String _buildSystemPrompt(UserModel user) => '''
You are Finbot 🐷, a friendly money calculator to ${user.name}.
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
    if (!Secrets.isConfigured()) {
      debugPrint('Gemini error: GEMINI_API_KEY is missing from .env');
      return 'Finbot is not configured yet. Please add your Gemini API key to the .env file.';
    }

    // On first message, prepend system prompt to user message
    final messageToSend = _conversationHistory.isEmpty
        ? '${_buildSystemPrompt(user)}\n\nUser: $userMessage'
        : userMessage;

    _conversationHistory.add({
      'role': 'user',
      'parts': [{'text': messageToSend}],
    });

    try {
      await _logConnectivityDiagnostics();

      final response = await _sendWithFallback();

      if (response == null) {
        _conversationHistory.removeLast();
        return 'Finbot could not contact the AI service. Please try again.';
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage =
            data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
                'Sorry, I had trouble understanding that.';

        debugPrint('Gemini assistant message: $assistantMessage');

        _conversationHistory.add({
          'role': 'model',
          'parts': [{'text': assistantMessage}],
        });

        final spendingWarning = await _processExpenseFromResponse(
          assistantMessage,
          user,
          userMessage,
        );

        final cleanMessage = _cleanMessage(assistantMessage);
        if (spendingWarning == null) return cleanMessage;
        return '$cleanMessage\n\n$spendingWarning';
      } else {
        // Remove the user message we just added since the request failed
        debugPrint('Gemini error: ${response.statusCode} ${response.body}');
        _conversationHistory.removeLast();
        if (response.statusCode == 503) {
          return 'Finbot AI is busy right now due to high demand. Please try again in a few moments.';
        }
        return 'I couldn\'t reach Finbot\'s AI service right now. Please check the API key and network, then try again.';
      }
    } on SocketException catch (e) {
      debugPrint('Gemini socket exception: $e');
      _conversationHistory.removeLast();
      return 'Network/DNS error while contacting Finbot AI. Please verify internet access on the device and try again.';
    } on HttpException catch (e) {
      debugPrint('Gemini HTTP exception: $e');
      _conversationHistory.removeLast();
      return 'There was an HTTP error while contacting Finbot AI. Please try again shortly.';
    } on HandshakeException catch (e) {
      debugPrint('Gemini TLS handshake exception: $e');
      _conversationHistory.removeLast();
      return 'Secure connection to Finbot AI failed. Please check the device time and network settings.';
    } on TimeoutException catch (e) {
      debugPrint('Gemini timeout: $e');
      _conversationHistory.removeLast();
      return 'Finbot AI took too long to respond. Please try again in a moment.';
    } catch (e) {
      debugPrint('Gemini exception: $e');
      _conversationHistory.removeLast();
      return 'Oops! Something went wrong: ${e.toString()}. Please check your connection!';
    }
  }

  Future<void> _logConnectivityDiagnostics() async {
    try {
      final addresses = await InternetAddress.lookup(_geminiHost)
          .timeout(const Duration(seconds: 5));
      debugPrint(
        'Gemini DNS lookup success for $_geminiHost: ${addresses.map((a) => a.address).join(', ')}',
      );
    } on SocketException catch (e) {
      debugPrint('Gemini DNS lookup failed for $_geminiHost: $e');
    } on TimeoutException catch (e) {
      debugPrint('Gemini DNS lookup timed out for $_geminiHost: $e');
    } catch (e) {
      debugPrint('Gemini DNS lookup unexpected error for $_geminiHost: $e');
    }
  }

  Future<http.Response?> _sendWithFallback() async {
    for (final model in _models) {
      final response = await _sendToModel(model);
      if (response == null) {
        return null;
      }

      if (response.statusCode == 200) {
        debugPrint('Gemini success with model: $model');
        return response;
      }

      if (response.statusCode != 503) {
        debugPrint('Gemini non-retryable error from model $model');
        return response;
      }

      debugPrint('Gemini model busy, falling back from $model');
    }

    return await _sendToModel(_models.last);
  }

  Future<http.Response?> _sendToModel(String model) async {
    final apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${Secrets.geminiApiKey}';

    http.Response? response;
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': _conversationHistory}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 503) {
        return response;
      }

      debugPrint(
        'Gemini busy for model $model on attempt $attempt/$_maxRetries: ${response.body}',
      );

      if (attempt < _maxRetries) {
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return response;
  }

  Future<String?> _processExpenseFromResponse(
    String response,
    UserModel user,
    String rawMessage,
  ) async {
    try {
      final parsed = _extractExpense(response, rawMessage, user);
      if (parsed == null) {
        debugPrint('Expense parsing skipped: no structured expense found.');
        return null;
      }

      if (parsed.amount <= 0) return null;

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
          isExpense: true,
        );
        await _expenseService.addExpense(expense);
        debugPrint(
          'Expense saved: ${parsed.amount} ${parsed.currency} in ${parsed.category}',
        );

        // Subtract expense from fresh savings
        final newSavings = currentSavings - parsed.amount;
        await _authService.updateSavings(
            user.uid, newSavings < 0 ? 0 : newSavings);
        debugPrint(
          'Savings updated from $currentSavings to ${newSavings < 0 ? 0 : newSavings}',
        );

        return await _buildMonthlySpendingWarning(user.uid, freshUser ?? user);
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
          isExpense: false,
        );
        await _expenseService.addExpense(income);
        debugPrint(
          'Income saved: ${parsed.amount} ${parsed.currency} in ${parsed.category}',
        );

        // Add income to fresh savings
        final newSavings = currentSavings + parsed.amount;
        await _authService.updateSavings(user.uid, newSavings);
        debugPrint('Savings updated from $currentSavings to $newSavings');
      }
    } catch (e) {
      debugPrint('Expense processing failed: $e');
    }

    return null;
  }

  Future<String?> _buildMonthlySpendingWarning(
    String userId,
    UserModel user,
  ) async {
    final monthlyIncome = user.monthlyIncome;
    if (monthlyIncome == null || monthlyIncome <= 0) return null;

    final monthlyExpenses =
        await _expenseService.getCurrentMonthExpenses(userId);
    final monthlySpent = monthlyExpenses
        .where((expense) => expense.isExpense)
        .fold<double>(0.0, (sum, expense) => sum + expense.amount);

    if (monthlySpent < monthlyIncome * 0.5) return null;

    final percent = (monthlySpent / monthlyIncome * 100).toStringAsFixed(0);
    return 'Heads up: you have spent $percent% of your monthly income this month. Be wary of spending further unless it is truly needed.';
  }

  ParsedExpense? _extractExpense(
    String response,
    String rawMessage,
    UserModel user,
  ) {
    final expenseRegex =
        RegExp(r'EXPENSE_DATA:(.*?):END_EXPENSE_DATA', dotAll: true);
    final match = expenseRegex.firstMatch(response);

    if (match != null) {
      final jsonStr = match.group(1)?.trim() ?? '';
      return ParsedExpense.fromJson(jsonDecode(jsonStr));
    }

    return _parseExpenseFromMessage(rawMessage, user);
  }

  ParsedExpense? _parseExpenseFromMessage(String message, UserModel user) {
    final normalized = message.toLowerCase().trim();

    final amountMatch = RegExp(r'(?<!\d)(\d+(?:\.\d+)?)').firstMatch(normalized);
    if (amountMatch == null) {
      return null;
    }

    final amount = double.tryParse(amountMatch.group(1) ?? '');
    if (amount == null || amount <= 0) {
      return null;
    }

    final isExpense = !_containsAny(
      normalized,
      [
        'received',
        'got paid',
        'got ',
        'earned',
        'income',
        'salary',
        'credited',
        'credit',
        'gifted',
        'gift from',
        'cashback',
        'refund',
      ],
    );

    final category = _detectCategory(normalized);
    final currency = _detectCurrency(normalized, user);

    return ParsedExpense(
      amount: amount,
      currency: currency,
      category: category,
      description: _buildDescription(normalized, category),
      date: DateTime.now(),
      isExpense: isExpense,
    );
  }

  bool _containsAny(String text, List<String> phrases) {
    return phrases.any(text.contains);
  }

  String _detectCurrency(String message, UserModel user) {
    if (_containsAny(message, [r'$', 'usd', 'dollar'])) return 'USD';
    if (_containsAny(message, ['€', 'eur', 'euro'])) return 'EUR';
    if (_containsAny(message, ['£', 'gbp', 'pound'])) return 'GBP';
    if (_containsAny(message, ['₹', 'inr', 'rupee', 'rupees'])) return 'INR';
    if (user.country.toLowerCase().contains('india')) return 'INR';
    return 'INR';
  }

  String _detectCategory(String message) {
    const categoryRules = <String, List<String>>{
      'Food': ['food', 'meal', 'lunch', 'dinner', 'breakfast', 'snack'],
      'Groceries': ['grocery', 'groceries', 'fruits', 'vegetables', 'milk'],
      'Clothing': ['cloth', 'clothes', 'shirt', 'jeans', 'dress', 'fashion'],
      'Transport': ['taxi', 'cab', 'uber', 'auto', 'bus', 'metro', 'train'],
      'Entertainment': ['movie', 'netflix', 'game', 'concert'],
      'Health': ['doctor', 'medicine', 'hospital', 'pharmacy', 'health'],
      'Education': ['book', 'course', 'tuition', 'school', 'college'],
      'Utilities': ['electricity', 'water', 'gas', 'internet', 'wifi', 'bill'],
      'Rent': ['rent', 'landlord'],
      'Shopping': ['shopping', 'bought', 'purchase', 'amazon'],
      'Coffee': ['coffee', 'cafe'],
      'Fuel': ['fuel', 'petrol', 'diesel'],
      'Gym': ['gym', 'workout', 'fitness'],
      'Subscriptions': ['subscription', 'spotify', 'membership'],
      'Electronics': ['phone', 'laptop', 'electronics', 'charger'],
      'Gifts': ['gift', 'present'],
      'Income': [
        'salary',
        'earned',
        'received',
        'income',
        'credited',
        'credit',
        'got ',
        'gift',
        'cashback',
        'refund',
      ],
    };

    for (final entry in categoryRules.entries) {
      if (_containsAny(message, entry.value)) {
        return entry.key;
      }
    }

    return 'Other';
  }

  String _buildDescription(String message, String category) {
    final cleaned = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) {
      return category;
    }
    return cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
  }

  String _cleanMessage(String message) {
    return message
        .replaceAll(
            RegExp(r'EXPENSE_DATA:.*?:END_EXPENSE_DATA', dotAll: true), '')
        .trim();
  }

  void restoreConversation(UserModel user, List<ChatMessage> messages) {
    _conversationHistory.clear();

    var firstUserMessage = true;
    for (final message in messages) {
      if (!message.isUser &&
          message.text.contains("I'm Finbot") &&
          message.text.contains('friendly money companion')) {
        continue;
      }

      final text = message.isUser && firstUserMessage
          ? '${_buildSystemPrompt(user)}\n\nUser: ${message.text}'
          : message.text;

      _conversationHistory.add({
        'role': message.isUser ? 'user' : 'model',
        'parts': [
          {'text': text}
        ],
      });

      if (message.isUser) {
        firstUserMessage = false;
      }
    }
  }

  void clearHistory() => _conversationHistory.clear();
}
