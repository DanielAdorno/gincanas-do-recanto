import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import 'admin/modalidades.dart';
import 'admin/painel.dart';
import 'admin/partidas.dart';
import 'admin/semanas.dart';
import 'admin/usuarios.dart';
import 'arbitro/arbitragem_lista.dart';
import 'lider/inscricoes.dart';
import 'lider/participantes.dart';
import 'lider/partidas_lider.dart';
import 'lider/resultados.dart';
import 'lider/times_lider.dart';

class _Destino {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
  const _Destino(this.label, this.icon, this.selectedIcon, this.page);
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _Menu { administracao, arbitragem }

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  _Menu _menu = _Menu.administracao;

  List<_Destino> _destinos(AppStore store) => [
    // Administrador/Árbitro: um único perfil com dois menus.
    if (store.tem(Perfil.administrador) && _menu == _Menu.administracao) ...const [
      _Destino('Painel', Icons.dashboard_outlined, Icons.dashboard, PainelScreen()),
      _Destino('Modalidades', Icons.sports_soccer_outlined, Icons.sports_soccer, ModalidadesScreen()),
      _Destino('Partidas', Icons.event_note_outlined, Icons.event_note, PartidasScreen()),
      _Destino('Usuários', Icons.manage_accounts_outlined, Icons.manage_accounts, UsuariosScreen()),
      _Destino('Semanas', Icons.date_range_outlined, Icons.date_range, SemanasScreen()),
    ],
    if (store.tem(Perfil.administrador) && _menu == _Menu.arbitragem) ...const [
      _Destino('Minhas partidas', Icons.sports_outlined, Icons.sports, ArbitragemListaScreen()),
      _Destino(
        'Todas as partidas',
        Icons.event_available_outlined,
        Icons.event_available,
        ArbitragemListaScreen(todas: true),
      ),
    ],
    if (store.tem(Perfil.lider)) ...const [
      _Destino('Participantes', Icons.people_alt_outlined, Icons.people_alt, ParticipantesScreen()),
      _Destino('Partidas', Icons.event_note_outlined, Icons.event_note, PartidasLiderScreen()),
      _Destino('Inscrições', Icons.how_to_reg_outlined, Icons.how_to_reg, InscricoesScreen()),
      _Destino('Times', Icons.groups_outlined, Icons.groups, TimesLiderScreen()),
      _Destino('Resultados', Icons.emoji_events_outlined, Icons.emoji_events, ResultadosScreen()),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final g = store.gincanaAtual!;
    final u = store.usuarioAtual!;
    final destinos = _destinos(store);
    if (_index >= destinos.length) _index = 0;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final perfis = store.perfisDe(u.id, g.id).map((p) => p.perfil.label).join(' · ');
    final eqLider = store.equipeDoLider;

    final seletorMenu = !store.tem(Perfil.administrador)
        ? null
        : PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(
                alignment: wide ? Alignment.centerLeft : Alignment.center,
                child: SegmentedButton<_Menu>(
                  segments: const [
                    ButtonSegment(
                      value: _Menu.administracao,
                      icon: Icon(Icons.admin_panel_settings_outlined),
                      label: Text('Administração'),
                    ),
                    ButtonSegment(value: _Menu.arbitragem, icon: Icon(Icons.sports), label: Text('Arbitragem')),
                  ],
                  selected: {_menu},
                  onSelectionChanged: (s) => setState(() {
                    _menu = s.first;
                    _index = 0;
                  }),
                ),
              ),
            ),
          );

    final appBar = AppBar(
      bottom: seletorMenu,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(destinos[_index].label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(
            'Gincana do $nomeLocal · ${g.nome} · ${formatarDiaCurto(g.inicio)} a ${formatarDiaCurto(g.fim)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        if (store.gincanasDe(u.id).length > 1)
          PopupMenuButton<String>(
            tooltip: 'Trocar de semana',
            offset: const Offset(0, 48),
            itemBuilder: (_) => [
              for (final s in store.semanas.where((x) => store.perfisDe(u.id, x.id).isNotEmpty))
                PopupMenuItem(
                  value: s.id,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(s.id == g.id ? Icons.radio_button_checked : Icons.radio_button_off),
                    title: Text(s.nome),
                    subtitle: Text('${formatarData(s.inicio)} a ${formatarData(s.fim)} · ${store.statusSemana(s)}'),
                  ),
                ),
            ],
            onSelected: (id) {
              store.trocarSemana(store.gincanas.firstWhere((x) => x.id == id));
              setState(() => _index = 0);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Chip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(g.nome),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        if (eqLider != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Chip(
              avatar: CircleAvatar(backgroundColor: eqLider.cor, radius: 8),
              label: Text(eqLider.nome),
              visualDensity: VisualDensity.compact,
            ),
          ),
        PopupMenuButton<String>(
          tooltip: 'Conta',
          offset: const Offset(0, 48),
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: ListTile(contentPadding: EdgeInsets.zero, title: Text(u.nome), subtitle: Text(perfis)),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'sair',
              child: ListTile(leading: Icon(Icons.logout), title: Text('Trocar usuário')),
            ),
          ],
          onSelected: (_) => store.sair(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CircleAvatar(radius: 18, child: Text(u.nome[0])),
          ),
        ),
      ],
    );

    final conteudo = KeyedSubtree(key: ValueKey(destinos[_index].label), child: destinos[_index].page);
    final page = !g.encerrada
        ? conteudo
        : Column(
            children: [
              MaterialBanner(
                leading: const Icon(Icons.flag),
                content: Text(
                  'Gincana finalizada em ${formatarData(g.encerradaEm!)} às ${formatarHora(g.encerradaEm!)}.',
                ),
                actions: const [SizedBox.shrink()],
              ),
              Expanded(child: conteudo),
            ],
          );

    if (wide) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.sizeOf(context).width >= 1200,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: MediaQuery.sizeOf(context).width >= 1200
                  ? NavigationRailLabelType.none
                  : NavigationRailLabelType.all,
              destinations: [
                for (final d in destinos)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: page),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: appBar,
      body: page,
      bottomNavigationBar: destinos.length < 2
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
              destinations: [
                for (final d in destinos)
                  NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
              ],
            ),
    );
  }
}
