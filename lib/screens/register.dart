import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:implementacion_fb/screens/login.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  

  @override
  // ignore: library_private_types_in_public_api
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
    final _namesController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _usernameController = TextEditingController();
    final _phoneController = TextEditingController();
    bool _isLoading = false;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isLoading = false;
      });

    try{

        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {

          await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'correo': _emailController.text.trim(),
            'nombre_usuario': _usernameController.text.trim(),
            'telefono': _phoneController.text.trim(),
            'contrasena': _passwordController.text.trim(),
            'creadoEn': Timestamp.now(),
          });

          await userCredential.user!.updateDisplayName(_usernameController.text.trim());
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registro exitoso! \n Bienvenido a fakeBook'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
    }
    on FirebaseAuthException catch (e) {
      String message = 'Ha ocurrido un error al registrarse.';
      if (e.code == 'email-already-in-use') {
        message = 'El correo electrónico ya está en uso.';
      } else if (e.code == 'weak-password') {
        message = 'La contraseña es demasiado débil.';
      } else if (e.code == 'invalid-email') {
        message = 'El correo electrónico no es válido.';
      } else {
        message = 'Error de registro: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {
        setState(() {
          _isLoading = false;
        });
      }

    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.facebook, size: 64, color: Colors.red),
                  const SizedBox(height: 20),
                  const Text(
                    "fakeBook",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Campo de nombre
                  TextFormField(
                    controller: _namesController,
                    keyboardType: TextInputType.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su nombre';
                      }
                      if (value.length < 2) {
                        return 'El nombre debe tener al menos 2 caracteres';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Ingrese su nombre",
                      prefixIcon: const Icon(Icons.person),
                      prefixIconColor: Colors.red,
                      filled: true,
                      fillColor: Colors.red[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Campo de correo electrónico
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su correo electrónico';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Por favor ingrese un correo electrónico válido';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Ingrese su correo electrónico",
                      prefixIcon: const Icon(Icons.email),
                      prefixIconColor: Colors.red,
                      filled: true,
                      fillColor: Colors.red[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Campo de contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su contraseña';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Ingrese su contraseña",
                      prefixIcon: const Icon(Icons.lock),
                      prefixIconColor: Colors.red,
                      filled: true,
                      fillColor: Colors.red[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Campo de confirmación de contraseña
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor confirme su contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Confirme su contraseña",
                      prefixIcon: const Icon(Icons.lock),
                      prefixIconColor: Colors.red,
                      filled: true,
                      fillColor: Colors.red[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Campo de nombre de usuario
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su nombre de usuario';
                      }
                      if (value.length < 3) {
                        return 'El nombre de usuario debe tener al menos 3 caracteres';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Ingrese su nombre de usuario",
                      prefixIcon: const Icon(Icons.person_outline),
                      prefixIconColor: Colors.red,
                      filled: true,
                      fillColor: Colors.red[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Campo de teléfono
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su número de teléfono';
                      }
                      if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                        return 'Por favor ingrese un número de teléfono válido';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Ingrese su número de teléfono",
                      prefixIcon: const Icon(Icons.phone),
                      prefixIconColor: Colors.red,
                      filled: true,
                      fillColor: Colors.red[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Botón de registro
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Registrarse", style: TextStyle(fontSize: 16, color: Colors.red)),
                  ),
                  SizedBox(height: 20),
                  // Texto de inicio de sesión
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, 
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            )
                          );
                        },
                        child: const Text("¿Ya tienes una cuenta? Iniciar sesión", style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
