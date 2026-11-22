import 'dart:math';
import 'package:flutter/material.dart';

const ink = Color(0xFF4A3B5C), pink = Color(0xFFFF8FAB), sky = Color(0xFF7BDFF2), mint = Color(0xFF8EE08A), sun = Color(0xFFFFD166);
const EM = ['🔴', '🔵', '🟢', '🟡', '🟣', '🟠'];
const PC = [Color(0xFFFF6B6B), Color(0xFF4D96FF), Color(0xFF4DD4AC), Color(0xFFFFD93D), Color(0xFFC77DFF), Color(0xFFFF9F1C)];
final rnd = Random();
double cl(double v, double a, double b) => min(b, max(a, v));
TextStyle ts(double s, [Color c = ink]) => TextStyle(fontSize: s, fontWeight: FontWeight.w900, color: c);

Widget cart(Color c, {Widget? child, double r = 18, double? w, double? h, EdgeInsets? pad, double sh = 4}) => Container(
    width: w, height: h, padding: pad, alignment: Alignment.center,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r), border: Border.all(color: ink, width: 3), boxShadow: [BoxShadow(color: ink, offset: Offset(0, sh))]),
    child: child);

class Pressable extends StatefulWidget {
  final Widget child; final VoidCallback? onTap;
  const Pressable({super.key, required this.child, this.onTap});
  @override State<Pressable> createState() => _PressS();
}
class _PressS extends State<Pressable> {
  bool d = false;
  @override Widget build(BuildContext c) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => d = true),
      onTapUp: (_) { setState(() => d = false); widget.onTap?.call(); },
      onTapCancel: () => setState(() => d = false),
      child: AnimatedScale(scale: d ? .92 : 1, duration: const Duration(milliseconds: 90), child: widget.child));
}

Widget btn(String t, VoidCallback f, {Color c = pink}) => Pressable(onTap: f, child: IntrinsicWidth(child: cart(c, pad: const EdgeInsets.symmetric(horizontal: 22, vertical: 12), child: Text(t, style: ts(18, Colors.white)))));
Widget status(String s) => AnimatedSwitcher(duration: const Duration(milliseconds: 200), transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w), child: Text(s, key: ValueKey(s), textAlign: TextAlign.center, style: ts(20)));
Widget board(int cols, List<Widget> k, {double gap = 8}) => GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: cols, mainAxisSpacing: gap, crossAxisSpacing: gap, children: k);
Widget page(List<Widget> k, {bool scroll = true, double pad = 16}) {
  final col = Column(mainAxisSize: MainAxisSize.min, children: k);
  return Center(child: scroll ? SingleChildScrollView(padding: EdgeInsets.all(pad), child: col) : Padding(padding: EdgeInsets.all(pad), child: col));
}

Widget header(BuildContext c, String t, [Widget? tr]) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Row(children: [
      Pressable(onTap: () => Navigator.pop(c), child: cart(pink, w: 48, h: 48, child: const Icon(Icons.arrow_back_rounded, color: Colors.white))),
      const SizedBox(width: 12),
      Expanded(child: Text(t, style: ts(22))),
      if (tr != null) tr,
    ]));

class Bg extends StatefulWidget {
  final Widget child;
  const Bg({super.key, required this.child});
  @override State<Bg> createState() => _BgS();
}
class _BgS extends State<Bg> with SingleTickerProviderStateMixin {
  late final AnimationController a = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  @override void dispose() { a.dispose(); super.dispose(); }
  @override Widget build(BuildContext c) => Stack(children: [
        Positioned.fill(child: AnimatedBuilder(animation: a, builder: (_, __) => CustomPaint(painter: _BgP(a.value)))),
        widget.child,
      ]);
}
class _BgP extends CustomPainter {
  final double t;
  _BgP(this.t);
  @override void paint(Canvas cv, Size s) {
    cv.drawRect(Offset.zero & s, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFF3D6), Color(0xFFFFD6E8)]).createShader(Offset.zero & s));
    final r = Random(7);
    for (int i = 0; i < 14; i++) {
      final x = r.nextDouble() * s.width, y0 = r.nextDouble(), sz = 20 + r.nextDouble() * 50;
      final y = ((y0 - t * (.3 + (i % 3) * .15)) % 1.0) * s.height;
      cv.drawCircle(Offset(x + sin(t * 6.28 + i) * 14, y), sz, Paint()..color = Colors.white.withOpacity(.35));
    }
  }
  @override bool shouldRepaint(_BgP o) => o.t != t;
}

class GameScaffold extends StatefulWidget {
  final String title, icon; final Widget Function() build;
  const GameScaffold({super.key, required this.title, required this.icon, required this.build});
  @override State<GameScaffold> createState() => _GSS();
}
class _GSS extends State<GameScaffold> {
  int k = 0;
  @override Widget build(BuildContext c) => Scaffold(
      body: Bg(child: SafeArea(child: Column(children: [
        header(c, '${widget.icon} ${widget.title}', Pressable(onTap: () => setState(() => k++), child: cart(sky, w: 48, h: 48, child: const Icon(Icons.refresh_rounded, color: Colors.white)))),
        Expanded(child: KeyedSubtree(key: ValueKey(k), child: widget.build())),
      ]))));
}
