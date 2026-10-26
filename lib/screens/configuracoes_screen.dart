import 'package:flutter/material.dart';

import '../services/preferences_service.dart';
import '../utils/formatar_data.dart';
import 'tarefas_screen.dart';

class ConfiguracoesScreen extends StatefulWidget {
  final Function(bool) onTemaAlterado;

  const ConfiguracoesScreen({super.key, required this.onTemaAlterado});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _service = PreferencesService();
  final _nomeController = TextEditingController();

  bool _modoEscuro = false;
  bool _carregando = true;
  DateTime? _ultimoAcesso;

  @override
  void initState() {
    super.initState();
    _carregarPreferencias();
  }

  Future<void> _carregarPreferencias() async {
    final nome = await _service.obterNomeUsuario();
    final modoEscuro = await _service.obterModoEscuro();
    final ultimoAcesso = await _service.registrarAcesso();

    setState(() {
      _nomeController.text = nome;
      _modoEscuro = modoEscuro;
      _ultimoAcesso = ultimoAcesso;
      _carregando = false;
    });
  }

  Future<void> _salvarPreferencias() async {
    await _service.salvarNomeUsuario(_nomeController.text);
    await _service.salvarModoEscuro(_modoEscuro);

    widget.onTemaAlterado(_modoEscuro);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferências salvas com sucesso!')),
      );
    }
  }

  // Desafio Intermediário: apaga o disco e volta aos valores iniciais do app
  Future<void> _redefinirPadroes() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redefinir padrões?'),
        content: const Text(
          'O nome, o tema, as tarefas e a data do último acesso salvos '
          'serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redefinir'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    await _service.limparTudo();
    // Com o disco vazio, o serviço devolve os padrões ('Usuário Convidado',
    // tema claro) e este acesso passa a ser o primeiro
    await _carregarPreferencias();
    widget.onTemaAlterado(_modoEscuro);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferências redefinidas para o padrão.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações & Perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TarefasScreen()),
            ),
            tooltip: 'Minhas Tarefas',
            icon: const Icon(Icons.checklist),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Usuário',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Ativar Modo Escuro'),
              subtitle: const Text(
                'Persiste o tema visual selecionado no disco',
              ),
              value: _modoEscuro,
              onChanged: (valor) => setState(() => _modoEscuro = valor),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _salvarPreferencias,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Alterações'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _redefinirPadroes,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Redefinir Padrões'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _construirRodape(context),
    );
  }

  // Desafio Básico: rodapé com a data/hora da execução anterior
  Widget _construirRodape(BuildContext context) {
    final cor = Theme.of(context).colorScheme.onSurfaceVariant;
    final texto = _ultimoAcesso == null
        ? 'Primeiro acesso ao aplicativo'
        : 'Último acesso: ${formatarDataHora(_ultimoAcesso!)}';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 16, color: cor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: cor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
