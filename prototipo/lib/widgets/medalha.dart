import 'package:flutter/material.dart';

import '../store.dart';
import 'common.dart';

const corMedalha = Color(0xFFB8860B);

/// Etiqueta curta para listas: "Medalha · Vôlei Feminino".
class MedalhaTag extends StatelessWidget {
  final ResultadoModalidade medalha;
  const MedalhaTag(this.medalha, {super.key});

  @override
  Widget build(BuildContext context) =>
      Tag('Medalha · ${medalha.modalidade.nome}', icon: Icons.workspace_premium, color: corMedalha);
}

/// Aviso na ficha da pessoa: qual modalidade deu a medalha e quais outras vitórias não dão nova medalha (RN020).
class MedalhaAviso extends StatelessWidget {
  final String usuarioId;
  const MedalhaAviso(this.usuarioId, {super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final medalha = store.medalhas()[usuarioId];
    if (medalha == null) return const SizedBox.shrink();
    final outras = store.vitoriasDe(usuarioId).where((r) => r.modalidade.id != medalha.modalidade.id).toList();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: corMedalha.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.workspace_premium, color: corMedalha, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Já tem medalha · ${medalha.modalidade.nome}',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6B4A00)),
                ),
                if (outras.isNotEmpty)
                  Text(
                    'Também venceu ${outras.map((r) => r.modalidade.nome).join(', ')}, mas não recebe outra medalha: '
                    'é uma medalha por pessoa.',
                    style: const TextStyle(color: Color(0xFF6B4A00), fontSize: 13),
                  )
                else
                  const Text(
                    'Se vencer outra modalidade, não recebe uma segunda medalha.',
                    style: TextStyle(color: Color(0xFF6B4A00), fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
