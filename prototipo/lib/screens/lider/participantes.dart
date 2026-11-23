import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/busca.dart';
import '../../widgets/common.dart';
import '../../widgets/medalha.dart';

enum _Filtro { todos, inscritos, semInscricao }

/// Página inicial do Líder: todos os participantes da equipe e suas inscrições, com busca.
class ParticipantesScreen extends StatefulWidget {
  const ParticipantesScreen({super.key});

  @override
  State<ParticipantesScreen> createState() => _ParticipantesScreenState();
}

class _ParticipantesScreenState extends State<ParticipantesScreen> {
  final _busca = TextEditingController();
  final _foco = FocusNode();
  _Filtro _filtro = _Filtro.todos;

  @override
  void dispose() {
    _busca.dispose();
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final eq = store.equipeDoLider!;
    final g = store.gincanaAtual!;
    final mods = store.modalidadesDaGincana.where((m) => m.ativa).toList();

    // Modalidades de cada participante (calculado uma vez por build).
    final med = store.medalhas();
    final porPessoa = <String, List<Modalidade>>{
      for (final uid in eq.participantes)
        uid: [
          for (final m in mods)
            if (store.inscritos(m.id).contains(uid)) m,
        ],
    };
    final total = eq.participantes.length;
    final comInscricao = porPessoa.values.where((l) => l.isNotEmpty).length;
    final semInscricao = total - comInscricao;

    final termo = normalizar(_busca.text.trim());
    final lista =
        eq.participantes.where((uid) {
          final insc = porPessoa[uid]!.isNotEmpty;
          if (_filtro == _Filtro.inscritos && !insc) return false;
          if (_filtro == _Filtro.semInscricao && insc) return false;
          return casaBusca(store.usuario(uid).nome, termo);
        }).toList()..sort(
          (a, b) => termo.isEmpty
              ? store.usuario(a).nome.compareTo(store.usuario(b).nome)
              : ordemBusca(store.usuario(a).nome, store.usuario(b).nome, termo),
        );

    Widget centro(Widget w) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: w),
      ),
    );

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: centro(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Participantes da ${eq.nome}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${store.textoDivisao(g)} · não muda até o fim da semana',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, c) {
                    final cards = [
                      _Resumo('Participantes', '$total', Icons.groups, eq.cor),
                      _Resumo(
                        'Inscritos em algo',
                        '$comInscricao',
                        Icons.how_to_reg,
                        const Color(0xFF1B7F3B),
                        sub: '${(comInscricao * 100 / (total == 0 ? 1 : total)).round()}%',
                      ),
                      _Resumo('Sem inscrição', '$semInscricao', Icons.person_off_outlined, const Color(0xFFB26A00)),
                    ];
                    final cols = c.maxWidth >= 600 ? 3 : 1;
                    final w = (c.maxWidth - (cols - 1) * 12) / cols;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [for (final x in cards) SizedBox(width: w, child: x)],
                    );
                  },
                ),
                const SizedBox(height: 16),
                CampoBusca(
                  controller: _busca,
                  focusNode: _foco,
                  hint: 'Buscar entre os $total participantes...',
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (lista.isNotEmpty) _abrir(context, lista.first);
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text('Todos ($total)'),
                      selected: _filtro == _Filtro.todos,
                      onSelected: (_) => setState(() => _filtro = _Filtro.todos),
                    ),
                    ChoiceChip(
                      label: Text('Inscritos ($comInscricao)'),
                      selected: _filtro == _Filtro.inscritos,
                      onSelected: (_) => setState(() => _filtro = _Filtro.inscritos),
                    ),
                    ChoiceChip(
                      label: Text('Sem inscrição ($semInscricao)'),
                      selected: _filtro == _Filtro.semInscricao,
                      onSelected: (_) => setState(() => _filtro = _Filtro.semInscricao),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${lista.length} na lista${termo.isNotEmpty && lista.isNotEmpty ? ' · Enter abre o primeiro' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (lista.isEmpty) const EmptyState(icon: Icons.person_search, text: 'Nenhum participante encontrado'),
              ],
            ),
          ),
        ),
        SliverList.builder(
          itemCount: lista.length,
          itemBuilder: (context, i) {
            final uid = lista[i];
            return centro(
              _LinhaParticipante(
                uid: uid,
                equipe: eq,
                modalidades: porPessoa[uid]!,
                medalha: med[uid],
                termo: termo,
                onTap: () => _abrir(context, uid),
              ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  void _abrir(BuildContext context, String uid) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (_) => _FichaParticipante(uid),
  );
}

class _Resumo extends StatelessWidget {
  final String titulo, valor;
  final String? sub;
  final IconData icon;
  final Color cor;
  const _Resumo(this.titulo, this.valor, this.icon, this.cor, {this.sub});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.12),
              child: Icon(icon, color: cor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: Theme.of(context).textTheme.bodySmall),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        valor,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: cor),
                      ),
                      if (sub != null) ...[
                        const SizedBox(width: 6),
                        Text(sub!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
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

class _LinhaParticipante extends StatelessWidget {
  final String uid;
  final Equipe equipe;
  final List<Modalidade> modalidades;
  final ResultadoModalidade? medalha;
  final String termo;
  final VoidCallback onTap;
  const _LinhaParticipante({
    required this.uid,
    required this.equipe,
    required this.modalidades,
    this.medalha,
    required this.termo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final nome = store.usuario(uid).nome;
    final inscrito = modalidades.isNotEmpty;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 6),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: equipe.cor.withValues(alpha: 0.12),
          child: Text(
            nome[0],
            style: TextStyle(color: equipe.cor, fontWeight: FontWeight.w700),
          ),
        ),
        title: NomeDestacado(nome, termo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: inscrito
              ? Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (medalha != null) MedalhaTag(medalha!),
                    for (final m in modalidades)
                      Tag(
                        m.nome,
                        icon: m.tipo == TipoMarcacao.placar ? Icons.scoreboard_outlined : Icons.timer_outlined,
                      ),
                  ],
                )
              : const Align(
                  alignment: Alignment.centerLeft,
                  child: Tag('Sem inscrição', icon: Icons.warning_amber, color: Color(0xFFB26A00)),
                ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inscrito)
              CircleAvatar(
                radius: 13,
                backgroundColor: const Color(0xFF1B7F3B),
                child: Text('${modalidades.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

/// Ficha do participante: inscrever/desinscrever em cada modalidade sem sair da página.
class _FichaParticipante extends StatelessWidget {
  final String uid;
  const _FichaParticipante(this.uid);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final eq = store.equipeDoLider!;
    final u = store.usuario(uid);
    final t = Theme.of(context).textTheme;
    final mods = store.modalidadesDaGincana.where((m) => m.ativa).toList();
    final n = mods.where((m) => store.inscritos(m.id).contains(uid)).length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: eq.cor,
                  foregroundColor: Colors.white,
                  child: Text(u.nome[0], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.nome, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(n == 0 ? 'Sem inscrição' : 'Inscrito em $n modalidade(s)', style: t.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            MedalhaAviso(uid),
            const SizedBox(height: 16),
            Text('Modalidades', style: t.titleSmall),
            Text('Ligue para inscrever, desligue para retirar a inscrição.', style: t.bodySmall),
            const SizedBox(height: 6),
            for (final m in mods)
              Builder(
                builder: (context) {
                  final inscrito = store.inscritos(m.id).contains(uid);
                  final time = store
                      .timesDa(m.id, equipeId: eq.id)
                      .where((x) => x.integrantes.contains(uid))
                      .firstOrNull;
                  final travado = time != null && store.timeBloqueado(time.id);
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(m.tipo == TipoMarcacao.placar ? Icons.scoreboard_outlined : Icons.timer_outlined),
                    title: Text(m.nome),
                    subtitle: Text(
                      !inscrito
                          ? 'Não inscrito'
                          : time == null
                          ? 'Inscrito · ainda sem time'
                          : 'Time: ${time.nome}${travado ? ' (partida em andamento)' : ''}',
                    ),
                    value: inscrito,
                    onChanged: travado ? null : (_) => store.alternarInscricao(m.id, uid),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
