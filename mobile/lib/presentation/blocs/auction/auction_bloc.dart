import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'auction_event.dart';
import 'auction_state.dart';

class AuctionBloc extends Bloc<AuctionEvent, AuctionState> {
  final Dio _dio;

  AuctionBloc({Dio? dio})
      : _dio = dio ?? apiClient,
        super(AuctionInitial()) {
    on<BroadcastRequested>(_onBroadcastRequested);
  }

  Future<void> _onBroadcastRequested(
    BroadcastRequested event,
    Emitter<AuctionState> emit,
  ) async {
    emit(AuctionLoading());
    try {
      final response = await _dio.post(
        '/api/v1/auctions/broadcast',
        data: {
          'categoriaId': 1, // Categoría hardcodeada por ahora (ej. Plomería)
          'latitud': event.latitude,
          'longitud': event.longitude,
        },
      );

      // Si el servidor retorna 202 Accepted (o 200/201 exitosos)
      if (response.statusCode == 202 || response.statusCode == 200 || response.statusCode == 201) {
        emit(AuctionBroadcastSuccess());
      } else {
        emit(const AuctionFailure('El servidor no pudo procesar la solicitud de subasta.'));
      }
    } on DioException catch (e) {
      String errorMessage = 'Fallo de conexión con el servidor.';
      if (e.response != null) {
        if (e.response!.statusCode == 401) {
          errorMessage = 'Sesión no autorizada. Token de Firebase inválido.';
        } else if (e.response!.statusCode == 403) {
          errorMessage = 'Acceso denegado a la subasta.';
        } else {
          errorMessage = 'Error del servidor: ${e.response!.statusCode}';
        }
      }
      emit(AuctionFailure(errorMessage));
    } catch (e) {
      emit(AuctionFailure('Error inesperado: $e'));
    }
  }
}
