import 'package:flutter/material.dart';
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

  String _formatCurrency(double amount, String? country) {
    final symbol = _getCurrencySymbol(country ?? 'India');
    if (amount >= 100000) {
      return '$symbol${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
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
        final effectiveSavings = provider.effectiveSavings;
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
                    onPressed: () async {
                      await _auth.signOut();
                      provider.clearUser();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignInScreen()),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white70, size: 22),
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
                                              effectiveSavings,
                                              user?.country),
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
                            .map((e) => _transactionTile(e, currSymbol)),
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
        final color = AppTheme.categoryColors[i % AppTheme.categoryColors.length];
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

  Widget _transactionTile(Expense expense, String symbol) {
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
            '-$symbol${expense.amount.toStringAsFixed(0)}',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.danger,
            ),
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
