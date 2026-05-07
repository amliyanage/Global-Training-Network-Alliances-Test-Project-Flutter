import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/dio_client.dart';
import 'core/services/environment_service.dart';

import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/services/domain/repositories/service_repository.dart';
import 'features/services/data/repositories/service_repository_impl.dart';
import 'features/services/data/datasources/service_remote_data_source.dart';
import 'features/services/presentation/bloc/services_bloc.dart';

import 'features/cart/domain/repositories/cart_repository.dart';
import 'features/cart/data/repositories/cart_repository_impl.dart';
import 'features/cart/data/datasources/cart_remote_data_source.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';

import 'features/bookings/domain/repositories/booking_repository.dart';
import 'features/bookings/data/repositories/booking_repository_impl.dart';
import 'features/bookings/data/datasources/booking_remote_data_source.dart';
import 'features/bookings/presentation/bloc/booking_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {

  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => const EnvironmentService());
  sl.registerLazySingleton(() => DioClient(sharedPreferences: sl()));

  sl.registerFactory(() => AuthBloc(authRepository: sl()));

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), sharedPreferences: sl()),
  );

  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerFactory(() => ServicesBloc(repository: sl()));

  sl.registerLazySingleton<ServiceRepository>(
    () => ServiceRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<ServiceRemoteDataSource>(
    () => ServiceRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerFactory(() => CartBloc(repository: sl(), sharedPreferences: sl()));

  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerFactory(() => BookingBloc(repository: sl()));

  sl.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(dioClient: sl()),
  );
}
