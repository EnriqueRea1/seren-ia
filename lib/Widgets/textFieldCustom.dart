import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextField extends StatefulWidget {
  final IconData icon;
  final String hintText;
  final bool obscureText;
  final Color iconColor;
  final Color textColor;
  final Color hintColor;
  final TextEditingController? controller;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    required this.icon,
    required this.hintText,
    this.obscureText = false,
    required this.iconColor,
    required this.textColor,
    required this.hintColor,
    this.controller,
    this.keyboardType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: widget.controller,
        obscureText: widget.obscureText ? _isObscured : false,
        keyboardType: widget.keyboardType,
        style: GoogleFonts.poppins(
          color: const Color(0xFF1E3A8A), // Azul oscuro para texto legible
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 8.0),
            child: Icon(
              widget.icon, 
              color: const Color(0xFF3B82F6), // Azul vibrante para iconos
            ),
          ),
          hintText: widget.hintText,
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFF64748B), // Gris azulado para hints
            fontSize: 14,
          ),
          filled: true,
          fillColor: const Color(0xFFF1F5F9), // Fondo gris muy claro con toque azul
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: const Color(0xFFE2E8F0), // Borde sutil
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: const Color(0xFF3B82F6), // Borde azul al enfocar
              width: 2,
            ),
          ),
          // Botón del ojito solo si es campo de contraseña
          suffixIcon: widget.obscureText
              ? Padding(
                padding: const EdgeInsets.only(right: 8.0), 
                child: IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF3B82F6), // Mismo azul de los iconos
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                ),
              )
              : null,
        ),
      ),
    );
  }
}