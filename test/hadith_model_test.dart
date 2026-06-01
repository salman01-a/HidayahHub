import 'package:flutter_test/flutter_test.dart';
import 'package:hidayahhub/models/hadith.dart';

void main() {
  test('HadithBook parses API book response', () {
    final book = HadithBook.fromMap({
      'name': 'HR. Bukhari',
      'id': 'bukhari',
      'available': 6638,
    });

    expect(book.id, 'bukhari');
    expect(book.name, 'HR. Bukhari');
    expect(book.available, 6638);
  });

  test('HadithPage parses API page response', () {
    final page = HadithPage.fromMap({
      'name': 'HR. Muslim',
      'id': 'muslim',
      'available': 4930,
      'requested': 1,
      'hadiths': [
        {'number': 1, 'arab': 'نص عربي', 'id': 'Terjemahan Indonesia'},
      ],
    });

    expect(page.bookId, 'muslim');
    expect(page.hadiths, hasLength(1));
    expect(page.hadiths.first.number, 1);
    expect(page.hadiths.first.translation, 'Terjemahan Indonesia');
  });
}
