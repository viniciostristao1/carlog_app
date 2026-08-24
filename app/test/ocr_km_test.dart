import 'package:carlog/services/ocr/ocr_km.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extração de km (odômetro). O caso-chave: "KM:" com muitos espaços antes do
/// número, e um número pequeno solto na mesma linha não pode "ganhar".
void main() {
  test('formatos básicos', () {
    expect(kmDaLinha('KM 10000'), 10000);
    expect(kmDaLinha('10.000 km'), 10000);
    expect(kmDaLinha('Odômetro: 87.532'), 87532);
    expect(kmDaLinha('Km/Horas: 166.710'), 166710);
    expect(kmDaLinha('Quilometragem 45231'), 45231);
  });

  test('KM com muitos espaços antes do número (bug do orçamento)', () {
    expect(kmDaLinha('KM:      120973'), 120973);
    expect(kmDaLinha('KM :   120.973'), 120973);
  });

  test('pega o número com MAIS dígitos na linha, não o primeiro', () {
    // Um "130" solto não pode ganhar do odômetro real "120973".
    expect(kmDaLinha('KM 130 ordem 120973'), 120973);
  });

  test('consumo "km/L" NÃO é odômetro', () {
    expect(kmDaLinha('Media 12 km/L'), isNull);
    expect(kmDaLinha('Consumo 9,8 km/l'), isNull);
  });

  test('linha sem rótulo de km → null', () {
    expect(kmDaLinha('Filtro de óleo 35,00'), isNull);
    expect(kmDaLinha('Total 124,90'), isNull);
  });
}
