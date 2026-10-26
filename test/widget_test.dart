// Testes da persistência local da Aula 12.
//
// O disco é simulado com SharedPreferences.setMockInitialValues, que troca o
// armazenamento nativo por um mapa em memória. Assim cada teste começa com um
// "disco" conhecido e pode conferir exatamente o que foi gravado em cada chave.
// Cobrem o PreferencesService, a tela do roteiro, os três desafios e a
// correção de layout da tela de configurações.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdm_aula12_shared_preferences/main.dart';
import 'package:pdm_aula12_shared_preferences/models/tarefa.dart';
import 'package:pdm_aula12_shared_preferences/services/preferences_service.dart';
import 'package:pdm_aula12_shared_preferences/utils/formatar_data.dart';

Future<void> _montarApp(
  WidgetTester tester, {
  bool modoEscuroInicial = false,
}) async {
  await tester.pumpWidget(MeuApp(modoEscuroInicial: modoEscuroInicial));
  await tester.pumpAndSettle();
}

Brightness _brilhoAtual(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(Scaffold).last)).brightness;
}

Future<void> _abrirTarefas(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Minhas Tarefas'));
  await tester.pumpAndSettle();
}

Future<void> _adicionarTarefa(WidgetTester tester, String titulo) async {
  await tester.enterText(find.byType(TextField), titulo);
  await tester.tap(find.byTooltip('Adicionar tarefa'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PreferencesService', () {
    test('devolve os valores padrão quando o disco está vazio', () async {
      final service = PreferencesService();

      expect(await service.obterNomeUsuario(), 'Usuário Convidado');
      expect(await service.obterModoEscuro(), isFalse);
      expect(await service.obterTarefas(), isEmpty);
    });

    test(
      'grava nome e tema com setString/setBool nas chaves do roteiro',
      () async {
        final service = PreferencesService();

        await service.salvarNomeUsuario('Vinicius');
        await service.salvarModoEscuro(true);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('key_nome_usuario'), 'Vinicius');
        expect(prefs.getBool('key_modo_escuro'), isTrue);
        expect(await service.obterNomeUsuario(), 'Vinicius');
        expect(await service.obterModoEscuro(), isTrue);
      },
    );

    test('limparTudo apaga todas as chaves', () async {
      SharedPreferences.setMockInitialValues({
        'key_nome_usuario': 'Vinicius',
        'key_modo_escuro': true,
        'key_ultimo_acesso': '2026-10-20 14:05:09.123456',
        'key_tarefas': '[]',
      });
      final service = PreferencesService();

      await service.limparTudo();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
      expect(await service.obterNomeUsuario(), 'Usuário Convidado');
    });

    test(
      'Básico: registrarAcesso devolve o acesso anterior e grava o atual',
      () async {
        final service = PreferencesService();

        expect(await service.registrarAcesso(), isNull);

        final prefs = await SharedPreferences.getInstance();
        final gravado = prefs.getString('key_ultimo_acesso');
        expect(gravado, isNotNull);
        // Mesmo formato de DateTime.now().toString() pedido no roteiro
        expect(DateTime.parse(gravado!).toString(), gravado);

        expect(await service.registrarAcesso(), DateTime.parse(gravado));
      },
    );

    test('Avançado: a List<Map> vira uma única String JSON no disco', () async {
      final service = PreferencesService();
      final criadaEm = DateTime(2026, 10, 26, 9, 30);

      await service.salvarTarefas([
        Tarefa(titulo: 'Estudar Flutter', concluida: true, criadaEm: criadaEm),
        Tarefa(titulo: 'Entregar trabalho', criadaEm: criadaEm),
      ]);

      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('key_tarefas');
      expect(json, isA<String>());
      expect(jsonDecode(json!), [
        {
          'titulo': 'Estudar Flutter',
          'concluida': true,
          'criada_em': '2026-10-26T09:30:00.000',
        },
        {
          'titulo': 'Entregar trabalho',
          'concluida': false,
          'criada_em': '2026-10-26T09:30:00.000',
        },
      ]);
      expect(await service.obterTarefasJson(), json);

      final lidas = await service.obterTarefas();
      expect(lidas.map((t) => t.titulo), [
        'Estudar Flutter',
        'Entregar trabalho',
      ]);
      expect(lidas.map((t) => t.concluida), [true, false]);
      expect(lidas.first.criadaEm, criadaEm);
    });

    test('Avançado: JSON corrompido no disco vira lista vazia', () async {
      SharedPreferences.setMockInitialValues({'key_tarefas': '[{"titulo":'});

      expect(await PreferencesService().obterTarefas(), isEmpty);
    });
  });

  test('formatarDataHora usa o padrão brasileiro com zeros à esquerda', () {
    expect(formatarDataHora(DateTime(2026, 3, 5, 8, 7)), '05/03/2026 às 08:07');
  });

  group('Tela de configurações (roteiro)', () {
    testWidgets('mostra o loading e preenche a tela com o que está no disco', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'key_nome_usuario': 'Vinicius',
        'key_modo_escuro': true,
      });

      await tester.pumpWidget(const MeuApp(modoEscuroInicial: true));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.widgetWithText(TextField, 'Vinicius'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
    });

    testWidgets('sem nada salvo usa o nome padrão e o tema claro', (
      tester,
    ) async {
      await _montarApp(tester);

      expect(
        find.widgetWithText(TextField, 'Usuário Convidado'),
        findsOneWidget,
      );
      expect(_brilhoAtual(tester), Brightness.light);
    });

    testWidgets('o tema lido no main() já abre o app no modo escuro', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'key_modo_escuro': true});

      await _montarApp(tester, modoEscuroInicial: true);

      expect(_brilhoAtual(tester), Brightness.dark);
    });

    testWidgets('Salvar grava no disco, avisa e troca o tema na hora', (
      tester,
    ) async {
      await _montarApp(tester);

      await tester.enterText(find.byType(TextField), 'Ana Souza');
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      // Só o switch não muda o tema: ele muda ao salvar
      expect(_brilhoAtual(tester), Brightness.light);

      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('key_nome_usuario'), 'Ana Souza');
      expect(prefs.getBool('key_modo_escuro'), isTrue);
      expect(find.text('Preferências salvas com sucesso!'), findsOneWidget);
      expect(_brilhoAtual(tester), Brightness.dark);
    });
  });

  group('Desafio Básico — último acesso', () {
    testWidgets('no primeiro acesso o rodapé avisa e a data é gravada', (
      tester,
    ) async {
      await _montarApp(tester);

      expect(find.text('Primeiro acesso ao aplicativo'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('key_ultimo_acesso'), isNotNull);
    });

    testWidgets(
      'o rodapé mostra a execução anterior e o disco recebe a atual',
      (tester) async {
        const anterior = '2026-10-20 14:05:09.123456';
        SharedPreferences.setMockInitialValues({'key_ultimo_acesso': anterior});

        await _montarApp(tester);

        expect(find.text('Último acesso: 20/10/2026 às 14:05'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        final atual = DateTime.parse(prefs.getString('key_ultimo_acesso')!);
        expect(atual.isAfter(DateTime.parse(anterior)), isTrue);
      },
    );
  });

  group('Desafio Intermediário — Redefinir Padrões', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'key_nome_usuario': 'Vinicius',
        'key_modo_escuro': true,
        'key_ultimo_acesso': '2026-10-20 14:05:09.123456',
        'key_tarefas':
            '[{"titulo":"Estudar","concluida":false,'
            '"criada_em":"2026-10-20T14:00:00.000"}]',
      });
    });

    testWidgets('Cancelar no diálogo mantém tudo como estava', (tester) async {
      await _montarApp(tester, modoEscuroInicial: true);

      await tester.tap(find.text('Redefinir Padrões'));
      await tester.pumpAndSettle();
      expect(find.text('Redefinir padrões?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('key_nome_usuario'), 'Vinicius');
      expect(prefs.getString('key_tarefas'), isNotNull);
      expect(find.widgetWithText(TextField, 'Vinicius'), findsOneWidget);
      expect(_brilhoAtual(tester), Brightness.dark);
    });

    testWidgets('confirmar chama limparTudo e restaura a interface', (
      tester,
    ) async {
      await _montarApp(tester, modoEscuroInicial: true);

      await tester.tap(find.text('Redefinir Padrões'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Redefinir'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      // Sobra apenas o registro deste acesso, gravado após a limpeza
      expect(prefs.getKeys(), {'key_ultimo_acesso'});

      expect(
        find.widgetWithText(TextField, 'Usuário Convidado'),
        findsOneWidget,
      );
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isFalse,
      );
      expect(_brilhoAtual(tester), Brightness.light);
      expect(find.text('Primeiro acesso ao aplicativo'), findsOneWidget);
      expect(
        find.text('Preferências redefinidas para o padrão.'),
        findsOneWidget,
      );
    });
  });

  group('Desafio Avançado — tarefas em JSON', () {
    testWidgets('sem tarefas no disco mostra a lista vazia', (tester) async {
      await _montarApp(tester);
      await _abrirTarefas(tester);

      expect(find.text('Minhas Tarefas'), findsOneWidget);
      expect(find.text('Nenhuma tarefa salva ainda.'), findsOneWidget);
      expect(find.text('0 de 0 concluídas'), findsOneWidget);
    });

    testWidgets('adicionar, concluir e remover regravam o JSON no disco', (
      tester,
    ) async {
      await _montarApp(tester);
      await _abrirTarefas(tester);
      final prefs = await SharedPreferences.getInstance();

      List<dynamic> salvas() => jsonDecode(prefs.getString('key_tarefas')!);

      await _adicionarTarefa(tester, 'Estudar Flutter');
      // Enter no teclado também adiciona
      await tester.enterText(find.byType(TextField), 'Entregar trabalho');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(salvas().map((t) => t['titulo']), [
        'Estudar Flutter',
        'Entregar trabalho',
      ]);
      expect(find.text('0 de 2 concluídas'), findsOneWidget);

      await tester.tap(find.text('Estudar Flutter'));
      await tester.pumpAndSettle();
      expect(salvas().first['concluida'], isTrue);
      expect(find.text('1 de 2 concluídas'), findsOneWidget);

      await tester.tap(find.byTooltip('Remover tarefa').first);
      await tester.pumpAndSettle();
      expect(salvas().map((t) => t['titulo']), ['Entregar trabalho']);
      expect(find.text('Estudar Flutter'), findsNothing);
      expect(find.text('0 de 1 concluídas'), findsOneWidget);
    });

    testWidgets('título em branco não vira tarefa', (tester) async {
      await _montarApp(tester);
      await _abrirTarefas(tester);

      await _adicionarTarefa(tester, '   ');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('key_tarefas'), isNull);
      expect(find.text('Nenhuma tarefa salva ainda.'), findsOneWidget);
    });

    testWidgets('ao reabrir a tela a lista volta do disco com jsonDecode', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'key_tarefas': jsonEncode([
          {
            'titulo': 'Revisar SharedPreferences',
            'concluida': true,
            'criada_em': '2026-10-25T19:45:00.000',
          },
        ]),
      });
      await _montarApp(tester);
      await _abrirTarefas(tester);

      expect(find.text('Revisar SharedPreferences'), findsOneWidget);
      expect(find.text('Criada em 25/10/2026 às 19:45'), findsOneWidget);
      expect(find.text('1 de 1 concluídas'), findsOneWidget);
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );

      await _adicionarTarefa(tester, 'Gravar evidências');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _abrirTarefas(tester);

      expect(find.text('Revisar SharedPreferences'), findsOneWidget);
      expect(find.text('Gravar evidências'), findsOneWidget);
    });

    testWidgets('o botão de JSON mostra a String exatamente como foi gravada', (
      tester,
    ) async {
      await _montarApp(tester);
      await _abrirTarefas(tester);
      await _adicionarTarefa(tester, 'Estudar Flutter');

      await tester.tap(find.byTooltip('Ver JSON salvo'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(find.text('JSON salvo no disco'), findsOneWidget);
      expect(
        find.text('key_tarefas = ${prefs.getString('key_tarefas')}'),
        findsOneWidget,
      );
    });
  });

  group('Correção — layout da tela de configurações', () {
    void definirTela(WidgetTester tester, double altura) {
      tester.view.physicalSize = Size(360, altura);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('com pouca altura (teclado aberto) rola em vez de estourar', (
      tester,
    ) async {
      definirTela(tester, 400);
      await _montarApp(tester);

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Redefinir Padrões'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Redefinir Padrões'));
      await tester.pumpAndSettle();
      expect(find.text('Redefinir padrões?'), findsOneWidget);
    });

    testWidgets('com sobra de altura os botões continuam no fim da tela', (
      tester,
    ) async {
      definirTela(tester, 800);
      await _montarApp(tester);

      final fimDoBotao = tester
          .getBottomLeft(find.text('Redefinir Padrões'))
          .dy;
      final topoDoRodape = tester
          .getTopLeft(find.text('Primeiro acesso ao aplicativo'))
          .dy;
      expect(topoDoRodape - fimDoBotao, lessThan(60));
    });
  });
}
