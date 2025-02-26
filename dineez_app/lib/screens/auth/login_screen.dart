import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../providers/providers.dart';
import '../../utils/validators.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    ref.read(logInfoProvider)('Login screen viewed', source: 'LoginScreen');
    
    // Check if we have stored credentials
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final preferences = ref.read(appPreferencesProvider);
      // Implementation would depend on how you store credentials
      // This is just a placeholder example
      if (preferences.lastEmail != null && preferences.lastEmail!.isNotEmpty) {
        _emailController.text = preferences.lastEmail!;
        _rememberMe = true;
        setState(() {});
      }
    } catch (e) {
      ref.read(logErrorProvider)('Error loading saved credentials', 
          source: 'LoginScreen', data: e);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      // Show loading indicator
      ref.read(globalLoadingProvider.notifier).state = true;
      
      // Log the login attempt (without the password!)
      ref.read(logInfoProvider)('Login attempt', 
          source: 'LoginScreen', data: {'email': email});
      
      // Attempt to sign in
      final success = await ref.read(authProvider.notifier).signInWithEmailAndPassword(
        email,
        password,
      );
      
      if (!success) {
        throw Exception('Login failed');
      }
      
      // Save credentials if remember me is checked
      if (_rememberMe) {
        // Implementation would depend on how you store credentials
        // This is just an example - in a real app, you'd use a secure storage
        ref.read(appPreferencesProvider.notifier).saveEmail(email);
      } else {
        ref.read(appPreferencesProvider.notifier).clearSavedCredentials();
      }

      // Check if we're still mounted before navigating
      if (!mounted) return;
      
      // Navigate to dashboard on success
      Navigator.pushReplacementNamed(context, AppConstants.routeDashboard);
    } catch (e) {
      // Log the error
      ref.read(logErrorProvider)('Login failed', 
          source: 'LoginScreen', data: e);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Hide loading indicator
      ref.read(globalLoadingProvider.notifier).state = false;
    }
  }

  void _navigateToRegister() {
    Navigator.pushNamed(context, AppConstants.routeRegister);
  }

  void _navigateToForgotPassword() {
    Navigator.pushNamed(context, AppConstants.routeForgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for any changes
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    margin: const EdgeInsets.only(bottom: 40),
                    child: Center(
                      child: Text(
                        'DineEZ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  // Heading
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your account',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => Validators.validateEmail(value),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword 
                            ? Icons.visibility_outlined 
                            : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) => Validators.validatePassword(value),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                  ),
                  
                  // Remember me & forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          const Text('Remember me'),
                        ],
                      ),
                      TextButton(
                        onPressed: _navigateToForgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  
                  // Register link
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: _navigateToRegister,
                        child: const Text('Register'),
                      ),
                    ],
                  ),
                  
                  // Error message
                  if (authState.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 