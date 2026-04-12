import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../widgets/piggy_icon.dart';
import 'signin_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _incomeCtrl = TextEditingController();
  final _savingsCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _rePassCtrl = TextEditingController();

  String _selectedCountry = 'India';
  bool _obscurePass = true;
  bool _obscureRePass = true;
  bool _loading = false;
  bool _isUnemployed = false;

  final AuthService _auth = AuthService();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final c in [
      _nameCtrl, _emailCtrl, _occupationCtrl, _incomeCtrl,
      _savingsCtrl, _passCtrl, _rePassCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _checkOccupation(String value) {
    final lower = value.toLowerCase();
    final unemployed = lower.contains('unemployed') ||
        lower.contains('student') ||
        lower == 'none' ||
        lower.contains('retired') ||
        lower.contains('homemaker');
    setState(() => _isUnemployed = unemployed);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      double? income;
      if (!_isUnemployed && _incomeCtrl.text.isNotEmpty) {
        income = double.tryParse(_incomeCtrl.text);
      }
      final savings = _savingsCtrl.text.isEmpty
          ? null
          : double.tryParse(_savingsCtrl.text);

      await _auth.signUp(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passCtrl.text,
        country: _selectedCountry,
        occupation: _occupationCtrl.text,
        monthlyIncome: income,
        currentSavings: savings,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Account created successfully! Please sign in.',
            style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppTheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const SignInScreen()));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF5F0),
                Color(0xFFFFFBF5),
                Color(0xFFF0FFFE),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          const PiggyBankIcon(size: 90),
                          const SizedBox(height: 12),
                          Text(
                            'Finbot',
                            style: GoogleFonts.nunito(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            'Your friendly money companion 🐷',
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              color: AppTheme.textMid,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _sectionHeader('Personal Info'),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _emailCtrl,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          !v!.contains('@') ? 'Enter a valid email' : null,
                    ),
                    const SizedBox(height: 14),
                    _countryPicker(),
                    const SizedBox(height: 24),
                    _sectionHeader('Occupation & Finances'),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _occupationCtrl,
                      label: 'Occupation',
                      icon: Icons.work_outline_rounded,
                      hint: 'e.g., Software Engineer, Student...',
                      onChanged: _checkOccupation,
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter your occupation' : null,
                    ),
                    if (!_isUnemployed) ...[
                      const SizedBox(height: 14),
                      _buildField(
                        controller: _incomeCtrl,
                        label: 'Monthly Income',
                        icon: Icons.account_balance_wallet_outlined,
                        keyboardType: TextInputType.number,
                        hint: 'e.g., 50000',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'))
                        ],
                        validator: (v) {
                          if (_isUnemployed) return null;
                          if (v!.isEmpty) return 'Please enter your monthly income';
                          return null;
                        },
                      ),
                    ],
                    if (_isUnemployed)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: AppTheme.secondary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Monthly income is optional for your occupation',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    _buildField(
                      controller: _savingsCtrl,
                      label: 'Current Savings (optional)',
                      icon: Icons.savings_outlined,
                      keyboardType: TextInputType.number,
                      hint: 'e.g., 100000',
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                    ),
                    const SizedBox(height: 24),
                    _sectionHeader('Set Your Password'),
                    const SizedBox(height: 12),
                    _buildPasswordField(
                      controller: _passCtrl,
                      label: 'Password',
                      obscure: _obscurePass,
                      onToggle: () =>
                          setState(() => _obscurePass = !_obscurePass),
                      validator: (v) => v!.length < 6
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildPasswordField(
                      controller: _rePassCtrl,
                      label: 'Re-enter Password',
                      obscure: _obscureRePass,
                      onToggle: () =>
                          setState(() => _obscureRePass = !_obscureRePass),
                      validator: (v) =>
                          v != _passCtrl.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signUp,
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Create Account 🐷'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Already have an account? ',
                            style: GoogleFonts.nunito(color: AppTheme.textMid)),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignInScreen()),
                          ),
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.nunito(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
          letterSpacing: 1.2,
        ),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        style: GoogleFonts.nunito(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.nunito(fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        validator: validator,
      );

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.nunito(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.nunito(fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              color: AppTheme.primary, size: 20),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppTheme.textMid,
              size: 20,
            ),
          ),
        ),
        validator: validator,
      );

  Widget _countryPicker() => GestureDetector(
        onTap: () {
          showCountryPicker(
            context: context,
            onSelect: (c) => setState(() => _selectedCountry = c.name),
            countryListTheme: CountryListThemeData(
              borderRadius: BorderRadius.circular(20),
              inputDecoration: InputDecoration(
                hintText: 'Search country',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.flag_outlined, color: AppTheme.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedCountry,
                  style: GoogleFonts.nunito(fontSize: 15),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppTheme.textMid),
            ],
          ),
        ),
      );
}