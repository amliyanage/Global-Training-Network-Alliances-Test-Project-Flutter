import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../bookings/presentation/bloc/booking_bloc.dart';
import '../../../bookings/presentation/bloc/booking_event.dart';
import '../../../bookings/presentation/bloc/booking_state.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../injection_container.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  Future<String?> _selectPaymentMethod(BuildContext context) {
    const methods = ['online', 'cash', 'pay_on_arrival'];
    return showModalBottomSheet<String>(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: methods
                .map(
                  (method) => ListTile(
                    title: Text(_labelForPaymentMethod(method)),
                    onTap: () => Navigator.of(bottomSheetContext).pop(method),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  String _labelForPaymentMethod(String method) {
    switch (method) {
      case 'pay_on_arrival':
        return 'Pay on arrival';
      case 'cash':
        return 'Cash';
      case 'online':
      default:
        return 'Online';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CartBloc>()..add(LoadCartEvent())),
        BlocProvider(create: (_) => sl<BookingBloc>()),
        BlocProvider(create: (_) => sl<AuthBloc>()),
      ],
      child: MultiBlocListener(
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
              if (state is BookingCheckoutSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Checkout successful')),
                );
                context.go('/bookings');
              } else if (state is BookingError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Your Cart'),
            actions: [
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
          body: BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoading || state is CartInitial) {
                return const CartListSkeleton();
              } else if (state is CartError) {
                return Center(child: Text(state.message));
              } else if (state is CartLoaded) {
                final cart = state.cart;
                if (cart.items.isEmpty) {
                  return const Center(child: Text('Your cart is empty'));
                }
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: cart.items.length,
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withAlpha(26),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.local_offer_outlined,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.serviceName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Qty: ${item.quantity}',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () {
                                      context.read<CartBloc>().add(
                                        RemoveCartItemEvent(item.id),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            offset: const Offset(0, -4),
                            blurRadius: 16,
                          ),
                        ],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'LKR ${cart.runningTotal.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<BookingBloc, BookingState>(
                              builder: (context, bookingState) {
                                final isSubmitting =
                                    bookingState is BookingLoading;
                                return SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: isSubmitting
                                        ? null
                                        : () async {
                                            final paymentMethod =
                                                await _selectPaymentMethod(
                                                  context,
                                                );
                                            if (paymentMethod == null ||
                                                !context.mounted) {
                                              return;
                                            }
                                            if (paymentMethod == 'online') {
                                              // Navigate to checkout page to collect
                                              // customer details and open PayHere.
                                              context.push('/checkout');
                                            } else {
                                              context.read<BookingBloc>().add(
                                                CheckoutEvent(
                                                  paymentMethod: paymentMethod,
                                                ),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: isSubmitting
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : const Text(
                                            'Proceed to Checkout',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const CartListSkeleton();
            },
          ),
        ),
      ),
    );
  }
}
