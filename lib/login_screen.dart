import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Ingrese un email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? 'Ingrese una contraseña' : null,
              ),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Iniciar Sesión'),
              ),
              if (_errorMessage.isNotEmpty)
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              
              // Botón temporal para crear documento admin
              const SizedBox(height: 20),
              TextButton(
                onPressed: _createAdminDocument,
                child: const Text(
                  'Crear documento admin (solo primera vez)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

void _submit() async {
  if (_formKey.currentState!.validate()) {
    try {
      final user = await _authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      
      if (user != null) {
        // La navegación ahora se manejará automáticamente por el StreamBuilder en main.dart
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _mapErrorCodeToMessage(e.code);
      });
    }
  }
}

String _mapErrorCodeToMessage(String code) {
  switch (code) {
    case 'user-not-found':
      return 'Usuario no registrado';
    case 'wrong-password':
      return 'Contraseña incorrecta';
    case 'invalid-email':
      return 'Formato de email inválido';
    default:
      return 'Error de autenticación';
  }
}

Future<void> _createAdminDocument() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Debes iniciar sesión primero';
      });
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
          'uid': user.uid,
          'email': user.email,
          'nombre': user.email?.split('@')[0] ?? 'Administrador',
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'createdBy': 'system',
        });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Documento admin creado. Recarga la página.')),
    );
  } catch (e) {
    setState(() {
      _errorMessage = 'Error al crear documento: $e';
    });
  }
}
}