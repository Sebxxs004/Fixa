import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_event.dart';
import '../../blocs/location/location_state.dart';
import '../../blocs/auction/auction_bloc.dart';
import '../../blocs/auction/auction_event.dart';
import '../../blocs/auction/auction_state.dart';
import '../../widgets/offer_card.dart';
import '../../widgets/service_request_sheet.dart';
import '../../widgets/web_map_widget.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  double? _selectedLat;
  double? _selectedLng;

  bool _isWorkerMode = false;
  String _workerCategory = 'Plomería';
  final TextEditingController _offerPriceController = TextEditingController();

  @override
  void dispose() {
    _mapController?.dispose();
    _offerPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LocationBloc>(
          create: (context) => LocationBloc()..add(LoadLocationRequested()),
        ),
        BlocProvider<AuctionBloc>(
          create: (context) => AuctionBloc(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChoiceChip(
                label: const Text('Cliente'),
                selected: !_isWorkerMode,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: !_isWorkerMode ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  if (val) setState(() => _isWorkerMode = false);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Trabajador'),
                selected: _isWorkerMode,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _isWorkerMode ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                onSelected: (val) {
                  if (val) setState(() => _isWorkerMode = true);
                },
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline_rounded, size: 22),
              tooltip: 'Mi Perfil',
              onPressed: () {
                context.push('/profile');
              },
            ),
          ],
        ),
        body: BlocListener<AuctionBloc, AuctionState>(
          listener: (context, auctionState) {
            if (auctionState is AuctionLoading) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Procesando solicitud de subasta...'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
            } else if (auctionState is AuctionBroadcastSuccess) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Buscando profesionales cercanos...'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
            } else if (auctionState is AuctionOfferAccepted) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('¡Servicio aceptado! El profesional va en camino.'),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
            }
          },
          child: BlocBuilder<LocationBloc, LocationState>(
            builder: (context, state) {
              if (state is LocationLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 16),
                      Text('Obteniendo tu ubicación actual...'),
                    ],
                  ),
                );
              }

              if (state is LocationError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_off_rounded,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context
                                .read<LocationBloc>()
                                .add(LoadLocationRequested());
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is LocationLoaded) {
                final LatLng currentLatLng = LatLng(state.latitude, state.longitude);
                final CameraPosition initialCamera = CameraPosition(
                  target: currentLatLng,
                  zoom: 16.0,
                );

                return BlocBuilder<AuctionBloc, AuctionState>(
                  builder: (context, auctionState) {
                    final bool isAuctionActive = auctionState is AuctionActive;

                    return Column(
                      children: [
                        // Mapa: Ocupa mitad superior o pantalla completa
                        Expanded(
                          flex: isAuctionActive ? 1 : 2,
                          child: Stack(
                            children: [
                              kIsWeb
                                  ? WebMapWidget(
                                      latitude: state.latitude,
                                      longitude: state.longitude,
                                      onLocationChanged: (lat, lng) {
                                        _selectedLat = lat;
                                        _selectedLng = lng;
                                      },
                                    )
                                  : GoogleMap(
                                      initialCameraPosition: initialCamera,
                                      myLocationEnabled: true,
                                      myLocationButtonEnabled: false,
                                      zoomControlsEnabled: false,
                                      onMapCreated: (controller) {
                                        _mapController = controller;
                                      },
                                      markers: {
                                        Marker(
                                          markerId: const MarkerId('current_location'),
                                          position: currentLatLng,
                                          infoWindow: const InfoWindow(title: 'Tu Ubicación Actual'),
                                        ),
                                      },
                                    ),
                              // Botón de solicitar servicio (Solo en Modo Cliente y si no hay subasta activa)
                              if (!isAuctionActive && !_isWorkerMode)
                                Positioned(
                                  bottom: 24.0,
                                  left: 24.0,
                                  right: 24.0,
                                  child: SafeArea(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        elevation: 4,
                                      ),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (sheetContext) => ServiceRequestSheet(
                                            onSubmit: ({
                                              required int categoriaId,
                                              required String categoriaNombre,
                                              required String descripcion,
                                              required List<String> fotos,
                                            }) {
                                              context.read<AuctionBloc>().add(
                                                    BroadcastRequested(
                                                      latitude: _selectedLat ?? state.latitude,
                                                      longitude: _selectedLng ?? state.longitude,
                                                      categoriaId: categoriaId,
                                                      categoriaNombre: categoriaNombre,
                                                      descripcion: descripcion,
                                                      fotos: fotos,
                                                    ),
                                                  );
                                            },
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Solicitar Servicio Aquí',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // MODO TRABAJADOR vs MODO CLIENTE
                        if (_isWorkerMode) ...[
                          // PANEL DEL TRABAJADOR CON FILTRADO POR RUBRO
                          Expanded(
                            flex: 1,
                            child: _buildWorkerAlertPanel(context, auctionState),
                          ),
                        ] else ...[
                          // MODO CLIENTE: Listado de ofertas recibidas cuando la subasta está activa
                          if (isAuctionActive)
                            Expanded(
                              flex: 1,
                              child: Container(
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                        horizontal: 16.0,
                                      ),
                                      color: Colors.grey[100],
                                      child: const Text(
                                        'Esperando cotizaciones...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: auctionState.ofertas.length,
                                        itemBuilder: (context, index) {
                                          final oferta = auctionState.ofertas[index];
                                          return OfferCard(
                                            oferta: oferta,
                                            onAccept: () {
                                              context.read<AuctionBloc>().add(
                                                    AcceptOfferRequested(
                                                      subastaId: auctionState.subastaId,
                                                      trabajadorId: oferta['trabajador_id'] ?? '',
                                                      montoAcordado: (oferta['precio'] is num)
                                                          ? (oferta['precio'] as num).toDouble()
                                                          : double.parse(oferta['precio']?.toString() ?? '0.0'),
                                                    ),
                                                  );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                );
              }

              return const Center(child: Text('Inicializando ubicación...'));
            },
          ),
        ),
      ),
    );
  }

  // WIDGET DEL PANEL DE TRABAJADOR CON FILTRADO POR RUBRO COINCIDENCIAL
  Widget _buildWorkerAlertPanel(BuildContext context, AuctionState auctionState) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector / Badge del Rubro Actual del Trabajador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.handyman_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Mi Rubro: $_workerCategory',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                initialValue: _workerCategory,
                tooltip: 'Cambiar Rubro de Prueba',
                onSelected: (val) {
                  setState(() {
                    _workerCategory = val;
                  });
                },
                itemBuilder: (context) => [
                  'Plomería',
                  'Electricidad',
                  'Cerrajería',
                  'Pintura',
                  'Carpintería',
                ]
                    .map((cat) => PopupMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                    .toList(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Text('Cambiar',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      Icon(Icons.arrow_drop_down,
                          size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.border),

          // LÓGICA DE FILTRADO POR RUBRO
          Expanded(
            child: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  if (auctionState is AuctionActive) {
                    final String subastaCategoria = auctionState.categoriaNombre;
                    final bool isMatch = subastaCategoria.trim().toLowerCase() ==
                        _workerCategory.trim().toLowerCase();

                    // CASO 1: LA SOLICITUD COINCIDE CON EL RUBRO DEL TRABAJADOR
                    if (isMatch) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(20),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '¡NUEVA ALERTA DE TRABAJO!',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  'Hace un momento',
                                  style: TextStyle(
                                      fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Servicio de ${auctionState.categoriaNombre}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              auctionState.descripcion.isNotEmpty
                                  ? auctionState.descripcion
                                  : 'El cliente solicita servicio sin descripción.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Campo para ingresar cotización / oferta
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _offerPriceController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Tu precio (\$)',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  onPressed: () {
                                    final text = _offerPriceController.text.trim();
                                    final precio = double.tryParse(text) ?? 50000.0;

                                    context.read<AuctionBloc>().add(
                                          OfferSubmittedRequested(
                                            subastaId: auctionState.subastaId,
                                            trabajadorId: 'trabajador_plomero_01',
                                            nombreTrabajador:
                                                'Juan Pérez ($_workerCategory)',
                                            precio: precio,
                                          ),
                                        );

                                    _offerPriceController.clear();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.primary,
                                        behavior: SnackBarBehavior.floating,
                                        content: Text(
                                            'Cotización de \$$precio enviada con éxito.'),
                                      ),
                                    );
                                  },
                                  child: const Text('Enviar Precio'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }

                    // CASO 2: LA SOLICITUD ES DE UN RUBRO DISTINTO (NO MATCH)
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.notifications_paused_outlined,
                              size: 36, color: AppColors.textMuted),
                          const SizedBox(height: 10),
                          Text(
                            'Alerta no correspondiente a tu rubro',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Existe una solicitud activa para "${auctionState.categoriaNombre}". Como tu rubro registrado es "$_workerCategory", esta alerta no te corresponde.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // CASO 3: SIN SUBASTAS ACTIVAS
                  return Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.radar_rounded,
                            size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'Buscando trabajos de $_workerCategory...',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Te notificaremos automáticamente cuando un cliente solicite un servicio en tu rubro.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
