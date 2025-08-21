import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// Using the same color palette from QuestionnairePage
const Color bgColor = Color(0xFF3B82F6);
const Color cardBgColor = Color(0xFF60A5FA);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFDDEAFF);
const Color accentColor = Color(0xFF93C5FD);
const Color accentColorLight = Color(0xFFBFDBFE);
const Color lightCardColor = Color(0xFFF8FAFC);

class ResultPage extends StatefulWidget {
  final int total;
  final int level;
  final String carrera;
  final String cuestionario;

  const ResultPage({
    super.key,
    required this.total,
    required this.level,
    required this.carrera,
    required this.cuestionario,
  });

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String? recomendacion;
  bool cargando = false;
  String? mensajeError;

  @override
  void initState() {
    super.initState();
    obtenerRecomendacion();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Reemplaza tu método obtenerRecomendacion() con este:

Future<void> obtenerRecomendacion() async {
  if (!mounted) return;

  setState(() {
    cargando = true;
    mensajeError = null;
  });

  // URL de tu backend en producción - CAMBIA POR TU URL REAL
  const String backendUrl = 'https://seren-ia-backend.onrender.com'; // Reemplaza con tu URL
  
  // Para desarrollo local usa: 'http://localhost:5000'
  // Para producción usa tu URL de Render/Railway/etc.

  try {
    final response = await http.post(
      Uri.parse('$backendUrl/api/recomendacion'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'total': widget.total,
        'level': widget.level,
        'carrera': widget.carrera,
        'cuestionario': widget.cuestionario,
      }),
    );

    if (!mounted) return;

    print("📡 Backend response status: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data['recomendacion'] != null) {
        setState(() {
          recomendacion = data['recomendacion'];
          cargando = false;
        });

        // Guardar en Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && recomendacion != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('recomendaciones')
              .add({
                'fecha': FieldValue.serverTimestamp(),
                'cuestionario': widget.cuestionario,
                'nivel': widget.level,
                'puntaje': widget.total,
                'carrera': widget.carrera,
                'recomendacion': recomendacion,
              });
        }
      } else {
        setState(() {
          mensajeError = 'Error: ${data['error'] ?? 'Respuesta inválida del servidor'}';
          cargando = false;
        });
      }
    } else {
      // Manejar errores del backend
      String errorMessage = 'Error del servidor';
      
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['error'] ?? 'Error desconocido';
      } catch (e) {
        errorMessage = 'Error ${response.statusCode}: No se pudo procesar la respuesta';
      }

      setState(() {
        mensajeError = errorMessage;
        cargando = false;
      });
    }
  } catch (e) {
    if (!mounted) return;

    String errorMessage;
    if (e.toString().contains('SocketException')) {
      errorMessage = 'Error de conexión: Verifica tu conexión a internet';
    } else if (e.toString().contains('TimeoutException')) {
      errorMessage = 'Tiempo de espera agotado: El servidor tardó demasiado en responder';
    } else {
      errorMessage = 'Error de conexión: $e';
    }

    setState(() {
      mensajeError = errorMessage;
      cargando = false;
    });
  }
}

  Color _obtenerColorProgreso(int nivel) {
    switch (nivel) {
      case 0:
        return const Color(0xFF10B981); // Verde
      case 1:
        return const Color(0xFFF59E0B); // Amarillo
      case 2:
        return const Color(0xFFF97316); // Naranja
      default:
        return const Color(0xFFEF4444); // Rojo
    }
  }

  String _getLevelDescription(int level) {
    switch (level) {
      case 0:
        return 'Mínimo';
      case 1:
        return 'Leve';
      case 2:
        return 'Moderado';
      case 3:
        return 'Severo';
      default:
        return '';
    }
  }

  String _getQuestionnaireTitle() {
    switch (widget.cuestionario) {
      case 'BAI':
        return 'Ansiedad';
      case 'BDI':
        return 'Depresión';
      case 'PSS':
        return 'Estrés';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final puntajeMaximo = widget.cuestionario == 'PSS' ? 42 : 63;
    final progreso = (widget.total / puntajeMaximo).clamp(0.0, 1.0);
    final color = _obtenerColorProgreso(widget.level);
    final levelDescription = _getLevelDescription(widget.level);
    final questionnaireTitle = _getQuestionnaireTitle();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bgColor,
                      cardBgColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resultados',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: primaryTextColor,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: primaryTextColor,
                            size: 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      questionnaireTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main content
              Container(
                decoration: BoxDecoration(
                  color: lightCardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Score card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircularPercentIndicator(
                            radius: 80.0,
                            lineWidth: 14.0,
                            animation: true,
                            percent: progreso,
                            circularStrokeCap: CircularStrokeCap.round,
                            backgroundColor: accentColorLight.withOpacity(0.2),
                            progressColor: color,
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${widget.total}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  '/ $puntajeMaximo',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              levelDescription,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nivel ${widget.level}/3',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Recommendation section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: accentColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Recomendaciones',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (cargando)
                            const Center(
                              child: CircularProgressIndicator(
                                color: accentColor,
                              ),
                            )
                          else if (mensajeError != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      mensajeError!,
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFFDC2626),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (recomendacion != null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD1FAE5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    recomendacion!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: const Color(0xFF065F46),
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                  const SizedBox(height: 12),                                  
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    SizedBox( 
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cardBgColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Volver al inicio',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}