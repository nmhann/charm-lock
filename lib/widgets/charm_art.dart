// lib/widgets/charm_art.dart
//
// The small pictures: charms, candles, sockets and clue pegs.
// Each charm has its own color AND its own shape, so players who can't
// tell the colors apart can still tell the charms apart.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../game/charm_lock_game.dart';
import '../theme.dart';

/// Display name for each charm ("Mushroom", not "mushroom").
String charmName(Charm charm) {
  final n = charm.name;
  return n[0].toUpperCase() + n.substring(1);
}

/// Main color of each charm (used for the token outline).
Color charmColor(Charm charm) {
  switch (charm) {
    case Charm.acorn:
      return const Color(0xFFA06A3B);
    case Charm.leaf:
      return const Color(0xFF6F9B58);
    case Charm.mushroom:
      return const Color(0xFFC4473A);
    case Charm.moon:
      return const Color(0xFF7F97C4);
    case Charm.berry:
      return const Color(0xFF7A4A8C);
    case Charm.honey:
      return const Color(0xFFE2A23A);
  }
}

// The same drawings used in the Figma file, as SVG text (24 x 24 box).
const Map<Charm, String> _charmSvg = {
  Charm.acorn:
      '<path d="M12 2.3v2.5" stroke="#6B4425" stroke-width="1.8" stroke-linecap="round"/>'
      '<path d="M4.6 9.6c0-3 3.3-5.1 7.4-5.1s7.4 2.1 7.4 5.1c0 .8-.6 1.4-1.4 1.4H6c-.8 0-1.4-.6-1.4-1.4z" fill="#6B4425"/>'
      '<path d="M6.4 11.8h11.2c0 5.1-2.7 9-5.6 10.3-2.9-1.3-5.6-5.2-5.6-10.3z" fill="#A06A3B"/>',
  Charm.leaf:
      '<path d="M20.6 3.3C11.2 3.3 4 8.3 4 15.4c0 1.7.5 3.2 1.3 4.4 3.6-6.2 7.6-8.9 11.2-10.4-3.6 2.6-7 6.2-9.5 11.6 1.2.6 2.6.9 4 .9 6.6 0 9.6-6.1 9.6-18.6z" fill="#6F9B58"/>',
  Charm.mushroom:
      '<path d="M9 13.4h6l.6 6.4c.1 1.2-.8 2.2-2 2.2h-3.2c-1.2 0-2.1-1-2-2.2z" fill="#EADBC4" stroke="#C9B48F" stroke-width=".6"/>'
      '<path d="M2.4 12.1C2.4 6.8 6.7 2.8 12 2.8s9.6 4 9.6 9.3c0 .8-.6 1.3-1.4 1.3H3.8c-.8 0-1.4-.5-1.4-1.3z" fill="#C4473A"/>'
      '<circle cx="7.8" cy="8.6" r="1.5" fill="#F8EEDF"/><circle cx="14.4" cy="6.5" r="1.2" fill="#F8EEDF"/>'
      '<circle cx="16.8" cy="10.3" r="1.3" fill="#F8EEDF"/>',
  Charm.moon:
      '<path d="M21 13.2A9 9 0 1 1 10.8 3a7 7 0 0 0 10.2 10.2z" fill="#7F97C4"/>'
      '<circle cx="9" cy="14" r="1.2" fill="#566E9C" opacity=".5"/><circle cx="12.6" cy="17.4" r=".9" fill="#566E9C" opacity=".5"/>',
  Charm.berry:
      '<path d="M12 5.2c.4-1.7 1.8-2.8 3.8-2.9" stroke="#4E7440" stroke-width="1.8" stroke-linecap="round"/>'
      '<circle cx="12" cy="9.6" r="4.5" fill="#7A4A8C"/><circle cx="7.9" cy="15.4" r="4.5" fill="#7A4A8C"/>'
      '<circle cx="16.1" cy="15.4" r="4.5" fill="#7A4A8C"/><circle cx="10.6" cy="8.2" r="1" fill="#F8EEDF" opacity=".7"/>'
      '<circle cx="6.5" cy="14" r="1" fill="#F8EEDF" opacity=".7"/><circle cx="14.7" cy="14" r="1" fill="#F8EEDF" opacity=".7"/>',
  Charm.honey:
      '<path d="M12 2.4l8.3 4.8v9.6L12 21.6l-8.3-4.8V7.2z" fill="#E2A23A"/>'
      '<path d="M12 7.4l4.1 2.4v4.6L12 16.8l-4.1-2.4V9.8z" fill="#A86E14" opacity=".4"/>',
};

String _wrap(String inner) =>
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24">$inner</svg>';

/// Just the charm drawing, no circle around it.
class CharmIcon extends StatelessWidget {
  final Charm charm;
  final double size;

  const CharmIcon(this.charm, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_wrap(_charmSvg[charm]!), width: size, height: size);
  }
}

/// A charm sitting on a round linen token (used on the board and picker).
class CharmToken extends StatelessWidget {
  final Charm charm;
  final double size;
  final bool faded;

  const CharmToken(this.charm, {super.key, this.size = 56, this.faded = false});

  @override
  Widget build(BuildContext context) {
    // Fades smoothly when a charm becomes "In use" or free again.
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: faded ? 0.4 : 1,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.linen,
          border: Border.all(color: charmColor(charm).withAlpha(alpha(0.55)), width: 2),
          boxShadow: softShadow(),
        ),
        child: CharmIcon(charm, size: size * 0.6),
      ),
    );
  }
}

/// An empty hole in the board. [next] marks where the next charm will go.
/// [ghost] is a charm the lantern revealed: shown faintly as a reminder.
class EmptySocket extends StatelessWidget {
  final double size;
  final bool next;
  final Charm? ghost;

  const EmptySocket({super.key, this.size = 56, this.next = false, this.ghost});

  @override
  Widget build(BuildContext context) {
    final Border? border = next
        ? Border.all(color: AppColors.emberLight, width: 2.5)
        : ghost != null
            ? Border.all(color: AppColors.ember, width: 2)
            : null;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // darker at the top so it looks carved into the wood
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.socketDeep, AppColors.socket],
        ),
        border: border,
      ),
      child: ghost != null
          ? Opacity(opacity: 0.5, child: CharmIcon(ghost!, size: size * 0.55))
          : next
          ? Container(
              width: size * 0.16,
              height: size * 0.16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.emberLight,
              ),
            )
          : null,
    );
  }
}

/// The three kinds of clue peg. Each has a different SHAPE:
/// glowing filled dot, hollow ring, tiny dot.
enum PegKind { ember, ring, ash }

class CluePeg extends StatelessWidget {
  final PegKind kind;
  final double size;

  const CluePeg(this.kind, {super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    late final Widget peg;
    switch (kind) {
      case PegKind.ember:
        peg = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.ember,
            border: Border.all(color: AppColors.emberLight, width: 1.5),
            boxShadow: [BoxShadow(color: AppColors.ember.withAlpha(alpha(0.8)), blurRadius: 8)],
          ),
        );
        break;
      case PegKind.ring:
        peg = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.linen, width: size * 0.16),
          ),
        );
        break;
      case PegKind.ash:
        peg = Container(
          width: size * 0.44,
          height: size * 0.44,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ash),
        );
        break;
    }
    return SizedBox(width: size, height: size, child: Center(child: peg));
  }
}

/// A candle: lit (tries left) or burnt out (tries used).
class CandleIcon extends StatelessWidget {
  final bool lit;
  final double size;

  const CandleIcon({super.key, required this.lit, this.size = 30});

  static const _lit =
      '<rect x="8" y="10" width="8" height="11.5" rx="2.2" fill="#F3E3C7" stroke="#C9B48F" stroke-width=".8"/>'
      '<path d="M12 9.6v-1" stroke="#3A2C24" stroke-width="1.2" stroke-linecap="round"/>'
      '<path d="M12 2.2c2 2.1 2.8 3.5 2.8 4.8a2.8 2.8 0 0 1-5.6 0c0-1.3.8-2.7 2.8-4.8z" fill="#E8913A"/>'
      '<path d="M12 5c.8.9 1.1 1.5 1.1 2.1a1.1 1.1 0 0 1-2.2 0c0-.6.3-1.2 1.1-2.1z" fill="#FFD27A"/>';
  static const _out =
      '<rect x="8" y="15" width="8" height="6.5" rx="2.2" fill="#BFAE96"/>'
      '<path d="M12 15v-1.6" stroke="#5B4A3E" stroke-width="1.2" stroke-linecap="round"/>'
      '<path d="M13 12.5c1-.8 1-1.8.2-2.8" stroke="#8C7B6A" stroke-width="1" stroke-linecap="round" opacity=".7"/>';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_wrap(lit ? _lit : _out), width: size, height: size);
  }
}

/// The lantern used for the hint. [lit] = still available.
class LanternIcon extends StatelessWidget {
  final double size;
  final bool lit;
  const LanternIcon({super.key, this.size = 36, this.lit = true});

  @override
  Widget build(BuildContext context) {
    final glass = lit ? '#FFD48A' : '#D9CDB8';
    final flame = lit
        ? '<path d="M12 10.2c1.3 1.4 1.9 2.4 1.9 3.4a1.9 1.9 0 0 1-3.8 0c0-1 .6-2 1.9-3.4z" fill="#E8913A"/>'
        : '';
    return SvgPicture.string(
      _wrap('<path d="M9.5 3.2a2.5 2.5 0 0 1 5 0" stroke="#6B4425" stroke-width="1.5" fill="none" stroke-linecap="round"/>'
          '<rect x="7.5" y="4.6" width="9" height="2.4" rx="1" fill="#8C6040"/>'
          '<rect x="8" y="7" width="8" height="11" rx="2" fill="$glass" stroke="#8C6040" stroke-width="1.4"/>'
          '$flame'
          '<rect x="7" y="18" width="10" height="2.6" rx="1" fill="#8C6040"/>'),
      width: size,
      height: size,
    );
  }
}

/// The purple gem: the reward points.
class GemIcon extends StatelessWidget {
  final double size;
  const GemIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _wrap('<path d="M6.6 3.2h10.8l4.4 5.6L12 21.6 2.2 8.8z" fill="#6E45A8"/><path d="M2.2 8.8l4.4-5.6 2 5.6z" fill="#9A6FD3"/><path d="M6.6 3.2H12L8.6 8.8z" fill="#C3A3EE"/><path d="M12 3.2l3.4 5.6H8.6z" fill="#A47AD9"/><path d="M12 3.2h5.4l-2 5.6z" fill="#B994E8"/><path d="M17.4 3.2l4.4 5.6h-6.4z" fill="#8F63CC"/><path d="M2.2 8.8h6.4L12 21.6z" fill="#7F55BD"/><path d="M8.6 8.8h6.8L12 21.6z" fill="#9567CF"/><path d="M15.4 8.8h6.4L12 21.6z" fill="#6A41A3"/><path d="M7.6 4.6l1.1-1" stroke="#FFFFFF" stroke-width="1.1" stroke-linecap="round" opacity=".9"/><path d="M20.6 1.4l.5 1.3 1.3.5-1.3.5-.5 1.3-.5-1.3-1.3-.5 1.3-.5z" fill="#FFD27A"/>'),
      width: size,
      height: size,
    );
  }
}

/// The small ember picture next to the clue message.
class EmberIcon extends StatelessWidget {
  final double size;
  const EmberIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _wrap('<path d="M12 2.5c3 3.2 5.5 6 5.5 9.6a5.5 5.5 0 0 1-11 0c0-1.9.8-3.5 2-4.8.3 1.6 1 2.6 2 2.9-.2-2.6.3-5 1.5-7.7z" fill="#E8913A"/>'
          '<path d="M12 11c1.4 1.5 2.3 2.7 2.3 4a2.3 2.3 0 0 1-4.6 0c0-1.3.9-2.5 2.3-4z" fill="#FFD27A"/>'),
      width: size,
      height: size,
    );
  }
}
