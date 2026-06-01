import 'package:flutter/material.dart';
import '../services/zakat_service.dart';

class ZakatController extends ChangeNotifier {
  static const double nisabGoldGrams = 85;
  static const double defaultGoldPricePerGramIdr = 1500000;

  bool isLoading = true;
  String? error;

  Map<String, dynamic> rates = {'IDR': 1.0};
  List<String> availableCurrencies = ['IDR'];

  String selectedCurrency = 'IDR';
  double goldPricePerGramIdr = defaultGoldPricePerGramIdr;
  double totalHartaIdr = 0;
  double nisabIdr = nisabGoldGrams * defaultGoldPricePerGramIdr;
  double zakatIdr = 0;
  double convertedZakat = 0;

  bool get hasReachedNisab =>
      goldPricePerGramIdr > 0 && totalHartaIdr >= nisabIdr;

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
    totalHartaIdr = _parseRupiahInput(inputAmount);
    _recalculateZakat();
    notifyListeners();
  }

  void setGoldPricePerGram(String inputAmount) {
    goldPricePerGramIdr = _parseRupiahInput(inputAmount);
    nisabIdr = nisabGoldGrams * goldPricePerGramIdr;
    _recalculateZakat();
    notifyListeners();
  }

  void setCurrency(String currency) {
    selectedCurrency = currency;
    _updateConvertedZakat();
    notifyListeners();
  }

  double _parseRupiahInput(String inputAmount) {
    final cleanInput = inputAmount.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(cleanInput) ?? 0;
  }

  void _recalculateZakat() {
    zakatIdr = hasReachedNisab ? totalHartaIdr * 0.025 : 0;
    _updateConvertedZakat();
  }

  void _updateConvertedZakat() {
    double rate = (rates[selectedCurrency] as num?)?.toDouble() ?? 1.0;
    convertedZakat = zakatIdr * rate;
  }
}
