import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../controllers/search_surah_controller.dart';
import '../../models/surah.dart';
import 'shared_widgets.dart';

class SearchSurahView extends StatefulWidget {
  const SearchSurahView({super.key});

  @override
  State<SearchSurahView> createState() => _SearchSurahViewState();
}

class _SearchSurahViewState extends State<SearchSurahView> {
  late final SearchSurahController _controller;
  final TextEditingController _searchController = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _controller = SearchSurahController();
    _controller.addListener(_onControllerChanged);
    _searchController.addListener(
      () => _controller.setQuery(_searchController.text),
    );
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.cancel();
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (!mounted) return;
    setState(() {});
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() => _isListening = false);
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() => _isListening = false);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable || _isListening) return;
    setState(() => _isListening = true);
    await _speech.listen(
      localeId: 'id_ID',
      listenMode: ListenMode.search,
      partialResults: true,
      cancelOnError: true,
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        _lastWords = words;
        _searchController.text = words;
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: words.length),
        );
      },
    );
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    await _speech.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: _speechAvailable
                    ? (_isListening
                        ? 'Berhenti mendengarkan'
                        : 'Cari dengan suara')
                    : 'Pengenalan suara tidak tersedia',
                onPressed:
                    _speechAvailable ? (_isListening ? _stopListening : _startListening) : null,
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? Colors.redAccent : null,
                ),
              ),
              hintText: 'Cari surah (nama latin/arab/arti/nomor)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        if (_lastWords.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Terakhir didengar: $_lastWords',
                style: const TextStyle(color: Color(0xFF6B7A8A), fontSize: 12),
              ),
            ),
          ),
        Expanded(
          child: FutureBuilder<List<Surah>>(
            future: _controller.surahFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ErrorPane(error: snapshot.error.toString());
              }

              final all = snapshot.data ?? const <Surah>[];
              final list = _controller.filtered(all);

              return RefreshIndicator(
                onRefresh: _controller.refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: list.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      SurahCard(surah: list[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
