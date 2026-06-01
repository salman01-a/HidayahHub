import 'package:flutter/material.dart';
import '../../controllers/zakat_controller.dart';

class ZakatView extends StatefulWidget {
  const ZakatView({super.key});

  @override
  State<ZakatView> createState() => _ZakatViewState();
}

class _ZakatViewState extends State<ZakatView> {
  late final ZakatController _controller;
  final TextEditingController _amountController = TextEditingController();
  late final TextEditingController _goldPriceController;

  static const Color _primaryTeal = Color(0xFF1A7F6D);
  static const Color _deepTeal = Color(0xFF0F5A4E);

  @override
  void initState() {
    super.initState();
    _controller = ZakatController();
    _goldPriceController = TextEditingController(
      text: _controller.goldPricePerGramIdr.toStringAsFixed(0),
    );
    _controller.addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _amountController.dispose();
    _goldPriceController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryTeal))
          : _controller.error != null
          ? Center(child: Text(_controller.error!))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                _buildInputSection(),
                const SizedBox(height: 24),
                _buildResultSection(),
                const SizedBox(height: 32),
                const SizedBox(height: 56),
              ],
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_deepTeal, _primaryTeal]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _deepTeal.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalkulator Zakat Maal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hitung kewajiban zakat hartamu (2,5%) setelah mencapai nisab 85 gram emas.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMoneyInput(
          label: 'Total Harta Keseluruhan (IDR)',
          controller: _amountController,
          onChanged: _controller.calculateZakat,
        ),
        const SizedBox(height: 16),
        _buildMoneyInput(
          label: 'Harga Emas per Gram (IDR)',
          controller: _goldPriceController,
          onChanged: _controller.setGoldPricePerGram,
        ),
      ],
    );
  }

  Widget _buildMoneyInput({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: _deepTeal,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.black87,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primaryTeal, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNisabStatus(),
          const Divider(height: 32),
          const Text(
            'Total Zakat yang Harus Dibayar',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatConvertedZakat(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _primaryTeal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _controller.selectedCurrency,
                    items: _controller.availableCurrencies
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) _controller.setCurrency(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Text(
            '1 IDR = ${_controller.rates[_controller.selectedCurrency]} ${_controller.selectedCurrency}',
            style: const TextStyle(
              color: Color(0xFFCBA052),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNisabStatus() {
    final hasReachedNisab = _controller.hasReachedNisab;
    final Color statusColor = hasReachedNisab
        ? _primaryTeal
        : const Color(0xFFCBA052);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasReachedNisab ? Icons.check_circle_outline : Icons.info_outline,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasReachedNisab
                      ? 'Sudah mencapai nisab'
                      : 'Belum mencapai nisab',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nisab: ${_formatIdr(_controller.nisabIdr)} (${ZakatController.nisabGoldGrams.toStringAsFixed(0)} gram emas)',
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatConvertedZakat() {
    if (_controller.selectedCurrency == 'IDR') {
      return _formatIdr(_controller.convertedZakat);
    }
    return _controller.convertedZakat.toStringAsFixed(2);
  }

  String _formatIdr(double value) {
    final text = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final remainingDigits = text.length - i;
      buffer.write(text[i]);
      if (remainingDigits > 1 && remainingDigits % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp $buffer';
  }
}
