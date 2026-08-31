import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class WebMapWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final Function(double lat, double lng)? onLocationChanged;

  const WebMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onLocationChanged,
  });

  @override
  State<WebMapWidget> createState() => _WebMapWidgetState();
}

class _WebMapWidgetState extends State<WebMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late TextEditingController _addressController;

  double? _currentLat;
  double? _currentLng;
  int _zoomLevel = 15;
  bool _isCustomLocation = false;

  double get activeLat => _currentLat ?? widget.latitude;
  double get activeLng => _currentLng ?? widget.longitude;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.latitude;
    _currentLng = widget.longitude;
    _addressController = TextEditingController(
      text: 'Lat ${activeLat.toStringAsFixed(4)}, Lng ${activeLng.toStringAsFixed(4)}',
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant WebMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      if (!_isCustomLocation) {
        setState(() {
          _currentLat = widget.latitude;
          _currentLng = widget.longitude;
          _updateAddressText();
        });
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _updateAddressText() {
    _addressController.text =
        'Lat ${activeLat.toStringAsFixed(4)}, Lng ${activeLng.toStringAsFixed(4)}';
  }

  void _notifyLocationChange() {
    widget.onLocationChanged?.call(activeLat, activeLng);
  }

  void _resetToGpsLocation() {
    setState(() {
      _currentLat = widget.latitude;
      _currentLng = widget.longitude;
      _isCustomLocation = false;
      _updateAddressText();
    });
    _notifyLocationChange();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // Convierte el desplazamiento en píxeles (dx, dy) en deltas de Latitud y Longitud
    final double mapFactor = 360.0 / (256.0 * pow(2.0, _zoomLevel));
    final double dLng = -details.delta.dx * mapFactor;
    final double dLat = details.delta.dy * mapFactor * cos(activeLat * pi / 180.0);

    setState(() {
      _currentLat = (activeLat + dLat).clamp(-85.0, 85.0);
      _currentLng = (activeLng + dLng).clamp(-180.0, 180.0);
      _isCustomLocation = true;
      _updateAddressText();
    });

    _notifyLocationChange();
  }

  // Convierte Longitud a coordenada continua de Tile X
  double _lngToTileX(double lng, int zoom) {
    return (lng + 180.0) / 360.0 * pow(2.0, zoom);
  }

  // Convierte Latitud a coordenada continua de Tile Y
  double _latToTileY(double lat, int zoom) {
    final rad = lat * pi / 180.0;
    return (1.0 - log(tan(rad) + (1.0 / cos(rad))) / pi) / 2.0 * pow(2.0, zoom);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        final double exactX = _lngToTileX(activeLng, _zoomLevel);
        final double exactY = _latToTileY(activeLat, _zoomLevel);

        final int centerTileX = exactX.floor();
        final int centerTileY = exactY.floor();

        final double centerPxX = width / 2;
        final double centerPxY = height / 2;

        const double tileSize = 256.0;

        final List<Widget> tileWidgets = [];

        // Generar tiles circundantes (5 de ancho x 7 de alto) con escala 1:1 sin distorsión
        for (int dx = -2; dx <= 2; dx++) {
          for (int dy = -3; dy <= 3; dy++) {
            final int tx = centerTileX + dx;
            final int ty = centerTileY + dy;

            final double tileLeft = centerPxX + (tx - exactX) * tileSize;
            final double tileTop = centerPxY + (ty - exactY) * tileSize;

            final String tileUrl =
                'https://tile.openstreetmap.org/$_zoomLevel/$tx/$ty.png';

            tileWidgets.add(
              Positioned(
                left: tileLeft,
                top: tileTop,
                width: tileSize,
                height: tileSize,
                child: Image.network(
                  tileUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child:
                          Icon(Icons.map_outlined, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return GestureDetector(
          onPanUpdate: _handlePanUpdate,
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // 1. Mosaico de Tiles 1:1 (Arrastrables)
                ...tileWidgets,

                // 2. Capa de oscurecimiento sutil
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withAlpha(15),
                  ),
                ),

                // 3. Pin de Ubicación en Centro de Pantalla (Punto de Selección)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Etiqueta de Ubicación
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(60),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isCustomLocation
                                  ? Icons.pin_drop_rounded
                                  : Icons.my_location_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isCustomLocation
                                  ? 'Ubicación Elegida'
                                  : 'Tu Ubicación GPS',
                              style: const TextStyle(
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

                      // Marcador y Radar
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
                                    (100 * (1.6 - _pulseAnimation.value))
                                        .clamp(0, 100)
                                        .toInt(),
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

                // 4. Barra Superior Interactiva de Dirección / Búsqueda
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
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
                          child: TextField(
                            controller: _addressController,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Ingresa dirección o arrastra el mapa...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                            onChanged: (val) {
                              setState(() {
                                _isCustomLocation = true;
                              });
                            },
                          ),
                        ),
                        if (_isCustomLocation)
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: AppColors.textSecondary),
                            onPressed: _resetToGpsLocation,
                            tooltip: 'Restablecer GPS',
                          ),
                      ],
                    ),
                  ),
                ),

                // 5. Controles de Zoom (+ y -) + Botón Mi Ubicación GPS
                Positioned(
                  right: 16,
                  top: 76,
                  child: Column(
                    children: [
                      // Botón Mi Ubicación GPS
                      if (_isCustomLocation) ...[
                        FloatingActionButton.small(
                          heroTag: 'my_gps_location',
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          onPressed: _resetToGpsLocation,
                          tooltip: 'Volver a Mi Ubicación GPS',
                          child: const Icon(Icons.my_location_rounded, size: 18),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Controles de Zoom
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                if (_zoomLevel < 18) {
                                  setState(() {
                                    _zoomLevel++;
                                  });
                                }
                              },
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 20,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            InkWell(
                              onTap: () {
                                if (_zoomLevel > 10) {
                                  setState(() {
                                    _zoomLevel--;
                                  });
                                }
                              },
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(10),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Icon(
                                  Icons.remove_rounded,
                                  size: 20,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
