import 'package:flutter/material.dart';
import 'package:memoria_viva_nicaragua/presentation/screens/auth/register_screen.dart';
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();

  // Observador de rutas compartido para reiniciar animaciones al volver a Login
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
}

class _LoginScreenState extends State<LoginScreen> with RouteAware {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  
  // Clave para forzar la reconstrucción de las animaciones (fade y background)
  Key _animationKey = UniqueKey();
  // Clave adicional para reiniciar el subárbol de contenido (FadeAnimation)
  Key _contentAnimationKey = UniqueKey();
  // Versión para re-crear instancias específicas de FadeAnimation
  int _animVersion = 0;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Registrar para observar cambios de ruta
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute) {
      LoginScreen.routeObserver.subscribe(this, route);
    }
  }
  
  @override
  void didPopNext() {
    // Cuando regresamos a esta pantalla (por ejemplo, desde register)
    // Regeneramos la clave para forzar nuevas animaciones
    setState(() {
      _animationKey = UniqueKey();
      _contentAnimationKey = UniqueKey();
      _animVersion++;
    });
    super.didPopNext();
  }
  
  @override
  void dispose() {
    LoginScreen.routeObserver.unsubscribe(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  // Iniciar sesión con correo y contraseña
  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
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
          _errorMessage = 'Error al iniciar sesión: $e';
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

  // Restablecer contraseña
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor ingresa tu correo electrónico para restablecer la contraseña';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.resetPassword(_emailController.text.trim());
      
      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se ha enviado un correo para restablecer tu contraseña'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al enviar el correo: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Iniciar sesión como invitado
  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInAnonymously();

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
        _errorMessage = 'Error al iniciar sesión como invitado: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
        // Clave en el background para re-crear su estado y animación al volver
        key: _animationKey,
        child: SingleChildScrollView(
          // Clave para forzar re-creación de FadeAnimation en los controles
          key: _contentAnimationKey,
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
                      'Bienvenido',
                      style: AppTypography.textTheme.displaySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtítulo
                  FadeAnimation(
                    delay: 0.6,
                    child: Text(
                      'Inicia sesión para continuar',
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
                    key: ValueKey('fade_email_\${_animVersion}'),
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
                    delay: 1.0,
                    key: ValueKey('fade_password_\${_animVersion}'),
                    child: CustomTextField(
                      controller: _passwordController,
                      hintText: 'Contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      validator: _validatePassword,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón de inicio de sesión
                  FadeAnimation(
                    delay: 1.2,
                    child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : AnimatedButton(
                          text: 'Iniciar Sesión',
                          onPressed: _signInWithEmailAndPassword,
                        ),
                  ),
                      
                  // Olvidé mi contraseña
                  FadeAnimation(
                    delay: 1.4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                      
                  const SizedBox(height: 24),
                      
                  // Separador
                  FadeAnimation(
                    delay: 1.6,
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.textSecondary.withOpacity(0.3))),
                        Padding(
                          padding: AppSpacing.marginHorizontalMd,
                          child: Text(
                            'O continúa con',
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
                    delay: 1.8,
                    child: Center(
                      child: SocialLoginButton(
                        icon: 'assets/icons/google.svg',
                        onPressed: () => _signInWithGoogle(),
                      ),
                    ),
                  ),
                      
                  SizedBox(height: isWeb ? 16 : 24),
                      
                  // Botón de invitado
                  FadeAnimation(
                    delay: 2.0,
                    child: TextButton(
                      onPressed: () => _signInAnonymously(),
                      child: Text(
                        'Continuar como invitado',
                        style: AppTypography.textTheme.labelLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                      
                  const SizedBox(height: 16),
                      
                  // Link de registro
                  FadeAnimation(
                    delay: 2.2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes una cuenta? ',
                          style: AppTypography.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Regístrate',
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