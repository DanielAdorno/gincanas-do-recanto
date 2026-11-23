import 'package:flutter/material.dart';

import '../../models.dart';
import '../../store.dart';
import '../../widgets/busca.dart';
import '../../widgets/common.dart';
import '../../widgets/medalha.dart';

/// Gestão de perfis por gincana (RF045–RF048), com busca rápida de usuários.
class UsuariosScreen extends StatelessWidget {
  const UsuariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = store.gincanaAtual!;
    final comPerfil = store.usuarios.where((u) => store.perfisDe(u.id, g.id).isNotEmpty).toList();

    return PageBody(
      maxWidth: 900,
      children: [
        const _BuscaUsuario(),
        SectionCard(
          title: 'Perfis nesta gincana',
          subtitle: g.nome,
          child: Column(
            children: [
              for (final u in comPerfil)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => abrirUsuario(context, u),
                  leading: CircleAvatar(child: Text(u.nome[0])),
                  title: Text(u.nome),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [for (final p in store.perfisDe(u.id, g.id)) _PerfilChip(p)],
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Adicionar perfil',
                    onPressed: () => atribuirPerfil(context, u),
                    icon: const Icon(Icons.add_moderator_outlined),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Participantes por equipe',
          subtitle: 'Recebidos do sistema de divisão; somente leitura. Toque em um nome para ver os detalhes.',
          child: LayoutBuilder(
            builder: (context, c) {
              final cols = [
                for (final e in g.equipes)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EquipeLabel(
                        e,
                        texto: '${e.nome} (${e.participantes.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      for (final uid in e.participantes.take(12))
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () => abrirUsuario(context, store.usuario(uid)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Text(store.usuario(uid).nome),
                          ),
                        ),
                      if (e.participantes.length > 12)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'e mais ${e.participantes.length - 12} — use a busca acima',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
              ];
              if (c.maxWidth < 500) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [cols[0], const SizedBox(height: 12), cols[1]],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cols[0]),
                  Expanded(child: cols[1]),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ busca

class _BuscaUsuario extends StatefulWidget {
  const _BuscaUsuario();

  @override
  State<_BuscaUsuario> createState() => _BuscaUsuarioState();
}

class _BuscaUsuarioState extends State<_BuscaUsuario> {
  final _ctrl = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _selecionar(Usuario u) {
    _ctrl.clear();
    _foco.unfocus();
    setState(() {});
    abrirUsuario(context, u);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = store.gincanaAtual!;
    final termo = normalizar(_ctrl.text.trim());
    final achados = termo.isEmpty
        ? <Usuario>[]
        : (store.usuarios.where((u) => normalizar(u.nome).contains(termo)).toList()..sort((a, b) {
            // Quem começa com o termo vem primeiro.
            final ia = normalizar(a.nome).startsWith(termo) ? 0 : 1;
            final ib = normalizar(b.nome).startsWith(termo) ? 0 : 1;
            return ia != ib ? ia - ib : a.nome.compareTo(b.nome);
          }));

    return SectionCard(
      title: 'Buscar usuário',
      subtitle: 'Digite parte do nome para encontrar e selecionar rapidamente (base de usuários existente)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctrl,
            focusNode: _foco,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Ex: ana, lucas, ferreira...',
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
              suffixIcon: _ctrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(_ctrl.clear),
                    ),
            ),
            onChanged: (_) => setState(() {}),
            // Enter seleciona o primeiro resultado.
            onSubmitted: (_) {
              if (achados.isNotEmpty) _selecionar(achados.first);
            },
          ),
          if (termo.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (achados.isEmpty)
              const EmptyState(icon: Icons.person_search, text: 'Nenhum usuário encontrado')
            else ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  '${achados.length} encontrado(s)${achados.length > 1 ? ' · Enter seleciona o primeiro' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              for (final u in achados.take(8)) _ResultadoTile(u, termo: termo, gincana: g, onTap: () => _selecionar(u)),
            ],
          ],
        ],
      ),
    );
  }
}

class _ResultadoTile extends StatelessWidget {
  final Usuario u;
  final String termo;
  final Gincana gincana;
  final VoidCallback onTap;
  const _ResultadoTile(this.u, {required this.termo, required this.gincana, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final eq = gincana.equipes.where((e) => e.participantes.contains(u.id)).firstOrNull;
    final perfis = store.perfisDe(u.id, gincana.id);

    // Destaca em negrito o trecho que casou com a busca.
    final n = normalizar(u.nome);
    final i = n.indexOf(termo);
    final nome = i < 0
        ? Text(u.nome)
        : Text.rich(
            TextSpan(
              children: [
                TextSpan(text: u.nome.substring(0, i)),
                TextSpan(
                  text: u.nome.substring(i, i + termo.length),
                  style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
                ),
                TextSpan(text: u.nome.substring(i + termo.length)),
              ],
            ),
          );

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
          backgroundColor: eq?.cor.withValues(alpha: 0.15),
          child: Text(u.nome[0], style: TextStyle(color: eq?.cor)),
        ),
        title: nome,
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (eq != null) EquipeLabel(eq) else const Text('Não participa desta gincana'),
            for (final p in perfis) Tag(p.perfil.label, color: const Color(0xFF6A4BC4)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

// ------------------------------------------------------------------ detalhe do usuário

Future<void> atribuirPerfil(BuildContext context, Usuario u) async {
  final store = AppScope.of(context);
  final g = store.gincanaAtual!;
  final escolha = await showDialog<(Perfil, String?)>(
    context: context,
    builder: (c) => SimpleDialog(
      title: Text('Perfil para ${u.nome}'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(c, (Perfil.administrador, null)),
          child: const Text('Administrador/Árbitro'),
        ),
        for (final e in g.equipes)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, (Perfil.lider, e.id)),
            child: EquipeLabel(e, texto: 'Líder — ${e.nome}'),
          ),
      ],
    ),
  );
  if (escolha != null) store.adicionarPerfil(u.id, escolha.$1, escolha.$2);
}

Future<void> abrirUsuario(BuildContext context, Usuario u) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => _DetalheUsuario(u),
);

class _PerfilChip extends StatelessWidget {
  final PerfilGincana p;
  const _PerfilChip(this.p);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return InputChip(
      label: Text(p.equipeId == null ? p.perfil.label : '${p.perfil.label} · ${store.equipe(p.equipeId!).nome}'),
      avatar: p.equipeId == null ? null : EquipeDot(store.equipe(p.equipeId!).cor),
      onDeleted: p.usuarioId == store.usuarioAtual!.id && p.perfil == Perfil.administrador
          ? null
          : () => store.removerPerfil(p),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _DetalheUsuario extends StatelessWidget {
  final Usuario u;
  const _DetalheUsuario(this.u);

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = store.gincanaAtual!;
    final t = Theme.of(context).textTheme;
    final eq = g.equipes.where((e) => e.participantes.contains(u.id)).firstOrNull;
    final perfis = store.perfisDe(u.id, g.id);
    final inscricoes = store.modalidadesDaGincana.where((m) => store.inscritos(m.id).contains(u.id)).toList();

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
                  backgroundColor: eq?.cor,
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
                      if (eq != null) EquipeLabel(eq) else Text('Não participa desta gincana', style: t.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Perfis nesta gincana', style: t.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => atribuirPerfil(context, u),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar perfil'),
                ),
              ],
            ),
            if (perfis.isEmpty)
              Text('Nenhum perfil atribuído', style: t.bodySmall)
            else
              Wrap(spacing: 6, runSpacing: 6, children: [for (final p in perfis) _PerfilChip(p)]),
            MedalhaAviso(u.id),
            const SizedBox(height: 20),
            Text('Modalidades inscritas', style: t.titleSmall),
            const SizedBox(height: 6),
            if (inscricoes.isEmpty)
              Text('Não está inscrito em nenhuma modalidade', style: t.bodySmall)
            else
              for (final m in inscricoes)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(m.tipo == TipoMarcacao.placar ? Icons.scoreboard_outlined : Icons.timer_outlined),
                  title: Text(m.nome),
                  subtitle: Text(
                    store
                            .timesDa(m.id)
                            .where((x) => x.integrantes.contains(u.id))
                            .map((x) => 'Time: ${x.nome}')
                            .firstOrNull ??
                        'Ainda sem time',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
