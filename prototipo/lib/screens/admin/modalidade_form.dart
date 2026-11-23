import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import 'modalidade_detalhe.dart';

/// Cadastro/edição de modalidade (RF010–RF016).
class ModalidadeFormScreen extends StatefulWidget {
  final Modalidade? modalidade;
  const ModalidadeFormScreen({super.key, this.modalidade});

  @override
  State<ModalidadeFormScreen> createState() => _ModalidadeFormScreenState();
}

class _ModalidadeFormScreenState extends State<ModalidadeFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.modalidade?.nome);
  late final _categoria = TextEditingController(text: widget.modalidade?.categoria ?? 'Esporte coletivo');
  late final _unidade = TextEditingController(text: widget.modalidade?.unidade ?? 'gol');
  late final _vit = TextEditingController(text: '${widget.modalidade?.pontosVitoria ?? 100}');
  late final _emp = TextEditingController(text: '${widget.modalidade?.pontosEmpate ?? 50}');
  late final _der = TextEditingController(text: '${widget.modalidade?.pontosDerrota ?? 0}');
  late final _col = TextEditingController(text: (widget.modalidade?.pontosColocacao ?? [100, 70, 40, 20]).join(', '));
  late double _peso = widget.modalidade?.peso ?? 1;
  late TipoMarcacao _tipo = widget.modalidade?.tipo ?? TipoMarcacao.placar;
  late RegraEmpate _empElim = widget.modalidade?.regraEmpateEliminatoria ?? RegraEmpate.penaltis;
  late RegraEmpate _empPont = widget.modalidade?.regraEmpatePontuada ?? RegraEmpate.empateAceito;
  late bool _todaEquipe = widget.modalidade != null && widget.modalidade!.participantesPorTime == null;
  late int _qtd = widget.modalidade?.participantesPorTime ?? 5;
  late bool _temReserva = (widget.modalidade?.reservas ?? 0) > 0;
  late int _reservas = (widget.modalidade?.reservas ?? 0) > 0 ? widget.modalidade!.reservas : 2;

  bool get _editando => widget.modalidade != null;

  String? _obrigatorio(String? v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;
  String? _inteiro(String? v) => int.tryParse(v?.trim() ?? '') == null ? 'Número inteiro' : null;

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    final store = AppScope.of(context);
    final col = _col.text.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();
    void aplicar(Modalidade m) {
      m
        ..nome = _nome.text.trim()
        ..categoria = _categoria.text.trim()
        ..tipo = _tipo
        ..unidade = _unidade.text.trim()
        ..pontosVitoria = int.parse(_vit.text)
        ..pontosEmpate = int.parse(_emp.text)
        ..pontosDerrota = int.parse(_der.text)
        ..pontosColocacao = col
        ..peso = _peso
        ..regraEmpateEliminatoria = _empElim
        ..regraEmpatePontuada = _empPont
        ..participantesPorTime = _todaEquipe ? null : _qtd
        ..reservas = _todaEquipe || !_temReserva ? 0 : _reservas;
    }

    if (_editando) {
      aplicar(widget.modalidade!);
      store.atualizarModalidade(widget.modalidade!);
      Navigator.pop(context);
    } else {
      final m = store.criarModalidade((id) {
        final m = Modalidade(id: id, gincanaId: store.gincanaAtual!.id, nome: '', categoria: '', tipo: _tipo);
        aplicar(m);
        return m;
      });
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ModalidadeDetalheScreen(m.id)));
    }
    mostrarMensagem(context, 'Modalidade salva');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final travado = _editando && store.modalidadeTemMarcacoes(widget.modalidade!.id);
    final placar = _tipo == TipoMarcacao.placar;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar modalidade' : 'Nova modalidade')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(onPressed: _salvar, icon: const Icon(Icons.check), label: const Text('Salvar')),
        ),
      ),
      body: Form(
        key: _form,
        child: PageBody(
          maxWidth: 720,
          children: [
            SectionCard(
              title: 'Dados da modalidade',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nome,
                    validator: _obrigatorio,
                    decoration: const InputDecoration(labelText: 'Nome', hintText: 'Ex: Futebol Adulto'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoria,
                    validator: _obrigatorio,
                    decoration: const InputDecoration(labelText: 'Categoria', hintText: 'Ex: Esporte coletivo'),
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'Tipo de marcação',
              subtitle: 'Como o árbitro vai registrar o resultado (RF012)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<TipoMarcacao>(
                    segments: const [
                      ButtonSegment(
                        value: TipoMarcacao.placar,
                        icon: Icon(Icons.scoreboard_outlined),
                        label: Text('Placar'),
                      ),
                      ButtonSegment(value: TipoMarcacao.tempo, icon: Icon(Icons.timer_outlined), label: Text('Tempo')),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: travado ? null : (s) => setState(() => _tipo = s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    placar
                        ? 'O árbitro marca gols/pontos de cada time em um placar ao vivo. Vence quem tiver mais.'
                        : 'O árbitro usa um cronômetro e registra o tempo de cada participante. Vence o menor tempo.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (travado)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: InfoBanner(
                        'Esta modalidade já tem partidas iniciadas; o tipo de marcação não pode mudar.',
                      ),
                    ),
                  if (placar) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _unidade,
                      validator: _obrigatorio,
                      decoration: const InputDecoration(
                        labelText: 'Unidade de marcação',
                        hintText: 'gol, ponto, set...',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SectionCard(
              title: 'Participantes por time',
              subtitle: 'Quantos competidores cada time escala nesta modalidade (RF070)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, icon: Icon(Icons.pin_outlined), label: Text('Quantidade definida')),
                      ButtonSegment(value: true, icon: Icon(Icons.groups), label: Text('Toda a equipe')),
                    ],
                    selected: {_todaEquipe},
                    onSelectionChanged: (s) => setState(() => _todaEquipe = s.first),
                  ),
                  const SizedBox(height: 12),
                  if (_todaEquipe)
                    Text(
                      'Todos os participantes da equipe podem ser escalados (ex: gincana bíblica). Não há reservas.',
                      style: Theme.of(context).textTheme.bodySmall,
                    )
                  else ...[
                    _Contador(
                      rotulo: 'Titulares por time',
                      valor: _qtd,
                      min: 1,
                      max: 50,
                      onChanged: (v) => setState(() => _qtd = v),
                    ),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Permite reservas'),
                      subtitle: Text(
                        _temReserva ? 'Além dos titulares, o Líder pode escalar reservas' : 'Sem reservas',
                      ),
                      value: _temReserva,
                      onChanged: (v) => setState(() => _temReserva = v),
                    ),
                    if (_temReserva)
                      _Contador(
                        rotulo: 'Reservas por time',
                        valor: _reservas,
                        min: 1,
                        max: 20,
                        onChanged: (v) => setState(() => _reservas = v),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Cada time terá $_qtd titular(es)${_temReserva ? ' e até $_reservas reserva(s)' : ''}.',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            SectionCard(
              title: 'Pontos da gincana',
              subtitle: 'Pontos que a equipe ganha pelo resultado, antes do peso (RF014/RF016)',
              child: Column(
                children: [
                  if (placar)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _vit,
                            validator: _inteiro,
                            decoration: const InputDecoration(labelText: 'Vitória'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emp,
                            validator: _inteiro,
                            decoration: const InputDecoration(labelText: 'Empate'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _der,
                            validator: _inteiro,
                            decoration: const InputDecoration(labelText: 'Derrota'),
                          ),
                        ),
                      ],
                    )
                  else
                    TextFormField(
                      controller: _col,
                      validator: (v) => (v ?? '').split(',').any((s) => int.tryParse(s.trim()) == null)
                          ? 'Use números separados por vírgula'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Pontos por colocação (1º, 2º, 3º...)',
                        hintText: '100, 70, 40, 20',
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Peso'),
                      Expanded(
                        child: Slider(
                          value: _peso,
                          min: 0.5,
                          max: 5,
                          divisions: 9,
                          label: '×${formatarPontos(_peso)}',
                          onChanged: (v) => setState(() => _peso = v),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text('×${formatarPontos(_peso)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'Regra de empate',
              subtitle: 'Cada modalidade trata o empate do seu jeito (RF015)',
              child: Column(
                children: [
                  DropdownButtonFormField<RegraEmpate>(
                    initialValue: _empElim,
                    decoration: const InputDecoration(labelText: 'Fases eliminatórias (sempre exigem vencedor)'),
                    items: [
                      for (final r in RegraEmpate.values.where((r) => r != RegraEmpate.empateAceito))
                        DropdownMenuItem(value: r, child: Text(r.label)),
                    ],
                    onChanged: (v) => setState(() => _empElim = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RegraEmpate>(
                    initialValue: _empPont,
                    decoration: const InputDecoration(labelText: 'Fases que valem pontos'),
                    items: [for (final r in RegraEmpate.values) DropdownMenuItem(value: r, child: Text(r.label))],
                    onChanged: (v) => setState(() => _empPont = v!),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo numérico com botões − / +.
class _Contador extends StatelessWidget {
  final String rotulo;
  final int valor, min, max;
  final ValueChanged<int> onChanged;
  const _Contador({
    required this.rotulo,
    required this.valor,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(rotulo)),
        IconButton.outlined(onPressed: valor > min ? () => onChanged(valor - 1) : null, icon: const Icon(Icons.remove)),
        SizedBox(
          width: 48,
          child: Text(
            '$valor',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        IconButton.outlined(onPressed: valor < max ? () => onChanged(valor + 1) : null, icon: const Icon(Icons.add)),
      ],
    );
  }
}
