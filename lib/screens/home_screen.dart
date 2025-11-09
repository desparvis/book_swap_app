// lib/screens/home_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../providers/book_provider.dart';
import '../providers/app_auth_provider.dart';
import '../models/book_model.dart';
import 'add_book_screen.dart';

class Styling {
  static const boldWhite = TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14);
  static const smallWhite = TextStyle(color: Colors.white70, fontSize: 11);
  static const tinyGray = TextStyle(color: Colors.white60, fontSize: 9);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A5C38),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          ['Browse', 'My Books', 'Offers', 'Settings'][_index],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 22),
        ),
        actions: _index <= 1
            ? [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFFFCD116), size: 28),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddBookScreen())),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: _index == 0
          ? const _BrowseTab()
          : _index == 1
              ? const _MyBooksTab()
              : _index == 2
                  ? const _MyOffersTab()
                  : const _SettingsTab(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: const Color(0xFF1A5C38),
        selectedItemColor: const Color(0xFFFCD116),
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.my_library_books), label: 'My Books'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Offers'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// REUSABLE CARD — NO OVERFLOW
Widget _buildBookCard({
  required Book b,
  required bool isMine,
  required Widget trailing,
  bool showRequest = false,
}) {
  return Card(
    color: Colors.white.withOpacity(0.08),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: b.imageBase64 != null
                ? Image.memory(
                    base64Decode(b.imageBase64!),
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 60,
                    height: 80,
                    color: Colors.white24,
                    child: const Icon(Icons.book, color: Colors.white70, size: 24),
                  ),
          ),
          const SizedBox(width: 10),

          // TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title, style: Styling.boldWhite, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 1),
                Text('by ${b.author}', style: Styling.smallWhite, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: _statusColor(b.status), borderRadius: BorderRadius.circular(10)),
                      child: Text(b.status, style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('by ${b.ownerName}', style: Styling.tinyGray, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                if (showRequest && b.swapRequest != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('From: ${b.swapRequest!.fromUserName}', style: const TextStyle(color: Color(0xFFFCD116), fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),

          // TRAILING — TIGHT
          SizedBox(
            width: 60,
            child: Center(child: trailing),
          ),
        ],
      ),
    ),
  );
}

Color _statusColor(String status) {
  switch (status) {
    case 'available': return Colors.green;
    case 'pending': return Colors.orange;
    case 'swapped': return Colors.purple;
    default: return Colors.grey;
  }
}

// BROWSE TAB
class _BrowseTab extends StatelessWidget {
  const _BrowseTab();
  @override Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<List<Book>>(
      stream: Provider.of<BookProvider>(context).getAllBooks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error', style: TextStyle(color: Colors.red)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFCD116)));

        final books = snapshot.data!;
        if (books.isEmpty) {
          return const Center(child: Text('No books yet.\nBe the first!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 18)));
        }

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, i) {
            final b = books[i];
            final isMine = b.ownerId == userId;

            final trailing = isMine
                ? const SizedBox()
                : (b.status == 'available' || b.status == 'swapped')
                    ? SizedBox(
                        height: 28,
                        child: ElevatedButton(
                          onPressed: () => _requestSwap(context, b.id, b.title),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFCD116),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Swap', style: TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      )
                    : const Icon(Icons.lock, color: Colors.grey, size: 16);

            return _buildBookCard(b: b, isMine: isMine, trailing: trailing);
          },
        );
      },
    );
  }
}

// MY BOOKS TAB — NO OVERFLOW
class _MyBooksTab extends StatelessWidget {
  const _MyBooksTab();
  @override Widget build(BuildContext context) {
    return StreamBuilder<List<Book>>(
      stream: Provider.of<BookProvider>(context).getMyBooks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error', style: TextStyle(color: Colors.red)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFCD116)));

        final books = snapshot.data!;
        if (books.isEmpty) return const Center(child: Text('No books posted.', style: TextStyle(color: Colors.white70)));

        return ListView.builder(
          itemCount: books.length,
          itemBuilder: (context, i) {
            final b = books[i];
            final hasRequest = b.swapRequest != null;

            final trailing = hasRequest
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          icon: const Icon(Icons.check, color: Colors.green, size: 16),
                          onPressed: () => _handleSwap(context, b.id, true),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 16),
                          onPressed: () => _handleSwap(context, b.id, false),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFFFCD116), size: 14),
                          onPressed: () => _editBook(context, b),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 14),
                          onPressed: () => _deleteBook(context, b.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  );

            return _buildBookCard(b: b, isMine: true, trailing: trailing, showRequest: hasRequest);
          },
        );
      },
    );
  }
}

// OFFERS TAB
class _MyOffersTab extends StatelessWidget {
  const _MyOffersTab();
  @override Widget build(BuildContext context) {
    return StreamBuilder<List<Book>>(
      stream: Provider.of<BookProvider>(context).getMyPendingOffers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFCD116)));
        final offers = snapshot.data!;
        if (offers.isEmpty) return const Center(child: Text('No pending offers.', style: TextStyle(color: Colors.white70)));

        return ListView.builder(
          itemCount: offers.length,
          itemBuilder: (context, i) {
            final b = offers[i];
            return _buildBookCard(
              b: b,
              isMine: false,
              trailing: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('Pending', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }
}

// SETTINGS TAB
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();
  @override State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final auth = Provider.of<AppAuthProvider>(context);

    if (user == null) {
      return const Center(child: Text('Not logged in', style: TextStyle(color: Colors.red)));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(radius: 50, backgroundColor: const Color(0xFFFCD116), child: Text(user.displayName?[0].toUpperCase() ?? 'U', style: const TextStyle(fontSize: 40, color: Colors.black, fontWeight: FontWeight.bold))),
          const SizedBox(height: 16),
          Text(user.displayName ?? 'User', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
          Text(user.email ?? '', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 30),

          Card(
            color: Colors.white.withOpacity(0.08),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: SwitchListTile(
              title: const Text('Push Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Get notified on swap requests', style: TextStyle(color: Colors.white70)),
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
              activeColor: const Color(0xFFFCD116),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.black),
              label: const Text('Sign Out', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFCD116), padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () => _signOut(context, auth),
            ),
          ),
        ],
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
      if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

// ——— FUNCTIONS ———

void _requestSwap(BuildContext context, String bookId, String title) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A5C38),
      title: const Text('Request Swap?', style: TextStyle(color: Colors.white)),
      content: Text('Swap for "$title"?', style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send', style: TextStyle(color: Color(0xFFFCD116)))),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await Provider.of<BookProvider>(context, listen: false).requestSwap(bookId, title);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap requested!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

void _editBook(BuildContext context, Book book) async {
  final titleCtrl = TextEditingController(text: book.title);
  final authorCtrl = TextEditingController(text: book.author);
  String condition = book.condition;
  String? newImageBase64 = book.imageBase64;

  final picker = ImagePicker();

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setStateDialog) => AlertDialog(
        backgroundColor: const Color(0xFF1A5C38),
        title: const Text('Edit Book', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () async {
                final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
                if (picked != null) {
                  final bytes = await File(picked.path).readAsBytes();
                  setStateDialog(() => newImageBase64 = base64Encode(bytes));
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: newImageBase64 != null
                    ? Image.memory(base64Decode(newImageBase64!), width: 100, height: 130, fit: BoxFit.cover)
                    : book.imageBase64 != null
                        ? Image.memory(base64Decode(book.imageBase64!), width: 100, height: 130, fit: BoxFit.cover)
                        : Container(width: 100, height: 130, color: Colors.white24, child: const Icon(Icons.add_a_photo, color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Colors.white70))),
            TextField(controller: authorCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Author', labelStyle: TextStyle(color: Colors.white70))),
            DropdownButtonFormField<String>(
              value: condition,
              items: ['New', 'Good', 'Fair'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setStateDialog(() => condition = v!),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () async {
              try {
                await Provider.of<BookProvider>(context, listen: false).updateBook(
                  book.id,
                  title: titleCtrl.text.trim(),
                  author: authorCtrl.text.trim(),
                  condition: condition,
                  imageBase64: newImageBase64,
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updated!')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFFFCD116))),
          ),
        ],
      ),
    ),
  );
}

void _handleSwap(BuildContext context, String id, bool accept) async {
  final provider = Provider.of<BookProvider>(context, listen: false);
  try {
    if (accept) {
      await provider.acceptSwap(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap completed!')));
    } else {
      await provider.declineSwap(id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap declined.')));
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
  }
}

void _deleteBook(BuildContext context, String id) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1A5C38),
      title: const Text('Delete Book?', style: TextStyle(color: Colors.white)),
      content: const Text('This cannot be undone.', style: TextStyle(color: Colors.white70)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
        TextButton(
          onPressed: () async {
            await Provider.of<BookProvider>(context, listen: false).deleteBook(id);
            Navigator.pop(ctx);
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}