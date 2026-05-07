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
  late final TextEditingController _slotIdController;
  int _quantity = 1;
  bool _isLoadingSlots = true;
  String? _slotLoadError;
  List<_ServiceSlot> _slots = const [];
  String? _selectedSlotId;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    _slotIdController = TextEditingController();
    _loadSlots();
  }

  @override
  void dispose() {
    _slotIdController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _isLoadingSlots = true;
      _slotLoadError = null;
    });

    try {
      final dateStr =
          "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
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
          _slotLoadError = 'No upcoming slots available for this service.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingSlots = false;
        _slotLoadError = 'Could not load slots. Enter slot ID manually.';
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
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute (cap ${slot.capacity})';
  }

  void _submit() {
    final slotId = _selectedSlotId ?? _slotIdController.text.trim();
    if (slotId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Slot ID is required')));
      return;
    }

    final dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    widget.onSubmit(slotId, dateStr, _quantity);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add "${widget.service.title}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                      _loadSlots();
                    }
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            if (_isLoadingSlots)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loading available slots...'),
                    SizedBox(height: 10),
                    SlotsSkeleton(),
                  ],
                ),
              )
            else if (_slots.isNotEmpty)
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSlotId,
                    decoration: const InputDecoration(labelText: 'Time Slot'),
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
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedSlotId = value;
                        _slotIdController.text = value;
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Slot ID: ${_selectedSlotId ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              )
            else
              TextField(
                controller: _slotIdController,
                decoration: InputDecoration(
                  labelText: 'Slot ID',
                  helperText:
                      _slotLoadError ??
                      'Enter a valid slot ID from /services/{id} slots.',
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Quantity'),
                const Spacer(),
                IconButton(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_quantity'),
                IconButton(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoadingSlots ? null : _loadSlots,
          child: const Text('Reload Slots'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Add to Cart')),
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
