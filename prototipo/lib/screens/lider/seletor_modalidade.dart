import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';

/// Chips horizontais para escolher a modalidade nas telas do Líder.
class SeletorModalidade extends StatelessWidget {
  final String? selecionada;
  final ValueChanged<String> onChanged;
  final bool Function(Modalidade m)? filtro;
  const SeletorModalidade({super.key, required this.selecionada, required this.onChanged, this.filtro});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final mods = store.modalidadesDaGincana.where((m) => m.ativa && (filtro?.call(m) ?? true)).toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final m in mods)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  m.tipo == TipoMarcacao.placar ? Icons.scoreboard_outlined : Icons.timer_outlined,
                  size: 18,
                ),
                label: Text(m.nome),
                selected: selecionada == m.id,
                onSelected: (_) => onChanged(m.id),
              ),
            ),
        ],
      ),
    );
  }
}
