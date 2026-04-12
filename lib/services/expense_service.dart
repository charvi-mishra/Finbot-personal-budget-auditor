import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _expenses => _db.collection('expenses');

  Future<Expense> addExpense(Expense expense) async {
    final doc = await _expenses.add(expense.toMap());
    return Expense.fromMap(expense.toMap(), doc.id);
  }

  // NOTE: This query requires a Firestore composite index on (userId ASC, date DESC).
  // If the app crashes on first run, check your debug logs for the Firebase Console
  // index creation URL and tap it to auto-create the index.
  Stream<List<Expense>> watchUserExpenses(String userId) {
    return _expenses
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<List<Expense>> getUserExpenses(String userId) async {
    final snap = await _expenses
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs
        .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
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
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    // NOTE: This query also requires a composite index on (userId ASC, date ASC).
    // Same as above — Firebase will print the index URL in logs if missing.
    final snap = await _expenses
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    return snap.docs
        .map((d) => Expense.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList();
  }
}