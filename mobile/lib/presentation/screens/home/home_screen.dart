import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_event.dart';
import '../../blocs/location/location_state.dart';
import 'package:go_router/go_router.dart';
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
          title: const Text('Solicitar Servicio'),
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
            } else if (auctionState is AuctionFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(auctionState.message),
                    backgroundColor: Colors.red,
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
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Buscando señal GPS...'),
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
                        const Icon(Icons.location_off, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<LocationBloc>().add(LoadLocationRequested());
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
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
                              if (!isAuctionActive)
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
                        // Listado inferior de ofertas: Se muestra cuando la subasta está activa
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
