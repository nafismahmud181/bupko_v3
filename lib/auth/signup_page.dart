import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await credential.user?.updateDisplayName(_nameController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(); // Go back to login after signup
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Signup failed. Please try again.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
                ? [
                    theme.colorScheme.primary, // 0xFF667EEA
                    theme.colorScheme.primaryContainer, // 0xFF764BA2
                  ]
                : [
                    theme.colorScheme.secondary, // 0xFF667EEA
                    theme.colorScheme.secondaryContainer, // 0xFF764BA2
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and sign in option
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Spacer(),
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // App name
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'BUPKO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Main content card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 40),
                  decoration: BoxDecoration(
                    color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 10),
                          
                          // Title
                          Text(
                            'Get started free.',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Subtitle
                          Text(
                            'Free forever. No credit card needed.',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Email field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: 'nicholas@ergemia.com',
                                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.colorScheme.outline),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (value) => value == null || !value.contains('@') ? 'Enter a valid email' : null,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Name field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Name',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: 'Nicholas Ergemia',
                                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.colorScheme.outline),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.colorScheme.outline),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (value) => value == null || value.trim().isEmpty ? 'Enter your name' : null,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Password field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Strong',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  hintText: '••••••••••••',
                                  hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.colorScheme.outline),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.colorScheme.outline),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Error message
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: theme.colorScheme.error),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          
                          // Sign up button
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark 
                                    ? [theme.colorScheme.primary, theme.colorScheme.primaryContainer]
                                    : [theme.colorScheme.secondary, theme.colorScheme.secondaryContainer],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _signup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Sign up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Or sign up with
                          Row(
                            children: [
                              Expanded(child: Divider(color: theme.colorScheme.outline)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Or sign up with',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: theme.colorScheme.outline)),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Social buttons
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.colorScheme.outline),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      // Handle Google sign up
                                    },
                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/logo/google.png', // You'll need to add this asset
                                          height: 20,
                                          width: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Google',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: theme.colorScheme.outline),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextButton(
                                    onPressed: () {
                                      // Handle Google sign up
                                    },
                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/logo/facebook.png', // You'll need to add this asset
                                          height: 20,
                                          width: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Facebook',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
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
            ],
          ),
        ),
      ),
    );
  }
}