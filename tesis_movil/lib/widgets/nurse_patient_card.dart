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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // --- DATA EXTRACTION ---
    final String? listaMedicamentos = paciente['indicaciones_medicamentos'] ?? paciente['requerimiento_medicamentos'];
    
    // Extraemos el estado de la farmacia
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
        // Habilitamos el tap si no está en preparación (PENDIENTE o LISTO para retirar)
        onTap: estadoFarmacia == 'PENDIENTE' ? null : onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER: NAME & ZONE ---
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
              
              // --- BASIC DATA: ID & AGE ---
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

              // --- MEDICATION LIST SECTION ---
              if (listaMedicamentos != null && listaMedicamentos.isNotEmpty && listaMedicamentos != "Ninguna registrada") ...[
                const Text(
                  "MEDICAMENTOS SOLICITADOS:",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3))
                  ),
                  child: Text(
                    listaMedicamentos,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.blue[900],
                      fontSize: 14,
                      height: 1.4 
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              // --- MEDICAL INFO ---
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

              // --- ACTION BUTTONS ACTUALIZADOS ---
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

  Widget _buildActionButtons(String? estado) {
    // CASO 1: No solicitado aún
    if (estado == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap, 
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

    // CASO 2: Pendiente en farmacia (En preparación)
    if (estado == 'PENDIENTE') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber[50], 
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber)
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
            ),
            SizedBox(width: 10),
            Text("EN PREPARACIÓN (FARMACIA)", 
              style: TextStyle(color: Color(0xFF795548), fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }

    // CASO 3: Listo en farmacia (Esperando que la enfermera lo busque)
    if (estado == 'LISTO') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap, 
          icon: const Icon(Icons.directions_walk, size: 18),
          label: const Text("IR A RETIRAR A FARMACIA"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    // CASO 4: Entregado (La enfermera ya tiene el medicamento, ahora debe suministrarlo)
    if (estado == 'ENTREGADO') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap, 
          icon: const Icon(Icons.vaccines, size: 18),
          label: const Text("SUMINISTRAR AL PACIENTE"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}