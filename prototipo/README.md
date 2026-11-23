# Protótipo — Gincanas do Recanto

Protótipo funcional em Flutter (web), feito a partir do `documento_requisitos_gincana.md` (v2.0).
Todos os dados são mockados e ficam em memória: recarregar a página volta ao estado inicial.

## Como rodar

Pré-requisito: [Flutter](https://docs.flutter.dev/get-started/install) (canal stable, Dart ≥ 3.14).

```bash
flutter pub get
flutter run -d chrome                         # ou: flutter run -d web-server --web-port 8090
flutter test                                  # testes das regras de negócio (test/regras_test.dart)
flutter build web --release                   # versão estática em build/web
flutter build web --release --no-web-resources-cdn   # idem, funcionando sem internet
```

## Usuários de demonstração

A gincana acontece sempre no mesmo local, em **semanas separadas** (nunca duas ao mesmo tempo). A base tem a
**1ª Semana** em andamento (480 participantes, 240 por equipe, parte sem inscrição), a **2ª Semana** planejada
(amostra de 20 participantes) e a **3ª Semana** cadastrada aguardando a divisão das equipes. Em
**Administração › Semanas** o Administrador cadastra novas semanas (sem sobreposição, podendo copiar as
modalidades de outra semana) e troca a semana aberta; o seletor no topo também troca de semana.

| Usuário | Perfis |
|---|---|
| Ana Souza | Administrador/Árbitro (1ª, 2ª e 3ª Semana) |
| Bruno Lima | Administrador/Árbitro (1ª, 2ª e 3ª Semana) |
| Carla Mendes | Líder da Equipe Azul (1ª Semana) |
| Diego Rocha | Líder da Equipe Vermelha (1ª Semana) |
| Elisa Prado / Fábio Nunes | Líderes Azul / Vermelha (2ª Semana) |

## O que dá para testar

- **Administrador/Árbitro** — um único perfil com dois menus, alternados no topo da tela.
- **Menu Administração**: painel com ranking e pontuação por modalidade e o cartão **Gincana › Editar dados e
  semana** (nome, local e semana em qualquer mês/ano — as partidas acompanham a mudança), cadastro de modalidade (Placar ou Tempo,
  pontos por resultado, peso, regra de empate, participantes por time — de 1 até toda a equipe — e reservas), criação de times e fases (vale ou não pontos); **Partidas** funciona como agenda (calendário da
  semana de sábado a sexta — competições de sábado a quinta, sexta sem jogos —, partidas do dia por horário, filtro por modalidade) e é onde se lança uma nova partida com
  data e horário ou se reagenda uma partida;
  designação de árbitros, correção e cancelamento de resultados, perfis por gincana. Em **Usuários**, a busca
  rápida filtra enquanto você digita (sem diferenciar acentos), Enter abre o primeiro resultado e a ficha do
  usuário mostra equipe, perfis e modalidades/times.
- **Finalizar gincana** (Painel › Encerramento): confirmação com o placar geral e as partidas pendentes, e
  relatório final com a equipe vencedora e o time vencedor de cada modalidade (com integrantes); botão
  "Copiar texto". Tocar em um vencedor (ou no botão "Cerimônia") abre o destaque em tela cheia com os nomes
  dos integrantes para a chamada às medalhas; setas ou ← → passam para o próximo vencedor. **Uma medalha por pessoa:** quem vence mais de uma modalidade aparece como "Já tem medalha" (no exemplo, Samuel Ribeiro vence Ping-pong e Vôlei), e as fichas do Líder e do Administrador mostram a medalha. Há uma prévia do relatório antes de finalizar e um "Reabrir" só para facilitar os testes.
- **Menu Arbitragem** (minhas partidas / todas as partidas): placar ao vivo com +/− e desfazer; cronômetro com centésimos em **baterias** (o árbitro
  seleciona quem larga, os selecionados ficam em destaque e o tempo vale só para eles), chegada por participante e
  ajuste manual com justificativa; desempate conforme a regra da modalidade (pênaltis, prorrogação, nova partida).
- **Líder › Partidas**: agenda das partidas da equipe (data e regras só leitura); em cada partida o Líder escala
  os participantes da equipe (busca, Enter escala, inscrição automática na modalidade). O árbitro vê essa escalação
  e não edita participantes.
- **Líder**: página inicial **Participantes** com todos da equipe, resumo (inscritos / sem inscrição), filtros,
  busca e ficha para inscrever em cada modalidade; inscrição dos participantes da própria equipe nas modalidades, montagem dos times (travados quando a
  partida começa) e resultados da equipe sem pontos. As telas de Inscrições e Times têm busca rápida: em
  Inscrições, Enter inscreve o primeiro encontrado; em Times, Enter abre a escolha de time do primeiro inscrito
  sem time.

## Estrutura

- `lib/models.dart` — entidades do modelo de dados
- `lib/store.dart` — estado em memória, regras de negócio e dados mockados
- `lib/screens/admin`, `lib/screens/arbitro`, `lib/screens/lider` — telas por perfil
- `lib/widgets` — componentes compartilhados
