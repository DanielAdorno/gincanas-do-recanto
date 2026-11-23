import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import 'gincana_form.dart';

/// Semanas do acampamento (RF071): local único, uma gincana por semana, sem sobreposição.
class SemanasScreen extends StatelessWidget {
  const SemanasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final semanas = store.semanas;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'nova-semana',
        onPressed: () => showDialog(context: context, builder: (_) => const _NovaSemanaDialog()),
        icon: const Icon(Icons.add),
        label: const Text('Nova semana'),
      ),
      body: PageBody(
        maxWidth: 820,
        children: [
          InfoBanner(
            'A gincana acontece sempre no $nomeLocal, em semanas separadas (1ª, 2ª, 3ª...). '
            'Cada semana tem suas equipes, modalidades, partidas e ranking. Duas semanas nunca acontecem ao mesmo tempo.',
            icon: Icons.date_range,
          ),
          for (final g in semanas) _SemanaCard(g),
        ],
      ),
    );
  }
}

class _SemanaCard extends StatelessWidget {
  final Gincana g;
  const _SemanaCard(this.g);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final atual = store.gincanaAtual?.id == g.id;
    final status = store.statusSemana(g);
    final cor = switch (status) {
      'Em andamento' => const Color(0xFF1B7F3B),
      'Planejada' => const Color(0xFF1F5FD1),
      'Finalizada' => const Color(0xFF6A4BC4),
      _ => Colors.grey,
    };
    final nMods = store.modalidades.where((m) => m.gincanaId == g.id).length;
    final nPart = store.partidasDe(g).length;
    final nPessoas = g.equipes.fold<int>(0, (a, e) => a + e.participantes.length);
    final temPerfil = store.perfisDe(store.usuarioAtual!.id, g.id).isNotEmpty;
    final sexta = DateTime(g.inicio.year, g.inicio.month, g.inicio.day + 6);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: atual ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(g.nome, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Tag(status, color: cor),
                if (atual) ...[const SizedBox(width: 6), const Tag('Aberta agora', icon: Icons.visibility)],
                const Spacer(),
                IconButton(
                  tooltip: 'Editar semana',
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: temPerfil
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GincanaFormScreen(gincanaId: g.id)),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sáb ${formatarData(g.inicio)} a Sex ${formatarData(sexta)} · competições até Qui ${formatarData(g.fim)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Tag(
                  g.divisaoRecebidaEm == null ? 'Aguardando divisão das equipes' : '$nPessoas participantes',
                  icon: g.divisaoRecebidaEm == null ? Icons.hourglass_top : Icons.groups,
                  color: g.divisaoRecebidaEm == null ? const Color(0xFFB26A00) : const Color(0xFF00796B),
                ),
                Tag('$nMods modalidade(s)', icon: Icons.sports_soccer_outlined),
                Tag('$nPart partida(s)', icon: Icons.event_note_outlined),
              ],
            ),
            if (!atual && temPerfil) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.login),
                label: Text('Abrir ${g.nome}'),
                onPressed: () {
                  store.trocarSemana(g);
                  mostrarMensagem(context, 'Agora você está na ${g.nome}');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NovaSemanaDialog extends StatefulWidget {
  const _NovaSemanaDialog();

  @override
  State<_NovaSemanaDialog> createState() => _NovaSemanaDialogState();
}

class _NovaSemanaDialogState extends State<_NovaSemanaDialog> {
  DateTime? _inicio;
  String? _copiarDe;
  bool _iniciado = false;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    if (!_iniciado) {
      _inicio = store.proximoSabadoLivre;
      // Sugere copiar da última semana que já tem modalidades.
      _copiarDe = store.semanas
          .lastWhere((g) => store.modalidades.any((m) => m.gincanaId == g.id), orElse: () => store.semanas.first)
          .id;
      _iniciado = true;
    }
    final conflito = store.sobreposicao(_inicio!);
    final nome = '${store.gincanas.length + 1}ª Semana';

    return AlertDialog(
      title: Text('Nova semana · $nome'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              icon: const Icon(Icons.calendar_month),
              label: Text('Início: ${formatarDiaCurto(_inicio!)}/${_inicio!.year}'),
              onPressed: () async {
                final d = await escolherSabado(context, _inicio!);
                if (d != null) setState(() => _inicio = d);
              },
            ),
            const SizedBox(height: 10),
            ResumoSemana(inicio: _inicio!),
            if (conflito != null) ...[
              const SizedBox(height: 10),
              Text(
                'Sobrepõe a ${conflito.nome}. Escolha outro sábado: as semanas não podem acontecer ao mesmo tempo.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _copiarDe,
              decoration: const InputDecoration(labelText: 'Modalidades'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Começar sem modalidades')),
                for (final g in store.semanas)
                  DropdownMenuItem(value: g.id, child: Text('Copiar modalidades da ${g.nome}')),
              ],
              onChanged: (v) => setState(() => _copiarDe = v),
            ),
            const SizedBox(height: 10),
            Text(
              'As equipes ficam aguardando a divisão do sistema existente. Copia-se a configuração das '
              'modalidades e fases; times e partidas são criados na nova semana.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: conflito != null
              ? null
              : () {
                  final g = store.criarSemana(inicio: _inicio!, copiarDe: _copiarDe);
                  Navigator.pop(context);
                  mostrarMensagem(context, '${g.nome} cadastrada: ${formatarData(g.inicio)} a ${formatarData(g.fim)}');
                },
          child: const Text('Cadastrar semana'),
        ),
      ],
    );
  }
}
