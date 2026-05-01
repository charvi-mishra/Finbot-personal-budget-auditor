import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/app_provider.dart';
import '../utils/theme.dart';
import '../widgets/piggy_icon.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  final AuthService _auth = AuthService();

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await _auth.signIn(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
      if (!mounted) return;
      if (user != null) {
        context.read<AppProvider>().setUser(user);
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage(e)),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return error.message ?? 'Authentication failed. Please try again.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5F0), Color(0xFFFFFBF5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _animCtrl,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const PiggyBankIcon(size: 110),
                        const SizedBox(height: 16),
                        Text(
                          'Welcome Back!',
                          style: GoogleFonts.nunito(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          'Finbot missed you 🐷💕',
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            color: AppTheme.textMid,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.nunito(fontSize: 15),
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: GoogleFonts.nunito(fontSize: 14),
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: AppTheme.primary, size: 20),
                          ),
                          validator: (v) =>
                              !v!.contains('@') ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          style: GoogleFonts.nunito(fontSize: 15),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: GoogleFonts.nunito(fontSize: 14),
                            prefixIcon: const Icon(Icons.lock_outline_rounded,
                                color: AppTheme.primary, size: 20),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppTheme.textMid,
                                size: 20,
                              ),
                            ),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Enter your password' : null,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signIn,
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Sign In 🚀'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: GoogleFonts.nunito(
                                    color: AppTheme.textMid)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpScreen()),
                              ),
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.nunito(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
