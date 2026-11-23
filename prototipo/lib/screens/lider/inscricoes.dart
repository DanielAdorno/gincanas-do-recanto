import 'package:flutter/material.dart';

import '../../store.dart';
import '../../widgets/busca.dart';
import '../../widgets/common.dart';
import 'seletor_modalidade.dart';

/// O Líder seleciona, entre os participantes da própria equipe, quem disputa cada modalidade (RF019).
class InscricoesScreen extends StatefulWidget {
  const InscricoesScreen({super.key});

  @override
  State<InscricoesScreen> createState() => _InscricoesScreenState();
}

class _InscricoesScreenState extends State<InscricoesScreen> {
  String? _mod;
  final _busca = TextEditingController();
  final _foco = FocusNode();
  bool _soInscritos = false;

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
    _mod ??= store.modalidadesDaGincana.where((m) => m.ativa).firstOrNull?.id;
    final m = _mod == null ? null : store.modalidade(_mod!);
    final inscritos = m == null ? <String>{} : store.inscritos(m.id);
    final daEquipe = eq.participantes.where(inscritos.contains).length;
    final termo = normalizar(_busca.text.trim());
    final lista = eq.participantes
        .where((u) => casaBusca(store.usuario(u).nome, termo) && (!_soInscritos || inscritos.contains(u)))
        .toList();
    if (termo.isNotEmpty) lista.sort((a, b) => ordemBusca(store.usuario(a).nome, store.usuario(b).nome, termo));

    void inscreverPrimeiro() {
      if (m == null || lista.isEmpty) return;
      final uid = lista.first;
      final nome = store.usuario(uid).nome;
      if (!inscritos.contains(uid)) {
        store.alternarInscricao(m.id, uid);
        mostrarMensagem(context, '$nome inscrito em ${m.nome}');
      } else {
        mostrarMensagem(context, '$nome já está inscrito em ${m.nome}');
      }
      _busca.clear();
      setState(() {});
      _foco.requestFocus();
    }

    return PageBody(
      maxWidth: 820,
      children: [
        InfoBanner(
          'Os ${eq.participantes.length} participantes da ${eq.nome} vieram do sistema de divisão '
          '(${store.textoDivisao(g).toLowerCase()}) e não mudam até o fim da ${g.nome}. Aqui você escolhe quem joga cada modalidade.',
          icon: Icons.groups_2_outlined,
        ),
        SeletorModalidade(selecionada: _mod, onChanged: (v) => setState(() => _mod = v)),
        if (m != null)
          SectionCard(
            title: m.nome,
            subtitle: '$daEquipe inscritos da ${eq.nome}',
            trailing: EquipeDot(eq.cor, size: 16),
            child: Column(
              children: [
                CampoBusca(
                  controller: _busca,
                  focusNode: _foco,
                  hint: 'Buscar participante da ${eq.nome}...',
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => inscreverPrimeiro(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        termo.isEmpty
                            ? '${lista.length} participante(s)'
                            : '${lista.length} encontrado(s)${lista.isNotEmpty ? ' · Enter inscreve o primeiro' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    FilterChip(
                      label: const Text('Só inscritos'),
                      selected: _soInscritos,
                      onSelected: (v) => setState(() => _soInscritos = v),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (lista.isEmpty) const EmptyState(icon: Icons.person_search, text: 'Nenhum participante encontrado'),
                for (final uid in lista)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: inscritos.contains(uid),
                    onChanged: (_) => store.alternarInscricao(m.id, uid),
                    title: NomeDestacado(store.usuario(uid).nome, termo),
                    subtitle: () {
                      final t = store
                          .timesDa(m.id, equipeId: eq.id)
                          .where((t) => t.integrantes.contains(uid))
                          .firstOrNull;
                      return t == null ? null : Text('Time: ${t.nome}');
                    }(),
                    secondary: CircleAvatar(
                      backgroundColor: eq.cor.withValues(alpha: 0.15),
                      child: Text(store.usuario(uid).nome[0], style: TextStyle(color: eq.cor)),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
