import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../widgets/add_expense_sheet.dart';

class OtherExpensesView extends StatelessWidget {
  final AppState appState;
  const OtherExpensesView({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico Spese', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, child) {
          // Filtriamo tutto ciò che NON è ricarica e NON è carburante
          final records = appState.records.where((r) => r['category'] != 'ricarica' && r['category'] != 'carburante').toList();

          if (records.isEmpty) {
            return const Center(
              child: Text('Nessuna spesa registrata.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              final category = r['category'] as String? ?? 'Altro';
              final cost = (r['totalCost'] as num?)?.toDouble() ?? 0.0;
              final notes = r['notes'] as String? ?? '';

              // Gestione avanzata delle date (per spese annuali/periodiche)
              String dateString = '';
              if (r['startDate'] != null && r['endDate'] != null) {
                final start = DateTime.parse(r['startDate']);
                final end = DateTime.parse(r['endDate']);
                dateString = 'Valida dal ${DateFormat('dd/MM/yy').format(start)}\nal ${DateFormat('dd/MM/yy').format(end)}';
              } else {
                final date = r['date'] as DateTime;
                dateString = DateFormat('dd MMM yyyy', 'it_IT').format(date);
              }

              // Dinamica dei colori e delle icone in base alla categoria
              IconData icon = Icons.receipt_long;
              Color color = Colors.purple;

              if (category.toLowerCase() == 'autostrada') {
                icon = Icons.add_road;
                color = Colors.indigo;
              } else if (category.toLowerCase() == 'assicurazione') {
                icon = Icons.shield;
                color = Colors.teal;
              } else if (category.toLowerCase() == 'bollo') {
                icon = Icons.description;
                color = Colors.redAccent;
              } else if (category.toLowerCase() == 'tagliando') {
                icon = Icons.build;
                color = Colors.blueGrey;
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: color.withOpacity(0.3), width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Icon(icon, color: color),
                  ),
                  title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(dateString, style: const TextStyle(height: 1.3, fontSize: 13)),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(notes, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
                      ]
                    ],
                  ),
                  trailing: Text('€ ${cost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                      builder: (ctx) => AddExpenseSheet(appState: appState, recordToEdit: r),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}