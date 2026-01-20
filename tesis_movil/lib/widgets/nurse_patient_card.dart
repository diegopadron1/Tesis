import 'package:flutter/material.dart';

class NursePatientCard extends StatelessWidget {
  final Map<String, dynamic> paciente;
  final VoidCallback onTap;

  const NursePatientCard({
    super.key,
    required this.paciente,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colors based on current theme
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extract optional medication data if backend sends it
    final nombreMedicamento = paciente['nombre_medicamento'] as String?;
    final concentracion = paciente['concentracion'] as String?;
    
    // Extract pharmacy order status: null (not ordered), 'PENDIENTE' (in prep), 'LISTO' (ready)
    final String? estadoFarmacia = paciente['estado_farmacia'];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.pink.withValues(alpha: 0.5), width: 1),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        // Disable general tap if order is pending preparation to prevent duplicate requests
        onTap: estadoFarmacia == 'PENDIENTE' ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Name and Zone
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "${paciente['nombre']} ${paciente['apellido']}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      paciente['ubicacion'] ?? 'Sin zona',
                      style: const TextStyle(
                        color: Colors.pinkAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Basic Data: ID and Age
              Row(
                children: [
                  Icon(Icons.badge, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text("C.I: ${paciente['cedula_paciente']}", 
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(width: 15),
                  Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text("${paciente['edad']} años", 
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
              const Divider(height: 15),

              // --- MEDICATION SECTION (IF EXISTS) ---
              if (nombreMedicamento != null) ...[
                Row(
                  children: [
                    const Icon(Icons.medication, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16),
                          children: [
                            TextSpan(text: nombreMedicamento, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blue)),
                            if (concentracion != null)
                              TextSpan(text: " ($concentracion)", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // Medical Information Section
              _buildMedicalInfo(
                context, 
                label: "Indicaciones:", 
                value: paciente['indicaciones_inmediatas'] ?? "N/A",
                icon: Icons.priority_high,
                color: Colors.orangeAccent
              ),
              const SizedBox(height: 6),
              _buildMedicalInfo(
                context, 
                label: "Tratamiento:", 
                value: paciente['tratamientos_sugeridos'] ?? "N/A",
                icon: Icons.medical_services_outlined,
                color: Colors.blueAccent
              ),
              
              const SizedBox(height: 20),

              // --- DYNAMIC ACTION BUTTONS ---
              _buildActionButtons(estadoFarmacia),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalInfo(BuildContext context, {
    required String label, 
    required String value, 
    required IconData icon,
    required Color color
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text("$label ", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  // Button logic based on state
  Widget _buildActionButtons(String? estado) {
    
    // CASE 1: Not yet requested (status is null)
    if (estado == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap, // Call callback to request from pharmacy
          icon: const Icon(Icons.add_shopping_cart, size: 18),
          label: const Text("Solicitar a Farmacia"),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.pink[700],
            side: BorderSide(color: Colors.pink[700]!),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    // CASE 2: Requested, waiting for pharmacy preparation
    if (estado == 'PENDIENTE') {
      return SizedBox(
        width: double.infinity,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber[50], // Soft yellow background
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
              ),
              const SizedBox(width: 10),
              Text("EN PREPARACIÓN (FARMACIA)", 
                style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    // CASE 3: Pharmacy marked as READY
    if (estado == 'LISTO') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onTap, // Logic for "Supply/Withdraw" goes here
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text("RETIRAR Y SUMINISTRAR"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}