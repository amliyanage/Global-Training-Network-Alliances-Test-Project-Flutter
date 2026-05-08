import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

import '../../../../config/env_config.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../cart/domain/entities/cart_item.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import '../../domain/entities/booking.dart';
import '../../domain/entities/payment_session.dart';
import '../bloc/booking_bloc.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<CartBloc>()..add(LoadCartEvent())),
        BlocProvider(create: (_) => sl<BookingBloc>()),
      ],
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'Sri Lanka');

  bool _didPrefillFromAuth = false;
  bool _isLaunchingPayHere = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefillFromAuth) return;
    _didPrefillFromAuth = true;
    _prefillFromAuthState(context.read<AuthBloc>().state);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  void _prefillFromAuthState(AuthState state) {
    if (state is! Authenticated) return;

    final email = state.user.email.trim();
    if (_emailCtrl.text.trim().isEmpty) {
      _emailCtrl.text = email;
    }

    if (_firstNameCtrl.text.trim().isNotEmpty &&
        _lastNameCtrl.text.trim().isNotEmpty) {
      return;
    }

    final (firstName, lastName) = _guessNameFromEmail(email);
    if (_firstNameCtrl.text.trim().isEmpty) {
      _firstNameCtrl.text = firstName;
    }
    if (_lastNameCtrl.text.trim().isEmpty) {
      _lastNameCtrl.text = lastName;
    }
  }

  (String, String) _guessNameFromEmail(String email) {
    final localPart = email.split('@').first;
    final tokens = localPart
        .split(RegExp(r'[._-]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (tokens.isEmpty) {
      return ('Guest', '');
    }
    if (tokens.length == 1) {
      return (_toTitleCase(tokens.first), '');
    }

    return (
      _toTitleCase(tokens.first),
      _toTitleCase(tokens.sublist(1).join(' ')),
    );
  }

  String _toTitleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map(
          (word) =>
              '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  void _submitCheckout() {
    if (!_formKey.currentState!.validate()) return;

    final cartState = context.read<CartBloc>().state;
    if (cartState is! CartLoaded || cartState.cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty. Add items first.')),
      );
      return;
    }

    context.read<BookingBloc>().add(
      CheckoutEvent(
        paymentMethod: 'online',
        customer: {
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'country': _countryCtrl.text.trim(),
        },
      ),
    );
  }

  void _handleCheckoutSuccess(BookingEntity booking) {
    final session = booking.paymentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Checkout created, but payment session is missing from backend response.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _startPayHerePayment(booking: booking, session: session);
  }

  String _itemsSummary(List<CartItemEntity> items) {
    if (items.isEmpty) return 'GlobalTNA Booking';
    if (items.length == 1) return items.first.serviceName;
    return '${items.first.serviceName} + ${items.length - 1} more';
  }

  Map<String, dynamic> _buildLineItemPayload(List<CartItemEntity> items) {
    final payload = <String, dynamic>{};
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final index = i + 1;
      payload['item_number_$index'] = item.serviceId.isNotEmpty
          ? item.serviceId
          : item.id;
      payload['item_name_$index'] = item.serviceName;
      payload['quantity_$index'] = item.quantity.toString();
      payload['amount_$index'] = item.price.toStringAsFixed(2);
    }
    return payload;
  }

  List<CartItemEntity> _resolvePaymentItems(BookingEntity booking) {
    if (booking.items.isNotEmpty) return booking.items;
    final cartState = context.read<CartBloc>().state;
    if (cartState is CartLoaded) return cartState.cart.items;
    return <CartItemEntity>[];
  }

  void _startPayHerePayment({
    required BookingEntity booking,
    required PaymentSession session,
  }) {
    final items = _resolvePaymentItems(booking);
    final customerFirstName = _firstNameCtrl.text.trim();
    final customerLastName = _lastNameCtrl.text.trim();
    final customerEmail = _emailCtrl.text.trim();
    final customerPhone = _phoneCtrl.text.trim();
    final customerAddress = _addressCtrl.text.trim();
    final customerCity = _cityCtrl.text.trim();
    final customerCountry = _countryCtrl.text.trim();

    setState(() {
      _isLaunchingPayHere = true;
    });

    final effectiveMerchantId = session.merchantId.trim().isNotEmpty
        ? session.merchantId.trim()
        : EnvConfig.payHereMerchantId;
    final effectiveNotifyUrl = session.notifyUrl.trim().isNotEmpty
        ? session.notifyUrl.trim()
        : EnvConfig.payHereNotifyUrl;

    final paymentObject = <String, dynamic>{
      'sandbox': session.sandbox,
      'merchant_id': effectiveMerchantId,
      'merchant_secret': EnvConfig.payHereMerchantSecret,
      'notify_url': effectiveNotifyUrl,
      'order_id': session.orderId,
      'items': _itemsSummary(items),
      'amount': session.amount.toStringAsFixed(2),
      'currency': session.currency,
      'first_name': customerFirstName,
      'last_name': customerLastName,
      'email': customerEmail,
      'phone': customerPhone,
      'address': customerAddress,
      'city': customerCity,
      'country': customerCountry,
      'delivery_address': customerAddress,
      'delivery_city': customerCity,
      'delivery_country': customerCountry,
      'custom_1': session.custom1,
      'custom_2': session.custom2,
      ..._buildLineItemPayload(items),
    };

    if (session.returnUrl.trim().isNotEmpty) {
      paymentObject['return_url'] = session.returnUrl.trim();
    }
    if (session.cancelUrl.trim().isNotEmpty) {
      paymentObject['cancel_url'] = session.cancelUrl.trim();
    }

    try {
      PayHere.startPayment(
        paymentObject,
        (paymentId) {
          debugPrint('Payment Successful: $paymentId');
          if (!mounted) return;
          setState(() {
            _isLaunchingPayHere = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment successful: $paymentId'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/bookings');
        },
        (error) {
          debugPrint('Payment Error: $error');
          if (!mounted) return;
          setState(() {
            _isLaunchingPayHere = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        () {
          debugPrint('Payment Dismissed');
          if (!mounted) return;
          setState(() {
            _isLaunchingPayHere = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Payment cancelled')));
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLaunchingPayHere = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to start payment: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) return requiredError;

    final email = value!.trim();
    final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!isValid) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    final requiredError = _requiredValidator(value);
    if (requiredError != null) return requiredError;

    final phone = value!.replaceAll(RegExp(r'\s+'), '');
    if (phone.length < 7) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ?? _requiredValidator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
        ),
      ),
    );
  }

  Widget _buildCartSummary(CartLoaded state) {
    final cart = state.cart;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(51),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...cart.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.serviceName} x${item.quantity}'),
                  ),
                  Text(
                    'LKR ${(item.price * item.quantity).toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                'LKR ${cart.runningTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
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
              return;
            }
            _prefillFromAuthState(state);
          },
        ),
        BlocListener<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is BookingCheckoutSuccess) {
              _handleCheckoutSuccess(state.booking);
            } else if (state is BookingError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PayHere Checkout'),
          centerTitle: true,
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            if (cartState is CartLoading || cartState is CartInitial) {
              return const CheckoutSkeleton();
            }
            if (cartState is CartError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(cartState.message, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.read<CartBloc>().add(LoadCartEvent()),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (cartState is! CartLoaded || cartState.cart.items.isEmpty) {
              return const Center(child: Text('Your cart is empty'));
            }

            return BlocBuilder<BookingBloc, BookingState>(
              builder: (context, bookingState) {
                final isSubmitting =
                    bookingState is BookingLoading || _isLaunchingPayHere;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const Icon(Icons.credit_card, size: 80),
                        const SizedBox(height: 20),
                        _buildCartSummary(cartState),
                        const SizedBox(height: 20),
                        _buildField(
                          controller: _firstNameCtrl,
                          label: 'First Name',
                          icon: Icons.person_outline,
                        ),
                        _buildField(
                          controller: _lastNameCtrl,
                          label: 'Last Name',
                          icon: Icons.person_outline,
                        ),
                        _buildField(
                          controller: _emailCtrl,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: _emailValidator,
                        ),
                        _buildField(
                          controller: _phoneCtrl,
                          label: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: _phoneValidator,
                        ),
                        _buildField(
                          controller: _addressCtrl,
                          label: 'Address',
                          icon: Icons.home_outlined,
                        ),
                        _buildField(
                          controller: _cityCtrl,
                          label: 'City',
                          icon: Icons.location_city_outlined,
                        ),
                        _buildField(
                          controller: _countryCtrl,
                          label: 'Country',
                          icon: Icons.flag_outlined,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.security),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Powered by PayHere Secure Payment Gateway',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting ? null : _submitCheckout,
                            icon: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.lock_outline),
                            label: Text(
                              isSubmitting
                                  ? 'Processing...'
                                  : 'Pay LKR ${cartState.cart.runningTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
