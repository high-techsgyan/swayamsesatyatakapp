import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:email_validator/email_validator.dart';
import 'package:go_router/go_router.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('Users');

  final _formKey = GlobalKey<FormState>();

  // Controllers for the form fields
  TextEditingController usernameController = TextEditingController();
  TextEditingController fullnameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController countryController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController pincodeController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  // Function to register the student
  Future<void> _registerStudent() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Authenticate user by creating with email and password
        // ignore: unused_local_variable
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Check if the user is authenticated
        final User? user = _auth.currentUser;
        if (user == null) {
          _showErrorDialog('Authentication failed.');
          return;
        }

        String userId = user.uid;

        // Check if username or phone number already exists
        final snapshot = await _dbRef
            .orderByChild('username')
            .equalTo(usernameController.text)
            .once();
        if (snapshot.snapshot.exists) {
          _showErrorDialog('Username already exists.');
          return;
        }

        final phoneSnapshot = await _dbRef
            .orderByChild('phone')
            .equalTo(phoneController.text)
            .once();
        if (phoneSnapshot.snapshot.exists) {
          _showErrorDialog('Phone number already registered.');
          return;
        }

        // Save user info in Realtime Database under their UID
        await _dbRef.child(userId).set({
          'username': usernameController.text,
          'fullname': fullnameController.text,
          'email': emailController.text,
          'phone': phoneController.text,
          'country': countryController.text,
          'state': stateController.text,
          'pincode': pincodeController.text,
          'userprofile': '',
          'password': _hashPassword(passwordController.text),
          'userid': userId,
          'isAdmin': false,
        });

        // Show success dialog and navigate to login screen
        _showSuccessDialog();
      } catch (e) {
        _showErrorDialog(e.toString());
      }
    }
  }

  // Hashing the password
  String _hashPassword(String password) {
    return password.hashCode.toString();
  }

  // Function to show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text('Okay'),
          ),
        ],
      ),
    );
  }

  // Function to show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Success'),
        content: Text('User created successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/login');
            },
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: _buildStudentForm(),
    );
  }

  // Student registration form
  Widget _buildStudentForm() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            _buildTextField(usernameController, 'Username', (value) {
              if (value!.isEmpty) return 'Please enter username';
              return null;
            }),
            _buildTextField(fullnameController, 'Full Name', (value) {
              if (value!.isEmpty) return 'Please enter full name';
              return null;
            }),
            _buildTextField(emailController, 'Email', (value) {
              if (!EmailValidator.validate(value!))
                return 'Please enter valid email';
              return null;
            }),
            _buildTextField(phoneController, 'Phone Number', (value) {
              if (value!.length != 10)
                return 'Phone number should be 10 digits';
              return null;
            }),
            _buildTextField(countryController, 'Country', (value) {
              if (value!.isEmpty) return 'Please enter country';
              return null;
            }),
            _buildTextField(stateController, 'State', (value) {
              if (value!.isEmpty) return 'Please enter state';
              return null;
            }),
            _buildTextField(pincodeController, 'Pincode', (value) {
              if (value!.isEmpty) return 'Please enter pincode';
              return null;
            }),
            _buildPasswordField(passwordController, 'Password', (value) {
              if (value!.length < 6)
                return 'Password must be at least 6 characters';
              return null;
            }),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerStudent,
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                context.go('/login');
              },
              child: Text('Already Have A Account? Login'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build TextFields
  Widget _buildTextField(TextEditingController controller, String labelText,
      String? Function(String?) validator) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: labelText),
        validator: validator,
      ),
    );
  }

  // Helper method to build PasswordFields
  Widget _buildPasswordField(TextEditingController controller, String labelText,
      String? Function(String?) validator) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(labelText: labelText),
        validator: validator,
      ),
    );
  }
}
