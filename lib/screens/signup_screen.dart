// lib/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';
import 'verify_email_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true; // ← VISIBILITY STATE

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A5C38),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - kToolbarHeight,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      const Text('Create Account', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      const Text('Join the book swap community', style: TextStyle(fontSize: 16, color: Colors.white70)),
                      const SizedBox(height: 50),

                      // NAME
                      _buildTextField(controller: _nameController, label: 'Full Name', icon: Icons.person, validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null),
                      const SizedBox(height: 16),

                      // EMAIL
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                      ),
                      const SizedBox(height: 16),

                      // PASSWORD WITH TOGGLE
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 30),

                      // SIGN UP BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _signup(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFCD116),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 8,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signup(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final auth = Provider.of<AppAuthProvider>(context, listen: false);

    try {
      await auth.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        context: context,
      );
      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VerifyEmailScreen()));
      }
    } catch (e) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                onPressed: onToggle,
              )
            : null,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Color(0xFFFCD116), width: 2)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      ),
    );
  }
}