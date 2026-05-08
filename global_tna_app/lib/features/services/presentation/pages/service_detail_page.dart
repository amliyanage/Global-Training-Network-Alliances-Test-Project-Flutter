import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../injection_container.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../domain/entities/service.dart';
import '../../domain/entities/service_slot.dart';
import '../bloc/services_bloc.dart';
import '../bloc/services_event.dart';
import '../bloc/services_state.dart';

class ServiceDetailPage extends StatelessWidget {
  final String serviceId;

  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ServicesBloc>()
            ..add(
              FetchServiceDetailEvent(
                serviceId,
                bookingDate: _ServiceDetailViewState.apiDate(
                  DateTime.now().add(const Duration(days: 1)),
                ),
              ),
            ),
        ),
        BlocProvider(create: (_) => sl<CartBloc>()),
      ],
      child: _ServiceDetailView(serviceId: serviceId),
    );
  }
}

class _ServiceDetailView extends StatefulWidget {
  final String serviceId;

  const _ServiceDetailView({required this.serviceId});

  @override
  State<_ServiceDetailView> createState() => _ServiceDetailViewState();
}

class _ServiceDetailViewState extends State<_ServiceDetailView> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlotId;
  int _quantity = 1;

  static String apiDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _friendlyDate(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[value.weekday - 1]}, ${months[value.month - 1]} ${value.day}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;
    if (_sameDay(_selectedDate, picked)) return;
    if (!mounted) return;

    setState(() {
      _selectedDate = picked;
      _selectedSlotId = null;
      _quantity = 1;
    });
    context.read<ServicesBloc>().add(
      FetchServiceDetailEvent(
        widget.serviceId,
        bookingDate: apiDate(_selectedDate),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<ServiceSlotEntity> _sortedSlots(ServiceEntity service) {
    final slots = [...service.slots];
    slots.sort((a, b) => a.startTime.compareTo(b.startTime));
    return slots;
  }

  String _slotLabel(ServiceSlotEntity slot) {
    final local = slot.startTime.toLocal();
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $suffix';
  }

  int _maxQuantity(ServiceEntity service, ServiceSlotEntity? selectedSlot) {
    final slotAvailable = selectedSlot?.available ?? 0;
    if (slotAvailable > 0 && service.capacity > 0) {
      return slotAvailable < service.capacity
          ? slotAvailable
          : service.capacity;
    }
    if (slotAvailable > 0) return slotAvailable;
    if (service.capacity > 0) return service.capacity;
    return 20;
  }

  void _syncQuantity(ServiceEntity service, ServiceSlotEntity? selectedSlot) {
    final max = _maxQuantity(service, selectedSlot);
    if (_quantity > max) _quantity = max;
    if (_quantity < 1) _quantity = 1;
  }

  void _addToCart(ServiceEntity service, ServiceSlotEntity? selectedSlot) {
    if (selectedSlot == null) {
      AppSnackbar.show(
        context,
        message: 'Please select an available time slot',
        type: AppSnackType.error,
      );
      return;
    }
    if (selectedSlot.isFull) {
      AppSnackbar.show(
        context,
        message: 'Selected slot is already full. Choose another slot.',
        type: AppSnackType.error,
      );
      return;
    }
    context.read<CartBloc>().add(
      AddCartItemEvent(
        service.id,
        selectedSlot.id,
        apiDate(_selectedDate),
        _quantity,
      ),
    );
  }

  Widget _buildCapacityPill(ServiceSlotEntity slot) {
    final available = slot.available;
    final isFull = slot.isFull;
    final color = isFull ? Colors.red : Colors.green;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isFull ? 'Full' : '$available seats left',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<CartBloc, CartState>(
          listener: (context, state) {
            if (state is CartLoaded) {
              AppSnackbar.show(
                context,
                message: 'Added to cart',
                type: AppSnackType.success,
              );
            } else if (state is CartError) {
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
          title: const Text('Service Details'),
          actions: [
            IconButton(
              tooltip: 'Cart',
              onPressed: () => context.push('/cart'),
              icon: const Icon(Icons.shopping_cart_outlined),
            ),
          ],
        ),
        body: BlocBuilder<ServicesBloc, ServicesState>(
          builder: (context, state) {
            if (state is ServicesLoading || state is ServicesInitial) {
              return const ServicesListSkeleton(itemCount: 1);
            }
            if (state is ServicesError) {
              return ErrorStateView(
                message: state.message,
                onRetry: () {
                  context.read<ServicesBloc>().add(
                    FetchServiceDetailEvent(
                      widget.serviceId,
                      bookingDate: apiDate(_selectedDate),
                    ),
                  );
                },
              );
            }
            if (state is! ServiceDetailLoaded) {
              return const EmptyStateView(
                title: 'No service found',
                message: 'Unable to load this service right now.',
              );
            }

            final service = state.service;
            final slots = _sortedSlots(service);
            ServiceSlotEntity? selectedSlot;
            for (final slot in slots) {
              if (slot.id == _selectedSlotId) {
                selectedSlot = slot;
                break;
              }
            }
            if (_selectedSlotId == null && slots.isNotEmpty) {
              final firstAvailable = slots.firstWhere(
                (slot) => !slot.isFull,
                orElse: () => slots.first,
              );
              _selectedSlotId = firstAvailable.id;
              selectedSlot = firstAvailable;
            }
            _syncQuantity(service, selectedSlot);
            final maxQuantity = _maxQuantity(service, selectedSlot);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ServicesBloc>().add(
                  FetchServiceDetailEvent(
                    widget.serviceId,
                    bookingDate: apiDate(_selectedDate),
                  ),
                );
              },
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: service.image.trim().isEmpty
                        ? Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 42,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Image.network(
                            service.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stackTrace) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 42,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(service.category)),
                            Chip(label: Text('${service.duration} min')),
                            Chip(
                              label: Text(
                                'LKR ${service.price.toStringAsFixed(0)}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          service.description.isEmpty
                              ? 'No description provided.'
                              : service.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Select Date',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.event_outlined),
                            label: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${_friendlyDate(_selectedDate)} (${apiDate(_selectedDate)})',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Available Time Slots',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (slots.isEmpty)
                          const EmptyStateView(
                            title: 'No slots available',
                            message:
                                'Try another date to view available times.',
                            icon: Icons.schedule_outlined,
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: slots.map((slot) {
                              final isSelected = _selectedSlotId == slot.id;
                              final isFull = slot.isFull;
                              return SizedBox(
                                width: 150,
                                child: InkWell(
                                  onTap: isFull
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedSlotId = slot.id;
                                            _syncQuantity(service, slot);
                                          });
                                        },
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: isSelected
                                          ? theme.colorScheme.primary.withAlpha(
                                              26,
                                            )
                                          : theme.colorScheme.surface,
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _slotLabel(slot),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: isFull
                                                    ? theme
                                                          .colorScheme
                                                          .onSurfaceVariant
                                                    : null,
                                              ),
                                        ),
                                        _buildCapacityPill(slot),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 18),
                        Text(
                          'Quantity',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$_quantity',
                              style: theme.textTheme.titleMedium,
                            ),
                            IconButton(
                              onPressed: _quantity < maxQuantity
                                  ? () => setState(() => _quantity++)
                                  : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const Spacer(),
                            Text(
                              'Max $maxQuantity',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: BlocBuilder<CartBloc, CartState>(
                            builder: (context, cartState) {
                              final isSubmitting = cartState is CartLoading;
                              return ElevatedButton.icon(
                                onPressed: isSubmitting
                                    ? null
                                    : () => _addToCart(service, selectedSlot),
                                icon: isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.add_shopping_cart_outlined,
                                      ),
                                label: Text(
                                  isSubmitting
                                      ? 'Adding...'
                                      : 'Add to Cart • LKR ${(service.price * _quantity).toStringAsFixed(0)}',
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
