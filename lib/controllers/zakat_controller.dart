import 'package:flutter/material.dart';
import '../services/zakat_service.dart';

class ZakatController extends ChangeNotifier {
  bool isLoading = true;
  String? error;

  Map<String, dynamic> rates = {'IDR': 1.0};
  List<String> availableCurrencies = ['IDR'];

  String selectedCurrency = 'IDR';
  double totalHartaIdr = 0;
  double zakatIdr = 0;
  double convertedZakat = 0;

  void initialize() async {
    try {
      rates = await ZakatService.instance.getExchangeRates();
      availableCurrencies = rates.keys.toList();
      // Pindahkan mata uang populer ke atas
      _prioritizeCurrencies(['IDR', 'USD', 'EUR', 'SAR', 'MYR']);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _prioritizeCurrencies(List<String> priorities) {
    for (var curr in priorities.reversed) {
      if (availableCurrencies.contains(curr)) {
        availableCurrencies.remove(curr);
        availableCurrencies.insert(0, curr);
      }
    }
  }

  void calculateZakat(String inputAmount) {
    // Hilangkan karakter selain angka
    final cleanInput = inputAmount.replaceAll(RegExp(r'[^0-9]'), '');
    totalHartaIdr = double.tryParse(cleanInput) ?? 0;

    // Zakat Maal adalah 2.5%
    zakatIdr = totalHartaIdr * 0.025;
    _updateConvertedZakat();
    notifyListeners();
  }

  void setCurrency(String currency) {
    selectedCurrency = currency;
    _updateConvertedZakat();
    notifyListeners();
  }

  void _updateConvertedZakat() {
    double rate = (rates[selectedCurrency] as num?)?.toDouble() ?? 1.0;
    convertedZakat = zakatIdr * rate;
  }
}
