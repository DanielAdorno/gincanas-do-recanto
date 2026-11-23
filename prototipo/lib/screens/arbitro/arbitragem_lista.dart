import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import '../../widgets/partida_tile.dart';
import 'arbitragem.dart';

/// Menu de Arbitragem do Administrador/Árbitro (RF031).
/// [todas] = false mostra só as partidas designadas a ele; true mostra todas da gincana.
class ArbitragemListaScreen extends StatelessWidget {
  final bool todas;
  const ArbitragemListaScreen({super.key, this.todas = false});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final lista = todas ? store.partidasDaGincana : store.partidasDoArbitro(store.usuarioAtual!.id);
    Widget grupo(StatusPartida s, String titulo) {
      final l = lista.where((p) => p.status == s).toList();
      if (l.isEmpty && s != StatusPartida.agendada) return const SizedBox.shrink();
      return SectionCard(
        title: titulo,
        subtitle: '${l.length} partida(s)',
        child: l.isEmpty
            ? EmptyState(
                icon: Icons.event_available,
                text: todas ? 'Nenhuma partida agendada' : 'Nenhuma partida agendada para você',
              )
            : Column(
                children: [
                  for (final p in l)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PartidaTile(
                        p,
                        mostrarModalidade: true,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArbitragemScreen(p.id))),
                      ),
                    ),
                ],
              ),
      );
    }

    return PageBody(
      maxWidth: 720,
      children: [
        InfoBanner(
          todas
              ? 'Todas as partidas da gincana. Como Administrador, você pode arbitrar qualquer uma, mesmo sem estar designado (RN009).'
              : 'Partidas em que você foi designado como árbitro. Toque em uma para abrir a tela de arbitragem.',
        ),
        grupo(StatusPartida.emAndamento, 'Em andamento'),
        grupo(StatusPartida.agendada, 'Próximas partidas'),
        grupo(StatusPartida.encerrada, 'Encerradas'),
      ],
    );
  }
}
