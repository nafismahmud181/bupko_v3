import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(user?.email ?? 'Guest'),
            subtitle: const Text('Current user'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Dark Mode'),
            trailing: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, mode, _) {
                return Switch(
                  value: mode == ThemeMode.dark,
                  onChanged: (val) {
                    themeModeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),
          ),
          const Divider(),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    );
  }
} 