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
              backgroundColor: cardBgColor,
            ),
          );
        }
        return -1;
      }
    } catch (e) {
      debugPrint('Error al conectar con la API BAI: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: cardBgColor,
          ),
        );
      }
      return -1;
    }
  }

  void _nextPage() {
    if (currentIndex < baiQuestions.length - 1) {
      if (responses[currentIndex] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Por favor, selecciona una opción antes de continuar',
              style: GoogleFonts.poppins(color: primaryTextColor),
            ),
            backgroundColor: cardBgColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
      _swiperController.next(animation: true);
    } else {
      if (responses.length < baiQuestions.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Por favor, completa todas las preguntas',
              style: GoogleFonts.poppins(color: primaryTextColor),
            ),
            backgroundColor: cardBgColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            SnackBar(
              content: Text(
                'Error al procesar cuestionario',
                style: GoogleFonts.poppins(color: primaryTextColor),
              ),
              backgroundColor: cardBgColor,
            ),
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
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Cuestionario de Ansiedad',
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
                      '${currentIndex + 1} de ${baiQuestions.length}',
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
                  value: (currentIndex + 1) / baiQuestions.length,
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
              itemCount: baiQuestions.length,
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
                        maxHeight: screenHeight * 0.7,
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
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Ícono de ansiedad
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardBgColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.psychology_outlined,
                                  color: cardBgColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 5),
                              
                              // Pregunta
                              Text(
                                'En los últimos días, ¿has experimentado alguna de las siguientes sensaciones?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                baiQuestions[index],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 15),
                              
                              // Opciones
                              Expanded(
                                child: ListView(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  children: List.generate(opciones.length, (i) {
                                    final isSelected = responses[index] == i;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected 
                                            ? cardBgColor.withOpacity(0.1)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected 
                                              ? cardBgColor
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: RadioListTile<int>(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        title: Text(
                                          opciones[i],
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
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
                              
                              const SizedBox(height: 24),
                              
                              // Botones de navegación
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (currentIndex > 0)
                                    OutlinedButton.icon(
                                      onPressed: _previousPage,
                                      icon: Icon(Icons.arrow_back_rounded, size: 18),
                                      label: Text('Anterior'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFF64748B),
                                        side: BorderSide(
                                          color: const Color(0xFFE2E8F0),
                                          width: 1,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
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
                                      index == baiQuestions.length - 1
                                          ? Icons.check_rounded
                                          : Icons.arrow_forward_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      index == baiQuestions.length - 1
                                          ? 'Finalizar'
                                          : 'Siguiente',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: cardBgColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
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
            ),
          ),
        ],
      ),
    );
  }
}