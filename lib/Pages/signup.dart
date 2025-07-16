import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Widgets/header.dart';

import '../Widgets/textFieldCustom.dart';
import '../app/auth_service.dart';

// Paleta de colores oscura, limpia (estilo iPhone Dark Mode)
const Color bgColor = Color(0xFF1C1C1E); // Fondo muy oscuro (casi negro, con un toque de gris)
const Color cardBgColor = Color(0xFF2C2C2E); // Fondo de tarjeta un poco más claro que el fondo
const Color primaryTextColor = Colors.white; // Texto principal blanco
const Color secondaryTextColor = Color(0xFF8E8E93); // Texto secundario gris claro
const Color accentColor = Color(0xFF0A84FF); // Azul vibrante para acentos (similar al azul de iOS)
const Color accentColorLight = Color(0xFF32ADE6); // Un azul más claro si se necesita, aunque no lo usaremos en el botón

// NOTA: Eliminamos errorColor y successColor, se usarán colores neutros en SnackBar

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController groupController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  bool isLoading = false;

  void signUp() async {
    // Validaciones básicas
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos obligatorios"),
          backgroundColor: Color(0xFF3A3A3C), // Color neutro oscuro para SnackBar
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      print("Iniciando proceso de registro...");

      // Crear cuenta en Firebase Auth
      UserCredential userCredential = await AuthService().createAccount(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      print("Usuario creado en Auth: ${userCredential.user!.uid}");

      // Actualizar nombre de usuario en Auth
      // Asegúrate de que AuthService().updateUserName exista y funcione correctamente
      await AuthService().updateUserName(username: nameController.text.trim());
      print("Nombre de usuario actualizado");

      // Preparar datos para Firestore
      Map<String, dynamic> userData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'age': ageController.text.trim().isNotEmpty
            ? int.tryParse(ageController.text.trim()) ?? 0
            : 0,
        'group': groupController.text.trim(),
        'class': classController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      print("Guardando datos en Firestore...");

      // Guardar en Firestore con mejor manejo de errores
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      print("Datos guardados exitosamente en Firestore");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Cuenta creada correctamente. Redirigiendo..."),
            backgroundColor: Color(0xFF3A3A3C), // Color neutro oscuro para SnackBar
            duration: Duration(seconds: 2),
          ),
        );

        await FirebaseAuth.instance.signOut();

        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context); // Vuelve a la página anterior (LoginPage)
        }
      }
    } on FirebaseAuthException catch (e) {
      print("Error de Firebase Auth: ${e.code} - ${e.message}");
      String errorMessage = _getAuthErrorMessage(e.code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ $errorMessage"),
            backgroundColor: Color(0xFF3A3A3C), // Color neutro oscuro para SnackBar
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseException catch (e) {
      print("Error de Firestore: ${e.code} - ${e.message}");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error al guardar datos: ${e.message}"),
            backgroundColor: Color(0xFF3A3A3C), // Color neutro oscuro para SnackBar
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print("Error general: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Error inesperado. Intenta nuevamente."),
            backgroundColor: Color(0xFF3A3A3C), // Color neutro oscuro para SnackBar
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'email-already-in-use':
        return 'Este email ya está registrado';
      case 'invalid-email':
        return 'Email inválido';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'user-disabled':
        return 'Usuario deshabilitado';
      default:
        return 'Error al crear la cuenta';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    ageController.dispose();
    groupController.dispose();
    classController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor, // Fondo muy oscuro para el Scaffold
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header reutilizable
            // Asegúrate de que el Header tenga texto blanco o un diseño que contraste bien con el fondo oscuro.
            const Header(
              title: '¡Bienvenido!',
              subtitle: 'Crea tu cuenta y únete a nosotros',
            ),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardBgColor, // Fondo de la tarjeta un poco más claro
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3), // Sombra más visible en oscuro
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: primaryTextColor, // Texto blanco
                              letterSpacing: -0.5,
                            ),
                          ),
                          // Asegúrate de que el LogoWidget se vea bien
                          // sobre el fondo oscuro de cardBgColor.
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crea tu cuenta para continuar',
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryTextColor, // Texto gris claro
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        icon: Icons.person_outline,
                        hintText: 'Nombre completo *',
                        controller: nameController,
                        iconColor: accentColor, // Icono azul
                        textColor: primaryTextColor, // Texto blanco
                        hintColor: secondaryTextColor, // Hint gris claro
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        icon: Icons.email_outlined,
                        hintText: 'Correo electrónico *',
                        controller: emailController,
                        iconColor: accentColor, // Icono azul
                        textColor: primaryTextColor, // Texto blanco
                        hintColor: secondaryTextColor, // Hint gris claro
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        icon: Icons.calendar_today_outlined,
                        hintText: 'Edad',
                        controller: ageController,
                        iconColor: accentColor, // Icono azul
                        textColor: primaryTextColor, // Texto blanco
                        hintColor: secondaryTextColor, // Hint gris claro
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        icon: Icons.school_outlined,
                        hintText: 'Grupo/Clase',
                        controller: groupController,
                        iconColor: accentColor, // Icono azul
                        textColor: primaryTextColor, // Texto blanco
                        hintColor: secondaryTextColor, // Hint gris claro
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        icon: Icons.class_outlined,
                        hintText: 'Carrera',
                        controller: classController,
                        iconColor: accentColor, // Icono azul
                        textColor: primaryTextColor, // Texto blanco
                        hintColor: secondaryTextColor, // Hint gris claro
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        icon: Icons.lock_outline,
                        hintText: 'Contraseña *',
                        controller: passwordController,
                        iconColor: accentColor, // Icono azul
                        textColor: primaryTextColor, // Texto blanco
                        hintColor: secondaryTextColor, // Hint gris claro
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '* Campos obligatorios',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor, // Texto gris claro
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Botón sin gradiente, con color sólido
                      ElevatedButton(
                        onPressed: isLoading ? null : signUp,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: accentColor, // Fondo del botón azul sólido
                          foregroundColor: primaryTextColor, // Color del texto del botón blanco
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5, // Una sombra sutil para el botón
                          shadowColor: accentColor.withOpacity(0.3), // Sombra que combine con el botón
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white, // Indicador blanco para fondo azul
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Crear Cuenta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes una cuenta? ',
                            style: TextStyle(
                              color: secondaryTextColor, // Texto gris claro
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context), // Vuelve a la pantalla anterior (Login)
                            child: Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                color: accentColor, // Texto azul
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}