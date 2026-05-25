// lib/features/auth/presentation/pages/login_page.dart
//
// ¿Qué hace este archivo?
// Pantalla de inicio de sesión del sistema MRO.
// Diseñada para trabajo profesional:
// - Alto contraste para luz solar
// - Campos grandes para dedos con guantes
// - Feedback claro de errores
// - Indicador de carga durante el login

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

// ConsumerState: permite acceder a Riverpod (ref) Y tener
// estado local (StatefulWidget) al mismo tiempo.
class _LoginPageState extends ConsumerState<LoginPage> {
  // Controladores de texto: manejan el valor de los campos
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Clave para el Form: permite validar todos los campos
  // del formulario con un solo comando
  final _formKey = GlobalKey<FormState>();

  // Estado local para mostrar/ocultar contraseña
  bool _obscurePassword = true;

  @override
  void dispose() {
    // SIEMPRE disponer los controladores para evitar memory leaks.
    // Si no los dispones, ocupan memoria aunque la pantalla no esté visible.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Método que ejecuta el login
  Future<void> _handleLogin() async {
    // validate() revisa todos los validators de los campos
    if (!_formKey.currentState!.validate()) return;

    // Ocultar teclado antes de procesar
    FocusScope.of(context).unfocus();

    // Llamar al AuthNotifier para hacer el login
    await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch(authProvider) escucha cambios en el estado de auth.
    // Cada vez que el estado cambia, este widget se reconstruye.
    final authState = ref.watch(authProvider);

    // Listener para reaccionar a cambios de estado SIN reconstruir.
    // Ideal para navegación y mostrar SnackBars.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        // Login exitoso → navegar al home
        context.go('/home');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        // Error → mostrar mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    next.errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        // Limpiar el error después de mostrarlo
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          // Permite scroll cuando el teclado sube
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // ─── LOGO Y MARCA ────────────────────────
                  _buildHeader(),

                  const SizedBox(height: 48),

                  // ─── FORMULARIO ──────────────────────────
                  _buildForm(authState),

                  const SizedBox(height: 48),

                  // ─── PIE DE PÁGINA ───────────────────────
                  _buildFooter(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo de la empresa
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.construction_rounded,
            color: Colors.white,
            size: 56,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'MRO Damage System',
          style: AppTextStyles.h1.copyWith(
            color: AppColors.primary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Sistema de Levantamiento de Daños',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── CAMPO EMAIL ────────────────────────────
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enabled: !authState.isLoading,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'usuario@mroam.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El correo es requerido';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // ─── CAMPO CONTRASEÑA ───────────────────────
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !authState.isLoading,
            onFieldSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              hintText: '••••••••',
              prefixIcon: const Icon(Icons.lock_outline),
              // Botón para mostrar/ocultar contraseña
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La contraseña es requerida';
              }
              if (value.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),

          const SizedBox(height: 32),

          // ─── BOTÓN DE LOGIN ─────────────────────────
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _handleLogin,
              child: authState.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Iniciar Sesión'),
            ),
          ),

          const SizedBox(height: 16),

          // ─── OLVIDÉ MI CONTRASEÑA ───────────────────
          TextButton(
            onPressed: authState.isLoading ? null : _showForgotPasswordDialog,
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'MRO Estado de Mexico-Michoacan SAPI de CV',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
        Text(
          'Contrato: BNO-GO-03-2019-01-MRO',
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(
      text: _emailController.text,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu correo y te enviaremos '
              'las instrucciones para restablecer tu contraseña.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(authRepositoryProvider)
                  .sendPasswordResetEmail(email: emailController.text.trim());

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Revisa tu correo para restablecer la contraseña'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}