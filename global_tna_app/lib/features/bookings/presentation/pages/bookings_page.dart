import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../injection_container.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<BookingBloc>()..add(LoadBookingsEvent()),
        ),
        BlocProvider(create: (_) => sl<AuthBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            context.go('/login');
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('My Bookings'),
            actions: [
              IconButton(
                tooltip: 'Services',
                icon: const Icon(Icons.home_repair_service_outlined),
                onPressed: () => context.go('/services'),
              ),
              IconButton(
                tooltip: 'Cart',
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => context.go('/cart'),
              ),
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(LogoutEvent());
                },
              ),
            ],
          ),
          body: BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              if (state is BookingLoading || state is BookingInitial) {
                return const BookingsListSkeleton();
              } else if (state is BookingError) {
                return Center(child: Text(state.message));
              } else if (state is BookingsLoaded) {
                final bookings = state.bookings;
                if (bookings.isEmpty) {
                  return const Center(child: Text('You have no bookings'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];

                    Color statusColor;
                    IconData statusIcon;
                    switch (booking.status.toLowerCase()) {
                      case 'confirmed':
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle;
                        break;
                      case 'cancelled':
                        statusColor = Colors.red;
                        statusIcon = Icons.cancel;
                        break;
                      case 'pending':
                      default:
                        statusColor = Colors.orange;
                        statusIcon = Icons.schedule;
                        break;
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Booking #${booking.id.substring(0, 8).toUpperCase()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'LKR ${booking.totalAmount.toStringAsFixed(2)}',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Status',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(26),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            statusIcon,
                                            size: 14,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            booking.status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Payment',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      booking.paymentStatus.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (booking.status == 'pending') ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    'Cancel Booking',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () {
                                    context.read<BookingBloc>().add(
                                      CancelBookingEvent(booking.id),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const BookingsListSkeleton();
            },
          ),
        ),
      ),
    );
  }
}
