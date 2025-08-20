import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'result_page.dart';

// Paleta de colores consistente
const Color bgColor = Color(0xFF3B82F6);
const Color cardBgColor = Color(0xFF60A5FA);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFDDEAFF);
const Color accentColor = Color(0xFF93C5FD);
const Color accentColorLight = Color(0xFFBFDBFE);

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
    "assets/p1_tristeza.png",
    "assets/p2_pesimismo.png",
    "assets/p3_fracaso.png",
    "assets/p4_placer.png",
    "assets/p5_culpa.png",
    "assets/p6_castigo.png",
    "assets/p7_disconformidad.png",
    "assets/p8_autocritica.png",
    "assets/p9_suicidio.png",
    "assets/p10_llanto.png",
    "assets/p11_agitacion.png",
    "assets/p12_interes.png",
    "assets/p13_indecision.png",
    "assets/p14_indecision.png",
    "assets/p15_energia.png",
    "assets/p16_sueno.png",
    "assets/p17_irritabilidad.png",
    "assets/p18_apetito.png",
    "assets/p19_concentracion.png",
    "assets/p20_fatiga.png",
    "assets/p21_sexualidad.png",
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
      "Puedo concentrarme tan bien como siempre.",
      "No puedo concentrarme tan bien como habitualmente .",
      "Me es difícil mantener la mente en algo por mucho tiempo.",
      "Encuentro que no puedo concentrarme en nada.",
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
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Cuestionario de Depresión',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        backgroundColor: bgColor,
        foregroundColor: primaryTextColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryTextColor),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: primaryTextColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Barra de progreso
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pregunta ${currentIndex + 1}',
                      style: GoogleFonts.poppins(
                        color: secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${currentIndex + 1} de ${bdiQuestions.length}',
                      style: GoogleFonts.poppins(
                        color: secondaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                LinearProgressIndicator(
                  value: (currentIndex + 1) / bdiQuestions.length,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColorLight),
                  borderRadius: BorderRadius.circular(8),
                  minHeight: 8,
                ),
              ],
            ),
          ),
          
          // Contenido del swiper
          Expanded(
            child: Swiper(
              controller: _swiperController,
              itemCount: bdiQuestions.length,
              loop: false,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: screenWidth > 600 ? 80 : 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 600,
                        maxHeight: screenHeight * 0.67,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Imagen representativa
                              Container(
                                height: 180, // Altura fija para la imagen
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  bdiQuestions[index],
                                  fit: BoxFit.contain,
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Opciones
                              Expanded(
                                child: ListView(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  padding: EdgeInsets.zero,
                                  children: List.generate(opciones[index].length, (i) {
                                    final isSelected = responses[index] == i;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? cardBgColor.withOpacity(0.1)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected 
                                              ? cardBgColor
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: RadioListTile<int>(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        title: Text(
                                          opciones[index][i],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: isSelected 
                                                ? cardBgColor 
                                                : const Color(0xFF475569),
                                            fontWeight: isSelected 
                                                ? FontWeight.w600 
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        value: i,
                                        groupValue: responses[index],
                                        activeColor: cardBgColor,
                                        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                          if (states.contains(MaterialState.selected)) {
                                            return cardBgColor;
                                          }
                                          return const Color(0xFFCBD5E1);
                                        }),
                                        onChanged: (value) {
                                          setState(() => responses[index] = value!);
                                        },
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              
                              // Botones de navegación
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (currentIndex > 0)
                                      OutlinedButton.icon(
                                        onPressed: _previousPage,
                                        icon: Icon(Icons.arrow_back_rounded, size: 16),
                                        label: Text(
                                          'Anterior',
                                          style: GoogleFonts.poppins(fontSize: 13),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF64748B),
                                          side: BorderSide(
                                            color: const Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    
                                    ElevatedButton.icon(
                                      onPressed: _nextPage,
                                      icon: Icon(
                                        index == bdiQuestions.length - 1
                                            ? Icons.check_rounded
                                            : Icons.arrow_forward_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        index == bdiQuestions.length - 1
                                            ? 'Finalizar'
                                            : 'Siguiente',
                                        style: GoogleFonts.poppins(fontSize: 13),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cardBgColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ],
                                ),
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
            ),
          ),
        ],
      ),
    );
  }
}