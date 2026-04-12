import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ExpenseService _expenseService = ExpenseService();

  UserModel? _user;
  List<Expense> _expenses = [];
  bool _loading = false;

  UserModel? get user => _user;
  List<Expense> get expenses => _expenses;
  bool get loading => _loading;

  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {};
    for (final e in _expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  double get totalSpent => _expenses.fold(0, (sum, e) => sum + e.amount);

  double get effectiveSavings {
    if (_user == null) return 0;
    final income = _user!.monthlyIncome ?? 0;
    final savings = _user!.currentSavings ?? 0;
    return savings + income;
  }

  Future<void> loadUser(String uid) async {
    _loading = true;
    notifyListeners();
    _user = await _authService.getUser(uid);
    _loading = false;
    notifyListeners();
    _listenToExpenses(uid);
  }

  void _listenToExpenses(String uid) {
    _expenseService.watchUserExpenses(uid).listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  Future<void> refreshUser() async {
    if (_user == null) return;
    _user = await _authService.getUser(_user!.uid);
    notifyListeners();
  }

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
    _listenToExpenses(user.uid);
  }

  void clearUser() {
    _user = null;
    _expenses = [];
    notifyListeners();
  }
}
