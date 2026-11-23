import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../store.dart';

/// Destaque de um vencedor do relatório final, para chamar os integrantes às medalhas (RF060).
/// Ocupa a tela por cima do relatório; as setas (ou ← →) passam para o próximo vencedor.
Future<void> abrirCerimoniaMedalhas(BuildContext context, List<ResultadoModalidade> vencedores, int inicial) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar',
    barrierColor: Colors.black.withValues(alpha: 0.75),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, _, _) => _CerimoniaMedalhas(vencedores, inicial),
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: child,
      ),
    ),
  );
}

class _CerimoniaMedalhas extends StatefulWidget {
  final List<ResultadoModalidade> vencedores;
  final int inicial;
  const _CerimoniaMedalhas(this.vencedores, this.inicial);

  @override
  State<_CerimoniaMedalhas> createState() => _CerimoniaMedalhasState();
}

class _CerimoniaMedalhasState extends State<_CerimoniaMedalhas> {
  late int _i = widget.inicial;
  final _foco = FocusNode();

  @override
  void dispose() {
    _foco.dispose();
    super.dispose();
  }

  void _ir(int delta) {
    final n = (_i + delta).clamp(0, widget.vencedores.length - 1);
    if (n != _i) setState(() => _i = n);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final res = widget.vencedores[_i];
    final t = store.time(res.timeId!);
    final e = store.equipe(t.equipeId);
    final ids = store.integrantesVencedores(res);
    final nomes = ids.map((u) => store.usuario(u).nome).toList();
    // Uma medalha por pessoa (RN020): quem já ganhou em outra modalidade não recebe de novo.
    final med = store.medalhas();
    final jaTem = [for (final u in ids) med[u] != null && med[u]!.modalidade.id != res.modalidade.id];
    final aEntregar = jaTem.where((x) => !x).length;
    final size = MediaQuery.sizeOf(context);
    final grande = size.width >= 700;

    return KeyboardListener(
      focusNode: _foco,
      autofocus: true,
      onKeyEvent: (k) {
        if (k is! KeyDownEvent) return;
        if (k.logicalKey == LogicalKeyboardKey.arrowRight) _ir(1);
        if (k.logicalKey == LogicalKeyboardKey.arrowLeft) _ir(-1);
      },
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Material(
                color: Colors.transparent,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                      child: c,
                    ),
                  ),
                  child: Container(
                    key: ValueKey(_i),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [e.cor, Color.lerp(e.cor, Colors.black, 0.35)!],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFFFD54F), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD54F).withValues(alpha: 0.45),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(24, 28, 24, grande ? 32 : 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.4, end: 1),
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.elasticOut,
                                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                                child: Icon(
                                  Icons.military_tech,
                                  size: grande ? 110 : 80,
                                  color: const Color(0xFFFFD54F),
                                ),
                              ),
                              Text(
                                res.modalidade.nome.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                  fontSize: grande ? 18 : 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.nome,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: grande ? 48 : 32,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                                child: Text(
                                  e.nome,
                                  style: TextStyle(color: e.cor, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                res.detalhe,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'CHAMADA PARA AS MEDALHAS',
                                style: TextStyle(
                                  color: const Color(0xFFFFE082),
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w800,
                                  fontSize: grande ? 16 : 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$aEntregar medalha(s) a entregar'
                                '${aEntregar < nomes.length ? ' · ${nomes.length - aEntregar} já tem medalha de outra modalidade' : ''}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 14),
                              if (nomes.isEmpty)
                                const Text('Sem integrantes registrados', style: TextStyle(color: Colors.white))
                              else
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    for (var k = 0; k < nomes.length; k++)
                                      TweenAnimationBuilder<double>(
                                        key: ValueKey('$_i-$k'),
                                        tween: Tween(begin: 0, end: 1),
                                        duration: Duration(milliseconds: 350 + 120 * k),
                                        curve: Curves.easeOut,
                                        builder: (_, v, child) => Opacity(
                                          opacity: v,
                                          child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: child),
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: grande ? 20 : 14,
                                            vertical: grande ? 12 : 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: jaTem[k] ? Colors.white.withValues(alpha: 0.45) : Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: const [
                                              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                jaTem[k] ? Icons.check_circle : Icons.workspace_premium,
                                                color: jaTem[k] ? const Color(0xFF455A64) : const Color(0xFFC79100),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    nomes[k],
                                                    style: TextStyle(
                                                      fontSize: grande ? 26 : 20,
                                                      fontWeight: FontWeight.w800,
                                                      color: jaTem[k]
                                                          ? const Color(0xFF37474F)
                                                          : const Color(0xFF1F2328),
                                                    ),
                                                  ),
                                                  if (jaTem[k])
                                                    Text(
                                                      'Já tem medalha · ${med[ids[k]]!.modalidade.nome}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF8A5A00),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton.filledTonal(
                                    tooltip: 'Vencedor anterior',
                                    onPressed: _i > 0 ? () => _ir(-1) : null,
                                    icon: const Icon(Icons.chevron_left),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      '${_i + 1} de ${widget.vencedores.length}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    tooltip: 'Próximo vencedor',
                                    onPressed: _i < widget.vencedores.length - 1 ? () => _ir(1) : null,
                                    icon: const Icon(Icons.chevron_right),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            tooltip: 'Fechar',
                            color: Colors.white,
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ),
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
