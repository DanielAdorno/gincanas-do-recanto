import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../widgets/common.dart';

/// Login simulado: escolhe um usuário de demonstração e a gincana.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final demo = store.usuarios.where((u) => store.perfisDe(u.id).isNotEmpty).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primary, const Color(0xFF1F5FD1), const Color(0xFFD13B2F)],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.emoji_events, size: 48, color: cs.primary),
                        const SizedBox(height: 8),
                        Text(
                          'Gincanas do Recanto',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Protótipo · dados de demonstração',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        const InfoBanner(
                          'Escolha um usuário para entrar. Cada um tem perfis diferentes, para você ver o que cada papel enxerga.',
                        ),
                        const SizedBox(height: 16),
                        for (final u in demo) _UsuarioTile(usuario: u),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UsuarioTile extends StatelessWidget {
  final Usuario usuario;
  const _UsuarioTile({required this.usuario});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final gincanas = store.gincanasDe(usuario.id);
    final perfis = store.perfisDe(usuario.id);

    String resumo(PerfilGincana p) {
      final g = store.gincanas.firstWhere((g) => g.id == p.gincanaId);
      final eq = p.equipeId == null ? '' : ' (${store.equipe(p.equipeId!).nome.replaceFirst('Equipe ', '')})';
      return '${p.perfil.label}$eq · ${g.nome}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.centerLeft,
        ),
        onPressed: () async {
          Gincana? g = gincanas.length == 1 ? gincanas.first : null;
          g ??= await showDialog<Gincana>(
            context: context,
            builder: (c) => SimpleDialog(
              title: const Text('Qual semana?'),
              children: [
                for (final g in gincanas)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(c, g),
                    child: ListTile(
                      leading: const Icon(Icons.date_range),
                      title: Text(g.nome),
                      subtitle: Text('${formatarData(g.inicio)} a ${formatarData(g.fim)} · ${store.statusSemana(g)}'),
                    ),
                  ),
              ],
            ),
          );
          if (g != null) store.entrar(usuario, g);
        },
        child: Row(
          children: [
            CircleAvatar(child: Text(usuario.nome[0])),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(usuario.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  for (final p in perfis) Text(resumo(p), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
