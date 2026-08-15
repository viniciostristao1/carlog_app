import '../models/lembrete.dart';
import '../models/media_manual.dart';
import '../models/veiculo.dart';

/// Idiomas do app.
enum Idioma { pt, en, es }

extension IdiomaX on Idioma {
  /// Nome do idioma no próprio idioma (para o seletor).
  String get nomeNativo => switch (this) {
        Idioma.pt => 'Português',
        Idioma.en => 'English',
        Idioma.es => 'Español',
      };

  /// Código de locale para formatação de data/número.
  String get localeData => switch (this) {
        Idioma.pt => 'pt_BR',
        Idioma.en => 'en_US',
        Idioma.es => 'es_ES',
      };
}

/// Textos do app em Português, Inglês e Espanhol. Fonte única de tudo que é
/// "nativo" do app (não depende do usuário). Trocar o idioma = trocar a
/// instância via `stringsProvider` (ver prefs.dart).
///
/// Convenção: getters para textos fixos; métodos para os que têm valor no meio.
class AppStrings {
  const AppStrings(this.idioma);

  final Idioma idioma;

  String _s(String pt, String en, String es) => switch (idioma) {
        Idioma.pt => pt,
        Idioma.en => en,
        Idioma.es => es,
      };

  // ───────────────────────────── genéricos ─────────────────────────────
  String get salvar => _s('Salvar', 'Save', 'Guardar');
  String get cancelar => _s('Cancelar', 'Cancel', 'Cancelar');
  String get excluir => _s('Excluir', 'Delete', 'Eliminar');
  String get alterar => _s('alterar', 'change', 'cambiar');
  String get limpar => _s('Limpar', 'Clear', 'Limpiar');
  String get nadaEncontrado =>
      _s('Nada encontrado.', 'Nothing found.', 'Nada encontrado.');
  String nadaEncontradoPara(String termo) => _s(
      'Nada encontrado para "$termo".',
      'Nothing found for "$termo".',
      'Nada encontrado para "$termo".');
  String get carregando => _s('Carregando…', 'Loading…', 'Cargando…');

  // ───────────────────────────── home ─────────────────────────────
  String get oQueRegistrar => _s('O que você quer registrar?',
      'What do you want to log?', '¿Qué quieres registrar?');
  String get cadastrarMeuCarro =>
      _s('Cadastrar meu carro', 'Add my car', 'Registrar mi auto');
  String get busquePelaFipe => _s(
      'Busque pela tabela FIPE (marca, modelo, ano)',
      'Look it up by make, model and year',
      'Búscalo por marca, modelo y año');
  String get adicionarCarro =>
      _s('Adicionar carro', 'Add car', 'Agregar auto');

  // botões redondos (home)
  String get catAbastecimento =>
      _s('Abastecimento', 'Fill-up', 'Carga');
  String get catConsumo => _s('Consumo / Média', 'Fuel economy', 'Consumo');
  String get catRevisoes => _s('Revisões', 'Service', 'Revisiones');
  String get catFipe => _s('Minha FIPE', 'My value', 'Mi valor');
  String get catCalibragem =>
      _s('Calibragem', 'Tire pressure', 'Presión');
  String get catLembretes => _s('Lembretes', 'Reminders', 'Recordatorios');

  // stats do cabeçalho
  String get statOdometro => _s('Odômetro', 'Odometer', 'Odómetro');
  String get statKmMes => _s('Km no mês', 'Km this month', 'Km del mes');
  String get statCombustivelMes =>
      _s('Combustível/mês', 'Fuel/month', 'Combustible/mes');
  String get statFipe => _s('FIPE', 'Value', 'Valor');
  String get statCalibragem => _s('Calibragem', 'Tires', 'Presión');
  String get statPrevRevisao =>
      _s('Prev. revisão', 'Next service', 'Próx. revisión');

  // ───────────────────────────── config ─────────────────────────────
  String get configuracoes =>
      _s('Configurações', 'Settings', 'Configuración');
  String get secaoConta =>
      _s('Conta e sincronização', 'Account & sync', 'Cuenta y sincronización');
  String get secaoAparencia => _s('Aparência', 'Appearance', 'Apariencia');
  String get secaoNotificacoes =>
      _s('Notificações', 'Notifications', 'Notificaciones');
  String get secaoSobre => _s('Sobre', 'About', 'Acerca de');
  String get secaoIdioma => _s('Idioma', 'Language', 'Idioma');
  String get tema => _s('Tema', 'Theme', 'Tema');
  String nomeTema(int i) => switch (i) {
        0 => _s('Âmbar', 'Amber', 'Ámbar'),
        1 => _s('Azul', 'Blue', 'Azul'),
        2 => _s('Expresso', 'Espresso', 'Espresso'),
        _ => _s('Madeira', 'Wood', 'Madera'),
      };
  String get tamanhoFonte =>
      _s('Tamanho da fonte', 'Font size', 'Tamaño de fuente');
  String get valeAppInteiro => _s('Vale para o app inteiro.',
      'Applies to the whole app.', 'Vale para toda la app.');
  String get fonteMenor => _s('Menor', 'Smaller', 'Menor');
  String get fonteNormal => _s('Normal', 'Normal', 'Normal');
  String get fonteMaior => _s('Maior', 'Larger', 'Mayor');
  String get fonteMax => _s('Máx.', 'Max', 'Máx.');
  String get entrarSincronizar => _s(
      'Entre para sincronizar seus dados entre aparelhos.',
      'Sign in to sync your data across devices.',
      'Inicia sesión para sincronizar tus datos entre dispositivos.');
  String get entrarComGoogle =>
      _s('Entrar com Google', 'Sign in with Google', 'Entrar con Google');
  String get naoConsegiuEntrar => _s('Não foi possível entrar.',
      "Couldn't sign in.", 'No se pudo iniciar sesión.');
  String get conectado => _s('Conectado', 'Connected', 'Conectado');
  String get sair => _s('Sair', 'Sign out', 'Salir');
  String get dadosNesteAparelho => _s('Dados salvos neste aparelho',
      'Data saved on this device', 'Datos guardados en este dispositivo');
  String get nuvemEmBreve => _s(
      'A sincronização na nuvem com login Google entra numa próxima versão. Por enquanto, tudo fica salvo localmente.',
      'Cloud sync with Google sign-in is coming in a future version. For now, everything is saved locally.',
      'La sincronización en la nube con Google llegará en una versión futura. Por ahora, todo se guarda localmente.');
  String get avisarVencimentos => _s('Avisar sobre vencimentos e revisão',
      'Alert about due dates and service', 'Avisar de vencimientos y revisión');
  String get avisarVencimentosSub => _s(
      'Notifica no dia (e 3 dias antes) dos lembretes e quando a próxima revisão se aproxima.',
      'Notifies on the day (and 3 days before) of reminders and when the next service is near.',
      'Notifica el día (y 3 días antes) de los recordatorios y cuando la próxima revisión se acerca.');
  String get permissaoNegada => _s(
      'Permissão negada. Ative as notificações do CarLog nos ajustes do Android.',
      'Permission denied. Enable CarLog notifications in Android settings.',
      'Permiso denegado. Activa las notificaciones de CarLog en los ajustes de Android.');
  String get appTagline => _s('O diário do seu carro', 'Your car diary',
      'El diario de tu auto');

  // ───────────────────────────── abastecimento ─────────────────────────────
  String get abastecimentos => _s('Abastecimentos', 'Fill-ups', 'Cargas');
  String get abastecer => _s('Abastecer', 'Add fill-up', 'Cargar');
  String get novoAbastecimento =>
      _s('Novo abastecimento', 'New fill-up', 'Nueva carga');
  String get abastecimento => _s('Abastecimento', 'Fill-up', 'Carga');
  String get semAbastecimento => _s('Nenhum abastecimento ainda',
      'No fill-ups yet', 'Sin cargas todavía');
  String get semAbastecimentoSub => _s(
      'Toque em "Abastecer" para registrar litros, preço e odômetro. Com dois tanques cheios o app já calcula sua média.',
      'Tap "Add fill-up" to log liters, price and odometer. With two full tanks the app computes your mileage.',
      'Toca "Cargar" para registrar litros, precio y odómetro. Con dos tanques llenos la app calcula tu consumo.');
  String get gastoNoMes => _s('Gasto no mês', 'Spent this month', 'Gasto del mes');
  String get litrosLabel => _s('Litros', 'Liters', 'Litros');
  String get abastecAbrev => _s('Abastec.', 'Fill-ups', 'Cargas');
  String get excluirAbastecimento =>
      _s('Excluir abastecimento?', 'Delete fill-up?', '¿Eliminar carga?');
  String get odometroKmOpc => _s('Odômetro (km, opcional)',
      'Odometer (km, optional)', 'Odómetro (km, opcional)');
  String get litrosOpc =>
      _s('Litros (opcional)', 'Liters (optional)', 'Litros (opcional)');
  String get valorTotalRs =>
      _s('Valor total (R\$)', 'Total amount', 'Importe total');
  String get precoLitro => _s('Preço / litro', 'Price / liter', 'Precio / litro');
  String get total => _s('Total', 'Total', 'Total');
  String get informarPrecoLitro => _s('Informar preço/litro',
      'Enter price/liter', 'Indicar precio/litro');
  String get informarValorTotal => _s('Informar valor total',
      'Enter total amount', 'Indicar importe total');
  String get enchiTanque =>
      _s('Enchi o tanque', 'Filled the tank', 'Llené el tanque');
  String get enchiTanqueSub => _s('Necessário para o cálculo de média confiável',
      'Needed for a reliable mileage calculation',
      'Necesario para un cálculo de consumo fiable');
  String get postoOpc => _s('Posto (opcional)', 'Station (optional)',
      'Estación (opcional)');
  String get postoHint => _s('Ex.: Shell da avenida', 'e.g. Shell on Main St',
      'Ej.: Shell de la avenida');
  String get observacaoOpc =>
      _s('Observação (opcional)', 'Note (optional)', 'Nota (opcional)');
  String get preenchaUmCampo => _s(
      'Preencha ao menos um campo (odômetro, litros ou preço).',
      'Fill at least one field (odometer, liters or price).',
      'Completa al menos un campo (odómetro, litros o precio).');

  // ───────────────────────────── consumo / média ─────────────────────────────
  String get consumoMedia =>
      _s('Consumo / Média', 'Fuel economy', 'Consumo');
  String get calcularMedia =>
      _s('Calcular média', 'Calc. mileage', 'Calcular consumo');
  String get mediaGeral => _s('Média geral', 'Overall mileage', 'Consumo medio');
  String get semMediaAinda => _s(
      'Registre pelo menos dois abastecimentos de tanque cheio para ver sua média automática.',
      'Log at least two full-tank fill-ups to see your automatic mileage.',
      'Registra al menos dos cargas de tanque lleno para ver tu consumo automático.');
  String get melhor => _s('Melhor', 'Best', 'Mejor');
  String get pior => _s('Pior', 'Worst', 'Peor');
  String get totalGasto => _s('Total gasto', 'Total spent', 'Total gastado');
  String get kmRodadosMes => _s('Km rodados este mês',
      'Km driven this month', 'Km recorridos este mes');
  String get mesAnterior => _s('mês anterior', 'last month', 'mes anterior');
  String get mediaAvulsa => _s('Média avulsa (cidade × rodovia)',
      'Quick mileage (city × highway)', 'Consumo puntual (ciudad × ruta)');
  String get usarCalcularMedia => _s(
      'Use "Calcular média" para medir um trecho: informe km e litros e marque se foi cidade ou rodovia.',
      'Use "Calc. mileage" to measure a leg: enter km and liters and mark city or highway.',
      'Usa "Calcular consumo" para medir un tramo: indica km y litros y marca ciudad o ruta.');
  String get trechos => _s('Trechos (tanque cheio → tanque cheio)',
      'Legs (full tank → full tank)', 'Tramos (tanque lleno → tanque lleno)');
  String get kmPercorridos =>
      _s('Km percorridos', 'Km driven', 'Km recorridos');
  String get litrosGastos =>
      _s('Litros gastos', 'Liters used', 'Litros usados');
  String get salvarMedicao =>
      _s('Salvar medição', 'Save measurement', 'Guardar medición');

  // ───────────────────────────── revisões ─────────────────────────────
  String get revisoes => _s('Revisões', 'Service', 'Revisiones');
  String get programar => _s('Programar', 'Planned', 'Programar');
  String get historico => _s('Histórico', 'History', 'Historial');
  String get adicionar => _s('Adicionar', 'Add', 'Agregar');
  String get registrar => _s('Registrar', 'Log', 'Registrar');
  String get novaRevisao => _s('Nova revisão', 'New service', 'Nueva revisión');
  String get revisao => _s('Revisão', 'Service', 'Revisión');
  String get excluirRevisao =>
      _s('Excluir revisão?', 'Delete service?', '¿Eliminar revisión?');
  String get nadaProgramado =>
      _s('Nada programado ainda', 'Nothing planned yet', 'Nada programado aún');
  String get nadaProgramadoSub => _s(
      'Toque em "Adicionar" para anotar o que verificar/trocar. Dá para definir o km e a frequência (ex.: óleo a cada 10.000 km).',
      'Tap "Add" to note what to check/replace. You can set the km and how often (e.g. oil every 10,000 km).',
      'Toca "Agregar" para anotar qué revisar/cambiar. Puedes fijar el km y la frecuencia (ej.: aceite cada 10.000 km).');
  String get semRevisoes => _s('Sem revisões registradas',
      'No service logged', 'Sin revisiones registradas');
  String get semRevisoesSub => _s(
      'Registre o que já foi trocado. A lupa busca por peça, serviço ou oficina.',
      'Log what was already replaced. The search finds parts, services or shops.',
      'Registra lo que ya se cambió. La lupa busca por pieza, servicio o taller.');
  String get buscarPecaServico => _s('Buscar peça, serviço, oficina…',
      'Search part, service, shop…', 'Buscar pieza, servicio, taller…');
  String get revisaoPodeVencida => _s('Sua revisão pode estar vencida',
      'Your service may be overdue', 'Tu revisión puede estar vencida');
  String get proximaRevisao =>
      _s('Próxima revisão', 'Next service', 'Próxima revisión');
  String get registreParaEstimar => _s(
      'Registre revisões e abastecimentos (com o km do painel) para o app estimar a próxima revisão pela sua rodagem.',
      'Log services and fill-ups (with the dashboard km) so the app can estimate the next service from your driving.',
      'Registra revisiones y cargas (con el km del tablero) para que la app estime la próxima revisión según tu conducción.');
  String get alvo => _s('Alvo', 'Target', 'Objetivo');
  String get previsao => _s('Previsão', 'Forecast', 'Previsión');
  String get estavaPrevista =>
      _s('estava prevista', 'was expected', 'estaba prevista');
  String get mediaUlt12 => _s('Média nos últimos 12 meses',
      'Average over the last 12 months', 'Media en los últimos 12 meses');
  String porMes(String v) => _s('$v/mês', '$v/mo', '$v/mes');
  String get novoItem => _s('Novo item', 'New item', 'Nuevo ítem');
  String get editarItem => _s('Editar item', 'Edit item', 'Editar ítem');
  String get oQueVerificar => _s('O que verificar/trocar',
      'What to check/replace', 'Qué revisar/cambiar');
  String get oQueVerificarHint => _s('Ex.: óleo, filtro de ar, velas…',
      'e.g. oil, air filter, spark plugs…', 'Ej.: aceite, filtro de aire, bujías…');
  String get aCadaKm => _s('A cada (km)', 'Every (km)', 'Cada (km)');
  String get fazerNoKm => _s('Fazer no km', 'Do at km', 'Hacer al km');
  String get ambosOpcionais => _s(
      'Ambos opcionais. Com o km, o app mostra quanto falta e a data provável (pelo seu ritmo de rodagem).',
      'Both optional. With the km, the app shows how much is left and the likely date (from your driving pace).',
      'Ambos opcionales. Con el km, la app muestra cuánto falta y la fecha probable (según tu ritmo).');
  String feitoReagendado(String km) => _s('Feito! Reagendado para $km.',
      'Done! Rescheduled to $km.', '¡Hecho! Reprogramado para $km.');
  String paraKm(String km) => _s('para $km', 'at $km', 'a $km');
  String get vencido => _s('vencido', 'overdue', 'vencido');
  String faltamKm(String km) =>
      _s('faltam $km', '$km left', 'faltan $km');
  String aCadaKmValor(String km) =>
      _s('a cada $km', 'every $km', 'cada $km');
  String get tituloRevisaoHint =>
      _s('Ex.: Revisão dos 40 mil', 'e.g. 40k service', 'Ej.: Revisión de los 40 mil');
  String get titulo => _s('Título', 'Title', 'Título');
  String get odometroKm => _s('Odômetro (km)', 'Odometer (km)', 'Odómetro (km)');
  String get custoRs => _s('Custo (R\$)', 'Cost', 'Costo');
  String get oficinaConcessionaria => _s('Oficina / concessionária',
      'Shop / dealership', 'Taller / concesionario');
  String get oficinaHint => _s('Ex.: Auto Center do João',
      "e.g. Joe's Auto Center", 'Ej.: Auto Center de Juan');
  String get pecasServicos => _s('Peças / serviços trocados',
      'Parts / services replaced', 'Piezas / servicios cambiados');
  String get pecaHint => _s('Ex.: Óleo, filtro de ar, pastilha…',
      'e.g. Oil, air filter, brake pad…', 'Ej.: Aceite, filtro de aire, pastilla…');
  String get textoOrcamento =>
      _s('Texto do orçamento', 'Quote text', 'Texto del presupuesto');
  String get lerFoto => _s('Ler foto', 'Read photo', 'Leer foto');
  String get lendo => _s('Lendo…', 'Reading…', 'Leyendo…');
  String get coleOrcamento => _s(
      'Cole aqui o texto do orçamento — fica buscável pela lupa.',
      'Paste the quote text here — it becomes searchable.',
      'Pega aquí el texto del presupuesto — queda buscable con la lupa.');
  String get deTituloOuItem => _s('Dê um título ou adicione ao menos um item.',
      'Give a title or add at least one item.',
      'Pon un título o agrega al menos un ítem.');
  String get naoLeuImagem => _s('Não foi possível ler a imagem.',
      "Couldn't read the image.", 'No se pudo leer la imagen.');
  String get nenhumTextoFoto => _s('Nenhum texto reconhecido na foto.',
      'No text recognized in the photo.', 'No se reconoció texto en la foto.');
  String get tirarFoto => _s('Tirar foto do orçamento',
      'Take a photo of the quote', 'Tomar foto del presupuesto');
  String get escolherGaleria =>
      _s('Escolher da galeria', 'Pick from gallery', 'Elegir de la galería');
  String get oQueImportar => _s('O que importar do orçamento',
      'What to import from the quote', 'Qué importar del presupuesto');
  String get oQueImportarSub => _s(
      'Marque as linhas que são peças/serviços. Use a lupa para achar um item específico. O texto completo também fica salvo e buscável.',
      'Check the lines that are parts/services. Use the search to find a specific item. The full text is also saved and searchable.',
      'Marca las líneas que son piezas/servicios. Usa la lupa para hallar un ítem. El texto completo también queda guardado y buscable.');
  String get buscarItemOrcamento => _s('Buscar item do orçamento…',
      'Search quote item…', 'Buscar ítem del presupuesto…');
  String get nenhumItemEncontrado => _s('Nenhum item encontrado.',
      'No item found.', 'Ningún ítem encontrado.');
  String get marcarTodos => _s('Marcar todos', 'Select all', 'Marcar todos');
  String get desmarcarTodos =>
      _s('Desmarcar todos', 'Deselect all', 'Desmarcar todos');
  String importarN(int n) =>
      _s('Importar ($n)', 'Import ($n)', 'Importar ($n)');

  // ───────────────────────────── calibragem ─────────────────────────────
  String get calibragem => _s('Calibragem', 'Tire pressure', 'Presión');
  String get calibragemRecomendada => _s('Calibragem recomendada',
      'Recommended pressure', 'Presión recomendada');
  String get definir => _s('Definir', 'Set', 'Definir');
  String get editar => _s('Editar', 'Edit', 'Editar');
  String get toqueDefinir => _s('Toque em "Definir" e ajuste com − / +.',
      'Tap "Set" and adjust with − / +.', 'Toca "Definir" y ajusta con − / +.');
  String get cadastreCarroCalibragem => _s(
      'Cadastre o carro (tela inicial) para definir a calibragem recomendada aqui.',
      'Add the car (home screen) to set the recommended pressure here.',
      'Registra el auto (pantalla inicial) para definir la presión recomendada aquí.');
  String get dianteiro => _s('Dianteiro', 'Front', 'Delantero');
  String get traseiro => _s('Traseiro', 'Rear', 'Trasero');
  String get ultimaCalibragem =>
      _s('Última calibragem', 'Last check', 'Última calibración');
  String get aindaNaoRegistrada =>
      _s('Ainda não registrada', 'Not logged yet', 'Aún no registrada');
  String get valeCalibrar => _s('Já faz um tempo — vale calibrar.',
      "It's been a while — worth checking.", 'Ya pasó un tiempo — conviene revisar.');
  String get registrarCalibragem => _s('Registrar calibragem',
      'Log tire check', 'Registrar calibración');
  String get observacaoOpcional =>
      _s('Observação (opcional)', 'Note (optional)', 'Nota (opcional)');

  // ───────────────────────────── minha FIPE ─────────────────────────────
  String get minhaFipe => _s('Minha FIPE', 'My value (FIPE)', 'Mi valor (FIPE)');
  String get consultarFipe => _s('Consultar tabela FIPE',
      'Look up FIPE table', 'Consultar tabla FIPE');
  String get consultarFipeSub => _s(
      'Selecione marca, modelo e ano — dá para cadastrar o carro por aqui.',
      'Pick make, model and year — you can register the car from here.',
      'Elige marca, modelo y año — puedes registrar el auto desde aquí.');
  String get usarComoMeuCarro =>
      _s('Usar como meu carro', 'Use as my car', 'Usar como mi auto');
  String get informarValorManual => _s('Informar valor manualmente',
      'Enter value manually', 'Indicar valor manualmente');
  String get valorRs => _s('Valor (R\$)', 'Value', 'Valor');
  String get valorHint => _s('Ex.: 45000', 'e.g. 45000', 'Ej.: 45000');
  String get valorAtualVeiculo =>
      _s('Valor atual do veículo', 'Current car value', 'Valor actual del auto');
  String get informadoManualmente => _s('informado manualmente',
      'entered manually', 'indicado manualmente');
  String refPrefixo(String mes) => _s('Ref.: $mes', 'Ref.: $mes', 'Ref.: $mes');
  String emData(String d) => _s('em $d', 'on $d', 'el $d');
  String get carroCadastradoFipe => _s(
      'Carro cadastrado pela FIPE. Adicione a placa no cartão do veículo.',
      'Car added from FIPE. Add the plate on the car card.',
      'Auto registrado por FIPE. Agrega la matrícula en la tarjeta del auto.');
  String get veiculoAtualizadoFipe => _s('Veículo atualizado pela FIPE.',
      'Car updated from FIPE.', 'Auto actualizado por FIPE.');
  String get marca => _s('Marca', 'Make', 'Marca');
  String get modelo => _s('Modelo', 'Model', 'Modelo');
  String get ano => _s('Ano', 'Year', 'Año');
  String get toqueParaBuscar =>
      _s('Toque para buscar', 'Tap to search', 'Toca para buscar');
  String buscarX(String campo) => _s('Buscar ${campo.toLowerCase()}…',
      'Search ${campo.toLowerCase()}…', 'Buscar ${campo.toLowerCase()}…');
  String get fipeIndisponivel => _s(
      'Não foi possível consultar a FIPE agora. Verifique a internet.',
      "Couldn't reach FIPE right now. Check your connection.",
      'No se pudo consultar FIPE ahora. Verifica la conexión.');
  String get falhaModelos => _s('Falha ao carregar modelos.',
      'Failed to load models.', 'Error al cargar modelos.');
  String get falhaAnos =>
      _s('Falha ao carregar anos.', 'Failed to load years.', 'Error al cargar años.');
  String get falhaValor => _s('Falha ao consultar o valor.',
      'Failed to look up the value.', 'Error al consultar el valor.');
  String get buscarNaFipe => _s('Buscar na tabela FIPE',
      'Search FIPE table', 'Buscar en la tabla FIPE');
  String get selecioneMarcaModeloAno => _s(
      'Selecione marca, modelo e ano do seu carro.',
      'Pick your car make, model and year.',
      'Elige la marca, modelo y año de tu auto.');
  String get usarEstesDados =>
      _s('Usar estes dados', 'Use these', 'Usar estos datos');

  // ───────────────────────────── lembretes ─────────────────────────────
  String get lembretes => _s('Lembretes', 'Reminders', 'Recordatorios');
  String get novo => _s('Novo', 'New', 'Nuevo');
  String get semLembretes => _s('Sem lembretes', 'No reminders', 'Sin recordatorios');
  String get semLembretesSub => _s(
      'Cadastre vencimentos de IPVA, seguro, licenciamento e afins. O app mostra quantos dias faltam.',
      'Add due dates for taxes, insurance, registration and the like. The app shows how many days are left.',
      'Registra vencimientos de impuestos, seguro, patente y demás. La app muestra cuántos días faltan.');
  String get pago => _s('Pago', 'Paid', 'Pagado');
  String get marcarPago => _s('Marcar pago', 'Mark paid', 'Marcar pagado');
  String get pagoProximoPeriodo => _s('Pago — próximo período',
      'Paid — next period', 'Pagado — próximo período');
  String get novoLembrete => _s('Novo lembrete', 'New reminder', 'Nuevo recordatorio');
  String get lembrete => _s('Lembrete', 'Reminder', 'Recordatorio');
  String get tituloOpc => _s('Título (opcional)', 'Title (optional)', 'Título (opcional)');
  String get tituloLembreteHint => _s('Ex.: IPVA 2026 — cota única',
      'e.g. Insurance 2026 — single payment', 'Ej.: Seguro 2026 — pago único');
  String venceEm(String d) => _s('Vence em $d', 'Due on $d', 'Vence el $d');
  String get valorRsOpc =>
      _s('Valor (R\$, opcional)', 'Amount (optional)', 'Importe (opcional)');
  String get repeticao => _s('Repetição', 'Repeat', 'Repetición');

  // ───────────────────────────── veículo ─────────────────────────────
  String get cadastrarCarro => _s('Cadastrar carro', 'Add car', 'Registrar auto');
  String get meuCarro => _s('Meu carro', 'My car', 'Mi auto');
  String get excluirCarro => _s('Excluir carro', 'Delete car', 'Eliminar auto');
  String get excluirEsteCarro =>
      _s('Excluir este carro?', 'Delete this car?', '¿Eliminar este auto?');
  String get excluirCarroSub => _s(
      'O carro sai da lista. Os lançamentos dele deixam de aparecer.',
      'The car leaves the list. Its records stop showing.',
      'El auto sale de la lista. Sus registros dejan de aparecer.');
  String get busqueSeuCarroFipe => _s(
      'Busque seu carro na tabela FIPE (marca, modelo, ano).',
      'Look up your car in the FIPE table (make, model, year).',
      'Busca tu auto en la tabla FIPE (marca, modelo, año).');
  String get pesquisarCarro => _s('Pesquisar carro', 'Search car', 'Buscar auto');
  String get apelidoOpc =>
      _s('Apelido (opcional)', 'Nickname (optional)', 'Apodo (opcional)');
  String get apelidoHint => _s('Ex.: Meu Onix', 'e.g. My Civic', 'Ej.: Mi auto');
  String get placaOpc => _s('Placa (opcional)', 'Plate (optional)', 'Matrícula (opcional)');
  String get tanqueOpc => _s('Tanque (litros, opcional)',
      'Tank (liters, optional)', 'Tanque (litros, opcional)');
  String get intervaloRevisao =>
      _s('Intervalo de revisão', 'Service interval', 'Intervalo de revisión');
  String get ouMeses => _s('ou (meses)', 'or (months)', 'o (meses)');

  // ───────────────────────────── datas / relativo ─────────────────────────────
  String get hoje => _s('hoje', 'today', 'hoy');
  String get amanha => _s('amanhã', 'tomorrow', 'mañana');
  String get ontem => _s('ontem', 'yesterday', 'ayer');
  String emDias(int d) => _s('em $d dias', 'in $d days', 'en $d días');
  String haDias(int d) => _s('há $d dias', '$d days ago', 'hace $d días');

  /// "hoje", "amanhã", "em 12 dias", "há 3 dias" — no idioma atual.
  String desdeAte(DateTime alvo, {DateTime? agora}) {
    final base = agora ?? DateTime.now();
    final dias = DateTime(alvo.year, alvo.month, alvo.day)
        .difference(DateTime(base.year, base.month, base.day))
        .inDays;
    if (dias == 0) return hoje;
    if (dias == 1) return amanha;
    if (dias == -1) return ontem;
    if (dias > 1) return emDias(dias);
    return haDias(-dias);
  }

  // ───────────────────────────── notificações ─────────────────────────────
  String notifVenceHoje(String nome) => _s(
      '$nome vence hoje.', '$nome is due today.', '$nome vence hoy.');
  String notifVence3Dias(String nome) => _s('$nome vence em 3 dias.',
      '$nome is due in 3 days.', '$nome vence en 3 días.');
  String notifRevisaoChegando(String km) => _s(
      'Sua próxima revisão está chegando (~$km).',
      'Your next service is coming up (~$km).',
      'Tu próxima revisión se acerca (~$km).');

  // ───────────────────────── rótulos de enums ─────────────────────────
  String rotuloCombustivel(Combustivel c) => switch (c) {
        Combustivel.flex => _s('Flex', 'Flex', 'Flex'),
        Combustivel.gasolina => _s('Gasolina', 'Gasoline', 'Gasolina'),
        Combustivel.etanol => _s('Etanol', 'Ethanol', 'Etanol'),
        Combustivel.diesel => _s('Diesel', 'Diesel', 'Diésel'),
        Combustivel.gnv => _s('GNV', 'CNG', 'GNC'),
      };

  String rotuloTipoTrecho(TipoTrecho t) => switch (t) {
        TipoTrecho.cidade => _s('Cidade', 'City', 'Ciudad'),
        TipoTrecho.rodovia => _s('Rodovia', 'Highway', 'Ruta'),
        TipoTrecho.misto => _s('Misto', 'Mixed', 'Mixto'),
      };

  String rotuloTipoLembrete(TipoLembrete t) => switch (t) {
        TipoLembrete.ipva => _s('IPVA', 'Tax', 'Impuesto'),
        TipoLembrete.seguro => _s('Seguro', 'Insurance', 'Seguro'),
        TipoLembrete.licenciamento =>
          _s('Licenciamento', 'Registration', 'Patente'),
        TipoLembrete.multa => _s('Multa', 'Fine', 'Multa'),
        TipoLembrete.revisao => _s('Revisão', 'Service', 'Revisión'),
        TipoLembrete.pedagio => _s('Pedágio', 'Toll', 'Peaje'),
        TipoLembrete.estacionamento =>
          _s('Estacionamento', 'Parking', 'Estacionamiento'),
        TipoLembrete.outro => _s('Outro', 'Other', 'Otro'),
      };

  String rotuloRecorrencia(Recorrencia r) => switch (r) {
        Recorrencia.nenhuma => _s('Sem repetição', 'No repeat', 'Sin repetición'),
        Recorrencia.mensal => _s('Mensal', 'Monthly', 'Mensual'),
        Recorrencia.anual => _s('Anual', 'Yearly', 'Anual'),
      };
}
