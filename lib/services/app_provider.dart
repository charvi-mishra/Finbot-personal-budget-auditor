import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../services/auth_service.dart';
import '../services/expense_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

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
    for (final e in _expenses.where((expense) => expense.isExpense)) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  double get totalSpent => _expenses
      .where((expense) => expense.isExpense)
      .fold(0, (sum, e) => sum + e.amount);

  double get currentSavings {
    if (_user == null) return 0;
    return _user!.currentSavings ?? 0;
  }

  double _savingsImpact(Expense expense) =>
      expense.isExpense ? -expense.amount : expense.amount;

  double _roundSavings(double amount) =>
      double.parse(amount.toStringAsFixed(3));

  Future<void> updateExpense(
    Expense oldExpense,
    Expense updatedExpense, {
    required bool reflectInSavings,
  }) async {
    await _expenseService.updateExpense(updatedExpense);

    if (reflectInSavings && _user != null) {
      final delta = _savingsImpact(updatedExpense) - _savingsImpact(oldExpense);
      final nextSavings = _roundSavings(
        (currentSavings + delta).clamp(0, double.infinity).toDouble(),
      );
      await _authService.updateSavings(_user!.uid, nextSavings);
      await refreshUser();
    }
  }

  Future<void> deleteExpense(
    Expense expense, {
    required bool reflectInSavings,
  }) async {
    await _expenseService.deleteExpense(expense.id);

    if (reflectInSavings && _user != null) {
      final delta = -_savingsImpact(expense);
      final nextSavings = _roundSavings(
        (currentSavings + delta).clamp(0, double.infinity).toDouble(),
      );
      await _authService.updateSavings(_user!.uid, nextSavings);
      await refreshUser();
    }
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

  Future<void> updateMonthlyIncome(double monthlyIncome) async {
    if (_user == null) return;
    await _authService.updateMonthlyIncome(_user!.uid, monthlyIncome);
    _user = _user!.copyWith(monthlyIncome: monthlyIncome);
    notifyListeners();
  }

  Future<void> disableAccount() async {
    if (_user == null) return;
    await _authService.disableAccount(_user!.uid);
    clearUser();
  }

Future<void> reEnableAccount(String uid) async {
  await _authService.reEnableAccount(uid);
  await refreshUser();
}

  Future<void> deleteAccount() async {
    await _authService.deleteCurrentAccount();
    clearUser();
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
