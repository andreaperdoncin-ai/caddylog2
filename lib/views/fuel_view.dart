import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';
import '../widgets/add_expense_sheet.dart';

class FuelView extends StatelessWidget {
  final AppState appState;
  const FuelView({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico Benzina', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, child) {
          // Filtriamo solo i record carburante
          final records = appState.records.where((r) => r['category'] == 'carburante').toList();

          if (records.isEmpty) {
            return const Center(
              child: Text('Nessun rifornimento registrato.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              final date = r['date'] as DateTime;
              final cost = (r['totalCost'] as num?)?.toDouble() ?? 0.0;
              final liters = (r['liters'] as num?)?.toDouble() ?? 0.0;

              // Calcolo del prezzo al litro derivato
              final pricePerLiter = liters > 0 ? (cost / liters) : 0.0;

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
                    side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      child: const Icon(Icons.local_gas_station, color: Colors.orange),
                    ),
                    title: Text('${liters.toStringAsFixed(2)} Litri', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text(
                        '${DateFormat('dd MMM yyyy', 'it_IT').format(date)}\n€ ${pricePerLiter.toStringAsFixed(3)}/L',
                        style: const TextStyle(height: 1.4)
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}