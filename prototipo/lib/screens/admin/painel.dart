import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import 'encerramento.dart';
import 'gincana_form.dart';

/// Painel do Administrador: ranking (RF043–RF046), divisão das equipes (RF008/RF009) e auditoria.
class PainelScreen extends StatelessWidget {
  const PainelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = store.gincanaAtual!;
    final ranking = store.ranking();
    final ordenadas = List.of(g.equipes)..sort((a, b) => ranking[b.id]!.compareTo(ranking[a.id]!));
    final lider = ranking[ordenadas[0].id]! > ranking[ordenadas[1].id]! ? ordenadas[0] : null;
    final partidas = store.partidasDaGincana;
    final encerradas = partidas.where((p) => p.status.name == 'encerrada').length;
    final inconsist = store.inconsistenciasDivisao(g);
    final t = Theme.of(context).textTheme;

    return PageBody(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cards = [
              for (final e in g.equipes)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [e.cor, e.cor.withValues(alpha: 0.75)])),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              e.nome,
                              style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            if (lider == e)
                              const Chip(
                                avatar: Icon(Icons.emoji_events, size: 16, color: Color(0xFF8A6D00)),
                                label: Text('Liderando'),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatarPontos(ranking[e.id]!),
                          style: t.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                        Text('pontos', style: t.bodyMedium?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
            ];
            if (c.maxWidth < 600) {
              return Column(children: [cards[0], const SizedBox(height: 12), cards[1]]);
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                ],
              ),
            );
          },
        ),
        const InfoBanner(
          'O ranking e os pontos aparecem somente para o Administrador (RF046).',
          icon: Icons.visibility_outlined,
        ),
        SectionCard(
          title: g.nome,
          subtitle:
              'Gincana do $nomeLocal · competições de ${formatarDiaCurto(g.inicio)}/${g.inicio.year} '
              'a ${formatarDiaCurto(g.fim)}/${g.fim.year} · ${store.statusSemana(g)}',
          trailing: OutlinedButton.icon(
            icon: const Icon(Icons.edit_calendar),
            label: const Text('Editar semana'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GincanaFormScreen())),
          ),
          child: const SizedBox.shrink(),
        ),
        SectionCard(
          title: g.encerrada ? 'Gincana finalizada' : 'Encerramento',
          subtitle: g.encerrada
              ? 'Finalizada em ${formatarData(g.encerradaEm!)} às ${formatarHora(g.encerradaEm!)}'
              : '${store.partidasPendentes.length} partida(s) ainda não encerrada(s)',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.description_outlined),
                label: Text(g.encerrada ? 'Relatório final' : 'Prévia do relatório'),
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RelatorioFinalScreen())),
              ),
              if (g.encerrada)
                TextButton(onPressed: store.reabrirGincana, child: const Text('Reabrir'))
              else
                FilledButton.icon(
                  icon: const Icon(Icons.flag),
                  label: const Text('Finalizar gincana'),
                  onPressed: () => showDialog(context: context, builder: (_) => const FinalizarGincanaDialog()),
                ),
            ],
          ),
          child: const SizedBox.shrink(),
        ),
        SectionCard(
          title: 'Pontuação por modalidade',
          subtitle: '$encerradas de ${partidas.length} partidas encerradas',
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              columns: [
                const DataColumn(label: Text('Modalidade')),
                const DataColumn(label: Text('Peso'), numeric: true),
                for (final e in g.equipes) DataColumn(label: EquipeLabel(e), numeric: true),
              ],
              rows: [
                for (final m in store.modalidadesDaGincana)
                  DataRow(
                    cells: [
                      DataCell(Text(m.nome)),
                      DataCell(Text('×${formatarPontos(m.peso)}')),
                      for (final e in g.equipes)
                        DataCell(Text(formatarPontos(store.rankingModalidade(m.id)[e.id] ?? 0))),
                    ],
                  ),
              ],
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final divisao = SectionCard(
              title: 'Divisão das equipes',
              subtitle: store.textoDivisao(g),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in g.equipes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: EquipeLabel(e, texto: '${e.nome}: ${e.participantes.length} participantes'),
                    ),
                  const SizedBox(height: 6),
                  if (inconsist.isEmpty)
                    const Tag('Nenhum participante nas duas equipes', icon: Icons.verified, color: Color(0xFF1B7F3B))
                  else
                    Tag('Inconsistência: ${inconsist.join(', ')}', icon: Icons.warning_amber, color: Colors.red),
                  const SizedBox(height: 6),
                  Text('A divisão não muda até o encerramento da gincana (RN018).', style: t.bodySmall),
                ],
              ),
            );
            final ultimas = SectionCard(
              title: 'Últimas pontuações',
              child: Column(
                children: [
                  for (final p in store.pontuacoesDaGincana.take(6))
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: EquipeDot(store.equipe(p.equipeId).cor),
                      title: Text(
                        p.descricao,
                        style: p.cancelada ? const TextStyle(decoration: TextDecoration.lineThrough) : null,
                      ),
                      trailing: Text(
                        p.cancelada ? 'estornado' : '+${formatarPontos(p.valor)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  if (store.pontuacoesDaGincana.isEmpty)
                    const EmptyState(icon: Icons.scoreboard_outlined, text: 'Sem pontuações ainda'),
                ],
              ),
            );
            if (c.maxWidth < 800) return Column(children: [divisao, const SizedBox(height: 16), ultimas]);
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: divisao),
                  const SizedBox(width: 16),
                  Expanded(child: ultimas),
                ],
              ),
            );
          },
        ),
        SectionCard(
          title: 'Auditoria',
          subtitle: 'Ações críticas registradas (RNF007)',
          child: Column(
            children: [
              for (final l in store.logs.take(8))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, size: 18),
                  title: Text(l.acao),
                  subtitle: Text('${store.usuario(l.usuarioId).nome} · ${formatarHora(l.data)}'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
