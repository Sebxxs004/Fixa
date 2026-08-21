import 'package:equatable/equatable.dart';

abstract class AuctionEvent extends Equatable {
  const AuctionEvent();

  @override
  List<Object?> get props => [];
}

class BroadcastRequested extends AuctionEvent {
  final double latitude;
  final double longitude;

  const BroadcastRequested({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}
