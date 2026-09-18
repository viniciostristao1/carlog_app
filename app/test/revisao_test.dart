import 'package:carlog/models/revisao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Revisao.ehRevisao', () {
    test('padrão é revisão (conta para a próxima)', () {
      final r = Revisao(id: 'r', data: DateTime(2026, 1, 1), odometro: 1000);
      expect(r.ehRevisao, isTrue);
    });

    test('toJson/fromJson preservam reparo', () {
      final r = Revisao(
          id: 'r',
          data: DateTime(2026, 1, 1),
          odometro: 1000,
          ehRevisao: false);
      expect(Revisao.fromJson(r.toJson()).ehRevisao, isFalse);
    });

    test('fromJson antigo (sem o campo) conta como revisão', () {
      final r = Revisao.fromJson({
        'id': 'r',
        'data': DateTime(2026, 1, 1).toIso8601String(),
        'odometro': 1000,
      });
      expect(r.ehRevisao, isTrue);
    });
  });
}
