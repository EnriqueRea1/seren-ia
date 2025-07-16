import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Widgets/header.dart';
import '../Widgets/textFieldCustom.dart';
import '../app/auth_service.dart';

// Nueva paleta de colores oscura, limpia (estilo iPhone Dark Mode)
const Color bgColor = Color(0xFF1C1C1E); // Fondo muy oscuro (casi negro, con un toque de gris)
const Color cardBgColor = Color(0xFF2C2C2E); // Fondo de tarjeta un poco más claro que el fondo
const Color primaryTextColor = Colors.white; // Texto principal blanco
const Color secondaryTextColor = Color(0xFF8E8E93); // Texto secundario gris claro
const Color accentColor = Color(0xFF0A84FF); // Azul vibrante para acentos (similar al azul de iOS)
const Color accentColorLight = Color(0xFF32ADE6); // Un azul más claro si se necesita, aunque no lo usaremos en el botón


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void login() async {
    // Validaciones básicas
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos"),
          backgroundColor: Color(0xFF3A3A3C), // Color neutro oscuro para SnackBar
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await authService.value?.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Inicio de sesión exitoso"),
            backgroundColor: Color(0xFF3A3A3C), // Color neutro oscuro para SnackBar
            duration: Duration(seconds: 2),
          ),
        );

        // Redireccionar a home después de un breve delay
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pushReplacementNamed(context, 'questionnaire');
        }
      }
    } on FirebaseAuthException catch (e) {
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
    } catch (e) {
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
      case 'user-not-found':
        return 'No existe una cuenta con este email';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Error al iniciar sesión';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor, // Fondo muy oscuro
      body: SafeArea(
        child: Column(
          children: [
            // Usamos el Header ya existente
            // **IMPORTANTE:** Si tu Header tiene colores fijos claros,
            // puede que necesites ajustar su implementación para que se vea bien
            // sobre un fondo oscuro, o que acepte un parámetro para el color de texto.
            const Header(
              title: '¡Hola!',
              subtitle: 'Bienvenido de vuelta a SerenIA',
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
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: primaryTextColor, // Texto blanco
                              letterSpacing: -0.5,
                            ),
                          ),
                          // **IMPORTANTE:** Asegúrate de que el LogoWidget se vea bien
                          // sobre el fondo oscuro de cardBgColor.
                          // Puede que necesite un asset diferente o lógica para invertir colores.
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ingresa tus credenciales para continuar',
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryTextColor, // Texto gris claro
                        ),
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        icon: Icons.email_outlined,
                        hintText: 'Correo electrónico',
                        controller: emailController,
                        iconColor: accentColor, // Icono azul
                        textColor: primaryTextColor, // Texto blanco
                        hintColor: secondaryTextColor, // Hint gris claro
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        icon: Icons.lock_outline,
                        hintText: 'Contraseña',
                        obscureText: true,
                        controller: passwordController,
                        iconColor: accentColor, // Icono azul
                        textColor: primaryTextColor, // Texto blanco
                        hintColor: secondaryTextColor, // Hint gris claro
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Función de recuperación próximamente"),
                                backgroundColor: Color(0xFF3A3A3C), // Color neutro oscuro para SnackBar
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: accentColor, // Texto azul
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Botón sin gradiente, con color sólido
                      ElevatedButton(
                        onPressed: isLoading ? null : login,
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
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: secondaryTextColor.withOpacity(0.3), // Separador gris translúcido
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'o',
                              style: TextStyle(
                                color: secondaryTextColor, // Texto gris claro
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: secondaryTextColor.withOpacity(0.3), // Separador gris translúcido
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿No tienes una cuenta? ',
                            style: TextStyle(
                              color: secondaryTextColor, // Texto gris claro
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, 'signup'),
                            child: Text(
                              'Regístrate',
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