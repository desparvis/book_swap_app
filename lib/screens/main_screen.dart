// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'add_book_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          ['BookSwap', 'My Books', 'Profile'][_index],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: _index == 0 || _index == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFFCD116)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBookScreen())),
                ),
              ]
            : null,
      ),
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF1A5C38),
        selectedItemColor: const Color(0xFFFCD116),
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.my_library_books), label: 'My Books'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}