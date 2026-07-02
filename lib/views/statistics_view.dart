import 'package:flutter/material.dart';
import 'dart:math';
import '../state/app_state.dart';

class StatisticsView extends StatefulWidget {
  final AppState appState;
  const StatisticsView({super.key, required this.appState});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  int _selectedYear = DateTime.now().year;

  final List<String> _monthLabels = ['G', 'F', 'M', 'A', 'M', 'G', 'L', 'A', 'S', 'O', 'N', 'D'];
  final List<String> _fullMonthLabels = ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'];

  void _changeYear(int increment) {
    setState(() {
      _selectedYear += increment;
    });
  }

  // Mappatura colori gestori dinamica
  Color _getProviderColor(String providerName, int fallbackIndex) {
    final name = providerName.toLowerCase();

    if (name.contains('enel')) return Colors.pink.shade700; // Rosa scuro
    if (name.contains('plenitude') || name.contains('be charge')) return Colors.green;
    if (name.contains('asm')) return Colors.yellow.shade700;

    // Altri gestori a rotazione
    final fallbacks = [Colors.blue, Colors.purple, Colors.teal, Colors.redAccent, Colors.indigo, Colors.cyan, Colors.deepOrange];
    return fallbacks[fallbackIndex % fallbacks.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche Annuali', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: widget.appState,
        builder: (context, child) {
          final yearRecords = widget.appState.records.where((r) {
            final date = r['date'] as DateTime;
            return date.year == _selectedYear;
          }).toList();

          // --- AGGREGAZIONI GLOBALI ---
          final electricRecords = yearRecords.where((r) => r['category'] == 'ricarica').toList();
          final electricCost = electricRecords.fold(0.0, (sum, r) => sum + ((r['totalCost'] ?? 0.0) as num));
          final totalKwh = electricRecords.fold(0.0, (sum, r) => sum + ((r['kwh'] ?? 0.0) as num));

          final fuelRecords = yearRecords.where((r) => r['category'] == 'carburante').toList();
          final fuelCost = fuelRecords.fold(0.0, (sum, r) => sum + ((r['totalCost'] ?? 0.0) as num));
          final totalLiters = fuelRecords.fold(0.0, (sum, r) => sum + ((r['liters'] ?? 0.0) as num));

          final otherRecords = yearRecords.where((r) => r['category'] != 'ricarica' && r['category'] != 'carburante').toList();
          final otherCost = otherRecords.fold(0.0, (sum, r) => sum + ((r['totalCost'] ?? 0.0) as num));

          final totalAnnualCost = electricCost + fuelCost + otherCost;
          final maxCost = max(1.0, max(electricCost, max(fuelCost, otherCost))) * 1.15;

          // --- AGGREGAZIONI MENSILI E SPECIFICHE ---
          List<double> casaKwhPerMonth = List.filled(12, 0.0);
          List<double> pubKwhPerMonth = List.filled(12, 0.0);
          List<double> litersPerMonth = List.filled(12, 0.0);
          List<double> autostradaPerMonth = List.filled(12, 0.0);

          Map<String, double> providerKwh = {};
          double totalPubKwh = 0.0; // Ci serve per calcolare le percentuali assolute

          for (var r in yearRecords) {
            final monthIdx = (r['date'] as DateTime).month - 1;

            if (r['category'] == 'ricarica') {
              final kwh = (r['kwh'] as num?)?.toDouble() ?? 0.0;
              if (r['type'] == 'Pubblica') {
                pubKwhPerMonth[monthIdx] += kwh;
                totalPubKwh += kwh;
                final provider = r['provider'] as String? ?? 'Sconosciuto';
                providerKwh[provider] = (providerKwh[provider] ?? 0.0) + kwh;
              } else {
                casaKwhPerMonth[monthIdx] += kwh;
              }
            } else if (r['category'] == 'carburante') {
              litersPerMonth[monthIdx] += (r['liters'] as num?)?.toDouble() ?? 0.0;
            } else if (r['category'] == 'Autostrada') {
              autostradaPerMonth[monthIdx] += (r['totalCost'] as num?)?.toDouble() ?? 0.0;
            }
          }

          var sortedProviders = providerKwh.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

          // Generiamo i colori assegnati per la lista ordinata
          List<Color> assignedColors = [];
          for (int i = 0; i < sortedProviders.length; i++) {
            assignedColors.add(_getProviderColor(sortedProviders[i].key, i));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Selettore Anno
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeYear(-1)),
                  Text('$_selectedYear', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _selectedYear >= DateTime.now().year ? null : () => _changeYear(1),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Totale Anno
              Center(
                child: Column(
                  children: [
                    const Text('Spesa Totale Annua', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    // Font size ridotto da 56 a 42
                    Text('€ ${totalAnnualCost.toStringAsFixed(0)}', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(child: _buildInfoCard(context, 'Energia Tot.', '${totalKwh.toStringAsFixed(0)} kWh', Icons.bolt, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoCard(context, 'Benzina Tot.', '${totalLiters.toStringAsFixed(0)} L', Icons.local_gas_station, Colors.orange)),
                ],
              ),
              const SizedBox(height: 40),

              const Text('Ripartizione Spese Globali', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildHorizontalBar(context, 'Gestione e Varie', otherCost, maxCost, Colors.purple, '€ ${otherCost.toStringAsFixed(0)}', icon: Icons.receipt_long),
              const SizedBox(height: 16),
              _buildHorizontalBar(context, 'Benzina', fuelCost, maxCost, Colors.orange, '€ ${fuelCost.toStringAsFixed(0)}', icon: Icons.local_gas_station),
              const SizedBox(height: 16),
              _buildHorizontalBar(context, 'Elettrico', electricCost, maxCost, Colors.blue, '€ ${electricCost.toStringAsFixed(0)}', icon: Icons.ev_station),

              const SizedBox(height: 48),

              const Text('Trend Consumo Elettrico (kWh)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildMonthlyStackedBarChart(context, casaKwhPerMonth, pubKwhPerMonth, Colors.green, Colors.blue),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Casa', Colors.green),
                  const SizedBox(width: 24),
                  _buildLegendItem('Pubblica', Colors.blue),
                ],
              ),

              const SizedBox(height: 48),

              const Text('Trend Benzina (Litri)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildMonthlyBarChart(context, litersPerMonth, Colors.orange),

              const SizedBox(height: 48),

              const Text('Costi Autostrada Mensili (€)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (autostradaPerMonth.every((v) => v == 0))
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nessun pedaggio autostradale registrato in questo anno.', style: TextStyle(color: Colors.grey)),
                )
              else
                _buildMonthlyBarChart(context, autostradaPerMonth, Colors.indigo),

              const SizedBox(height: 48),

              const Text('Divisione Gestori Pubblici', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              if (sortedProviders.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Nessuna ricarica pubblica registrata in questo anno.', style: TextStyle(color: Colors.grey)),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CustomPaint(
                        painter: MultiPieChartPainter(
                          values: sortedProviders.map((e) => e.value).toList(),
                          colors: assignedColors,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 24,
                      runSpacing: 20,
                      children: List.generate(sortedProviders.length, (index) {
                        final val = sortedProviders[index].value;
                        return _buildPieLegend(
                            sortedProviders[index].key,
                            val,
                            assignedColors[index]
                        );
                      }),
                    ),
                  ],
                ),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  // Widget Riquadri in alto
  Widget _buildInfoCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  // Barra Orizzontale
  Widget _buildHorizontalBar(BuildContext context, String label, double value, double maxValue, Color color, String valueLabel, {IconData? icon}) {
    final double percentage = (value / maxValue).clamp(0.0, 1.0);

    return Row(
      children: [
        if (icon != null) ...[
          CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(valueLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth * percentage,
                          height: 12,
                          decoration: BoxDecoration(color: value > 0 ? color : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Grafico a Barre Verticali (Singolo)
  Widget _buildMonthlyBarChart(BuildContext context, List<double> data, Color color) {
    final maxVal = max(1.0, data.reduce(max));
    const double chartHeight = 150;

    return SizedBox(
      height: chartHeight + 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (index) {
          final height = (data[index] / maxVal) * chartHeight;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (data[index] > 0)
                  Text(data[index].toStringAsFixed(0), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  width: 16,
                  height: height,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(height: 8),
                Text(_monthLabels[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ),
    );
  }

  // Grafico a Barre Verticali (Stacked / Impilato)
  Widget _buildMonthlyStackedBarChart(BuildContext context, List<double> bottomData, List<double> topData, Color bottomColor, Color topColor) {
    double maxVal = 1.0;
    for (int i = 0; i < 12; i++) {
      maxVal = max(maxVal, bottomData[i] + topData[i]);
    }
    const double chartHeight = 150;

    return SizedBox(
      height: chartHeight + 50,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(12, (index) {
          final bHeight = (bottomData[index] / maxVal) * chartHeight;
          final tHeight = (topData[index] / maxVal) * chartHeight;
          final total = bottomData[index] + topData[index];

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (total > 0)
                  Text(total.toStringAsFixed(0), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 16,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(duration: const Duration(milliseconds: 600), height: tHeight, color: topColor),
                        AnimatedContainer(duration: const Duration(milliseconds: 600), height: bHeight, color: bottomColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_monthLabels[index], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Legenda Torta senza Percentuali
  Widget _buildPieLegend(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('${value.toStringAsFixed(1)} kWh', style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}

// Disegnatore custom per il grafico a torta multiplo con percentuali scritte sopra
class MultiPieChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  MultiPieChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    final total = values.fold(0.0, (sum, val) => sum + val);

    if (total == 0) return;

    double startAngle = -pi / 2; // Inizia a ore 12

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * pi;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Disegna la percentuale se lo spicchio è > 4% per evitare sovrapposizioni
      final percentage = (values[i] / total) * 100;
      if (percentage > 4.0) {
        final textAngle = startAngle + sweepAngle / 2;
        final textRadius = radius * 0.65; // A 2/3 del raggio dal centro

        final dx = center.dx + textRadius * cos(textAngle);
        final dy = center.dy + textRadius * sin(textAngle);

        final textSpan = TextSpan(
          text: '${percentage.toStringAsFixed(0)}%',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)]
          ),
        );
        final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();

        // Centriamo il testo sulle coordinate calcolate
        textPainter.paint(canvas, Offset(dx - textPainter.width / 2, dy - textPainter.height / 2));
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}