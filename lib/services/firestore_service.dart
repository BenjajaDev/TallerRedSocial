import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance; // Cambié a static
  static const String _usersCollection = 'users';

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

  // ================================
  // MÉTODOS PARA ESTADÍSTICAS DE USUARIO
  // ================================

  /// Obtener el número de posts de un usuario
  static Future<int> getUserPostsCount(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('posts')
              .where('authorId', isEqualTo: userId)
              .get();

      return querySnapshot.docs.length;
    } catch (e) {
      print('Error obteniendo conteo de posts del usuario: $e');
      return 0;
    }
  }

  /// Obtener los posts de un usuario específico
  static Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('posts')
              .where('authorId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error obteniendo posts del usuario: $e');
      return [];
    }
  }

  /// Stream de posts de un usuario específico
  static Stream<List<Map<String, dynamic>>> getUserPostsStream(String userId) {
    return _firestore
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList(),
        );
  }

  /// Obtener estadísticas completas de un usuario
  static Future<Map<String, int>> getUserStats(String userId) async {
    try {
      // Obtener número de posts
      final postsCount = await getUserPostsCount(userId);

      return {
        'postsCount': postsCount,
        'followersCount': 0, // Placeholder hasta implementar seguimiento
        'followingCount': 0, // Placeholder hasta implementar seguimiento
        //por ahora no implementamos seguidores/seguidos porque requiere más lógica
        // y no sería muy optimo con nuestra manera de cargar los datos de firestore
      };
    } catch (e) {
      print('Error obteniendo estadísticas del usuario: $e');
      return {'postsCount': 0, 'followersCount': 0, 'followingCount': 0};
    }
  }

  /// Actualizar información del perfil de usuario
  static Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? bio,
    String? profileImageUrl,
    String? phone,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name.trim();
      if (bio != null) updateData['bio'] = bio.trim();
      if (profileImageUrl != null)
        updateData['profileImageUrl'] = profileImageUrl;
      if (phone != null) updateData['phone'] = phone.trim();

      await _firestore.collection(_usersCollection).doc(uid).update(updateData);

      // También actualizar el displayName en Firebase Auth si se cambió el nombre
      if (name != null && _auth.currentUser != null) {
        await _auth.currentUser!.updateDisplayName(name.trim());
      }
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Error actualizando perfil de usuario: $e',
      );
    }
  }

  // ================================
  // MÉTODOS DE USUARIO - REGISTRO
  // ================================

  /// Verificar si un username ya está en uso
  static Future<bool> isUsernameAvailable(String username) async {
    try {
      final normalizedUsername = username.trim().toLowerCase();

      final querySnapshot =
          await _firestore
              .collection(_usersCollection)
              .where('username_lower', isEqualTo: normalizedUsername)
              .limit(1)
              .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Error verificando disponibilidad del username: $e',
      );
    }
  }

  /// Verificar disponibilidad del username y lanzar excepción si no está disponible
  static Future<void> checkUsernameAvailability(String username) async {
    final isAvailable = await isUsernameAvailable(username);
    if (!isAvailable) {
      throw Exception('El nombre de usuario ya está en uso');
    }
  }

  /// Crear un nuevo usuario en Firestore
  static Future<void> createUserDocument({
    required String uid,
    required String name,
    required String email,
    required String username,
    required String phone,
    String profileImageUrl = '',
    String bio = '',
  }) async {
    try {
      final userData = {
        'uid': uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(), // Normalizar email
        'username': username.trim(),
        'username_lower': username.trim().toLowerCase(),
        'phone': phone.trim(),
        'createdAt': FieldValue.serverTimestamp(), // Usar serverTimestamp
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileImageUrl': profileImageUrl,
        'bio': bio,
      };

      await _firestore.collection(_usersCollection).doc(uid).set(userData);
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Error creando usuario en Firestore: $e',
      );
    }
  }

  /// Proceso completo de registro de usuario - MEJORADO
  static Future<UserCredential> registerUser({
    required String name,
    required String email,
    required String username,
    required String phone,
    required String password,
    String profileImageUrl = '',
    String bio = '',
  }) async {
    UserCredential? userCredential;

    try {
      // 1. Verificar disponibilidad del username
      await checkUsernameAvailability(username);

      // 2. Crear usuario en Firebase Auth
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      // 3. Actualizar displayName en Firebase Auth PRIMERO
      await userCredential.user!.updateDisplayName(name.trim());

      // 4. Crear documento del usuario en Firestore
      await createUserDocument(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        username: username,
        phone: phone,
        profileImageUrl: profileImageUrl,
        bio: bio,
      );

      return userCredential;
    } catch (e) {
      // Si falla la creación del documento pero el usuario ya se creó en Auth,
      // eliminar el usuario de Auth para mantener consistencia
      if (userCredential != null && userCredential.user != null) {
        try {
          await userCredential.user!.delete();
        } catch (deleteError) {
          print('Error eliminando usuario de Auth tras fallo: $deleteError');
        }
      }

      rethrow; // Re-lanzar la excepción original
    }
  }

  // ================================
  // MÉTODOS DE LECTURA DE USUARIOS
  // ================================

  /// Obtener un usuario por su UID
  static Future<Map<String, dynamic>?> getUserById(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Error obteniendo usuario por ID: $e',
      );
    }
  }

  /// Obtener un usuario por su email
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_usersCollection)
              .where('email', isEqualTo: email.trim().toLowerCase())
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Error obteniendo usuario por email: $e',
      );
    }
  }

  /// Obtener un usuario por su username
  static Future<Map<String, dynamic>?> getUserByUsername(
    String username,
  ) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_usersCollection)
              .where('username_lower', isEqualTo: username.trim().toLowerCase())
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Error obteniendo usuario por username: $e',
      );
    }
  }

  /// Obtener todos los usuarios activos
  static Future<List<Map<String, dynamic>>> getAllActiveUsers() async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_usersCollection)
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw FirebaseException(
        plugin: 'firestore',
        message: 'Error obteniendo usuarios activos: $e',
      );
    }
  }

  // ================================
  // MÉTODOS DE VALIDACIÓN
  // ================================

  /// Validar formato de email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email.trim());
  }

  /// Validar formato de username
  static bool isValidUsername(String username) {
    final trimmed = username.trim();
    return trimmed.length >= 3 &&
        trimmed.length <= 20 &&
        RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(trimmed) &&
        !trimmed.startsWith('.') &&
        !trimmed.endsWith('.') &&
        !trimmed.contains('..');
  }

  /// Validar formato de teléfono
  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    return cleaned.length >= 8 && cleaned.length <= 15;
  }

  /// Validar formato de nombre
  static bool isValidName(String name) {
    final trimmed = name.trim();
    return trimmed.length >= 2 && trimmed.length <= 50;
  }

  /// Validar contraseña
  static bool isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password);
  }

  // ================================
  // MÉTODOS DE STREAMING (TIEMPO REAL)
  // ================================

  /// Stream de un usuario específico
  static Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStream(
    String uid,
  ) {
    return _firestore.collection(_usersCollection).doc(uid).snapshots();
  }

  /// Stream de todos los usuarios activos
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsersStream() {
    return _firestore
        .collection(_usersCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ================================
  // MANEJO DE ERRORES PERSONALIZADO
  // ================================

  /// Convertir errores de Firebase a mensajes amigables
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'weak-password':
          return 'La contraseña es muy débil. Debe tener al menos 8 caracteres con mayúsculas, minúsculas y números.';
        case 'email-already-in-use':
          return 'Ya existe una cuenta con este correo electrónico.';
        case 'invalid-email':
          return 'El correo electrónico no tiene un formato válido.';
        case 'operation-not-allowed':
          return 'El registro con email/contraseña no está habilitado.';
        case 'too-many-requests':
          return 'Demasiados intentos. Por favor, espera unos minutos antes de intentar nuevamente.';
        case 'network-request-failed':
          return 'Error de conexión. Verifica tu conexión a internet.';
        default:
          return 'Error de autenticación: ${error.message ?? 'Error desconocido'}';
      }
    } else if (error is FirebaseException) {
      return 'Error de base de datos: ${error.message ?? 'Error desconocido'}';
    } else {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  // ================================
  // MÉTODOS DE UTILIDAD
  // ================================

  /// Obtener el usuario actual autenticado
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Cerrar sesión
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Verificar si hay un usuario autenticado
  static bool isUserSignedIn() {
    return _auth.currentUser != null;
  }
}
