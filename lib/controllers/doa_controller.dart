import 'package:flutter/material.dart';

import '../models/doa.dart';
import '../services/doa_service.dart';

class DoaController extends ChangeNotifier {
  Future<List<DoaItem>>? _doaFuture;
  String query = '';

  Future<List<DoaItem>> get doaFuture {
    _doaFuture ??= DoaService.instance.getDoaList();
    return _doaFuture!;
  }

  void setQuery(String value) {
    query = value.trim().toLowerCase();
    notifyListeners();
  }

  List<DoaItem> filtered(List<DoaItem> allDoa) {
    if (query.isEmpty) return allDoa;
    return allDoa
        .where(
          (e) =>
              e.title.toLowerCase().contains(query) ||
              e.group.toLowerCase().contains(query) ||
              e.translation.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  Future<void> refresh() async {
    _doaFuture = DoaService.instance.getDoaList();
    notifyListeners();
    await _doaFuture;
  }
}
