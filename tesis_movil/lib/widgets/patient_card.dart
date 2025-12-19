import 'package:flutter/material.dart';

class PatientCard extends StatelessWidget {
  final Map<String, dynamic> paciente;
  final VoidCallback onTap;
  
  // --- CAMBIO: AHORA SON OPCIONALES (NULLABLE) ---
  final VoidCallback? onDarAlta;
  final VoidCallback? onAtender;

  const PatientCard({
    super.key, 
    required this.paciente, 
    required this.onTap,
    this.onDarAlta, // Ya no es 'required'
    this.onAtender, // Ya no es 'required'
  });

  Color _getColor(String? colorName) {
    switch (colorName) {
      case 'Rojo': return Colors.red;
      case 'Naranja': return Colors.orange;
      case 'Amarillo': return Colors.yellow.shade700;
      case 'Verde': return Colors.green;
      case 'Azul': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getPrioridadText(String? colorName) {
    switch (colorName) {
      case 'Rojo': return 'Atención inmediata';
      case 'Naranja': return 'Atención muy urgente';
      case 'Amarillo': return 'Atención urgente';
      case 'Verde': return 'Atención normal';
      case 'Azul': return 'No urgente';
      default: return 'Sin Clasificar';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(paciente['color']);
    final estado = paciente['estado'] ?? 'Desconocido';
    final isEnEspera = estado == 'En Espera';
    
    final textoPrioridad = _getPrioridadText(paciente['color']);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              stops: const [0.03, 0.03], 
              colors: [color, Colors.white]
            )
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Fila Superior: Nombre y Etiqueta de Prioridad ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        paciente['nombre_completo'] ?? "${paciente['nombre'] ?? ''} ${paciente['apellido'] ?? ''}".trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 18,
                          color: Colors.black87 
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8), 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha:0.1), // Usamos withOpacity por compatibilidad
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha:0.5))
                      ),
                      child: Text(
                        textoPrioridad, 
                        style: TextStyle(
                          color: color, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 11 
                        ),
                      ),
                    )
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // --- Información Principal ---
                Row(
                  children: [
                    Icon(Icons.badge, size: 16, color: Colors.grey[700]), 
                    const SizedBox(width: 5),
                    Text(
                      "C.I: ${paciente['cedula_paciente'] ?? paciente['cedula']}", 
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)
                    ),
                    const SizedBox(width: 15),
                    Icon(Icons.cake, size: 16, color: Colors.grey[700]), 
                    const SizedBox(width: 5),
                    Text(
                      "${paciente['edad']} años",
                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ],
                ),
                
                const SizedBox(height: 5),
                
                // --- Ubicación ---
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.teal),
                    const SizedBox(width: 5),
                    Text(
                      "Ubicación: ${paciente['ubicacion']}",
                      style: TextStyle(color: Colors.teal[800], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),

                if (!isEnEspera && paciente['residente_atendiendo'] != null) ...[
                   const SizedBox(height: 5),
                   Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, size: 16, color: Colors.indigo),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Atendido por: ${paciente['residente_atendiendo']}",
                          style: TextStyle(color: Colors.indigo[800], fontWeight: FontWeight.w500, fontStyle: FontStyle.italic),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const Divider(),

                // --- Fila Inferior: Estado y Botones ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isEnEspera ? Icons.access_time : Icons.health_and_safety, 
                          size: 16, 
                          color: isEnEspera ? Colors.orange : Colors.blue
                        ),
                        const SizedBox(width: 5),
                        Text(
                          estado,
                          style: TextStyle(
                            color: isEnEspera ? Colors.orange[800] : Colors.blue[800],
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),

                    // --- CAMBIO: RENDERIZADO CONDICIONAL DE BOTONES ---
                    Row(
                      children: [
                        // Botón ATENDER (Solo si está en espera Y se pasó la función)
                        if (isEnEspera && onAtender != null)
                          SizedBox(
                            height: 35,
                            child: ElevatedButton.icon(
                              onPressed: onAtender,
                              icon: const Icon(Icons.front_hand, size: 16),
                              label: const Text("Atender"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[50],
                                foregroundColor: Colors.blue[700],
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12)
                              ),
                            ),
                          ),

                        // Botón DAR ALTA (Solo si NO está en espera Y se pasó la función)
                        if (!isEnEspera && onDarAlta != null)
                          SizedBox(
                            height: 35,
                            child: ElevatedButton.icon(
                              onPressed: onDarAlta,
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text("Finalizar"), // Cambio sutil de texto
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[50],
                                foregroundColor: Colors.green[700],
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12)
                              ),
                            ),
                          )
                      ],
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}