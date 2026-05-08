import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_tna_app/core/exceptions/failures.dart';
import 'package:global_tna_app/features/auth/domain/entities/user.dart';
import 'package:global_tna_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:global_tna_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:global_tna_app/features/auth/presentation/pages/login_page.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, User>> getCurrentUser() async =>
      const Left(ServerFailure('no'));

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<Either<Failure, User>> login(String email, String password) async =>
      const Left(ServerFailure('no'));

  @override
  Future<Either<Failure, void>> logout() async => const Right(null);

  @override
  Future<Either<Failure, User>> signup(String email, String password) async =>
      const Left(ServerFailure('no'));
}

void main() {
  testWidgets('login page renders sign in form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (_) => AuthBloc(authRepository: _FakeAuthRepository()),
          child: const LoginPage(),
        ),
      ),
    );

    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
