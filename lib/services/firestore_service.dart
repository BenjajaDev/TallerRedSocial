import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList(),
        );
  }

  Future<void> createPost(String content) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('posts').add({
        'content': content,
        'authorId': user.uid,
        'authorName': user.displayName ?? 'Usuario',
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'likesCount': 0,
        'commentsCount': 0,
        'sharesCount': 0,
      });
    }
  }

  Future<void> toggleLike(String postId) async {
    final user = _auth.currentUser;
    if (user != null) {
      final postRef = _firestore.collection('posts').doc(postId);
      return _firestore.runTransaction((transaction) async {
        final postDoc = await transaction.get(postRef);
        if (postDoc.exists) {
          final likes = List<String>.from(postDoc.data()?['likes'] ?? []);
          if (likes.contains(user.uid)) {
            likes.remove(user.uid);
          } else {
            likes.add(user.uid);
          }
          transaction.update(postRef, {
            'likes': likes,
            'likesCount': likes.length,
          });
        }
      });
    }
  }
}
