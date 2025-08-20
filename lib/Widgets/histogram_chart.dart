import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatear las fechas

class HistogramChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const HistogramChart({super.key, required this.data});

  Color _getColor(int level) {
    switch (level) {
      case 0: // Nivel mínimo (ej: Sin ansiedad/estrés)
        return const Color(0xFF00FFAA); // Verde claro
      case 1: // Nivel leve
        return const Color(0xFFFFE600); // Amarillo
      case 2: // Nivel moderado
        return const Color(0xFFFF7B00); // Naranja
      case 3: // Nivel severo
        return const Color(0xFFFF007A); // Rosa fuerte
      default:
        return Colors.white; // Color por defecto
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sortedData = data; // Ya vienen ordenados

    final barGroups = sortedData.asMap().entries.map((entry) {
      final index = entry.key; // Usar el índice como valor X (0 a 4)
      final level = entry.value['level'] as int;
      return BarChartGroupData(
        x: index, 
        barRods: [
          BarChartRodData(
            toY: level.toDouble(),
            color: _getColor(level),
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        // No necesitamos mostrar indicators si el tooltip solo muestra el nivel
        // y el eje X ya lo etiqueta.
        // showingTooltipIndicators: [0], // Puedes quitar esto si no quieres el efecto de highlight
      );
    }).toList();

    final List<int> levels = sortedData.map((e) => e['level'] as int).toList();

    final maxLevel = levels.isNotEmpty
        ? levels.reduce((a, b) => a > b ? a : b)
        : 0;
    final dynamicMaxY = maxLevel < 3 ? 4 : maxLevel + 1; 

    return Container(
      height: 120, 
      padding: const EdgeInsets.only(top: 10, right: 10, left: 10),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: dynamicMaxY.toDouble(),
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true, // Permitir que el tooltip aparezca al tocar
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                // **CAMBIO CLAVE: Muestra solo el nivel**
                return BarTooltipItem(
                  'Nivel ${rod.toY.toInt()}', 
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Estilo más legible
                );
              },
              // Opcional: Alinear el tooltip para que no tape el nombre
              tooltipBgColor: Colors.black.withOpacity(0.7), // Fondo del tooltip más oscuro
              tooltipBorder: const BorderSide(color: Colors.white38, width: 0.5),
              tooltipRoundedRadius: 8,
              // Esto ayuda a que el tooltip no se dibuje sobre el título si está en el borde superior
              fitInsideHorizontally: true, 
              fitInsideVertically: true, 
            ),
          ),
          barGroups: barGroups,
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  String labelText = '';

                  if (index >= 0 && index < sortedData.length) {
                    final DateTime currentDate = sortedData[index]['date'];
                    // **CAMBIO CLAVE: Siempre muestra la fecha (dd/MM)**
                    labelText = DateFormat('dd/MM').format(currentDate);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      labelText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1, 
                getTitlesWidget: (value, meta) {
                  if (value >= 0 && value <= 3) { // Asumimos niveles de 0 a 3
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
              left: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            horizontalInterval: 1, 
            getDrawingHorizontalLine:
                (_) => FlLine(color: Colors.white24, strokeWidth: 1),
            checkToShowHorizontalLine: (value) => value % 1 == 0,
          ),
        ),
      ),
    );
  }
}