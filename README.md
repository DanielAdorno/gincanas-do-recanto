# Gincanas do Recanto

Sistema de gerenciamento das gincanas do acampamento (local único, semanas separadas): modalidades,
partidas com placar ao vivo e cronômetro, escalação pelos Líderes, ranking, relatório final e medalhas.

## Conteúdo do repositório

| Caminho | O que é |
|---|---|
| `documento_requisitos_gincana.md` | Documento de requisitos (fonte, versão atual) |
| `documento_requisitos_gincana_v*.pdf` | Versões publicadas do documento em PDF |
| `prototipo/` | Protótipo funcional em **Flutter** (web), com dados de demonstração em memória — ponto de partida do front-end |
| `.github/workflows/deploy-pages.yml` | CI: análise, testes, build web e publicação no GitHub Pages |

## Rodar o protótipo localmente

Pré-requisito: [Flutter](https://docs.flutter.dev/get-started/install) (stable, Dart ≥ 3.14).

```bash
cd prototipo
flutter pub get
flutter run -d chrome          # ou: flutter run -d web-server --web-port 8090
flutter test                   # testes das regras de negócio
```

Usuários de demonstração e roteiro de apresentação: veja [`prototipo/README.md`](prototipo/README.md).

## Protótipo online (GitHub Pages)

1. Crie um repositório vazio no GitHub e envie este código (veja abaixo).
2. No GitHub: **Settings › Pages › Build and deployment › Source: GitHub Actions**.
3. A cada `git push` na branch `main`, o workflow testa e publica em
   `https://<seu-usuario>.github.io/<nome-do-repositorio>/`.

> O GitHub Pages é público para quem tiver o link (em contas gratuitas, o repositório precisa ser público para usar
> o Pages). O protótipo só tem dados fictícios.

### Enviar para o GitHub pela primeira vez

```bash
git remote add origin https://github.com/<seu-usuario>/<nome-do-repositorio>.git
git push -u origin main
```

## Próximos passos para virar o front-end real

- Trocar o `AppStore` (dados em memória, `prototipo/lib/store.dart`) por uma camada de serviços que consome a API.
- Separar `lib/` em camadas (modelos, serviços/repositórios, estado, telas) e adotar uma solução de estado
  (ex: Riverpod ou Bloc) e de rotas (ex: go_router).
- Autenticação integrada à base de usuários existente (RF049) e perfis vindos do back-end.
- Builds Android/iOS (`flutter create --platforms android,ios .` dentro de `prototipo/`).
