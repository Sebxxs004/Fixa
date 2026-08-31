import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class WebMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const WebMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<WebMapWidget> createState() => _WebMapWidgetState();
}

class _WebMapWidgetState extends State<WebMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _zoomLevel = 15;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Convierte Latitud y Longitud a coordenadas de Tiles de OpenStreetMap (Slippy Map Tilenames)
  Point<int> _latLngToTile(double lat, double lng, int zoom) {
    final n = pow(2.0, zoom);
    final rad = lat * pi / 180.0;
    final xtile = ((lng + 180.0) / 360.0 * n).floor();
    final ytile =
        ((1.0 - log(tan(rad) + (1.0 / cos(rad))) / pi) / 2.0 * n).floor();
    return Point(xtile, ytile);
  }

  @override
  Widget build(BuildContext context) {
    final centerTile = _latLngToTile(widget.latitude, widget.longitude, _zoomLevel);

    return ClipRRect(
      child: Stack(
        children: [
          // Cuadrícula 3x3 de Tiles reales de OpenStreetMap
          Positioned.fill(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                final dx = (index % 3) - 1;
                final dy = (index ~/ 3) - 1;
                final tileX = centerTile.x + dx;
                final tileY = centerTile.y + dy;
                final tileUrl =
                    'https://tile.openstreetmap.org/$_zoomLevel/$tileX/$tileY.png';

                return Image.network(
                  tileUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child: Icon(Icons.map_outlined, color: AppColors.textMuted),
                    ),
                  ),
                );
              },
            ),
          ),

          // Capa de oscurecimiento sutil para alinearlo con la paleta monocromática
          Positioned.fill(
            child: Container(
              color: Colors.white.withAlpha(20),
            ),
          ),

          // Pin de Ubicación Actual con Animación de Radar Pulsante
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Etiqueta de Ubicación
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.my_location_rounded,
                          size: 13, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Tu Ubicación Actual',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Marcador y Onda de Radar
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 48 * _pulseAnimation.value,
                          height: 48 * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withAlpha(
                              (100 * (1.6 - _pulseAnimation.value)).clamp(0, 100).toInt(),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Barra Superior de Búsqueda / Dirección
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ubicación: Lat ${widget.latitude.toStringAsFixed(4)}, Lng ${widget.longitude.toStringAsFixed(4)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controles de Mapa Flotantes (Zoom + / -)
          Positioned(
            right: 16,
            bottom: 24,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 2,
                  onPressed: () {
                    if (_zoomLevel < 18) {
                      setState(() {
                        _zoomLevel++;
                      });
                    }
                  },
                  child: const Icon(Icons.add_rounded, size: 20),
                ),
                const SizedBox(height: 6),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 2,
                  onPressed: () {
                    if (_zoomLevel > 10) {
                      setState(() {
                        _zoomLevel--;
                      });
                    }
                  },
                  child: const Icon(Icons.remove_rounded, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
