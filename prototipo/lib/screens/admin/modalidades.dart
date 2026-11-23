import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import 'modalidade_detalhe.dart';
import 'modalidade_form.dart';

class ModalidadesScreen extends StatelessWidget {
  const ModalidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final mods = store.modalidadesDaGincana;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModalidadeFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Nova modalidade'),
      ),
      body: PageBody(
        children: [
          if (mods.isEmpty) const EmptyState(icon: Icons.sports, text: 'Nenhuma modalidade cadastrada'),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
              final w = (c.maxWidth - (cols - 1) * 16) / cols;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [for (final m in mods) SizedBox(width: w, child: _ModalidadeCard(m))],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ModalidadeCard extends StatelessWidget {
  final Modalidade m;
  const _ModalidadeCard(this.m);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final nTimes = store.timesDa(m.id).length;
    final partidas = store.partidasDaModalidade(m.id);
    final enc = partidas.where((p) => p.status == StatusPartida.encerrada).length;
    final placar = m.tipo == TipoMarcacao.placar;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ModalidadeDetalheScreen(m.id))),
        child: Opacity(
          opacity: m.ativa ? 1 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      placar ? Icons.scoreboard_outlined : Icons.timer_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(m.nome, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                    if (!m.ativa) const Tag('Inativa', color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 4),
                Text(m.categoria, style: t.bodySmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Tag(
                      placar ? 'Placar · ${m.unidade}' : 'Tempo · cronômetro',
                      icon: placar ? Icons.add_circle_outline : Icons.timer,
                    ),
                    Tag('Peso ×${formatarPontos(m.peso)}', color: const Color(0xFF6A4BC4)),
                    Tag(m.descricaoParticipantes, icon: Icons.groups_outlined, color: const Color(0xFF00796B)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '$nTimes times · ${store.fasesDa(m.id).length} fases · $enc/${partidas.length} partidas encerradas',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
