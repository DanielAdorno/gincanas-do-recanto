import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import 'common.dart';

/// Linha de partida reutilizada nas listas. Nunca mostra pontos da gincana.
class PartidaTile extends StatelessWidget {
  final Partida partida;
  final VoidCallback? onTap;
  final bool mostrarModalidade;
  const PartidaTile(this.partida, {super.key, this.onTap, this.mostrarModalidade = false});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = partida;
    final f = store.fase(p.faseId);
    final m = store.modalidade(f.modalidadeId);
    final t = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mostrarModalidade
                          ? '${m.nome} · ${f.nome}'
                          : '${f.nome} · ${formatarDiaCurto(p.dataHora)} ${formatarHora(p.dataHora)}',
                      style: t.labelMedium,
                    ),
                  ),
                  StatusBadge(p.status),
                ],
              ),
              const SizedBox(height: 8),
              ResultadoPartida(p),
              const SizedBox(height: 6),
              Text(
                '${mostrarModalidade ? '${formatarDiaCurto(p.dataHora)} ${formatarHora(p.dataHora)} · ' : ''}Árbitro: ${p.arbitroIds.map((a) => store.usuario(a).nome.split(' ').first).join(', ')}',
                style: t.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mostra os times com placar/tempo/colocação.
class ResultadoPartida extends StatelessWidget {
  final Partida partida;
  const ResultadoPartida(this.partida, {super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final p = partida;
    final m = store.modalidadeDaPartida(p);
    final iniciado = p.status != StatusPartida.agendada;

    if (m.tipo == TipoMarcacao.placar && p.timeIds.length == 2) {
      final a = store.time(p.timeIds[0]), b = store.time(p.timeIds[1]);
      Widget lado(Time tm, {bool direita = false}) {
        final venceu = p.vencedorId == tm.id;
        return Expanded(
          child: Row(
            mainAxisAlignment: direita ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!direita) ...[EquipeDot(store.equipe(tm.equipeId).cor), const SizedBox(width: 6)],
              Flexible(
                child: Text(
                  tm.nome,
                  overflow: TextOverflow.ellipsis,
                  textAlign: direita ? TextAlign.end : TextAlign.start,
                  style: TextStyle(fontWeight: venceu ? FontWeight.w800 : FontWeight.w500),
                ),
              ),
              if (direita) ...[const SizedBox(width: 6), EquipeDot(store.equipe(tm.equipeId).cor)],
            ],
          ),
        );
      }

      final desempate = p.placarDesempate.isNotEmpty ? ' (${p.placarDesempate[a.id]}–${p.placarDesempate[b.id]})' : '';
      return Row(
        children: [
          lado(a),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              iniciado ? '${p.placar[a.id]} × ${p.placar[b.id]}$desempate' : '×',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          lado(b, direita: true),
        ],
      );
    }

    final ordem = p.status == StatusPartida.encerrada ? p.classificacao : p.timeIds;
    return Column(
      children: [
        for (var i = 0; i < ordem.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                if (p.status == StatusPartida.encerrada)
                  SizedBox(
                    width: 28,
                    child: Text('${i + 1}º', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                EquipeDot(store.equipe(store.time(ordem[i]).equipeId).cor),
                const SizedBox(width: 6),
                Expanded(child: Text(store.time(ordem[i]).nome)),
                if (p.tempos[ordem[i]] != null)
                  Text(
                    formatarTempo(p.tempos[ordem[i]]!),
                    style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
