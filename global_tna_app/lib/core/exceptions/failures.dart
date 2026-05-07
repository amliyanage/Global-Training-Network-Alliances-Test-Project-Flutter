import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? errorCode;

  const Failure(this.message, [this.errorCode]);

  @override
  List<Object?> get props => [message, errorCode];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.errorCode]);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message, 'NETWORK_ERROR');
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
