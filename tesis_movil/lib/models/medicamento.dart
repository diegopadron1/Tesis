class Medicamento {
  final int idMedicamento;
  final String nombre;
  final String? principioActivo;
  final String? concentracion;
  final String? presentacion;
  final int cantidadDisponible;
  final int stockMinimo;

  Medicamento({
    required this.idMedicamento,
    required this.nombre,
    this.principioActivo,
    this.concentracion,
    this.presentacion,
    required this.cantidadDisponible,
    required this.stockMinimo,
  });

  factory Medicamento.fromJson(Map<String, dynamic> json) {
    return Medicamento(
      idMedicamento: json['id_medicamento'],
      nombre: json['nombre'],
      principioActivo: json['principio_activo'],
      concentracion: json['concentracion'],
      presentacion: json['presentacion'],
      cantidadDisponible: json['cantidad_disponible'] ?? 0,
      stockMinimo: json['stock_minimo'] ?? 10,
    );
  }
}