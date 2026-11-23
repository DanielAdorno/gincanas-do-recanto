# Documento de Requisitos de Software

## Sistema de Gerenciamento de Gincanas — Gincanas do Recanto

**Versão:** 2.0
**Data:** 23/11/2026
**Status:** Rascunho para validação

---

## 1. Introdução

### 1.1 Objetivo do Documento
Este documento descreve os requisitos funcionais e não funcionais para o desenvolvimento de uma aplicação destinada ao gerenciamento de gincanas realizadas durante a semana da temporada. A aplicação permitirá o cadastro de modalidades esportivas e competições, a marcação dos resultados das partidas pelos árbitros, o controle de pontuação das equipes, a gestão de usuários com diferentes perfis de acesso e a exibição do ranking geral da gincana.

### 1.2 Contexto do Negócio
Durante a semana de acampamento, os participantes são divididos em **duas equipes**, cada uma identificada por uma cor. As equipes competem entre si em diversas modalidades esportivas e culturais/bíblicas ao longo da semana, acumulando pontos que definem a equipe vencedora ao final do evento. A gincana acontece sempre no **mesmo local** (o acampamento) e é organizada em **semanas separadas** (1ª Semana, 2ª Semana, 3ª Semana...). Cada semana é uma gincana independente, com seus participantes, equipes e resultados; **nunca há duas gincanas ao mesmo tempo**.

Cada modalidade tem uma forma própria de marcar o resultado: o futebol é decidido por gols, o ping-pong por pontos e a canoagem por tempo. Em algumas modalidades, cada equipe pode ter mais de um time (ex: dois times de futebol por equipe), e há fases eliminatórias que não valem pontos para a gincana, servindo apenas para definir quem avança.

### 1.3 Definições e Abreviações

| Termo | Descrição |
|---|---|
| Gincana / Semana | Conjunto de competições de uma semana do acampamento (ex: 1ª Semana). O local é sempre o mesmo; as semanas são sequenciais e não se sobrepõem |
| Modalidade | Um tipo de competição (ex: Futebol Adulto, Vôlei Feminino, Canoagem) |
| Equipe | Um dos dois grupos competidores (identificados por cor) |
| Time | Grupo de competidores de uma mesma equipe que disputa uma modalidade (ex: Azul A, Azul B). Uma equipe pode ter um ou mais times por modalidade |
| Tipo de marcação | Forma como o resultado de uma partida é registrado: **Placar** (gols, pontos) ou **Tempo** (cronômetro) |
| Fase | Etapa de uma modalidade (ex: Eliminatória, Semifinal, Final). Cada fase pode valer ou não pontos para a gincana |
| Partida/Prova | Disputa entre times dentro de uma fase (ex: um jogo de futebol, uma bateria de canoagem) |
| Administrador/Árbitro | Perfil único responsável por configurar a gincana (modalidades, equipes, times, fases e partidas) e por registrar as marcações das partidas na tela de arbitragem. Tem dois menus: **Administração** e **Arbitragem** |
| Líder de Equipe | Usuário responsável por sua equipe e pela inscrição dos competidores nas modalidades |
| Competidor | Usuário inscrito pelo Líder de Equipe em uma ou mais modalidades |
| Ranking | Classificação geral das equipes com base na pontuação acumulada |

---

## 2. Visão Geral da Aplicação

### 2.1 Escopo
A aplicação contemplará:
- Cadastro e gerenciamento das **semanas** do acampamento (1ª, 2ª, 3ª...), cada uma com sua gincana, no mesmo local e sem sobreposição.
- Cadastro de **modalidades** de esporte/competição, com **tipo de marcação** (Placar ou Tempo), pontos por resultado, regra de empate e peso configuráveis.
- Cadastro das **duas equipes** por gincana, com definição de cor. A lista de participantes de cada equipe vem pronta de um sistema já existente.
- Cadastro de **times** por equipe em cada modalidade.
- Organização de cada modalidade em **fases** (ex: eliminatórias sem pontos e final com pontos) e **partidas**.
- **Tela de arbitragem** para registro das marcações em tempo real: placar ao vivo ou cronômetro.
- Gerenciamento de **usuários e perfis de acesso** (integrado a uma base de usuários já existente).
- Inscrição de competidores nas modalidades pelo **Líder de Equipe**.
- Cálculo automático da **pontuação** das equipes a partir dos resultados das partidas.
- Cálculo automático do **ranking geral** da gincana.
- Painel administrativo para o Administrador/Árbitro da competição.
- **Finalização da gincana** com geração do **relatório final** (equipe vencedora e times vencedores de cada modalidade).
- Acesso via **web responsiva**, com possibilidade de disponibilizar também **aplicativo mobile (Android/iOS)**, a depender da tecnologia definida (ver seção 2.3).

### 2.2 Fora de Escopo (nesta versão)
- Cadastro completo de dados pessoais de usuários (virá de base já existente).
- Divisão dos participantes entre as duas equipes (feita de forma equilibrada por um sistema já existente).

### 2.3 Stack Tecnológica

A stack tecnológica **ainda não está definida**. A tabela abaixo registra as tendências atuais e os pontos em aberto, servindo apenas como referência inicial.

| Camada | Situação |
|---|---|
| Front-end | A definir. **Provável: Flutter**, que permitiria atender web e mobile com uma única base de código |
| Back-end | A definir |
| Banco de Dados | A definir (preferencialmente relacional) |
| Autenticação | Integração com base de usuários existente (a definir: SSO/JWT/API externa) |
| Comunicação Front/Back | A definir (provavelmente API REST/JSON) |

> **Observação:** as escolhas de tecnologia dependem de definição técnica adicional com a equipe. Recomenda-se registrar cada decisão em um ADR (Architecture Decision Record) específico.

---

## 3. Perfis de Usuário (Atores)

| Perfil | Descrição | Origem do cadastro |
|---|---|---|
| **Administrador/Árbitro** | Perfil único com dois menus. **Administração:** cria gincanas, modalidades, equipes, times, fases e partidas, designa os árbitros de cada partida, corrige resultados e acompanha pontuação e ranking. **Arbitragem:** registra as marcações das partidas (placar ou tempo) na tela de arbitragem | Cadastrado nesta aplicação com perfil específico |
| **Líder de Equipe** | Gerencia sua equipe: **inscreve os competidores da própria equipe nas modalidades, distribui-os nos times** e acompanha os resultados da equipe em cada modalidade (sem acesso a pontos ou ranking) | Vinculado a usuário existente + perfil nesta aplicação |
| **Competidor** | Participante de uma equipe, selecionado pelo Líder de Equipe para uma ou mais modalidades | Vem da base existente, já vinculado à sua equipe |

> Os dados cadastrais básicos (nome, e-mail, etc.) **já existem em uma base de usuários externa**. Esta aplicação deverá apenas referenciar o usuário existente (por ID/CPF/e-mail) e associar a ele um ou mais **perfis/papéis** dentro do contexto de cada gincana.
>
> **Administrador e Árbitro são o mesmo perfil.** Ao longo do documento, "Administrador" e "Árbitro" se referem ao perfil Administrador/Árbitro, conforme o menu em uso (Administração ou Arbitragem).
>
> A **composição das equipes** também já vem pronta: um sistema existente divide os participantes de forma equilibrada entre as duas equipes. Esta aplicação apenas recebe essa divisão, uma única vez antes do início da gincana, e ela permanece a mesma até o encerramento; a aplicação não cria nem altera os participantes de cada equipe.

---

## 4. Requisitos Funcionais

### 4.1 Gestão de Gincanas
| ID | Requisito |
|---|---|
| RF001 | O sistema deve permitir cadastrar uma nova gincana, que corresponde a uma **semana** do acampamento (ex: 1ª Semana), com data de início (sábado) e fim (quinta). O local é único e não precisa ser informado. |
| RF002 | O sistema deve permitir editar e encerrar uma gincana. |
| RF003 | O sistema deve permitir consultar o histórico de gincanas de anos/semanas anteriores. |
| RF004 | Cada gincana deve possuir exatamente **duas equipes**, cada uma com nome e cor associada. |
| RF005 | As gincanas acontecem em **semanas sequenciais** (1ª, 2ª, 3ª...), **uma de cada vez**: o sistema deve impedir que duas semanas se sobreponham. Equipes, modalidades, perfis, partidas, resultados e ranking de cada semana ficam separados dos das demais. |
| RF066 | O Administrador deve poder definir e alterar a **semana da gincana em qualquer mês e ano**, antes ou durante a gincana, escolhendo o sábado de início (as competições vão até a quinta, conforme RN021). As partidas podem ser organizadas antes de a gincana começar. Ao mudar a semana, as partidas já agendadas acompanham a mudança, mantendo o dia da semana e o horário. Nos calendários de data, o Administrador pode navegar entre meses e anos, mas só os dias de competição da gincana podem ser escolhidos. |
| RF071 | O Administrador deve ter uma tela de **Semanas** para cadastrar as semanas do acampamento (1ª, 2ª, 3ª...), escolhendo o sábado de início em qualquer mês/ano. O sistema sugere o próximo sábado livre, impede sobreposição com outra semana e permite **copiar as modalidades** (com fases e configurações) de uma semana anterior. Na nova semana as equipes ficam aguardando a divisão do sistema existente e os Administradores já recebem perfil. A tela mostra o status de cada semana (planejada, em andamento, concluída, finalizada) e permite abrir/trocar a semana em que se está trabalhando. |

### 4.2 Gestão de Equipes
| ID | Requisito |
|---|---|
| RF006 | O sistema deve permitir cadastrar as duas equipes de uma gincana, definindo nome e cor (ex: Equipe Azul, Equipe Vermelha). |
| RF007 | O sistema deve permitir associar um ou mais líderes a cada equipe. |
| RF008 | O sistema deve obter da base existente a lista de participantes de cada equipe, já dividida de forma equilibrada pelo sistema existente. A divisão é recebida uma única vez, antes do início da gincana, e permanece a mesma até o encerramento; a aplicação não cria nem altera essa divisão. |
| RF009 | Ao receber a lista de participantes, o sistema deve validar que nenhum usuário esteja nas duas equipes da mesma gincana, sinalizando inconsistências ao Administrador. |

### 4.3 Gestão de Modalidades
| ID | Requisito |
|---|---|
| RF010 | O sistema deve permitir que o Administrador cadastre novas modalidades de esporte/competição (nome, descrição, categoria). |
| RF011 | O sistema deve permitir definir subcategorias/naipes por modalidade (ex: Futebol Adulto, Futebol Mirim, Futebol Infantil; Vôlei Masculino, Vôlei Feminino). |
| RF012 | Ao cadastrar a modalidade, o Administrador deve escolher o **tipo de marcação**: **Placar** (ex: gols no futebol, pontos no ping-pong) ou **Tempo** (ex: canoagem). |
| RF013 | Para o tipo **Placar**, o sistema deve permitir definir a unidade de marcação (ex: gol, ponto) e considerar vencedor quem tiver o maior placar. Para o tipo **Tempo**, deve considerar vencedor quem tiver o menor tempo. |
| RF014 | O sistema deve permitir configurar, por modalidade na gincana, os **pontos da gincana por resultado** (ex: vitória = 100, empate = 50, derrota = 0; ou 1º lugar = 100, 2º lugar = 60). |
| RF015 | O sistema deve permitir configurar, por modalidade, a **regra de empate**: se o empate é aceito como resultado ou qual o critério de desempate (ex: pênaltis, prorrogação, nova partida), podendo ser diferente para fases eliminatórias e para fases que valem pontos. |
| RF016 | O sistema deve permitir configurar um **peso/multiplicador** de pontuação por modalidade dentro da gincana (ex: Maratona Bíblica vale mais pontos que um jogo amistoso). |
| RF070 | Ao cadastrar a modalidade, o Administrador deve definir a **quantidade de participantes por time**: um número de titulares (de 1 em diante) ou **toda a equipe** (ex: gincana bíblica). Quando houver quantidade definida, deve poder indicar se a modalidade **permite reservas** e quantas. |
| RF017 | O sistema deve permitir ativar/inativar modalidades em uma gincana específica, permitindo reaproveitar o cadastro em edições futuras. |
| RF018 | O sistema deve permitir editar e excluir (ou inativar) uma modalidade, desde que não possua partidas com marcações registradas. |

### 4.4 Inscrição de Competidores
| ID | Requisito |
|---|---|
| RF019 | Apenas o **Líder de Equipe** deve poder inscrever competidores nas modalidades, selecionando-os entre os participantes da própria equipe (vindos da base existente). |
| RF020 | O sistema deve validar regras de elegibilidade por modalidade (ex: categoria etária, sexo), quando aplicável. |
| RF021 | O sistema deve permitir consultar a lista de inscritos por modalidade e por equipe. |

### 4.5 Times
| ID | Requisito |
|---|---|
| RF022 | O sistema deve permitir que o Administrador cadastre **um ou mais times por equipe** em cada modalidade (ex: 4 times de futebol, sendo Azul A, Azul B, Vermelho A e Vermelho B). |
| RF023 | O **Líder de Equipe** deve poder associar os competidores inscritos na modalidade aos times da própria equipe, aceitando apenas competidores da mesma equipe do time. O Líder pode alterar os participantes de um time (incluir, remover ou trocar) **até o Árbitro iniciar a partida**; depois de iniciada, a composição do time fica bloqueada para aquela partida. |
| RF024 | Em modalidades individuais ou por dupla (ex: canoagem), o competidor ou a dupla/barco deve poder ser cadastrado como um time. |

### 4.6 Fases e Partidas
| ID | Requisito |
|---|---|
| RF025 | O sistema deve permitir que o Administrador cadastre as **fases** de uma modalidade, em ordem (ex: Eliminatória, Semifinal, Final). |
| RF026 | O sistema deve permitir indicar, para cada fase, se ela **vale pontos para a gincana**. Fases eliminatórias podem ser configuradas para não valer pontos, servindo apenas para definir quem avança. |
| RF027 | O sistema deve permitir cadastrar as **partidas/provas** de cada fase, definindo os times participantes (dois times em um confronto, ou vários times em uma prova de tempo). |
| RF028 | Em fases que não valem pontos, o sistema deve permitir confrontos entre times da mesma equipe (ex: Azul A x Azul B). Em fases que valem pontos, deve impedir o cadastro de partidas entre times da mesma equipe. |
| RF029 | O sistema deve indicar os times vencedores de cada partida eliminatória como classificados para a fase seguinte, e permitir que o Administrador monte os confrontos dessa fase a partir deles. |
| RF030 | O sistema deve permitir que o Administrador designe um ou mais árbitros para cada partida. |
| RF065 | O menu **Partidas** do Administrador deve funcionar como **agenda**: mostrar o calendário da semana da gincana, de sábado a sexta (com a quantidade de partidas de cada dia e a sexta sem jogos, conforme RN021), listar as partidas do dia escolhido em ordem de horário e permitir filtrar por modalidade. Nele, o Administrador **lança novas partidas** escolhendo modalidade, fase, times, árbitros, **data** (calendário limitado ao período de competição, de sábado a quinta) e **horário**, e pode **reagendar** partidas ainda não iniciadas. O sistema deve avisar quando um time já tiver partida no mesmo dia e horário. |

### 4.7 Tela de Arbitragem
| ID | Requisito |
|---|---|
| RF031 | O sistema deve prover uma **tela de arbitragem**, acessada pelo menu Arbitragem, onde o usuário vê as partidas designadas a ele e todas as partidas da gincana, e pode iniciar, acompanhar e encerrar cada uma. |
| RF032 | Para modalidades do tipo **Placar**, a tela deve exibir o **placar atual de cada time** durante a partida, com botões para adicionar ou retirar uma marcação (gol/ponto) de cada time. |
| RF033 | Cada marcação de placar deve ser registrada com data/hora e árbitro responsável, e o Árbitro deve poder desfazer uma marcação enquanto a partida estiver em andamento. |
| RF034 | Para modalidades do tipo **Tempo**, a tela deve abrir um **cronômetro** com precisão de centésimos de segundo, com as ações iniciar, pausar, parar e zerar. |
| RF035 | A prova de tempo é feita em **baterias**: antes da largada, o Árbitro **seleciona os participantes** que vão largar (um ou vários). Os selecionados ficam **em destaque** na tela e os demais ficam esmaecidos. O cronômetro marca o tempo **somente para os participantes da bateria**: o Árbitro toca em cada um ao cruzar a linha (ou usa "Parar" para registrar o tempo atual a quem ainda não chegou). Quando todos da bateria têm tempo, o cronômetro zera e o Árbitro seleciona a próxima bateria. |
| RF036 | O sistema deve permitir o ajuste manual de um tempo registrado, exigindo justificativa e gerando registro de auditoria. |
| RF037 | Em caso de empate em uma partida que exige vencedor, a tela deve aplicar a regra de empate configurada na modalidade, permitindo registrar o desempate (ex: placar dos pênaltis, prorrogação) ou agendar uma nova partida. |
| RF038 | Ao encerrar a partida, o sistema deve definir o vencedor ou a colocação de cada time conforme o tipo de marcação (maior placar ou menor tempo) e a regra de empate, e pedir a confirmação do Árbitro antes de gravar o resultado. |

### 4.8 Pontuação da Gincana
| ID | Requisito |
|---|---|
| RF039 | Ao confirmar o resultado de uma partida de fase que **vale pontos**, o sistema deve calcular automaticamente os pontos da equipe a partir dos pontos por resultado e do peso configurados na modalidade. Partidas de fases que não valem pontos não geram pontuação. |
| RF040 | O sistema deve manter histórico de todos os resultados e pontuações lançados, com data/hora e usuário responsável. |
| RF041 | O sistema deve permitir que o Administrador corrija o resultado de uma partida já encerrada, recalculando a pontuação e mantendo registro de auditoria (log de alterações). |
| RF042 | O sistema deve permitir que o Administrador cancele/estorne o resultado de uma partida lançado incorretamente. |

### 4.9 Ranking e Visualização de Resultados
| ID | Requisito |
|---|---|
| RF043 | O sistema deve exibir o ranking geral da gincana, somando a pontuação de todas as modalidades, considerando os pesos configurados. |
| RF044 | O sistema deve exibir o ranking/pontuação detalhado por modalidade. |
| RF045 | O ranking deve ser atualizado em tempo real (ou near real-time) a cada novo resultado confirmado. |
| RF046 | A visualização do ranking e dos pontos deve ser restrita a usuários com perfil **Administrador/Árbitro**. |
| RF047 | O perfil Administrador/Árbitro deve ter dois menus, **Administração** e **Arbitragem**, que o usuário alterna na mesma sessão. O menu Arbitragem lista as partidas designadas ao usuário e todas as partidas da gincana; a tela de arbitragem mostra apenas o placar/tempo da partida, sem pontos da gincana. |
| RF048 | O sistema deve permitir que o Líder de Equipe visualize apenas os **resultados da própria equipe por modalidade** (ex: vitória/derrota, colocação, avanço nas eliminatórias), sem exibir pontos, pesos, total acumulado ou dados da equipe adversária. |

### 4.10 Gestão de Usuários e Perfis
| ID | Requisito |
|---|---|
| RF049 | O sistema deve permitir buscar um usuário já existente na base externa (por nome, e-mail ou identificador). |
| RF050 | O sistema deve permitir associar ao usuário localizado um ou mais perfis **em cada gincana** (Administrador/Árbitro, Líder de Equipe, Competidor). Um mesmo usuário pode ter perfis diferentes em gincanas diferentes. |
| RF051 | O sistema deve permitir revogar ou alterar o perfil de um usuário dentro de uma gincana. |
| RF052 | O sistema deve impedir acesso a funcionalidades administrativas, de arbitragem e de inscrição por usuários sem o perfil adequado na gincana em questão (controle de autorização). |

### 4.11 Painel Administrativo
| ID | Requisito |
|---|---|
| RF053 | O sistema deve prover um painel administrativo para o Administrador com visão consolidada de modalidades, equipes, times, fases, partidas, pontuações e usuários da gincana. |
| RF054 | O painel deve permitir exportar/consultar relatórios da gincana (ex: pontuação final, participação por modalidade). |

### 4.12 Finalização da Gincana e Relatório Final
| ID | Requisito |
|---|---|
| RF055 | O sistema deve prover uma ação de **Finalizar gincana**, acessível ao Administrador, que abre uma confirmação com o placar geral das equipes e a equipe que será declarada vencedora. |
| RF056 | Antes de finalizar, o sistema deve listar as partidas ainda não encerradas e exigir uma confirmação explícita para finalizar mesmo assim; essas partidas não contam pontos. Após a finalização, nenhuma partida pode ser iniciada. |
| RF057 | Ao finalizar, o sistema deve gerar o **relatório final** com: a **equipe vencedora** e a pontuação final de cada equipe; para cada modalidade, o **nome do time vencedor**, sua equipe, o resultado decisivo (placar ou tempo) e os nomes dos integrantes; e quantas modalidades cada equipe venceu. |
| RF058 | O vencedor de uma modalidade é o time que venceu a última fase que vale pontos (ou o 1º lugar, nas modalidades de tempo). Modalidades sem resultado aparecem como "Não disputada" e empates aceitos aparecem como "Empate". |
| RF059 | O relatório final deve poder ser consultado depois da finalização e exportado/compartilhado (ex: texto, PDF). Uma prévia do relatório deve estar disponível antes da finalização. |
| RF060 | No relatório final, ao tocar no vencedor de uma modalidade, o sistema deve destacá-lo em tela cheia sobre os demais, com ênfase nos **nomes dos integrantes** do time vencedor, para a **chamada às medalhas**. Deve ser possível passar para o vencedor seguinte/anterior sem fechar o destaque (modo cerimônia). |
| RF064 | Cada pessoa recebe **no máximo uma medalha** na gincana, mesmo que vença mais de uma modalidade. No relatório final e na cerimônia, quem já ganhou medalha em outra modalidade deve aparecer com a indicação **"Já tem medalha"** (e em qual modalidade), sem contar para a entrega. O relatório deve informar o total de medalhas a entregar. A ficha do participante (Líder e Administrador) deve mostrar se ele já tem medalha. |


### 4.13 Página Inicial do Líder de Equipe
| ID | Requisito |
|---|---|
| RF061 | A página inicial do Líder de Equipe deve listar **todos os participantes da sua equipe**, indicando para cada um se está inscrito em alguma modalidade (e em quais) ou se está **sem inscrição**. |
| RF062 | A página deve mostrar um resumo com o total de participantes, quantos estão inscritos em ao menos uma modalidade e quantos estão sem inscrição, e permitir filtrar a lista por "Todos", "Inscritos" e "Sem inscrição". |
| RF063 | A página deve ter **busca por nome** (sem diferenciar acentos e maiúsculas), com resultados enquanto o Líder digita. Ao selecionar um participante, o Líder vê suas modalidades e pode inscrevê-lo ou retirá-lo de cada uma ali mesmo. |


### 4.14 Partidas e Escalação pelo Líder de Equipe
| ID | Requisito |
|---|---|
| RF067 | O Líder de Equipe deve ver as **partidas da sua equipe** em uma agenda (calendário da semana e lista por dia), com data, horário, modalidade, fase, adversário e árbitro. Esses dados são **somente leitura**: o Líder não altera data, horário nem configurações da modalidade. |
| RF068 | Em cada partida, o Líder **escala os participantes da sua equipe** para o(s) time(s) dela, buscando pelo nome. Se o participante ainda não estiver inscrito na modalidade, a inscrição é feita automaticamente; se estiver em outro time da mesma modalidade, é movido. O Líder pode trocar a escalação até o árbitro iniciar a partida (RN017). A agenda deve destacar as partidas que ainda estão sem escalação. |
| RF069 | A escalação feita pelo Líder aparece para o **Árbitro** na tela da partida. O Árbitro **não edita participantes**; se um time ainda não foi escalado, a tela mostra "Aguardando o Líder escalar". |

---

## 5. Requisitos Não Funcionais

| ID | Requisito |
|---|---|
| RNF001 | A aplicação deve estar disponível na web, de forma responsiva e compatível com navegadores modernos (Chrome, Edge, Safari, Firefox), podendo também ser distribuída como aplicativo mobile (Android/iOS), conforme a tecnologia definida. |
| RNF002 | A tecnologia do front-end será definida pela equipe (provavelmente **Flutter**), conforme seção 2.3. |
| RNF003 | O back-end deve expor uma API para consumo pelo front-end; a tecnologia será definida pela equipe, conforme seção 2.3. |
| RNF004 | A comunicação entre front e back deve ocorrer via HTTPS. |
| RNF005 | O sistema deve suportar múltiplos usuários simultâneos registrando marcações e consultando resultados sem inconsistência de dados (controle de concorrência). |
| RNF006 | O tempo de resposta das operações de consulta (ranking, pontuação) não deve ultrapassar 2 segundos em condições normais de uso. |
| RNF007 | O sistema deve manter log de auditoria de ações críticas (marcações, ajustes de tempo, correção/cancelamento de resultados, alteração de perfis). |
| RNF008 | O sistema deve seguir boas práticas de segurança (autenticação, autorização por perfil, proteção contra CSRF/XSS/SQL Injection). |
| RNF009 | O banco de dados deve permitir a persistência histórica de gincanas de semanas/anos anteriores, sem perda de dados. |
| RNF010 | O sistema deve suportar os picos de acesso durante os dias de competição (cerca de 500 participantes por semana). |
| RNF011 | O código deve seguir padrões de arquitetura em camadas (ex: Controller/Service/Repository no back-end) e componentização no front-end. |
| RNF012 | O cronômetro deve rodar localmente no dispositivo do Árbitro, sem depender da rede para a precisão do tempo; o tempo é enviado ao servidor ao ser registrado. |
| RNF013 | A tela de arbitragem deve ser otimizada para uso em celular no local da competição (botões grandes, poucos toques por marcação, legível ao ar livre). |
| RNF014 | A tela de arbitragem deve tolerar conexão instável, guardando as marcações localmente e sincronizando com o servidor assim que a conexão voltar, sem perder ou duplicar marcações. |

---

## 6. Modelo de Dados (Visão Conceitual de Alto Nível)

> Modelo preliminar, sujeito a refinamento na fase de modelagem técnica.

**Principais entidades:**

- **Gincana (Semana)**: id, nome (ex: 1ª Semana), numero, data_inicio (sábado), data_fim (quinta), status, data_divisao_recebida, data_finalizacao, finalizada_por
- **Equipe**: id, gincana_id, nome, cor
- **Usuario** *(referência à base externa)*: id_externo, nome, e-mail (dados apenas referenciados, não duplicados/gerenciados aqui)
- **EquipeParticipante** *(recebido do sistema existente)*: equipe_id, usuario_id_externo, data_sincronizacao
- **UsuarioPerfil**: usuario_id_externo, gincana_id, equipe_id (opcional), perfil (ADMINISTRADOR_ARBITRO, LIDER_EQUIPE, COMPETIDOR)
- **Modalidade**: id, nome, categoria, descrição, tipo_marcacao (PLACAR, TEMPO), unidade_marcacao (ex: gol, ponto), ativo
- **ModalidadeGincana**: id, modalidade_id, gincana_id, peso, pontos_por_resultado (ex: vitória/empate/derrota ou 1º/2º lugar), regra_empate_eliminatoria, regra_empate_fase_pontuada, ativo
- **Inscricao**: usuario_id_externo, modalidade_gincana_id, equipe_id, inscrito_por (líder), data_inscricao
- **Time**: id, modalidade_gincana_id, equipe_id, nome
- **TimeIntegrante**: time_id, usuario_id_externo
- **Fase**: id, modalidade_gincana_id, nome, ordem, vale_pontos
- **Partida**: id, fase_id, data_hora, status (AGENDADA, EM_ANDAMENTO, ENCERRADA, CANCELADA)
- **PartidaArbitro**: partida_id, usuario_id_externo (usuário com perfil Administrador/Árbitro designado para a partida)
- **PartidaParticipante**: partida_id, time_id, placar, placar_desempate, tempo_ms, colocacao, classificado
- **Marcacao**: id, partida_id, time_id, tipo (PONTO, TEMPO, DESEMPATE, AJUSTE), valor, justificativa, data_hora, usuario_id, desfeita
- **Pontuacao**: id, partida_id, equipe_id, valor (já com peso aplicado), data_lancamento, usuario_lancamento_id, status (ativo/cancelado)
- **LogAuditoria**: id, gincana_id, entidade, entidade_id, ação, usuario_id, data_hora, dados_anteriores/novos

---

## 7. Regras de Negócio

| ID | Regra |
|---|---|
| RN001 | Uma gincana possui sempre exatamente duas equipes. |
| RN002 | Cada modalidade possui um tipo de marcação, **Placar** ou **Tempo**, escolhido pelo Administrador no cadastro. |
| RN003 | No tipo Placar, vence quem tiver o maior placar. No tipo Tempo, vence quem tiver o menor tempo. |
| RN004 | Apenas partidas de fases marcadas como "vale pontos" geram pontuação para a gincana. Partidas de fases eliminatórias sem pontos apenas definem quem avança. |
| RN005 | Os pontos de uma equipe em uma partida são os pontos configurados para o resultado obtido (ex: vitória, 1º lugar) multiplicados pelo peso da modalidade na gincana. |
| RN006 | A pontuação geral da equipe na gincana é a soma das pontuações de todas as partidas que valem pontos. |
| RN007 | Um usuário não pode pertencer a mais de uma equipe na mesma gincana. |
| RN008 | Um time pertence a uma única equipe e só pode ter competidores dessa equipe. |
| RN009 | Apenas usuários com perfil Administrador/Árbitro podem registrar ou desfazer marcações durante a partida, sejam ou não os árbitros designados para ela. Depois de encerrada, a correção ou o cancelamento do resultado é feito pelo menu Administração. |
| RN010 | Toda marcação, ajuste de tempo e alteração de resultado já lançado deve gerar registro de auditoria. |
| RN011 | Pontos, totais e ranking são visíveis apenas ao perfil Administrador/Árbitro (menu Administração). A tela de arbitragem mostra somente o placar/tempo da partida. O Líder de Equipe vê somente os resultados da própria equipe por modalidade, sem valores de pontuação. |
| RN012 | Administrador e Árbitro são um único perfil (Administrador/Árbitro), com menus separados de Administração e de Arbitragem. |
| RN013 | Apenas o Líder de Equipe inscreve competidores nas modalidades e os distribui nos times, e somente competidores da própria equipe. |
| RN014 | Times da mesma equipe podem se enfrentar apenas em fases que não valem pontos. Partidas de fases que valem pontos são sempre entre times de equipes diferentes. |
| RN015 | O tratamento de empate é definido por modalidade (ex: empate aceito, pênaltis, prorrogação, nova partida), podendo variar entre fases eliminatórias e fases que valem pontos. |
| RN016 | Existe **um único local**. As gincanas são semanas separadas e **não podem se sobrepor** (de sábado a sexta). Os perfis de acesso são atribuídos por semana, e os dados de uma semana (equipes, modalidades, partidas, resultados, ranking) não aparecem nas demais. |
| RN017 | O Líder de Equipe pode alterar os participantes de um time somente antes de o Árbitro iniciar a partida. A partir do início da partida, nenhuma alteração de participantes é permitida para ela. |
| RN018 | A divisão dos participantes entre as equipes é recebida do sistema existente antes do início da gincana e não muda até o seu encerramento. |
| RN019 | Depois de finalizada, a gincana não aceita novas partidas nem marcações; a equipe vencedora é a de maior pontuação geral no momento da finalização. |
| RN020 | Uma medalha por pessoa: se alguém vencer mais de uma modalidade, a medalha é da primeira vitória em ordem cronológica (partida decisiva mais antiga); as demais vitórias contam para a equipe, mas não geram nova medalha. |
| RN021 | A **semana da gincana vai de sábado a sexta**, mas as **competições acontecem de sábado a quinta**: a gincana começa no sábado e é encerrada na quinta. A sexta aparece no calendário sem jogos e não aceita partidas. |
| RN022 | A escalação dos participantes em cada partida é responsabilidade exclusiva do Líder da equipe. O Administrador define data, horário e configurações; o Árbitro apenas registra as marcações. |
| RN023 | Na escalação, o Líder pode colocar no máximo os titulares definidos na modalidade mais as reservas permitidas; os primeiros escalados são os titulares e os demais, reservas (o Líder pode promover um reserva a titular). Em modalidades de "toda a equipe" não há limite nem reservas. O Árbitro vê titulares e reservas e é avisado se o time estiver incompleto. |

---

## 8. Requisitos Futuros (Sugestões / Backlog)

- Notificações em tempo real (push/e-mail) sobre resultados e mudanças no ranking.
- Integração com fotos/vídeos das competições.
- Chaveamento automático dos confrontos das fases eliminatórias (nesta versão, o Administrador monta os confrontos manualmente).

---

## 9. Perguntas em Aberto para Validação com o Time

1. Qual o mecanismo de integração com a base de usuários existente e com o sistema que divide os participantes entre as equipes (API, banco compartilhado, SSO)?
2. Qual SGBD será utilizado (PostgreSQL, MySQL, outro)?
3. Modalidades culturais/bíblicas (ex: Maratona Bíblica) se encaixam no tipo Placar ou precisam de outro tipo de marcação (ex: pontuação direta pelo júri)?

---

*Documento sujeito a revisão conforme validação com stakeholders (organização do acampamento).*
