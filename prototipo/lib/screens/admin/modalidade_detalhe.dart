import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/common.dart';
import '../../widgets/partida_tile.dart';
import 'modalidade_form.dart';
import 'nova_partida.dart';
import 'partida_detalhe.dart';

class ModalidadeDetalheScreen extends StatelessWidget {
  final String modalidadeId;
  const ModalidadeDetalheScreen(this.modalidadeId, {super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final m = store.modalidades.where((x) => x.id == modalidadeId).firstOrNull;
    if (m == null) return const Scaffold();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(m.nome),
          actions: [
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ModalidadeFormScreen(modalidade: m))),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'ativa') {
                  m.ativa = !m.ativa;
                  store.atualizarModalidade(m);
                } else if (v == 'excluir') {
                  if (store.modalidadeTemMarcacoes(m.id)) {
                    mostrarMensagem(
                      context,
                      'Não é possível excluir: já há partidas com marcações (RF018). Inative-a.',
                    );
                    return;
                  }
                  if (await confirmar(
                    context,
                    'Excluir modalidade',
                    'Excluir "${m.nome}" e seus times e fases?',
                    ok: 'Excluir',
                  )) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    store.excluirModalidade(m);
                  }
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'ativa', child: Text(m.ativa ? 'Inativar nesta gincana' : 'Ativar nesta gincana')),
                const PopupMenuItem(value: 'excluir', child: Text('Excluir')),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Fases e partidas'),
              Tab(text: 'Times'),
              Tab(text: 'Configuração'),
            ],
          ),
        ),
        body: TabBarView(children: [_FasesTab(m), _TimesTab(m), _ConfigTab(m)]),
      ),
    );
  }
}

// ------------------------------------------------------------------ Configuração

class _ConfigTab extends StatelessWidget {
  final Modalidade m;
  const _ConfigTab(this.m);

  @override
  Widget build(BuildContext context) {
    final placar = m.tipo == TipoMarcacao.placar;
    Widget linha(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(a, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(b)),
        ],
      ),
    );
    return PageBody(
      maxWidth: 760,
      children: [
        SectionCard(
          title: 'Resumo',
          child: Column(
            children: [
              linha('Categoria', m.categoria),
              linha(
                'Tipo de marcação',
                placar ? 'Placar (${m.unidade}) · vence o maior placar' : 'Tempo · vence o menor tempo',
              ),
              if (placar)
                linha(
                  'Pontos por resultado',
                  'Vitória ${m.pontosVitoria} · Empate ${m.pontosEmpate} · Derrota ${m.pontosDerrota}',
                )
              else
                linha(
                  'Pontos por colocação',
                  [for (var i = 0; i < m.pontosColocacao.length; i++) '${i + 1}º ${m.pontosColocacao[i]}'].join(' · '),
                ),
              linha('Participantes', m.descricaoParticipantes),
              linha('Peso', '×${formatarPontos(m.peso)}'),
              linha('Empate em eliminatória', m.regraEmpateEliminatoria.label),
              linha('Empate em fase que vale pontos', m.regraEmpatePontuada.label),
              linha('Situação', m.ativa ? 'Ativa nesta gincana' : 'Inativa nesta gincana'),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Times

class _TimesTab extends StatelessWidget {
  final Modalidade m;
  const _TimesTab(this.m);

  Future<void> _novoTime(BuildContext context, Equipe e) async {
    final store = AppScope.of(context);
    final n = store.timesDa(m.id, equipeId: e.id).length;
    final ctrl = TextEditingController(text: '${e.nome.replaceFirst('Equipe ', '')} ${String.fromCharCode(65 + n)}');
    final nome = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Novo time — ${e.nome}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome do time'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('Criar')),
        ],
      ),
    );
    if (nome != null && nome.isNotEmpty) store.criarTime(m.id, e.id, nome);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = store.gincanaAtual!;
    return PageBody(
      children: [
        const InfoBanner(
          'O Administrador cria os times. Quem escolhe os competidores de cada time é o Líder da equipe (RF022/RF023).',
        ),
        LayoutBuilder(
          builder: (context, c) {
            final colunas = [
              for (final e in g.equipes)
                SectionCard(
                  title: e.nome,
                  trailing: FilledButton.tonalIcon(
                    onPressed: () => _novoTime(context, e),
                    icon: const Icon(Icons.add),
                    label: const Text('Time'),
                  ),
                  child: Column(
                    children: [
                      for (final t in store.timesDa(m.id, equipeId: e.id))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: e.cor,
                            foregroundColor: Colors.white,
                            child: Text('${t.integrantes.length}'),
                          ),
                          title: Text(t.nome),
                          subtitle: Text(
                            t.integrantes.isEmpty
                                ? 'Sem competidores ainda'
                                : t.integrantes.map((u) => store.usuario(u).nome.split(' ').first).join(', '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: store.partidas.any((p) => p.timeIds.contains(t.id))
                              ? null
                              : IconButton(
                                  tooltip: 'Remover time',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => store.removerTime(t),
                                ),
                        ),
                      if (store.timesDa(m.id, equipeId: e.id).isEmpty)
                        const EmptyState(icon: Icons.group_add_outlined, text: 'Nenhum time'),
                    ],
                  ),
                ),
            ];
            if (c.maxWidth < 700) return Column(children: [colunas[0], const SizedBox(height: 16), colunas[1]]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: colunas[0]),
                const SizedBox(width: 16),
                Expanded(child: colunas[1]),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ Fases e partidas

class _FasesTab extends StatelessWidget {
  final Modalidade m;
  const _FasesTab(this.m);

  Future<void> _novaFase(BuildContext context) async {
    final store = AppScope.of(context);
    final ctrl = TextEditingController(text: store.fasesDa(m.id).isEmpty ? 'Eliminatória' : 'Final');
    var vale = store.fasesDa(m.id).isNotEmpty;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Nova fase'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(labelText: 'Nome da fase'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vale pontos para a gincana'),
                subtitle: const Text('Desligue para eliminatórias que só definem quem avança'),
                value: vale,
                onChanged: (v) => set(() => vale = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Criar')),
          ],
        ),
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) store.criarFase(m.id, ctrl.text.trim(), vale);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final fases = store.fasesDa(m.id);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fase',
        onPressed: () => _novaFase(context),
        icon: const Icon(Icons.add),
        label: const Text('Nova fase'),
      ),
      body: PageBody(
        children: [
          if (store.timesDa(m.id).isEmpty)
            const InfoBanner('Cadastre os times na aba "Times" antes de criar partidas.', icon: Icons.warning_amber),
          if (fases.isEmpty) const EmptyState(icon: Icons.account_tree_outlined, text: 'Nenhuma fase cadastrada'),
          for (var i = 0; i < fases.length; i++) _FaseCard(m, fases[i], anterior: i > 0 ? fases[i - 1] : null),
        ],
      ),
    );
  }
}

class _FaseCard extends StatelessWidget {
  final Modalidade m;
  final Fase f;
  final Fase? anterior;
  const _FaseCard(this.m, this.f, {this.anterior});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final partidas = store.partidasDa(f.id)..sort((a, b) => a.dataHora.compareTo(b.dataHora));
    final classificados = anterior == null ? <String>[] : store.classificados(anterior!.id);
    return SectionCard(
      title: '${f.ordem}. ${f.nome}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          f.valePontos
              ? const Tag('Vale pontos', icon: Icons.star, color: Color(0xFF1B7F3B))
              : const Tag('Sem pontos', icon: Icons.star_border, color: Colors.grey),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: store.timesDa(m.id).length < 2
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NovaPartidaScreen(modalidadeId: m.id, faseId: f.id, sugeridos: classificados),
                    ),
                  ),
            icon: const Icon(Icons.add),
            label: const Text('Partida'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (classificados.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Classificados de ${anterior!.nome}:', style: Theme.of(context).textTheme.bodySmall),
                for (final t in classificados)
                  Tag(store.time(t).nome, icon: Icons.arrow_upward, color: store.equipe(store.time(t).equipeId).cor),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (partidas.isEmpty) const EmptyState(icon: Icons.event_busy_outlined, text: 'Nenhuma partida nesta fase'),
          for (final p in partidas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PartidaTile(
                p,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PartidaDetalheScreen(p.id))),
              ),
            ),
        ],
      ),
    );
  }
}
