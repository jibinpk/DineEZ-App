import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/constants.dart';
import '../../providers/providers.dart';
import '../../utils/validators.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _resetEmailSent = false;

  @override
  void initState() {
    super.initState();
    ref.read(logInfoProvider)('Forgot password screen viewed', source: 'ForgotPasswordScreen');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();

    try {
      // Show loading indicator
      ref.read(globalLoadingProvider.notifier).state = true;
      
      // Log the reset attempt
      ref.read(logInfoProvider)('Password reset attempt', 
          source: 'ForgotPasswordScreen', data: {'email': email});
      
      // Attempt to reset password
      final success = await ref.read(authProvider.notifier).resetPassword(email);
      
      if (!success) {
        throw Exception('Password reset failed');
      }

      // Set success state
      setState(() {
        _resetEmailSent = true;
      });
      
    } catch (e) {
      // Log the error
      ref.read(logErrorProvider)('Password reset failed', 
          source: 'ForgotPasswordScreen', data: e);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Hide loading indicator
      ref.read(globalLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state for any changes
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: _resetEmailSent
                ? _buildSuccessView(context)
                : _buildResetForm(context, authState),
          ),
        ),
      ),
    );
  }
  
  Widget _buildResetForm(BuildContext context, AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          
          // Heading
          Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
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
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
          ),
          const SizedBox(height: 24),
          
          // Reset button
          ElevatedButton(
            onPressed: authState.isLoading ? null : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reset Password',
              style: TextStyle(fontSize: 16),
            ),
          ),
          
          // Back to login
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Login'),
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
    );
  }
  
  Widget _buildSuccessView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success icon
        const Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        
        // Success message
        Text(
          'Email Sent!',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to ${_emailController.text}. Please check your email and follow the instructions.',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        // Didnt receive email
        Text(
          'Didn\'t receive the email?',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        
        // Retry button
        OutlinedButton(
          onPressed: () {
            setState(() {
              _resetEmailSent = false;
            });
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Try Again'),
        ),
        
        // Back to login
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacementNamed(context, AppConstants.routeLogin),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Back to Login'),
        ),
      ],
    );
  }
} 