import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../state/app_state.dart';

class HomeView extends StatefulWidget {
  final AppState appState;
  const HomeView({super.key, required this.appState});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  DateTime _focusedMonth = DateTime.now();

  void _changeMonth(int increment) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + increment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard mensile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: widget.appState,
        builder: (context, child) {
          final records = widget.appState.records;

          // --- FILTRI DEL MESE CORRENTE ---
          final electricRecords = records.where((r) {
            final date = r['date'] as DateTime;
            return r['category'] == 'ricarica' && date.month == _focusedMonth.month && date.year == _focusedMonth.year;
          }).toList();

          final casaCost = electricRecords.where((r) => r['type'] == 'Domestica' || r['type'] == null).fold(0.0, (sum, r) => sum + ((r['totalCost'] ?? 0.0) as num));
          final pubCost = electricRecords.where((r) => r['type'] == 'Pubblica').fold(0.0, (sum, r) => sum + ((r['totalCost'] ?? 0.0) as num));

          final casaKwh = electricRecords.where((r) => r['type'] == 'Domestica' || r['type'] == null).fold(0.0, (sum, r) => sum + ((r['kwh'] ?? 0.0) as num));
          final pubKwh = electricRecords.where((r) => r['type'] == 'Pubblica').fold(0.0, (sum, r) => sum + ((r['kwh'] ?? 0.0) as num));
          final totalKwh = casaKwh + pubKwh;

          final fuelRecords = records.where((r) {
            final date = r['date'] as DateTime;
            return r['category'] == 'carburante' && date.month == _focusedMonth.month && date.year == _focusedMonth.year;
          }).toList();

          final fuelCost = fuelRecords.fold(0.0, (sum, r) => sum + ((r['totalCost'] ?? 0.0) as num));
          final fuelLiters = fuelRecords.fold(0.0, (sum, r) => sum + ((r['liters'] ?? 0.0) as num));

          final totalMonthCost = casaCost + pubCost + fuelCost;

          // Aggiungiamo un 15% di margine fittizio al massimo in modo che la barra più grande non tocchi mai il bordo destro
          final maxCost = max(1.0, max(casaCost, max(pubCost, fuelCost))) * 1.15;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Selettore Mese
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
                  Text(
                    DateFormat('MMMM yyyy', 'it_IT').format(_focusedMonth).toUpperCase(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _focusedMonth.month == DateTime.now().month && _focusedMonth.year == DateTime.now().year
                        ? null
                        : () => _changeMonth(1),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Riquadri Totali Centrati (3 colonne)
              Row(
                children: [
                  Expanded(child: _buildSummaryCard(context, 'Spesa', '€ ${totalMonthCost.toStringAsFixed(0)}', Icons.account_balance_wallet, Theme.of(context).colorScheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryCard(context, 'Energia', '${totalKwh.toStringAsFixed(0)} kWh', Icons.bolt, Colors.green)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildSummaryCard(context, 'Benzina', '${fuelLiters.toStringAsFixed(0)} L', Icons.local_gas_station, Colors.orange)),
                ],
              ),
              const SizedBox(height: 32),

              // Sezione Grafico Costi (Barre)
              const Text('Ripartizione Costi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildHorizontalBar(context, 'Benzina', fuelCost, maxCost, Colors.orange, '€ ${fuelCost.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _buildHorizontalBar(context, 'Ricarica Pubblica', pubCost, maxCost, Colors.blue, '€ ${pubCost.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _buildHorizontalBar(context, 'Ricarica Casa', casaCost, maxCost, Colors.green, '€ ${casaCost.toStringAsFixed(2)}'),

              const SizedBox(height: 40),

              // Sezione Grafico Consumi Elettrici (Torta)
              const Text('Consumi Elettrici', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CustomPaint(
                      painter: PieChartPainter(
                          casaKwh,
                          pubKwh,
                          Colors.green,
                          Colors.blue,
                          Theme.of(context).colorScheme.surfaceContainerHighest
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPieLegend('Casa', casaKwh, Colors.green),
                      const SizedBox(height: 16),
                      _buildPieLegend('Pubblica', pubKwh, Colors.blue),
                    ],
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

  // Widget per i 3 riquadri in alto
  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          // Usiamo FittedBox per evitare che numeri molto grandi vadano a capo
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  // Widget per la barra orizzontale
  Widget _buildHorizontalBar(BuildContext context, String label, double value, double maxValue, Color color, String valueLabel) {
    final double percentage = (value / maxValue).clamp(0.0, 1.0);

    return Column(
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
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * percentage,
                    height: 12,
                    decoration: BoxDecoration(
                      color: value > 0 ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Legenda per il grafico a torta
  Widget _buildPieLegend(String label, double value, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text('${value.toStringAsFixed(1)} kWh', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }
}

// Disegnatore custom per il grafico a torta
class PieChartPainter extends CustomPainter {
  final double casaKwh;
  final double pubKwh;
  final Color casaColor;
  final Color pubColor;
  final Color emptyColor;

  PieChartPainter(this.casaKwh, this.pubKwh, this.casaColor, this.pubColor, this.emptyColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.fill;

    final total = casaKwh + pubKwh;

    // Se non ci sono consumi, disegna un cerchio grigio
    if (total == 0) {
      paint.color = emptyColor;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    // Disegna lo spicchio Casa
    final casaAngle = (casaKwh / total) * 2 * pi;
    paint.color = casaColor;
    canvas.drawArc(rect, -pi / 2, casaAngle, true, paint);

    // Disegna lo spicchio Pubblica (inizia dove finisce Casa)
    final pubAngle = (pubKwh / total) * 2 * pi;
    paint.color = pubColor;
    canvas.drawArc(rect, -pi / 2 + casaAngle, pubAngle, true, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}