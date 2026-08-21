import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../blocs/location/location_bloc.dart';
import '../../blocs/location/location_event.dart';
import '../../blocs/location/location_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocationBloc()..add(LoadLocationRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Solicitar Servicio'),
          centerTitle: true,
        ),
        body: BlocBuilder<LocationBloc, LocationState>(
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

              return Stack(
                children: [
                  GoogleMap(
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
                  Positioned(
                    bottom: 24.0,
                    left: 24.0,
                    right: 24.0,
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              elevation: 4,
                            ),
                            onPressed: () {
                              // Imprimimos en consola las coordenadas según la restricción temporal
                              debugPrint('--- SOLICITAR SERVICIO AQUÍ ---');
                              debugPrint('Latitud: ${state.latitude}');
                              debugPrint('Longitud: ${state.longitude}');
                              debugPrint('--------------------------------');
                            },
                            child: const Text(
                              'Solicitar Servicio Aquí',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return const Center(child: Text('Inicializando ubicación...'));
          },
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
