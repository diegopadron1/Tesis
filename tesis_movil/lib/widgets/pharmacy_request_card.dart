import 'package:flutter/material.dart';

class PharmacyRequestCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  final VoidCallback onAction; // Nombre genérico para manejar ambos estados

  const PharmacyRequestCard({
    super.key,
    required this.solicitud,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extraemos el estado actual de la solicitud
    final String estado = solicitud['estatus'] ?? 'PENDIENTE';
    final bool isListo = estado == 'LISTO';

    // Datos del medicamento
    final nombreMedicamento = solicitud['medicamento']?['nombre'] ?? 'Medicamento Desconocido';
    final concentracion = solicitud['medicamento']?['concentracion'] ?? '';
    final presentacion = solicitud['medicamento']?['presentacion'] ?? '';
    final cantidad = solicitud['cantidad'] ?? 1;
    
    // Datos del solicitante y paciente
    final nombreEnfermera = solicitud['usuario_solicitante']?['nombre_completo'] ?? 
                            solicitud['usuario_solicitante']?['nombre_usuario'] ?? 
                            'Personal de Enfermería';
    
    final cedulaPaciente = solicitud['cedula_paciente'] ?? '---';

    return Card(
      elevation: isListo ? 1 : 4, // Menos sombra si ya está preparado
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Borde naranja si está listo para entregar, teal si está pendiente
        side: BorderSide(
          color: isListo ? Colors.orange : Colors.teal.withValues(alpha: 0.3), 
          width: 1.5
        ),
      ),
      color: isListo 
          ? (isDark ? const Color(0xFF2C2C2C) : Colors.orange[50]) 
          : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
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
                    color: (isListo ? Colors.orange : Colors.teal).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isListo ? Icons.pending_actions : Icons.medication_liquid, 
                    color: isListo ? Colors.orange[800] : Colors.teal, 
                    size: 28
                  ),
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
                        [concentracion, presentacion].where((s) => s.isNotEmpty).join(" - "),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de Cantidad y Estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isListo ? Colors.orange : Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "x$cantidad",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isListo)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          "LISTO PARA RETIRAR", 
                          style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w900)
                        ),
                      ),
                  ],
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

            // --- BOTÓN DE ACCIÓN DINÁMICO ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(
                  isListo ? Icons.delivery_dining : Icons.check_circle_outline, 
                  size: 20
                ),
                label: Text(
                  isListo ? "CONFIRMAR ENTREGA FINAL" : "MARCAR COMO PREPARADO"
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isListo ? Colors.orange[800] : Colors.teal[700],
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