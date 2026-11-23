import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';

/// O Líder vê apenas os resultados da própria equipe por modalidade, sem pontos (RF048).
class ResultadosScreen extends StatelessWidget {
  const ResultadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final eq = store.equipeDoLider!;
    final mods = store.modalidadesDaGincana.where((m) => store.timesDa(m.id, equipeId: eq.id).isNotEmpty).toList();

    return PageBody(
      maxWidth: 820,
      children: [
        const InfoBanner(
          'Você vê os resultados dos times da sua equipe. Pontos e ranking da gincana ficam só com o Administrador.',
          icon: Icons.visibility_off_outlined,
        ),
        for (final m in mods) _ModalidadeResultado(m, eq),
        if (mods.isEmpty) const EmptyState(icon: Icons.emoji_events_outlined, text: 'Ainda não há resultados'),
      ],
    );
  }
}

class _ModalidadeResultado extends StatelessWidget {
  final Modalidade m;
  final Equipe eq;
  const _ModalidadeResultado(this.m, this.eq);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final meus = store.timesDa(m.id, equipeId: eq.id).map((t) => t.id).toSet();
    final linhas = <Widget>[];
    for (final f in store.fasesDa(m.id)) {
      for (final p in store.partidasDa(f.id)..sort((a, b) => a.dataHora.compareTo(b.dataHora))) {
        for (final tid in p.timeIds.where(meus.contains)) {
          linhas.add(_linha(context, store, f, p, tid));
        }
      }
    }
    return SectionCard(
      title: m.nome,
      subtitle: m.tipo == TipoMarcacao.placar ? 'Placar · ${m.unidade}' : 'Tempo',
      child: linhas.isEmpty
          ? const EmptyState(icon: Icons.event_outlined, text: 'Nenhuma partida da sua equipe ainda')
          : Column(children: linhas),
    );
  }

  Widget _linha(BuildContext context, AppStore store, Fase f, Partida p, String tid) {
    final t = store.time(tid);
    String resultado;
    Color cor;
    IconData icon;
    if (p.status != StatusPartida.encerrada) {
      resultado = p.status == StatusPartida.emAndamento
          ? 'Em andamento'
          : 'Agendada · ${formatarDiaCurto(p.dataHora)} ${formatarHora(p.dataHora)}';
      cor = Colors.grey;
      icon = Icons.schedule;
    } else if (store.modalidadeDaPartida(p).tipo == TipoMarcacao.tempo) {
      final pos = p.classificacao.indexOf(tid) + 1;
      resultado = '$posº lugar${p.tempos[tid] != null ? ' · ${formatarTempo(p.tempos[tid]!)}' : ''}';
      cor = pos == 1 ? const Color(0xFF1B7F3B) : const Color(0xFF5C6BC0);
      icon = pos == 1 ? Icons.emoji_events : Icons.flag;
    } else if (p.empate) {
      resultado = 'Empate';
      cor = const Color(0xFF8D6E63);
      icon = Icons.drag_handle;
    } else if (p.vencedorId == tid) {
      resultado = f.valePontos ? 'Vitória' : 'Vitória · classificado';
      cor = const Color(0xFF1B7F3B);
      icon = f.valePontos ? Icons.emoji_events : Icons.arrow_upward;
    } else {
      resultado = f.valePontos ? 'Derrota' : 'Derrota · eliminado';
      cor = const Color(0xFFC62828);
      icon = Icons.close;
    }
    final adversarios = p.timeIds.where((x) => x != tid).map((x) => store.time(x).nome).join(', ');
    final outro = p.timeIds.firstWhere((x) => x != tid);
    final desempate = p.placarDesempate.isNotEmpty
        ? ' (desempate ${p.placarDesempate[tid]} × ${p.placarDesempate[outro]})'
        : '';
    final placar = store.modalidadeDaPartida(p).tipo == TipoMarcacao.placar && p.status != StatusPartida.agendada
        ? ' · ${p.placar[tid]} × ${p.placar[outro]}$desempate'
        : '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: cor.withValues(alpha: 0.12),
        child: Icon(icon, color: cor),
      ),
      title: Text('${t.nome} · ${f.nome}'),
      subtitle: Text('contra $adversarios$placar'),
      trailing: Tag(resultado, color: cor),
    );
  }
}
