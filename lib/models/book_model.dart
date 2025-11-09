// lib/models/book_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SwapRequest {
  final String fromUserId;
  final String fromUserName;

  SwapRequest({required this.fromUserId, required this.fromUserName});

  Map<String, dynamic> toMap() => {
        'fromUserId': fromUserId,
        'fromUserName': fromUserName,
      };

  factory SwapRequest.fromMap(Map<String, dynamic> map) => SwapRequest(
        fromUserId: map['fromUserId'] ?? '',
        fromUserName: map['fromUserName'] ?? 'Unknown',
      );
}

class Book {
  final String id;
  final String title;
  final String author;
  final String condition;
  final String ownerId;
  final String ownerName;
  final DateTime postedAt;
  final String status; // available, pending, swapped
  final SwapRequest? swapRequest;
  final String? imageBase64; // NEW: Base64-encoded image

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.condition,
    required this.ownerId,
    required this.ownerName,
    required this.postedAt,
    this.status = 'available',
    this.swapRequest,
    this.imageBase64,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'condition': condition,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'postedAt': Timestamp.fromDate(postedAt),
      'status': status,
      if (swapRequest != null) 'swapRequest': swapRequest!.toMap(),
      if (imageBase64 != null) 'imageBase64': imageBase64,
    };
  }

  factory Book.fromMap(String id, Map<String, dynamic> map) {
    return Book(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      condition: map['condition'] ?? 'Good',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? 'Unknown',
      postedAt: map['postedAt'] is Timestamp
          ? (map['postedAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'available',
      swapRequest: map['swapRequest'] != null
          ? SwapRequest.fromMap(map['swapRequest'])
          : null,
      imageBase64: map['imageBase64'] as String?,
    );
  }
}