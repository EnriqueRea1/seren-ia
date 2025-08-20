import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final Color accentColor; 
  final Color backgroundColor; 

  const Header({
    super.key,
    required this.title,
    required this.subtitle,
    this.titleColor = Colors.black,
    this.subtitleColor = Colors.grey,
    this.accentColor = const Color(0xFF2196F3),
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: .5),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "Bienvenido de vuelta a ",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: subtitleColor,
                  ),
                ),
                TextSpan(
                  text: "SerenIA ",
                  style: GoogleFonts.poppins(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
                TextSpan(
                  text: "\nPara Estudiantes",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: subtitleColor,
                    decorationColor: subtitleColor,

                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
