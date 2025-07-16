import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/Pages/bai.dart';
import '/Pages/bdi.dart';
import '/Pages/pss.dart';
import '/widgets/histogram_chart.dart'; // Asegúrate de que esta ruta sea correcta

class QuestionnairePage extends StatelessWidget {
  const QuestionnairePage({super.key});

  final List<Map<String, dynamic>> questionnaires = const [
    {'name': 'BAI', 'title': 'Ansiedad'},
    {'name': 'BDI', 'title': 'Depresión'},
    {'name': 'PSS', 'title': 'Estrés'}, 
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Por favor inicia sesión')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cuestionarios'),
        backgroundColor: Colors.grey[900], // Asegura un color oscuro para el AppBar
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('respuestas_cuestionarios')
              .where('id_user', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
              lastFiveLevels[key] = value.length > 5 ? value.sublist(value.length - 5) : value;
            });


            bool overallHasData = false;
            for (var levelsList in lastFiveLevels.values) {
              if (levelsList.isNotEmpty) {
                overallHasData = true;
                break;
              }
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage('/profile_placeholder_1.jpg'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? 'Usuario',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (!overallHasData && snapshot.hasData && snapshot.data!.docs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'No se encontraron respuestas para tus cuestionarios aún.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                    ),
                  Column(
                    children: questionnaires.map((q) {
                      final hasData = lastFiveLevels[q['name']]!.isNotEmpty;

                      return Card(
                        color: Colors.grey[850], // Un color oscuro para las tarjetas
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey[700]!, width: 1),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16, left: 16),
                              child: Text(
                                q['title']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white, // Color de texto para el título
                                ),
                              ),
                            ),
                            if (hasData)
                              HistogramChart(
                                data: lastFiveLevels[q['name']]!, 
                              )
                            else
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Sin registros aún',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    _navigateToQuestionnaire(context, q['name']!);
                                  },
                                  icon: const Icon(Icons.arrow_forward, color: Colors.white70),
                                  label: const Text('Ir al cuestionario', style: TextStyle(color: Colors.white)),
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.transparent, // Fondo transparente
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(color: Colors.white.withOpacity(0.3)), // Borde más suave
                                    ),
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
            );
          },
        ),
      ),
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