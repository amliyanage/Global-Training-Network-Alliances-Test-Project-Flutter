import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/booking.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';

class BookingDetailPage extends StatelessWidget {
  final String bookingId;

  const BookingDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BookingBloc>()..add(LoadBookingByIdEvent(bookingId)),
      child: _BookingDetailView(bookingId: bookingId),
    );
  }
}

class _BookingDetailView extends StatelessWidget {
  final String bookingId;

  const _BookingDetailView({required this.bookingId});

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

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.year}-$month-$day $hour:$minute';
  }

  List<(String, bool)> _timeline(String status) {
    final normalized = status.toLowerCase();
    final isCancelled = normalized == 'cancelled';
    final isFailed = normalized == 'failed';
    final isPending = normalized == 'pending';
    final isConfirmed = normalized == 'confirmed' || normalized == 'completed';
    final isCompleted = normalized == 'completed';

    return [
      ('Created', true),
      ('Pending Payment', isPending || isConfirmed || isCompleted),
      ('Confirmed', isConfirmed || isCompleted),
      ('Completed', isCompleted),
      ('Cancelled / Failed', isCancelled || isFailed),
    ];
  }

  Widget _buildTimeline(BuildContext context, BookingEntity booking) {
    final theme = Theme.of(context);
    final steps = _timeline(booking.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Timeline',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        ...steps.map((step) {
          final active = step.$2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  active ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: active
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  step.$1,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BookingBloc, BookingState>(
      listener: (context, state) {
        if (state is BookingError) {
          AppSnackbar.show(
            context,
            message: state.message,
            type: AppSnackType.error,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: BlocBuilder<BookingBloc, BookingState>(
          builder: (context, state) {
            if (state is BookingLoading || state is BookingInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is BookingError) {
              return ErrorStateView(
                message: state.message,
                onRetry: () {
                  context.read<BookingBloc>().add(
                    LoadBookingByIdEvent(bookingId),
                  );
                },
              );
            }
            if (state is! BookingDetailLoaded) {
              return const EmptyStateView(
                title: 'Booking not found',
                message: 'We could not load booking details right now.',
              );
            }

            final booking = state.booking;
            final statusStyle = _statusStyle(booking.status);
            final paymentStyle = _statusStyle(booking.paymentStatus);
            final canCancel = booking.status.toLowerCase() == 'pending';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking #${booking.id.substring(0, booking.id.length < 8 ? booking.id.length : 8).toUpperCase()}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Created: ${_formatDate(booking.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            StatusChip(
                              label: booking.status.toUpperCase(),
                              foreground: statusStyle.$1,
                              icon: statusStyle.$2,
                            ),
                            const SizedBox(width: 8),
                            StatusChip(
                              label: booking.paymentStatus.toUpperCase(),
                              foreground: paymentStyle.$1,
                              icon: paymentStyle.$2,
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Total: LKR ${booking.totalAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booked Items',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (booking.items.isEmpty)
                          const Text('No line items in this booking.')
                        else
                          ...booking.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.serviceName} x${item.quantity}',
                                    ),
                                  ),
                                  Text(
                                    'LKR ${(item.price * item.quantity).toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTimeline(context, booking),
                  ),
                ),
                if (canCancel) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<BookingBloc>().add(
                        CancelBookingEvent(booking.id),
                      );
                      context.read<BookingBloc>().add(
                        LoadBookingByIdEvent(booking.id),
                      );
                    },
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
            );
          },
        ),
      ),
    );
  }
}
