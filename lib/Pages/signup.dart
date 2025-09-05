import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Widgets/header.dart';
import '../Widgets/textFieldCustom.dart';
import '../app/auth_service.dart';

// Paleta azul vibrante pero suave - feliz y minimalista (igual que login)
const Color bgColor = Color(0xFF3B82F6); // Azul vibrante pero no saturado
const Color cardBgColor = Color(0xFF60A5FA); // Azul alegre medio
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFDDEAFF); // Azul muy claro pero vibrante
const Color accentColor = Color(0xFF93C5FD); // Azul claro vibrante
const Color accentColorLight = Color(0xFFBFDBFE); // Azul suave pero vivo

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

  String? selectedGender;
  bool isLoading = false;

  void signUp() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor completa todos los campos obligatorios"),
          backgroundColor: Color(0xFF60A5FA),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await AuthService().createAccount(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await AuthService().updateUserName(username: nameController.text.trim());

      Map<String, dynamic> userData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'age': ageController.text.trim().isNotEmpty
            ? int.tryParse(ageController.text.trim()) ?? 0
            : 0,
        'group': groupController.text.trim(),
        'class': classController.text.trim(),
        'gender': selectedGender,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Cuenta creada correctamente. Redirigiendo..."),
          backgroundColor: Color(0xFF60A5FA),
          duration: Duration(seconds: 2),
        ),
      );

      await FirebaseAuth.instance.signOut();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Error al crear cuenta"),
          backgroundColor: Color(0xFF60A5FA),
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => isLoading = false);
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
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Header(
              title: '¡El primer paso!',
              subtitle: 'Crea tu cuenta y únete a SerenIA',
              titleColor: primaryTextColor,
              subtitleColor: secondaryTextColor,
              accentColor: accentColorLight,
              backgroundColor: bgColor,
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: cardBgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
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
                      Text(
                        'Crear Cuenta',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completa la información para continuar',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      CustomTextField(
                        icon: Icons.person_outline,
                        hintText: 'Nombre completo *',
                        controller: nameController,
                        iconColor: accentColorLight,
                        textColor: primaryTextColor,
                        hintColor: secondaryTextColor,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        icon: Icons.email_outlined,
                        hintText: 'Correo electrónico *',
                        controller: emailController,
                        iconColor: accentColorLight,
                        textColor: primaryTextColor,
                        hintColor: secondaryTextColor,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        icon: Icons.calendar_today_outlined,
                        hintText: 'Edad',
                        controller: ageController,
                        iconColor: accentColorLight,
                        textColor: primaryTextColor,
                        hintColor: secondaryTextColor,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedGender,
                        dropdownColor: const Color(0xFFF1F5F9), // Mismo fondo que los textfields
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                            child: Icon(Icons.wc, color: const Color(0xFF3B82F6)),
                          ),
                          hintText: "Género *",
                          hintStyle: GoogleFonts.poppins(
                            color: accentColor,
                            fontSize: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: const Color(0xFFE2E8F0), 
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: const Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                        ),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1E3A8A),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        iconEnabledColor: const Color(0xFF3B82F6),
                        items: [
                          DropdownMenuItem(
                            value: 'Masculino', 
                            child: Text(
                              "Masculino",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1E3A8A),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Femenino', 
                            child: Text(
                              "Femenino",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1E3A8A),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'Otro', 
                            child: Text(
                              "Otro",
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1E3A8A),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => selectedGender = value);
                        },
                      ),

                      const SizedBox(height: 16),
                      CustomTextField(
                        icon: Icons.school_outlined,
                        hintText: 'Grupo/Clase',
                        controller: groupController,
                        iconColor: accentColorLight,
                        textColor: primaryTextColor,
                        hintColor: secondaryTextColor,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        icon: Icons.class_outlined,
                        hintText: 'Carrera',
                        controller: classController,
                        iconColor: accentColorLight,
                        textColor: primaryTextColor,
                        hintColor: secondaryTextColor,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        icon: Icons.lock_outline,
                        hintText: 'Contraseña *',
                        obscureText: true,
                        controller: passwordController,
                        iconColor: accentColorLight,
                        textColor: primaryTextColor,
                        hintColor: secondaryTextColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '* Campos obligatorios',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: isLoading ? null : signUp,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: accentColorLight,
                          foregroundColor: primaryTextColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: accentColorLight.withOpacity(0.4),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Crear Cuenta',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿Ya tienes una cuenta? ',
                            style: GoogleFonts.poppins(
                              color: secondaryTextColor,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Iniciar Sesión',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
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