import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  static const routeName = '/auth';

  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  User? _user;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateDisplayName(User user, String name) async {
    if (name.isEmpty) return;
    await user.updateDisplayName(name);
    await user.reload();
    _user = FirebaseAuth.instance.currentUser;
  }

  Future<void> _handleAnonymous() async {
    final name = _nameController.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.signInAnonymously();
      if (user != null && name.isNotEmpty) {
        await _updateDisplayName(user, name);
      }
    } catch (e) {
      setState(() => _error = 'Anonymous sign‑in failed');
    } finally {
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _loading = false;
      });
    }
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.signInWithEmail(email, password);
      final name = _nameController.text.trim();
      if (user != null && name.isNotEmpty) {
        await _updateDisplayName(user, name);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Email sign‑in failed');
    } finally {
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _loading = false;
      });
    }
  }

  Future<void> _handleEmailSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Name, email and password required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await _authService.signUpWithEmail(email, password);
      if (user != null) {
        await _updateDisplayName(user, name);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Sign up failed');
    } finally {
      setState(() {
        _user = FirebaseAuth.instance.currentUser;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final displayName =
        _user?.displayName ??
        (_user?.isAnonymous == true ? 'Guest' : _user?.email);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_user != null) ...[
                Text('Signed in as: $displayName'),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (used in game)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleEmailSignIn,
                child: const Text('Sign in with Email'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _handleEmailSignUp,
                child: const Text('Sign up with Email'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _handleAnonymous,
                child: const Text('Continue as Guest'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
