import 'package:flutter/material.dart';

/// O Administrador também é o Árbitro: um único perfil com dois menus.
enum Perfil { administrador, lider, competidor }

extension PerfilLabel on Perfil {
  String get label => switch (this) {
    Perfil.administrador => 'Administrador/Árbitro',
    Perfil.lider => 'Líder de Equipe',
    Perfil.competidor => 'Competidor',
  };
}

enum TipoMarcacao { placar, tempo }

enum StatusPartida { agendada, emAndamento, encerrada }

extension StatusLabel on StatusPartida {
  String get label => switch (this) {
    StatusPartida.agendada => 'Agendada',
    StatusPartida.emAndamento => 'Em andamento',
    StatusPartida.encerrada => 'Encerrada',
  };
}

/// Regras de empate configuráveis por modalidade (RF015).
enum RegraEmpate { empateAceito, penaltis, prorrogacao, novaPartida }

extension RegraEmpateLabel on RegraEmpate {
  String get label => switch (this) {
    RegraEmpate.empateAceito => 'Empate aceito',
    RegraEmpate.penaltis => 'Pênaltis / disputa extra',
    RegraEmpate.prorrogacao => 'Prorrogação',
    RegraEmpate.novaPartida => 'Nova partida',
  };
}

class Usuario {
  final String id;
  final String nome;
  const Usuario(this.id, this.nome);
}

class PerfilGincana {
  final String usuarioId;
  final String gincanaId;
  final Perfil perfil;
  final String? equipeId;
  const PerfilGincana(this.usuarioId, this.gincanaId, this.perfil, [this.equipeId]);
}

class Equipe {
  final String id;
  final String nome;
  final Color cor;

  /// Participantes recebidos do sistema existente (RF008). Não muda (RN018).
  final List<String> participantes;
  Equipe(this.id, this.nome, this.cor, this.participantes);
}

/// Local único do acampamento: a gincana acontece sempre aqui, em semanas separadas.
const nomeLocal = 'Recanto';

/// Uma gincana = uma semana do acampamento (1ª, 2ª, 3ª semana...). Semanas nunca se sobrepõem (RN016).
class Gincana {
  final String id;
  String nome;
  String local;

  /// Início da semana (sempre um sábado) e último dia de competições (quinta) — RN021.
  DateTime inicio;
  DateTime fim;
  final List<Equipe> equipes;

  /// Quando a divisão das equipes chegou do sistema existente (null = ainda não recebida).
  DateTime? divisaoRecebidaEm;

  /// Preenchido quando o Administrador finaliza a gincana.
  DateTime? encerradaEm;
  bool get encerrada => encerradaEm != null;

  Gincana({
    required this.id,
    required this.nome,
    required this.local,
    required this.inicio,
    required this.fim,
    required this.equipes,
    this.divisaoRecebidaEm,
  });
}

class Modalidade {
  final String id;
  final String gincanaId;
  String nome;
  String categoria;
  TipoMarcacao tipo;
  String unidade; // gol, ponto... (só para placar)
  int pontosVitoria;
  int pontosEmpate;
  int pontosDerrota;
  List<int> pontosColocacao; // para tempo: 1º, 2º, 3º...
  double peso;
  RegraEmpate regraEmpateEliminatoria;
  RegraEmpate regraEmpatePontuada;
  bool ativa;

  /// Participantes titulares por time (null = toda a equipe, ex: gincana bíblica) e reservas (RF070).
  int? participantesPorTime;
  int reservas;

  /// Máximo de escalados por time (titulares + reservas); null = sem limite.
  int? get maxEscalados => participantesPorTime == null ? null : participantesPorTime! + reservas;

  String get descricaoParticipantes => participantesPorTime == null
      ? 'Toda a equipe'
      : '${participantesPorTime!} por time${reservas > 0 ? ' + $reservas reserva${reservas > 1 ? 's' : ''}' : ' · sem reservas'}';

  Modalidade({
    required this.id,
    required this.gincanaId,
    required this.nome,
    required this.categoria,
    required this.tipo,
    this.unidade = 'ponto',
    this.pontosVitoria = 100,
    this.pontosEmpate = 50,
    this.pontosDerrota = 0,
    List<int>? pontosColocacao,
    this.peso = 1,
    this.regraEmpateEliminatoria = RegraEmpate.penaltis,
    this.regraEmpatePontuada = RegraEmpate.empateAceito,
    this.ativa = true,
    this.participantesPorTime = 1,
    this.reservas = 0,
  }) : pontosColocacao = pontosColocacao ?? [100, 70, 40, 20];
}

class Time {
  final String id;
  final String modalidadeId;
  final String equipeId;
  String nome;
  final List<String> integrantes;
  Time(this.id, this.modalidadeId, this.equipeId, this.nome, [List<String>? integrantes])
    : integrantes = integrantes ?? [];
}

class Fase {
  final String id;
  final String modalidadeId;
  String nome;
  int ordem;
  bool valePontos;
  Fase(this.id, this.modalidadeId, this.nome, this.ordem, this.valePontos);
}

enum TipoMarcacaoEvento { ponto, tempo, desempate, ajuste }

class Marcacao {
  final String timeId;
  final TipoMarcacaoEvento tipo;
  final int valor; // +1/-1 para ponto; ms para tempo
  final DateTime hora;
  final String usuarioId;
  final String? justificativa;
  bool desfeita;
  Marcacao({
    required this.timeId,
    required this.tipo,
    required this.valor,
    required this.usuarioId,
    this.justificativa,
    DateTime? hora,
  }) : hora = hora ?? DateTime.now(),
       desfeita = false;
}

class Partida {
  final String id;
  final String faseId;
  final List<String> timeIds;
  final List<String> arbitroIds;
  DateTime dataHora;
  StatusPartida status;
  final Map<String, int> placar;
  final Map<String, int> placarDesempate;
  final Map<String, int> tempos; // ms
  final List<Marcacao> marcacoes;

  /// Escalação congelada quando o árbitro inicia a partida (RN017).
  final Map<String, List<String>> escalacao;

  /// Resultado: timeIds ordenados por colocação (1º primeiro). Empate aceito => empate=true.
  List<String> classificacao;
  bool empate;
  bool cancelada;

  Partida({
    required this.id,
    required this.faseId,
    required this.timeIds,
    required this.arbitroIds,
    required this.dataHora,
    this.status = StatusPartida.agendada,
  }) : placar = {for (final t in timeIds) t: 0},
       placarDesempate = {},
       tempos = {},
       marcacoes = [],
       escalacao = {},
       classificacao = [],
       empate = false,
       cancelada = false;

  String? get vencedorId =>
      (status == StatusPartida.encerrada && !empate && classificacao.isNotEmpty) ? classificacao.first : null;
}

class Pontuacao {
  final String partidaId;
  final String modalidadeId;
  final String equipeId;
  final double valor; // já com peso
  final String descricao;
  final DateTime data;
  final String usuarioId;
  bool cancelada;
  Pontuacao({
    required this.partidaId,
    required this.modalidadeId,
    required this.equipeId,
    required this.valor,
    required this.descricao,
    required this.usuarioId,
    DateTime? data,
  }) : data = data ?? DateTime.now(),
       cancelada = false;
}

class LogAuditoria {
  final DateTime data;
  final String usuarioId;
  final String acao;
  LogAuditoria(this.usuarioId, this.acao) : data = DateTime.now();
}
