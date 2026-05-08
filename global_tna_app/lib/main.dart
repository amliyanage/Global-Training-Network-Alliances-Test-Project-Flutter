import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/services/presentation/pages/services_page.dart';
import 'features/services/presentation/pages/service_detail_page.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/bookings/presentation/pages/bookings_page.dart';
import 'features/bookings/presentation/pages/booking_detail_page.dart';
import 'features/bookings/presentation/pages/checkout_page.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const GlobalTNAApp());
}

class GlobalTNAApp extends StatelessWidget {
  const GlobalTNAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppBootstrap();
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late final AuthBloc _authBloc;
  late final GoRouter _router;

  bool _isAuthRoute(String location) {
    return location == '/login' || location == '/register';
  }

  bool _isProtectedRoute(String location) {
    return location == '/services' ||
        location.startsWith('/services/') ||
        location == '/cart' ||
        location == '/bookings' ||
        location.startsWith('/bookings/') ||
        location == '/checkout';
  }

  @override
  void initState() {
    super.initState();
    _authBloc = di.sl<AuthBloc>()..add(CheckAuthStatus());
    _router = GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(_authBloc.stream),
      redirect: (context, state) {
        final location = state.matchedLocation;
        final authState = _authBloc.state;
        final isAuthenticated = authState is Authenticated;
        final isBootstrapping =
            authState is AuthLoading || authState is AuthInitial;

        if (isBootstrapping) return null;
        if (!isAuthenticated && _isProtectedRoute(location)) return '/login';
        if (isAuthenticated && _isAuthRoute(location)) return '/services';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/services',
          builder: (context, state) => const ServicesPage(),
        ),
        GoRoute(
          path: '/services/:id',
          builder: (context, state) =>
              ServiceDetailPage(serviceId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
        GoRoute(
          path: '/bookings',
          builder: (context, state) => const BookingsPage(),
        ),
        GoRoute(
          path: '/bookings/:id',
          builder: (context, state) =>
              BookingDetailPage(bookingId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const CheckoutPage(),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: 'MenteCart',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
