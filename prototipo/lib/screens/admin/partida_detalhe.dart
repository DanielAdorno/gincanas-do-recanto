import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import '../../widgets/partida_tile.dart';
import '../arbitro/arbitragem.dart';
import 'nova_partida.dart';

/// Detalhe da partida para o Administrador: resultado, escalação, marcações,
/// correção e cancelamento (RF041/RF042).
class PartidaDetalheScreen extends StatelessWidget {
  final String partidaId;
  const PartidaDetalheScreen(this.partidaId, {super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = store.partidas.where((x) => x.id == partidaId).firstOrNull;
    if (p == null) return const Scaffold();
    final f = store.fase(p.faseId);
    final m = store.modalidade(f.modalidadeId);
    final pts = store.pontuacoes.where((x) => x.partidaId == p.id).toList();
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text('${m.nome} · ${f.nome}')),
      body: PageBody(
        maxWidth: 820,
        children: [
          SectionCard(
            title: store.tituloPartida(p),
            subtitle:
                '${formatarDiaCurto(p.dataHora)} ${formatarHora(p.dataHora)} · ${f.valePontos ? 'Vale pontos' : 'Não vale pontos'}',
            trailing: StatusBadge(p.status),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResultadoPartida(p),
                if (p.status == StatusPartida.encerrada && p.empate)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Tag('Empate', icon: Icons.drag_handle),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (p.status != StatusPartida.encerrada)
                      FilledButton.icon(
                        icon: const Icon(Icons.sports),
                        label: const Text('Abrir tela de arbitragem'),
                        onPressed: () =>
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ArbitragemScreen(p.id))),
                      ),
                    if (p.status == StatusPartida.encerrada) ...[
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Corrigir resultado'),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => _CorrigirDialog(p, m.tipo == TipoMarcacao.placar),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.undo),
                        label: const Text('Cancelar resultado'),
                        onPressed: () async {
                          if (await confirmar(
                            context,
                            'Cancelar resultado',
                            'O resultado e os pontos desta partida serão estornados e ela volta a ficar agendada. A ação fica na auditoria.',
                            ok: 'Cancelar resultado',
                          )) {
                            store.cancelarResultado(p);
                            if (context.mounted) mostrarMensagem(context, 'Resultado cancelado');
                          }
                        },
                      ),
                    ],
                    if (p.status == StatusPartida.agendada && !store.gincanaAtual!.encerrada)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.edit_calendar),
                        label: const Text('Reagendar'),
                        onPressed: () => reagendarPartida(context, p),
                      ),
                    if (p.status == StatusPartida.agendada)
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Excluir partida'),
                        onPressed: () {
                          Navigator.pop(context);
                          store.excluirPartida(p);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (pts.isNotEmpty)
            SectionCard(
              title: 'Pontos gerados para a gincana',
              subtitle: 'Visível apenas ao Administrador',
              child: Column(
                children: [
                  for (final x in pts)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: EquipeDot(store.equipe(x.equipeId).cor),
                      title: Text(
                        x.descricao,
                        style: x.cancelada ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
                      ),
                      trailing: Text(
                        x.cancelada ? 'estornado' : '+${formatarPontos(x.valor)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          SectionCard(
            title: 'Escalação',
            subtitle: p.escalacao.isEmpty
                ? 'Ainda pode ser alterada pelo Líder até o início da partida'
                : 'Congelada no início da partida (RN017)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final tid in p.timeIds)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EquipeLabel(
                          store.equipe(store.time(tid).equipeId),
                          texto: store.time(tid).nome,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          (p.escalacao[tid] ?? store.time(tid).integrantes)
                              .map((u) => store.usuario(u).nome)
                              .join(', '),
                          style: t.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (p.marcacoes.isNotEmpty)
            SectionCard(
              title: 'Marcações',
              child: Column(
                children: [
                  for (final mk in p.marcacoes.reversed)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(switch (mk.tipo) {
                        TipoMarcacaoEvento.ponto => Icons.add_circle_outline,
                        TipoMarcacaoEvento.tempo => Icons.timer_outlined,
                        TipoMarcacaoEvento.desempate => Icons.sports_score,
                        TipoMarcacaoEvento.ajuste => Icons.edit_outlined,
                      }, size: 18),
                      title: Text(
                        '${store.time(mk.timeId).nome}: ${descreverMarcacao(mk)}',
                        style: mk.desfeita ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
                      ),
                      subtitle: Text(
                        '${store.usuario(mk.usuarioId).nome} · ${formatarHora(mk.hora)}${mk.justificativa != null ? ' · ${mk.justificativa}' : ''}',
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String descreverMarcacao(Marcacao mk) => switch (mk.tipo) {
  TipoMarcacaoEvento.ponto => mk.valor > 0 ? '+${mk.valor}' : '${mk.valor}',
  TipoMarcacaoEvento.tempo => 'chegada ${formatarTempo(mk.valor)}',
  TipoMarcacaoEvento.desempate => 'desempate ${mk.valor}',
  TipoMarcacaoEvento.ajuste => 'tempo ajustado para ${formatarTempo(mk.valor)}',
};

int? lerTempo(String s) {
  final r = RegExp(r'^(\d{1,2}):(\d{2})[.,](\d{1,2})$').firstMatch(s.trim());
  if (r == null) return null;
  final cent = r.group(3)!.padRight(2, '0');
  return int.parse(r.group(1)!) * 60000 + int.parse(r.group(2)!) * 1000 + int.parse(cent) * 10;
}

class _CorrigirDialog extends StatefulWidget {
  final Partida p;
  final bool placar;
  const _CorrigirDialog(this.p, this.placar);

  @override
  State<_CorrigirDialog> createState() => _CorrigirDialogState();
}

class _CorrigirDialogState extends State<_CorrigirDialog> {
  late final Map<String, TextEditingController> _ctrl;
  late final Map<String, TextEditingController> _des;
  final _just = TextEditingController();
  String? _erro;

  @override
  void initState() {
    super.initState();
    final p = widget.p;
    final tempo = !widget.placar;
    _ctrl = {
      for (final t in p.timeIds)
        t: TextEditingController(text: tempo ? formatarTempo(p.tempos[t] ?? 0) : '${p.placar[t] ?? 0}'),
    };
    _des = {for (final t in p.timeIds) t: TextEditingController(text: p.placarDesempate[t]?.toString() ?? '')};
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = widget.p;
    final placar = widget.placar;
    return AlertDialog(
      title: const Text('Corrigir resultado'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final t in p.timeIds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      EquipeDot(store.equipe(store.time(t).equipeId).cor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(store.time(t).nome)),
                      SizedBox(
                        width: placar ? 70 : 110,
                        child: TextField(
                          controller: _ctrl[t],
                          decoration: InputDecoration(isDense: true, labelText: placar ? 'Placar' : 'mm:ss.cc'),
                        ),
                      ),
                      if (placar) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _des[t],
                            decoration: const InputDecoration(isDense: true, labelText: 'Desempate'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              TextField(
                controller: _just,
                decoration: const InputDecoration(labelText: 'Justificativa (obrigatória)'),
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_just.text.trim().isEmpty) return setState(() => _erro = 'Informe a justificativa.');
            if (placar) {
              final v = {for (final e in _ctrl.entries) e.key: int.tryParse(e.value.text.trim())};
              if (v.values.any((x) => x == null)) return setState(() => _erro = 'Placar inválido.');
              final d = {for (final e in _des.entries) e.key: int.tryParse(e.value.text.trim())};
              final temDes = d.values.every((x) => x != null);
              store.corrigirResultado(
                p,
                placar: v.map((k, x) => MapEntry(k, x!)),
                desempate: temDes ? d.map((k, x) => MapEntry(k, x!)) : null,
              );
            } else {
              final v = {for (final e in _ctrl.entries) e.key: lerTempo(e.value.text)};
              if (v.values.any((x) => x == null)) return setState(() => _erro = 'Use o formato mm:ss.cc');
              store.corrigirResultado(p, tempos: v.map((k, x) => MapEntry(k, x!)));
            }
            Navigator.pop(context);
            mostrarMensagem(context, 'Resultado corrigido e pontuação recalculada');
          },
          child: const Text('Salvar correção'),
        ),
      ],
    );
  }
}
