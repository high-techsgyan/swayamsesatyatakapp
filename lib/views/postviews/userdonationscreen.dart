import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:go_router/go_router.dart';

class UserDonationScreen extends StatefulWidget {
  @override
  _UserDonationScreenState createState() => _UserDonationScreenState();
}

class _UserDonationScreenState extends State<UserDonationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late DatabaseReference _donationsRef;
  List<Map<dynamic, dynamic>> donations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserDonations();
  }

  Future<void> _fetchUserDonations() async {
    final user = _auth.currentUser;
    if (user != null) {
      _donationsRef =
          FirebaseDatabase.instance.ref('Users/${user.uid}/donation');
      final snapshot = await _donationsRef.once();

      if (snapshot.snapshot.value != null) {
        final donationsData = snapshot.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          donations = donationsData.values
              .map((e) => e as Map<dynamic, dynamic>)
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Donations')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : donations.isEmpty
              ? Center(child: Text('No Donations'))
              : ListView.builder(
                  itemCount: donations.length,
                  itemBuilder: (context, index) {
                    final donation = donations[index];
                    return ListTile(
                      title: Text(donation['name'] ?? 'Anonymous'),
                      subtitle: Text('Amount: \$${donation['amount'] ?? '0'}'),
                      trailing: Text(donation['date'] ?? ''),
                    );
                  },
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () => context.push('/donation'),
          child: Text('Make a Donation'),
        ),
      ),
    );
  }
}
