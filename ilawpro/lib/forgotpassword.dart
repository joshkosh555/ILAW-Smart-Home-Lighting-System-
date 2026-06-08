import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'loginpage.dart';

class ForgotPass extends StatefulWidget {
  const ForgotPass({super.key});

  @override
  State<ForgotPass> createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  final TextEditingController email = TextEditingController();
  bool _isLoading = false;

  static const _red = Color(0xFF8B0000);

  Future<void> forgotPass() async {
    final emailText = email.text.trim();

    if (emailText.isEmpty) {
      _snack("Missing Field", "Please enter your email address.");
      return;
    }

    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(emailText)) {
      _snack("Invalid Email", "Please enter a valid email address.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailText);
      _snack("Email Sent", "A password reset link has been sent to your email.",
          icon: Icons.check_circle_outline);
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found'         => "No account found with this email.",
        'invalid-email'          => "The email address is not valid.",
        'network-request-failed' => "No internet connection. Please check your network.",
        _                        => "Error: ${e.code}",
      };
      _snack("Failed", msg, icon: Icons.error_outline);
    } catch (e) {
      _snack("Failed", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String title, String message,
      {IconData icon = Icons.info_outline}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(message,
                      style:
                      const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Back button ───────────────────────
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: _red, size: 20),
                padding: EdgeInsets.zero,
                onPressed: () => Get.off(() => const LoginPage()),
              ),


              // ── Logo ─────────────────────────────
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/red_bulb.png',
                      width: 52,
                      height: 52,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),


              // ── Headline ──────────────────────────
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Forgot password?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Enter your email and we'll send you a reset link",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── Email label ───────────────────────
              const Text(
                "Email",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF444444),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),

              // ── Email field ───────────────────────
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                style:
                const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
                decoration: InputDecoration(
                  hintText: "you@example.com",
                  hintStyle:
                  TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.mail_outline_rounded,
                      color: Colors.grey[400], size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Color(0xFFE8E8E8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: _red, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Send button ───────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : forgotPass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _red.withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text(
                    "Send Reset Link",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Back to login link ────────────────
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Remember your password?  ",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.off(() => const LoginPage()),
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          color: _red,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}