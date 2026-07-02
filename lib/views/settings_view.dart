import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import '../state/app_state.dart';

class SettingsView extends StatefulWidget {
  final AppState appState;

  const SettingsView({super.key, required this.appState});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _homePriceCtrl = TextEditingController(text: '0.40');

  // Dialog per aggiungere o modificare un gestore pubblico
  void _showProviderDialog({Map<String, dynamic>? provider}) {
    final isEditing = provider != null;
    final nameCtrl = TextEditingController(text: isEditing ? provider['name'] : '');
    final priceCtrl = TextEditingController(text: isEditing ? (provider['defaultPrice'] as num).toStringAsFixed(2) : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isEditing ? 'Modifica Tariffa' : 'Nuovo Gestore', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              enabled: !isEditing, // Non cambia il nome se si sta solo modificando la tariffa
              decoration: InputDecoration(
                labelText: 'Nome Gestore',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tariffa predefinita (€/kWh)',
                prefixText: '€ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULLA')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text.replaceAll(',', '.')) ?? 0.0;
              if (name.isEmpty || price <= 0) return;

              if (isEditing) {
                widget.appState.updateProviderPrice(name, price);
              } else {
                widget.appState.addProvider(name, price);
              }
              Navigator.pop(ctx);
            },
            child: const Text('SALVA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opzioni', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. TARIFFE DI DEFAULT
          _buildSectionTitle('Tariffe e Consumi'),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.home, color: Colors.green),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ricarica Domestica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Prezzo predefinito al kWh', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _homePriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixText: '€ ',
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. GESTORI PUBBLICI (Con aggiunta e modifica)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionTitle('Gestori Ricarica Pubblica'),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                onPressed: () => _showProviderDialog(),
              )
            ],
          ),
          ListenableBuilder(
            listenable: widget.appState,
            builder: (context, child) {
              final providers = widget.appState.providers;
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: providers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final p = providers[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 20, right: 8, top: 4, bottom: 4),
                      leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          child: const Icon(Icons.ev_station, color: Colors.blue, size: 20)
                      ),
                      title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('€ ${(p['defaultPrice'] ?? 0.0).toStringAsFixed(2)}/kWh', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showProviderDialog(provider: p),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // 3. VERSIONE
          Center(
            child: Text(
              'Caddy Log v2.5',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey),
      ),
    );
  }
}

extension on ColorScheme {
  Color get surfaceContainerHighest => onInverseSurface;
}
