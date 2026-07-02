import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppState extends ChangeNotifier {
  List<Map<String, dynamic>> records = [];

  List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Autostrada', 'type': 'mensile'},
    {'name': 'Assicurazione', 'type': 'annuale'},
    {'name': 'Bollo', 'type': 'annuale'},
    {'name': 'Tagliando', 'type': 'intervallo'},
  ];

  List<Map<String, dynamic>> providers = [
    {'name': 'Plenitude', 'defaultPrice': 0.64},
    {'name': 'Enel X', 'defaultPrice': 0.67},
    {'name': 'ASM', 'defaultPrice': 0.45},
    {'name': 'Altri', 'defaultPrice': 0.50},
  ];

  DateTime carPurchaseDate = DateTime(2025, 7, 1);

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppState() {
    _listenToRecords();
    _listenToSettings();
  }

  // --- LETTURA REAL-TIME ---

  void _listenToRecords() {
    _db.collection('caddy_records').snapshots().listen((snapshot) {
      records = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        if (data['date'] is Timestamp) {
          data['date'] = (data['date'] as Timestamp).toDate();
        }
        return data;
      }).toList();

      records.sort((a, b) => b['date'].compareTo(a['date']));
      notifyListeners();
    });
  }

  void _listenToSettings() {
    _db.collection('caddy_settings').doc('config').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        if (data.containsKey('expenseCategories')) {
          expenseCategories = List<Map<String, dynamic>>.from(data['expenseCategories']);
        }
        if (data.containsKey('providers')) {
          providers = List<Map<String, dynamic>>.from(data['providers']);
        }
        if (data.containsKey('carPurchaseDate') && data['carPurchaseDate'] is Timestamp) {
          carPurchaseDate = (data['carPurchaseDate'] as Timestamp).toDate();
        }
        notifyListeners();
      } else {
        _saveSettingsToFirebase();
      }
    });
  }

  // --- SALVATAGGIO IMPOSTAZIONI ---

  Future<void> _saveSettingsToFirebase() async {
    await _db.collection('caddy_settings').doc('config').set({
      'expenseCategories': expenseCategories,
      'providers': providers,
      'carPurchaseDate': Timestamp.fromDate(carPurchaseDate),
    });
  }

  // --- OPERAZIONI SUI RECORD (CRUD) ---

  void addRecord(Map<String, dynamic> record) async {
    final dataToSave = Map<String, dynamic>.from(record);
    if (dataToSave['date'] is DateTime) {
      dataToSave['date'] = Timestamp.fromDate(dataToSave['date']);
    }
    await _db.collection('caddy_records').add(dataToSave);
  }

  void updateRecord(Map<String, dynamic> oldRecord, Map<String, dynamic> newRecord) async {
    final docId = oldRecord['id'];
    if (docId != null) {
      final dataToSave = Map<String, dynamic>.from(newRecord);
      if (dataToSave['date'] is DateTime) {
        dataToSave['date'] = Timestamp.fromDate(dataToSave['date']);
      }
      dataToSave.remove('id');
      await _db.collection('caddy_records').doc(docId).update(dataToSave);
    }
  }

  void deleteRecord(Map<String, dynamic> record) async {
    final docId = record['id'];
    if (docId != null) {
      await _db.collection('caddy_records').doc(docId).delete();
    }
  }

  // --- GESTIONE CATEGORIE E GESTORI ---

  void updateExpenseCategory(String oldName, String newName, String newType) async {
    final index = expenseCategories.indexWhere((c) => c['name'] == oldName);
    if (index != -1) {
      expenseCategories[index] = {'name': newName, 'type': newType};
      await _saveSettingsToFirebase();

      // Aggiorna a cascata il nome della categoria nei record vecchi
      final batch = _db.batch();
      for (var r in records) {
        if (r['category'] == oldName) {
          final docRef = _db.collection('caddy_records').doc(r['id']);
          batch.update(docRef, {'category': newName});
        }
      }
      await batch.commit();
    }
  }

  void addExpenseCategory(String name, String type) async {
    if (!expenseCategories.any((c) => c['name'] == name) && name.isNotEmpty) {
      expenseCategories.add({'name': name, 'type': type});
      await _saveSettingsToFirebase();
    }
  }

  void addProvider(String name, double defaultPrice) async {
    if (!providers.any((p) => p['name'] == name) && name.isNotEmpty) {
      providers.add({'name': name, 'defaultPrice': defaultPrice});
      await _saveSettingsToFirebase();
    }
  }

  // --- IMPORTAZIONE STORICO ---

  Future<bool> importBackupFromJson(String jsonString) async {
    try {
      final List<dynamic> decodedData = jsonDecode(jsonString);

      // Scrive tutti i dati in blocco (batch) per massima efficienza
      final batch = _db.batch();

      for (var item in decodedData) {
        final docRef = _db.collection('caddy_records').doc();
        final data = Map<String, dynamic>.from(item);

        if (data['date'] is String) {
          data['date'] = Timestamp.fromDate(DateTime.parse(data['date']));
        }

        data.remove('id');
        batch.set(docRef, data);
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Errore importazione: $e');
      return false;
    }
  }
  // Aggiorna la tariffa di un gestore esistente
  void updateProviderPrice(String name, double price) {
    final index = providers.indexWhere((p) => p['name'] == name);
    if (index >= 0) {
      providers[index]['defaultPrice'] = price;
      notifyListeners();

      // TODO: Aggiorna su Firebase
    }
  }
}