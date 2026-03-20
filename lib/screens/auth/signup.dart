import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_pulse/screens/auth/signin.dart';
import 'package:home_pulse/screens/user/user_profile.dart';
import 'package:home_pulse/screens/provider/provider_profile.dart';

enum UserType { provider, user }

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final providerTypeController = TextEditingController();
  UserType _selectedUserType = UserType.user;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    phoneController.dispose();
    providerTypeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    // Basic validation
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (_selectedUserType == UserType.provider &&
        providerTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the provider type.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create the user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        String uid = user.uid;
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        // 2. Save role to 'role' collection
        await firestore.collection('role').doc(uid).set({
          'role': _selectedUserType == UserType.user ? 'user' : 'provider',
        });

        // 3. Save to specific collection based on user type
        if (_selectedUserType == UserType.user) {
          await firestore.collection('users').doc(uid).set({
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'phone': phoneController.text.trim(),
            'profileImageUrl': '',
            'savedAddresses': [],
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await firestore.collection('providers').doc(uid).set({
            'name': nameController.text.trim(),
            'phone': phoneController.text.trim(),
            'ProviderType': providerTypeController.text.trim(),
            'bio': '',
            'rating': 0.0,
            'totalReviews': 0,
            'location': const GeoPoint(0, 0),
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        // 4. Navigate to the correct profile screen
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );

          final Widget profileScreen = _selectedUserType == UserType.user
              ? const UserProfileScreen()
              : const ProviderProfileScreen();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => profileScreen),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'An error occurred.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: _selectedUserType == UserType.user
                    ? 'User Name'
                    : 'Provider Name',
                hintText: _selectedUserType == UserType.user
                    ? 'Enter your name'
                    : 'Enter provider name',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            // Phone field
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: _selectedUserType == UserType.user
                    ? 'User Phone'
                    : 'Provider Phone',
                hintText: _selectedUserType == UserType.user
                    ? 'Enter your phone'
                    : 'Enter provider phone',
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            // Provider type field (only for provider)
            if (_selectedUserType == UserType.provider) ...[
              TextField(
                controller: providerTypeController,
                decoration: const InputDecoration(
                  labelText: 'Provider Type',
                  hintText: 'e.g. Electrician, Plumber',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
            // Email field
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            // Password field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Select Role:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            // User role selection
            Row(
              children: [
                Radio<UserType>(
                  value: UserType.user,
                  groupValue: _selectedUserType,
                  onChanged: (UserType? value) {
                    setState(() => _selectedUserType = value!);
                  },
                ),
                const Text('User'),
                Radio<UserType>(
                  value: UserType.provider,
                  groupValue: _selectedUserType,
                  onChanged: (UserType? value) {
                    setState(() => _selectedUserType = value!);
                  },
                ),
                const Text('Provider'),
              ],
            ),
            const SizedBox(height: 24.0),
            // Sign Up button
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSignUp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign Up', style: TextStyle(fontSize: 16.0)),
            ),
            const SizedBox(height: 24.0),
            // Navigate to Sign In
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => const SignIn()),
                      );
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                'Already have an account? Sign In',
                style: TextStyle(fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
