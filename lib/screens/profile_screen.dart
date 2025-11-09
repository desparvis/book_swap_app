// lib/screens/profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final auth = Provider.of<AppAuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A5C38),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 50, backgroundColor: const Color(0xFFFCD116), child: const Icon(Icons.person, size: 60, color: Colors.black)),
              const SizedBox(height: 16),
              Text(user.displayName ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(user.email ?? '', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.black),
                label: const Text('Sign Out', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFCD116), padding: const EdgeInsets.symmetric(vertical: 16), minimumSize: const Size(double.infinity, 50)),
                onPressed: () => _signOut(context, auth),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _signOut(BuildContext context, AppAuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A5C38),
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: Color(0xFFFCD116)))),
        ],
      ),
    );
    if (confirm == true) {
      await auth.signOut(context);
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}