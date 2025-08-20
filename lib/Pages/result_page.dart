import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  Future<void> obtenerRecomendacion() async {
    if (!mounted) return;

    setState(() {
      cargando = true;
      mensajeError = null;
    });

    const descripcionesNiveles = ['mínimo', 'leve', 'moderado', 'severo'];
    final nivelTexto = descripcionesNiveles[widget.level];

    String obtenerPromptPersonalizado() {
      String tipoEvaluacion = widget.cuestionario == 'BAI' 
          ? 'Ansiedad (Beck Anxiety Inventory)' 
          : widget.cuestionario == 'BDI' 
          ? 'Depresión (Beck Depression Inventory)' 
          : 'Estrés Percibido (Perceived Stress Scale)';
      
      String contextoNivel = '';
      switch (widget.level) {
        case 0:
          contextoNivel = 'Este es un nivel muy positivo. Enfócate en técnicas de mantenimiento del bienestar.';
          break;
        case 1:
          contextoNivel = 'Este es un nivel leve que requiere atención preventiva y técnicas de autocuidado.';
          break;
        case 2:
          contextoNivel = 'Este es un nivel moderado que requiere estrategias activas de manejo y posible apoyo adicional.';
          break;
        case 3:
          contextoNivel = 'Este es un nivel severo que requiere atención inmediata y apoyo profesional.';
          break;
      }
      
     return '''
Eres un psicólogo especializado en salud mental estudiantil. Un estudiante de ${widget.carrera} ha completado la evaluación de $tipoEvaluacion con estos resultados:

- Puntaje: ${widget.total}
- Nivel: $nivelTexto (${widget.level}/3)
- Contexto: $contextoNivel

Proporciona una recomendación específica (que sea bastante breve) con este formato EXACTO:

📌 Interpretación del resultado
[Texto breve de 1-2 oraciones explicando el nivel]
Quiero que las estrategias sean prácticas y aplicables por el estudiante sin necesidad de asistencia profesional ni con areas de la universidad.
💡 Estrategias recomendadas
1. [Primera estrategia práctica]
2. [Segunda estrategia práctica]
3. [Tercera estrategia opcional]

✨ Palabras finales
[Mensaje motivacional breve]

REGLAS ESTRICTAS:
- NO uses markdown (**negritas** o _cursivas_)
- NO uses asteriscos para énfasis
- Usa solo los emojis proporcionados (📌💡✨) como separadores
- Mantén un tono empático pero profesional
- Enfócate en acciones que el estudiante pueda realizar por sí mismo, no recomiendes terapia o asistencia profesional o grupos de apoyo
''';
}

    final prompt = obtenerPromptPersonalizado();

    try {
      final respuesta = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${dotenv.env['OPENROUTER_API_KEY']}',
          'Content-Type': 'application/json',
          'HTTP-Referer': '',
          'X-Title': 'SerenIA',
        },
        body: jsonEncode({
          'model': 'moonshotai/kimi-k2:free',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un psicólogo especializado en salud mental estudiantil. Proporciona recomendaciones empáticas y profesionales basadas en resultados de cuestionarios psicológicos.'
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 200,
          'temperature': 0.7,
        }),
      );

      if (!mounted) return;

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        setState(() {
          recomendacion = datos['choices'][0]['message']['content'].trim();
          cargando = false;
        });

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
        String mensajeEspecifico;
        switch (respuesta.statusCode) {
          case 401:
            mensajeEspecifico = 'Error 401: No autorizado.\nVerifica que tu API Key sea válida o tenga permisos.';
            break;
          case 404:
            mensajeEspecifico = 'Error 404: No encontrado.\nVerifica que el modelo o la URL del endpoint estén correctos.';
            break;
          case 429:
            mensajeEspecifico = 'Error 429: Demasiadas solicitudes.\nIntenta de nuevo más tarde.';
            break;
          default:
            mensajeEspecifico = 'Error desconocido (${respuesta.statusCode}): ${respuesta.body}';
        }

        setState(() {
          mensajeError = mensajeEspecifico;
          cargando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        mensajeError = 'Error: $e';
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