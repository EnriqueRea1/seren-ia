import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'result_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BdiPageView extends StatefulWidget {
  const BdiPageView({super.key});

  @override
  State<BdiPageView> createState() => _BdiPageViewState();
}

class _BdiPageViewState extends State<BdiPageView> {
  final SwiperController _swiperController = SwiperController();
  int currentIndex = 0;
  final Map<int, int> responses = {};

  final List<String> bdiQuestions = [
    "Tristeza",
    "Pesimismo",
    "Fracaso",
    "Pérdida de Placer",
    "Sentimientos de Culpa",
    "Sentimientos de Castigo",
    "Disconformidad con uno mismo",
    "Autocrítica",
    "Pensamientos o Deseos Suicidas",
    "Llanto",
    "Agitación",
    "Pérdida de Interés",
    "Indecisión",
    "Desvalorización",
    "Pérdida de Energía",
    "Cambios en los Hábitos de Sueño",
    "Irritabilidad",
    "Cambios en el Apetito",
    "Dificultad de Concentración",
    "Cansancio o Fatiga",
    "Pérdida de Interés en el Sexo",
  ];

  final List<List<String>> opciones = [
    [
      "No me siento triste.",
      "Me siento triste gran parte del tiempo.",
      "Me siento triste todo el tiempo.",
      "Me siento tan triste o soy tan infeliz que no puedo soportarlo.",
    ],
    [
      "No estoy desalentado respecto de mi futuro.",
      "Me siento más desalentado respecto de mi futuro que lo que solía estarlo.",
      "No espero que las cosas funcionen para mí.",
      "Siento que no hay esperanza para mi futuro y que sólo puede empeorar.",
    ],
    [
      "No me siento como un fracasado.",
      "He fracasado más de lo que hubiera debido.",
      "Cuando miro hacia atrás, veo muchos fracasos.",
      "Siento que como persona soy un fracaso total.",
    ],
    [
      "Obtengo tanto placer como siempre por las cosas de las que disfruto.",
      "No disfruto tanto de las cosas como solía hacerlo.",
      "Obtengo muy poco placer de las cosas que solía disfrutar.",
      "No puedo obtener ningún placer de las cosas de las que solía disfrutar.",
    ],
    [
      "No me siento particularmente culpable.",
      "Me siento culpable respecto de varias cosas que he hecho o que debería haber.",
      "Me siento bastante culpable la mayor parte del tiempo.",
      "Me siento culpable todo el tiempo.",
    ],
    [
      "No siento que esté siendo castigado.",
      "Siento que tal vez pueda ser castigado.",
      "Espero ser castigado.",
      "Siento que estoy siendo castigado.",
    ],
    [
      "Siento acerca de mí lo mismo que siempre.",
      "He perdido la confianza en mí mismo.",
      "Estoy decepcionado conmigo mismo.",
      "No me gusto a mí mismo.",
    ],
    [
      "No me critico ni me culpo más de lo habitual.",
      "Estoy más crítico conmigo mismo de lo que solía estarlo.",
      "Me critico a mí mismo por todos mis errores.",
      "Me culpo a mí mismo por todo lo malo que sucede.",
    ],
    [
      "No tengo ningún pensamiento de matarme.",
      "He tenido pensamientos de matarme, pero no lo haría.",
      "Querría matarme.",
      "Me mataría si tuviera la oportunidad de hacerlo.",
    ],
    [
      "No lloro más de lo que solía hacerlo.",
      "Lloro más de lo que solía hacerlo.",
      "Lloro por cualquier pequeñez.",
      "Siento ganas de llorar, pero no puedo.",
    ],
    [
      "No estoy más inquieto o tenso que lo habitual.",
      "Me siento más inquieto o tenso que lo habitual.",
      "Estoy tan inquieto o agitado que me es difícil quedarme quieto.",
      "Estoy tan inquieto o agitado que tengo que estar siempre en movimiento o haciendo algo.",
    ],
    [
      "No he perdido el interés en otras actividades o personas.",
      "Estoy menos interesado que antes en otras personas o cosas.",
      "He perdido casi todo el interés en otras personas o cosas.",
      "Me es difícil interesarme por algo.",
    ],
    [
      "Tomo mis propias decisiones tan bien como siempre.",
      "Me resulta más difícil que de costumbre tomar decisiones.",
      "Encuentro mucha más dificultad que antes para tomar decisiones.",
      "Tengo problemas para tomar cualquier decisión.",
    ],
    [
      "No siento que yo no sea valioso.",
      "No me considero a mí mismo tan valioso y útil como solía considerarme.",
      "Me siento menos valioso cuando me comparo con otros.",
      "Siento que no valgo nada.",
    ],
    [
      "Tengo tanta energía como siempre.",
      "Tengo menos energía que la que solía tener.",
      "No tengo suficiente energía para hacer demasiado.",
      "No tengo energía suficiente para hacer nada.",
    ],
    [
      "No he experimentado ningún cambio en mis hábitos de sueño.",
      "Duermo un poco más/menos que lo habitual.",
      "Duermo mucho más/menos que lo habitual.",
      "Duermo la mayor parte del día o me despierto 1-2 horas más temprano y no puedo volver a dormirme.",
    ],
    [
      "No estoy tan irritable que lo habitual.",
      "Estoy más irritable que lo habitual.",
      "Estoy mucho más irritable que lo habitual.",
      "Estoy irritable todo el tiempo.",
    ],
    [
      "No he experimentado ningún cambio en mi apetito.",
      "Mi apetito es un poco menor/mayor que lo habitual.",
      "Mi apetito es mucho menor/mayor que lo habitual.",
      "No tengo apetito en absoluto o quiero comer todo el día.",
    ],
    [
      "No estoy más cansado o fatigado que lo habitual.",
      "Me fatigo o me canso más fácilmente que lo habitual.",
      "Estoy demasiado fatigado o cansado para hacer muchas de las cosas que solía hacer.",
      "Estoy demasiado fatigado o cansado para hacer la mayoría de las cosas que solía.",
    ],
    [
      "No estoy más cansado o fatigado que lo habitual.",
      "Me fatigo o me canso más fácilmente que lo habitual.",
      "Estoy demasiado fatigado o cansado para hacer muchas de las cosas que solía hacer.",
      "Estoy demasiado fatigado o cansado para hacer la mayoría de las cosas que solía.",
    ],
    [
      "No he notado ningún cambio reciente en mi interés por el sexo.",
      "Estoy menos interesado en el sexo de lo que solía estarlo.",
      "Estoy mucho menos interesado en el sexo.",
      "He perdido completamente el interés en el sexo.",
    ],
  ];

  Future<int> _predictLevel(List<double> input) async {
  try {
    final response = await http.post(
      Uri.parse('https://mental-health-api-5mg1.onrender.com/predict/bdi'),
      headers: {'Content-Type': 'application/json'},
      // CORREGIR: Enviar los valores directos 0-3, no transformados
      body: jsonEncode({'datos': input.map((e) => e.toInt()).toList()}),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final int level = json['nivel'];
      final List<dynamic> distribucion = json['distribucion'][0];
      debugPrint('Distribución BDI: $distribucion, Nivel predicho: $level');
      return level;
    } else {
      debugPrint('Error en la API BDI: ${response.body}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en la API: ${response.statusCode}')),
        );
      }
      return -1;
    }
  } catch (e) {
    debugPrint('Error al conectar con la API BDI: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
    return -1;
  }
}

  void _nextPage() {
    if (currentIndex < bdiQuestions.length - 1) {
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
      if (responses.length < bdiQuestions.length) {
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
    bdiQuestions.length,
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
            'questionnaire': 'BDI',
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
              cuestionario: "BDI",
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
        title: const Text('Depresión'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Swiper(
        controller: _swiperController,
        itemCount: bdiQuestions.length,
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
                          'Pregunta ${index + 1} de ${bdiQuestions.length}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          bdiQuestions[index],
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
                              children: List.generate(opciones[index].length, (
                                i,
                              ) {
                                return RadioListTile<int>(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    opciones[index][i],
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
                                index == bdiQuestions.length - 1
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
