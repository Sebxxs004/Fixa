import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../data/datasources/firestore_data_source.dart';
import 'auction_event.dart';
import 'auction_state.dart';

class AuctionBloc extends Bloc<AuctionEvent, AuctionState> {
  final Dio _dio;
  final FirestoreDataSource? _firestoreDataSource;

  AuctionBloc({Dio? dio, FirestoreDataSource? firestoreDataSource})
      : _dio = dio ?? apiClient,
        _firestoreDataSource = firestoreDataSource,
        super(AuctionInitial()) {
    on<BroadcastRequested>(_onBroadcastRequested);
    on<AcceptOfferRequested>(_onAcceptOfferRequested);
  }

  Future<void> _onBroadcastRequested(
    BroadcastRequested event,
    Emitter<AuctionState> emit,
  ) async {
    emit(AuctionLoading());
    try {
      final dataSource = _firestoreDataSource ?? FirestoreDataSource();
      // 1. Crear la sala de subasta en Firestore
      final String subastaId = await dataSource.crearSubasta(
        latitud: event.latitude,
        longitud: event.longitude,
        categoriaId: 1, // Categoría hardcodeada por ahora (ej. Plomería)
      );

      // 2. Notificar al backend sobre la nueva subasta para iniciar el broadcast espacial
      final response = await _dio.post(
        '/api/v1/auctions/broadcast',
        data: {
          'categoriaId': 1,
          'latitud': event.latitude,
          'longitud': event.longitude,
          'subastaId': subastaId, // Inyectamos el ID generado por Firestore
        },
      );

      if (response.statusCode != 202 && response.statusCode != 200 && response.statusCode != 201) {
        emit(const AuctionFailure('El backend rechazó el inicio del broadcast de subasta.'));
        return;
      }

      // Emitir éxito inicial en el broadcast antes de suscribirse al Stream
      emit(AuctionBroadcastSuccess());

      // 3. Conectarse y escuchar la subcolección de ofertas en tiempo real de Firestore
      await emit.forEach<List<Map<String, dynamic>>>(
        dataSource.escucharOfertas(subastaId),
        onData: (ofertas) {
          return AuctionActive(subastaId: subastaId, ofertas: ofertas);
        },
        onError: (error, stackTrace) {
          return AuctionFailure('Fallo en el canal de ofertas de Firestore: $error');
        },
      );

    } on DioException catch (e) {
      String errorMessage = 'Fallo de red al conectar con el backend.';
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          errorMessage = 'Autorización denegada. Token de Firebase inválido.';
        } else {
          errorMessage = 'Error del servidor backend: ${e.response!.statusCode}';
        }
      }
      emit(AuctionFailure(errorMessage));
    } catch (e) {
      emit(AuctionFailure('Error de orquestación de subasta: $e'));
    }
  }

  Future<void> _onAcceptOfferRequested(
    AcceptOfferRequested event,
    Emitter<AuctionState> emit,
  ) async {
    emit(AuctionLoading());
    try {
      final response = await _dio.post(
        '/api/v1/auctions/accept',
        data: {
          'subastaId': event.subastaId,
          'trabajadorId': event.trabajadorId,
          'montoAcordado': event.montoAcordado,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> orden = response.data;
        emit(AuctionOfferAccepted(orden));
      } else {
        emit(const AuctionFailure('No se pudo consolidar la orden con el proveedor seleccionado.'));
      }
    } on DioException catch (e) {
      String errorMessage = 'Fallo de red al aceptar oferta.';
      if (e.response != null) {
        if (e.response!.statusCode == 403) {
          errorMessage = 'No autorizado para aceptar esta oferta.';
        } else {
          errorMessage = 'Error al aceptar oferta: ${e.response!.statusCode}';
        }
      }
      emit(AuctionFailure(errorMessage));
    } catch (e) {
      emit(AuctionFailure('Error inesperado al aceptar oferta: $e'));
    }
  }
}
