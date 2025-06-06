import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:implementacion_fb/screens/feed.dart';
import 'package:implementacion_fb/services/firestore_service.dart';

void main() => runApp(const ProfileScreen());

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'RedConnect Profile', home: const ProfilePage());
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  Map<String, int>? userStats;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Cargar datos del usuario y estadísticas en paralelo
        final results = await Future.wait([
          FirestoreService.getUserById(user.uid),
          FirestoreService.getUserStats(user.uid),
        ]);

        if (mounted) {
          setState(() {
            userData = results[0] as Map<String, dynamic>?;
            userStats = results[1] as Map<String, int>?;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Usuario no autenticado';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error cargando datos del usuario: $e';
          isLoading = false;
        });
      }
    }
  }

  String _formatJoinDate(dynamic timestamp) {
    if (timestamp == null) return 'Fecha no disponible';

    try {
      // Si es un Timestamp de Firestore
      if (timestamp.runtimeType.toString().contains('Timestamp')) {
        final date = timestamp.toDate();
        final months = [
          'Enero',
          'Febrero',
          'Marzo',
          'Abril',
          'Mayo',
          'Junio',
          'Julio',
          'Agosto',
          'Septiembre',
          'Octubre',
          'Noviembre',
          'Diciembre',
        ];
        return 'Se unió en ${months[date.month - 1]} ${date.year}';
      }
    } catch (e) {
      print('Error formateando fecha: $e');
    }

    return 'Se unió recientemente';
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
              child:
                  isLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.red),
                      )
                      : errorMessage != null
                      ? _buildErrorWidget()
                      : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: 20),
                          _buildStatsSection(),
                          const SizedBox(height: 20),
                          _buildInfoSection(),
                          const SizedBox(height: 20),
                          _buildActionButtons(),
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
        currentIndex: 1, // Profile está seleccionado
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FeedScreen()),
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

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isLoading = true;
                  errorMessage = null;
                });
                _loadUserData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Perfil',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            setState(() {
              isLoading = true;
              errorMessage = null;
            });
            _loadUserData();
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () {
            // TODO: Implementar configuración
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Configuración próximamente'),
                backgroundColor: Colors.orange,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final name = userData?['name'] ?? user?.displayName ?? 'Usuario';
    final username = userData?['username'] ?? 'usuario';
    final bio =
        userData?['bio'] ??
        'Conectando ideas y pensamientos en la red social del futuro 🚀';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.red.withOpacity(0.3),
            backgroundImage:
                userData?['profileImageUrl'] != null &&
                        userData!['profileImageUrl'].isNotEmpty
                    ? NetworkImage(userData!['profileImageUrl'])
                    : null,
            child:
                userData?['profileImageUrl'] == null ||
                        userData!['profileImageUrl'].isEmpty
                    ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@$username',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            bio,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    // Usar estadísticas reales de Firebase
    final postsCount = userStats?['postsCount']?.toString() ?? '0';
    final followersCount = userStats?['followersCount']?.toString() ?? '0';
    final followingCount = userStats?['followingCount']?.toString() ?? '0';

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
          _buildStatItem('Publicaciones', postsCount),
          _buildStatDivider(),
          _buildStatItem('Seguidores', followersCount),
          _buildStatDivider(),
          _buildStatItem('Siguiendo', followingCount),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 40, width: 1, color: Colors.red.withOpacity(0.3));
  }

  Widget _buildInfoSection() {
    final user = FirebaseAuth.instance.currentUser;
    final email = userData?['email'] ?? user?.email ?? 'No disponible';
    final phone = userData?['phone'] ?? 'No especificado';
    final joinDate = _formatJoinDate(userData?['createdAt']);

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
            'Información',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email, email),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, phone),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, joinDate),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.red, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implementar editar perfil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Función de editar perfil próximamente'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Editar Perfil',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              // TODO: Implementar compartir perfil
              final username = userData?['username'] ?? 'usuario';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Compartir perfil: @$username'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Compartir Perfil',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
