class Tarefa {
  final String titulo;
  final bool concluida;
  final DateTime criadaEm;

  const Tarefa({
    required this.titulo,
    this.concluida = false,
    required this.criadaEm,
  });

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      titulo: json['titulo'] as String,
      concluida: json['concluida'] as bool? ?? false,
      criadaEm: DateTime.parse(json['criada_em'] as String),
    );
  }

  // Cada tarefa vira um Map, e a lista inteira vira uma String com jsonEncode
  Map<String, dynamic> toJson() {
    return {
      'titulo': titulo,
      'concluida': concluida,
      'criada_em': criadaEm.toIso8601String(),
    };
  }

  Tarefa copyWith({bool? concluida}) {
    return Tarefa(
      titulo: titulo,
      concluida: concluida ?? this.concluida,
      criadaEm: criadaEm,
    );
  }
}
