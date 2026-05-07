import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:global_tna_app/core/exceptions/failures.dart';
import 'package:global_tna_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:global_tna_app/features/auth/data/models/user_model.dart';
import 'package:global_tna_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  AuthPayload loginPayload = const AuthPayload(
    user: UserModel(id: '1', email: 'user@example.com'),
    token: 'jwt-token',
  );
  AuthPayload signupPayload = const AuthPayload(
    user: UserModel(id: '2', email: 'new@example.com'),
    token: 'signup-token',
  );
  UserModel currentUser = const UserModel(id: '1', email: 'user@example.com');

  @override
  Future<UserModel> getCurrentUser() async => currentUser;

  @override
  Future<AuthPayload> login(String email, String password) async =>
      loginPayload;

  @override
  Future<AuthPayload> signup(String email, String password) async =>
      signupPayload;
}

void main() {
  test('login caches token and returns user', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = AuthRepositoryImpl(
      remoteDataSource: _FakeAuthRemoteDataSource(),
      sharedPreferences: prefs,
    );

    final result = await repo.login('user@example.com', 'Password123!');
    final cachedToken = prefs.getString(AuthRepositoryImpl.cachedTokenKey);

    expect(result.isRight(), isTrue);
    expect(cachedToken, 'jwt-token');
  });

  test('logout clears auth and cart cache keys', () async {
    SharedPreferences.setMockInitialValues({
      AuthRepositoryImpl.cachedTokenKey: 'abc',
      'cached_cart_v1': '{"id":"1","items":[],"runningTotal":0}',
    });
    final prefs = await SharedPreferences.getInstance();
    final repo = AuthRepositoryImpl(
      remoteDataSource: _FakeAuthRemoteDataSource(),
      sharedPreferences: prefs,
    );

    final result = await repo.logout();

    expect(result, const Right<Failure, void>(null));
    expect(prefs.getString(AuthRepositoryImpl.cachedTokenKey), isNull);
    expect(prefs.getString('cached_cart_v1'), isNull);
  });
}
