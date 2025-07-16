import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResultPage extends StatefulWidget {
  final int total; // Puntaje total del cuestionario
  final int level; // Nivel predicho (0-3)
  final String carrera; // Carrera del estudiante (ej. "Ingeniería Informática")
  final String cuestionario; // Tipo: "BAI", "BDI" o "PSS"

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
  String? recomendacion; // Respuesta de la API
  bool cargando = false; // Estado de carga
  String? mensajeError; // Mensaje de error si falla la API

  @override
  void initState() {
    super.initState();
    obtenerRecomendacion();
  }

  // Asegúrate de limpiar los recursos si el widget se descarta
  @override
  void dispose() {
    // Si tuvieras temporizadores o listeners que necesiten ser cancelados, hazlo aquí.
    super.dispose();
  }

  Future<void> obtenerRecomendacion() async {
    // Primero, verifica si el widget sigue montado antes de llamar a setState
    if (!mounted) return;

    setState(() {
      cargando = true;
      mensajeError = null;
    });

    // Descripciones de niveles según BAI/BDI/PSS
    const descripcionesNiveles = ['mínimo', 'leve', 'moderado', 'severo'];
    final nivelTexto = descripcionesNiveles[widget.level];

    // Crear un prompt más específico según el nivel
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

Proporciona una recomendación específica (máximo 120 palabras) que incluya:
1. Interpretación empática del resultado
2. 2-3 estrategias concretas y aplicables
3. Recursos específicos para estudiantes universitarios
${widget.level >= 2 ? '4. Importancia de buscar apoyo profesional' : ''}

Usa un tono empático, motivador y enfocado en soluciones prácticas. NO hagas preguntas al final, solo proporciona las recomendaciones de forma conclusiva.
      ''';
    }

    final prompt = obtenerPromptPersonalizado();

    try {
      final respuesta = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Authorization':
              'Bearer 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',
          'Content-Type': 'application/json',
          'HTTP-Referer': '',
          'X-Title': 'SerenIA',
        },
        body: jsonEncode({
          'model': 'openrouter/cypher-alpha:free',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un psicólogo especializado en salud mental estudiantil. Proporciona recomendaciones empáticas y profesionales basadas en resultados de cuestionarios psicológicos.'
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 200,
          'temperature': 0.7, // Un poco de creatividad pero manteniendo consistencia
        }),
      );

      // Vuelve a verificar si el widget sigue montado antes de actualizar el estado
      if (!mounted) return;

      if (respuesta.statusCode == 200) {
        final datos = jsonDecode(respuesta.body);
        setState(() {
          recomendacion = datos['choices'][0]['message']['content'].trim();
          cargando = false;
        });
      } else {
        setState(() {
          mensajeError =
              'Error al obtener recomendación: ${respuesta.statusCode}';
          cargando = false;
        });
      }
    } catch (e) {
      // Vuelve a verificar si el widget sigue montado en el bloque catch
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
        return const Color(0xFF00FFAA); // Verde
      case 1:
        return const Color(0xFFFFE600); // Amarillo
      case 2:
        return const Color(0xFFFF7B00); // Naranja
      default:
        return const Color(0xFFFF007A); // Rosa
    }
  }

  @override
  Widget build(BuildContext context) {
    final puntajeMaximo = widget.cuestionario == 'PSS' ? 42 : 63;
    final progreso = (widget.total / puntajeMaximo).clamp(0.0, 1.0);
    final color = _obtenerColorProgreso(widget.level);
    final anchoPantalla = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Resultados'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: anchoPantalla > 600 ? 80 : 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              color: Colors.grey[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
              elevation: 4,
              // *** CAMBIO CLAVE AQUÍ: Envuelve el Padding con SingleChildScrollView ***
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Permite que la columna ocupe solo el espacio necesario
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularPercentIndicator(
                      radius: 90.0,
                      lineWidth: 14.0,
                      animation: true,
                      percent: progreso,
                      circularStrokeCap: CircularStrokeCap.round,
                      backgroundColor: Colors.white12,
                      progressColor: color,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${(progreso * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.total} / $puntajeMaximo',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nivel: ${widget.level}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '¡Sigue esforzándote para mejorar tu bienestar!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Mostrar recomendación, carga o error
                    if (cargando)
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    else if (mensajeError != null)
                      Text(
                        mensajeError!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red[400],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else if (recomendacion != null)
                      Text(
                        recomendacion!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          'questionnaire',
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.arrow_forward, size: 20),
                      label: const Text(
                        'Volver al inicio',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                        shadowColor: color.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}