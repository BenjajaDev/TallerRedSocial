import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final List<String> likes;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;

  PostModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.likes,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Usuario',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      sharesCount: data['sharesCount'] ?? 0,
    );
  }
}