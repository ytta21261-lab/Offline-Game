import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui.dart';

// ---------- Pasangan Ajaib (kartu membalik 3D) ----------
class MemoryGame extends StatefulWidget {
  const MemoryGame({super.key});
  @override State<MemoryGame> createState() => _MemoryS();
}
class _MemoryS extends State<MemoryGame> {
  late List<String> d;
  final up = List.filled(16, false), ok = List.filled(16, false);
  int? a; int moves = 0; bool lock = false;
  @override void initState() {
    super.initState();
    final e = '🐶🐱🦊🐸🐵🐼🦄🐙'.runes.map((r) => String.fromCharCode(r)).toList();
    d = [...e, ...e]..shuffle();
  }
  void _tap(int i) {
    if (lock || up[i] || ok[i]) return;
    setState(() => up[i] = true);
    if (a == null) { a = i; return; }
    final b = a!; a = null; moves++;
    if (d[b] == d[i]) {
      Sfx.good();
      setState(() { ok[b] = true; ok[i] = true; });
    } else {
      lock = true;
      Future.delayed(const Duration(milliseconds: 750), () {
        if (!mounted) return;
        setState(() { up[b] = false; up[i] = false; lock = false; });
      });
    }
  }
  Widget _card(int i) => GestureDetector(
      onTap: () => _tap(i),
      child: TweenAnimationBuilder<double>(
          tween: Tween(end: up[i] ? pi : 0.0), duration: const Duration(milliseconds: 350), curve: Curves.easeOut,
          builder: (c, v, _) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(v),
              child: v > pi / 2
                  ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: cart(ok[i] ? const Color(0xFFC9F2C7) : Colors.white, child: Tx(d[i], style: const TextStyle(fontSize: 34))))
                  : cart(pink, child: Tx('?', style: ts(32, Colors.white))))));
  @override Widget build(BuildContext c) => page([
        status(ok.every((x) => x) ? '🎉 Selesai dalam $moves langkah!' : 'Langkah: $moves'),
        const SizedBox(height: 12),
        board(4, List.generate(16, _card)),
      ]);
}

// ---------- 2048 ----------
class G2048 extends StatefulWidget {
  const G2048({super.key});
  @override State<G2048> createState() => _G2048S();
}
class _G2048S extends State<G2048> {
  final g = List.filled(16, 0); int sc = 0; bool over = false;
  @override void initState() { super.initState(); _add(); _add(); }
  void _add() {
    final z = [for (int i = 0; i < 16; i++) if (g[i] == 0) i];
    if (z.isNotEmpty) g[z[rnd.nextInt(z.length)]] = rnd.nextDouble() < .9 ? 2 : 4;
  }
  Color _c(int v) => v == 0 ? const Color(0xFFEFE6F7) : HSLColor.fromAHSL(1, (40 + log(v) / ln2 * 28) % 360, .9, .72).toColor();
  bool _stuck() {
    if (g.contains(0)) return false;
    for (int i = 0; i < 16; i++) {
      if (i % 4 < 3 && g[i] == g[i + 1]) return false;
      if (i < 12 && g[i] == g[i + 4]) return false;
    }
    return true;
  }
  void _move(int dx, int dy) {
    bool ch = false;
    for (int k = 0; k < 4; k++) {
      final L = List.generate(4, (j) => dx != 0 ? (dx > 0 ? k * 4 + 3 - j : k * 4 + j) : (dy > 0 ? (3 - j) * 4 + k : j * 4 + k));
      final v = [for (final i in L) if (g[i] != 0) g[i]];
      final o = <int>[];
      for (int j = 0; j < v.length; j++) {
        if (j + 1 < v.length && v[j] == v[j + 1]) { o.add(v[j] * 2); sc += v[j] * 2; j++; } else { o.add(v[j]); }
      }
      while (o.length < 4) { o.add(0); }
      for (int j = 0; j < 4; j++) { if (g[L[j]] != o[j]) ch = true; g[L[j]] = o[j]; }
    }
    if (ch) { _add(); Sfx.tap(); }
    setState(() => over = _stuck());
  }
  @override Widget build(BuildContext c) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanEnd: (d) {
        final v = d.velocity.pixelsPerSecond;
        if (v.distance < 200) return;
        if (v.dx.abs() > v.dy.abs()) { _move(v.dx > 0 ? 1 : -1, 0); } else { _move(0, v.dy > 0 ? 1 : -1); }
      },
      child: page(scroll: false, [
        status(over ? 'Game over! Skor $sc 😵' : 'Skor: $sc  — geser layar!'),
        const SizedBox(height: 12),
        board(4, [for (final v in g) AnimatedContainer(
            duration: const Duration(milliseconds: 150), alignment: Alignment.center,
            decoration: BoxDecoration(color: _c(v), borderRadius: BorderRadius.circular(14), border: Border.all(color: ink, width: 3)),
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 150), transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                child: Tx(v == 0 ? '' : '$v', key: ValueKey(v), style: ts(v > 99 ? 22 : 28))))]),
      ]));
}

// ---------- Tikus Usil ----------
class WhackGame extends StatefulWidget {
  const WhackGame({super.key});
  @override State<WhackGame> createState() => _WhackS();
}
class _WhackS extends State<WhackGame> {
  int s = 0, t = 30, h = -1; Timer? a, b;
  @override void initState() {
    super.initState();
    a = Timer.periodic(const Duration(milliseconds: 700), (_) { if (t > 0) setState(() => h = rnd.nextInt(9)); });
    b = Timer.periodic(const Duration(seconds: 1), (_) { if (t > 0) setState(() { t--; if (t == 0) h = -1; }); });
  }
  @override void dispose() { a?.cancel(); b?.cancel(); super.dispose(); }
  @override Widget build(BuildContext c) => page([
        status(t > 0 ? '⏱ $t    ⭐ $s' : 'Selesai! Skor $s 🎉'),
        const SizedBox(height: 12),
        board(3, [for (int i = 0; i < 9; i++) GestureDetector(
            onTapDown: (_) { if (i == h && t > 0) { Sfx.good(); setState(() { s++; h = -1; }); } },
            child: cart(const Color(0xFF9C6B4E), r: 100, child: AnimatedScale(scale: h == i ? 1 : 0, duration: const Duration(milliseconds: 250), curve: Curves.elasticOut, child: Tx('🐹', style: TextStyle(fontSize: 44)))))]),
      ]);
}

// ---------- Simon Warna ----------
class SimonGame extends StatefulWidget {
  const SimonGame({super.key});
  @override State<SimonGame> createState() => _SimonS();
}
class _SimonS extends State<SimonGame> {
  final q = <int>[]; int p = 0, lit = -1; bool ok = false; String msg = 'Tekan Mulai';
  Future<void> _play() async {
    ok = false; p = 0; q.add(rnd.nextInt(4));
    setState(() => msg = 'Perhatikan… level ${q.length}');
    await Future.delayed(const Duration(milliseconds: 500));
    for (final x in q) {
      if (!mounted) return;
      setState(() => lit = x);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => lit = -1);
      await Future.delayed(const Duration(milliseconds: 250));
    }
    if (!mounted) return;
    setState(() { ok = true; msg = 'Giliranmu!'; });
  }
  Future<void> _tap(int i) async {
    if (!ok) return;
    Sfx.tap();
    setState(() => lit = i);
    Future.delayed(const Duration(milliseconds: 180), () { if (mounted) setState(() => lit = -1); });
    if (q[p] != i) { setState(() { ok = false; msg = 'Salah! Skor ${q.length - 1} 😵'; }); return; }
    p++;
    if (p == q.length) { ok = false; await Future.delayed(const Duration(milliseconds: 650)); if (mounted) _play(); }
  }
  @override Widget build(BuildContext c) {
    const cols = [Color(0xFFFF6B6B), Color(0xFF4DD4AC), Color(0xFF4D96FF), Color(0xFFFFD93D)];
    return page([
      status(msg), const SizedBox(height: 12),
      board(2, [for (int i = 0; i < 4; i++) GestureDetector(
          onTapDown: (_) => _tap(i),
          child: AnimatedScale(scale: lit == i ? 1.06 : 1, duration: const Duration(milliseconds: 100),
              child: AnimatedOpacity(opacity: lit == i ? 1 : .6, duration: const Duration(milliseconds: 100), child: cart(cols[i], r: 28))))]),
      const SizedBox(height: 12),
      if (q.isEmpty || msg.startsWith('Salah')) btn('▶ Mulai', () { q.clear(); _play(); }),
    ]);
  }
}

// ---------- Kilat Hitung ----------
class MathGame extends StatefulWidget {
  const MathGame({super.key});
  @override State<MathGame> createState() => _MathS();
}
class _MathS extends State<MathGame> {
  int s = 0, t = 30, a = 0, b = 0, ans = 0; bool m = false; List<int> o = []; Timer? tm;
  @override void initState() {
    super.initState(); _nx();
    tm = Timer.periodic(const Duration(seconds: 1), (_) { if (t > 0) setState(() => t--); });
  }
  @override void dispose() { tm?.cancel(); super.dispose(); }
  void _nx() {
    a = 1 + rnd.nextInt(12); b = 1 + rnd.nextInt(12); m = rnd.nextBool(); ans = m ? a * b : a + b;
    final x = <int>{ans};
    while (x.length < 3) { x.add(max(0, ans + rnd.nextInt(11) - 5)); }
    o = x.toList()..shuffle();
  }
  @override Widget build(BuildContext c) {
    if (t <= 0) return page([Tx('Selesai! 🎉', style: ts(34)), const SizedBox(height: 8), Tx('Skor $s', style: ts(28))]);
    return page([
      status('⏱ $t    ⭐ $s'), const SizedBox(height: 10),
      ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: t / 30, minHeight: 12, color: pink, backgroundColor: Colors.white)),
      const SizedBox(height: 16),
      AnimatedSwitcher(duration: const Duration(milliseconds: 250), transitionBuilder: (w, an) => ScaleTransition(scale: an, child: w),
          child: Tx('$a ${m ? '×' : '+'} $b', key: ValueKey('$a-$b-$m-$s'), style: ts(54))),
      const SizedBox(height: 16),
      for (final v in o) Padding(padding: const EdgeInsets.only(bottom: 12), child: Pressable(
          onTap: () { setState(() { if (v == ans) { s++; Sfx.good(); } _nx(); }); },
          child: cart(Colors.white, w: double.infinity, h: 62, child: Tx('$v', style: ts(30))))),
    ]);
  }
}

// ---------- Ular Lapar ----------
class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});
  @override State<SnakeGame> createState() => _SnakeS();
}
class _SnakeS extends State<SnakeGame> {
  final s = <Point<int>>[const Point(7, 7)]; Point<int> d = const Point(1, 0), f = const Point(3, 3);
  int sc = 0; bool dead = false; Timer? t;
  @override void initState() { super.initState(); t = Timer.periodic(const Duration(milliseconds: 160), (_) => _tick()); }
  @override void dispose() { t?.cancel(); super.dispose(); }
  void _tick() {
    if (dead) return;
    final h = s.first + d;
    if (h.x < 0 || h.y < 0 || h.x > 14 || h.y > 14 || s.contains(h)) { Sfx.bad(); setState(() => dead = true); return; }
    setState(() {
      s.insert(0, h);
      if (h == f) { sc++; f = Point(rnd.nextInt(15), rnd.nextInt(15)); Sfx.tap(); } else { s.removeLast(); }
    });
  }
  void _dir(int x, int y) { if (x != -d.x || y != -d.y) d = Point(x, y); }
  @override Widget build(BuildContext c) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanEnd: (e) {
        final v = e.velocity.pixelsPerSecond;
        if (v.distance < 150) return;
        if (v.dx.abs() > v.dy.abs()) { _dir(v.dx > 0 ? 1 : -1, 0); } else { _dir(0, v.dy > 0 ? 1 : -1); }
      },
      child: page(scroll: false, [
        status(dead ? 'Game over 🐍 Skor $sc' : 'Skor $sc — geser untuk belok'),
        const SizedBox(height: 12),
        AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _SnakeP(List.of(s), f))),
      ]));
}
class _SnakeP extends CustomPainter {
  final List<Point<int>> s; final Point<int> f;
  _SnakeP(this.s, this.f);
  @override void paint(Canvas cv, Size size) {
    final c = size.width / 15;
    final bg = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18));
    cv.save(); cv.clipRRect(bg);
    cv.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE8FFF0));
    for (int i = 0; i < 15; i++) { for (int j = 0; j < 15; j++) { if ((i + j) % 2 == 0) cv.drawRect(Rect.fromLTWH(i * c, j * c, c, c), Paint()..color = const Color(0xFFD4F7E0)); } }
    cv.restore();
    final fc = Offset((f.x + .5) * c, (f.y + .55) * c);
    cv.drawCircle(fc, c * .38, Paint()..color = const Color(0xFFFF5D5D));
    cv.drawCircle(fc, c * .38, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = ink);
    cv.drawOval(Rect.fromCenter(center: fc + Offset(c * .15, -c * .38), width: c * .3, height: c * .16), Paint()..color = const Color(0xFF2BA84A));
    for (int i = s.length - 1; i >= 0; i--) {
      final p = s[i];
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(p.x * c + c * .06, p.y * c + c * .06, c * .88, c * .88), Radius.circular(c * .35));
      cv.drawRRect(r, Paint()..color = i == 0 ? const Color(0xFF2A9D8F) : Color.lerp(const Color(0xFF4DD4AC), const Color(0xFF8EE0C4), (i % 4) / 4)!);
      cv.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = ink);
      if (i == 0) {
        for (final dx in [-.2, .2]) {
          final e = Offset((p.x + .5 + dx) * c, (p.y + .42) * c);
          cv.drawCircle(e, c * .13, Paint()..color = Colors.white);
          cv.drawCircle(e, c * .06, Paint()..color = ink);
        }
      }
    }
    cv.drawRRect(bg, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = ink);
  }
  @override bool shouldRepaint(_SnakeP o) => true;
}

// ---------- Lampu Padam ----------
class LightsGame extends StatefulWidget {
  const LightsGame({super.key});
  @override State<LightsGame> createState() => _LightsS();
}
class _LightsS extends State<LightsGame> {
  final g = List.filled(25, false); int mv = 0;
  @override void initState() { super.initState(); for (int k = 0; k < 14; k++) { _tg(rnd.nextInt(25)); } if (!g.contains(true)) g[12] = true; }
  void _tg(int i) {
    final x = i % 5, y = i ~/ 5;
    for (final o in const [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]) {
      final X = x + o[0], Y = y + o[1];
      if (X >= 0 && X < 5 && Y >= 0 && Y < 5) g[Y * 5 + X] = !g[Y * 5 + X];
    }
  }
  @override Widget build(BuildContext c) => page([
        status(g.contains(true) ? 'Matikan semua lampu! Langkah $mv' : '🎉 Menang dalam $mv langkah!'),
        const SizedBox(height: 12),
        board(5, [for (int i = 0; i < 25; i++) GestureDetector(
            onTap: () { Sfx.tap(); setState(() { _tg(i); mv++; }); },
            child: AnimatedContainer(duration: const Duration(milliseconds: 250), alignment: Alignment.center,
                decoration: BoxDecoration(color: g[i] ? const Color(0xFFFFE066) : const Color(0xFFD9D2E9), borderRadius: BorderRadius.circular(16), border: Border.all(color: ink, width: 3),
                    boxShadow: g[i] ? [BoxShadow(color: const Color(0xFFFFD93D).withOpacity(.8), blurRadius: 14)] : []),
                child: AnimatedScale(scale: g[i] ? 1 : 0, duration: const Duration(milliseconds: 250), curve: Curves.elasticOut, child: Tx('💡', style: TextStyle(fontSize: 28)))))], gap: 6),
      ]);
}
