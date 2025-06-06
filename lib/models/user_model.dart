import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String username;
  final String usernameLower;
  final String phone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final String profileImageUrl;
  final String bio;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
    required this.usernameLower,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.profileImageUrl,
    required this.bio,
  });

  // Constructor para crear un usuario desde Map (Firestore)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      usernameLower: map['username_lower'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: _timestampToDateTime(map['createdAt']),
      updatedAt: _timestampToDateTime(map['updatedAt']),
      isActive: map['isActive'] ?? true,
      profileImageUrl: map['profileImageUrl'] ?? '',
      bio: map['bio'] ?? '',
    );
  }

  // Constructor para crear un usuario desde DocumentSnapshot
  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  // Convertir el modelo a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'username': username,
      'username_lower': usernameLower,
      'phone': phone,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
    };
  }

  // Convertir a Map para actualización (sin createdAt)
  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'email': email,
      'username': username,
      'username_lower': usernameLower,
      'phone': phone,
      'updatedAt': DateTime.now(),
      'isActive': isActive,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
    };
  }

  // Crear copia del modelo con cambios
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? username,
    String? usernameLower,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? profileImageUrl,
    String? bio,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      usernameLower: usernameLower ?? this.usernameLower,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
    );
  }

  // Crear un nuevo usuario para registro
  factory UserModel.create({
    required String uid,
    required String name,
    required String email,
    required String username,
    required String phone,
    String profileImageUrl = '',
    String bio = '',
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      name: name,
      email: email,
      username: username,
      usernameLower: username.toLowerCase(),
      phone: phone,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      profileImageUrl: profileImageUrl,
      bio: bio,
    );
  }

  // Método para obtener el nombre de usuario con @
  String get usernameWithAt => '@$username';

  // Método para obtener iniciales del nombre
  String get initials {
    final names = name.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return '';
  }

  // Método para obtener el primer nombre
  String get firstName {
    final names = name.trim().split(' ');
    return names.isNotEmpty ? names[0] : '';
  }

  // Método para obtener el apellido
  String get lastName {
    final names = name.trim().split(' ');
    return names.length > 1 ? names.sublist(1).join(' ') : '';
  }

  // Verificar si tiene imagen de perfil
  bool get hasProfileImage => profileImageUrl.isNotEmpty;

  // Verificar si tiene biografía
  bool get hasBio => bio.isNotEmpty;

  // Métodos de validación
  bool get isValidEmail {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  bool get isValidUsername {
    return username.length >= 3 && 
           username.length <= 20 && 
           RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username);
  }

  bool get isValidPhone {
    return phone.length >= 8;
  }

  // Convertir a JSON String
  String toJson() {
    return '''
{
  "uid": "$uid",
  "name": "$name",
  "email": "$email",
  "username": "$username",
  "username_lower": "$usernameLower",
  "phone": "$phone",
  "createdAt": "${createdAt.toIso8601String()}",
  "updatedAt": "${updatedAt.toIso8601String()}",
  "isActive": $isActive,
  "profileImageUrl": "$profileImageUrl",
  "bio": "$bio"
}''';
  }

  // toString para debugging
  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, username: $username, isActive: $isActive)';
  }

  // Comparar usuarios
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;

  // Método privado para convertir Timestamp a DateTime
  static DateTime _timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.tryParse(timestamp) ?? DateTime.now();
    }
    
    return DateTime.now();
  }
}

// Extensión para trabajar con listas de usuarios
extension UserModelList on List<UserModel> {
  // Filtrar usuarios activos
  List<UserModel> get activeUsers => where((user) => user.isActive).toList();
  
  // Buscar por username
  UserModel? findByUsername(String username) {
    try {
      return firstWhere((user) => user.usernameLower == username.toLowerCase());
    } catch (e) {
      return null;
    }
  }
  
  // Buscar por email
  UserModel? findByEmail(String email) {
    try {
      return firstWhere((user) => user.email.toLowerCase() == email.toLowerCase());
    } catch (e) {
      return null;
    }
  }
  
  // Ordenar por fecha de creación
  List<UserModel> sortByCreatedAt({bool descending = true}) {
    final sorted = List<UserModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
    return sorted;
  }
  
  // Ordenar por nombre
  List<UserModel> sortByName({bool descending = false}) {
    final sorted = List<UserModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.name.compareTo(a.name)
        : a.name.compareTo(b.name));
    return sorted;
  }
}