import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../home/presentation/home_screen.dart';

class LaunchScreen extends ConsumerStatefulWidget {
  const LaunchScreen({super.key});

  @override
  ConsumerState<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ConsumerState<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconInScale;
  late final Animation<double> _iconPulseScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _bgBlend;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    _iconInScale = Tween<double>(begin: 0.74, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _iconPulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0),
        weight: 55,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.82, curve: Curves.easeInOutCubic),
      ),
    );

    _iconFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _bgBlend = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          _NoAnimationRoute(page: const HomeScreen()),
        );
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final chosenAccent = ref.watch(themeProvider.select((s) => s.accentColor));
    final onAccent =
        ThemeData.estimateBrightnessForColor(chosenAccent) == Brightness.dark
            ? Colors.white
            : Colors.black;
    final shortSide = MediaQuery.of(context).size.shortestSide;
    final iconSize = (shortSide * 0.30).clamp(96.0, 152.0).toDouble();

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final bgColor =
              Color.lerp(chosenAccent, colors.background, _bgBlend.value)!;
          final currentScale = _iconInScale.value * _iconPulseScale.value;

          return ColoredBox(
            color: bgColor,
            child: Center(
              child: RepaintBoundary(
                child: Opacity(
                  opacity: _iconFade.value,
                  child: Transform.scale(
                    scale: currentScale,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(onAccent, BlendMode.srcIn),
                      child: Image.asset(
                        'assets/images/app_icon_foreground.png',
                        width: iconSize,
                        height: iconSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NoAnimationRoute<T> extends PageRouteBuilder<T> {
  _NoAnimationRoute({required Widget page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
}
