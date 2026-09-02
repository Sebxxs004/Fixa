import 'package:equatable/equatable.dart';

abstract class AuctionState extends Equatable {
  const AuctionState();

  @override
  List<Object?> get props => [];
}

class AuctionInitial extends AuctionState {}

class AuctionLoading extends AuctionState {}

class AuctionBroadcastSuccess extends AuctionState {}

class AuctionActive extends AuctionState {
  final String subastaId;
  final int categoriaId;
  final String categoriaNombre;
  final String descripcion;
  final List<String> fotos;
  final List<Map<String, dynamic>> ofertas;

  const AuctionActive({
    required this.subastaId,
    this.categoriaId = 1,
    this.categoriaNombre = 'Plomería',
    this.descripcion = '',
    this.fotos = const [],
    required this.ofertas,
  });

  @override
  List<Object?> get props => [
        subastaId,
        categoriaId,
        categoriaNombre,
        descripcion,
        fotos,
        ofertas,
      ];
}

class AuctionFailure extends AuctionState {
  final String message;

  const AuctionFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class AuctionOfferAccepted extends AuctionState {
  final Map<String, dynamic> orden;

  const AuctionOfferAccepted(this.orden);

  @override
  List<Object?> get props => [orden];
}
