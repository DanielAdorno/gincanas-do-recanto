import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import 'gincana_form.dart';

/// Lançamento de partida pelo Administrador (RF027/RF065): modalidade, fase, times, árbitros,
/// data no calendário da gincana e horário. Também usado para reagendar.
class NovaPartidaScreen extends StatefulWidget {
  final String? modalidadeId;
  final String? faseId;
  final List<String> sugeridos;
  final DateTime? diaInicial;
  const NovaPartidaScreen({super.key, this.modalidadeId, this.faseId, this.sugeridos = const [], this.diaInicial});

  @override
  State<NovaPartidaScreen> createState() => _NovaPartidaScreenState();
}

class _NovaPartidaScreenState extends State<NovaPartidaScreen> {
  String? _mod;
  String? _fase;
  late final Set<String> _times = {...widget.sugeridos};
  final Set<String> _arbitros = {};
  DateTime? _dia;
  TimeOfDay _hora = const TimeOfDay(hour: 15, minute: 0);
  String? _erro;

  @override
  void initState() {
    super.initState();
    _mod = widget.modalidadeId;
    _fase = widget.faseId;
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = store.gincanaAtual!;
    final mods = store.modalidadesDaGincana.where((m) => m.ativa).toList();
    final m = _mod == null ? null : store.modalidade(_mod!);
    final fases = m == null ? <Fase>[] : store.fasesDa(m.id);
    if (_fase != null && !fases.any((f) => f.id == _fase)) _fase = null;
    _fase ??= fases.isEmpty ? null : fases.last.id;
    final f = _fase == null ? null : store.fase(_fase!);
    final times = m == null ? <Time>[] : store.timesDa(m.id);
    _dia ??= widget.diaInicial ?? store.diaPadrao;
    if (!store.diaDeCompeticao(_dia!)) _dia = store.diaPadrao;
    final dias = store.semanaDaGincana;
    final dataHora = DateTime(_dia!.year, _dia!.month, _dia!.day, _hora.hour, _hora.minute);
    final conflitos = f == null
        ? <Partida>[]
        : store.partidasDaGincana.where((p) => p.dataHora == dataHora && p.timeIds.any(_times.contains)).toList();
    final anterior = f == null ? null : fases.where((x) => x.ordem < f.ordem).lastOrNull;
    final classificados = anterior == null ? <String>[] : store.classificados(anterior.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Nova partida')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: const Icon(Icons.event_available),
            label: Text('Agendar para ${formatarDiaCurto(dataHora)} às ${formatarHora(dataHora)}'),
            onPressed: () {
              if (f == null) return setState(() => _erro = 'Escolha a modalidade e a fase.');
              final ids = times.where((t) => _times.contains(t.id)).map((t) => t.id).toList();
              final erro =
                  store.validarPartida(f, ids) ?? (_arbitros.isEmpty ? 'Designe pelo menos um árbitro (RF030).' : null);
              if (erro != null) return setState(() => _erro = erro);
              store.criarPartida(f, ids, _arbitros.toList(), dataHora);
              Navigator.pop(context);
              mostrarMensagem(
                context,
                'Partida agendada para ${formatarDiaCurto(dataHora)} às ${formatarHora(dataHora)}',
              );
            },
          ),
        ),
      ),
      body: PageBody(
        maxWidth: 720,
        children: [
          SectionCard(
            title: '1. Modalidade e fase',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _mod,
                  decoration: const InputDecoration(labelText: 'Modalidade'),
                  items: [
                    for (final x in mods)
                      DropdownMenuItem(
                        value: x.id,
                        child: Row(
                          children: [
                            Icon(
                              x.tipo == TipoMarcacao.placar ? Icons.scoreboard_outlined : Icons.timer_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(x.nome),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() {
                    _mod = v;
                    _fase = null;
                    _times.clear();
                    _erro = null;
                  }),
                ),
                const SizedBox(height: 12),
                if (m != null && fases.isEmpty)
                  const InfoBanner(
                    'Esta modalidade ainda não tem fases. Crie as fases em Modalidades › Fases e partidas.',
                    icon: Icons.warning_amber,
                  )
                else if (m != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final x in fases)
                        ChoiceChip(
                          avatar: Icon(x.valePontos ? Icons.star : Icons.star_border, size: 18),
                          label: Text('${x.nome}${x.valePontos ? '' : ' (sem pontos)'}'),
                          selected: _fase == x.id,
                          onSelected: (_) => setState(() {
                            _fase = x.id;
                            _times.clear();
                            _erro = null;
                          }),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (f != null)
            SectionCard(
              title: '2. ${m!.tipo == TipoMarcacao.placar ? 'Times (escolha 2)' : 'Participantes da prova'}',
              subtitle: f.valePontos ? 'Fase que vale pontos: times de equipes diferentes (RN014)' : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (classificados.isNotEmpty) ...[
                    Text(
                      'Classificados de ${anterior!.nome}: ${classificados.map((t) => store.time(t).nome).join(', ')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in times)
                        FilterChip(
                          showCheckmark: false,
                          avatar: _times.contains(t.id)
                              ? Icon(Icons.check_circle, color: store.equipe(t.equipeId).cor)
                              : EquipeDot(store.equipe(t.equipeId).cor),
                          label: Text(classificados.contains(t.id) ? '${t.nome} ★' : t.nome),
                          selected: _times.contains(t.id),
                          onSelected: (s) => setState(() {
                            s ? _times.add(t.id) : _times.remove(t.id);
                            _erro = null;
                          }),
                        ),
                    ],
                  ),
                  if (times.isEmpty) const Text('Nenhum time cadastrado nesta modalidade.'),
                ],
              ),
            ),
          SectionCard(
            title: '3. Data e horário',
            subtitle: 'Gincana de ${formatarData(g.inicio)} a ${formatarData(g.fim)}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final d in dias)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: DiaCalendario(
                            dia: d,
                            habilitado: store.diaDeCompeticao(d),
                            selecionado: mesmoDia(d, _dia!),
                            qtd: store.partidasDaGincana.where((p) => mesmoDia(p.dataHora, d)).length,
                            onTap: () => setState(() => _dia = d),
                          ),
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.edit_calendar, size: 18),
                    label: const Text('Mudar a semana da gincana (outro mês/ano)'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GincanaFormScreen()),
                    ).then((_) => setState(() => _dia = null)),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_month),
                        label: Text(formatarData(_dia!)),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _dia!,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040, 12, 31),
                            helpText: 'Competições: ${formatarData(g.inicio)} a ${formatarData(g.fim)}',
                            selectableDayPredicate: store.diaDeCompeticao,
                          );
                          if (d != null) setState(() => _dia = d);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.schedule),
                        label: Text(_hora.format(context)),
                        onPressed: () async {
                          final h = await showTimePicker(context: context, initialTime: _hora, helpText: 'Horário');
                          if (h != null) setState(() => _hora = h);
                        },
                      ),
                    ),
                  ],
                ),
                if (conflitos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InfoBanner(
                    'Atenção: no mesmo dia e horário já há ${conflitos.map(store.tituloPartida).join('; ')}.',
                    icon: Icons.warning_amber,
                  ),
                ],
              ],
            ),
          ),
          SectionCard(
            title: '4. Árbitros',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final a in store.arbitrosDaGincana)
                  FilterChip(
                    label: Text(a.nome),
                    selected: _arbitros.contains(a.id),
                    onSelected: (s) => setState(() => s ? _arbitros.add(a.id) : _arbitros.remove(a.id)),
                  ),
              ],
            ),
          ),
          if (_erro != null)
            Text(
              _erro!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

/// Bloco de dia do calendário (dia da semana, número, nº de partidas).
/// Dias fora do período de competição (ex: sexta) aparecem desabilitados.
class DiaCalendario extends StatelessWidget {
  final DateTime dia;
  final bool selecionado;
  final int qtd;
  final VoidCallback? onTap;
  final bool habilitado;
  const DiaCalendario({
    super.key,
    required this.dia,
    required this.selecionado,
    required this.qtd,
    required this.onTap,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hoje = mesmoDia(dia, DateTime.now());
    final fg = selecionado ? cs.onPrimary : (habilitado ? cs.onSurface : cs.onSurface.withValues(alpha: 0.35));
    final fg2 = selecionado ? cs.onPrimary : (habilitado ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.35));
    return Tooltip(
      message: habilitado ? formatarData(dia) : '${formatarData(dia)} · sem competições',
      child: Material(
        color: selecionado ? cs.primary : (habilitado ? cs.surface : cs.surfaceContainerHighest),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selecionado ? cs.primary : (hoje ? cs.primary : cs.outlineVariant),
            width: hoje ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: habilitado ? onTap : null,
          mouseCursor: habilitado ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
          child: SizedBox(
            width: 68,
            height: 74,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(diaSemana(dia), style: TextStyle(fontSize: 12, color: fg2)),
                Text(
                  '${dia.day}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: fg),
                ),
                Text(
                  !habilitado ? 'sem jogos' : (hoje ? (qtd == 0 ? 'hoje' : 'hoje · $qtd') : (qtd == 0 ? '—' : '$qtd')),
                  style: TextStyle(fontSize: 11, color: fg2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Reagendar uma partida ainda não iniciada (data e horário).
Future<void> reagendarPartida(BuildContext context, Partida p) async {
  final store = AppScope.of(context);
  final g = store.gincanaAtual!;
  final d = await showDatePicker(
    context: context,
    initialDate: p.dataHora,
    firstDate: DateTime(2020),
    lastDate: DateTime(2040, 12, 31),
    helpText: 'Nova data · competições de ${formatarData(g.inicio)} a ${formatarData(g.fim)}',
    selectableDayPredicate: store.diaDeCompeticao,
  );
  if (d == null || !context.mounted) return;
  final h = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(p.dataHora),
    helpText: 'Novo horário',
  );
  if (h == null) return;
  final nova = DateTime(d.year, d.month, d.day, h.hour, h.minute);
  store.reagendarPartida(p, nova);
  if (context.mounted) {
    mostrarMensagem(context, 'Partida reagendada para ${formatarDiaCurto(nova)} às ${formatarHora(nova)}');
  }
}
