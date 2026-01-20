import 'package:flutter/material.dart';

class PharmacyRequestCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback onDespachar;

  const PharmacyRequestCard({
    super.key,
    required this.solicitud,
    required this.onDespachar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extraemos datos seguros (con valores por defecto si vienen nulos)
    final nombreMedicamento = solicitud['medicamento']?['nombre'] ?? 'Medicamento Desconocido';
    final concentracion = solicitud['medicamento']?['concentracion'] ?? 'S/D';
    final cantidad = solicitud['cantidad'] ?? 1;
    
    // Datos del solicitante (Enfermera)
    final nombreEnfermera = solicitud['usuario_solicitante']?['nombre_completo'] ?? 
                            solicitud['usuario_solicitante']?['nombre_usuario'] ?? 
                            'Usuario Desconocido';
    
    // Datos del paciente (Contexto útil para farmacia)
    final cedulaPaciente = solicitud['cedula_paciente'] ?? '---';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Borde verde suave para diferenciar de enfermería
        side: BorderSide(color: Colors.teal.withValues(alpha: 0.3), width: 1),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ENCABEZADO: MEDICAMENTO Y CANTIDAD ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medication_liquid, color: Colors.teal, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreMedicamento,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$concentracion",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de Cantidad
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "x$cantidad",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            const Divider(height: 25),

            // --- INFO DEL SOLICITANTE Y PACIENTE ---
            Row(
              children: [
                Icon(Icons.person_pin, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  "Solicitado por: ",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Expanded(
                  child: Text(
                    nombreEnfermera,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.tealAccent : Colors.teal[800]
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  "Paciente C.I: $cedulaPaciente",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // --- BOTÓN DE ACCIÓN ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDespachar,
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text("MARCAR COMO PREPARADO"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}