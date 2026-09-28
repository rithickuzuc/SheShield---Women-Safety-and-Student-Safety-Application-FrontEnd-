import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

abstract final class SheShieldColors {
  static const wine = Color(0xFF79134C),
      rose = Color(0xFFFF3D8D),
      blush = Color(0xFFFFC8DF),
      violet = Color(0xFF7047EB),
      teal = Color(0xFF00B8B0),
      ink = Color(0xFF251425),
      gold = Color(0xFFFFB629),
      blue = Color(0xFF2475FF);
  static const rainbow = [
    Color(0xFFFF3D8D),
    Color(0xFFB52CF2),
    Color(0xFF2475FF),
    Color(0xFF00B8B0),
  ];
}

class SheShieldBackground extends StatefulWidget {
  const SheShieldBackground({super.key, required this.child});
  final Widget child;
  @override
  State<SheShieldBackground> createState() => _State();
}

class _State extends State<SheShieldBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );
  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    )) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    child: widget.child,
    builder: (_, child) => Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _MeshPainter(controller.value)),
        ...List.generate(12, (i) {
          final phase = controller.value * math.pi * 2 + i;
          return Positioned(
            left:
                ((i * 97 + math.sin(phase) * 42) %
                    (MediaQuery.sizeOf(context).width + 80)) -
                40,
            top:
                ((i * 137 + math.cos(phase * .7) * 60) %
                    (MediaQuery.sizeOf(context).height + 100)) -
                50,
            child: Transform.rotate(
              angle: phase * .25,
              child: Icon(
                i.isEven ? Icons.auto_awesome : Icons.favorite_rounded,
                size: 12 + (i % 4) * 6,
                color: SheShieldColors.rainbow[i % 4].withValues(alpha: .12),
              ),
            ),
          );
        }),
        child!,
      ],
    ),
  );
}

class _MeshPainter extends CustomPainter {
  _MeshPainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFD3E8),
          Color(0xFFFFB9E0),
          Color(0xFFD7C3FF),
          Color(0xFFAEDCFF),
          Color(0xFFADFFEA),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);
    final blobs = [
      (SheShieldColors.rose, .22, .10, 220.0),
      (SheShieldColors.violet, .80, .25, 260.0),
      (SheShieldColors.blue, .18, .72, 240.0),
      (SheShieldColors.teal, .78, .82, 280.0),
      (SheShieldColors.gold, .52, .48, 180.0),
    ];
    for (var i = 0; i < blobs.length; i++) {
      final b = blobs[i],
          a = t * math.pi * 2 + i * 1.7,
          x = size.width * (b.$2 + .12 * math.sin(a)),
          y = size.height * (b.$3 + .10 * math.cos(a * .8));
      final p = Paint()
        ..shader = RadialGradient(
          colors: [
            b.$1.withValues(alpha: .46),
            b.$1.withValues(alpha: .10),
            b.$1.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: b.$4));
      canvas.drawCircle(Offset(x, y), b.$4, p);
    }
    for (var i = 0; i < 4; i++) {
      final y =
          (size.height * (.13 + i * .25) + t * size.height * .22) % size.height;
      final beam = Paint()
        ..strokeWidth = 2 + i.toDouble()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            SheShieldColors.rainbow[i].withValues(alpha: .55),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, y, size.width, 4));
      canvas.drawLine(
        Offset(-40, y + 50),
        Offset(size.width + 40, y - 50),
        beam,
      );
    }
    final wave = Path()..moveTo(0, size.height * .32);
    for (double x = 0; x <= size.width; x += 12) {
      wave.lineTo(
        x,
        size.height * .32 + 24 * math.sin((x / 85) + (t * math.pi * 2)),
      );
    }
    wave.lineTo(size.width, size.height * .52);
    wave.lineTo(0, size.height * .48);
    wave.close();
    canvas.drawPath(wave, Paint()..color = Colors.white.withValues(alpha: .16));
  }

  @override
  bool shouldRepaint(covariant _MeshPainter old) => old.t != t;
}

class NeonGlass extends StatelessWidget {
  const NeonGlass({
    super.key,
    required this.child,
    this.colors = SheShieldColors.rainbow,
    this.padding = const EdgeInsets.all(20),
    this.radius = 26,
  });
  final Widget child;
  final List<Color> colors;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: colors.map((c) => c.withValues(alpha: .55)).toList(),
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: colors.first.withValues(alpha: .22),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    padding: const EdgeInsets.all(1.5),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius - 1),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          color: Colors.white.withValues(alpha: .78),
          child: child,
        ),
      ),
    ),
  );
}

class AnimatedEntrance extends StatelessWidget {
  const AnimatedEntrance({super.key, required this.child, this.delay = 0});
  final Widget child;
  final int delay;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(milliseconds: 650 + delay),
    curve: Curves.easeOutBack,
    builder: (_, v, child) => Opacity(
      opacity: v.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 32 * (1 - v)),
        child: Transform.scale(scale: .92 + .08 * v, child: child),
      ),
    ),
    child: child,
  );
}

class OrbitShield extends StatefulWidget {
  const OrbitShield({super.key});
  @override
  State<OrbitShield> createState() => _OrbitShieldState();
}

class _OrbitShieldState extends State<OrbitShield>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );
  @override
  void initState() {
    super.initState();
    if (!WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    )) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: _c.value * math.pi * 2,
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SheShieldColors.violet.withValues(alpha: .55),
                  width: 2,
                ),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: SheShieldColors.teal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: SheShieldColors.teal, blurRadius: 14),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: -_c.value * math.pi * 2 * .7,
            child: Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SheShieldColors.rose.withValues(alpha: .65),
                  width: 2,
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: SheShieldColors.gold,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: SheShieldColors.gold, blurRadius: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SheShieldColors.rose,
                  SheShieldColors.violet,
                  SheShieldColors.blue,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: SheShieldColors.rose,
                  blurRadius: 28,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    ),
  );
}

class GradientActionButton extends StatelessWidget {
  const GradientActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool loading;
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity: onPressed == null ? 0.55 : 1.0,
    duration: const Duration(milliseconds: 220),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                SheShieldColors.rose,
                SheShieldColors.violet,
                SheShieldColors.blue,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SheShieldColors.violet.withValues(alpha: .42),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          height: 58,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .3,
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

class SheShieldSectionTitle extends StatelessWidget {
  const SheShieldSectionTitle(
    this.title, {
    super.key,
    this.subtitle,
    this.icon,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (icon != null)
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [SheShieldColors.rose, SheShieldColors.violet],
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: SheShieldColors.rose.withValues(alpha: .3),
                blurRadius: 14,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
      if (icon != null) const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: SheShieldColors.ink,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: TextStyle(
                  color: SheShieldColors.ink.withValues(alpha: .62),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
