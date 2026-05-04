import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_provider.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/piggy_icon.dart';
import '../models/expense_model.dart';
import 'chat_screen.dart';
import 'signin_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  String _formatCurrency(
    double amount,
    String? country, {
    int decimalPlaces = 0,
  }) {
    final symbol = _getCurrencySymbol(country ?? 'India');
    String formatNumber(double value) {
      if (decimalPlaces == 0) return value.toStringAsFixed(0);
      return value
          .toStringAsFixed(decimalPlaces)
          .replaceFirst(RegExp(r'\.?0+$'), '');
    }

    if (amount >= 100000) {
      return '$symbol${formatNumber(amount / 100000)}L';
    } else if (amount >= 1000) {
      return '$symbol${formatNumber(amount / 1000)}K';
    }
    return '$symbol${formatNumber(amount)}';
  }

  String _getCurrencySymbol(String country) {
    const Map<String, String> symbols = {
      'india': '₹',
      'united states': '\$',
      'united kingdom': '£',
      'europe': '€',
      'japan': '¥',
      'germany': '€',
      'france': '€',
    };
    final lower = country.toLowerCase();
    for (final e in symbols.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return '₹';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final user = provider.user;
        final expenses = provider.expenses;
        final categoryTotals = provider.categoryTotals;
        final totalSpent = provider.totalSpent;
        final currentSavings = provider.currentSavings;
        final currSymbol = _getCurrencySymbol(user?.country ?? 'India');

        return Scaffold(
          backgroundColor: AppTheme.surface,
          body: CustomScrollView(
            slivers: [
              // ── App Bar ──
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.primary,
                actions: [
                  IconButton(
                    tooltip: 'Update salary',
                    onPressed: () =>
                        _showUpdateSalaryDialog(context, provider),
                    icon: const Icon(
                      Icons.payments_outlined,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Account',
                    icon: const Icon(
                      Icons.account_circle_outlined,
                      color: Colors.white70,
                      size: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) {
                      if (value == 'logout') {
                        _logout(provider);
                      } else if (value == 'disable') {
                        _disableAccount(provider);
                      } else if (value == 'delete') {
                        _deleteAccount(provider);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            const Icon(Icons.logout_rounded, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Logout',
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'disable',
                        child: Row(
                          children: [
                            const Icon(Icons.block_rounded, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Disable account',
                              style: GoogleFonts.nunito(
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_forever_outlined,
                              size: 18,
                              color: AppTheme.danger,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Delete account',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFF6B35),
                          Color(0xFFE85D28),
                          Color(0xFFFF8C5A),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: -20,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 40),
                                Row(
                                  children: [
                                    const PiggyBankIcon(size: 44),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Hello, ${user?.name.split(' ').first ?? 'Friend'}! 👋',
                                          style: GoogleFonts.nunito(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('EEEE, d MMMM')
                                              .format(DateTime.now()),
                                          style: GoogleFonts.nunito(
                                            fontSize: 13,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Savings Card
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 08),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _miniStat(
                                          'Savings',
                                          _formatCurrency(
                                              currentSavings,
                                              user?.country,
                                              decimalPlaces: 3),
                                          Icons.savings_rounded,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.white30,
                                      ),
                                      Expanded(
                                        child: _miniStat(
                                          'Spent',
                                          _formatCurrency(
                                              totalSpent, user?.country),
                                          Icons.trending_down_rounded,
                                        ),
                                      ),
                                      if (user?.monthlyIncome != null) ...[
                                        Container(
                                          width: 1,
                                          height: 40,
                                          color: Colors.white30,
                                        ),
                                        Expanded(
                                          child: _miniStat(
                                            'Monthly Income',
                                            _formatCurrency(
                                                user!.monthlyIncome!,
                                                user.country),
                                            Icons.account_balance_wallet_rounded,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Body Content ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Spending
                      if (categoryTotals.isNotEmpty) ...[
                        _sectionTitle('Spending by Category'),
                        const SizedBox(height: 14),
                        _categoryChart(categoryTotals, totalSpent, currSymbol),
                        const SizedBox(height: 24),
                        _categoryGrid(
                            categoryTotals, totalSpent, currSymbol),
                        const SizedBox(height: 28),
                      ] else ...[
                        _emptyState(),
                      ],

                      // Recent Transactions
                      if (expenses.isNotEmpty) ...[
                        _sectionTitle('Recent Transactions'),
                        const SizedBox(height: 14),
                        ...expenses
                            .take(10)
                            .map(
                              (e) => _transactionTile(e, currSymbol, provider),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Floating Chat Button ──
          floatingActionButton: ScaleTransition(
            scale: CurvedAnimation(
              parent: _fabAnim,
              curve: Curves.elasticOut,
            ),
            child: FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              ),
              backgroundColor: AppTheme.primary,
              elevation: 8,
              icon: const PiggyBankIcon(size: 32),
              label: Text(
                'Chat with Finbot',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40)),
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(String label, String value, IconData icon) => Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 10,
              color: Colors.white60,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  void _goToSignIn() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
  }

  Future<void> _logout(AppProvider provider) async {
    await _auth.signOut();
    provider.clearUser();
    if (!mounted) return;
    _goToSignIn();
  }

  Future<bool> _confirmAccountAction({
    required String title,
    required String message,
    required String actionLabel,
    bool danger = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            content: Text(
              message,
              style: GoogleFonts.nunito(color: AppTheme.textMid),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
              ),
              ElevatedButton(
                style: danger
                    ? ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                      )
                    : null,
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(actionLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _disableAccount(AppProvider provider) async {
    final confirmed = await _confirmAccountAction(
      title: 'Disable Account?',
      message:
          'You will be signed out and this account will be blocked from signing in again.',
      actionLabel: 'Disable',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.disableAccount();
      if (!mounted) return;
      _goToSignIn();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not disable account. Please try again.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _deleteAccount(AppProvider provider) async {
    final confirmed = await _confirmAccountAction(
      title: 'Delete Account?',
      message:
          'This permanently deletes your account and saved transactions. You may need to sign in again first if Firebase requires recent login.',
      actionLabel: 'Delete',
      danger: true,
    );
    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.deleteAccount();
      if (!mounted) return;
      _goToSignIn();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete account. Sign in again, then try once more.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _showUpdateSalaryDialog(
    BuildContext context,
    AppProvider provider,
  ) async {
    final user = provider.user;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final salary = await showDialog<double>(
      context: context,
      builder: (_) => _UpdateSalaryDialog(
        initialSalary: user.monthlyIncome,
        currencySymbol: _getCurrencySymbol(user.country),
      ),
    );

    if (salary == null || !mounted) return;

    try {
      await provider.updateMonthlyIncome(salary);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Salary updated',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not update salary. Please try again.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppTheme.textDark,
        ),
      );

  Widget _categoryChart(
      Map<String, double> totals, double total, String symbol) {
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(
                  entries.length > 6 ? 6 : entries.length,
                  (i) {
                    final pct = entries[i].value / total * 100;
                    return PieChartSectionData(
                      value: entries[i].value,
                      color: AppTheme.categoryColors[
                          i % AppTheme.categoryColors.length],
                      radius: 40,
                      title: '${pct.toStringAsFixed(0)}%',
                      titleStyle: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                entries.length > 6 ? 6 : entries.length,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.categoryColors[
                              i % AppTheme.categoryColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entries[i].key,
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: AppTheme.textMid,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$symbol${entries[i].value.toStringAsFixed(0)}',
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryGrid(
      Map<String, double> totals, double total, String symbol) {
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final entry = entries[i];
        final color =
            AppTheme.categoryColors[i % AppTheme.categoryColors.length];
        final pct = total > 0 ? entry.value / total : 0.0;

        // Find the emoji for this category
        final tempExpense = Expense(
          id: '',
          userId: '',
          amount: 0,
          currency: '',
          category: entry.key,
          description: '',
          date: DateTime.now(),
          rawMessage: '',
          isExpense: true,
        );

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tempExpense.categoryEmoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.textMid,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$symbol${entry.value.toStringAsFixed(0)}',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _askReflectInSavings({
    required String title,
    required String message,
    required String plainAction,
    required String savingsAction,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.nunito(color: AppTheme.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              plainAction,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              savingsAction,
              style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTransactionDialog(
    Expense expense,
    AppProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final updatedExpense = await showDialog<Expense>(
      context: context,
      builder: (_) => _EditTransactionDialog(expense: expense),
    );

    if (updatedExpense == null || !mounted) return;

    final reflectInSavings = await _askReflectInSavings(
      title: 'Update Savings?',
      message: 'Should this edit also adjust your current savings?',
      plainAction: 'Only transaction',
      savingsAction: 'Update savings',
    );
    if (reflectInSavings == null || !mounted) return;

    try {
      await provider.updateExpense(
        expense,
        updatedExpense,
        reflectInSavings: reflectInSavings,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            reflectInSavings
                ? 'Transaction and savings updated'
                : 'Transaction updated',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not update transaction. Please try again.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _deleteTransaction(
    Expense expense,
    AppProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final reflectInSavings = await _askReflectInSavings(
      title: 'Delete Transaction?',
      message:
          'Should deleting this transaction also adjust your current savings?',
      plainAction: 'Only delete',
      savingsAction: 'Delete and update',
    );
    if (reflectInSavings == null || !mounted) return;

    try {
      await provider.deleteExpense(
        expense,
        reflectInSavings: reflectInSavings,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            reflectInSavings
                ? 'Transaction deleted and savings updated'
                : 'Transaction deleted',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete transaction. Please try again.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _transactionTile(
    Expense expense,
    String symbol,
    AppProvider provider,
  ) {
    final amountColor = expense.isExpense ? AppTheme.danger : AppTheme.success;
    final amountPrefix = expense.isExpense ? '-' : '+';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                expense.categoryEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                if (expense.description.isNotEmpty)
                  Text(
                    expense.description,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppTheme.textMid,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  DateFormat('d MMM, yyyy').format(expense.date),
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$amountPrefix$symbol${expense.amount.toStringAsFixed(0)}',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textMid),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditTransactionDialog(expense, provider);
              } else if (value == 'delete') {
                _deleteTransaction(expense, provider);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Edit',
                      style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppTheme.danger,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Delete',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Container(
        margin: const EdgeInsets.only(top: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PiggyBankIcon(size: 100),
            const SizedBox(height: 20),
            Text(
              'No expenses yet! 🎉',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the Finbot button below\nand tell me what you spent today!',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppTheme.textMid,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                '💬 "I spent ₹500 on groceries today"',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _UpdateSalaryDialog extends StatefulWidget {
  const _UpdateSalaryDialog({
    required this.initialSalary,
    required this.currencySymbol,
  });

  final double? initialSalary;
  final String currencySymbol;

  @override
  State<_UpdateSalaryDialog> createState() => _UpdateSalaryDialogState();
}

class _UpdateSalaryDialogState extends State<_UpdateSalaryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _salaryCtrl;

  @override
  void initState() {
    super.initState();
    _salaryCtrl = TextEditingController(
      text: widget.initialSalary?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _salaryCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(double.parse(_salaryCtrl.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Update Salary',
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          color: AppTheme.textDark,
        ),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _salaryCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r'^\d+\.?\d{0,2}'),
            ),
          ],
          style: GoogleFonts.nunito(fontSize: 15),
          decoration: InputDecoration(
            labelText: 'Monthly Salary',
            prefixText: widget.currencySymbol,
            prefixIcon: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
          validator: (value) {
            final salary = double.tryParse(value?.trim() ?? '');
            if (salary == null) return 'Enter your monthly salary';
            if (salary < 0) return 'Salary cannot be negative';
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _EditTransactionDialog extends StatefulWidget {
  const _EditTransactionDialog({required this.expense});

  final Expense expense;

  @override
  State<_EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<_EditTransactionDialog> {
  static const _expenseCategories = [
    'Food',
    'Groceries',
    'Clothing',
    'Transport',
    'Entertainment',
    'Health',
    'Education',
    'Utilities',
    'Rent',
    'Shopping',
    'Coffee',
    'Fuel',
    'Gym',
    'Subscriptions',
    'Electronics',
    'Gifts',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descriptionCtrl;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late bool _isExpense;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _amountCtrl = TextEditingController(
      text: expense.amount.toStringAsFixed(
        expense.amount.truncateToDouble() == expense.amount ? 0 : 2,
      ),
    );
    _descriptionCtrl = TextEditingController(text: expense.description);
    _isExpense = expense.isExpense;
    _selectedDate = expense.date;
    _selectedCategory = _initialCategory(expense);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  String _initialCategory(Expense expense) {
    if (!expense.isExpense) return 'Income';
    return _expenseCategories.contains(expense.category)
        ? expense.category
        : 'Other';
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final expense = widget.expense;
    Navigator.of(context).pop(
      Expense(
        id: expense.id,
        userId: expense.userId,
        amount: double.parse(_amountCtrl.text.trim()),
        currency: expense.currency,
        category: _isExpense ? _selectedCategory : 'Income',
        description: _descriptionCtrl.text.trim(),
        date: _selectedDate,
        rawMessage: expense.rawMessage,
        isExpense: _isExpense,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final categories = _isExpense ? _expenseCategories : const ['Income'];

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        'Edit Transaction',
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          color: AppTheme.textDark,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.trending_down_rounded),
                    label: Text('Expense'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.trending_up_rounded),
                    label: Text('Income'),
                  ),
                ],
                selected: {_isExpense},
                onSelectionChanged: (selection) {
                  setState(() {
                    _isExpense = selection.first;
                    _selectedCategory = _isExpense ? 'Other' : 'Income';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}'),
                  ),
                ],
                style: GoogleFonts.nunito(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                style: GoogleFonts.nunito(fontSize: 15),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_rounded),
                title: Text(
                  DateFormat('d MMM, yyyy').format(_selectedDate),
                  style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
                ),
                trailing: const Icon(Icons.edit_calendar_rounded),
                onTap: _pickDate,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
