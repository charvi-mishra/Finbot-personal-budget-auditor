import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _expenses => _db.collection('expenses');

  Future<Expense> addExpense(Expense expense) async {
    final doc = await _expenses.add(expense.toMap());
    return Expense.fromMap(expense.toMap(), doc.id);
  }

  Future<void> updateExpense(Expense expense) async {
    await _expenses.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expenses.doc(expenseId).delete();
  }

  Stream<List<Expense>> watchUserExpenses(String userId) {
    return _expenses.where('userId', isEqualTo: userId).snapshots().map((snap) {
      final expenses = snap.docs
          .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      expenses.sort((a, b) => b.date.compareTo(a.date));
      return expenses;
    });
  }

  Future<List<Expense>> getUserExpenses(String userId) async {
    final snap = await _expenses.where('userId', isEqualTo: userId).get();
    final expenses = snap.docs
        .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  Future<Map<String, double>> getCategoryTotals(String userId) async {
    final expenses = await getUserExpenses(userId);
    final Map<String, double> totals = {};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  /// Returns expenses for the current month only
  Future<List<Expense>> getCurrentMonthExpenses(String userId) async {
    final now = DateTime.now();
    final expenses = await getUserExpenses(userId);
    return expenses
        .where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        )
        .toList();
  }
}
