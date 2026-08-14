import '../models/abastecimento.dart';
import '../models/revisao.dart';
import '../models/veiculo.dart';

/// Um trecho de consumo "tanque cheio → tanque cheio". A distância é a diferença
/// de odômetro entre dois abastecimentos completos; os litros são tudo que foi
/// abastecido no intervalo (inclui abastecimentos parciais no meio).
class TrechoConsumo {
  final DateTime dataInicio;
  final DateTime dataFim;
  final double distancia; // km
  final double litros;
  final double custo; // R$ gastos no intervalo

  const TrechoConsumo({
    required this.dataInicio,
    required this.dataFim,
    required this.distancia,
    required this.litros,
    required this.custo,
  });

  double get kmPorLitro => litros > 0 ? distancia / litros : 0;
  double get custoPorKm => distancia > 0 ? custo / distancia : 0;
}

/// Resultado consolidado do consumo a partir do histórico de abastecimentos.
class ResumoConsumo {
  final List<TrechoConsumo> trechos; // mais recente primeiro
  final double? mediaGeral; // km/L ponderada (distância/litros do total)
  final double? melhor; // melhor km/L de um trecho
  final double? pior; // pior km/L de um trecho
  final double totalLitros;
  final double totalGasto;

  const ResumoConsumo({
    required this.trechos,
    required this.mediaGeral,
    required this.melhor,
    required this.pior,
    required this.totalLitros,
    required this.totalGasto,
  });

  bool get temMedia => mediaGeral != null;
  static const vazio = ResumoConsumo(
    trechos: [],
    mediaGeral: null,
    melhor: null,
    pior: null,
    totalLitros: 0,
    totalGasto: 0,
  );
}

/// Calcula os trechos full-to-full. Só considera abastecimentos com **odômetro e
/// litros informados** (campos são opcionais). Precisa de ≥2 tanques cheios.
ResumoConsumo calcularConsumo(List<Abastecimento> abastecimentos) {
  final ordenados = abastecimentos
      .where((a) => a.odometro != null && a.litros != null)
      .toList()
    ..sort((a, b) => a.odometro!.compareTo(b.odometro!));

  final trechos = <TrechoConsumo>[];
  int? iAnteriorCheio;
  double litrosAcumulados = 0;
  double custoAcumulado = 0;

  for (var j = 0; j < ordenados.length; j++) {
    final atual = ordenados[j];
    if (iAnteriorCheio != null) {
      litrosAcumulados += atual.litros!;
      custoAcumulado += atual.total;
    }
    if (atual.tanqueCheio) {
      if (iAnteriorCheio != null) {
        final anterior = ordenados[iAnteriorCheio];
        final dist = atual.odometro! - anterior.odometro!;
        if (dist > 0 && litrosAcumulados > 0) {
          trechos.add(TrechoConsumo(
            dataInicio: anterior.data,
            dataFim: atual.data,
            distancia: dist,
            litros: litrosAcumulados,
            custo: custoAcumulado,
          ));
        }
      }
      iAnteriorCheio = j;
      litrosAcumulados = 0;
      custoAcumulado = 0;
    }
  }

  if (trechos.isEmpty) return ResumoConsumo.vazio;

  final distTotal = trechos.fold<double>(0, (s, t) => s + t.distancia);
  final litrosTotal = trechos.fold<double>(0, (s, t) => s + t.litros);
  final gastoTotal = trechos.fold<double>(0, (s, t) => s + t.custo);
  final kmls = trechos.map((t) => t.kmPorLitro).toList()..sort();

  trechos.sort((a, b) => b.dataFim.compareTo(a.dataFim)); // recente primeiro

  return ResumoConsumo(
    trechos: trechos,
    mediaGeral: litrosTotal > 0 ? distTotal / litrosTotal : null,
    melhor: kmls.last,
    pior: kmls.first,
    totalLitros: litrosTotal,
    totalGasto: gastoTotal,
  );
}

/// Km rodados num mês, a partir das leituras de odômetro dos abastecimentos.
/// Usa a última leitura antes do mês como base; senão a menor leitura do mês.
double kmRodadosNoMes(List<Abastecimento> abastecimentos, int ano, int mes) {
  final inicio = DateTime(ano, mes);
  final fim = DateTime(ano, mes + 1);
  final ordenados = abastecimentos.where((a) => a.odometro != null).toList()
    ..sort((a, b) => a.data.compareTo(b.data));

  double? base;
  double? maxNoMes;
  double? minNoMes;
  for (final a in ordenados) {
    final o = a.odometro!;
    if (a.data.isBefore(inicio)) {
      base = o;
    } else if (a.data.isBefore(fim)) {
      maxNoMes = (maxNoMes == null || o > maxNoMes) ? o : maxNoMes;
      minNoMes = (minNoMes == null || o < minNoMes) ? o : minNoMes;
    }
  }
  if (maxNoMes == null) return 0;
  final origem = base ?? minNoMes!;
  final km = maxNoMes - origem;
  return km > 0 ? km : 0;
}

/// Ritmo em **km/dia** pela janela dos últimos [dias] dias (fallback = tudo).
double? ritmoKmPorDia(List<Abastecimento> abastecimentos, {int dias = 90}) {
  final validos = abastecimentos.where((a) => a.odometro != null).toList()
    ..sort((a, b) => a.data.compareTo(b.data));
  if (validos.length < 2) return null;
  final corte = DateTime.now().subtract(Duration(days: dias));
  var janela = validos.where((a) => !a.data.isBefore(corte)).toList();
  if (janela.length < 2) janela = validos;
  final dist = janela.last.odometro! - janela.first.odometro!;
  final ndias = janela.last.data.difference(janela.first.data).inDays;
  if (dist <= 0 || ndias <= 0) return null;
  return dist / ndias;
}

/// Data provável para percorrer [faltamKm], dado um ritmo em km/dia.
DateTime? previsaoData(double faltamKm, double? kmPorDia) {
  if (kmPorDia == null || kmPorDia <= 0 || faltamKm <= 0) return null;
  final dias = (faltamKm / kmPorDia).ceil();
  return DateTime.now().add(Duration(days: dias));
}

/// Odômetro mais recente conhecido (maior leitura registrada).
double? ultimoOdometro(List<Abastecimento> abastecimentos) {
  final odos = abastecimentos
      .where((a) => a.odometro != null)
      .map((a) => a.odometro!);
  if (odos.isEmpty) return null;
  return odos.reduce((a, b) => a > b ? a : b);
}

// ─────────────────────────── Previsão de revisão ───────────────────────────

/// Previsão da próxima revisão, combinando abastecimentos + revisões.
class PrevisaoRevisao {
  final double? alvoKm; // odômetro estimado da próxima revisão
  final double? faltamKm; // alvoKm - odômetro atual (negativo = vencida)
  final DateTime? data; // data provável
  final double? mediaKmMes12; // média de km/mês nos últimos 12 meses

  const PrevisaoRevisao({
    this.alvoKm,
    this.faltamKm,
    this.data,
    this.mediaKmMes12,
  });

  bool get vencida => faltamKm != null && faltamKm! <= 0;
  static const vazio = PrevisaoRevisao();
}

/// Todas as leituras de odômetro (abastecimentos + revisões), por data.
List<(DateTime, double)> _leituras(
    List<Abastecimento> ab, List<Revisao> revs) {
  final r = <(DateTime, double)>[];
  for (final a in ab) {
    if (a.odometro != null) r.add((a.data, a.odometro!));
  }
  for (final v in revs) {
    if (v.odometro != null) r.add((v.data, v.odometro!));
  }
  r.sort((a, b) => a.$1.compareTo(b.$1));
  return r;
}

/// Estima a próxima revisão. **Km é o principal** (odômetro dos abastecimentos +
/// revisões dos últimos 12 meses); o intervalo de km sai do HISTÓRICO de revisões
/// (média dos espaçamentos) quando há ≥2, senão do cadastro do veículo. Se não dá
/// para prever por km, cai para o tempo (última revisão + intervalo de meses).
PrevisaoRevisao preverRevisao(
    Veiculo v, List<Abastecimento> abastecimentos, List<Revisao> revisoes) {
  final leituras = _leituras(abastecimentos, revisoes);
  if (leituras.isEmpty) return PrevisaoRevisao.vazio;

  double odoAtual = leituras.first.$2;
  for (final l in leituras) {
    if (l.$2 > odoAtual) odoAtual = l.$2;
  }

  // ritmo km/dia nos últimos 12 meses (fallback = todo o histórico)
  double? kmDia;
  if (leituras.length >= 2) {
    final corte = DateTime.now().subtract(const Duration(days: 365));
    var jan = leituras.where((l) => !l.$1.isBefore(corte)).toList();
    if (jan.length < 2) jan = leituras;
    final dist = jan.last.$2 - jan.first.$2;
    final dias = jan.last.$1.difference(jan.first.$1).inDays;
    if (dist > 0 && dias > 0) kmDia = dist / dias;
  }
  final media12 = kmDia != null ? kmDia * 30 : null;

  // intervalo de km: média dos espaçamentos entre revisões; senão o do veículo
  final revsOdo = revisoes.where((r) => r.odometro != null).toList()
    ..sort((a, b) => a.odometro!.compareTo(b.odometro!));
  double intervaloKm = v.revisaoIntervaloKm.toDouble();
  if (revsOdo.length >= 2) {
    final gaps = <double>[];
    for (var i = 1; i < revsOdo.length; i++) {
      final g = revsOdo[i].odometro! - revsOdo[i - 1].odometro!;
      if (g > 0) gaps.add(g);
    }
    if (gaps.isNotEmpty) {
      intervaloKm = gaps.reduce((a, b) => a + b) / gaps.length;
    }
  }

  final baseOdo = revsOdo.isNotEmpty ? revsOdo.last.odometro! : odoAtual;
  final alvoKm = baseOdo + intervaloKm;
  final faltamKm = alvoKm - odoAtual;

  DateTime? data;
  if (faltamKm > 0 && kmDia != null && kmDia > 0) {
    data = DateTime.now().add(Duration(days: (faltamKm / kmDia).ceil()));
  } else if (faltamKm > 0) {
    // fallback por tempo: última revisão + intervalo de meses (histórico/veículo)
    final revsData = [...revisoes]..sort((a, b) => a.data.compareTo(b.data));
    if (revsData.isNotEmpty) {
      int meses = v.revisaoIntervaloMeses;
      if (revsData.length >= 2) {
        final difs = <int>[];
        for (var i = 1; i < revsData.length; i++) {
          difs.add(revsData[i].data.difference(revsData[i - 1].data).inDays);
        }
        final mediaDias = difs.reduce((a, b) => a + b) / difs.length;
        if (mediaDias > 0) meses = (mediaDias / 30).round();
      }
      final ult = revsData.last.data;
      final d = DateTime(ult.year, ult.month + meses, ult.day);
      if (d.isAfter(DateTime.now())) data = d;
    }
  }

  return PrevisaoRevisao(
    alvoKm: alvoKm,
    faltamKm: faltamKm,
    data: data,
    mediaKmMes12: media12,
  );
}
