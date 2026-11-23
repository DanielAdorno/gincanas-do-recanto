import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import '../../widgets/partida_tile.dart';
import 'nova_partida.dart';
import 'partida_detalhe.dart';

/// Agenda de partidas do Administrador: calendário da gincana, partidas do dia em ordem de horário
/// e lançamento de novas partidas com data e horário (RF065).
class PartidasScreen extends StatefulWidget {
  const PartidasScreen({super.key});

  @override
  State<PartidasScreen> createState() => _PartidasScreenState();
}

class _PartidasScreenState extends State<PartidasScreen> {
  DateTime? _dia; // null = todos os dias
  bool _iniciado = false;
  String? _modalidade; // filtro opcional

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!_iniciado || (_dia != null && !store.semanaDaGincana.any((d) => mesmoDia(d, _dia!)))) {
      _dia = store.diaPadrao;
      _iniciado = true;
    }
    final todas = store.partidasDaGincana
        .where((p) => _modalidade == null || store.modalidadeDaPartida(p).id == _modalidade)
        .toList();
    final dias = store.semanaDaGincana;
    final doDia = _dia == null ? todas : todas.where((p) => mesmoDia(p.dataHora, _dia!)).toList();

    // Agrupa por dia (quando "Todos") e mantém ordem de horário.
    final grupos = <DateTime, List<Partida>>{};
    for (final p in doDia) {
      grupos.putIfAbsent(DateTime(p.dataHora.year, p.dataHora.month, p.dataHora.day), () => []).add(p);
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nova-partida',
        onPressed: store.gincanaAtual!.encerrada
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NovaPartidaScreen(modalidadeId: _modalidade, diaInicial: _dia),
                ),
              ),
        icon: const Icon(Icons.add),
        label: const Text('Nova partida'),
      ),
      body: PageBody(
        children: [
          SectionCard(
            title: 'Calendário',
            subtitle: '${todas.length} partida(s) na gincana · toque em um dia',
            trailing: DropdownButton<String?>(
              value: _modalidade,
              hint: const Text('Todas as modalidades'),
              underline: const SizedBox.shrink(),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas as modalidades')),
                for (final m in store.modalidadesDaGincana) DropdownMenuItem(value: m.id, child: Text(m.nome)),
              ],
              onChanged: (v) => setState(() => _modalidade = v),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _TodosChip(selecionado: _dia == null, qtd: todas.length, onTap: () => setState(() => _dia = null)),
                  const SizedBox(width: 8),
                  for (final d in dias)
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
          if (grupos.isEmpty)
            SectionCard(
              title: _dia == null ? 'Partidas' : formatarDiaCurto(_dia!),
              child: const EmptyState(
                icon: Icons.event_busy_outlined,
                text: 'Nenhuma partida neste dia.\nUse "Nova partida" para agendar.',
              ),
            ),
          for (final e in grupos.entries)
            SectionCard(
              title: '${formatarDiaCurto(e.key)}${mesmoDia(e.key, DateTime.now()) ? ' · hoje' : ''}',
              subtitle: '${e.value.length} partida(s)',
              child: Column(children: [for (final p in e.value) _LinhaAgenda(p)]),
            ),
        ],
      ),
    );
  }
}

class _TodosChip extends StatelessWidget {
  final bool selecionado;
  final int qtd;
  final VoidCallback onTap;
  const _TodosChip({required this.selecionado, required this.qtd, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? cs.primary : cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selecionado ? cs.primary : cs.outlineVariant),
        ),
        child: Column(
          children: [
            Text('Todos', style: TextStyle(fontSize: 12, color: selecionado ? cs.onPrimary : cs.onSurfaceVariant)),
            Icon(Icons.calendar_view_week, color: selecionado ? cs.onPrimary : cs.onSurface),
            Text('$qtd', style: TextStyle(fontSize: 11, color: selecionado ? cs.onPrimary : cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Linha da agenda: horário em destaque à esquerda e o cartão da partida.
class _LinhaAgenda extends StatelessWidget {
  final Partida p;
  const _LinhaAgenda(this.p);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  Text(formatarHora(p.dataHora), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (p.status == StatusPartida.agendada && !store.gincanaAtual!.encerrada)
                    IconButton(
                      tooltip: 'Reagendar',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_calendar, size: 20),
                      onPressed: () => reagendarPartida(context, p),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: PartidaTile(
              p,
              mostrarModalidade: true,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartidaDetalheScreen(p.id))),
            ),
          ),
        ],
      ),
    );
  }
}
