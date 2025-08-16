import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Paleta de colores consistente
const Color bgColor = Color(0xFF3B82F6);
const Color cardBgColor = Color(0xFF60A5FA);
const Color primaryTextColor = Colors.white;
const Color secondaryTextColor = Color(0xFFDDEAFF);
const Color accentColor = Color(0xFF93C5FD);
const Color accentColorLight = Color(0xFFBFDBFE);

 String _formatearFecha(Timestamp? fecha) {
    if (fecha == null) return 'Fecha desconocida';
    return DateFormat('dd/MM/yyyy - HH:mm').format(fecha.toDate());
  }

  Color _getColorByQuestionnaire(String cuestionario) {
    switch (cuestionario) {
      case 'BAI':
        return const Color(0xFF10B981); // Verde
      case 'BDI':
        return const Color(0xFF3B82F6); // Azul
      case 'PSS':
        return const Color(0xFFF59E0B); // Amarillo
      default:
        return accentColor;
    }
  }

class RecomendacionesPage extends StatelessWidget {
  const RecomendacionesPage({super.key});

  Future<List<Map<String, dynamic>>> _obtenerRecomendaciones() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('recomendaciones')
        .orderBy('fecha', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'fecha': doc['fecha'],
              'cuestionario': doc['cuestionario'],
              'nivel': doc['nivel'],
              'puntaje': doc['puntaje'],
              'carrera': doc['carrera'],
              'recomendacion': doc['recomendacion'],
            })
        .toList();
  }

 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Historial de Recomendaciones',
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
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _obtenerRecomendaciones(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: accentColorLight,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes recomendaciones guardadas',
                    style: GoogleFonts.poppins(
                      color: secondaryTextColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final recomendaciones = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...recomendaciones.map((item) => _RecommendationCard(item: item)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  final Map<String, dynamic> item;

  const _RecommendationCard({required this.item});

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final color = _getColorByQuestionnaire(widget.item['cuestionario']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Ícono
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconByQuestionnaire(widget.item['cuestionario']),
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item['cuestionario'],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        Text(
                          'Nivel ${widget.item['nivel']} | Puntaje: ${widget.item['puntaje']}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Fecha y flecha
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatearFecha(widget.item['fecha']),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Contenido expandible
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carrera
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 16,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.item['carrera'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Recomendación
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.item['recomendacion'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconByQuestionnaire(String cuestionario) {
    switch (cuestionario) {
      case 'BAI':
        return Icons.psychology_outlined;
      case 'BDI':
        return Icons.mood_outlined;
      case 'PSS':
        return Icons.spa_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }
}