import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_tna_app/core/exceptions/failures.dart';
import 'package:global_tna_app/features/auth/domain/entities/user.dart';
import 'package:global_tna_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:global_tna_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:global_tna_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:global_tna_app/features/auth/presentation/bloc/auth_state.dart';

class _FakeAuthRepository implements AuthRepository {
  Either<Failure, User> loginResult = const Right(
    User(id: '1', email: 'a@b.com'),
  );
  Either<Failure, User> signupResult = const Right(
    User(id: '1', email: 'a@b.com'),
  );
  Either<Failure, User> currentUserResult = const Right(
    User(id: '1', email: 'a@b.com'),
  );
  bool loggedIn = false;

  @override
  Future<Either<Failure, User>> getCurrentUser() async => currentUserResult;

  @override
  Future<bool> isLoggedIn() async => loggedIn;

  @override
  Future<Either<Failure, User>> login(String email, String password) async =>
      loginResult;

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);

  @override
  Future<Either<Failure, User>> signup(String email, String password) async =>
      signupResult;
}

void main() {
  group('AuthBloc', () {
    late AuthBloc bloc;
    late _FakeAuthRepository repo;

    setUp(() {
      repo = _FakeAuthRepository();
      bloc = AuthBloc(authRepository: repo);
    });

    tearDown(() async {
      await bloc.close();
    });

    test('emits [AuthLoading, Authenticated] on successful login', () async {
      repo.loginResult = const Right(User(id: '42', email: 'user@example.com'));

      bloc.add(
        const LoginEvent(email: 'user@example.com', password: 'Password123!'),
      );

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>(
            (state) =>
                state is Authenticated &&
                state.user.email == 'user@example.com',
          ),
        ]),
      );
    });

    test('emits [AuthLoading, AuthError] on failed signup', () async {
      repo.signupResult = const Left(ServerFailure('Validation failed'));

      bloc.add(const SignupEvent(email: 'bad', password: '1234'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          predicate<AuthState>(
            (state) =>
                state is AuthError && state.message == 'Validation failed',
          ),
        ]),
      );
    });
  });
}
