import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class OfferCard extends StatelessWidget {
  final Map<String, dynamic> oferta;
  final VoidCallback onAccept;

  const OfferCard({
    super.key,
    required this.oferta,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    // Valores por defecto si no vienen en el payload NoSQL
    final String nombre = oferta['trabajador_nombre'] ?? 'Profesional Verificado';
    final double calificacion = (oferta['trabajador_calificacion'] is num)
        ? (oferta['trabajador_calificacion'] as num).toDouble()
        : 4.8;
    final double precio = (oferta['precio'] is num)
        ? (oferta['precio'] as num).toDouble()
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shadowColor: Colors.black.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar del Trabajador con Inicial
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withAlpha(30),
              child: const Icon(
                Icons.person,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // Información del Trabajador
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        calificacion.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      const Text('•'),
                      const SizedBox(width: 8),
                      const Text(
                        'Socio Fixa',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${precio.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Botón de Aceptar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onAccept,
              child: const Text(
                'Aceptar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
