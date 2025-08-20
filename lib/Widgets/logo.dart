import 'package:flutter/material.dart';

class LogoWidget extends StatelessWidget {
  const LogoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/soyut_blanco.png',
        height: 100,
        fit: BoxFit.contain,
      ),
    );
  }
}
