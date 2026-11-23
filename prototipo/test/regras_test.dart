import 'package:flutter_test/flutter_test.dart';
import 'package:gincanas_recanto/main.dart';
import 'package:gincanas_recanto/models.dart';
import 'package:gincanas_recanto/store.dart';

/// Testes das regras de negócio principais, usando os dados de demonstração.
void main() {
  late AppStore store;

  setUp(() {
    store = AppStore();
    store.entrar(store.usuario('u1'), store.gincanas.firstWhere((g) => g.id == 'g1'));
  });

  test('base de demonstração: ~500 pessoas e 3 semanas sequenciais', () {
    expect(store.usuarios.length, 506);
    expect(store.semanas.map((g) => g.nome), ['1ª Semana', '2ª Semana', '3ª Semana']);
  });

  test('RN016: semanas não podem se sobrepor', () {
    final g1 = store.gincanas.firstWhere((g) => g.id == 'g1');
    expect(store.sobreposicao(g1.inicio.add(const Duration(days: 7)))?.nome, '2ª Semana');
    expect(store.sobreposicao(store.proximoSabadoLivre), isNull);
    final nova = store.criarSemana(inicio: store.proximoSabadoLivre, copiarDe: 'g1');
    expect(nova.nome, '4ª Semana');
    expect(store.modalidades.where((m) => m.gincanaId == nova.id).length, 5);
  });

  test('RN021: competições de sábado a quinta; sexta sem jogos', () {
    final semana = store.semanaDaGincana;
    expect(semana.first.weekday, DateTime.saturday);
    expect(store.diaDeCompeticao(semana[5]), isTrue); // quinta
    expect(store.diaDeCompeticao(semana[6]), isFalse); // sexta
  });

  test('RN014: times da mesma equipe não se enfrentam em fase que vale pontos', () {
    final finalFutebol = store.fase('f2');
    expect(store.validarPartida(finalFutebol, ['t1', 't2']), isNotNull); // Azul A x Azul B
    expect(store.validarPartida(finalFutebol, ['t1', 't4']), isNull); // Azul A x Vermelho B
    expect(store.validarPartida(store.fase('f1'), ['t1', 't2']), isNull); // eliminatória sem pontos
  });

  test('RN004/RN005: só fases que valem pontos pontuam, com peso', () {
    final r = store.ranking();
    expect(r['e1'], 160); // Ping-pong 60 + Vôlei 100
    expect(r['e2'], 0);
  });

  test('RN020: uma medalha por pessoa, mesmo vencendo duas modalidades', () {
    final samuel = store.usuarios.firstWhere((u) => u.nome == 'Samuel Ribeiro').id;
    expect(store.vitoriasDe(samuel).length, 2);
    expect(store.medalhas()[samuel]!.modalidade.nome, 'Ping-pong Misto');
  });

  test('RN023: escalação limitada a titulares + reservas', () {
    final t = store.time('t1'); // Futebol: 5 + 2 reservas
    final partida = store.partidas.firstWhere((p) => p.id == 'p3');
    final livres = store.equipe('e1').participantes.where((u) => !t.integrantes.contains(u)).toList();
    expect(store.escalar(partida, 't1', livres[0]), isNull);
    expect(store.escalar(partida, 't1', livres[1]), isNull);
    expect(store.escalar(partida, 't1', livres[2]), isNotNull); // cheio
    expect(store.titularesDe(t).length, 5);
    expect(store.reservasDe(t).length, 2);
  });

  test('RN017: escalação trava quando a partida começa', () {
    final partida = store.partidas.firstWhere((p) => p.id == 'p3');
    store.iniciarPartida(partida);
    expect(partida.status, StatusPartida.emAndamento);
    expect(store.podeEscalar(partida), isFalse);
  });

  testWidgets('abre na tela de login', (tester) async {
    await tester.pumpWidget(const GincanaApp());
    expect(find.text('Gincanas do Recanto'), findsOneWidget);
    expect(find.text('Ana Souza'), findsOneWidget);
  });
}
