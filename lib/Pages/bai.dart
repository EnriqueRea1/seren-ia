import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'result_page.dart';

class BaiPageView extends StatefulWidget {
  const BaiPageView({super.key});

  @override
  State<BaiPageView> createState() => _BaiPageViewState();
}

class _BaiPageViewState extends State<BaiPageView> {
  final SwiperController _swiperController = SwiperController();
  int currentIndex = 0;
  final Map<int, int> responses = {};

  final List<String> baiQuestions = [
    "Torpe o entumecido",
    "Acalorado",
    "Temblor en las piernas",
    "Incapaz de relajarse",
    "Temor a que ocurra lo peor",
    "Mareado o aturdido",
    "Palpitaciones rápidas",
    "Inestable",
    "Atemorizado",
    "Nervioso",
    "Bloqueado",
    "Temblores en las manos",
    "Inquieto o inseguro",
    "Miedo a perder el control",
    "Sensación de ahogo",
    "Temor a morir",
    "Miedo",
    "Problemas digestivos",
    "Desvanecimientos",
    "Rubor facial",
    "Sudoración fría o caliente",
  ];

  final List<String> opciones = [
    'En absoluto',
    'Levemente',
    'Moderadamente',
    'Severamente',
  ];

  Future<int> _predictLevel(List<double> input) async {
    try {
      final response = await http.post(
        Uri.parse('https://mental-health-api-5mg1.onrender.com/predict/bai'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'datos': input.map((e) => e.toInt()).toList()}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final int level = json['nivel'];
        final List<dynamic> distribucion = json['distribucion'][0];

        debugPrint('Distribución BAI: $distribucion, Nivel predicho: $level');
        return level;
      } else {
        debugPrint('Error en la API BAI: ${response.body}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error en la API: ${response.statusCode} - ${response.body}',
              ),
            ),
          );
        }
        return -1;
      }
    } catch (e) {
      debugPrint('Error al conectar con la API BAI: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
      return -1;
    }
  }

  void _nextPage() {
    if (currentIndex < baiQuestions.length - 1) {
      if (responses[currentIndex] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Por favor, selecciona una opción antes de continuar',
            ),
          ),
        );
        return;
      }
      _swiperController.next(animation: true);
    } else {
      if (responses.length < baiQuestions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, completa todas las preguntas'),
          ),
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
  final input = List.generate(
    baiQuestions.length,
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
            'questionnaire': 'BAI',
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
              cuestionario: "BAI",
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
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Ansiedad'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Swiper(
        controller: _swiperController,
        itemCount: baiQuestions.length,
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
                          'Pregunta ${index + 1} de ${baiQuestions.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          baiQuestions[index],
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
                                index == baiQuestions.length - 1
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
