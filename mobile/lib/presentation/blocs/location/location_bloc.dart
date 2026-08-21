import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc() : super(LocationInitial()) {
    on<LoadLocationRequested>(_onLoadLocationRequested);
  }

  Future<void> _onLoadLocationRequested(
    LoadLocationRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());
    try {
      // 1. Verificar y solicitar permisos usando permission_handler
      PermissionStatus status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }

      if (status.isPermanentlyDenied) {
        emit(const LocationError('El permiso de ubicación está permanentemente denegado en los ajustes.'));
        return;
      }

      if (!status.isGranted) {
        emit(const LocationError('Permiso de ubicación denegado por el usuario.'));
        return;
      }

      // 2. Verificar si el servicio GPS de ubicación está activo en el dispositivo
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(const LocationError('El servicio GPS de ubicación está desactivado en el dispositivo.'));
        return;
      }

      // 3. Obtener la posición actual
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      emit(LocationLoaded(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (e) {
      emit(LocationError('Error al obtener la ubicación: $e'));
    }
  }
}
