import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';
import '../widgets/piggy_icon.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';

class VerifyEmailScreen extends StatelessWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PiggyBankIcon(size: 96),
                  const SizedBox(height: 24),
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      color: AppTheme.secondary,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      color: AppTheme.textMid,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please verify your email before signing in. If you do not see the email, check your spam or junk folder.',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              height: 1.35,
                              color: AppTheme.textMid,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      ),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('I Verified, Go to Sign In'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: Text(
                      'Use a different email',
                      style: GoogleFonts.nunito(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
