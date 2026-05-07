import 'package:flutter/material.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController(text: "Ashen");
  final _lastNameCtrl = TextEditingController(text: "Madushanka");
  final _emailCtrl =
      TextEditingController(text: "ashenmadushanka@gmail.com");
  final _phoneCtrl = TextEditingController(text: "0771234567");
  final _addressCtrl = TextEditingController(text: "Colombo");
  final _cityCtrl = TextEditingController(text: "Colombo");
  final _countryCtrl = TextEditingController(text: "Sri Lanka");

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

  void _startPayment() {
    if (!_formKey.currentState!.validate()) return;

    final orderId = "ORDER_${DateTime.now().millisecondsSinceEpoch}";

    final Map<String, dynamic> paymentObject = {
      "sandbox": true,

      // PayHere sandbox merchant credentials
      "merchant_id": "1235615",
      "merchant_secret": "NDE0MDM5MzE2NjIxMjI1MDk2NjI0ODk2NzU4ODQ4NTU0NTI3NzI=",

      // Order details
      "notify_url": "https://regulator-granny-pretended.ngrok-free.dev/notify",
      "order_id": orderId,
      "items": "Global TNA Booking",

      // Amount
      "amount": "1000.00",
      "currency": "LKR",

      // Customer details
      "first_name": _firstNameCtrl.text.trim(),
      "last_name": _lastNameCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "phone": _phoneCtrl.text.trim(),
      "address": _addressCtrl.text.trim(),
      "city": _cityCtrl.text.trim(),
      "country": _countryCtrl.text.trim(),

      // Delivery details
      "delivery_address": _addressCtrl.text.trim(),
      "delivery_city": _cityCtrl.text.trim(),
      "delivery_country": _countryCtrl.text.trim(),

      // Optional
      "custom_1": "",
      "custom_2": "",
    };

    PayHere.startPayment(
      paymentObject,

      // SUCCESS
      (paymentId) {
        debugPrint("Payment Successful: $paymentId");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment Successful: $paymentId"),
            backgroundColor: Colors.green,
          ),
        );
      },

      // ERROR
      (error) {
        debugPrint("Payment Error: $error");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment Failed: $error"),
            backgroundColor: Colors.red,
          ),
        );
      },

      // DISMISSED
      () {
        debugPrint("Payment Dismissed");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment Cancelled"),
          ),
        );
      },
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    }
    return null;
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: _requiredValidator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PayHere Checkout"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),

              Icon(
                Icons.credit_card,
                size: 80,
              ),

              const SizedBox(height: 20),

              _buildField(
                controller: _firstNameCtrl,
                label: "First Name",
                icon: Icons.person_outline,
              ),

              _buildField(
                controller: _lastNameCtrl,
                label: "Last Name",
                icon: Icons.person_outline,
              ),

              _buildField(
                controller: _emailCtrl,
                label: "Email",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              _buildField(
                controller: _phoneCtrl,
                label: "Phone Number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              _buildField(
                controller: _addressCtrl,
                label: "Address",
                icon: Icons.home_outlined,
              ),

              _buildField(
                controller: _cityCtrl,
                label: "City",
                icon: Icons.location_city_outlined,
              ),

              _buildField(
                controller: _countryCtrl,
                label: "Country",
                icon: Icons.flag_outlined,
              ),

              const SizedBox(height: 30),

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
                        "Powered by PayHere Secure Payment Gateway",
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _startPayment,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text(
                    "Pay Now",
                    style: TextStyle(
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
      ),
    );
  }
}