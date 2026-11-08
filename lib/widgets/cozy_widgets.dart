// lib/widgets/cozy_widgets.dart
//
// Small building blocks reused on every screen: the pill buttons,
// the cream cards and the soft background shapes.

import 'package:flutter/material.dart';

import '../services/gem_bank.dart';
import '../services/sound_service.dart';
import '../theme.dart';
import 'charm_art.dart';
import 'motion.dart';

enum CozyButtonStyle { primary, outline }

/// Round outlined icon button (used for sound and, on phones, Start over).
class CozyIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  const CozyIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(side: BorderSide(color: AppColors.bark, width: 2)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: AppColors.bark, size: size * 0.46, semanticLabel: tooltip),
          ),
        ),
      ),
    );
  }
}

/// The speaker button. It rebuilds itself whenever sound is turned on/off.
class SoundToggle extends StatelessWidget {
  final double size;
  const SoundToggle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final sound = SoundService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: sound.enabled,
      builder: (context, on, _) => CozyIconButton(
        icon: on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        tooltip: on ? 'Sound on (tap to mute)' : 'Sound off (tap to turn on)',
        onPressed: sound.toggle,
        size: size,
      ),
    );
  }
}

/// A rounded pill button. Pass `onPressed: null` to disable it:
/// it turns grey and can't be tapped (that's how we prevent invalid moves).
class CozyButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final CozyButtonStyle style;
  final double height;
  final bool expand;

  const CozyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = CozyButtonStyle.primary,
    this.height = 60,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final isPrimary = style == CozyButtonStyle.primary;

    final Color bg = !enabled
        ? AppColors.disabledBg
        : isPrimary
            ? AppColors.pine
            : Colors.transparent;
    final Color fg = !enabled
        ? AppColors.disabledFg
        : isPrimary
            ? AppColors.linen
            : AppColors.bark;
    final shape = StadiumBorder(
      side: isPrimary || !enabled
          ? BorderSide.none
          : const BorderSide(color: AppColors.bark, width: 2),
    );

    // FittedBox shrinks the label a little if the button is squeezed,
    // instead of overflowing.
    final content = Center(
      widthFactor: expand ? null : 1,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: fg, size: height * 0.38),
              SizedBox(width: height * 0.16),
            ],
            Text(label, style: heading(height * 0.36, weight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height),
        // a hard "pressable" shadow under the main button only
        boxShadow: enabled && isPrimary
            ? [BoxShadow(color: const Color(0xFF1F3326).withAlpha(alpha(0.35)), offset: const Offset(0, 6))]
            : null,
      ),
      child: Material(
        color: bg,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: height * 0.42),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// The cream rounded card used for the status, picker and how-to-play.
class CozyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final Border? border;

  const CozyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(26, 22, 26, 22),
    this.color = AppColors.linen,
    this.radius = 30,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: child,
    );
  }
}

/// The sage page background with two big soft circles behind everything.
class CozyBackground extends StatelessWidget {
  final Widget child;
  const CozyBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.moss),
        Positioned(
          left: -180,
          bottom: -200,
          child: _blob(560, AppColors.mossDeep),
        ),
        Positioned(
          right: -140,
          top: -220,
          child: _blob(480, AppColors.sand.withAlpha(alpha(0.7))),
        ),
        SafeArea(child: child),
      ],
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

/// The gem total in a small pill. It listens to GemBank, so it
/// updates (with a little pop) whenever gems are added.
class GemCounter extends StatelessWidget {
  final bool compact;
  const GemCounter({super.key, this.compact = false});

  static const _purple = Color(0xFF7B4FB5);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: GemBank.instance.total,
      builder: (context, gems, _) => Tooltip(
        message: 'Gems: you earn one for every candle still lit when you win',
        child: Semantics(
          label: '$gems gems',
          excludeSemantics: true,
          child: Container(
            height: compact ? 38 : 48,
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
            decoration: BoxDecoration(
              color: AppColors.linen,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: _purple.withAlpha(alpha(0.5)), width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GemIcon(size: compact ? 20 : 24),
                const SizedBox(width: 6),
                // the key changes with the number, so PopIn plays each time it grows
                PopIn(
                  key: ValueKey(gems),
                  child: Text('$gems', style: heading(compact ? 17 : 20, weight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
