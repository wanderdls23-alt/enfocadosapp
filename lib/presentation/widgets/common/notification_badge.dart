import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_colors.dart';
import '../../providers/notification_provider.dart';

class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final bool showZero;
  final Color? badgeColor;
  final Color? textColor;
  final double? size;
  final EdgeInsetsGeometry? padding;

  const NotificationBadge({
    super.key,
    required this.child,
    this.showZero = false,
    this.badgeColor,
    this.textColor,
    this.size,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    if (unreadCount == 0 && !showZero) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -8,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: padding ?? const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: badgeColor ?? AppColors.gold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: BoxConstraints(
              minWidth: size ?? 18,
              minHeight: size ?? 18,
            ),
            child: unreadCount > 0
                ? Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: unreadCount > 99 ? 8 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// Widget simplificado para solo mostrar un punto indicador
class NotificationDot extends ConsumerWidget {
  final Widget child;
  final Color? dotColor;
  final double? size;
  final bool animate;

  const NotificationDot({
    super.key,
    required this.child,
    this.dotColor,
    this.size,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNotifications = ref.watch(hasNewNotificationsProvider);

    if (!hasNotifications) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -4,
          top: -4,
          child: animate
              ? _AnimatedDot(
                  color: dotColor ?? AppColors.gold,
                  size: size ?? 8,
                )
              : Container(
                  width: size ?? 8,
                  height: size ?? 8,
                  decoration: BoxDecoration(
                    color: dotColor ?? AppColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// Punto animado con efecto de pulso
class _AnimatedDot extends StatefulWidget {
  final Color color;
  final double size;

  const _AnimatedDot({
    required this.color,
    required this.size,
  });

  @override
  State<_AnimatedDot> createState() => __AnimatedDotState();
}

class __AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4),
                blurRadius: 4 * _animation.value,
                spreadRadius: 1 * _animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget para mostrar el contador en una barra de navegación
class NavigationBadge extends ConsumerWidget {
  final int index;
  final Widget icon;
  final Widget? activeIcon;

  const NavigationBadge({
    super.key,
    required this.index,
    required this.icon,
    this.activeIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Solo mostrar badge en la pestaña de notificaciones (asumiendo que es el índice 3)
    if (index != 3) {
      return icon;
    }

    return NotificationBadge(
      child: icon,
    );
  }
}