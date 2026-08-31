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
    final String nombre =
        oferta['trabajador_nombre'] ?? 'Profesional Verificado';
    final double calificacion = (oferta['trabajador_calificacion'] is num)
        ? (oferta['trabajador_calificacion'] as num).toDouble()
        : 4.8;
    final double precio =
        (oferta['precio'] is num) ? (oferta['precio'] as num).toDouble() : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Avatar del Trabajador Minimalista
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.surfaceElevated,
              child: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Información del Trabajador
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.textPrimary,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        calificacion.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '•',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Verificado',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${precio.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Botón de Aceptar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              onPressed: onAccept,
              child: const Text('Aceptar'),
            ),
          ],
        ),
      ),
    );
  }
}
