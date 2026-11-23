import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/busca.dart';
import '../../widgets/common.dart';
import '../../widgets/partida_tile.dart';
import '../admin/nova_partida.dart' show DiaCalendario;

/// Agenda de partidas da equipe para o Líder (RF067): só consulta datas e configurações;
/// em cada partida o Líder escala os participantes da própria equipe (RF068).
class PartidasLiderScreen extends StatefulWidget {
  const PartidasLiderScreen({super.key});

  @override
  State<PartidasLiderScreen> createState() => _PartidasLiderScreenState();
}

class _PartidasLiderScreenState extends State<PartidasLiderScreen> {
  DateTime? _dia;
  bool _soPendentes = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final eq = store.equipeDoLider!;
    bool semEscalacao(Partida p) =>
        store.podeEscalar(p) &&
        p.timeIds.where((t) => store.time(t).equipeId == eq.id).any((t) => store.time(t).integrantes.isEmpty);
    final todas = store.partidasDaEquipe(eq.id).where((p) => !_soPendentes || semEscalacao(p)).toList();
    final pendentes = store.partidasDaEquipe(eq.id).where(semEscalacao).length;
    final lista = _dia == null ? todas : todas.where((p) => mesmoDia(p.dataHora, _dia!)).toList();

    return PageBody(
      children: [
        const InfoBanner(
          'Aqui ficam as partidas da sua equipe. A data, o horário e as regras são definidos pelo Administrador; '
          'você escolhe quais participantes da sua equipe jogam em cada partida.',
          icon: Icons.event_note,
        ),
        SectionCard(
          title: 'Calendário da equipe',
          subtitle: '${store.partidasDaEquipe(eq.id).length} partida(s) · toque em um dia',
          trailing: FilterChip(
            avatar: const Icon(Icons.group_add, size: 18),
            label: Text('Sem escalação ($pendentes)'),
            selected: _soPendentes,
            onSelected: (v) => setState(() => _soPendentes = v),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Todos'),
                    selected: _dia == null,
                    onSelected: (_) => setState(() => _dia = null),
                  ),
                ),
                for (final d in store.semanaDaGincana)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: DiaCalendario(
                      dia: d,
                      habilitado: store.diaDeCompeticao(d),
                      selecionado: _dia != null && mesmoDia(d, _dia!),
                      qtd: todas.where((p) => mesmoDia(p.dataHora, d)).length,
                      onTap: () => setState(() => _dia = d),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (lista.isEmpty)
          const EmptyState(icon: Icons.event_busy_outlined, text: 'Nenhuma partida da sua equipe aqui'),
        for (final p in lista)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (semEscalacao(p))
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Tag('Escale os participantes', icon: Icons.group_add, color: Color(0xFFB26A00)),
                  ),
                ),
              PartidaTile(
                p,
                mostrarModalidade: true,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EscalacaoLiderScreen(p.id))),
              ),
            ],
          ),
      ],
    );
  }
}

/// Partida vista pelo Líder: dados somente leitura e escalação dos times da própria equipe.
class EscalacaoLiderScreen extends StatelessWidget {
  final String partidaId;
  const EscalacaoLiderScreen(this.partidaId, {super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final eq = store.equipeDoLider!;
    final p = store.partidas.firstWhere((x) => x.id == partidaId);
    final f = store.fase(p.faseId);
    final m = store.modalidade(f.modalidadeId);
    final meus = p.timeIds.where((t) => store.time(t).equipeId == eq.id).toList();
    final adversarios = p.timeIds.where((t) => !meus.contains(t)).toList();
    final pode = store.podeEscalar(p);
    final t = Theme.of(context).textTheme;

    Widget linha(IconData i, String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(i, size: 18),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(a, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(b)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('${m.nome} · ${f.nome}')),
      body: PageBody(
        maxWidth: 760,
        children: [
          SectionCard(
            title: 'Dados da partida',
            subtitle: 'Definidos pelo Administrador · somente leitura',
            trailing: StatusBadge(p.status),
            child: Column(
              children: [
                linha(
                  Icons.event,
                  'Data',
                  '${formatarDiaCurto(p.dataHora)}/${p.dataHora.year} às ${formatarHora(p.dataHora)}',
                ),
                linha(
                  m.tipo == TipoMarcacao.placar ? Icons.scoreboard_outlined : Icons.timer_outlined,
                  'Marcação',
                  m.tipo == TipoMarcacao.placar ? 'Placar (${m.unidade})' : 'Tempo (cronômetro)',
                ),
                linha(
                  Icons.flag_outlined,
                  'Fase',
                  '${f.nome}${f.valePontos ? ' · vale pontos' : ' · não vale pontos'}',
                ),
                if (adversarios.isNotEmpty)
                  linha(Icons.groups_outlined, 'Contra', adversarios.map((x) => store.time(x).nome).join(', ')),
                linha(Icons.sports, 'Árbitro', p.arbitroIds.map((a) => store.usuario(a).nome).join(', ')),
              ],
            ),
          ),
          if (!pode)
            InfoBanner(
              p.status == StatusPartida.agendada
                  ? 'A gincana foi finalizada; a escalação não pode mais ser alterada.'
                  : 'A partida já começou: a escalação ficou travada (RN017).',
              icon: Icons.lock,
            )
          else
            const InfoBanner(
              'Escolha quem joga. Quem você escalar aparece para o árbitro na tela da partida. '
              'Você pode trocar até o árbitro iniciar a partida.',
              icon: Icons.info_outline,
            ),
          for (final tid in meus) _EscalacaoTime(p, tid, pode: pode),
          Text('Somente os participantes da ${eq.nome} podem ser escalados.', style: t.bodySmall),
        ],
      ),
    );
  }
}

class _EscalacaoTime extends StatefulWidget {
  final Partida p;
  final String timeId;
  final bool pode;
  const _EscalacaoTime(this.p, this.timeId, {required this.pode});

  @override
  State<_EscalacaoTime> createState() => _EscalacaoTimeState();
}

class _EscalacaoTimeState extends State<_EscalacaoTime> {
  final _busca = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _busca.dispose();
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = widget.p;
    final tm = store.time(widget.timeId);
    final eq = store.equipe(tm.equipeId);
    final m = store.modalidadeDaPartida(p);
    final n = m.participantesPorTime;
    // Escalação congelada se a partida já começou; senão, a atual do time.
    final escalados = p.escalacao[tm.id] ?? tm.integrantes;
    final titulares = store.titularesDe(tm, escalados);
    final reservas = store.reservasDe(tm, escalados);
    final cheio = store.limiteTime(tm) != null && p.escalacao[tm.id] == null;
    final termo = normalizar(_busca.text.trim());
    final inscritos = store.inscritos(m.id);
    final outrosTimes = {
      for (final x in store.timesDa(m.id, equipeId: eq.id))
        if (x.id != tm.id)
          for (final u in x.integrantes) u: x.nome,
    };
    final candidatos = termo.isEmpty
        ? <String>[]
        : (eq.participantes.where((u) => !escalados.contains(u) && casaBusca(store.usuario(u).nome, termo)).toList()
            ..sort((a, b) {
              final ia = inscritos.contains(a) ? 0 : 1, ib = inscritos.contains(b) ? 0 : 1;
              return ia != ib ? ia - ib : ordemBusca(store.usuario(a).nome, store.usuario(b).nome, termo);
            }));
    final sugestoes = termo.isNotEmpty
        ? <String>[]
        : inscritos
              .where((u) => eq.participantes.contains(u) && !escalados.contains(u) && !outrosTimes.containsKey(u))
              .toList();

    void escalar(String u) {
      final erro = store.escalar(p, tm.id, u);
      if (erro != null) mostrarMensagem(context, erro);
      _busca.clear();
      setState(() {});
      _foco.requestFocus();
    }

    Widget chip(String u, {required bool reserva}) => InputChip(
      avatar: CircleAvatar(
        backgroundColor: reserva ? Colors.blueGrey : eq.cor,
        child: Text(store.usuario(u).nome[0], style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
      label: Text(store.usuario(u).nome),
      tooltip: reserva && widget.pode ? 'Tocar para tornar titular' : null,
      onPressed: reserva && widget.pode ? () => store.tornarTitular(p, tm.id, u) : null,
      onDeleted: widget.pode ? () => store.desescalar(p, tm.id, u) : null,
      deleteButtonTooltipMessage: 'Tirar da partida',
    );

    final contagem = n == null
        ? '${escalados.length} escalado(s) · toda a equipe pode jogar'
        : 'Titulares ${titulares.length}/$n${m.reservas > 0 ? ' · Reservas ${reservas.length}/${m.reservas}' : ' · sem reservas'}';

    return SectionCard(
      title: tm.nome,
      subtitle: contagem,
      trailing: n == null && widget.pode && escalados.length < eq.participantes.length
          ? FilledButton.tonalIcon(
              icon: const Icon(Icons.groups),
              label: const Text('Escalar toda a equipe'),
              onPressed: () => store.escalarTodos(p, tm.id),
            )
          : EquipeDot(eq.cor, size: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (escalados.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Tag('Ninguém escalado ainda', icon: Icons.warning_amber, color: Color(0xFFB26A00)),
            )
          else ...[
            if (n != null) Text('Titulares', style: Theme.of(context).textTheme.labelLarge),
            if (n != null) const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final u in titulares) chip(u, reserva: false)]),
            if (n != null && titulares.length < n)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Tag(
                  'Faltam ${n - titulares.length} titular(es)',
                  icon: Icons.person_add,
                  color: const Color(0xFFB26A00),
                ),
              ),
            if (reservas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Reservas · toque para tornar titular', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final u in reservas) chip(u, reserva: true)]),
            ],
          ],
          if (widget.pode) ...[
            const SizedBox(height: 12),
            if (cheio)
              Tag(
                'Time completo (${m.descricaoParticipantes}). Tire alguém para escalar outro.',
                icon: Icons.check_circle,
                color: const Color(0xFF1B7F3B),
              )
            else ...[
              CampoBusca(
                controller: _busca,
                focusNode: _foco,
                hint: n != null && titulares.length >= n
                    ? 'Escalar reserva da ${eq.nome}...'
                    : 'Escalar participante da ${eq.nome}...',
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (candidatos.isNotEmpty) escalar(candidatos.first);
                },
              ),
              if (termo.isNotEmpty) ...[
                const SizedBox(height: 6),
                if (candidatos.isEmpty)
                  Text('Ninguém encontrado na ${eq.nome}', style: Theme.of(context).textTheme.bodySmall)
                else
                  for (final u in candidatos.take(6))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_add_alt),
                      title: NomeDestacado(store.usuario(u).nome, termo),
                      subtitle: Text(
                        outrosTimes.containsKey(u)
                            ? 'Está no time ${outrosTimes[u]} — será movido'
                            : inscritos.contains(u)
                            ? 'Inscrito em ${m.nome}'
                            : 'Será inscrito em ${m.nome}',
                      ),
                      onTap: () => escalar(u),
                    ),
              ],
              if (sugestoes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('Inscritos em ${m.nome} ainda sem time:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final u in sugestoes.take(20))
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: Text(store.usuario(u).nome),
                        onPressed: () => escalar(u),
                      ),
                  ],
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
