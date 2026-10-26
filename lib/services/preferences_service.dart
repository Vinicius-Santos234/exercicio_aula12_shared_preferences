import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tarefa.dart';

class PreferencesService {
  static const String _keyNomeUsuario = 'key_nome_usuario';
  static const String _keyModoEscuro = 'key_modo_escuro';
  static const String _keyUltimoAcesso = 'key_ultimo_acesso';
  static const String _keyTarefas = 'key_tarefas';

  Future<void> salvarNomeUsuario(String nome) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNomeUsuario, nome);
  }

  Future<String> obterNomeUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyNomeUsuario) ?? 'Usuário Convidado';
  }

  Future<void> salvarModoEscuro(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyModoEscuro, valor);
  }

  Future<bool> obterModoEscuro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyModoEscuro) ?? false;
  }

  // Desafio Básico: grava a data/hora desta execução e devolve a da execução
  // anterior (null no primeiro acesso)
  Future<DateTime?> registrarAcesso() async {
    final prefs = await SharedPreferences.getInstance();
    final anterior = prefs.getString(_keyUltimoAcesso);
    await prefs.setString(_keyUltimoAcesso, DateTime.now().toString());
    return anterior == null ? null : DateTime.tryParse(anterior);
  }

  // Desafio Avançado: o SharedPreferences só guarda tipos simples, então a
  // List<Map> é convertida em uma única String JSON
  Future<void> salvarTarefas(List<Tarefa> tarefas) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = tarefas.map((tarefa) => tarefa.toJson()).toList();
    await prefs.setString(_keyTarefas, jsonEncode(lista));
  }

  Future<List<Tarefa>> obterTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyTarefas);
    if (json == null) return [];

    try {
      final lista = jsonDecode(json) as List<dynamic>;
      return lista
          .map((item) => Tarefa.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException {
      // String corrompida no disco: começa com a lista vazia em vez de travar
      return [];
    }
  }

  // String exatamente como está gravada, para conferir o JSON na interface
  Future<String> obterTarefasJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTarefas) ?? '[]';
  }

  Future<void> limparTudo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
