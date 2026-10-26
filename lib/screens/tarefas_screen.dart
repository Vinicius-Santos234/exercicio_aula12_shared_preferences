import 'package:flutter/material.dart';

import '../models/tarefa.dart';
import '../services/preferences_service.dart';
import '../utils/formatar_data.dart';

// Desafio Avançado: lista de tarefas persistida como uma String JSON
class TarefasScreen extends StatefulWidget {
  const TarefasScreen({super.key});

  @override
  State<TarefasScreen> createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  final _service = PreferencesService();
  final _tituloController = TextEditingController();

  List<Tarefa> _tarefas = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  Future<void> _carregarTarefas() async {
    final tarefas = await _service.obterTarefas();
    if (!mounted) return;

    setState(() {
      _tarefas = tarefas;
      _carregando = false;
    });
  }

  // Toda alteração atualiza a tela e regrava a lista inteira no disco
  Future<void> _atualizarTarefas(List<Tarefa> tarefas) async {
    setState(() => _tarefas = tarefas);
    await _service.salvarTarefas(tarefas);
  }

  void _adicionarTarefa() {
    final titulo = _tituloController.text.trim();
    if (titulo.isEmpty) return;

    _tituloController.clear();
    _atualizarTarefas([
      ..._tarefas,
      Tarefa(titulo: titulo, criadaEm: DateTime.now()),
    ]);
  }

  void _alternarConclusao(int indice, bool concluida) {
    final tarefas = [..._tarefas];
    tarefas[indice] = tarefas[indice].copyWith(concluida: concluida);
    _atualizarTarefas(tarefas);
  }

  void _removerTarefa(int indice) {
    _atualizarTarefas([..._tarefas]..removeAt(indice));
  }

  Future<void> _mostrarJsonSalvo() async {
    final json = await _service.obterTarefasJson();
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON salvo no disco'),
        content: SingleChildScrollView(
          child: SelectableText(
            'key_tarefas = $json',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _carregando ? null : _mostrarJsonSalvo,
            tooltip: 'Ver JSON salvo',
            icon: const Icon(Icons.data_object),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tituloController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _adicionarTarefa(),
                          decoration: const InputDecoration(
                            labelText: 'Nova tarefa',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.add_task),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _adicionarTarefa,
                        tooltip: 'Adicionar tarefa',
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_tarefas.where((t) => t.concluida).length} de '
                      '${_tarefas.length} concluídas',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
                Expanded(
                  child: _tarefas.isEmpty
                      ? _construirListaVazia(context)
                      : _construirLista(context),
                ),
              ],
            ),
    );
  }

  Widget _construirLista(BuildContext context) {
    final corConcluida = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _tarefas.length,
      itemBuilder: (context, indice) {
        final tarefa = _tarefas[indice];

        return CheckboxListTile(
          value: tarefa.concluida,
          onChanged: (valor) => _alternarConclusao(indice, valor ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            tarefa.titulo,
            style: tarefa.concluida
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: corConcluida,
                  )
                : null,
          ),
          subtitle: Text('Criada em ${formatarDataHora(tarefa.criadaEm)}'),
          secondary: IconButton(
            onPressed: () => _removerTarefa(indice),
            tooltip: 'Remover tarefa',
            icon: const Icon(Icons.delete_outline),
          ),
        );
      },
    );
  }

  Widget _construirListaVazia(BuildContext context) {
    final cor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist, size: 64, color: cor),
          const SizedBox(height: 8),
          Text('Nenhuma tarefa salva ainda.', style: TextStyle(color: cor)),
        ],
      ),
    );
  }
}
