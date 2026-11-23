import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';

/// Edição de uma semana da gincana (RF066). A semana pode ser em qualquer mês/ano, sempre começa no sábado
/// e as competições vão até quinta (RN021). Semanas não podem se sobrepor (RN016).
class GincanaFormScreen extends StatefulWidget {
  /// Semana a editar; se nulo, a semana atual.
  final String? gincanaId;
  const GincanaFormScreen({super.key, this.gincanaId});

  @override
  State<GincanaFormScreen> createState() => _GincanaFormScreenState();
}

class _GincanaFormScreenState extends State<GincanaFormScreen> {
  TextEditingController? _nome;
  DateTime? _inicio;

  Gincana _g(AppStore store) =>
      widget.gincanaId == null ? store.gincanaAtual! : store.gincanas.firstWhere((x) => x.id == widget.gincanaId);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final g = _g(AppScope.of(context));
    _nome ??= TextEditingController(text: g.nome);
    _inicio ??= g.inicio;
  }

  @override
  void dispose() {
    _nome?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = _g(store);
    final inicio = _inicio!;
    final fimComp = DateTime(inicio.year, inicio.month, inicio.day + 5);
    final sexta = DateTime(inicio.year, inicio.month, inicio.day + 6);
    final delta = DateTime.utc(
      inicio.year,
      inicio.month,
      inicio.day,
    ).difference(DateTime.utc(g.inicio.year, g.inicio.month, g.inicio.day)).inDays;
    final nPartidas = store.partidasDe(g).length;
    final conflito = store.sobreposicao(inicio, ignorarId: g.id);

    return Scaffold(
      appBar: AppBar(title: Text('Editar ${g.nome}')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Salvar'),
            onPressed: conflito != null
                ? null
                : () {
                    if (_nome!.text.trim().isEmpty) {
                      mostrarMensagem(context, 'Informe o nome da semana.');
                      return;
                    }
                    store.atualizarSemana(g, nome: _nome!.text.trim(), inicio: inicio);
                    Navigator.pop(context);
                    mostrarMensagem(context, '${g.nome}: ${formatarData(inicio)} a ${formatarData(fimComp)}');
                  },
          ),
        ),
      ),
      body: PageBody(
        maxWidth: 640,
        children: [
          SectionCard(
            title: 'Semana',
            subtitle: 'Gincana do $nomeLocal · local único, semanas separadas',
            child: TextField(
              controller: _nome,
              decoration: const InputDecoration(labelText: 'Nome', hintText: 'Ex: 1ª Semana'),
            ),
          ),
          SectionCard(
            title: 'Datas',
            subtitle: 'Qualquer mês e ano. Começa no sábado; as competições vão até quinta.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  icon: const Icon(Icons.calendar_month),
                  label: Text('Início: ${formatarDiaCurto(inicio)}/${inicio.year}'),
                  onPressed: g.encerrada
                      ? null
                      : () async {
                          final d = await escolherSabado(context, inicio);
                          if (d != null) setState(() => _inicio = d);
                        },
                ),
                const SizedBox(height: 12),
                ResumoSemana(inicio: inicio),
                if (conflito != null) ...[
                  const SizedBox(height: 12),
                  InfoBanner(
                    'Essa data se sobrepõe à ${conflito.nome} (${formatarData(conflito.inicio)} a '
                    '${formatarData(DateTime(conflito.inicio.year, conflito.inicio.month, conflito.inicio.day + 6))}). '
                    'As semanas não podem acontecer ao mesmo tempo.',
                    icon: Icons.block,
                  ),
                ] else if (delta != 0 && nPartidas > 0) ...[
                  const SizedBox(height: 12),
                  InfoBanner(
                    'As $nPartidas partida(s) já agendadas serão movidas junto com a semana '
                    '(${delta > 0 ? '+' : ''}$delta dia(s)), mantendo o dia da semana e o horário.',
                    icon: Icons.move_down,
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Sexta ${formatarDiaCurto(sexta).substring(4)}: sem jogos.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Calendário para escolher o sábado de início (navega por meses e anos; só sábados).
Future<DateTime?> escolherSabado(BuildContext context, DateTime inicial) => showDatePicker(
  context: context,
  initialDate: inicial,
  firstDate: DateTime(2020),
  lastDate: DateTime(2040, 12, 31),
  helpText: 'Sábado de início da semana',
  selectableDayPredicate: (d) => d.weekday == DateTime.saturday,
);

/// Etiquetas com o período de competições e a sexta sem jogos.
class ResumoSemana extends StatelessWidget {
  final DateTime inicio;
  const ResumoSemana({super.key, required this.inicio});

  @override
  Widget build(BuildContext context) {
    final fim = DateTime(inicio.year, inicio.month, inicio.day + 5);
    final sexta = DateTime(inicio.year, inicio.month, inicio.day + 6);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Tag(
          'Competições: ${formatarDiaCurto(inicio)} a ${formatarDiaCurto(fim)}/${fim.year}',
          icon: Icons.sports,
          color: const Color(0xFF1B7F3B),
        ),
        Tag('Sex ${formatarDiaCurto(sexta).substring(4)}: sem jogos', icon: Icons.block, color: Colors.grey),
      ],
    );
  }
}
