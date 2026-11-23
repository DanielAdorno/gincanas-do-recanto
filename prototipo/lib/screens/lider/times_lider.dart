import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/busca.dart';
import '../../widgets/common.dart';
import 'seletor_modalidade.dart';

/// O Líder distribui os inscritos nos times da própria equipe (RF023),
/// podendo alterar até o árbitro iniciar a partida (RN017).
class TimesLiderScreen extends StatefulWidget {
  const TimesLiderScreen({super.key});

  @override
  State<TimesLiderScreen> createState() => _TimesLiderScreenState();
}

class _TimesLiderScreenState extends State<TimesLiderScreen> {
  String? _mod;
  final _busca = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _busca.dispose();
    _foco.dispose();
    super.dispose();
  }

  Future<void> _escolherTime(String modalidadeId, String uid, List<Time> timesEq) async {
    final store = AppScope.of(context);
    final livres = timesEq.where((t) => !store.timeBloqueado(t.id)).toList();
    final escolha = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text('Colocar ${store.usuario(uid).nome} em...'),
        children: [
          for (final t in livres)
            SimpleDialogOption(
              onPressed: store.limiteTime(t) == null ? () => Navigator.pop(c, t.id) : null,
              child: Text(
                '${t.nome}  (${t.integrantes.length}${store.modalidade(t.modalidadeId).maxEscalados != null ? '/${store.modalidade(t.modalidadeId).maxEscalados}' : ''})'
                '${store.limiteTime(t) != null ? ' · cheio' : ''}',
                style: store.limiteTime(t) != null ? const TextStyle(color: Colors.grey) : null,
              ),
            ),
          if (livres.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('Todos os times estão com partida em andamento.')),
        ],
      ),
    );
    if (escolha != null) {
      final erro = store.moverParaTime(modalidadeId, uid, escolha);
      if (erro != null && mounted) mostrarMensagem(context, erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final eq = store.equipeDoLider!;
    _mod ??= store.modalidadesDaGincana
        .where((m) => m.ativa && store.timesDa(m.id, equipeId: eq.id).isNotEmpty)
        .firstOrNull
        ?.id;
    final m = _mod == null ? null : store.modalidade(_mod!);
    final timesEq = m == null ? <Time>[] : store.timesDa(m.id, equipeId: eq.id);
    final inscritosEq = m == null ? <String>[] : eq.participantes.where(store.inscritos(m.id).contains).toList();
    final termo = normalizar(_busca.text.trim());
    final semTime = inscritosEq
        .where((u) => !timesEq.any((t) => t.integrantes.contains(u)) && casaBusca(store.usuario(u).nome, termo))
        .toList();
    if (termo.isNotEmpty) semTime.sort((a, b) => ordemBusca(store.usuario(a).nome, store.usuario(b).nome, termo));
    final emTimes = termo.isEmpty
        ? <String>[]
        : inscritosEq
              .where((u) => timesEq.any((t) => t.integrantes.contains(u)) && casaBusca(store.usuario(u).nome, termo))
              .toList();

    return PageBody(
      maxWidth: 900,
      children: [
        const InfoBanner(
          'Você pode montar e trocar os competidores dos times até o árbitro iniciar a partida. Depois disso, o time fica travado (RN017).',
          icon: Icons.lock_clock_outlined,
        ),
        SeletorModalidade(
          selecionada: _mod,
          onChanged: (v) => setState(() => _mod = v),
          filtro: (m) => store.timesDa(m.id, equipeId: eq.id).isNotEmpty,
        ),
        if (m == null)
          const EmptyState(icon: Icons.groups_outlined, text: 'O Administrador ainda não criou times para sua equipe'),
        if (m != null) ...[
          CampoBusca(
            controller: _busca,
            focusNode: _foco,
            hint: 'Buscar competidor inscrito...',
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) async {
              if (semTime.isEmpty) return;
              await _escolherTime(m.id, semTime.first, timesEq);
              _busca.clear();
              if (mounted) setState(() {});
              _foco.requestFocus();
            },
          ),
          if (termo.isNotEmpty && emTimes.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final u in emTimes)
                  Tag(
                    '${store.usuario(u).nome} está no time ${timesEq.firstWhere((t) => t.integrantes.contains(u)).nome}',
                    icon: Icons.groups,
                    color: eq.cor,
                  ),
              ],
            ),
          SectionCard(
            title: 'Inscritos sem time',
            subtitle: semTime.isEmpty
                ? (termo.isEmpty ? 'Todos os inscritos estão em um time' : 'Ninguém sem time com esse nome')
                : (termo.isEmpty
                      ? 'Toque para colocar em um time'
                      : 'Toque (ou Enter no primeiro) para colocar em um time'),
            child: semTime.isEmpty
                ? const SizedBox.shrink()
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final u in semTime)
                        ActionChip(
                          avatar: const Icon(Icons.person_add_alt, size: 18),
                          label: NomeDestacado(store.usuario(u).nome, termo),
                          onPressed: () => _escolherTime(m.id, u, timesEq),
                        ),
                    ],
                  ),
          ),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 700 ? 2 : 1;
              final w = (c.maxWidth - (cols - 1) * 16) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final t in timesEq)
                    SizedBox(
                      width: w,
                      child: _TimeCard(t, eq, termo: termo, onMover: (u) => _escolherTime(m.id, u, timesEq)),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _TimeCard extends StatelessWidget {
  final Time t;
  final Equipe eq;
  final ValueChanged<String> onMover;
  final String termo;
  const _TimeCard(this.t, this.eq, {required this.onMover, this.termo = ''});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final bloqueado = store.timeBloqueado(t.id);
    final proxima =
        store.partidas.where((p) => p.timeIds.contains(t.id) && p.status != StatusPartida.encerrada).toList()
          ..sort((a, b) => a.dataHora.compareTo(b.dataHora));
    return SectionCard(
      title: t.nome,
      subtitle: proxima.isEmpty
          ? 'Sem partida agendada'
          : '${store.fase(proxima.first.faseId).nome} às ${formatarHora(proxima.first.dataHora)} · ${proxima.first.status.label}',
      trailing: bloqueado
          ? const Tag('Travado', icon: Icons.lock, color: Color(0xFFB26A00))
          : Tag(() {
              final m = store.modalidade(t.modalidadeId);
              if (m.participantesPorTime == null) return '${t.integrantes.length} · toda a equipe';
              final tit = store.titularesDe(t).length, res = store.reservasDe(t).length;
              return '$tit/${m.participantesPorTime} titulares${m.reservas > 0 ? ' · $res/${m.reservas} reservas' : ''}';
            }(), color: eq.cor),
      child: t.integrantes.isEmpty
          ? const EmptyState(icon: Icons.person_off_outlined, text: 'Nenhum competidor neste time')
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final u in t.integrantes)
                  Opacity(
                    opacity: termo.isEmpty || casaBusca(store.usuario(u).nome, termo) ? 1 : 0.35,
                    child: InputChip(
                      avatar: CircleAvatar(
                        backgroundColor: eq.cor,
                        child: Text(
                          store.usuario(u).nome[0],
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      label: NomeDestacado(store.usuario(u).nome, termo),
                      onPressed: bloqueado ? null : () => onMover(u),
                      onDeleted: bloqueado ? null : () => store.moverParaTime(t.modalidadeId, u, null),
                      deleteButtonTooltipMessage: 'Tirar do time',
                    ),
                  ),
              ],
            ),
    );
  }
}
