import 'package:flutter/material.dart';

import 'models.dart';

/// Estado em memória do protótipo. Todos os dados são mockados.
class AppStore extends ChangeNotifier {
  final List<Usuario> usuarios = [];
  final List<PerfilGincana> perfis = [];
  final List<Gincana> gincanas = [];
  final List<Modalidade> modalidades = [];
  final List<Time> times = [];
  final List<Fase> fases = [];
  final List<Partida> partidas = [];
  final List<Pontuacao> pontuacoes = [];
  final List<LogAuditoria> logs = [];

  /// modalidadeId -> usuários inscritos (RF019).
  final Map<String, Set<String>> inscricoes = {};

  Usuario? usuarioAtual;
  Gincana? gincanaAtual;

  int _seq = 1000;
  String _id(String p) => '$p${_seq++}';

  AppStore() {
    _carregarMock();
  }

  // ---------------------------------------------------------------- sessão

  void entrar(Usuario u, Gincana g) {
    usuarioAtual = u;
    gincanaAtual = g;
    notifyListeners();
  }

  void sair() {
    usuarioAtual = null;
    gincanaAtual = null;
    notifyListeners();
  }

  List<PerfilGincana> perfisDe(String usuarioId, [String? gincanaId]) =>
      perfis.where((p) => p.usuarioId == usuarioId && (gincanaId == null || p.gincanaId == gincanaId)).toList();

  List<Gincana> gincanasDe(String usuarioId) {
    final ids = perfisDe(usuarioId).map((p) => p.gincanaId).toSet();
    return semanas.where((g) => ids.contains(g.id)).toList();
  }

  bool tem(Perfil perfil) {
    final u = usuarioAtual, g = gincanaAtual;
    if (u == null || g == null) return false;
    return perfisDe(u.id, g.id).any((p) => p.perfil == perfil);
  }

  Equipe? get equipeDoLider {
    final u = usuarioAtual, g = gincanaAtual;
    if (u == null || g == null) return null;
    final p = perfisDe(u.id, g.id).where((p) => p.perfil == Perfil.lider).firstOrNull;
    if (p == null) return null;
    return g.equipes.firstWhere((e) => e.id == p.equipeId);
  }

  // ---------------------------------------------------------------- consultas

  Usuario usuario(String id) => usuarios.firstWhere((u) => u.id == id);
  Equipe equipe(String id) => gincanas.expand((g) => g.equipes).firstWhere((e) => e.id == id);
  Modalidade modalidade(String id) => modalidades.firstWhere((m) => m.id == id);
  Time time(String id) => times.firstWhere((t) => t.id == id);
  Fase fase(String id) => fases.firstWhere((f) => f.id == id);

  List<Modalidade> get modalidadesDaGincana => modalidades.where((m) => m.gincanaId == gincanaAtual?.id).toList();

  List<Time> timesDa(String modalidadeId, {String? equipeId}) =>
      times.where((t) => t.modalidadeId == modalidadeId && (equipeId == null || t.equipeId == equipeId)).toList();

  List<Fase> fasesDa(String modalidadeId) =>
      fases.where((f) => f.modalidadeId == modalidadeId).toList()..sort((a, b) => a.ordem.compareTo(b.ordem));

  List<Partida> partidasDa(String faseId) => partidas.where((p) => p.faseId == faseId).toList();

  List<Partida> partidasDaModalidade(String modalidadeId) {
    final ids = fasesDa(modalidadeId).map((f) => f.id).toSet();
    return partidas.where((p) => ids.contains(p.faseId)).toList();
  }

  List<Partida> get partidasDaGincana {
    final mids = modalidadesDaGincana.map((m) => m.id).toSet();
    final fids = fases.where((f) => mids.contains(f.modalidadeId)).map((f) => f.id).toSet();
    return partidas.where((p) => fids.contains(p.faseId)).toList()..sort((a, b) => a.dataHora.compareTo(b.dataHora));
  }

  List<Partida> partidasDoArbitro(String usuarioId) =>
      partidasDaGincana.where((p) => p.arbitroIds.contains(usuarioId)).toList();

  Modalidade modalidadeDaPartida(Partida p) => modalidade(fase(p.faseId).modalidadeId);

  String tituloPartida(Partida p) => p.timeIds.map((t) => time(t).nome).join(p.timeIds.length == 2 ? ' x ' : ' · ');

  Set<String> inscritos(String modalidadeId) => inscricoes.putIfAbsent(modalidadeId, () => {});

  /// Times que venceram partidas encerradas de uma fase (RF029).
  List<String> classificados(String faseId) => partidasDa(faseId).map((p) => p.vencedorId).whereType<String>().toList();

  /// Time travado enquanto houver partida dele em andamento (RN017).
  bool timeBloqueado(String timeId) =>
      partidas.any((p) => p.status == StatusPartida.emAndamento && p.timeIds.contains(timeId));

  Map<String, double> ranking() {
    final g = gincanaAtual!;
    final r = {for (final e in g.equipes) e.id: 0.0};
    for (final p in pontuacoes.where((p) => !p.cancelada)) {
      if (r.containsKey(p.equipeId)) r[p.equipeId] = r[p.equipeId]! + p.valor;
    }
    return r;
  }

  Map<String, double> rankingModalidade(String modalidadeId) {
    final g = gincanaAtual!;
    final r = {for (final e in g.equipes) e.id: 0.0};
    for (final p in pontuacoes.where((p) => !p.cancelada && p.modalidadeId == modalidadeId)) {
      r[p.equipeId] = (r[p.equipeId] ?? 0) + p.valor;
    }
    return r;
  }

  List<Pontuacao> get pontuacoesDaGincana {
    final mids = modalidadesDaGincana.map((m) => m.id).toSet();
    return pontuacoes.where((p) => mids.contains(p.modalidadeId)).toList()..sort((a, b) => b.data.compareTo(a.data));
  }

  /// RF009: valida a divisão recebida.
  List<String> inconsistenciasDivisao(Gincana g) {
    final a = g.equipes[0].participantes.toSet();
    final b = g.equipes[1].participantes.toSet();
    return a.intersection(b).map((id) => usuario(id).nome).toList();
  }

  // ---------------------------------------------------------------- perfis (RF045–RF047)

  void adicionarPerfil(String usuarioId, Perfil perfil, [String? equipeId]) {
    final g = gincanaAtual!;
    if (perfis.any((p) => p.usuarioId == usuarioId && p.gincanaId == g.id && p.perfil == perfil)) return;
    perfis.add(PerfilGincana(usuarioId, g.id, perfil, equipeId));
    _log('Atribuiu o perfil ${perfil.label} a ${usuario(usuarioId).nome}');
    notifyListeners();
  }

  void removerPerfil(PerfilGincana p) {
    perfis.remove(p);
    _log('Revogou o perfil ${p.perfil.label} de ${usuario(p.usuarioId).nome}');
    notifyListeners();
  }

  /// Quem pode arbitrar: os Administradores da gincana.
  List<Usuario> get arbitrosDaGincana {
    final ids = perfis
        .where((p) => p.gincanaId == gincanaAtual?.id && p.perfil == Perfil.administrador)
        .map((p) => p.usuarioId)
        .toSet();
    return usuarios.where((u) => ids.contains(u.id)).toList();
  }

  // ---------------------------------------------------------------- administração

  Modalidade criarModalidade(Modalidade Function(String id) build) {
    final m = build(_id('m'));
    modalidades.add(m);
    _log('Criou a modalidade ${m.nome}');
    notifyListeners();
    return m;
  }

  void atualizarModalidade(Modalidade m) {
    _log('Editou a modalidade ${m.nome}');
    notifyListeners();
  }

  bool modalidadeTemMarcacoes(String modalidadeId) =>
      partidasDaModalidade(modalidadeId).any((p) => p.status != StatusPartida.agendada);

  void excluirModalidade(Modalidade m) {
    final fids = fasesDa(m.id).map((f) => f.id).toSet();
    partidas.removeWhere((p) => fids.contains(p.faseId));
    fases.removeWhere((f) => f.modalidadeId == m.id);
    times.removeWhere((t) => t.modalidadeId == m.id);
    modalidades.remove(m);
    _log('Excluiu a modalidade ${m.nome}');
    notifyListeners();
  }

  void criarTime(String modalidadeId, String equipeId, String nome) {
    times.add(Time(_id('t'), modalidadeId, equipeId, nome));
    _log('Criou o time $nome');
    notifyListeners();
  }

  void removerTime(Time t) {
    times.remove(t);
    notifyListeners();
  }

  void criarFase(String modalidadeId, String nome, bool valePontos) {
    final ordem = fasesDa(modalidadeId).length + 1;
    fases.add(Fase(_id('f'), modalidadeId, nome, ordem, valePontos));
    _log('Criou a fase $nome');
    notifyListeners();
  }

  /// Retorna mensagem de erro ou null (RF027/RF028).
  String? validarPartida(Fase f, List<String> timeIds) {
    final m = modalidade(f.modalidadeId);
    if (m.tipo == TipoMarcacao.placar && timeIds.length != 2) {
      return 'Partidas de placar precisam de exatamente 2 times.';
    }
    if (m.tipo == TipoMarcacao.tempo && timeIds.length < 2) {
      return 'Selecione pelo menos 2 participantes para a prova.';
    }
    if (f.valePontos) {
      final equipes = timeIds.map((t) => time(t).equipeId).toList();
      if (m.tipo == TipoMarcacao.placar && equipes.toSet().length < equipes.length) {
        return 'Em fases que valem pontos, times da mesma equipe não podem se enfrentar (RN014).';
      }
      if (equipes.toSet().length < 2) {
        return 'Em fases que valem pontos, a prova precisa ter times das duas equipes (RN014).';
      }
    }
    return null;
  }

  void criarPartida(Fase f, List<String> timeIds, List<String> arbitroIds, DateTime dataHora) {
    partidas.add(Partida(id: _id('p'), faseId: f.id, timeIds: timeIds, arbitroIds: arbitroIds, dataHora: dataHora));
    _log('Criou partida em ${modalidade(f.modalidadeId).nome} / ${f.nome}');
    notifyListeners();
  }

  void reagendarPartida(Partida p, DateTime nova) {
    final antes = p.dataHora;
    p.dataHora = nova;
    _log(
      'Reagendou ${tituloPartida(p)}: ${formatarData(antes)} ${formatarHora(antes)} para ${formatarData(nova)} ${formatarHora(nova)}',
    );
    notifyListeners();
  }

  /// Dias do calendário da gincana (início a fim).
  List<DateTime> get diasDaGincana {
    final g = gincanaAtual!;
    final n = g.fim.difference(g.inicio).inDays;
    return [for (var i = 0; i <= n; i++) DateTime(g.inicio.year, g.inicio.month, g.inicio.day + i)];
  }

  // ---------------------------------------------------------------- semanas (RF005/RF066/RF071)

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);
  static int _diasEntre(DateTime a, DateTime b) =>
      DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

  /// Semanas do acampamento em ordem cronológica.
  List<Gincana> get semanas => List.of(gincanas)..sort((a, b) => a.inicio.compareTo(b.inicio));

  List<Partida> partidasDe(Gincana g) {
    final mids = modalidades.where((m) => m.gincanaId == g.id).map((m) => m.id).toSet();
    final fids = fases.where((f) => mids.contains(f.modalidadeId)).map((f) => f.id).toSet();
    return partidas.where((p) => fids.contains(p.faseId)).toList();
  }

  /// Semana que se sobreporia a outra (sábado a sexta), ou null (RN016: semanas nunca se sobrepõem).
  Gincana? sobreposicao(DateTime inicio, {String? ignorarId}) {
    final a0 = _dia(inicio), a1 = DateTime(a0.year, a0.month, a0.day + 6);
    for (final g in gincanas) {
      if (g.id == ignorarId) continue;
      final b0 = g.inicio, b1 = DateTime(b0.year, b0.month, b0.day + 6);
      if (!a1.isBefore(b0) && !b1.isBefore(a0)) return g;
    }
    return null;
  }

  /// Próximo sábado livre depois da última semana cadastrada.
  DateTime get proximoSabadoLivre {
    final ult = semanas.isEmpty ? null : semanas.last.inicio;
    if (ult != null) return DateTime(ult.year, ult.month, ult.day + 7);
    final h = _dia(DateTime.now());
    return DateTime(h.year, h.month, h.day + ((DateTime.saturday - h.weekday) % 7));
  }

  String statusSemana(Gincana g) {
    if (g.encerrada) return 'Finalizada';
    final h = _dia(DateTime.now());
    if (h.isBefore(g.inicio)) return 'Planejada';
    if (h.isAfter(DateTime(g.inicio.year, g.inicio.month, g.inicio.day + 6))) return 'Concluída';
    return 'Em andamento';
  }

  String textoDivisao(Gincana g) => g.divisaoRecebidaEm == null
      ? 'Divisão das equipes ainda não recebida do sistema existente'
      : 'Divisão recebida em ${formatarData(g.divisaoRecebidaEm!)} às ${formatarHora(g.divisaoRecebidaEm!)}';

  /// Cadastra uma nova semana (RF071). Equipes começam vazias, aguardando a divisão do sistema existente.
  /// Os Administradores da semana atual passam a ter perfil na nova. Opcionalmente copia as modalidades
  /// (com fases e configurações) de outra semana.
  Gincana criarSemana({required DateTime inicio, String? copiarDe}) {
    final ini = _dia(inicio);
    final n = gincanas.length + 1;
    final id = _id('g');
    final g = Gincana(
      id: id,
      nome: '$nª Semana',
      local: nomeLocal,
      inicio: ini,
      fim: DateTime(ini.year, ini.month, ini.day + 5),
      equipes: [
        Equipe(_id('e'), 'Equipe Azul', const Color(0xFF1F5FD1), []),
        Equipe(_id('e'), 'Equipe Vermelha', const Color(0xFFD13B2F), []),
      ],
    );
    gincanas.add(g);
    final admins = perfis
        .where((p) => p.gincanaId == gincanaAtual?.id && p.perfil == Perfil.administrador)
        .map((p) => p.usuarioId)
        .toSet();
    for (final u in admins) {
      perfis.add(PerfilGincana(u, id, Perfil.administrador));
    }
    if (copiarDe != null) {
      for (final m in modalidades.where((m) => m.gincanaId == copiarDe).toList()) {
        final nova = Modalidade(
          id: _id('m'),
          gincanaId: id,
          nome: m.nome,
          categoria: m.categoria,
          tipo: m.tipo,
          unidade: m.unidade,
          pontosVitoria: m.pontosVitoria,
          pontosEmpate: m.pontosEmpate,
          pontosDerrota: m.pontosDerrota,
          pontosColocacao: List.of(m.pontosColocacao),
          peso: m.peso,
          regraEmpateEliminatoria: m.regraEmpateEliminatoria,
          regraEmpatePontuada: m.regraEmpatePontuada,
          participantesPorTime: m.participantesPorTime,
          reservas: m.reservas,
        );
        modalidades.add(nova);
        for (final f in fasesDa(m.id)) {
          fases.add(Fase(_id('f'), nova.id, f.nome, f.ordem, f.valePontos));
        }
      }
    }
    _log('Cadastrou a ${g.nome}: ${formatarData(g.inicio)} a ${formatarData(g.fim)}');
    notifyListeners();
    return g;
  }

  /// Passa a trabalhar em outra semana (o usuário precisa ter perfil nela).
  void trocarSemana(Gincana g) {
    gincanaAtual = g;
    notifyListeners();
  }

  /// Altera nome e semana (RF066). [inicio] deve ser um sábado; as competições vão até a quinta.
  /// Partidas já agendadas acompanham a mudança (mantêm dia da semana e horário).
  void atualizarSemana(Gincana g, {required String nome, required DateTime inicio}) {
    final novoInicio = _dia(inicio);
    final delta = _diasEntre(g.inicio, novoInicio);
    if (delta != 0) {
      for (final p in partidasDe(g)) {
        final d = p.dataHora;
        p.dataHora = DateTime(d.year, d.month, d.day + delta, d.hour, d.minute);
      }
    }
    g
      ..nome = nome
      ..inicio = novoInicio
      ..fim = DateTime(novoInicio.year, novoInicio.month, novoInicio.day + 5);
    _log(
      'Alterou a $nome: ${formatarData(g.inicio)} a ${formatarData(g.fim)}'
      '${delta != 0 ? ' (partidas movidas junto)' : ''}',
    );
    notifyListeners();
  }

  /// Semana da gincana: de sábado a sexta (7 dias a partir do início).
  /// As competições vão de sábado a quinta; a sexta aparece sem jogos (RN021).
  List<DateTime> get semanaDaGincana {
    final g = gincanaAtual!;
    return [for (var i = 0; i < 7; i++) DateTime(g.inicio.year, g.inicio.month, g.inicio.day + i)];
  }

  bool diaDeCompeticao(DateTime d) {
    final g = gincanaAtual!;
    final dia = DateTime(d.year, d.month, d.day);
    return !dia.isBefore(g.inicio) && !dia.isAfter(g.fim);
  }

  /// Hoje, se estiver dentro da gincana; senão o primeiro dia.
  DateTime get diaPadrao {
    final h = DateTime.now();
    final hoje = DateTime(h.year, h.month, h.day);
    final dias = diasDaGincana;
    return dias.any((d) => d == hoje) ? hoje : dias.first;
  }

  void excluirPartida(Partida p) {
    partidas.remove(p);
    notifyListeners();
  }

  // ---------------------------------------------------------------- encerramento da gincana

  /// Partidas ainda não encerradas (avisadas antes de finalizar).
  List<Partida> get partidasPendentes => partidasDaGincana.where((p) => p.status != StatusPartida.encerrada).toList();

  void encerrarGincana() {
    final g = gincanaAtual!;
    g.encerradaEm = DateTime.now();
    _log('Finalizou a gincana da ${g.nome}');
    notifyListeners();
  }

  void reabrirGincana() {
    gincanaAtual!.encerradaEm = null;
    _log('Reabriu a gincana');
    notifyListeners();
  }

  /// Equipe vencedora (null se empate ou sem pontos).
  Equipe? get equipeVencedora {
    final g = gincanaAtual!;
    final r = ranking();
    final a = r[g.equipes[0].id]!, b = r[g.equipes[1].id]!;
    if (a == b) return null;
    return a > b ? g.equipes[0] : g.equipes[1];
  }

  /// Vencedor de cada modalidade: a partida encerrada da última fase que vale pontos.
  ResultadoModalidade resultadoModalidade(Modalidade m) {
    final fasesPont = fasesDa(m.id).where((f) => f.valePontos).toList();
    if (fasesPont.isEmpty) return ResultadoModalidade(m, null, null, 'Sem fase que vale pontos');
    final f = fasesPont.last;
    final enc = partidasDa(f.id).where((p) => p.status == StatusPartida.encerrada && !p.cancelada).toList()
      ..sort((a, b) => b.dataHora.compareTo(a.dataHora));
    final decisivas = enc.where((p) => !p.empate || regraEmpate(p) == RegraEmpate.empateAceito).toList();
    if (decisivas.isEmpty) return ResultadoModalidade(m, null, null, 'Não disputada');
    final p = decisivas.first;
    if (p.empate) return ResultadoModalidade(m, null, p, 'Empate');
    return ResultadoModalidade(m, p.classificacao.first, p, detalheResultado(p));
  }

  String detalheResultado(Partida p) {
    final m = modalidadeDaPartida(p);
    final v = p.classificacao.first;
    if (m.tipo == TipoMarcacao.tempo) {
      return p.tempos[v] != null ? 'Tempo ${formatarTempo(p.tempos[v]!)}' : '1º lugar';
    }
    final o = p.timeIds.firstWhere((t) => t != v);
    final des = p.placarDesempate.isNotEmpty ? ' (desempate ${p.placarDesempate[v]} × ${p.placarDesempate[o]})' : '';
    return '${p.placar[v]} × ${p.placar[o]} contra ${time(o).nome}$des';
  }

  /// Integrantes do time vencedor (escalação congelada na partida decisiva).
  List<String> integrantesVencedores(ResultadoModalidade r) {
    final t = time(r.timeId!);
    return r.partida!.escalacao[t.id] ?? t.integrantes;
  }

  /// Vitórias decisivas da gincana em ordem cronológica.
  List<ResultadoModalidade> vitoriasEmOrdem() =>
      [for (final m in modalidadesDaGincana.where((m) => m.ativa)) resultadoModalidade(m)]
          .where((r) => r.timeId != null && r.partida != null)
          .toList()
        ..sort((a, b) => a.partida!.dataHora.compareTo(b.partida!.dataHora));

  /// Uma medalha por pessoa (RN020): vale a primeira vitória em ordem cronológica.
  /// Retorna usuarioId -> resultado que deu a medalha.
  Map<String, ResultadoModalidade> medalhas() {
    final m = <String, ResultadoModalidade>{};
    for (final r in vitoriasEmOrdem()) {
      for (final u in integrantesVencedores(r)) {
        m.putIfAbsent(u, () => r);
      }
    }
    return m;
  }

  /// Todas as modalidades que a pessoa venceu (pode ser mais de uma, mas só uma medalha).
  List<ResultadoModalidade> vitoriasDe(String usuarioId) =>
      vitoriasEmOrdem().where((r) => integrantesVencedores(r).contains(usuarioId)).toList();

  /// Relatório final em texto puro, para copiar/compartilhar.
  String relatorioTexto() {
    final g = gincanaAtual!;
    final r = ranking();
    final v = equipeVencedora;
    final b = StringBuffer()
      ..writeln('RELATÓRIO FINAL — Gincana do $nomeLocal · ${g.nome}')
      ..writeln('$nomeLocal · ${formatarData(g.inicio)} a ${formatarData(g.fim)}')
      ..writeln()
      ..writeln(v == null ? 'RESULTADO: EMPATE' : 'EQUIPE VENCEDORA: ${v.nome.toUpperCase()}')
      ..writeln();
    for (final e in g.equipes) {
      b.writeln('${e.nome}: ${formatarPontos(r[e.id]!)} pontos');
    }
    b
      ..writeln()
      ..writeln('VENCEDORES POR MODALIDADE');
    for (final m in modalidadesDaGincana.where((m) => m.ativa)) {
      final res = resultadoModalidade(m);
      if (res.timeId == null) {
        b.writeln('- ${m.nome}: ${res.detalhe}');
      } else {
        final t = time(res.timeId!);
        final med = medalhas();
        final nomes = integrantesVencedores(res)
            .map(
              (u) => med[u]?.modalidade.id == m.id
                  ? usuario(u).nome
                  : '${usuario(u).nome} (já tem medalha: ${med[u]?.modalidade.nome})',
            )
            .join(', ');
        b.writeln('- ${m.nome}: ${t.nome} (${equipe(t.equipeId).nome}) — ${res.detalhe}');
        if (nomes.isNotEmpty) b.writeln('    Integrantes: $nomes');
      }
    }
    b
      ..writeln()
      ..writeln('Medalhas a entregar: ${medalhas().length} (uma por pessoa, mesmo vencendo mais de uma modalidade)');
    if (g.encerradaEm != null) {
      b
        ..writeln()
        ..writeln('Gincana finalizada em ${formatarData(g.encerradaEm!)} às ${formatarHora(g.encerradaEm!)}.');
    }
    return b.toString();
  }

  // ---------------------------------------------------------------- líder

  void alternarInscricao(String modalidadeId, String usuarioId) {
    final s = inscritos(modalidadeId);
    if (s.contains(usuarioId)) {
      s.remove(usuarioId);
      for (final t in timesDa(modalidadeId)) {
        if (!timeBloqueado(t.id)) t.integrantes.remove(usuarioId);
      }
    } else {
      s.add(usuarioId);
    }
    notifyListeners();
  }

  /// Mensagem de erro se o time já estiver cheio (titulares + reservas), senão null (RF070).
  String? limiteTime(Time t) {
    final m = modalidade(t.modalidadeId);
    final max = m.maxEscalados;
    if (max != null && t.integrantes.length >= max) {
      return '${t.nome} já tem o máximo de $max (${m.descricaoParticipantes}).';
    }
    return null;
  }

  /// Titulares e reservas de uma escalação: os primeiros N são titulares.
  List<String> titularesDe(Time t, [List<String>? lista]) {
    final l = lista ?? t.integrantes;
    final n = modalidade(t.modalidadeId).participantesPorTime;
    return n == null ? List.of(l) : l.take(n).toList();
  }

  List<String> reservasDe(Time t, [List<String>? lista]) {
    final l = lista ?? t.integrantes;
    final n = modalidade(t.modalidadeId).participantesPorTime;
    return n == null ? <String>[] : l.skip(n).toList();
  }

  /// Retorna mensagem de erro se não foi possível (time cheio).
  String? moverParaTime(String modalidadeId, String usuarioId, String? timeId) {
    if (timeId != null && !time(timeId).integrantes.contains(usuarioId)) {
      final erro = limiteTime(time(timeId));
      if (erro != null) return erro;
    }
    for (final t in timesDa(modalidadeId)) {
      if (t.integrantes.contains(usuarioId) && !timeBloqueado(t.id)) t.integrantes.remove(usuarioId);
    }
    if (timeId != null) time(timeId).integrantes.add(usuarioId);
    notifyListeners();
    return null;
  }

  /// Partidas em que a equipe do Líder joga (RF067).
  List<Partida> partidasDaEquipe(String equipeId) =>
      partidasDaGincana.where((p) => p.timeIds.any((t) => time(t).equipeId == equipeId)).toList();

  /// A escalação de um time só pode mudar enquanto a partida estiver agendada (RN017).
  bool podeEscalar(Partida p) => p.status == StatusPartida.agendada && !(gincanaAtual?.encerrada ?? false);

  /// O Líder coloca um participante da própria equipe no time da partida (RF068).
  /// Se ainda não estiver inscrito na modalidade, a inscrição é feita automaticamente.
  /// Se estiver em outro time da mesma modalidade (não travado), é movido.
  String? escalar(Partida p, String timeId, String usuarioId) {
    if (!podeEscalar(p)) return 'A escalação está travada.';
    final m = modalidadeDaPartida(p);
    final erro = limiteTime(time(timeId));
    if (erro != null) return erro;
    inscritos(m.id).add(usuarioId);
    moverParaTime(m.id, usuarioId, timeId);
    _log('Líder escalou ${usuario(usuarioId).nome} em ${time(timeId).nome} (${m.nome})');
    return null;
  }

  /// Escala todos os participantes da equipe (modalidades "toda a equipe").
  void escalarTodos(Partida p, String timeId) {
    if (!podeEscalar(p)) return;
    final t = time(timeId);
    final m = modalidade(t.modalidadeId);
    for (final u in equipe(t.equipeId).participantes) {
      if (!t.integrantes.contains(u)) {
        inscritos(m.id).add(u);
        t.integrantes.add(u);
      }
    }
    notifyListeners();
  }

  /// Passa um reserva para titular (o último titular vira reserva).
  void tornarTitular(Partida p, String timeId, String usuarioId) {
    if (!podeEscalar(p)) return;
    final t = time(timeId);
    final n = modalidade(t.modalidadeId).participantesPorTime;
    if (n == null) return;
    t.integrantes.remove(usuarioId);
    t.integrantes.insert((n - 1).clamp(0, t.integrantes.length), usuarioId);
    notifyListeners();
  }

  void desescalar(Partida p, String timeId, String usuarioId) {
    if (!podeEscalar(p)) return;
    time(timeId).integrantes.remove(usuarioId);
    notifyListeners();
  }

  // ---------------------------------------------------------------- arbitragem

  void iniciarPartida(Partida p) {
    if (gincanaAtual?.encerrada ?? false) return;
    p.status = StatusPartida.emAndamento;
    for (final t in p.timeIds) {
      p.escalacao[t] = List.of(time(t).integrantes);
    }
    _log('Iniciou ${tituloPartida(p)}');
    notifyListeners();
  }

  void marcarPonto(Partida p, String timeId, int delta) {
    final atual = p.placar[timeId] ?? 0;
    if (atual + delta < 0) return;
    p.placar[timeId] = atual + delta;
    p.marcacoes.add(
      Marcacao(timeId: timeId, tipo: TipoMarcacaoEvento.ponto, valor: delta, usuarioId: usuarioAtual!.id),
    );
    notifyListeners();
  }

  void desfazerMarcacao(Partida p, Marcacao m) {
    if (m.desfeita) return;
    m.desfeita = true;
    if (m.tipo == TipoMarcacaoEvento.ponto) {
      p.placar[m.timeId] = (p.placar[m.timeId] ?? 0) - m.valor;
    } else if (m.tipo == TipoMarcacaoEvento.tempo || m.tipo == TipoMarcacaoEvento.ajuste) {
      p.tempos.remove(m.timeId);
    }
    notifyListeners();
  }

  void registrarTempo(Partida p, String timeId, int ms) {
    p.tempos[timeId] = ms;
    p.marcacoes.add(Marcacao(timeId: timeId, tipo: TipoMarcacaoEvento.tempo, valor: ms, usuarioId: usuarioAtual!.id));
    notifyListeners();
  }

  void ajustarTempo(Partida p, String timeId, int ms, String justificativa) {
    p.tempos[timeId] = ms;
    p.marcacoes.add(
      Marcacao(
        timeId: timeId,
        tipo: TipoMarcacaoEvento.ajuste,
        valor: ms,
        usuarioId: usuarioAtual!.id,
        justificativa: justificativa,
      ),
    );
    _log('Ajustou tempo de ${time(timeId).nome} para ${formatarTempo(ms)}: $justificativa');
    notifyListeners();
  }

  RegraEmpate regraEmpate(Partida p) {
    final f = fase(p.faseId);
    final m = modalidade(f.modalidadeId);
    return f.valePontos ? m.regraEmpatePontuada : m.regraEmpateEliminatoria;
  }

  /// Fase eliminatória sempre exige vencedor; fase pontuada só se a regra não aceitar empate.
  bool exigeDesempate(Partida p) {
    final m = modalidadeDaPartida(p);
    if (m.tipo != TipoMarcacao.placar || p.timeIds.length != 2) return false;
    final a = p.placar[p.timeIds[0]] ?? 0, b = p.placar[p.timeIds[1]] ?? 0;
    if (a != b) return false;
    final f = fase(p.faseId);
    if (!f.valePontos) return true;
    return regraEmpate(p) != RegraEmpate.empateAceito;
  }

  /// Calcula a classificação proposta, sem gravar (RF038).
  ({List<String> ordem, bool empate}) calcularResultado(Partida p, {Map<String, int>? desempate}) {
    final m = modalidadeDaPartida(p);
    if (m.tipo == TipoMarcacao.tempo) {
      final ordem = List.of(p.timeIds)..sort((a, b) => (p.tempos[a] ?? 1 << 40).compareTo(p.tempos[b] ?? 1 << 40));
      return (ordem: ordem, empate: false);
    }
    final ordem = List.of(p.timeIds)..sort((a, b) => (p.placar[b] ?? 0).compareTo(p.placar[a] ?? 0));
    final empatado = ordem.length == 2 && p.placar[ordem[0]] == p.placar[ordem[1]];
    if (!empatado) return (ordem: ordem, empate: false);
    final d = desempate ?? (p.placarDesempate.isEmpty ? null : p.placarDesempate);
    if (d != null && d[ordem[0]] != d[ordem[1]]) {
      ordem.sort((a, b) => (d[b] ?? 0).compareTo(d[a] ?? 0));
      return (ordem: ordem, empate: false);
    }
    return (ordem: ordem, empate: true);
  }

  void encerrarPartida(Partida p, {Map<String, int>? desempate}) {
    if (desempate != null) {
      p.placarDesempate
        ..clear()
        ..addAll(desempate);
      for (final e in desempate.entries) {
        p.marcacoes.add(
          Marcacao(timeId: e.key, tipo: TipoMarcacaoEvento.desempate, valor: e.value, usuarioId: usuarioAtual!.id),
        );
      }
    }
    final r = calcularResultado(p);
    p.classificacao = r.ordem;
    p.empate = r.empate;
    p.status = StatusPartida.encerrada;
    _gerarPontuacao(p);
    _log('Encerrou ${tituloPartida(p)}');
    notifyListeners();
  }

  /// Nova partida em caso de empate (RF037).
  void agendarNovaPartida(Partida p) {
    p.status = StatusPartida.encerrada;
    p.empate = true;
    p.classificacao = List.of(p.timeIds);
    final f = fase(p.faseId);
    partidas.add(
      Partida(
        id: _id('p'),
        faseId: f.id,
        timeIds: List.of(p.timeIds),
        arbitroIds: List.of(p.arbitroIds),
        dataHora: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
    _log('Empate em ${tituloPartida(p)}: nova partida agendada');
    notifyListeners();
  }

  // ---------------------------------------------------------------- correção (admin)

  void corrigirResultado(Partida p, {Map<String, int>? placar, Map<String, int>? tempos, Map<String, int>? desempate}) {
    for (final pt in pontuacoes.where((x) => x.partidaId == p.id)) {
      pt.cancelada = true;
    }
    if (placar != null) p.placar.addAll(placar);
    if (tempos != null) p.tempos.addAll(tempos);
    p.placarDesempate.clear();
    if (desempate != null) p.placarDesempate.addAll(desempate);
    final r = calcularResultado(p);
    p.classificacao = r.ordem;
    p.empate = r.empate;
    _gerarPontuacao(p);
    _log('Corrigiu o resultado de ${tituloPartida(p)}');
    notifyListeners();
  }

  void cancelarResultado(Partida p) {
    for (final pt in pontuacoes.where((x) => x.partidaId == p.id)) {
      pt.cancelada = true;
    }
    p.status = StatusPartida.agendada;
    p.classificacao = [];
    p.empate = false;
    p.placar.updateAll((_, _) => 0);
    p.placarDesempate.clear();
    p.tempos.clear();
    p.marcacoes.clear();
    p.escalacao.clear();
    _log('Cancelou o resultado de ${tituloPartida(p)}');
    notifyListeners();
  }

  void _gerarPontuacao(Partida p) {
    final f = fase(p.faseId);
    if (!f.valePontos) return; // RN004
    final m = modalidade(f.modalidadeId);
    final uid = usuarioAtual?.id ?? 'u1';
    if (m.tipo == TipoMarcacao.placar) {
      for (final t in p.timeIds) {
        final int base;
        final String desc;
        if (p.empate) {
          base = m.pontosEmpate;
          desc = 'Empate';
        } else if (p.classificacao.first == t) {
          base = m.pontosVitoria;
          desc = 'Vitória';
        } else {
          base = m.pontosDerrota;
          desc = 'Derrota';
        }
        pontuacoes.add(
          Pontuacao(
            partidaId: p.id,
            modalidadeId: m.id,
            equipeId: time(t).equipeId,
            valor: base * m.peso,
            descricao: '${m.nome} · ${f.nome}: $desc (${time(t).nome})',
            usuarioId: uid,
          ),
        );
      }
    } else {
      for (var i = 0; i < p.classificacao.length; i++) {
        final t = p.classificacao[i];
        final base = i < m.pontosColocacao.length ? m.pontosColocacao[i] : 0;
        pontuacoes.add(
          Pontuacao(
            partidaId: p.id,
            modalidadeId: m.id,
            equipeId: time(t).equipeId,
            valor: base * m.peso,
            descricao: '${m.nome} · ${f.nome}: ${i + 1}º lugar (${time(t).nome})',
            usuarioId: uid,
          ),
        );
      }
    }
  }

  void _log(String acao) => logs.insert(0, LogAuditoria(usuarioAtual?.id ?? 'u1', acao));

  // ---------------------------------------------------------------- mock

  void _carregarMock() {
    const nomes = [
      'Ana Souza', 'Bruno Lima', 'Carla Mendes', 'Diego Rocha', 'Elisa Prado', 'Fábio Nunes', //
      'Gabriel Alves', 'Helena Costa', 'Igor Martins', 'Júlia Ramos', 'Lucas Ferreira', 'Marina Dias',
      'Nicolas Pereira', 'Olívia Santos', 'Paulo Gomes', 'Rafaela Lopes', 'Samuel Ribeiro', 'Tatiane Melo',
      'Vitor Cardoso', 'Yasmin Teixeira', 'André Barbosa', 'Beatriz Moura', 'Caio Fernandes', 'Débora Pinto',
      'Eduardo Araújo', 'Fernanda Castro', 'Gustavo Rezende', 'Isabela Monteiro', 'João Pedro Silva',
      'Larissa Duarte', 'Mateus Correia', 'Natália Freitas', 'Otávio Batista', 'Priscila Vieira',
      'Renan Campos', 'Sofia Azevedo', 'Thiago Moreira', 'Vanessa Cunha',
    ];
    for (var i = 0; i < nomes.length; i++) {
      usuarios.add(Usuario('u${i + 1}', nomes[i]));
    }
    // Completa a base até ~500 pessoas do acampamento com nomes gerados (determinístico).
    const primeiros = [
      'Adriana', 'Alice', 'Amanda', 'Ana Clara', 'Ana Luiza', 'Arthur', 'Benício', 'Bernardo', 'Bianca', 'Bruna', //
      'Camila', 'Carlos', 'Cecília', 'Clara', 'Daniel', 'Davi', 'Eduarda', 'Elias', 'Emanuel', 'Enzo',
      'Esther', 'Felipe', 'Gabriela', 'Giovana', 'Guilherme', 'Heitor', 'Henrique', 'Isaac', 'Isadora', 'Jéssica',
      'Joana', 'João Miguel', 'Joaquim', 'Jonas', 'Laura', 'Lívia', 'Lorena', 'Luana', 'Lucca', 'Luíza',
      'Manuela',
      'Marcelo',
      'Maria Eduarda',
      'Mariana',
      'Melissa',
      'Miguel',
      'Murilo',
      'Noah',
      'Pedro Henrique',
      'Pietra',
      'Rafael', 'Raquel', 'Rebeca', 'Ricardo', 'Rodrigo', 'Sara', 'Sophia', 'Tiago', 'Valentina', 'Vinícius',
    ];
    const sobrenomes = [
      'Almeida', 'Andrade', 'Antunes', 'Barros', 'Bastos', 'Borges', 'Brandão', 'Cabral', 'Camargo', 'Carvalho', //
      'Coelho', 'Cordeiro', 'Costa', 'Cruz', 'Dantas', 'Farias', 'Figueiredo', 'Fonseca', 'Garcia', 'Gonçalves',
      'Guimarães', 'Lacerda', 'Leite', 'Lima', 'Macedo', 'Machado', 'Magalhães', 'Marques', 'Matos', 'Medeiros',
      'Miranda', 'Morais', 'Nascimento', 'Neves', 'Nogueira', 'Oliveira', 'Pacheco', 'Paiva', 'Peixoto', 'Prado',
      'Queiroz', 'Rangel', 'Rocha', 'Rodrigues', 'Sales', 'Sampaio', 'Siqueira', 'Soares', 'Tavares', 'Toledo',
    ];
    const totalUsuarios = 506;
    final usados = nomes.toSet();
    var k = 0;
    while (usuarios.length < totalUsuarios) {
      final nome =
          '${primeiros[(k * 7) % primeiros.length]} ${sobrenomes[(k * 11 + k ~/ primeiros.length) % sobrenomes.length]}';
      k++;
      if (usados.add(nome)) usuarios.add(Usuario('u${usuarios.length + 1}', nome));
    }
    String u(int n) => 'u$n';

    // Gincana principal: participantes u7..u30 (12 por equipe), divididos pelo sistema existente.
    // Sede: 480 participantes (240 por equipe), divididos alternadamente pelo "sistema existente".
    final sede = [for (var i = 7; i <= 30; i++) u(i), for (var i = 39; i <= 494; i++) u(i)];
    final azul = Equipe('e1', 'Equipe Azul', const Color(0xFF1F5FD1), [
      for (var i = 0; i < sede.length; i += 2) sede[i],
    ]);
    final verm = Equipe('e2', 'Equipe Vermelha', const Color(0xFFD13B2F), [
      for (var i = 1; i < sede.length; i += 2) sede[i],
    ]);
    final g1 = Gincana(
      id: 'g1',
      nome: '1ª Semana',
      local: nomeLocal,
      inicio: DateTime(2026, 11, 21),
      fim: DateTime(2026, 11, 26),
      equipes: [azul, verm],
      divisaoRecebidaEm: DateTime(2026, 11, 20, 18, 30),
    );
    // 2ª Semana: divisão já recebida (amostra pequena de 20 participantes).
    final serra = [for (var i = 31; i <= 38; i++) u(i), for (var i = 495; i <= totalUsuarios; i++) u(i)];
    final verde = Equipe('e3', 'Equipe Azul', const Color(0xFF1F5FD1), [
      for (var i = 0; i < serra.length; i += 2) serra[i],
    ]);
    final amar = Equipe('e4', 'Equipe Vermelha', const Color(0xFFD13B2F), [
      for (var i = 1; i < serra.length; i += 2) serra[i],
    ]);
    final g2 = Gincana(
      id: 'g2',
      nome: '2ª Semana',
      local: nomeLocal,
      inicio: DateTime(2026, 11, 28),
      fim: DateTime(2026, 12, 3),
      equipes: [verde, amar],
      divisaoRecebidaEm: DateTime(2026, 11, 27, 19, 0),
    );
    // 3ª Semana: cadastrada, aguardando a divisão das equipes.
    final g3 = Gincana(
      id: 'g3',
      nome: '3ª Semana',
      local: nomeLocal,
      inicio: DateTime(2026, 12, 5),
      fim: DateTime(2026, 12, 10),
      equipes: [
        Equipe('e5', 'Equipe Azul', const Color(0xFF1F5FD1), []),
        Equipe('e6', 'Equipe Vermelha', const Color(0xFFD13B2F), []),
      ],
    );
    gincanas.addAll([g1, g2, g3]);

    perfis.addAll([
      PerfilGincana(u(1), 'g1', Perfil.administrador),
      PerfilGincana(u(2), 'g1', Perfil.administrador),
      PerfilGincana(u(3), 'g1', Perfil.lider, 'e1'),
      PerfilGincana(u(4), 'g1', Perfil.lider, 'e2'),
      PerfilGincana(u(1), 'g2', Perfil.administrador),
      PerfilGincana(u(5), 'g2', Perfil.lider, 'e3'),
      PerfilGincana(u(6), 'g2', Perfil.lider, 'e4'),
      PerfilGincana(u(2), 'g2', Perfil.administrador),
      PerfilGincana(u(1), 'g3', Perfil.administrador),
      PerfilGincana(u(2), 'g3', Perfil.administrador),
    ]);

    final az = azul.participantes, vm = verm.participantes;
    // Partidas distribuídas no calendário da gincana: dia(0) = Sáb 21/11, dia(1) = Dom 22/11...
    DateTime dia(int d, int h, [int m = 0]) => DateTime(2026, 11, 21 + d, h, m);

    // --- Futebol Adulto: 2 times por equipe, eliminatória sem pontos + final.
    final fut = Modalidade(
      id: 'm1',
      gincanaId: 'g1',
      nome: 'Futebol Adulto',
      categoria: 'Esporte coletivo',
      tipo: TipoMarcacao.placar,
      unidade: 'gol',
      peso: 2,
      regraEmpateEliminatoria: RegraEmpate.penaltis,
      regraEmpatePontuada: RegraEmpate.penaltis,
    );
    modalidades.add(fut);
    final tAzA = Time('t1', 'm1', 'e1', 'Azul A', az.sublist(0, 5));
    final tAzB = Time('t2', 'm1', 'e1', 'Azul B', az.sublist(5, 10));
    final tVmA = Time('t3', 'm1', 'e2', 'Vermelho A', vm.sublist(0, 5));
    final tVmB = Time('t4', 'm1', 'e2', 'Vermelho B', vm.sublist(5, 10));
    times.addAll([tAzA, tAzB, tVmA, tVmB]);
    inscricoes['m1'] = {...az.sublist(0, 10), ...vm.sublist(0, 11)};
    final fElim = Fase('f1', 'm1', 'Eliminatória', 1, false);
    final fFinal = Fase('f2', 'm1', 'Final', 2, true);
    fases.addAll([fElim, fFinal]);
    final p1 = Partida(id: 'p1', faseId: 'f1', timeIds: ['t1', 't2'], arbitroIds: [u(2)], dataHora: dia(0, 8));
    p1.placar.addAll({'t1': 3, 't2': 1});
    final p2 = Partida(id: 'p2', faseId: 'f1', timeIds: ['t3', 't4'], arbitroIds: [u(2)], dataHora: dia(0, 9));
    p2.placar.addAll({'t3': 2, 't4': 2});
    p2.placarDesempate.addAll({'t3': 4, 't4': 5});
    final p3 = Partida(id: 'p3', faseId: 'f2', timeIds: ['t1', 't4'], arbitroIds: [u(2), u(1)], dataHora: dia(2, 16));
    partidas.addAll([p1, p2, p3]);

    // --- Ping-pong: placar por pontos, 1 jogador por equipe.
    final ping = Modalidade(
      id: 'm2',
      gincanaId: 'g1',
      nome: 'Ping-pong Misto',
      categoria: 'Esporte individual',
      tipo: TipoMarcacao.placar,
      unidade: 'ponto',
      pontosVitoria: 60,
      pontosEmpate: 30,
      regraEmpatePontuada: RegraEmpate.prorrogacao,
    );
    modalidades.add(ping);
    times.addAll([
      Time('t5', 'm2', 'e1', 'Azul — ${usuario(az[5]).nome}', [az[5]]),
      Time('t6', 'm2', 'e2', 'Vermelho — ${usuario(vm[10]).nome}', [vm[10]]),
    ]);
    inscricoes['m2'] = {az[5], vm[10]};
    fases.add(Fase('f3', 'm2', 'Final', 1, true));
    final p4 = Partida(id: 'p4', faseId: 'f3', timeIds: ['t5', 't6'], arbitroIds: [u(1)], dataHora: dia(0, 10));
    p4.placar.addAll({'t5': 21, 't6': 18});
    partidas.add(p4);

    // --- Canoagem: tempo, 2 barcos por equipe.
    final cano = Modalidade(
      id: 'm3',
      gincanaId: 'g1',
      nome: 'Canoagem Dupla',
      categoria: 'Esporte aquático',
      tipo: TipoMarcacao.tempo,
      pontosColocacao: [100, 70, 40, 20],
      peso: 1.5,
    );
    modalidades.add(cano);
    times.addAll([
      Time('t7', 'm3', 'e1', 'Barco Azul 1', [az[0], az[11]]),
      Time('t8', 'm3', 'e1', 'Barco Azul 2', [az[2], az[3]]),
      Time('t9', 'm3', 'e2', 'Barco Vermelho 1', [vm[0], vm[11]]),
      Time('t10', 'm3', 'e2', 'Barco Vermelho 2', [vm[2], vm[3]]),
    ]);
    inscricoes['m3'] = {az[0], az[11], az[2], az[3], vm[0], vm[11], vm[2], vm[3]};
    fases.add(Fase('f4', 'm3', 'Final', 1, true));
    partidas.add(
      Partida(
        id: 'p5',
        faseId: 'f4',
        timeIds: ['t7', 't8', 't9', 't10'],
        arbitroIds: [u(1), u(2)],
        dataHora: dia(3, 14),
      ),
    );

    // --- Vôlei Feminino: placar por sets.
    final volei = Modalidade(
      id: 'm4',
      gincanaId: 'g1',
      nome: 'Vôlei Feminino',
      categoria: 'Esporte coletivo',
      tipo: TipoMarcacao.placar,
      unidade: 'set',
    );
    modalidades.add(volei);
    times.addAll([
      Time('t11', 'm4', 'e1', 'Azul', az.sublist(4, 10)),
      Time('t12', 'm4', 'e2', 'Vermelho', vm.sublist(4, 10)),
    ]);
    inscricoes['m4'] = {...az.sublist(4, 10), ...vm.sublist(4, 10)};
    fases.add(Fase('f5', 'm4', 'Final', 1, true));
    final p6 = Partida(id: 'p6', faseId: 'f5', timeIds: ['t11', 't12'], arbitroIds: [u(2)], dataHora: dia(0, 11));
    p6.placar.addAll({'t11': 2, 't12': 1});
    partidas.add(p6);

    // --- Maratona Bíblica: cadastrada, ainda sem times/fases.
    modalidades.add(
      Modalidade(
        id: 'm5',
        gincanaId: 'g1',
        nome: 'Maratona Bíblica',
        categoria: 'Cultural / Bíblica',
        tipo: TipoMarcacao.placar,
        unidade: 'ponto',
        pontosVitoria: 150,
        peso: 3,
      ),
    );

    // --- Gincana da Serra
    modalidades.add(
      Modalidade(
        id: 'm6',
        gincanaId: 'g2',
        nome: 'Futebol Adulto',
        categoria: 'Esporte coletivo',
        tipo: TipoMarcacao.placar,
        unidade: 'gol',
      ),
    );
    times.addAll([
      Time('t13', 'm6', 'e3', 'Verde', verde.participantes),
      Time('t14', 'm6', 'e4', 'Amarelo', amar.participantes),
    ]);
    fases.add(Fase('f6', 'm6', 'Final', 1, true));
    partidas.add(
      Partida(
        id: 'p7',
        faseId: 'f6',
        timeIds: ['t13', 't14'],
        arbitroIds: [u(2)],
        dataHora: DateTime(2026, 11, 30, 15),
      ),
    );

    // Quantidade de participantes por time (RF070).
    void qtd(String id, int? n, [int reservas = 0]) => modalidade(id)
      ..participantesPorTime = n
      ..reservas = reservas;
    qtd('m1', 5, 2); // Futebol: 5 titulares + 2 reservas
    qtd('m2', 1); // Ping-pong: individual
    qtd('m3', 2); // Canoagem: dupla
    qtd('m4', 6, 2); // Vôlei: 6 + 2 reservas
    qtd('m5', null); // Maratona Bíblica: toda a equipe
    qtd('m6', 4); // Serra: futebol de 4

    // Inscrições extras (sem time ainda) para o restante dos participantes da Sede,
    // deixando parte deles sem nenhuma inscrição.
    for (final eqLista in [az, vm]) {
      for (var i = 12; i < eqLista.length; i++) {
        final uid = eqLista[i];
        if ((i * 37 + 11) % 100 < 18) inscricoes['m1']!.add(uid);
        if ((i * 53 + 5) % 100 < 6) inscricoes['m2']!.add(uid);
        if ((i * 29 + 3) % 100 < 10) inscricoes['m3']!.add(uid);
        if ((i * 41 + 7) % 100 < 14) inscricoes['m4']!.add(uid);
        if ((i * 17 + 13) % 100 < 25) inscricoes.putIfAbsent('m5', () => {}).add(uid);
      }
    }

    // Encerra as partidas já jogadas, gerando pontuação.
    for (final p in [p1, p2, p4, p6]) {
      for (final t in p.timeIds) {
        p.escalacao[t] = List.of(time(t).integrantes);
      }
      final r = calcularResultado(p);
      p.classificacao = r.ordem;
      p.empate = r.empate;
      p.status = StatusPartida.encerrada;
      _gerarPontuacao(p);
    }
    logs.add(LogAuditoria('u1', 'Divisão das equipes recebida do sistema existente'));
  }
}

class ResultadoModalidade {
  final Modalidade modalidade;
  final String? timeId;
  final Partida? partida;
  final String detalhe;
  ResultadoModalidade(this.modalidade, this.timeId, this.partida, this.detalhe);
}

String formatarTempo(int ms) {
  final min = ms ~/ 60000;
  final seg = (ms % 60000) ~/ 1000;
  final cent = (ms % 1000) ~/ 10;
  return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}.${cent.toString().padLeft(2, '0')}';
}

const _diasSemana = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
String diaSemana(DateTime d) => _diasSemana[d.weekday - 1];
String formatarDiaCurto(DateTime d) =>
    '${diaSemana(d)} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
bool mesmoDia(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String formatarPontos(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

String formatarHora(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String formatarData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class AppScope extends InheritedNotifier<AppStore> {
  const AppScope({super.key, required AppStore store, required super.child}) : super(notifier: store);

  static AppStore of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
