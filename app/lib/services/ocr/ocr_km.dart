/// Extração de quilometragem (odômetro) de uma linha do orçamento.
///
/// Regra: uma leitura de odômetro é o **maior número** associado a um rótulo de
/// km — carro rodado tem 5–6 dígitos. Por isso, numa linha com rótulo, pegamos
/// o número com **mais dígitos** (não o primeiro que aparecer): assim
/// "KM:      120973" devolve 120973 e não um "130" que estivesse solto na linha.
///
/// Casos cobertos (ver test/ocr_km_test.dart):
///   "KM 10000", "10.000 km", "Odômetro: 87.532", "Km/Horas: 166.710",
///   "KM:      120973" (muitos espaços), "Media 12 km/L" (consumo → NÃO é km).
library;

// Rótulo de km em qualquer lugar da linha.
final _labelKm = RegExp(
  r'\b(?:quilometragem|kilometragem|hod[oôó]metro|od[oôó]metro|km)\b',
  caseSensitive: false,
);

// "10.000 km" / "166710 km": número colado (antes) do "km".
final _numAntesDeKm = RegExp(
  r'(\d{1,3}(?:\.\d{3})+|\d{3,7})\s*km\b',
  caseSensitive: false,
);

// Um número: milhar com ponto ("166.710") OU dígitos corridos ("120973").
final _token = RegExp(r'\d{1,3}(?:\.\d{3})+|\d+');

/// Converte "166.710"/"120973" em int, aceitando só faixa plausível de odômetro
/// (≥ 100 evita "12 km/L"; ≤ 9.999.999 evita CNPJ/telefone gigante). Null se não.
int? _limpar(String? s) {
  if (s == null) return null;
  final n = int.tryParse(s.replaceAll('.', ''));
  return (n != null && n >= 100 && n <= 9999999) ? n : null;
}

/// Quilometragem detectada nesta linha, ou null se a linha não for de km.
int? kmDaLinha(String linha) {
  // 1) Forma "NNN km": o número vem colado no 'km' — sinal forte e direto.
  final suf = _limpar(_numAntesDeKm.firstMatch(linha)?.group(1));
  if (suf != null) return suf;

  // 2) Rótulo de km ("KM:", "Odômetro:", "Km/Horas:") → o número com MAIS
  //    dígitos DEPOIS do rótulo (robusto a espaços e a números pequenos soltos).
  final lab = _labelKm.firstMatch(linha);
  if (lab == null) return null;
  final resto = linha.substring(lab.end);

  int? melhor;
  var maisDigitos = 0;
  for (final m in _token.allMatches(resto)) {
    final bruto = m.group(0)!;
    final v = _limpar(bruto);
    if (v == null) continue;
    final digitos = bruto.replaceAll('.', '').length;
    if (digitos > maisDigitos) {
      maisDigitos = digitos;
      melhor = v;
    }
  }
  return melhor;
}
