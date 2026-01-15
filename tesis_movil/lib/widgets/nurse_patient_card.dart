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
    // Colores basados en tu tema actual
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Extraemos datos opcionales de medicamento si el backend los enviara
    // (Asegúrate de que tu backend envíe 'nombre_medicamento' y 'concentracion' si quieres verlos aquí)
    final nombreMedicamento = paciente['nombre_medicamento'] as String?;
    final concentracion = paciente['concentracion'] as String?;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.pink.withValues(alpha: 0.5), width: 1),
      ),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Nombre y Zona
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
              
              // Datos básicos: Cédula y Edad
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

              // --- NUEVA SECCIÓN: MEDICAMENTO (SI EXISTE) ---
              if (nombreMedicamento != null) ...[
                Row(
                  children: [
                    const Icon(Icons.medication, size: 18, color: Colors.pink),
                    const SizedBox(width: 6),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 15),
                          children: [
                            TextSpan(text: nombreMedicamento, style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (concentracion != null)
                              TextSpan(text: " ($concentracion)", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Sección Médica Informativa
              _buildMedicalInfo(
                context, 
                label: "Indicaciones Inmediatas:", 
                value: paciente['indicaciones_inmediatas'] ?? "Ninguna registrada",
                icon: Icons.priority_high,
                color: Colors.orangeAccent
              ),
              const SizedBox(height: 10),
              _buildMedicalInfo(
                context, 
                label: "Tratamiento Sugerido:", 
                value: paciente['tratamientos_sugeridos'] ?? "Pendiente",
                icon: Icons.medical_services_outlined,
                color: Colors.blueAccent
              ),
              
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Gestionar órdenes", 
                      style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold)),
                    Icon(Icons.chevron_right, color: Colors.pinkAccent),
                  ],
                ),
              )
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 22, top: 2),
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, height: 1.2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}