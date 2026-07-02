import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../widgets/add_expense_sheet.dart';

class ElectricView extends StatelessWidget {
  final AppState appState;
  const ElectricView({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico Ricariche', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, child) {
          // Filtriamo solo i record di tipo ricarica
          final records = appState.records.where((r) => r['category'] == 'ricarica').toList();

          if (records.isEmpty) {
            return const Center(
              child: Text('Nessuna ricarica registrata.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              final isDomestica = r['type'] == 'Domestica' || r['type'] == null;
              final color = isDomestica ? Colors.green : Colors.blue;
              final icon = isDomestica ? Icons.home : Icons.ev_station;
              final provider = isDomestica ? 'Casa' : (r['provider'] ?? 'Sconosciuto');

              final date = r['date'] as DateTime;
              final kwh = (r['kwh'] as num?)?.toDouble() ?? 0.0;
              final cost = (r['totalCost'] as num?)?.toDouble() ?? 0.0;

              return Dismissible(
                key: Key(r['id']),
                direction: DismissDirection.horizontal,
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    // Modifica
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                      builder: (ctx) => AddExpenseSheet(appState: appState, recordToEdit: r),
                    );
                    return false;
                  } else {
                    // Elimina
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Conferma eliminazione'),
                        content: const Text('Vuoi davvero eliminare questo record?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULLA')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('ELIMINA', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      appState.deleteRecord(r);
                      return true;
                    }
                    return false;
                  }
                },
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(provider, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(
                        '${DateFormat('dd MMM yyyy', 'it_IT').format(date)}\n${kwh.toStringAsFixed(1)} kWh',
                        style: const TextStyle(height: 1.4)
                    ),
                    trailing: Text('€ ${cost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    onTap: () {
                      // Cliccando sulla card, riutilizziamo il foglio di inserimento passandogli il record per la modifica
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
                        builder: (ctx) => AddExpenseSheet(appState: appState, recordToEdit: r),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}