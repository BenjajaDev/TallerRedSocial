import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  // Método para obtener el conteo de posts
  Stream<int> _getPostsCount() {
    return FirebaseFirestore.instance
        .collection('posts')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Método para obtener el conteo de usuarios
  Stream<int> _getUsersCount() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Método para obtener el conteo total de likes
  Stream<int> _getTotalLikesCount() {
    return FirebaseFirestore.instance.collection('posts').snapshots().map((
      snapshot,
    ) {
      int totalLikes = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalLikes += (data['likesCount'] as int?) ?? 0;
      }
      return totalLikes;
    });
  }

  // Método para formatear números grandes
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Posts count
          StreamBuilder<int>(
            stream: _getPostsCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return _buildStatItem(
                icon: Icons.article,
                label: 'Posts',
                value: _formatNumber(count),
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
          // Users count
          StreamBuilder<int>(
            stream: _getUsersCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return _buildStatItem(
                icon: Icons.people,
                label: 'Usuarios',
                value: _formatNumber(count),
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
          // Total likes count
          StreamBuilder<int>(
            stream: _getTotalLikesCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return _buildStatItem(
                icon: Icons.favorite,
                label: 'Likes',
                value: _formatNumber(count),
                isLoading: snapshot.connectionState == ConnectionState.waiting,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    bool isLoading = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.red, size: 24),
        const SizedBox(height: 8),
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
          )
        else
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
      ],
    );
  }
}
