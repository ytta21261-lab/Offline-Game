import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui.dart';

// ---------- Pop Balon ----------
class _Bl { double x, y, v; Color c; _Bl(this.x, this.y, this.v, this.c); }
class BalloonGame extends StatefulWidget {
  const BalloonGame({super.key});
  @override State<BalloonGame> createState() => _BalloonS();
}
class _BalloonS extends State<BalloonGame> {
  final bs = <_Bl>[]; final pops = <List<double>>[]; int sc = 0, lives = 5, tick = 0; double W = 1, H = 1; Timer? t;
  @override void initState() { super.initState(); t = Timer.periodic(const Duration(milliseconds: 33), (_) => _tick()); }
  @override void dispose() { t?.cancel(); super.dispose(); }
  void _tick() {
    if (lives <= 0) return;
    tick++;
    setState(() {
      if (tick % max(12, 30 - sc ~/ 4) == 0) bs.add(_Bl(.1 + rnd.nextDouble() * .8, 1.1, .005 + rnd.nextDouble() * .004 + sc * .00008, PC[rnd.nextInt(6)]));
      for (final b in bs) { b.y -= b.v; }
      bs.removeWhere((b) { if (b.y < -.15) { lives--; return true; } return false; });
      for (final p in pops) { p[2]--; }
      pops.removeWhere((p) => p[2] <= 0);
    });
  }
  Widget _bw(Color c) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 68,
            decoration: BoxDecoration(color: c, borderRadius: const BorderRadius.all(Radius.elliptical(28, 34)), border: Border.all(color: ink, width: 3)),
            child: Align(alignment: const Alignment(-.5, -.5), child: Container(width: 10, height: 18, decoration: BoxDecoration(color: Colors.white60, borderRadius: BorderRadius.circular(8))))),
        Container(width: 2, height: 22, color: ink),
      ]);
  @override Widget build(BuildContext c) => LayoutBuilder(builder: (c, k) {
        W = k.maxWidth; H = k.maxHeight;
        return Stack(children: [
          for (final b in bs) Positioned(left: b.x * W - 28, top: b.y * H, child: GestureDetector(
              onTapDown: (_) { Sfx.good(); setState(() { bs.remove(b); sc++; pops.add([b.x, b.y, 8]); }); }, child: _bw(b.c))),
          for (final p in pops) Positioned(left: p[0] * W - 24, top: p[1] * H, child: Transform.scale(scale: 1.6 - p[2] / 8, child: Tx('💥', style: TextStyle(fontSize: 40)))),
          Positioned(top: 10, left: 0, right: 0, child: Center(child: status('⭐ $sc    ${'❤️' * max(0, lives)}'))),
          if (lives <= 0) Center(child: cart(Colors.white, pad: const EdgeInsets.all(20), child: Tx('Game over 🎈\nSkor $sc\n(tekan 🔄)', textAlign: TextAlign.center, style: ts(26)))),
        ]);
      });
}

// ---------- Menara Tumpuk ----------
class StackGame extends StatefulWidget {
  const StackGame({super.key});
  @override State<StackGame> createState() => _StackS();
}
class _StackS extends State<StackGame> {
  final bl = <List<double>>[[.3, .4]]; double x = 0, w = .4, dir = 1, sp = .008; bool dead = false; Timer? t;
  @override void initState() {
    super.initState();
    t = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (dead) return;
      setState(() { x += dir * sp; if (x + w > 1) { x = 1 - w; dir = -1; } if (x < 0) { x = 0; dir = 1; } });
    });
  }
  @override void dispose() { t?.cancel(); super.dispose(); }
  void _tap() {
    if (dead) return;
    final l = bl.last; final o = min(x + w, l[0] + l[1]) - max(x, l[0]);
    if (o <= .01) { Sfx.bad(); setState(() => dead = true); return; }
    Sfx.good();
    setState(() { bl.add([max(x, l[0]), o]); w = o; sp = min(.03, sp + .0004); x = 0; dir = 1; });
  }
  @override Widget build(BuildContext c) => GestureDetector(
      behavior: HitTestBehavior.opaque, onTapDown: (_) => _tap(),
      child: Column(children: [
        const SizedBox(height: 8),
        status(dead ? 'Roboh! Tinggi ${bl.length - 1} 🧱 (tekan 🔄)' : 'Tinggi: ${bl.length - 1} — ketuk untuk menjatuhkan'),
        Expanded(child: Padding(padding: const EdgeInsets.all(14), child: CustomPaint(size: Size.infinite, painter: _StackP(bl, x, w, dead)))),
      ]));
}
class _StackP extends CustomPainter {
  final List<List<double>> bl; final double x, w; final bool dead;
  _StackP(this.bl, this.x, this.w, this.dead);
  @override void paint(Canvas cv, Size s) {
    final bg = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(20));
    cv.save(); cv.clipRRect(bg);
    cv.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFD0F0FF));
    const bh = 34.0; final off = max(0, bl.length - 8);
    for (int i = 0; i <= bl.length; i++) {
      if (i == bl.length && dead) continue;
      final b = i < bl.length ? bl[i] : [x, w];
      final y = s.height - (i + 1 - off) * bh;
      if (y > s.height) continue;
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(b[0] * s.width, y, b[1] * s.width, bh), const Radius.circular(8));
      cv.drawRRect(r, Paint()..color = HSLColor.fromAHSL(1, (i * 25.0) % 360, .8, .7).toColor());
      cv.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = ink);
    }
    cv.restore();
    cv.drawRRect(bg, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = ink);
  }
  @override bool shouldRepaint(_StackP o) => true;
}

// ---------- Burung Loncat ----------
class FlappyGame extends StatefulWidget {
  const FlappyGame({super.key});
  @override State<FlappyGame> createState() => _FlappyS();
}
class _FlappyS extends State<FlappyGame> {
  double W = 0, H = 0, by = 0, vy = 0; final p = <List<double>>[]; int sc = 0; bool dead = false, go = false; Timer? t;
  @override void initState() { super.initState(); t = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick()); }
  @override void dispose() { t?.cancel(); super.dispose(); }
  void _tick() {
    if (W == 0 || dead || !go) return;
    setState(() {
      vy += .55; by += vy;
      for (final q in p) { q[0] -= 2.6; }
      if (p.isEmpty || p.last[0] < W - 210) p.add([W, 90 + rnd.nextDouble() * max(10.0, H - 330), 0]);
      p.removeWhere((q) => q[0] < -70);
      for (final q in p) {
        if (q[2] == 0 && q[0] + 60 < 80) { q[2] = 1; sc++; Sfx.tap(); }
        if (q[0] < 114 && q[0] + 60 > 80 && (by < q[1] || by + 34 > q[1] + 160)) dead = true;
      }
      if (by < 0 || by + 34 > H - 30) dead = true;
    });
  }
  void _tap() { if (dead) return; if (!go) { go = true; by = H / 2; } vy = -8.5; }
  @override Widget build(BuildContext c) => LayoutBuilder(builder: (c, k) {
        W = k.maxWidth; H = k.maxHeight; if (!go) by = H / 2;
        return GestureDetector(
            behavior: HitTestBehavior.opaque, onTapDown: (_) => _tap(),
            child: ClipRect(child: Container(color: const Color(0xFFBFEBFF), child: Stack(children: [
              Positioned(top: 60, left: 40, child: Opacity(opacity: .7, child: Tx('☁️', style: ts(60)))),
              Positioned(top: 140, right: 30, child: Opacity(opacity: .7, child: Tx('☁️', style: ts(44)))),
              for (final q in p) ...[
                Positioned(left: q[0], top: -10, width: 60, height: q[1] + 10, child: cart(const Color(0xFF6BCB77), r: 10)),
                Positioned(left: q[0], top: q[1] + 160, width: 60, height: max(0.0, H - q[1] - 190), child: cart(const Color(0xFF6BCB77), r: 10)),
              ],
              Positioned(bottom: 0, left: 0, right: 0, height: 30, child: Container(decoration: const BoxDecoration(color: Color(0xFFE0B36B), border: Border(top: BorderSide(color: ink, width: 3))))),
              Positioned(left: 80, top: by, child: Transform.rotate(angle: cl(vy / 12, -.5, .8), child: Tx('🐥', style: TextStyle(fontSize: 34)))),
              Positioned(top: 12, left: 0, right: 0, child: Center(child: status(dead ? 'Game over! Skor $sc (tekan 🔄)' : go ? 'Skor $sc' : 'Ketuk untuk terbang!'))),
            ]))));
      });
}

// ---------- Geser Angka ----------
class SlideGame extends StatefulWidget {
  const SlideGame({super.key});
  @override State<SlideGame> createState() => _SlideS();
}
class _SlideS extends State<SlideGame> {
  final t = [1, 2, 3, 4, 5, 6, 7, 8, 0]; int moves = 0;
  List<int> _nb(int e) { final r = e ~/ 3, c = e % 3; return [if (r > 0) e - 3, if (r < 2) e + 3, if (c > 0) e - 1, if (c < 2) e + 1]; }
  @override void initState() {
    super.initState();
    int e = 8, prev = -1;
    for (int k = 0; k < 120; k++) {
      final n = _nb(e).where((x) => x != prev).toList(); final m = n[rnd.nextInt(n.length)];
      t[e] = t[m]; t[m] = 0; prev = e; e = m;
    }
  }
  bool get won { for (int i = 0; i < 8; i++) { if (t[i] != i + 1) return false; } return true; }
  void _tap(int i) {
    final e = t.indexOf(0);
    if (!won && _nb(e).contains(i)) { Sfx.tap(); setState(() { t[e] = t[i]; t[i] = 0; moves++; }); }
  }
  @override Widget build(BuildContext c) => page([
        status(won ? '🎉 Selesai dalam $moves langkah!' : 'Langkah: $moves'), const SizedBox(height: 12),
        cart(const Color(0xFFD9D2E9), r: 22, pad: const EdgeInsets.all(6), child: AspectRatio(aspectRatio: 1, child: LayoutBuilder(builder: (c, k) {
          final cs = k.maxWidth / 3;
          return Stack(children: [
            for (int v = 1; v <= 8; v++) AnimatedPositioned(
                key: ValueKey(v), duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
                left: (t.indexOf(v) % 3) * cs, top: (t.indexOf(v) ~/ 3) * cs, width: cs, height: cs,
                child: Padding(padding: const EdgeInsets.all(4), child: GestureDetector(onTap: () => _tap(t.indexOf(v)),
                    child: cart(HSLColor.fromAHSL(1, v * 40.0, .75, .75).toColor(), child: Tx('$v', style: ts(38)))))),
          ]);
        }))),
      ]);
}

// ---------- Cari Ranjau ----------
class MineGame extends StatefulWidget {
  const MineGame({super.key});
  @override State<MineGame> createState() => _MineS();
}
class _MineS extends State<MineGame> {
  final mine = List.filled(64, false), open = List.filled(64, false), flag = List.filled(64, false);
  bool first = true, dead = false, fm = false;
  List<int> _nbs(int i) {
    final r = i ~/ 8, c = i % 8;
    return [for (int a = -1; a <= 1; a++) for (int b = -1; b <= 1; b++) if ((a != 0 || b != 0) && r + a >= 0 && r + a < 8 && c + b >= 0 && c + b < 8) (r + a) * 8 + c + b];
  }
  int _n(int i) => _nbs(i).where((j) => mine[j]).length;
  bool get won => !dead && !first && List.generate(64, (i) => i).every((i) => mine[i] || open[i]);
  void _tap(int i) {
    if (dead || won || open[i]) return;
    if (fm) { setState(() => flag[i] = !flag[i]); return; }
    if (flag[i]) return;
    if (first) {
      first = false; int k = 0; final safe = [i, ..._nbs(i)];
      while (k < 10) { final j = rnd.nextInt(64); if (!mine[j] && !safe.contains(j)) { mine[j] = true; k++; } }
    }
    if (mine[i]) { Sfx.bad(); setState(() { dead = true; for (int j = 0; j < 64; j++) { if (mine[j]) open[j] = true; } }); return; }
    setState(() {
      final q = [i];
      while (q.isNotEmpty) { final x = q.removeLast(); if (open[x] || flag[x]) continue; open[x] = true; if (_n(x) == 0) q.addAll(_nbs(x)); }
    });
  }
  @override Widget build(BuildContext c) {
    const nc = [Colors.black, Color(0xFF1D7AFC), Color(0xFF2BA84A), Color(0xFFE63946), Color(0xFF7B2CBF), Color(0xFFFF7B00), Colors.teal, Colors.black, Colors.grey];
    return page([
      status(dead ? '💥 Kena ranjau! (tekan 🔄)' : won ? '🎉 Semua ranjau terhindar!' : '10 ranjau tersembunyi'), const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Pressable(onTap: () => setState(() => fm = false), child: cart(fm ? Colors.white : sun, pad: const EdgeInsets.all(10), child: Tx('⛏️ Gali', style: ts(16)))),
        const SizedBox(width: 12),
        Pressable(onTap: () => setState(() => fm = true), child: cart(fm ? sun : Colors.white, pad: const EdgeInsets.all(10), child: Tx('🚩 Bendera', style: ts(16)))),
      ]),
      const SizedBox(height: 12),
      board(8, [for (int i = 0; i < 64; i++) GestureDetector(onTap: () => _tap(i), onLongPress: () { if (!open[i] && !dead) setState(() => flag[i] = !flag[i]); },
          child: AnimatedContainer(duration: const Duration(milliseconds: 200), alignment: Alignment.center,
              decoration: BoxDecoration(color: open[i] ? (mine[i] ? const Color(0xFFFF9B9B) : const Color(0xFFFFF3D6)) : sky, borderRadius: BorderRadius.circular(8), border: Border.all(color: ink, width: 2)),
              child: Tx(open[i] ? (mine[i] ? '💣' : (_n(i) > 0 ? '${_n(i)}' : '')) : (flag[i] ? '🚩' : ''), style: ts(17, open[i] && !mine[i] ? nc[_n(i)] : ink))))], gap: 3),
    ]);
  }
}

// ---------- Warna Tipu ----------
class ColorGame extends StatefulWidget {
  const ColorGame({super.key});
  @override State<ColorGame> createState() => _ColorS();
}
class _ColorS extends State<ColorGame> {
  static const names = ['MERAH', 'BIRU', 'HIJAU', 'KUNING'];
  static const cols = [Color(0xFFE63946), Color(0xFF1D7AFC), Color(0xFF2BA84A), Color(0xFFF2B600)];
  int s = 0, t = 30, w = 0, c = 0, n = 0; Timer? tm;
  @override void initState() { super.initState(); _nx(); tm = Timer.periodic(const Duration(seconds: 1), (_) { if (t > 0) setState(() => t--); }); }
  @override void dispose() { tm?.cancel(); super.dispose(); }
  void _nx() { w = rnd.nextInt(4); c = rnd.nextInt(4); n++; }
  @override Widget build(BuildContext ctx) {
    if (t <= 0) return page([Tx('Selesai! 🌈', style: ts(34)), const SizedBox(height: 8), Tx('Skor $s', style: ts(28))]);
    return page([
      status('⏱ $t    ⭐ $s'), const SizedBox(height: 16),
      Tx('Apa WARNA tulisannya?', style: ts(16)), const SizedBox(height: 8),
      AnimatedSwitcher(duration: const Duration(milliseconds: 200), transitionBuilder: (a, an) => ScaleTransition(scale: an, child: a),
          child: Tx(names[w], key: ValueKey(n), style: ts(56, cols[c]))),
      const SizedBox(height: 20),
      board(2, [for (int i = 0; i < 4; i++) Pressable(
          onTap: () { setState(() { if (i == c) { s++; Sfx.good(); } else if (s > 0) { s--; } _nx(); }); },
          child: cart(Colors.white, child: Tx(names[i], style: ts(22))))], gap: 12),
    ]);
  }
}

// ---------- Ubin Piano ----------
class TilesGame extends StatefulWidget {
  const TilesGame({super.key});
  @override State<TilesGame> createState() => _TilesS();
}
class _TilesS extends State<TilesGame> {
  final rows = <List<int>>[]; int id = 0, s = 0, t = 20; bool started = false, over = false; Timer? tm;
  @override void initState() { super.initState(); for (int i = 0; i < 6; i++) { _add(); } }
  @override void dispose() { tm?.cancel(); super.dispose(); }
  void _add() { rows.add([id++, rnd.nextInt(4)]); }
  void _tap(int col) {
    if (over) return;
    if (!started) { started = true; tm = Timer.periodic(const Duration(seconds: 1), (_) { setState(() { t--; if (t <= 0) { over = true; tm?.cancel(); } }); }); }
    if (rows.first[1] == col) { Sfx.tap(); setState(() { rows.removeAt(0); _add(); s++; }); }
    else { Sfx.bad(); setState(() { over = true; tm?.cancel(); }); }
  }
  @override Widget build(BuildContext c) => Column(children: [
        const SizedBox(height: 8),
        status(over ? 'Selesai! Skor $s 🎹 (tekan 🔄)' : started ? '⏱ $t    ⭐ $s' : 'Ketuk kolom ubin hitam paling bawah!'),
        Expanded(child: Padding(padding: const EdgeInsets.all(12), child: LayoutBuilder(builder: (c, k) {
          final rh = k.maxHeight / 5;
          return GestureDetector(behavior: HitTestBehavior.opaque, onTapDown: (d) => _tap(min(3, max(0, (d.localPosition.dx / k.maxWidth * 4).floor()))),
              child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Container(
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: ink, width: 3), borderRadius: BorderRadius.circular(18)),
                  child: Stack(children: [
                    for (int i = 0; i < rows.length; i++) AnimatedPositioned(
                        key: ValueKey(rows[i][0]), duration: const Duration(milliseconds: 120), bottom: i * rh, left: 0, right: 0, height: rh,
                        child: Row(children: [for (int j = 0; j < 4; j++) Expanded(child: Container(margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(color: j == rows[i][1] ? ink : const Color(0xFFF1ECF7), borderRadius: BorderRadius.circular(10))))])),
                  ]))));
        }))),
      ]);
}

// ---------- Urut Angka ----------
class OrderGame extends StatefulWidget {
  const OrderGame({super.key});
  @override State<OrderGame> createState() => _OrderS();
}
class _OrderS extends State<OrderGame> {
  final n = List.generate(16, (i) => i + 1)..shuffle(); int next = 1, bad = -1; final sw = Stopwatch(); Timer? tm;
  @override void dispose() { tm?.cancel(); super.dispose(); }
  void _tap(int v) {
    if (next > 16) return;
    if (v == next) {
      if (next == 1) { sw.start(); tm = Timer.periodic(const Duration(milliseconds: 100), (_) => setState(() {})); }
      Sfx.tap();
      setState(() => next++);
      if (next > 16) { sw.stop(); tm?.cancel(); }
    } else {
      setState(() => bad = v);
      Future.delayed(const Duration(milliseconds: 300), () { if (mounted) setState(() => bad = -1); });
    }
  }
  @override Widget build(BuildContext c) {
    final tt = (sw.elapsedMilliseconds / 1000).toStringAsFixed(1);
    return page([
      status(next > 16 ? '🎉 Selesai dalam $tt detik!' : '⏱ $tt s    Cari angka: $next'), const SizedBox(height: 12),
      board(4, [for (final v in n) AnimatedScale(scale: v < next ? 0 : 1, duration: const Duration(milliseconds: 250), curve: Curves.easeIn,
          child: Pressable(onTap: () => _tap(v), child: cart(bad == v ? const Color(0xFFFF9B9B) : HSLColor.fromAHSL(1, v * 22.0, .7, .8).toColor(), child: Tx('$v', style: ts(26)))))]),
    ]);
  }
}

// ---------- Pingpong Bot ----------
class PongGame extends StatefulWidget {
  const PongGame({super.key});
  @override State<PongGame> createState() => _PongS();
}
class _PongS extends State<PongGame> {
  double W = 0, H = 0, px = 0, ox = 0, bx = 0, by = 0, vx = 0, vy = 0; int ps = 0, os = 0; bool init = false; Timer? t;
  static const pw = 80.0;
  @override void initState() { super.initState(); t = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick()); }
  @override void dispose() { t?.cancel(); super.dispose(); }
  void _reset(double dir) { bx = W / 2; by = H / 2; vx = (rnd.nextBool() ? 1 : -1) * 2.5; vy = dir * 3.5; }
  void _tick() {
    if (W == 0 || ps >= 5 || os >= 5) return;
    setState(() {
      if (!init) { init = true; px = ox = W / 2; _reset(1); }
      bx += vx; by += vy;
      if (bx < 10 || bx > W - 10) { vx = -vx; bx = cl(bx, 10, W - 10); }
      if (vy > 0 && by > H - 52 && by < H - 34 && (bx - px).abs() < pw / 2 + 10) { vy = cl(-vy * 1.06, -9, 9); vx = cl(vx + (bx - px) * .06, -7, 7); by = H - 52; Sfx.tap(); }
      if (vy < 0 && by < 52 && by > 34 && (bx - ox).abs() < pw / 2 + 10) { vy = cl(-vy * 1.06, -9, 9); vx = cl(vx + (bx - ox) * .06, -7, 7); by = 52; }
      ox += cl(bx - ox, -3.4, 3.4) * (vy < 0 ? 1 : .35);
      if (by > H) { os++; _reset(-1); }
      if (by < 0) { ps++; _reset(1); }
    });
  }
  @override Widget build(BuildContext c) => Padding(padding: const EdgeInsets.all(12), child: LayoutBuilder(builder: (c, k) {
        W = k.maxWidth; H = k.maxHeight;
        return GestureDetector(
            onPanUpdate: (d) => px = cl(d.localPosition.dx, pw / 2, W - pw / 2),
            child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(children: [
              CustomPaint(size: Size.infinite, painter: _PongP(px, ox, bx, by, init)),
              Positioned(left: 14, top: H / 2 - 40, child: Tx('$os', style: ts(40, ink.withOpacity(.4)))),
              Positioned(left: 14, top: H / 2 + 4, child: Tx('$ps', style: ts(40, ink.withOpacity(.4)))),
              if (ps >= 5 || os >= 5) Center(child: cart(Colors.white, pad: const EdgeInsets.all(18), child: Tx(ps >= 5 ? '🏆 Kamu menang!\n(tekan 🔄)' : '🤖 Bot menang!\n(tekan 🔄)', textAlign: TextAlign.center, style: ts(24)))),
            ])));
      }));
}
class _PongP extends CustomPainter {
  final double px, ox, bx, by; final bool init;
  _PongP(this.px, this.ox, this.bx, this.by, this.init);
  @override void paint(Canvas cv, Size s) {
    cv.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFD7F5E9));
    for (double x = 0; x < s.width; x += 24) { cv.drawRect(Rect.fromLTWH(x, s.height / 2 - 2, 12, 4), Paint()..color = ink.withOpacity(.35)); }
    RRect pad(double cx, double y) => RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, y), width: 80, height: 16), const Radius.circular(8));
    final st = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = ink;
    cv.drawRRect(pad(ox, 40), Paint()..color = pink); cv.drawRRect(pad(ox, 40), st);
    cv.drawRRect(pad(px, s.height - 40), Paint()..color = sky); cv.drawRRect(pad(px, s.height - 40), st);
    if (init) { cv.drawCircle(Offset(bx, by), 10, Paint()..color = sun); cv.drawCircle(Offset(bx, by), 10, st); }
    cv.drawRect(Offset.zero & s, st..strokeWidth = 6);
  }
  @override bool shouldRepaint(_PongP o) => true;
}
