import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/booking.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';

class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingBloc>()..add(LoadBookingsEvent()),
      child: const _BookingsView(),
    );
  }
}

class _BookingsView extends StatelessWidget {
  const _BookingsView();

  (Color, IconData) _statusStyle(String raw) {
    switch (raw.toLowerCase()) {
      case 'confirmed':
        return (Colors.green, Icons.check_circle_outline);
      case 'completed':
        return (Colors.blue, Icons.verified_outlined);
      case 'cancelled':
        return (Colors.red, Icons.cancel_outlined);
      case 'failed':
        return (Colors.redAccent, Icons.error_outline);
      case 'pending':
      default:
        return (Colors.orange, Icons.schedule_outlined);
    }
  }

  String _dateLabel(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _confirmCancel(BuildContext context, String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text(
            'Are you sure you want to cancel this booking? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cancel Booking'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) return;
    context.read<BookingBloc>().add(CancelBookingEvent(bookingId));
  }

  Widget _bookingCard(BuildContext context, BookingEntity booking) {
    final status = _statusStyle(booking.status);
    final payment = _statusStyle(booking.paymentStatus);
    final canCancel = booking.status.toLowerCase() == 'pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/bookings/${booking.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Booking #${booking.id.substring(0, booking.id.length < 8 ? booking.id.length : 8).toUpperCase()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'LKR ${booking.totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Created ${_dateLabel(booking.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    label: booking.status.toUpperCase(),
                    foreground: status.$1,
                    icon: status.$2,
                  ),
                  StatusChip(
                    label: booking.paymentStatus.toUpperCase(),
                    foreground: payment.$1,
                    icon: payment.$2,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${booking.items.length} item(s)',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (canCancel) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _confirmCancel(context, booking.id),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text(
                    'Cancel Booking',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Unauthenticated) {
              context.go('/login');
            }
          },
        ),
        BlocListener<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is BookingError) {
              AppSnackbar.show(
                context,
                message: state.message,
                type: AppSnackType.error,
              );
            }
          },
        ),
      ],
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
            }
            if (state is BookingError) {
              return ErrorStateView(
                message: state.message,
                onRetry: () {
                  context.read<BookingBloc>().add(LoadBookingsEvent());
                },
              );
            }
            if (state is! BookingsLoaded) {
              return const BookingsListSkeleton();
            }
            final bookings = state.bookings;
            if (bookings.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<BookingBloc>().add(LoadBookingsEvent());
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 100),
                    EmptyStateView(
                      title: 'No bookings yet',
                      message: 'Complete your first booking to see it here.',
                      icon: Icons.event_busy_outlined,
                    ),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BookingBloc>().add(LoadBookingsEvent());
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (context, index) =>
                    _bookingCard(context, bookings[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}
