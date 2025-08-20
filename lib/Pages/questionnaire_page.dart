import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '/Pages/bai.dart';
import '/Pages/bdi.dart';
import '/Pages/pss.dart';
import '/Pages/recomendaciones.dart';
import '/Pages/profile.dart';
import '/Widgets/histogram_chart.dart';

// Paleta de colores consistente
const Color bgColor = Color(0xFF3B82F6);
const Color cardBgColor = Color(0xFF60A5FA);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFDDEAFF);
const Color accentColor = Color(0xFF93C5FD);
const Color accentColorLight = Color(0xFFBFDBFE);

class QuestionnairePage extends StatelessWidget {
  const QuestionnairePage({super.key});

  final List<Map<String, dynamic>> questionnaires = const [
    {'name': 'BAI', 'title': 'Ansiedad', 'icon': Icons.psychology_outlined},
    {'name': 'BDI', 'title': 'Depresión', 'icon': Icons.mood_outlined},
    {'name': 'PSS', 'title': 'Estrés', 'icon': Icons.spa_outlined}, 
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text(
            'Por favor inicia sesión',
            style: GoogleFonts.poppins(
              color: primaryTextColor,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('respuestas_cuestionarios')
              .where('id_user', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: accentColorLight,
                ),
              );
            }

            // Cambiado para almacenar una lista de mapas (fecha y nivel)
            final Map<String, List<Map<String, dynamic>>> historicalLevels = {
              'BAI': [],
              'BDI': [],
              'PSS': [],
            };

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final questionnaire = data['questionnaire'] as String?;
                final level = data['level'] as int?;
                final date = data['date'];

                if (questionnaire != null && level != null && date is Timestamp) {
                  final dateTime = date.toDate();

                  if (historicalLevels.containsKey(questionnaire)) {
                    historicalLevels[questionnaire]!.add({
                      'date': dateTime,
                      'level': level,
                    });
                  }
                }
              }
            }

            // Procesar los datos para obtener los últimos 5 niveles por cuestionario
            final Map<String, List<Map<String, dynamic>>> lastFiveLevels = {};
            historicalLevels.forEach((key, value) {
              // Ordenar por fecha de forma ascendente
              value.sort((a, b) => a['date'].compareTo(b['date']));
              // Tomar los últimos 5
              lastFiveLevels[key] =
                  value.length > 5 ? value.sublist(value.length - 5) : value;
            });

            bool overallHasData = false;
            for (var levelsList in lastFiveLevels.values) {
              if (levelsList.isNotEmpty) {
                overallHasData = true;
                break;
              }
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header con información del usuario y botones
                  Container(
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
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Botón de cerrar sesión en la esquina
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mis Cuestionarios',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: primaryTextColor,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showLogoutDialog(context),
                              icon: Icon(
                                Icons.logout_rounded,
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
                        const SizedBox(height: 20),
                        
                        // Información del usuario sin foto
// Reemplaza el Container de información del usuario con este código:
GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );
  },
  child: Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColorLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.person_outline,
            size: 28,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
              Text(
                user.displayName ?? 'Usuario',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: primaryTextColor.withOpacity(0.7),
        ),
      ],
    ),
  ),
),
                        const SizedBox(height: 20),

                        // Botón de historial rediseñado
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentColorLight,
                                accentColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const RecomendacionesPage()),
                              );
                            },
                            icon: Icon(
                              Icons.timeline_rounded,
                              color: bgColor,
                              size: 22,
                            ),
                            label: Text(
                              'Historial de Recomendaciones',
                              style: GoogleFonts.poppins(
                                color: bgColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contenido principal
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        if (!overallHasData &&
                            snapshot.hasData &&
                            snapshot.data!.docs.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cardBgColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cardBgColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.quiz_outlined,
                                  size: 48,
                                  color: cardBgColor,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No se encontraron respuestas para tus cuestionarios aún.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Cuestionarios
                        Column(
                          children: questionnaires.map((q) {
                            final hasData = lastFiveLevels[q['name']]!.isNotEmpty;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
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
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: cardBgColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            q['icon'] as IconData,
                                            color: cardBgColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            q['title']!,
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 18,
                                              color: const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  if (hasData)
                                    HistogramChart(
                                      data: lastFiveLevels[q['name']]!,
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: const Color(0xFF64748B),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Sin registros aún',
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF64748B),
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          _navigateToQuestionnaire(context, q['name']!);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: cardBgColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Ir al cuestionario',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Cerrar Sesión',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.pushReplacementNamed(context, 'login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cerrar Sesión',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToQuestionnaire(BuildContext context, String questionnaireName) {
    switch (questionnaireName) {
      case 'BAI':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BaiPageView()),
        );
        break;
      case 'BDI':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BdiPageView()),
        );
        break;
      case 'PSS': 
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PssPageView()),
        );
        break;
      default:
        break;
    }
  }
}