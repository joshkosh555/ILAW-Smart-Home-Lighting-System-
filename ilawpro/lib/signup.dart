import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ilawpro/loginpage.dart';
import 'homepage.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  static const _red = Color(0xFF8B0000);

  Future<void> signUp() async {
    final emailText = email.text.trim();
    final passwordText = password.text.trim();

    if (emailText.isEmpty || passwordText.isEmpty) {
      _snack("Missing Fields", "Please enter both email and password");
      return;
    }

    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(emailText)) {
      _snack("Invalid Email", "Please enter a valid email address.");
      return;
    }

    if (passwordText.length < 6) {
      _snack("Weak Password", "Password must be at least 6 characters");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailText,
        password: passwordText,
      );
      Get.offAll(() => const HomePage());
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use'  => "This email is already registered. Try logging in instead.",
        'invalid-email'         => "The email address is not valid.",
        'operation-not-allowed' => "Email/password sign-up is currently disabled.",
        'weak-password'         => "Your password is too weak. Try something stronger.",
        _                       => "Sign up failed: ${e.code}",
      };
      _snack("Sign Up Failed", msg, icon: Icons.error_outline);
    } catch (e) {
      _snack("Sign Up Failed", e.toString());
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
                      style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      "Create an account",
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
                      "Sign up to get started",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // ── Email field ───────────────────────
              _label("Email"),
              const SizedBox(height: 8),
              _inputField(
                controller: email,
                hint: "you@example.com",
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // ── Password field ────────────────────
              _label("Password"),
              const SizedBox(height: 8),
              _inputField(
                controller: password,
                hint: "Min. 6 characters",
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 8),

              // ── Password hint ─────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  "Use at least 6 characters",
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ),

              const SizedBox(height: 36),

              // ── Sign up button ────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : signUp,
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
                    "Create Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Log in link ───────────────────────
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Already have an account?  ",
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

  // ── Helpers ──────────────────────────────────────
  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF444444),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
      ),
    );
  }
}