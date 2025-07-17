import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'login_page.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  void initState() {
    super.initState();
    print('SettingPage: initState called');
  }

  @override
  Widget build(BuildContext context) {
    print('SettingPage: build called');
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Settings Page'),
            const SizedBox(height: 20),
            ThemeToggleWidget(
              isDark: theme.brightness == Brightness.dark,
              theme: theme,
              width: 140,
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: BorderRadius.circular(16),
              backgroundColor: theme.cardColor,
              borderColor: theme.dividerColor,
              borderWidth: 1.2,
              elevation: 2,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                print('SettingPage: Logout button pressed');
                
                // Show confirmation dialog
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    );
                  },
                ) ?? false;
                
                if (shouldLogout && mounted) {
                  await FirebaseAuth.instance.signOut();
                }
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}

// ThemeToggleWidget implementation
class ThemeToggleWidget extends StatefulWidget {
  final bool isDark;
  final ThemeData theme;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderWidth;
  final double? elevation;

  const ThemeToggleWidget({
    super.key,
    required this.isDark,
    required this.theme,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.elevation,
  });

  @override
  State<ThemeToggleWidget> createState() => _ThemeToggleWidgetState();
}

class _ThemeToggleWidgetState extends State<ThemeToggleWidget> {
  @override
  Widget build(BuildContext context) {
    ThemeMode currentMode = themeModeNotifier.value;
    
    return Material(
      elevation: widget.elevation ?? 3,
      borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          minWidth: widget.width ?? 120,
          maxWidth: widget.width ?? 160,
        ),
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? (widget.isDark ? Colors.grey[800] : Colors.white),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: widget.borderColor ?? widget.theme.colorScheme.primary.withAlpha(33),
            width: widget.borderWidth ?? 1.2,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<ThemeMode>(
            value: currentMode,
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                setState(() {
                  themeModeNotifier.value = newMode;
                });
              }
            },
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: widget.theme.colorScheme.primary,
              size: 20,
            ),
            style: TextStyle(
              color: widget.theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: widget.isDark ? Colors.grey[800] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 8,
            items: [
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.orange.withAlpha(51),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.light_mode,
                        color: Colors.orange,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Light'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withAlpha(51),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.dark_mode,
                        color: Colors.indigo,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Dark'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withAlpha(77),
                            Colors.indigo.withAlpha(77)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: widget.theme.colorScheme.primary,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('System'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}