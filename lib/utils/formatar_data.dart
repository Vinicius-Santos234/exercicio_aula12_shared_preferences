// Formata no padrão brasileiro, por exemplo: 20/10/2026 às 14:30
String formatarDataHora(DateTime data) {
  String doisDigitos(int valor) => valor.toString().padLeft(2, '0');

  return '${doisDigitos(data.day)}/${doisDigitos(data.month)}/${data.year} '
      'às ${doisDigitos(data.hour)}:${doisDigitos(data.minute)}';
}
