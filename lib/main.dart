// Updated main.dart - AppWrapper and AuthGate
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'package:provider/provider.dart';
import 'bottom_nav.dart';
import 'bottom_nav_provider.dart';
import 'splash_screen.dart';
import 'app_theme.dart';
import 'dart:async';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Ebook Library',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/main': (context) => const AuthGate(),
          },
        );
      },
    );
  }
}

// Use StreamBuilder approach for more reliable auth state management
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    final user = FirebaseAuth.instance.currentUser;
    
    setState(() {
      _currentUser = user;
      _isLoading = false;
    });

    // Listen to auth changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
        
        // Reset navigation to home page when user logs in
        if (user != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final navProvider = Provider.of<BottomNavProvider>(context, listen: false);
            navProvider.setIndex(0);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser != null) {
      return const BottomNav();
    }

    return const LoginPage();
  }
}

// Alternative AuthGate with manual state management (use this if StreamBuilder doesn't work)
class AuthGateManual extends StatefulWidget {
  const AuthGateManual({super.key});

  @override
  State<AuthGateManual> createState() => _AuthGateManualState();
}

class _AuthGateManualState extends State<AuthGateManual> {
  User? _user;
  bool _isLoading = true;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  void _initializeAuth() async {
    // Check current user first
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      setState(() {
        _user = currentUser;
        _isLoading = false;
      });
    }
    
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        if (mounted) {
          setState(() {
            _user = user;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_user != null) {
      return const BottomNav();
    }
    
    return const LoginPage();
  }
}