import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/presentation/blocs/auction/auction_bloc.dart';
import 'package:mobile/presentation/blocs/auction/auction_state.dart';

void main() {
  group('AuctionBloc Tests', () {
    test('initial state is AuctionInitial', () {
      final auctionBloc = AuctionBloc();
      expect(auctionBloc.state, isA<AuctionInitial>());
      auctionBloc.close();
    });
  });
}
