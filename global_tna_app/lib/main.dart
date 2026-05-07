import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/services/presentation/pages/services_page.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/bookings/presentation/pages/bookings_page.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(CheckAuthStatus()),
        ),
      ],
      child: MaterialApp.router(
        title: 'GlobalTNA Booking',
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/services',
      builder: (context, state) => const ServicesPage(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartPage(),
    ),
    GoRoute(
      path: '/bookings',
      builder: (context, state) => const BookingsPage(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutPage(),
    ),
  ],
);
