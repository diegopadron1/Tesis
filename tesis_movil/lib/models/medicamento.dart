class Medicamento {
  final int idMedicamento;
  final String nombre;
  final String? principioActivo;
  final String? concentracion;
  final String? presentacion;
  final int cantidadDisponible;
  final int stockMinimo;
  final String? fechaVencimiento; // <--- Agregamos este campo nuevamente

  Medicamento({
    required this.idMedicamento,
    required this.nombre,
    this.principioActivo,
    this.concentracion,
    this.presentacion,
    required this.cantidadDisponible,
    required this.stockMinimo,
    this.fechaVencimiento, // <--- Agregamos al constructor
  });

  factory Medicamento.fromJson(Map<String, dynamic> json) {
    return Medicamento(
      idMedicamento: json['id_medicamento'] ?? 0,
      nombre: json['nombre'] ?? 'Sin Nombre',
      principioActivo: json['principio_activo'],
      concentracion: json['concentracion'],
      presentacion: json['presentacion'],
      cantidadDisponible: json['cantidad_disponible'] ?? 0,
      stockMinimo: json['stock_minimo'] ?? 10,
      fechaVencimiento: json['fecha_vencimiento'], // <--- Leemos del JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_medicamento': idMedicamento,
      'nombre': nombre,
      'principio_activo': principioActivo,
      'concentracion': concentracion,
      'presentacion': presentacion,
      'cantidad_disponible': cantidadDisponible,
      'stock_minimo': stockMinimo,
      'fecha_vencimiento': fechaVencimiento, // <--- Enviamos al backend
    };
  }
}