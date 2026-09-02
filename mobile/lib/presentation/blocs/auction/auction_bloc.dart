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
    on<OfferSubmittedRequested>(_onOfferSubmittedRequested);
    on<AcceptOfferRequested>(_onAcceptOfferRequested);
  }

  Future<void> _onBroadcastRequested(
    BroadcastRequested event,
    Emitter<AuctionState> emit,
  ) async {
    emit(AuctionLoading());
    try {
      final dataSource = _firestoreDataSource ?? FirestoreDataSource();

      // 1. Crear la sala de subasta en Firestore con categoría, descripción y evidencia fotográfica
      final String subastaId = await dataSource.crearSubasta(
        latitud: event.latitude,
        longitud: event.longitude,
        categoriaId: event.categoriaId,
        categoriaNombre: event.categoriaNombre,
        descripcion: event.descripcion,
        fotos: event.fotos,
      );

      // 2. Notificar al backend HTTP únicamente si el servidor Spring Boot está activo
      final bool enableHttpBackend =
          bool.fromEnvironment('ENABLE_HTTP_BACKEND', defaultValue: false);
      if (enableHttpBackend) {
        try {
          await _dio.post(
            '/api/v1/auctions/broadcast',
            data: {
              'categoriaId': event.categoriaId,
              'categoriaNombre': event.categoriaNombre,
              'descripcion': event.descripcion,
              'fotos': event.fotos,
              'latitud': event.latitude,
              'longitud': event.longitude,
              'subastaId': subastaId,
            },
          );
        } catch (_) {
          // En entorno local o sin backend HTTP activo, continuar con Firestore directo
        }
      }

      // Emitir inmediatamente AuctionActive para cambiar la UI del Cliente al instante
      emit(
        AuctionActive(
          subastaId: subastaId,
          categoriaId: event.categoriaId,
          categoriaNombre: event.categoriaNombre,
          descripcion: event.descripcion,
          fotos: event.fotos,
          ofertas: const [],
        ),
      );

      // 3. Conectarse y escuchar la subcolección de ofertas en tiempo real de Firestore
      await emit.forEach<List<Map<String, dynamic>>>(
        dataSource.escucharOfertas(subastaId),
        onData: (ofertas) {
          return AuctionActive(
            subastaId: subastaId,
            categoriaId: event.categoriaId,
            categoriaNombre: event.categoriaNombre,
            descripcion: event.descripcion,
            fotos: event.fotos,
            ofertas: ofertas,
          );
        },
        onError: (error, stackTrace) {
          return AuctionFailure(
              'Fallo en el canal de ofertas de Firestore: $error');
        },
      );
    } catch (e) {
      emit(AuctionFailure('Fallo al transmitir la subasta: ${e.toString()}'));
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data =
            response.data is Map<String, dynamic>
                ? response.data as Map<String, dynamic>
                : <String, dynamic>{
                    'subastaId': event.subastaId,
                    'trabajadorId': event.trabajadorId,
                    'montoAcordado': event.montoAcordado,
                  };
        emit(AuctionOfferAccepted(data));
      } else {
        emit(const AuctionFailure('El backend no pudo confirmar el contrato.'));
      }
    } catch (e) {
      emit(AuctionFailure('Error al aceptar oferta: ${e.toString()}'));
    }
  }

  Future<void> _onOfferSubmittedRequested(
    OfferSubmittedRequested event,
    Emitter<AuctionState> emit,
  ) async {
    try {
      final dataSource = _firestoreDataSource ?? FirestoreDataSource();
      await dataSource.crearOferta(
        subastaId: event.subastaId,
        trabajadorId: event.trabajadorId,
        nombreTrabajador: event.nombreTrabajador,
        precio: event.precio,
      );
    } catch (e) {
      emit(AuctionFailure('Fallo al enviar oferta: ${e.toString()}'));
    }
  }
}
