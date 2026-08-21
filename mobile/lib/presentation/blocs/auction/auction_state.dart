import 'package:equatable/equatable.dart';

abstract class AuctionState extends Equatable {
  const AuctionState();

  @override
  List<Object?> get props => [];
}

class AuctionInitial extends AuctionState {}

class AuctionLoading extends AuctionState {}

class AuctionBroadcastSuccess extends AuctionState {}

class AuctionFailure extends AuctionState {
  final String message;

  const AuctionFailure(this.message);

  @override
  List<Object?> get props => [message];
}
