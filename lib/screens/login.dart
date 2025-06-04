// ignore_for_file: unused_field, unused_element, unused_local_variable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:implementacion_fb/screens/feed.dart';
import 'package:implementacion_fb/screens/register.dart';


void main() => runApp(const LoginPage());

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Material App', home: LoginPageState());
  }
}

class LoginPageState extends StatefulWidget {
  const LoginPageState({super.key});

  @override
  State<LoginPageState> createState() => _LoginPageStateState();
}

class _LoginPageStateState extends State<LoginPageState> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose(){
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
      if (!_formKey.currentState!.validate()) return;
        

        setState(() {
          _isLoading = true;
        });


        try{

            UserCredential userCredential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(
              email: _usernameController.text.trim(),
              password: _passwordController.text.trim(),
            );

            if (userCredential.user != null) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('¡Bienvenido de nuevo! '),
                          content: const Text('Has iniciado sesión correctamente'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
            }
        }
        on FirebaseAuthException catch(e){
          String message;
          switch (e.code) {
            
            case 'invalid-email':
            message = 'Correo electrónico no válido';
            break;

            case 'user-not-found':
            message = 'Usuario no encontrado';
            break;

            case 'wrong-password':
            message = 'Contraseña incorrecta';
            break;

            case 'network-request-failed':
            message = 'Error de red';
            break;


            default:
            message = 'Error desconocido';
            break;
          }

          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }

        catch (e) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error inesperado: $e'),
                backgroundColor: Colors.red,
              ));
        }


        setState(() {
          _isLoading = false;
        });
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
                  // Campo de texto de correo electrónico
                  TextFormField(
                    controller: _usernameController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su correo electrónico';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Por favor ingrese un correo válido';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: "Ingrese su correo",
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
                  // Campo de texto de contraseña
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
                      prefixIcon: const Icon(Icons.lock),
                      prefixIconColor: Colors.red,
                      labelText: "Ingrese su contraseña",
                      filled: true,
                      fillColor: Colors.red[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Botón de iniciar sesión
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _isLoading
                            ? null
                            : _signIn(); // Llama a la función de inicio de sesión solo si no está cargando
                          Navigator.push(context, 
                            MaterialPageRoute(
                              builder: (context) => const FeedScreen(),
                            ),
                          );
                      }
                      
                      
                      ,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.arrow_circle_right, color: Colors.white),
                      label: Text(
                        _isLoading ? "Iniciando..." : "Iniciar sesión",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Botón para ir al registro
                  TextButton(
                    onPressed: () {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "¿No tienes cuenta? Regístrate aquí",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
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

      

