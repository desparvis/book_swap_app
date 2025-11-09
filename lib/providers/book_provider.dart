// lib/providers/book_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/book_model.dart';

class BookProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Book> _mapDocs(QuerySnapshot snapshot) {
    return snapshot.docs
        .map((doc) => Book.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // BROWSE: ALL BOOKS — SHOW EVERYTHING (available, pending, swapped)
  Stream<List<Book>> getAllBooks() {
    return _firestore
        .collection('books')
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map(_mapDocs);
  }

  // MY BOOKS: ONLY BOOKS I OWN
  Stream<List<Book>> getMyBooks() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('books')
        .where('ownerId', isEqualTo: userId)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map(_mapDocs);
  }

  // MY OFFERS: ONLY BOOKS I REQUESTED (pending)
  Stream<List<Book>> getMyPendingOffers() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('books')
        .where('status', isEqualTo: 'pending')
        .where('swapRequest.fromUserId', isEqualTo: userId)
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map(_mapDocs);
  }

  // ADD BOOK — SUPPORTS imageBase64
  Future<String> addBook(Book book) async {
    final user = _auth.currentUser!;
    final newBook = Book(
      id: '',
      title: book.title,
      author: book.author,
      condition: book.condition,
      ownerId: user.uid,
      ownerName: user.displayName ?? 'User',
      postedAt: DateTime.now(),
      status: 'available',
      imageBase64: book.imageBase64,
    );
    final ref = await _firestore.collection('books').add(newBook.toMap());
    return ref.id;
  }

  // UPDATE BOOK — SUPPORTS imageBase64
  Future<void> updateBook(String bookId, {
    required String title,
    required String author,
    required String condition,
    String? imageBase64,
  }) async {
    if (title.isEmpty || author.isEmpty) {
      throw Exception('Title and author are required');
    }

    final updateData = <String, dynamic>{
      'title': title,
      'author': author,
      'condition': condition,
    };

    if (imageBase64 != null) {
      updateData['imageBase64'] = imageBase64;
    }

    await _firestore.collection('books').doc(bookId).update(updateData);
  }

  // DELETE BOOK
  Future<void> deleteBook(String bookId) async {
    await _firestore.collection('books').doc(bookId).delete();
  }

  // REQUEST SWAP — ON available OR swapped
  Future<void> requestSwap(String bookId, String bookTitle) async {
    final user = _auth.currentUser!;
    final bookDoc = await _firestore.collection('books').doc(bookId).get();
    final data = bookDoc.data()!;

    if (data['ownerId'] == user.uid) {
      throw Exception("You can't swap your own book");
    }

    // Allow swap on 'available' or 'swapped'
    final currentStatus = data['status'];
    if (!['available', 'swapped'].contains(currentStatus)) {
      throw Exception("This book is not available for swap");
    }

    final request = SwapRequest(
      fromUserId: user.uid,
      fromUserName: user.displayName ?? 'User',
    );

    await _firestore.collection('books').doc(bookId).update({
      'status': 'pending',
      'swapRequest': request.toMap(),
    });
  }

  // ACCEPT SWAP → SWAP OWNERS + MARK SWAPPED
  Future<void> acceptSwap(String bookId) async {
    final user = _auth.currentUser!;
    final bookDoc = await _firestore.collection('books').doc(bookId).get();
    final data = bookDoc.data()!;
    final swapRequest = data['swapRequest'] as Map<String, dynamic>;
    final requesterId = swapRequest['fromUserId'];
    final requesterName = swapRequest['fromUserName'];

    // Get one available book from requester
    final requesterBookSnap = await _firestore
        .collection('books')
        .where('ownerId', isEqualTo: requesterId)
        .where('status', isEqualTo: 'available')
        .limit(1)
        .get();

    if (requesterBookSnap.docs.isEmpty) {
      throw Exception("Requester has no book to swap");
    }

    final requesterBookId = requesterBookSnap.docs.first.id;

    final batch = _firestore.batch();

    // 1. Give requester the requested book
    batch.update(_firestore.collection('books').doc(bookId), {
      'ownerId': requesterId,
      'ownerName': requesterName,
      'status': 'swapped',
      'swapRequest': FieldValue.delete(),
    });

    // 2. Give current user the requester's book
    batch.update(_firestore.collection('books').doc(requesterBookId), {
      'ownerId': user.uid,
      'ownerName': user.displayName ?? 'User',
      'status': 'swapped',
    });

    await batch.commit();
  }

  // DECLINE SWAP
  Future<void> declineSwap(String bookId) async {
    final bookDoc = await _firestore.collection('books').doc(bookId).get();
    final data = bookDoc.data()!;
    final wasSwapped = data['status'] == 'swapped';

    await _firestore.collection('books').doc(bookId).update({
      'status': wasSwapped ? 'swapped' : 'available',
      'swapRequest': FieldValue.delete(),
    });
  }
}