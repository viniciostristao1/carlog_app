import 'package:carlog/features/fipe/fipe_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('codigosDaTabela (triênio salvo no veículo)', () {
    test('quebra marca/modelo/ano nos 3 códigos', () {
      expect(codigosDaTabela('59/5940/2014-1'), ['59', '5940', '2014-1']);
    });

    test('ignora espaços nas pontas de cada código', () {
      expect(codigosDaTabela(' 59 / 5940 / 2014-1 '), ['59', '5940', '2014-1']);
    });

    test('null ou vazio não tem códigos', () {
      expect(codigosDaTabela(null), isNull);
      expect(codigosDaTabela(''), isNull);
    });

    test('formato errado (faltando ou sobrando parte) devolve null', () {
      expect(codigosDaTabela('59/5940'), isNull);
      expect(codigosDaTabela('59//2014-1'), isNull);
      expect(codigosDaTabela('59/5940/2014-1/extra'), isNull);
    });
  });
}
