import 'package:flutter/material.dart';

import '../models/hadith.dart';
import '../services/hadith_service.dart';

class HadithController extends ChangeNotifier {
  static const int pageSize = 20;
  static const List<String> shahihBookIds = ['bukhari', 'muslim'];

  bool isLoading = true;
  bool isPageLoading = false;
  String? error;

  List<HadithBook> books = const [];
  HadithPage? currentPage;
  String selectedBookId = 'bukhari';
  int page = 1;
  String query = '';

  int get startNumber => ((page - 1) * pageSize) + 1;
  int get endNumber {
    final available = selectedBook?.available ?? currentPage?.available ?? 0;
    final rawEnd = page * pageSize;
    return available > 0 ? rawEnd.clamp(1, available) : rawEnd;
  }

  HadithBook? get selectedBook {
    for (final book in books) {
      if (book.id == selectedBookId) return book;
    }
    return null;
  }

  bool get canGoPrevious => page > 1;

  bool get canGoNext {
    final available = selectedBook?.available ?? currentPage?.available ?? 0;
    return available == 0 || endNumber < available;
  }

  List<Hadith> get filteredHadiths {
    final hadiths = currentPage?.hadiths ?? const <Hadith>[];
    final cleanQuery = query.trim().toLowerCase();

    if (cleanQuery.isEmpty) return hadiths;

    return hadiths
        .where(
          (hadith) =>
              hadith.number.toString().contains(cleanQuery) ||
              hadith.translation.toLowerCase().contains(cleanQuery),
        )
        .toList(growable: false);
  }

  Future<void> initialize() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final allBooks = await HadithService.instance.getBooks();
      books = allBooks
          .where((book) => shahihBookIds.contains(book.id))
          .toList(growable: false);

      if (books.isNotEmpty && !books.any((book) => book.id == selectedBookId)) {
        selectedBookId = books.first.id;
      }

      await _loadCurrentPage(notify: false);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await initialize();
  }

  Future<void> selectBook(String bookId) async {
    if (bookId == selectedBookId) return;
    selectedBookId = bookId;
    page = 1;
    query = '';
    currentPage = null;
    await _loadCurrentPage();
  }

  Future<void> nextPage() async {
    if (!canGoNext || isPageLoading) return;
    page++;
    query = '';
    currentPage = null;
    await _loadCurrentPage();
  }

  Future<void> previousPage() async {
    if (!canGoPrevious || isPageLoading) return;
    page--;
    query = '';
    currentPage = null;
    await _loadCurrentPage();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> _loadCurrentPage({bool notify = true}) async {
    try {
      isPageLoading = true;
      error = null;
      if (notify) notifyListeners();

      currentPage = await HadithService.instance.getHadiths(
        bookId: selectedBookId,
        start: startNumber,
        end: endNumber,
      );
    } catch (e) {
      error = e.toString();
    } finally {
      isPageLoading = false;
      if (notify) notifyListeners();
    }
  }
}
