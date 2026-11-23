import 'dart:async';

import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import '../admin/partida_detalhe.dart' show descreverMarcacao, lerTempo;

/// Tela de arbitragem (RF031–RF038): placar ao vivo ou cronômetro.
class ArbitragemScreen extends StatelessWidget {
  final String partidaId;
  const ArbitragemScreen(this.partidaId, {super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = store.partidas.where((x) => x.id == partidaId).firstOrNull;
    if (p == null) return const Scaffold();
    final f = store.fase(p.faseId);
    final m = store.modalidade(f.modalidadeId);
    final placar = m.tipo == TipoMarcacao.placar;

    final Widget corpo;
    if (p.status == StatusPartida.agendada) {
      corpo = _PreInicio(p);
    } else if (placar) {
      corpo = _PlacarView(p);
    } else {
      corpo = _TempoView(p);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${m.nome} · ${f.nome}'),
            Text(placar ? 'Placar · ${m.unidade}' : 'Tempo · cronômetro', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        actions: [Padding(padding: const EdgeInsets.only(right: 12), child: StatusBadge(p.status))],
      ),
      body: corpo,
    );
  }
}

// ------------------------------------------------------------------ antes de iniciar

class _PreInicio extends StatelessWidget {
  final Partida p;
  const _PreInicio(this.p);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return PageBody(
      maxWidth: 640,
      children: [
        SectionCard(
          title: store.tituloPartida(p),
          subtitle:
              'Agendada para ${formatarDiaCurto(p.dataHora)} ${formatarHora(p.dataHora)} · '
              'escalação definida pelos Líderes das equipes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final tid in p.timeIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EquipeLabel(
                        store.equipe(store.time(tid).equipeId),
                        texto: store.time(tid).nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      if (store.time(tid).integrantes.isEmpty)
                        const Tag('Aguardando o Líder escalar', icon: Icons.hourglass_top, color: Color(0xFFB26A00))
                      else
                        Builder(
                          builder: (context) {
                            final tm = store.time(tid);
                            final n = store.modalidade(tm.modalidadeId).participantesPorTime;
                            final tit = store.titularesDe(tm), res = store.reservasDe(tm);
                            final st = Theme.of(context).textTheme.bodySmall;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${n == null ? '' : 'Titulares: '}${tit.map((u) => store.usuario(u).nome).join(', ')}',
                                  style: st,
                                ),
                                if (res.isNotEmpty)
                                  Text('Reservas: ${res.map((u) => store.usuario(u).nome).join(', ')}', style: st),
                                if (n != null && tit.length < n)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Tag(
                                      'Incompleto: ${tit.length} de $n titulares',
                                      icon: Icons.warning_amber,
                                      color: const Color(0xFFB26A00),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (store.gincanaAtual!.encerrada)
          const InfoBanner('A gincana foi finalizada. Não é possível iniciar novas partidas.', icon: Icons.flag)
        else
          const InfoBanner(
            'Ao iniciar, a escalação dos times fica travada e o Líder não pode mais alterá-la (RN017).',
            icon: Icons.lock_outline,
          ),
        SizedBox(
          height: 64,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text('Iniciar partida'),
            onPressed: store.gincanaAtual!.encerrada ? null : () => store.iniciarPartida(p),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ placar

class _PlacarView extends StatelessWidget {
  final Partida p;
  const _PlacarView(this.p);

  Future<void> _encerrar(BuildContext context) async {
    final store = AppScope.of(context);
    Map<String, int>? desempate;
    if (store.exigeDesempate(p)) {
      final regra = store.regraEmpate(p);
      switch (regra) {
        case RegraEmpate.prorrogacao:
          await showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Empate — prorrogação'),
              content: const Text(
                'A regra desta modalidade é prorrogação. Continue marcando no placar durante a prorrogação e encerre de novo ao final.',
              ),
              actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Entendi'))],
            ),
          );
          return;
        case RegraEmpate.novaPartida:
          if (await confirmar(
            context,
            'Empate — nova partida',
            'A regra desta modalidade é jogar uma nova partida. Esta será encerrada como empate e outra será agendada.',
            ok: 'Agendar nova partida',
          )) {
            store.agendarNovaPartida(p);
            if (context.mounted) {
              Navigator.pop(context);
              mostrarMensagem(context, 'Nova partida agendada');
            }
          }
          return;
        case RegraEmpate.penaltis:
        case RegraEmpate.empateAceito:
          if (!context.mounted) return;
          desempate = await showDialog<Map<String, int>>(context: context, builder: (_) => _DesempateDialog(p));
          if (desempate == null) return;
      }
    }
    if (!context.mounted) return;
    final r = store.calcularResultado(p, desempate: desempate);
    final texto = r.empate ? 'Resultado: empate.' : 'Vencedor: ${store.time(r.ordem.first).nome}.';
    final ok = await confirmar(
      context,
      'Confirmar resultado',
      '$texto\n\nPlacar: ${p.timeIds.map((t) => '${store.time(t).nome} ${p.placar[t]}').join(' × ')}'
          '${desempate != null ? '\nDesempate: ${p.timeIds.map((t) => desempate![t]).join(' × ')}' : ''}'
          '\n\nDepois de confirmado, correções só pelo menu Administração › Partidas.',
      ok: 'Confirmar e encerrar',
    );
    if (ok) store.encerrarPartida(p, desempate: desempate);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final ativo = p.status == StatusPartida.emAndamento;
    final m = store.modalidadeDaPartida(p);
    return PageBody(
      maxWidth: 900,
      children: [
        if (p.status == StatusPartida.encerrada) _ResultadoFinal(p),
        LayoutBuilder(
          builder: (context, c) {
            final lados = [for (final t in p.timeIds) _LadoPlacar(p, t, ativo: ativo, unidade: m.unidade)];
            if (c.maxWidth < 560) {
              return Column(children: [lados[0], const SizedBox(height: 12), lados[1]]);
            }
            return Row(
              children: [
                Expanded(child: lados[0]),
                const SizedBox(width: 12),
                Expanded(child: lados[1]),
              ],
            );
          },
        ),
        if (p.placarDesempate.isNotEmpty)
          Center(
            child: Tag(
              'Desempate: ${p.timeIds.map((t) => p.placarDesempate[t]).join(' × ')}',
              icon: Icons.sports_score,
            ),
          ),
        if (ativo)
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF263238)),
              icon: const Icon(Icons.flag),
              label: const Text('Encerrar partida', style: TextStyle(fontSize: 16)),
              onPressed: () => _encerrar(context),
            ),
          ),
        _Timeline(p, podeDesfazer: ativo),
      ],
    );
  }
}

class _LadoPlacar extends StatelessWidget {
  final Partida p;
  final String timeId;
  final bool ativo;
  final String unidade;
  const _LadoPlacar(this.p, this.timeId, {required this.ativo, required this.unidade});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final t = store.time(timeId);
    final e = store.equipe(t.equipeId);
    final venceu = p.vencedorId == timeId;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: e.cor,
        borderRadius: BorderRadius.circular(20),
        border: venceu ? Border.all(color: const Color(0xFFFFC83D), width: 4) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (venceu) const Icon(Icons.emoji_events, color: Color(0xFFFFE07A)),
              if (venceu) const SizedBox(width: 6),
              Flexible(
                child: Text(
                  t.nome,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Text(
            '${p.placar[timeId] ?? 0}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 112,
              height: 1.1,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (ativo)
            Row(
              children: [
                IconButton.filledTonal(
                  iconSize: 28,
                  tooltip: 'Retirar 1',
                  onPressed: (p.placar[timeId] ?? 0) == 0 ? null : () => store.marcarPonto(p, timeId, -1),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: e.cor,
                        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      onPressed: () => store.marcarPonto(p, timeId, 1),
                      icon: const Icon(Icons.add, size: 28),
                      label: Text(unidade),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DesempateDialog extends StatefulWidget {
  final Partida p;
  const _DesempateDialog(this.p);

  @override
  State<_DesempateDialog> createState() => _DesempateDialogState();
}

class _DesempateDialogState extends State<_DesempateDialog> {
  late final Map<String, int> _v = {for (final t in widget.p.timeIds) t: 0};

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final iguais = _v.values.toSet().length == 1;
    return AlertDialog(
      title: const Text('Empate — desempate'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Esta fase exige um vencedor. Registre o placar do desempate (${store.regraEmpate(widget.p).label}).'),
          const SizedBox(height: 16),
          for (final t in widget.p.timeIds)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  EquipeDot(store.equipe(store.time(t).equipeId).cor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(store.time(t).nome)),
                  IconButton(
                    onPressed: _v[t]! > 0 ? () => setState(() => _v[t] = _v[t]! - 1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${_v[t]}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _v[t] = _v[t]! + 1),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
            ),
          if (iguais)
            Text('O desempate precisa ter um vencedor.', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Voltar')),
        FilledButton(onPressed: iguais ? null : () => Navigator.pop(context, _v), child: const Text('Continuar')),
      ],
    );
  }
}

// ------------------------------------------------------------------ cronômetro

class _TempoView extends StatefulWidget {
  final Partida p;
  const _TempoView(this.p);

  @override
  State<_TempoView> createState() => _TempoViewState();
}

/// Cronômetro por bateria (RF034/RF035): o árbitro seleciona os participantes que vão largar,
/// eles ficam em destaque e o cronômetro marca o tempo só para eles.
class _TempoViewState extends State<_TempoView> {
  // O cronômetro roda localmente no dispositivo (RNF012).
  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;

  /// Participantes da bateria atual (selecionados pelo árbitro).
  final Set<String> _bateria = {};
  int _numBateria = 1;

  Partida get p => widget.p;
  bool get _emProva => _sw.elapsedMilliseconds > 0 || _sw.isRunning;
  List<String> get _faltandoNaBateria => _bateria.where((t) => p.tempos[t] == null).toList();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _alternarSelecao(String timeId) {
    if (_emProva || p.tempos[timeId] != null) return;
    setState(() => _bateria.contains(timeId) ? _bateria.remove(timeId) : _bateria.add(timeId));
  }

  void _largar() {
    if (_bateria.isEmpty) return;
    _sw.start();
    _ticker ??= Timer.periodic(const Duration(milliseconds: 31), (_) => setState(() {}));
    setState(() {});
  }

  void _pausar() => setState(_sw.stop);

  void _fecharBateria() {
    _sw
      ..stop()
      ..reset();
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _bateria.clear();
      _numBateria++;
    });
  }

  /// Registra a chegada de um participante da bateria; fecha a bateria quando todos chegam.
  void _chegada(String timeId) {
    final store = AppScope.of(context);
    store.registrarTempo(p, timeId, _sw.elapsedMilliseconds);
    if (_faltandoNaBateria.isEmpty) {
      _fecharBateria();
      mostrarMensagem(context, 'Bateria concluída. Selecione os próximos participantes.');
    }
  }

  /// Parar: atribui o tempo atual aos participantes da bateria que ainda não chegaram.
  Future<void> _parar() async {
    final store = AppScope.of(context);
    final ms = _sw.elapsedMilliseconds;
    _sw.stop();
    final faltando = _faltandoNaBateria;
    if (faltando.length > 1 &&
        !await confirmar(
          context,
          'Parar cronômetro',
          'Registrar ${formatarTempo(ms)} para ${faltando.map((t) => store.time(t).nome).join(', ')}?',
          ok: 'Registrar',
        )) {
      return;
    }
    for (final t in faltando) {
      store.registrarTempo(p, t, ms);
    }
    _fecharBateria();
  }

  Future<void> _cancelarBateria() async {
    if (!await confirmar(
      context,
      'Cancelar bateria',
      'O cronômetro será zerado e os participantes que ainda não chegaram voltam para a lista, sem tempo.',
      ok: 'Cancelar bateria',
    )) {
      return;
    }
    _fecharBateria();
    setState(() => _numBateria--);
  }

  Future<void> _ajustar(String timeId) async {
    final store = AppScope.of(context);
    final tempo = TextEditingController(text: formatarTempo(p.tempos[timeId] ?? _sw.elapsedMilliseconds));
    final just = TextEditingController();
    String? erro;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text('Ajustar tempo — ${store.time(timeId).nome}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tempo,
                decoration: const InputDecoration(labelText: 'Tempo (mm:ss.cc)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: just,
                decoration: const InputDecoration(labelText: 'Justificativa (obrigatória)'),
              ),
              if (erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(erro!, style: TextStyle(color: Theme.of(c).colorScheme.error)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final ms = lerTempo(tempo.text);
                if (ms == null) return set(() => erro = 'Use o formato mm:ss.cc');
                if (just.text.trim().isEmpty) return set(() => erro = 'Informe a justificativa (RF036).');
                store.ajustarTempo(p, timeId, ms, just.text.trim());
                Navigator.pop(c);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _encerrar() async {
    final store = AppScope.of(context);
    final faltando = p.timeIds.where((t) => p.tempos[t] == null).toList();
    if (faltando.isNotEmpty &&
        !await confirmar(
          context,
          'Participantes sem tempo',
          '${faltando.map((t) => store.time(t).nome).join(', ')} ainda não têm tempo e ficarão nas últimas colocações.',
          ok: 'Continuar',
        )) {
      return;
    }
    if (!mounted) return;
    final r = store.calcularResultado(p);
    final ok = await confirmar(
      context,
      'Confirmar classificação',
      [
        for (var i = 0; i < r.ordem.length; i++)
          '${i + 1}º  ${store.time(r.ordem[i]).nome}  ${p.tempos[r.ordem[i]] != null ? formatarTempo(p.tempos[r.ordem[i]]!) : 'sem tempo'}',
      ].join('\n'),
      ok: 'Confirmar e encerrar',
    );
    if (ok) {
      _sw.stop();
      _ticker?.cancel();
      _ticker = null;
      store.encerrarPartida(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final ativo = p.status == StatusPartida.emAndamento;
    final ms = _sw.elapsedMilliseconds;
    final rodando = _sw.isRunning;
    final ordem = p.status == StatusPartida.encerrada ? p.classificacao : p.timeIds;
    final pendentes = p.timeIds.where((t) => p.tempos[t] == null).toList();
    final nomesBateria = _bateria.map((t) => store.time(t).nome).join(', ');

    return PageBody(
      maxWidth: 760,
      children: [
        if (p.status == StatusPartida.encerrada) _ResultadoFinal(p),
        if (ativo)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFF102A43), borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Text(
                  _bateria.isEmpty
                      ? (pendentes.isEmpty
                            ? 'Todos os participantes já têm tempo'
                            : 'Bateria $_numBateria · selecione quem vai largar')
                      : 'Bateria $_numBateria · $nomesBateria',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
                FittedBox(
                  child: Text(
                    formatarTempo(ms),
                    style: TextStyle(
                      color: rodando ? const Color(0xFF7CFFB2) : Colors.white,
                      fontSize: 88,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (!rodando)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1B9E55),
                          disabledBackgroundColor: Colors.white12,
                          disabledForegroundColor: Colors.white38,
                          minimumSize: const Size(150, 52),
                        ),
                        onPressed: _bateria.isEmpty ? null : _largar,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(ms == 0 ? 'Largada' : 'Retomar'),
                      )
                    else
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE0A100),
                          minimumSize: const Size(140, 52),
                        ),
                        onPressed: _pausar,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pausar'),
                      ),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(110, 52),
                        disabledBackgroundColor: Colors.white12,
                        disabledForegroundColor: Colors.white38,
                      ),
                      onPressed: ms == 0 ? null : _parar,
                      icon: const Icon(Icons.stop),
                      label: const Text('Parar'),
                    ),
                    if (_emProva)
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: Colors.white70, minimumSize: const Size(110, 52)),
                        onPressed: _cancelarBateria,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Cancelar bateria'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        if (ativo)
          InfoBanner(
            _emProva
                ? 'Toque no participante em destaque quando ele cruzar a linha. "Parar" registra o tempo atual para quem ainda não chegou.'
                : 'Toque nos participantes que vão largar nesta bateria (um ou vários). Eles ficam em destaque e o cronômetro marca o tempo só para eles.',
            icon: Icons.tips_and_updates_outlined,
          ),
        SectionCard(
          title: p.status == StatusPartida.encerrada ? 'Classificação' : 'Participantes',
          subtitle: ativo ? '${p.timeIds.length - pendentes.length} de ${p.timeIds.length} com tempo' : null,
          child: Column(children: [for (var i = 0; i < ordem.length; i++) _cartao(context, store, ordem[i], i, ativo)]),
        ),
        if (ativo)
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF263238)),
              icon: const Icon(Icons.flag),
              label: const Text('Encerrar prova', style: TextStyle(fontSize: 16)),
              onPressed: _emProva ? null : _encerrar,
            ),
          ),
        _Timeline(p, podeDesfazer: false),
      ],
    );
  }

  Widget _cartao(BuildContext context, AppStore store, String tid, int i, bool ativo) {
    final t = store.time(tid);
    final cor = store.equipe(t.equipeId).cor;
    final tempo = p.tempos[tid];
    final naBateria = _bateria.contains(tid);
    final correndo = naBateria && tempo == null && _emProva;
    final esmaecido = ativo && _emProva && !naBateria;
    final selecionavel = ativo && !_emProva && tempo == null;
    final cs = Theme.of(context).colorScheme;

    final Widget acao;
    if (!ativo) {
      acao = const SizedBox.shrink();
    } else if (correndo) {
      acao = FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: cor,
          minimumSize: const Size(130, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        onPressed: _sw.isRunning ? () => _chegada(tid) : null,
        icon: const Icon(Icons.sports_score),
        label: const Text('Chegada'),
      );
    } else if (tempo != null) {
      acao = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Desfazer tempo',
            onPressed: _emProva
                ? null
                : () {
                    final mk = p.marcacoes.lastWhere(
                      (x) => x.timeId == tid && !x.desfeita && x.tipo != TipoMarcacaoEvento.ponto,
                    );
                    store.desfazerMarcacao(p, mk);
                  },
            icon: Icon(Icons.undo, color: naBateria ? Colors.white : null),
          ),
          IconButton(
            tooltip: 'Ajustar manualmente',
            onPressed: () => _ajustar(tid),
            icon: Icon(Icons.edit_outlined, color: naBateria ? Colors.white : null),
          ),
        ],
      );
    } else if (selecionavel) {
      acao = Checkbox(value: naBateria, onChanged: (_) => _alternarSelecao(tid));
    } else {
      acao = const SizedBox.shrink();
    }

    final destaque = naBateria && ativo;
    final fg = destaque ? Colors.white : null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: esmaecido ? 0.35 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: destaque ? cor : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: destaque
              ? Border.all(color: const Color(0xFFFFD54F), width: 3)
              : Border(left: BorderSide(color: cor, width: 6)),
          boxShadow: destaque
              ? [BoxShadow(color: cor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: selecionavel
                ? () => _alternarSelecao(tid)
                : (correndo && _sw.isRunning ? () => _chegada(tid) : null),
            child: Padding(
              padding: EdgeInsets.all(destaque ? 16 : 12),
              child: Row(
                children: [
                  if (p.status == StatusPartida.encerrada)
                    SizedBox(
                      width: 36,
                      child: Text('${i + 1}º', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                  if (correndo) ...[const Icon(Icons.rowing, color: Colors.white), const SizedBox(width: 10)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.nome,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: destaque ? 18 : 16, color: fg),
                        ),
                        Text(
                          t.integrantes.map((u) => store.usuario(u).nome.split(' ').first).join(', '),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: destaque ? Colors.white70 : null),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    tempo == null ? (correndo ? formatarTempo(_sw.elapsedMilliseconds) : '—') : formatarTempo(tempo),
                    style: TextStyle(
                      fontSize: destaque ? 22 : 20,
                      fontWeight: FontWeight.w700,
                      color: correndo ? Colors.white70 : fg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  acao,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ comum

class _ResultadoFinal extends StatelessWidget {
  final Partida p;
  const _ResultadoFinal(this.p);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final texto = p.empate ? 'Partida encerrada em empate' : 'Vencedor: ${store.time(p.classificacao.first).nome}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFD6F2DD), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFF1B5E2E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Color(0xFF1B5E2E), fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const Text('Correções: Administração › Partidas', style: TextStyle(color: Color(0xFF1B5E2E), fontSize: 12)),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  final Partida p;
  final bool podeDesfazer;
  const _Timeline(this.p, {required this.podeDesfazer});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (p.marcacoes.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      title: 'Marcações',
      subtitle: 'Cada marcação fica registrada com horário e árbitro (RF033)',
      child: Column(
        children: [
          for (final mk in p.marcacoes.reversed.take(30))
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: EquipeDot(store.equipe(store.time(mk.timeId).equipeId).cor),
              title: Text(
                '${store.time(mk.timeId).nome}: ${descreverMarcacao(mk)}',
                style: mk.desfeita ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
              ),
              subtitle: Text(
                '${formatarHora(mk.hora)} · ${store.usuario(mk.usuarioId).nome}'
                '${mk.justificativa != null ? ' · ${mk.justificativa}' : ''}',
              ),
              trailing: podeDesfazer && !mk.desfeita && mk.tipo == TipoMarcacaoEvento.ponto
                  ? TextButton.icon(
                      onPressed: () => store.desfazerMarcacao(p, mk),
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Desfazer'),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
