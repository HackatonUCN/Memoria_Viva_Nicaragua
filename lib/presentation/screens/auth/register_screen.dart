import 'package:flutter/material.dart';
import 'package:memoria_viva_nicaragua/presentation/screens/home/home_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/social_login_button.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/auth_background.dart';
import '../../widgets/auth/animated_button.dart';
import '../../widgets/auth/fade_animation.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validar nombre
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu nombre';
    }
    return null;
  }

  // Validar correo electrónico
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    // Expresión regular para validar correo
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor ingresa un correo electrónico válido';
    }
    return null;
  }

  // Validar contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  // Validar confirmación de contraseña
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // Registrarse con correo y contraseña
  Future<void> _registerWithEmailAndPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.registerWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
        );

        if (authProvider.status == AuthStatus.authenticated) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const HomeScreen(title: '',),
              ),
            );
          }
        } else if (authProvider.status == AuthStatus.error) {
          setState(() {
            _errorMessage = authProvider.errorMessage;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error al registrarse: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Iniciar sesión con Google
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();

      if (authProvider.status == AuthStatus.authenticated) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const HomeScreen(title: '',),
            ),
          );
        }
      } else if (authProvider.status == AuthStatus.error) {
        setState(() {
          _errorMessage = authProvider.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al iniciar sesión con Google: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Método eliminado

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isWeb = ResponsiveHelper.isTablet(context) || ResponsiveHelper.isDesktop(context);

    // Si el usuario ya está autenticado, redirigir a HomeScreen
    if (authProvider.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const HomeScreen(title: '',),
          ),
        );
      });
    }

    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: isWeb ? 20.0 : 16.0,
                horizontal: isWeb ? 20.0 : 0.0,
              ),
              child: Container(
                // Quitamos el ConstrainedBox para que se adapte al contenido
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: isWeb ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    SizedBox(height: isWeb ? 0 : 16),
                  
                                    // Logo
                  FadeAnimation(
                    delay: 0.2,
                    child: Center(
                      child: Container(
                        width: isWeb ? 100 : 120,
                        height: isWeb ? 100 : 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.nicaraguaGradient,
                        ),
                        child: Center(
                          child: Text(
                            'MV',
                            style: AppTypography.textTheme.displayMedium?.copyWith(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              
              SizedBox(height: isWeb ? 20 : 32),
                  
                  // Título
                  FadeAnimation(
                    delay: 0.4,
                    child: Text(
                      'Crear Cuenta',
                      style: AppTypography.textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtítulo
                  FadeAnimation(
                    delay: 0.6,
                    child: Text(
                      'Únete a nuestra comunidad cultural',
                      style: AppTypography.textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  SizedBox(height: isWeb ? 16 : 32),
                  
                  // Mensaje de error
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  
                  // Campos de texto
                  FadeAnimation(
                    delay: 0.8,
                    child: CustomTextField(
                      controller: _nameController,
                      hintText: 'Nombre completo',
                      prefixIcon: Icons.person_outline,
                      validator: _validateName,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  FadeAnimation(
                    delay: 1.0,
                    child: CustomTextField(
                      controller: _emailController,
                      hintText: 'Correo electrónico',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  FadeAnimation(
                    delay: 1.2,
                    child: CustomTextField(
                      controller: _passwordController,
                      hintText: 'Contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  FadeAnimation(
                    delay: 1.4,
                    child: CustomTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirmar contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: _validateConfirmPassword,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón de registro
                  FadeAnimation(
                    delay: 1.6,
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : AnimatedButton(
                          text: 'Registrarse',
                          onPressed: _registerWithEmailAndPassword,
                        ),
                  ),
                      
                  const SizedBox(height: 24),
                      
                  // Separador
                  FadeAnimation(
                    delay: 1.8,
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
                        Padding(
                          padding: AppSpacing.marginHorizontalMd,
                          child: Text(
                            'O regístrate con',
                            style: AppTypography.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
                      ],
                    ),
                  ),
                      
                  const SizedBox(height: 24),
                      
                  // Botón de Google
                  FadeAnimation(
                    delay: 2.0,
                    child: Center(
                      child: SocialLoginButton(
                        icon: 'assets/icons/google.svg',
                        onPressed: () => _signInWithGoogle(),
                      ),
                    ),
                  ),
                      
                  const SizedBox(height: 24),
                      
                  // Link de inicio de sesión
                  FadeAnimation(
                    delay: 2.2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes una cuenta? ',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Inicia sesión',
                            style: AppTypography.textTheme.labelLarge?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}