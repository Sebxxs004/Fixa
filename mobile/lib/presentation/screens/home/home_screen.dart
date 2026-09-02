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
import '../../../data/datasources/firestore_data_source.dart';

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
  bool _isWorkerRegistered = false;
  String? _workerCategory;
  final TextEditingController _offerPriceController = TextEditingController();

  String _normalizeString(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _offerPriceController.dispose();
    super.dispose();
  }

  void _showWorkerRegistrationModal(BuildContext context) {
    String selectedCategory = 'Plomería';
    final categories = [
      'Plomería',
      'Electricidad',
      'Cerrajería',
      'Pintura',
      'Carpintería',
      'Climatización',
      'Reparación General',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Trabaja con Fixa!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona tu especialidad u oficio para comenzar a recibir solicitudes de servicio en tu zona.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Selecciona tu Oficio o Especialidad:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = cat == selectedCategory;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() {
                          selectedCategory = cat;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _isWorkerRegistered = true;
                    _workerCategory = selectedCategory;
                    _isWorkerMode = true;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      content: Text(
                        '¡Registro completado! Ahora estás registrado como trabajador en $selectedCategory.',
                      ),
                    ),
                  );
                },
                child: const Text('Completar Registro de Trabajador'),
              ),
            ],
          ),
        ),
      ),
    );
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
                          flex: (isAuctionActive || _isWorkerMode) ? 1 : 2,
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
                          // PANEL DEL TRABAJADOR
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

  // WIDGET DEL PANEL DE TRABAJADOR CON VALIDADOR FIRESTORE EN TIEMPO REAL
  Widget _buildWorkerAlertPanel(BuildContext context, AuctionState auctionState) {
    // CASO A: EL USUARIO AÚN NO SE HA REGISTRADO COMO TRABAJADOR
    if (!_isWorkerRegistered || _workerCategory == null) {
      return Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.work_outline_rounded,
                    size: 32,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '¡Aún no estás registrado como trabajador!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Para recibir solicitudes de servicio y enviar cotizaciones en tu zona, primero debes registrar tu especialidad u oficio.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showWorkerRegistrationModal(context),
                  icon: const Icon(Icons.badge_rounded, size: 16),
                  label: const Text(
                    'Registrarme como Trabajador',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // CASO B: EL USUARIO YA ESTÁ REGISTRADO COMO TRABAJADOR
    final activeTrade = _workerCategory!;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badge del Rubro Registrado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.handyman_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Mi Rubro: $activeTrade',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 13, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'Verificado',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.border),

          // LÓGICA DE FILTRADO POR RUBRO EN TIEMPO REAL DESDE FIRESTORE
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreDataSource().escucharSubastasAbiertas(),
                builder: (context, snapshot) {
                  final List<Map<String, dynamic>> subastas =
                      snapshot.data ?? [];

                  if (subastas.isNotEmpty) {
                    final Map<String, dynamic> subastaActiva = subastas.last;
                    final String subastaId = subastaActiva['id'] ?? '';
                    final String subastaCategoria =
                        subastaActiva['categoria_nombre'] ?? 'General';
                    final String descripcion =
                        subastaActiva['descripcion'] ?? '';

                    final bool isMatch = _normalizeString(subastaCategoria) ==
                        _normalizeString(activeTrade);

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
                              'Servicio de $subastaCategoria',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              descripcion.isNotEmpty
                                  ? descripcion
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
                                            subastaId: subastaId,
                                            trabajadorId: 'trabajador_registrado_01',
                                            nombreTrabajador:
                                                'Juan Pérez ($activeTrade)',
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
                          const Text(
                            'Alerta no correspondiente a tu rubro',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Existe una solicitud activa para "$subastaCategoria". Como tu rubro registrado es "$activeTrade", esta alerta no te corresponde.',
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
                          'Buscando trabajos de $activeTrade...',
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
