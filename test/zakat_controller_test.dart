import 'package:flutter_test/flutter_test.dart';
import 'package:hidayahhub/controllers/zakat_controller.dart';

void main() {
  test('zakat bernilai nol saat harta belum mencapai nisab', () {
    final controller = ZakatController();

    controller.setGoldPricePerGram('1000000');
    controller.calculateZakat('84999999');

    expect(controller.nisabIdr, 85000000);
    expect(controller.hasReachedNisab, isFalse);
    expect(controller.zakatIdr, 0);
  });

  test('zakat dihitung 2,5 persen saat harta mencapai nisab', () {
    final controller = ZakatController();

    controller.setGoldPricePerGram('1000000');
    controller.calculateZakat('100000000');

    expect(controller.hasReachedNisab, isTrue);
    expect(controller.zakatIdr, 2500000);
  });
}
