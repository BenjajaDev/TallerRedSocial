import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:implementacion_fb/screens/profile.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import '../widgets/stats_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _postController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('es', timeago.EsMessages());
  }

  // Función para manejar el logout
  Future<void> _handleLogout() async {
    try {
      // Mostrar diálogo de confirmación
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              '¿Estás seguro de que quieres cerrar sesión?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      // Si el usuario confirmó, proceder con el logout
      if (shouldLogout == true) {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          // Navegar de vuelta al login y limpiar el stack de navegación
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login', // Asegúrate de que esta ruta existe en tu main.dart
            (Route<dynamic> route) => false,
          );

          // Mostrar mensaje de confirmación
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesión cerrada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('🛑 Error al cerrar sesión: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cerrar sesión. Inténtalo de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.9),
              Colors.red.shade900.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPostCreator(),
                  const SizedBox(height: 20),
                  const StatsCard(),
                  const SizedBox(height: 20),
                  _buildPostsFeed(),
                ],
              ),
            ),
          ],
        ),
      ),
            bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black.withOpacity(0.9),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // Feed está seleccionado
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'FakeBook',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          onPressed: _handleLogout, // Llamar a la función de logout
        ),
      ],
    );
  }

  Widget _buildPostCreator() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Qué está pasando?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _postController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Comparte tus pensamientos...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
              fillColor: Colors.black.withOpacity(0.3),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(color: Colors.red.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) {
                  print('🛑 No hay usuario autenticado');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debes iniciar sesión para publicar'),
                    ),
                  );
                  return;
                }

                if (_postController.text.trim().isNotEmpty) {
                  try {
                    await _firestoreService.createPost(
                      _postController.text.trim(),
                    );
                    _postController.clear();
                  } catch (e) {
                    print('🛑 Error al crear post: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Publicar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsFeed() {
    return StreamBuilder<List<PostModel>>(
      stream: _firestoreService.getPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'No hay publicaciones aún. ¡Sé el primero en compartir algo!',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          children:
              snapshot.data!
                  .map(
                    (post) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PostCard(
                        post: post,
                        onLike: () => _firestoreService.toggleLike(post.id),
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }
}
