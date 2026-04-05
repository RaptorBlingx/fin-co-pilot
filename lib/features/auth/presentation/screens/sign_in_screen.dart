import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/premium_button.dart';
import '../../../../services/auth_service.dart';
import '../../../../core/constants/app_constants.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  bool _obscurePassword = true;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      
      if (mounted) {
        context.go(AppConstants.routeOnboarding);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      
      if (mounted) {
        context.go(AppConstants.routeOnboarding);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Google Sign In failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithApple();
      
      if (mounted) {
        context.go(AppConstants.routeOnboarding);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Apple Sign In failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: context.isDark
                ? [AppTheme.darkBackground, const Color(0xFF1A1040)]
                : [AppTheme.slate50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(DesignTokens.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: DesignTokens.space48),
                
                // App branding
                Icon(
                  PhosphorIcons.wallet(PhosphorIconsStyle.duotone),
                  size: 72,
                  color: AppTheme.primaryIndigo,
                ).animate().fadeIn(duration: DesignTokens.durationSlow).scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  curve: DesignTokens.curveDecelerate,
                ),
                
                SizedBox(height: DesignTokens.space16),
                
                Text(
                  'Fin Co-Pilot',
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                
                SizedBox(height: DesignTokens.space4),
                
                Text(
                  'Your AI-Powered Financial Assistant',
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ).animate().fadeIn(delay: 200.ms),
                
                SizedBox(height: DesignTokens.space40),
                
                // Error banner
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(DesignTokens.space12),
                    margin: EdgeInsets.only(bottom: DesignTokens.space16),
                    decoration: BoxDecoration(
                      color: AppTheme.rose500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                      border: Border.all(color: AppTheme.rose500.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(PhosphorIcons.warningCircle(), color: AppTheme.rose500, size: DesignTokens.iconSM),
                        SizedBox(width: DesignTokens.space8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: context.textTheme.bodySmall?.copyWith(color: AppTheme.rose500),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                
                // Email/Password Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                          ),
                          prefixIcon: Icon(PhosphorIcons.envelope()),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      
                      SizedBox(height: DesignTokens.space16),
                      
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSM),
                          ),
                          prefixIcon: Icon(PhosphorIcons.lock()),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? PhosphorIcons.eye()
                                  : PhosphorIcons.eyeSlash(),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                
                SizedBox(height: DesignTokens.space24),
                
                // Sign In/Sign Up Button
                PremiumButton(
                  onPressed: _isLoading ? null : _handleEmailAuth,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                ).animate().fadeIn(delay: 400.ms),
                
                SizedBox(height: DesignTokens.space12),
                
                // Toggle Sign In/Sign Up
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Don\'t have an account? Sign Up',
                  ),
                ),
                
                SizedBox(height: DesignTokens.space24),
                
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: DesignTokens.space16),
                      child: Text(
                        'OR',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                SizedBox(height: DesignTokens.space24),
                
                // Google Sign In
                PremiumButton(
                  variant: PremiumButtonVariant.secondary,
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: PhosphorIcons.googleLogo(),
                  child: const Text('Continue with Google'),
                ).animate().fadeIn(delay: 500.ms),
                
                SizedBox(height: DesignTokens.space12),
                
                // Apple Sign In (iOS only)
                if (Theme.of(context).platform == TargetPlatform.iOS)
                  PremiumButton(
                    variant: PremiumButtonVariant.secondary,
                    onPressed: _isLoading ? null : _handleAppleSignIn,
                    icon: PhosphorIcons.appleLogo(),
                    child: const Text('Continue with Apple'),
                  ).animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}