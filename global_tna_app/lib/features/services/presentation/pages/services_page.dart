import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/network/dio_client.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../bloc/services_bloc.dart';
import '../bloc/services_event.dart';
import '../bloc/services_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/service.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<ServicesBloc>()..add(const FetchServicesEvent(limit: 10)),
        ),
        BlocProvider(create: (_) => sl<CartBloc>()),
        BlocProvider(create: (_) => sl<AuthBloc>()),
      ],
      child: const _ServicesView(),
    );
  }
}

class _ServicesView extends StatefulWidget {
  const _ServicesView();

  @override
  State<_ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<_ServicesView> {
  static const int _pageSize = 10;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 280) return;

    final servicesState = context.read<ServicesBloc>().state;
    if (servicesState is! ServicesLoaded) return;
    if (servicesState.isLoadingMore || servicesState.hasReachedMax) return;

    context.read<ServicesBloc>().add(
      FetchServicesEvent(page: servicesState.currentPage + 1, limit: _pageSize),
    );
  }

  void _showAddToCartDialog(BuildContext context, ServiceEntity service) {
    final cartBloc = context.read<CartBloc>();

    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) {
        return _AddToCartDialog(
          service: service,
          onSubmit: (slotId, bookingDate, quantity) {
            cartBloc.add(
              AddCartItemEvent(service.id, slotId, bookingDate, quantity),
            );
          },
        );
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, ServiceEntity service) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          service.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'LKR ${service.price.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${service.duration} min',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.people_outline,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Max ${service.capacity}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddToCartDialog(context, service),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Book'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppSkeleton(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SkeletonBox(height: 16),
                SizedBox(height: 10),
                SkeletonBox(height: 16),
              ],
            ),
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
        BlocListener<CartBloc, CartState>(
          listener: (context, state) {
            if (state is CartLoaded) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Added to cart')));
            } else if (state is CartError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Services'),
          actions: [
            IconButton(
              tooltip: 'Cart',
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => context.go('/cart'),
            ),
            IconButton(
              tooltip: 'Bookings',
              icon: const Icon(Icons.event_note_outlined),
              onPressed: () => context.go('/bookings'),
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
        body: BlocBuilder<ServicesBloc, ServicesState>(
          builder: (context, state) {
            if (state is ServicesLoading) {
              return const ServicesListSkeleton();
            } else if (state is ServicesError) {
              return Center(child: Text(state.message));
            } else if (state is ServicesLoaded) {
              final services = state.services;
              if (services.isEmpty) {
                return const Center(child: Text('No services found'));
              }
              final itemCount = services.length + (state.isLoadingMore ? 1 : 0);

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index >= services.length) {
                    return _buildLoadMoreIndicator();
                  }

                  final service = services[index];
                  return _buildServiceCard(context, service);
                },
              );
            }
            return const ServicesListSkeleton(itemCount: 4);
          },
        ),
      ),
    );
  }
}

class _AddToCartDialog extends StatefulWidget {
  final ServiceEntity service;
  final void Function(String slotId, String bookingDate, int quantity) onSubmit;

  const _AddToCartDialog({required this.service, required this.onSubmit});

  @override
  State<_AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<_AddToCartDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _slotIdController;
  int _quantity = 1;
  bool _isLoadingSlots = true;
  bool _isSubmitting = false;
  String? _slotLoadError;
  List<_ServiceSlot> _slots = const [];
  String? _selectedSlotId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _slotIdController = TextEditingController()
      ..addListener(_onManualSlotChanged);
    _loadSlots();
  }

  @override
  void dispose() {
    _slotIdController.removeListener(_onManualSlotChanged);
    _slotIdController.dispose();
    super.dispose();
  }

  void _onManualSlotChanged() {
    if (_slots.isNotEmpty || !mounted) return;
    setState(() {});
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatFriendlyDate(DateTime date) {
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
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  _ServiceSlot? get _selectedSlot {
    final selectedId = _selectedSlotId;
    if (selectedId == null) return null;
    for (final slot in _slots) {
      if (slot.id == selectedId) return slot;
    }
    return null;
  }

  int get _quantityLimit {
    final slotCapacity = _selectedSlot?.capacity ?? 0;
    final serviceCapacity = widget.service.capacity;

    if (slotCapacity > 0 && serviceCapacity > 0) {
      return slotCapacity < serviceCapacity ? slotCapacity : serviceCapacity;
    }
    if (slotCapacity > 0) return slotCapacity;
    if (serviceCapacity > 0) return serviceCapacity;
    return 20;
  }

  bool get _canSubmit {
    if (_isLoadingSlots || _isSubmitting) return false;
    if (_slots.isNotEmpty) return _selectedSlotId != null;
    return _slotIdController.text.trim().isNotEmpty;
  }

  void _syncQuantityWithinLimit() {
    final limit = _quantityLimit;
    if (_quantity > limit) _quantity = limit;
    if (_quantity < 1) _quantity = 1;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null || _isSameDate(picked, _selectedDate)) return;

    setState(() {
      _selectedDate = picked;
    });
    _loadSlots();
  }

  void _decreaseQuantity() {
    if (_quantity <= 1) return;
    setState(() => _quantity--);
  }

  void _increaseQuantity() {
    final limit = _quantityLimit;
    if (_quantity >= limit) return;
    setState(() => _quantity++);
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _slotLoadError = null;
    });

    try {
      final dateStr = _formatDate(_selectedDate);
      final response = await sl<DioClient>().dio.get(
        '/services/${widget.service.id}',
        queryParameters: {'bookingDate': dateStr},
      );
      final slots = _extractSlots(response.data);

      if (!mounted) return;

      setState(() {
        _slots = slots;
        _isLoadingSlots = false;
        if (slots.isNotEmpty) {
          _selectedSlotId = slots.first.id;
          _slotIdController.text = slots.first.id;
        } else {
          _selectedSlotId = null;
          _slotIdController.clear();
          _slotLoadError =
              'No available slots for this date. Try another date or enter slot ID manually.';
        }
        _syncQuantityWithinLimit();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slots = const [];
        _selectedSlotId = null;
        _isLoadingSlots = false;
        _slotIdController.clear();
        _slotLoadError =
            'Could not load slots right now. Enter slot ID manually or retry.';
        _syncQuantityWithinLimit();
      });
    }
  }

  List<_ServiceSlot> _extractSlots(dynamic responseData) {
    if (responseData is! Map) return const [];

    final root = Map<String, dynamic>.from(responseData);
    final nested = root['data'];
    final dataMap = nested is Map ? Map<String, dynamic>.from(nested) : null;
    final rawSlots = root['slots'] ?? dataMap?['slots'];
    if (rawSlots is! List) return const [];

    final slots = <_ServiceSlot>[];
    for (final raw in rawSlots) {
      final slot = _ServiceSlot.tryParse(raw);
      if (slot != null) {
        slots.add(slot);
      }
    }

    final nowUtc = DateTime.now().toUtc();
    final upcoming =
        slots.where((slot) => slot.startTime.isAfter(nowUtc)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming;
  }

  String _formatSlotLabel(_ServiceSlot slot) {
    final local = slot.startTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour24 = local.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$day/$month ${local.year} at $hour12:$minute $period - ${slot.capacity} seats';
  }

  void _submit() {
    if (!_canSubmit) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final slotId = (_selectedSlotId ?? _slotIdController.text).trim();
    if (slotId.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });
    final dateStr = _formatDate(_selectedDate);
    widget.onSubmit(slotId, dateStr, _quantity);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSlot = _selectedSlot;
    final quantityLimit = _quantityLimit;
    final total = widget.service.price * _quantity;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Book "${widget.service.title}"'),
          const SizedBox(height: 4),
          Text(
            'Choose date, time, and quantity.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Booking date',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
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
                    child: Text(_formatFriendlyDate(_selectedDate)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Requested for ${_formatDate(_selectedDate)}',
                style: theme.textTheme.bodySmall,
              ),
              const Divider(height: 24),
              if (_isLoadingSlots)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Checking available time slots...'),
                      SizedBox(height: 10),
                      SlotsSkeleton(),
                    ],
                  ),
                )
              else if (_slots.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSlotId,
                      decoration: const InputDecoration(
                        labelText: 'Available time slot',
                        helperText: 'Slots are shown in your local time.',
                      ),
                      isExpanded: true,
                      items: _slots
                          .map(
                            (slot) => DropdownMenuItem<String>(
                              value: slot.id,
                              child: Text(
                                _formatSlotLabel(slot),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      validator: (value) {
                        if (_slots.isNotEmpty &&
                            (value == null || value.isEmpty)) {
                          return 'Please select a time slot';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedSlotId = value;
                          _slotIdController.text = value;
                          _syncQuantityWithinLimit();
                        });
                      },
                    ),
                    if (selectedSlot != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Selected slot capacity: ${selectedSlot.capacity}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                )
              else
                TextFormField(
                  controller: _slotIdController,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: 'Slot ID (manual)',
                    helperText:
                        _slotLoadError ??
                        'Enter a valid slot ID from the service slots API.',
                  ),
                  validator: (value) {
                    if (_slots.isNotEmpty) return null;
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a slot ID';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              Text(
                'Quantity',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1 ? _decreaseQuantity : null,
                    tooltip: 'Decrease quantity',
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('$_quantity', style: theme.textTheme.titleMedium),
                  IconButton(
                    onPressed: _quantity < quantityLimit
                        ? _increaseQuantity
                        : null,
                    tooltip: 'Increase quantity',
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  Text('Max $quantityLimit', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Total: LKR ${total.toStringAsFixed(0)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoadingSlots ? null : _loadSlots,
          child: const Text('Reload Slots'),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canSubmit ? _submit : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add to Cart'),
        ),
      ],
    );
  }
}

class _ServiceSlot {
  final String id;
  final DateTime startTime;
  final int capacity;

  const _ServiceSlot({
    required this.id,
    required this.startTime,
    required this.capacity,
  });

  static _ServiceSlot? tryParse(dynamic raw) {
    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    final dynamic rawId = map['_id'] ?? map['id'];
    final dynamic rawStart = map['startTime'] ?? map['start'];
    final dynamic rawCapacity = map['capacity'];

    if (rawId is! String || rawStart is! String) return null;
    final parsed = DateTime.tryParse(rawStart);
    if (parsed == null) return null;

    final capacity = rawCapacity is num ? rawCapacity.toInt() : 0;
    return _ServiceSlot(
      id: rawId,
      startTime: parsed.toUtc(),
      capacity: capacity,
    );
  }
}
