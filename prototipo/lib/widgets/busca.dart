import 'package:flutter/material.dart';

/// Remove acentos e caixa para comparar nomes ("jose" encontra "José").
String normalizar(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const para = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = de.indexOf(ch);
    b.write(i >= 0 ? para[i] : ch);
  }
  return b.toString().toLowerCase();
}

bool casaBusca(String nome, String termoNormalizado) =>
    termoNormalizado.isEmpty || normalizar(nome).contains(termoNormalizado);

/// Ordena: nomes que começam com o termo primeiro, depois alfabético.
int ordemBusca(String a, String b, String termo) {
  final ia = normalizar(a).startsWith(termo) ? 0 : 1;
  final ib = normalizar(b).startsWith(termo) ? 0 : 1;
  return ia != ib ? ia - ib : a.compareTo(b);
}

/// Campo de busca padrão (arredondado, com limpar). [onSubmitted] = Enter.
class CampoBusca extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  const CampoBusca({
    super.key,
    required this.controller,
    required this.onChanged,
    this.focusNode,
    this.hint = 'Buscar pelo nome...',
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hint,
        isDense: true,
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(28))),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar',
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

/// Nome com o trecho buscado em destaque.
class NomeDestacado extends StatelessWidget {
  final String nome;
  final String termo; // já normalizado
  final TextStyle? style;
  const NomeDestacado(this.nome, this.termo, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final i = termo.isEmpty ? -1 : normalizar(nome).indexOf(termo);
    if (i < 0) return Text(nome, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: nome.substring(0, i)),
          TextSpan(
            text: nome.substring(i, i + termo.length),
            style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary),
          ),
          TextSpan(text: nome.substring(i + termo.length)),
        ],
      ),
    );
  }
}
