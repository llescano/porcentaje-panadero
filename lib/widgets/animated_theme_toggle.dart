import 'package:flutter/material.dart';

/// Widget animado que muestra una transición suave entre luna y sol
/// cuando se cambia el tema de la aplicación
class AnimatedThemeToggle extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const AnimatedThemeToggle({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  State<AnimatedThemeToggle> createState() => _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends State<AnimatedThemeToggle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador de animación con duración de 1 segundo
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Animación de rotación para el efecto de transición
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Animación de escala para efecto de pulsación
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Animación de color para transición suave usando colores del tema
    _colorAnimation = ColorTween(
      begin: const Color(0xFFD2691E), // Chocolate claro para el sol
      end: const Color(0xFF8D6E63),   // Brown 400 para la luna
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Establecer estado inicial basado en el tema actual
    if (widget.isDark) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedThemeToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animar cuando cambia el estado del tema
    if (oldWidget.isDark != widget.isDark) {
      if (widget.isDark) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: widget.onToggle,
      icon: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.14159, // Rotación completa
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _colorAnimation.value,
                  boxShadow: [
                    BoxShadow(
                      color: (_colorAnimation.value ?? const Color(0xFFD2691E))
                          .withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  _getIcon(),
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Determina qué icono mostrar basado en el progreso de la animación
  IconData _getIcon() {
    if (_controller.value < 0.5) {
      return Icons.wb_sunny; // Sol
    } else {
      return Icons.nightlight_round; // Luna
    }
  }
}