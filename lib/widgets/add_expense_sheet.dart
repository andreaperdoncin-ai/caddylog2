import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/app_state.dart';

enum AddStep { menu, form }
enum ActionType { casa, pubblica, benzina, spese }

class AddExpenseSheet extends StatefulWidget {
  final AppState appState;
  final Map<String, dynamic>? recordToEdit;

  const AddExpenseSheet({
    super.key,
    required this.appState,
    this.recordToEdit,
  });

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  AddStep _currentStep = AddStep.menu;
  ActionType? _selectedAction;

  DateTime _selectedDate = DateTime.now();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime(DateTime.now().year + 1, DateTime.now().month, DateTime.now().day);

  // Controller Elettrico
  final _kwhCtrl = TextEditingController();
  final _kwPriceCtrl = TextEditingController(text: '0.40');
  String? _selectedProvider;

  // Controller Benzina
  final _fuelTotalCostCtrl = TextEditingController();
  final _literPriceCtrl = TextEditingController(text: '1.80');

  // Controller Spese
  final _totalCostCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _selectedExpenseCategory;

  @override
  void initState() {
    super.initState();

    if (widget.appState.providers.isNotEmpty) {
      _selectedProvider = widget.appState.providers.first['name'] as String;
    }
    
    // Priorità ad Autostrada
    _selectedExpenseCategory = 'Autostrada';

    // Se siamo in modifica, saltiamo il menu e andiamo dritti al form
    if (widget.recordToEdit != null) {
      _currentStep = AddStep.form;
      final r = widget.recordToEdit!;
      _selectedDate = r['date'] ?? DateTime.now();

      if (r['category'] == 'ricarica') {
        if (r['type'] == 'Domestica') {
          _selectedAction = ActionType.casa;
        } else {
          _selectedAction = ActionType.pubblica;
          _selectedProvider = r['provider'] as String?;
        }
        _kwhCtrl.text = r['kwh'].toString();
        _kwPriceCtrl.text = (r['totalCost'] / r['kwh']).toStringAsFixed(2);
      } else if (r['category'] == 'carburante') {
        _selectedAction = ActionType.benzina;
        _fuelTotalCostCtrl.text = r['totalCost'].toStringAsFixed(2);
        _literPriceCtrl.text = (r['totalCost'] / (r['liters'] ?? 1)).toStringAsFixed(2);
      } else {
        _selectedAction = ActionType.spese;
        _selectedExpenseCategory = r['category'] as String?;
        _totalCostCtrl.text = r['totalCost'].toString();
        _notesCtrl.text = r['notes'] ?? '';
        if (r['startDate'] != null) _startDate = DateTime.parse(r['startDate']);
        if (r['endDate'] != null) _endDate = DateTime.parse(r['endDate']);
      }
    } else {
      // Setup default dates for new "Altre Spese"
      _startDate = widget.appState.carPurchaseDate;
      _endDate = DateTime.now();
    }
  }

  void _saveRecord() {
    Map<String, dynamic> record = {'date': _selectedDate};

    try {
      if (_selectedAction == ActionType.casa || _selectedAction == ActionType.pubblica) {
        double kwh = double.tryParse(_kwhCtrl.text.replaceAll(',', '.')) ?? 0;
        double price = double.tryParse(_kwPriceCtrl.text.replaceAll(',', '.')) ?? 0;
        if (kwh <= 0) return;

        record['category'] = 'ricarica';
        record['kwh'] = kwh;
        record['totalCost'] = kwh * price;

        if (_selectedAction == ActionType.casa) {
          record['type'] = 'Domestica';
          record['provider'] = 'Casa';
        } else {
          record['type'] = 'Pubblica';
          record['provider'] = _selectedProvider;
        }

      } else if (_selectedAction == ActionType.benzina) {
        double total = double.tryParse(_fuelTotalCostCtrl.text.replaceAll(',', '.')) ?? 0;
        double price = double.tryParse(_literPriceCtrl.text.replaceAll(',', '.')) ?? 0;
        if (total <= 0 || price <= 0) return;

        record['category'] = 'carburante';
        record['totalCost'] = total;
        record['liters'] = total / price;

      } else if (_selectedAction == ActionType.spese) {
        double total = double.tryParse(_totalCostCtrl.text.replaceAll(',', '.')) ?? 0;
        if (total <= 0) return;

        record['category'] = _selectedExpenseCategory ?? 'Altro';
        record['totalCost'] = total;
        record['notes'] = _notesCtrl.text;

        final selectedCatMap = widget.appState.expenseCategories.firstWhere(
                (c) => c['name'] == _selectedExpenseCategory,
            orElse: () => {'name': '', 'type': 'puntuale'}
        );
        final catType = selectedCatMap['type'] ?? 'puntuale';

        if (catType == 'annuale') {
          record['startDate'] = _startDate.toIso8601String();
          record['endDate'] = _endDate.toIso8601String();
          record['date'] = _startDate;
        } else if (catType == 'mensile') {
          record['date'] = DateTime(_selectedDate.year, _selectedDate.month, 1);
        } else if (catType == 'intervallo') {
          record['startDate'] = _startDate.toIso8601String();
          record['endDate'] = _endDate.toIso8601String();
          record['date'] = _endDate;
        }
      }

      if (widget.recordToEdit != null) {
        widget.appState.updateRecord(widget.recordToEdit!, record);
      } else {
        widget.appState.addRecord(record);
      }
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Errore salvataggio: $e');
    }
  }

  Widget _buildMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cosa vuoi aggiungere?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildMenuCard('Ricarica\nCasa', Icons.home, Colors.green, ActionType.casa),
            _buildMenuCard('Ricarica\nPubblica', Icons.ev_station, Colors.blue, ActionType.pubblica),
            _buildMenuCard('Rifornimento\nBenzina', Icons.local_gas_station, Colors.orange, ActionType.benzina),
            _buildMenuCard('Altre\nSpese', Icons.receipt_long, Colors.purple, ActionType.spese),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuCard(String title, IconData icon, MaterialColor color, ActionType action) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAction = action;
          _currentStep = AddStep.form;
          // Imposta i prezzi di default in base all'azione
          if (action == ActionType.casa) {
            _kwPriceCtrl.text = "0.40";
          } else if (action == ActionType.pubblica) {
            final prov = widget.appState.providers.firstWhere(
                (p) => p['name'] == _selectedProvider,
                orElse: () => {'defaultPrice': 0.0});
            if (prov['defaultPrice'] > 0) {
              _kwPriceCtrl.text = prov['defaultPrice'].toStringAsFixed(2);
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: color.shade100.withOpacity(0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.shade200, width: 2),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color.shade700),
            const Spacer(),
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color.shade900, height: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    String title = '';
    Widget formFields = const SizedBox();

    switch (_selectedAction) {
      case ActionType.casa:
        title = 'Ricarica Casa';
        formFields = Column(
          children: [
            _buildNumberField('kWh Erogati', _kwhCtrl, autofocus: true),
            const SizedBox(height: 16),
            _buildNumberField('Costo Stimato (€/kWh)', _kwPriceCtrl),
          ],
        );
        break;
      case ActionType.pubblica:
        title = 'Ricarica Pubblica';
        final providers = widget.appState.providers.map((p) => p['name'] as String).toList();
        formFields = Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              decoration: InputDecoration(labelText: 'Gestore', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              items: providers.map((p) => DropdownMenuItem<String>(value: p, child: Text(p, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedProvider = val;
                  final prov = widget.appState.providers.firstWhere((p) => p['name'] == val, orElse: () => {'defaultPrice': 0.0});
                  if (prov['defaultPrice'] > 0) _kwPriceCtrl.text = prov['defaultPrice'].toStringAsFixed(2);
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildNumberField('kWh', _kwhCtrl, autofocus: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField('€/kWh', _kwPriceCtrl)),
              ],
            ),
          ],
        );
        break;
      case ActionType.benzina:
        title = 'Rifornimento';
        formFields = Row(
          children: [
            Expanded(child: _buildNumberField('Totale (€)', _fuelTotalCostCtrl, autofocus: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildNumberField('€/Litro', _literPriceCtrl)),
          ],
        );
        break;
      case ActionType.spese:
        title = 'Altre Spese';
        final selectedCatMap = widget.appState.expenseCategories.firstWhere(
                (c) => c['name'] == _selectedExpenseCategory,
            orElse: () => {'name': '', 'type': 'puntuale'}
        );
        final catType = selectedCatMap['type'] ?? 'puntuale';

        formFields = Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedExpenseCategory,
              decoration: InputDecoration(labelText: 'Categoria', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              items: widget.appState.expenseCategories.map((c) => DropdownMenuItem<String>(
                  value: c['name'] as String, child: Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
              onChanged: (val) => setState(() {
                _selectedExpenseCategory = val;
                if (val == 'Assicurazione' || val == 'Bollo') {
                  _endDate = DateTime(_startDate.year + 1, _startDate.month, _startDate.day - 1);
                } else if (val == 'Tagliando') {
                  _startDate = widget.appState.carPurchaseDate;
                  _endDate = DateTime.now();
                }
              }),
            ),
            const SizedBox(height: 16),
            _buildNumberField('Costo Totale (€)', _totalCostCtrl, autofocus: true),
            const SizedBox(height: 16),
            if (catType == 'mensile')
              _buildMonthSelector()
            else if (catType == 'annuale')
              _buildAnnualSelector()
            else if (catType == 'intervallo')
              _buildIntervalSelector()
            else
              _buildDateSelector(),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: 'Note (Opzionale)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
            ),
          ],
        );
        break;
      default:
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.recordToEdit == null) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _currentStep = AddStep.menu),
              ),
              const SizedBox(width: 16),
            ],
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 24),
        formFields,
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saveRecord,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(widget.recordToEdit == null ? 'SALVA' : 'AGGIORNA', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, {bool autofocus = false}) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      decoration: InputDecoration(labelText: label, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
    );
  }

  Widget _buildDateSelector() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime.now(), locale: const Locale("it", "IT"));
        if (d != null) setState(() => _selectedDate = d);
      },
    );
  }

  Widget _buildMonthSelector() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Competenza Mese: ${DateFormat('MMMM yyyy', 'it_IT').format(_selectedDate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          locale: const Locale("it", "IT"),
          initialDatePickerMode: DatePickerMode.year,
        );
        if (d != null) setState(() => _selectedDate = DateTime(d.year, d.month, 1));
      },
    );
  }

  Widget _buildAnnualSelector() {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Inizio Validità: ${DateFormat('dd/MM/yyyy').format(_startDate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          subtitle: Text('Fine (auto): ${DateFormat('dd/MM/yyyy').format(_endDate)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime(2030), locale: const Locale("it", "IT"));
            if (d != null) {
              setState(() {
                _startDate = d;
                _endDate = DateTime(d.year + 1, d.month, d.day - 1);
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildIntervalSelector() {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Data Acquisto/Prec.: ${DateFormat('dd/MM/yyyy').format(_startDate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.history),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2020), lastDate: DateTime.now(), locale: const Locale("it", "IT"));
            if (d != null) setState(() => _startDate = d);
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Data Tagliando: ${DateFormat('dd/MM/yyyy').format(_endDate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.build),
          onTap: () async {
            final d = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2020), lastDate: DateTime.now(), locale: const Locale("it", "IT"));
            if (d != null) setState(() => _endDate = d);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 24, left: 24, right: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _currentStep == AddStep.menu ? _buildMenu() : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }
}