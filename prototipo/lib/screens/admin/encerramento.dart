import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import 'cerimonia_medalhas.dart';

/// Modal de finalização da gincana (RF055/RF056).
class FinalizarGincanaDialog extends StatefulWidget {
  const FinalizarGincanaDialog({super.key});

  @override
  State<FinalizarGincanaDialog> createState() => _FinalizarGincanaDialogState();
}

class _FinalizarGincanaDialogState extends State<FinalizarGincanaDialog> {
  bool _ciente = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = store.gincanaAtual!;
    final r = store.ranking();
    final pend = store.partidasPendentes;
    final v = store.equipeVencedora;
    final podeFinalizar = pend.isEmpty || _ciente;

    return AlertDialog(
      icon: const Icon(Icons.flag_circle, size: 40),
      title: const Text('Finalizar gincana'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Gincana do $nomeLocal · ${g.nome}', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final e in g.equipes)
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: e == g.equipes.first ? 8 : 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: e.cor, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            Text(
                              e.nome,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              formatarPontos(r[e.id]!),
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                v == null ? 'Placar empatado no momento.' : 'Vencedora se finalizar agora: ${v.nome}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              if (pend.isEmpty)
                const Tag('Todas as partidas foram encerradas', icon: Icons.check_circle, color: Color(0xFF1B7F3B))
              else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Color(0xFF8A5A00)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${pend.length} partida(s) ainda não encerrada(s):',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8A5A00)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      for (final p in pend)
                        Text(
                          '• ${store.modalidadeDaPartida(p).nome} · ${store.fase(p.faseId).nome}: '
                          '${store.tituloPartida(p)} (${p.status.label})',
                        ),
                      const SizedBox(height: 6),
                      const Text('Elas não contarão pontos e ficarão travadas.', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _ciente,
                  onChanged: (v) => setState(() => _ciente = v ?? false),
                  title: const Text('Estou ciente e quero finalizar mesmo assim'),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Depois de finalizada, nenhuma partida pode ser iniciada e o relatório final fica disponível.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: !podeFinalizar
              ? null
              : () {
                  final nav = Navigator.of(context);
                  store.encerrarGincana();
                  nav.pop();
                  nav.push(MaterialPageRoute(builder: (_) => const RelatorioFinalScreen()));
                },
          icon: const Icon(Icons.flag),
          label: const Text('Finalizar e gerar relatório'),
        ),
      ],
    );
  }
}

/// Relatório final: equipe vencedora e times vencedores de cada modalidade (RF057).
class RelatorioFinalScreen extends StatelessWidget {
  const RelatorioFinalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = store.gincanaAtual!;
    final r = store.ranking();
    final v = store.equipeVencedora;
    final t = Theme.of(context).textTheme;
    final mods = store.modalidadesDaGincana.where((m) => m.ativa).toList();
    final resultados = [for (final m in mods) store.resultadoModalidade(m)];
    // Cerimônia em ordem cronológica, a mesma usada para decidir a medalha de quem venceu mais de uma (RN020).
    final vencedores = store.vitoriasEmOrdem();
    final medalhas = store.medalhas();
    final cor = v?.cor ?? Colors.blueGrey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório final'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar texto'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: store.relatorioTexto()));
              if (context.mounted) mostrarMensagem(context, 'Relatório copiado para a área de transferência');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PageBody(
        maxWidth: 860,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cor, cor.withValues(alpha: 0.75)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.emoji_events, size: 64, color: Color(0xFFFFE07A)),
                const SizedBox(height: 4),
                Text(v == null ? 'Empate!' : 'Equipe vencedora', style: t.titleMedium?.copyWith(color: Colors.white70)),
                Text(
                  v?.nome ?? 'As duas equipes empataram',
                  textAlign: TextAlign.center,
                  style: t.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gincana do $nomeLocal · ${g.nome} · ${formatarData(g.inicio)} a ${formatarData(g.fim)}',
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final e in g.equipes)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            EquipeDot(e.cor, size: 14),
                            const SizedBox(width: 8),
                            Text(e.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            Text(
                              '${formatarPontos(r[e.id]!)} pts',
                              style: TextStyle(fontWeight: FontWeight.w800, color: e.cor, fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!g.encerrada)
            const InfoBanner(
              'Prévia: a gincana ainda não foi finalizada, os números podem mudar.',
              icon: Icons.hourglass_top,
            ),
          SectionCard(
            title: 'Vencedores por modalidade',
            subtitle:
                '${medalhas.length} medalha(s) a entregar — uma por pessoa, mesmo vencendo mais de uma modalidade. '
                'Toque em um vencedor para destacá-lo e chamar os integrantes às medalhas',
            trailing: vencedores.isEmpty
                ? null
                : FilledButton.tonalIcon(
                    icon: const Icon(Icons.military_tech),
                    label: const Text('Cerimônia'),
                    onPressed: () => abrirCerimoniaMedalhas(context, vencedores, 0),
                  ),
            child: Column(
              children: [
                for (final r in resultados)
                  _LinhaModalidade(
                    r,
                    onTap: r.timeId == null
                        ? null
                        : () => abrirCerimoniaMedalhas(
                            context,
                            vencedores,
                            vencedores.indexWhere((x) => x.modalidade.id == r.modalidade.id),
                          ),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: 'Modalidades vencidas por equipe',
            child: Column(
              children: [
                for (final e in g.equipes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        EquipeLabel(e),
                        const Spacer(),
                        Text(
                          '${mods.where((m) {
                            final res = store.resultadoModalidade(m);
                            return res.timeId != null && store.time(res.timeId!).equipeId == e.id;
                          }).length} de ${mods.length}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (g.encerradaEm != null)
            Text(
              'Gincana finalizada em ${formatarData(g.encerradaEm!)} às ${formatarHora(g.encerradaEm!)} por ${store.usuarioAtual!.nome}.',
              textAlign: TextAlign.center,
              style: t.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _LinhaModalidade extends StatelessWidget {
  final ResultadoModalidade res;
  final VoidCallback? onTap;
  const _LinhaModalidade(this.res, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final m = res.modalidade;
    final placar = m.tipo == TipoMarcacao.placar;
    final icone = Icon(placar ? Icons.scoreboard_outlined : Icons.timer_outlined);
    if (res.timeId == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: icone,
        title: Text(m.nome),
        trailing: Tag(res.detalhe, color: Colors.grey),
      );
    }
    final t = store.time(res.timeId!);
    final e = store.equipe(t.equipeId);
    final med = store.medalhas();
    final ids = store.integrantesVencedores(res);
    final repetidos = ids.where((u) => med[u]?.modalidade.id != m.id).toList();
    final nomes = ids.map((u) => store.usuario(u).nome).join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: e.cor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: e.cor, width: 5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icone,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.nome, style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.emoji_events, size: 18, color: Color(0xFFC79100)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(t.nome, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                          const SizedBox(width: 8),
                          Tag(e.nome, color: e.cor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(res.detalhe, style: Theme.of(context).textTheme.bodySmall),
                      if (nomes.isNotEmpty) Text('Integrantes: $nomes', style: Theme.of(context).textTheme.bodySmall),
                      if (repetidos.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final u in repetidos)
                                Tag(
                                  '${store.usuario(u).nome}: já tem medalha (${med[u]!.modalidade.nome})',
                                  icon: Icons.check_circle,
                                  color: const Color(0xFFB26A00),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.military_tech, color: Color(0xFFC79100)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
