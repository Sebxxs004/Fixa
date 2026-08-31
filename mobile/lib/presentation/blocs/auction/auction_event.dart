import 'package:equatable/equatable.dart';

abstract class AuctionEvent extends Equatable {
  const AuctionEvent();

  @override
  List<Object?> get props => [];
}

class BroadcastRequested extends AuctionEvent {
  final double latitude;
  final double longitude;
  final int categoriaId;
  final String categoriaNombre;
  final String descripcion;
  final List<String> fotos;

  const BroadcastRequested({
    required this.latitude,
    required this.longitude,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.descripcion,
    this.fotos = const [],
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        categoriaId,
        categoriaNombre,
        descripcion,
        fotos,
      ];
}

class AcceptOfferRequested extends AuctionEvent {
  final String subastaId;
  final String trabajadorId;
  final double montoAcordado;

  const AcceptOfferRequested({
    required this.subastaId,
    required this.trabajadorId,
    required this.montoAcordado,
  });

  @override
  List<Object?> get props => [subastaId, trabajadorId, montoAcordado];
}
