import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_pulse/screens/auth/signup.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  Future<Map<String, dynamic>?> _fetchProviderData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SignUp()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchProviderData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No provider data found.'));
          }
          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${data['name'] ?? ''}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Phone: ${data['phone'] ?? ''}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Provider Type: ${data['ProviderType'] ?? ''}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Bio: ${data['bio'] ?? ''}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Rating: ${data['rating'] ?? 0.0}',
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text('Total Reviews: ${data['totalReviews'] ?? 0}',
                    style: const TextStyle(fontSize: 18)),
                // Add more fields as needed
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
