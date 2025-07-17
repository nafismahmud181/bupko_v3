import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-fill email as shown in the image
    _emailController.text = 'nicholas@ergemia.com';
  }

  // Future<void> _login() async {
  //   setState(() {
  //     _loading = true;
  //     _error = null;
  //   });
  //   try {
  //     await FirebaseAuth.instance.signInWithEmailAndPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //     );
  //   } on FirebaseAuthException catch (e) {
  //     setState(() {
  //       _error = e.message;
  //     });
  //   } finally {
  //     setState(() {
  //       _loading = false;
  //     });
  //   }
  // }
    // Updated login method for your LoginPage
  Future<void> _login() async {
  // Prevent multiple login attempts
  if (_loading) {
    return;
  }
  
  // Validate input
  if (_emailController.text.trim().isEmpty) {
    setState(() {
      _error = 'Please enter your email';
    });
    return;
  }
  
  if (_passwordController.text.trim().isEmpty) {
    setState(() {
      _error = 'Please enter your password';
    });
    return;
  }
  
    setState(() {
      _loading = true;
      _error = null;
    });
  
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  
  try {
    
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Double-check current user after login
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // The AuthGate StreamBuilder should automatically pick up this change
      // and navigate to BottomNav
      
      // Optional: Force a small delay to ensure auth state propagates
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Double-check again
      final finalUser = FirebaseAuth.instance.currentUser;
      
    } else {
      setState(() {
        _error = 'Login failed - please try again';
      });
    }
    
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found for that email.';
        break;
      case 'wrong-password':
        errorMessage = 'Wrong password provided.';
        break;
      case 'invalid-email':
        errorMessage = 'Invalid email address.';
        break;
      case 'user-disabled':
        errorMessage = 'User account has been disabled.';
        break;
      case 'too-many-requests':
        errorMessage = 'Too many login attempts. Please try again later.';
        break;
      case 'network-request-failed':
        errorMessage = 'Network error. Please check your connection.';
        break;
      case 'invalid-credential':
        errorMessage = 'Invalid email or password.';
        break;
      case 'user-token-expired':
        errorMessage = 'Session expired. Please log in again.';
        break;
      default:
        errorMessage = e.message ?? 'An error occurred. Please try again.';
    }
    
    setState(() {
      _error = errorMessage;
    });
    
  } catch (e) {
    setState(() {
      _error = 'An unexpected error occurred. Please try again.';
      });
    } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}

// Add this method to test Firebase connection
Future<void> _testFirebaseConnection() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
  // ignore: empty_catches
  } catch (e) {
  }
}
  Future<void> _signInWithGoogle() async {
    // Implement Google sign-in logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Sign-In not implemented yet')),
    );
  }

  Future<void> _signInWithFacebook() async {
    // Implement Facebook sign-in logic here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Facebook Sign-In not implemented yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [
                  const Color(0xFF667EEA),
                  const Color(0xFF764BA2),
                ]
              : [
                  const Color(0xFF667EEA),
                  const Color(0xFF29B6F6),
                ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Section with Back Button and Get Started
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    Row(
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SignupPage()),
                            );
                          },
                          child: const Text(
                            'Get Started',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Jobsly Title
              const Text(
                'Jobsly',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Main Content Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: SingleChildScrollView(
        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                          // Welcome Back Title
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your details below',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Email Field
                          Text(
                            'Email Address',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withValues(alpha: 0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withValues(alpha: 0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                ),
                              ),
                              filled: true,
                              fillColor: theme.cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Password Field
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••••••',
                              hintStyle: TextStyle(
                                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withValues(alpha: 0.2),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.dividerColor.withValues(alpha: 0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                ),
                              ),
                              filled: true,
                              fillColor: theme.cardColor,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Error Message
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          
                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark 
                                    ? [
                                        const Color(0xFF667EEA),
                                        const Color(0xFF764BA2),
                                      ]
                                    : [
                                        const Color(0xFF667EEA),
                                        const Color(0xFF29B6F6),
                                      ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Forgot Password
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // Implement forgot password logic
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Forgot password not implemented yet')),
                                );
                              },
                              child: Text(
                                'Forgot your password?',
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Or sign in with
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: theme.dividerColor.withValues(alpha: 0.3),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Or sign in with',
                                  style: TextStyle(
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: theme.dividerColor.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                          
            const SizedBox(height: 24),
                          
                          // Social Sign In Buttons
                          Row(
                            children: [
                              // Google Sign In
                              Expanded(
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: theme.dividerColor.withValues(alpha: 0.2),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextButton(
                                    onPressed: _signInWithGoogle,
                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/google_logo.png', // Add Google logo asset
                                          height: 20,
                                          width: 20,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.g_mobiledata,
                                              size: 24,
                                              color: Colors.red,
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Google',
                                          style: TextStyle(
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
                              
                              // Facebook Sign In
                              Expanded(
                                child: Container(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: theme.dividerColor.withValues(alpha: 0.2),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextButton(
                                    onPressed: _signInWithFacebook,
                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/facebook_logo.png', // Add Facebook logo asset
                                          height: 20,
                                          width: 20,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.facebook,
                                              size: 24,
                                              color: Colors.blue,
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Facebook',
                                          style: TextStyle(
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
} 