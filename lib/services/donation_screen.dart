import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class DonationPage extends StatefulWidget {
  @override
  _DonationPageState createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  late Razorpay _razorpay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final donationData = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'message': _messageController.text,
        'amount': _amountController.text,
        'userId': user.uid,
        'paymentId': response.paymentId,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final DatabaseReference donationsRef =
          FirebaseDatabase.instance.ref('Users/${user.uid}/donations').push();
      await donationsRef.set(donationData);

      _showDialog('Success', 'Payment successful and donation recorded!');
      _clearFields();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showDialog('Payment Error', 'Payment failed: ${response.message}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _showDialog(
        'External Wallet', 'External wallet selected: ${response.walletName}');
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _clearFields() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _messageController.clear();
    _amountController.clear();
  }

  void _initiatePayment() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      var options = {
        'key': 'YOUR_RAZORPAY_KEY',
        'amount': (double.parse(_amountController.text) * 100)
            .toInt(), // amount in paise
        'name': 'Donation',
        'description': 'Donation Payment',
        'timeout': 300, // in seconds
        'prefill': {
          'contact': _phoneController.text,
          'email': _emailController.text,
        },
      };

      try {
        _razorpay.open(options);
      } catch (e) {
        _showDialog('Error', 'Failed to initiate payment: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation Page')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Support Us with a Donation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _buildTextField(_nameController, 'Name',
                    'Please enter your name', TextInputType.name),
                _buildTextField(_emailController, 'Email',
                    'Please enter a valid email', TextInputType.emailAddress),
                _buildTextField(_phoneController, 'Phone Number',
                    'Please enter a valid phone number', TextInputType.phone),
                _buildTextField(_messageController, 'Message (Optional)', null,
                    TextInputType.text,
                    requiredField: false),
                _buildTextField(_amountController, 'Donation Amount',
                    'Please enter a donation amount', TextInputType.number),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _initiatePayment,
                        child: const Text('Donate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String? errorMessage, TextInputType inputType,
      {bool requiredField = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        validator: (value) {
          if (requiredField && (value == null || value.isEmpty)) {
            return errorMessage;
          } else if (label == 'Email' &&
              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
            return 'Please enter a valid email address';
          } else if (label == 'Phone Number' &&
              !RegExp(r'^\d{10}$').hasMatch(value!)) {
            return 'Please enter a valid 10-digit phone number';
          } else if (label == 'Donation Amount' &&
              (double.tryParse(value!) == null || double.parse(value) <= 0)) {
            return 'Please enter a valid amount';
          }
          return null;
        },
      ),
    );
  }
}
