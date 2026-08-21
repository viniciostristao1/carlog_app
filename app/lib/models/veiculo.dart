/// Combustível principal do veículo.
enum Combustivel { flex, gasolina, etanol, diesel, gnv }

extension CombustivelX on Combustivel {
  String get rotulo => switch (this) {
        Combustivel.flex => 'Flex',
        Combustivel.gasolina => 'Gasolina',
        Combustivel.etanol => 'Etanol',
        Combustivel.diesel => 'Diesel',
        Combustivel.gnv => 'GNV',
      };
}

/// O veículo do usuário (o app é single-car por ora; multi-veículo é ideia futura).
/// Guarda também os parâmetros que outras telas usam: pressão recomendada dos
/// pneus (Calibragem), intervalo de revisão (estimativa da próxima) e o vínculo
/// com a FIPE (código + último valor consultado).
class Veiculo {
  final String id;
  final String apelido; // "Meu Onix", "Corolla da família"
  final String marca;
  final String modelo;
  final int? ano;
  final String placa;
  final Combustivel combustivel;
  final double? tanqueLitros;

  // Calibragem recomendada (psi). A data da última calibragem vive no store próprio.
  final double? pressaoDianteira;
  final double? pressaoTraseira;

  // Revisão: intervalo para estimar a próxima (o que for atingido primeiro).
  final int revisaoIntervaloKm; // ex.: 10000
  final int revisaoIntervaloMeses; // ex.: 12

  // FIPE (preenchido pela tela "Minha FIPE").
  final String? fipeCodigo; // código FIPE do modelo
  final String? fipeCodigoTabela; // triênio marca/modelo/ano p/ reconsulta
  final double? fipeValor; // último valor consultado (R$)
  final String? fipeMesRef; // mês de referência do valor
  final DateTime? fipeConsultadoEm;

  const Veiculo({
    required this.id,
    required this.apelido,
    this.marca = '',
    this.modelo = '',
    this.ano,
    this.placa = '',
    this.combustivel = Combustivel.flex,
    this.tanqueLitros,
    this.pressaoDianteira,
    this.pressaoTraseira,
    this.revisaoIntervaloKm = 10000,
    this.revisaoIntervaloMeses = 12,
    this.fipeCodigo,
    this.fipeCodigoTabela,
    this.fipeValor,
    this.fipeMesRef,
    this.fipeConsultadoEm,
  });

  Veiculo copyWith({
    String? apelido,
    String? marca,
    String? modelo,
    int? ano,
    String? placa,
    Combustivel? combustivel,
    double? tanqueLitros,
    double? pressaoDianteira,
    double? pressaoTraseira,
    int? revisaoIntervaloKm,
    int? revisaoIntervaloMeses,
    String? fipeCodigo,
    String? fipeCodigoTabela,
    double? fipeValor,
    String? fipeMesRef,
    DateTime? fipeConsultadoEm,
  }) {
    return Veiculo(
      id: id,
      apelido: apelido ?? this.apelido,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      ano: ano ?? this.ano,
      placa: placa ?? this.placa,
      combustivel: combustivel ?? this.combustivel,
      tanqueLitros: tanqueLitros ?? this.tanqueLitros,
      pressaoDianteira: pressaoDianteira ?? this.pressaoDianteira,
      pressaoTraseira: pressaoTraseira ?? this.pressaoTraseira,
      revisaoIntervaloKm: revisaoIntervaloKm ?? this.revisaoIntervaloKm,
      revisaoIntervaloMeses: revisaoIntervaloMeses ?? this.revisaoIntervaloMeses,
      fipeCodigo: fipeCodigo ?? this.fipeCodigo,
      fipeCodigoTabela: fipeCodigoTabela ?? this.fipeCodigoTabela,
      fipeValor: fipeValor ?? this.fipeValor,
      fipeMesRef: fipeMesRef ?? this.fipeMesRef,
      fipeConsultadoEm: fipeConsultadoEm ?? this.fipeConsultadoEm,
    );
  }

  String get titulo {
    if (apelido.trim().isNotEmpty) return apelido.trim();
    final mm = [marca, modelo].where((s) => s.trim().isNotEmpty).join(' ');
    return mm.isNotEmpty ? mm : 'Meu carro';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'apelido': apelido,
        'marca': marca,
        'modelo': modelo,
        'ano': ano,
        'placa': placa,
        'combustivel': combustivel.name,
        'tanqueLitros': tanqueLitros,
        'pressaoDianteira': pressaoDianteira,
        'pressaoTraseira': pressaoTraseira,
        'revisaoIntervaloKm': revisaoIntervaloKm,
        'revisaoIntervaloMeses': revisaoIntervaloMeses,
        'fipeCodigo': fipeCodigo,
        'fipeCodigoTabela': fipeCodigoTabela,
        'fipeValor': fipeValor,
        'fipeMesRef': fipeMesRef,
        'fipeConsultadoEm': fipeConsultadoEm?.toIso8601String(),
      };

  factory Veiculo.fromJson(Map<String, dynamic> j) => Veiculo(
        id: j['id'] as String,
        apelido: (j['apelido'] ?? '') as String,
        marca: (j['marca'] ?? '') as String,
        modelo: (j['modelo'] ?? '') as String,
        ano: (j['ano'] as num?)?.toInt(),
        placa: (j['placa'] ?? '') as String,
        combustivel: Combustivel.values.firstWhere(
          (c) => c.name == j['combustivel'],
          orElse: () => Combustivel.flex,
        ),
        tanqueLitros: (j['tanqueLitros'] as num?)?.toDouble(),
        pressaoDianteira: (j['pressaoDianteira'] as num?)?.toDouble(),
        pressaoTraseira: (j['pressaoTraseira'] as num?)?.toDouble(),
        revisaoIntervaloKm: (j['revisaoIntervaloKm'] as num?)?.toInt() ?? 10000,
        revisaoIntervaloMeses:
            (j['revisaoIntervaloMeses'] as num?)?.toInt() ?? 12,
        fipeCodigo: j['fipeCodigo'] as String?,
        fipeCodigoTabela: j['fipeCodigoTabela'] as String?,
        fipeValor: (j['fipeValor'] as num?)?.toDouble(),
        fipeMesRef: j['fipeMesRef'] as String?,
        fipeConsultadoEm: j['fipeConsultadoEm'] == null
            ? null
            : DateTime.tryParse(j['fipeConsultadoEm'] as String),
      );
}
