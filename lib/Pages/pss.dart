import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'result_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PssPageView extends StatefulWidget {
  const PssPageView({super.key});

  @override
  State<PssPageView> createState() => _PssPageViewState();
}

class _PssPageViewState extends State<PssPageView> {
  final SwiperController _swiperController = SwiperController();
  int currentIndex = 0;
  final Map<int, int> responses = {};

  final List<String> pssQuestions = [
    "En el último mes, ¿con qué frecuencia te has sentido afectado por algo que ocurrió inesperadamente?",
    "En el último mes, ¿con qué frecuencia te has sentido incapaz de controlar las cosas importantes en tu vida?",
    "En el último mes, ¿con qué frecuencia te has sentido nervioso o estresado?",
    "En el último mes, ¿con qué frecuencia has manejado con éxito los pequeños problemas irritantes de la vida?",
    "En el último mes, ¿con qué frecuencia has sentido que has afrontado efectivamente los cambios importantes que han estado ocurriendo en tu vida?",
    "En el último mes, ¿con qué frecuencia has estado seguro sobre tu capacidad para manejar tus problemas personales?",
    "En el último mes, ¿con qué frecuencia has sentido que las cosas van bien?",
    "En el último mes, ¿con qué frecuencia te has sentido afectado por algo que ocurrió inesperadamente?",
    "En el último mes, ¿con qué frecuencia has podido controlar las dificultades de tu vida?",
    "En el último mes, ¿con qué frecuencia has sentido que tenías todo bajo control?",
    "En el último mes, ¿con qué frecuencia has estado enfadado porque las cosas que te han ocurrido estaban fuera de tu control?",
    "En el último mes, ¿con qué frecuencia has pensado sobre las cosas que te faltan por hacer?",
    "En el último mes, ¿con qué frecuencia has podido controlar la forma de pasar el tiempo?",
    "En el último mes, ¿con qué frecuencia has sentido que las dificultades se acumulan tanto que no puedes superarlas?",
  ];

  final List<String> opciones = [
    'Nunca',
    'Casi nunca',
    'De vez en cuando',
    'A menudo',
    'Muy a menudo',
  ];

  Future<int> _predictLevel(List<double> input) async {
    try {
      final response = await http.post(
        Uri.parse('https://mental-health-api-5mg1.onrender.com/predict/pss'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'datos': input.map((e) => e.toInt()).toList()}),
      );
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['nivel'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en la API: ${response.statusCode}')),
        );
        return -1;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      return -1;
    }
  }

  void _nextPage() {
    if (responses[currentIndex] == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona una opción')));
      return;
    }
    if (currentIndex < pssQuestions.length - 1) {
      _swiperController.next(animation: true);
    } else {
      if (responses.length < pssQuestions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa todas las preguntas')),
        );
        return;
      }
      _finalizarCuestionario();
    }
  }

  void _previousPage() {
    if (currentIndex > 0) {
      _swiperController.previous(animation: true);
    }
  }

  void _finalizarCuestionario() async {
  if (pssQuestions.length != 14) {
    debugPrint('Advertencia: pssQuestions no tiene 14 elementos. Verifique la definición de las preguntas PSS.');
    // Podrías manejar este error de forma más robusta, por ejemplo, mostrando un mensaje al usuario.
    return;
  }

  final input = List.generate(
    pssQuestions.length, // Esto debería ser 14 si pssQuestions tiene 14 elementos
    (i) => responses[i]!.toDouble(),
  );
  
  final level = await _predictLevel(input);
  if (level == -1) return;

  final total = input.fold(0, (sum, val) => sum + val.toInt());
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      // Obtener la carrera desde Firestore solo para usarla en la API
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final carrera = docSnapshot.data()?['class'] ?? 'Sin carrera';

      // Guardar solo los datos esenciales en Firebase (sin carrera ni total)
      await FirebaseFirestore.instance
          .collection('respuestas_cuestionarios')
          .add({
            'id_user': user.uid,
            'questionnaire': 'PSS',
            'level': level,
            'date': FieldValue.serverTimestamp(),
          });

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultPage(
              total: total, // Pasamos el total calculado
              level: level,
              carrera: carrera, // Pasamos la carrera obtenida
              cuestionario: "PSS",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al procesar cuestionario: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar cuestionario')),
        );
      }
    }
  }
}

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Estrés'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Swiper(
        controller: _swiperController,
        itemCount: pssQuestions.length,
        loop: false,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: screenWidth > 600 ? 80 : 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 600,
                  maxHeight: screenHeight * 0.7,
                ),
                child: Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Pregunta ${index + 1} de ${pssQuestions.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          pssQuestions[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: Center(
                            child: ListView(
                              shrinkWrap: true,
                              physics: const ClampingScrollPhysics(),
                              children: List.generate(opciones.length, (i) {
                                return RadioListTile<int>(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    opciones[i],
                                    style: TextStyle(
                                      fontSize: 15,
                                      color:
                                          responses[index] == i
                                              ? Colors.white
                                              : Colors.grey[300],
                                      shadows: [
                                        Shadow(
                                          color:
                                              responses[index] == i
                                                  ? Colors.white.withOpacity(
                                                    0.8,
                                                  )
                                                  : Colors.grey[300]!
                                                      .withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  value: i,
                                  groupValue: responses[index],
                                  activeColor: Colors.white,
                                  fillColor:
                                      MaterialStateProperty.resolveWith<Color>((
                                        states,
                                      ) {
                                        if (states.contains(
                                          MaterialState.selected,
                                        )) {
                                          return Colors.white;
                                        }
                                        return Colors.grey[600]!;
                                      }),
                                  onChanged: (value) {
                                    setState(() => responses[index] = value!);
                                  },
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(
                              onPressed:
                                  currentIndex > 0 ? _previousPage : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.transparent,
                                side: BorderSide(
                                  color:
                                      currentIndex > 0
                                          ? Colors.white
                                          : Colors.grey[800]!,
                                  width: 1.5,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                shadowColor: Colors.white.withOpacity(0.5),
                              ),
                              child: const Text(
                                'Anterior',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _nextPage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                                shadowColor: Colors.white.withOpacity(0.5),
                              ),
                              child: Text(
                                index == pssQuestions.length - 1
                                    ? 'Finalizar'
                                    : 'Siguiente',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
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
            ),
          );
        },
        onIndexChanged: (index) => setState(() => currentIndex = index),
        pagination: const SwiperPagination(
          margin: EdgeInsets.only(bottom: 8),
          builder: DotSwiperPaginationBuilder(
            activeColor: Colors.white,
            color: Color.fromARGB(255, 90, 90, 90),
            size: 8,
            activeSize: 10,
            space: 6,
          ),
        ),
      ),
    );
  }
}
