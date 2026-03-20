import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_pulse/screens/auth/signup.dart';
import 'package:home_pulse/screens/user/user_profile.dart';
import 'package:home_pulse/screens/provider/provider_profile.dart';

/// Checks auth state on app launch and routes to the correct screen:
/// - Not logged in → SignUp
/// - Logged in as 'user' → UserProfileScreen
/// - Logged in as 'provider' → ProviderProfileScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Widget> _resolveHome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SignUp();

    try {
      final roleDoc = await FirebaseFirestore.instance
          .collection('role')
          .doc(user.uid)
          .get();

      final role = roleDoc.data()?['role'];

      if (role == 'provider') {
        return const ProviderProfileScreen();
      }
      return const UserProfileScreen();
    } catch (_) {
      // If role lookup fails, sign out and show signup
      await FirebaseAuth.instance.signOut();
      return const SignUp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _resolveHome(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SignUp();
        }
        return snapshot.data!;
      },
    );
  }
}
