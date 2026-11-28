import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'ui.dart';

// ===== Kerangka multiplayer satu HP =====
class LocalScreen extends StatefulWidget {
  final String title, icon; final Widget Function(int) build;
  const LocalScreen({super.key, required this.title, required this.icon, required this.build});
  @override State<LocalScreen> createState() => _LocalS();
}
class _LocalS extends State<LocalScreen> {
  int? n; int k = 0;
  Widget _pick() => page([
        Tx('Berapa pemain?', style: ts(28)), const SizedBox(height: 8),
        Tx('Satu HP, main bareng!', style: ts(15, const Color(0xFF8A7A9B))), const SizedBox(height: 20),
        for (int i = 2; i <= 4; i++) Padding(padding: const EdgeInsets.only(bottom: 14), child: Pressable(onTap: () => setState(() => n = i), child: cart(PC[i - 1], w: 240, h: 72, child: Tx('👥 $i Pemain', style: ts(24, Colors.white))))),
      ]);
  @override Widget build(BuildContext c) => Scaffold(body: Bg(child: SafeArea(child: Column(children: [
        header(c, '${widget.icon} ${widget.title}', n == null ? null : Row(mainAxisSize: MainAxisSize.min, children: [
          Pressable(onTap: () => setState(() => n = null), child: cart(sun, w: 48, h: 48, child: const Text('👥', style: TextStyle(fontSize: 22)))),
          const SizedBox(width: 8),
          Pressable(onTap: () => setState(() => k++), child: cart(sky, w: 48, h: 48, child: const Icon(Icons.refresh_rounded, color: Colors.white))),
        ])),
        Expanded(child: n == null ? _pick() : KeyedSubtree(key: ValueKey('$n-$k'), child: widget.build(n!))),
      ]))));
}

mixin Cd<T extends StatefulWidget> on State<T> {
  int cd = 3; Timer? _ct;
  void startCd(VoidCallback go) {
    _ct = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => cd--);
      if (cd <= 0) { t.cancel(); go(); }
    });
  }
  @override void dispose() { _ct?.cancel(); super.dispose(); }
}

String wtxt(List<num> s, {bool low = false}) {
  final b = s.reduce((x, y) => low ? min(x, y) : max(x, y));
  final w = [for (int i = 0; i < s.length; i++) if (s[i] == b) i];
  return w.length == 1 ? '🏆 ${EM[w[0]]} P${w[0] + 1} menang!' : '🤝 Seri!';
}
Widget? mb(String s) => s.isEmpty ? null : cart(Colors.white, pad: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), child: Tx(s, style: ts(24)));
Widget zone(int p, Widget child, {VoidCallback? onDown, Color? col}) => GestureDetector(
    behavior: HitTestBehavior.opaque, onTapDown: (_) => onDown?.call(),
    child: cart(col ?? PC[p].withOpacity(.88), r: 24, child: child));
Widget zones(int n, Widget Function(int) f, {Widget? mid}) {
  Widget z(int p, bool flip) { final w = f(p); return Expanded(child: Padding(padding: const EdgeInsets.all(5), child: flip ? RotatedBox(quarterTurns: 2, child: w) : w)); }
  final Widget col = n == 2 ? Column(children: [z(0, true), z(1, false)])
      : n == 3 ? Column(children: [z(0, true), Expanded(child: Row(children: [z(1, false), z(2, false)]))])
      : Column(children: [Expanded(child: Row(children: [z(0, true), z(1, true)])), Expanded(child: Row(children: [z(2, false), z(3, false)]))]);
  return Stack(fit: StackFit.expand, children: [col, if (mid != null) Center(child: mid)]);
}
TextStyle big([double s = 56]) => ts(s, Colors.white);

// ===== 21 Adu Ketuk =====
class TapRace extends StatefulWidget {
  final int n; const TapRace(this.n, {super.key});
  @override State<TapRace> createState() => _TapRaceS();
}
class _TapRaceS extends State<TapRace> with Cd<TapRace> {
  late final List<int> sc = List.filled(widget.n, 0); int t = 10; bool run = false, done = false; Timer? tm;
  @override void initState() {
    super.initState();
    startCd(() {
      setState(() => run = true);
      tm = Timer.periodic(const Duration(seconds: 1), (_) { if (!mounted) return; setState(() { t--; if (t <= 0) { run = false; done = true; tm?.cancel(); Sfx.win(); } }); });
    });
  }
  @override void dispose() { tm?.cancel(); super.dispose(); }
  @override Widget build(BuildContext c) => zones(widget.n, (p) => zone(p, Tx('${sc[p]}', style: big(64)), onDown: () { if (run) { Sfx.tap(); setState(() => sc[p]++); } }),
      mid: mb(done ? wtxt(sc) : run ? '⏱ $t' : cd > 0 ? '$cd' : ''));
}

// ===== 22 Tarik Tambang =====
class TugGame extends StatefulWidget {
  final int n; const TugGame(this.n, {super.key});
  @override State<TugGame> createState() => _TugS();
}
class _TugS extends State<TugGame> with Cd<TugGame> {
  double pos = 0; bool done = false;
  bool _top(int p) => widget.n == 4 ? p < 2 : p == 0;
  @override void initState() { super.initState(); startCd(() {}); }
  @override Widget build(BuildContext c) => zones(widget.n, (p) => zone(p, Tx(_top(p) ? '⬆️ Tarik!' : '⬇️ Tarik!', style: big(34)), onDown: () {
        if (cd > 0 || done) return;
        Sfx.tap(); setState(() { pos += _top(p) ? -.035 : .035; if (pos.abs() >= 1) { done = true; Sfx.win(); } });
      }), mid: done ? mb(pos < 0 ? '🏆 Tim Atas menang!' : '🏆 Tim Bawah menang!') : cd > 0 ? mb('$cd') : SizedBox(width: 50, height: 220, child: Stack(children: [
        Center(child: Container(width: 8, color: ink)),
        Positioned(top: (pos + 1) / 2 * 176, left: 0, right: 0, child: cart(sun, h: 44, r: 14, child: const Text('🚩', style: TextStyle(fontSize: 24)))),
      ])));
}

// ===== 23 Reaksi Kilat =====
class ReactGame extends StatefulWidget {
  final int n; const ReactGame(this.n, {super.key});
  @override State<ReactGame> createState() => _ReactS();
}
class _ReactS extends State<ReactGame> with Cd<ReactGame> {
  late final List<int> sc = List.filled(widget.n, 0); List<bool> lock = []; String ph = 'wait', msg = ''; Timer? tm;
  @override void initState() { super.initState(); lock = List.filled(widget.n, false); startCd(_next); }
  @override void dispose() { tm?.cancel(); super.dispose(); }
  void _next() {
    if (!mounted) return;
    setState(() { ph = 'wait'; lock = List.filled(widget.n, false); msg = ''; });
    tm = Timer(Duration(milliseconds: 1500 + rnd.nextInt(2500)), () { if (mounted && ph == 'wait') setState(() => ph = 'go'); });
  }
  void _tap(int p) {
    if (cd > 0 || ph == 'res' || ph == 'end' || lock[p]) return;
    if (ph == 'wait') {
      Sfx.bad(); setState(() { lock[p] = true; sc[p] = max(0, sc[p] - 1); });
      if (lock.every((x) => x)) { tm?.cancel(); tm = Timer(const Duration(milliseconds: 900), _next); }
      return;
    }
    tm?.cancel(); Sfx.good();
    setState(() { ph = 'res'; sc[p]++; msg = '${EM[p]} +1'; });
    if (sc[p] >= 3) { setState(() { ph = 'end'; msg = wtxt(sc); }); Sfx.win(); } else { tm = Timer(const Duration(milliseconds: 1300), _next); }
  }
  @override Widget build(BuildContext c) => zones(widget.n, (p) => zone(p,
      Tx(lock[p] ? '🚫' : ph == 'go' ? '👆 TAP!' : ph == 'wait' ? '✋ Tunggu…' : '${sc[p]}', style: big(36)), onDown: () => _tap(p),
      col: lock[p] ? Colors.grey : ph == 'wait' ? const Color(0xFFE63946) : ph == 'go' ? const Color(0xFF2BA84A) : PC[p]),
      mid: mb(ph == 'res' || ph == 'end' ? msg : cd > 0 ? '$cd' : '${sc.join(' - ')}  (3)'));
}

// ===== 24 Duel Hitung =====
class MathDuel extends StatefulWidget {
  final int n; const MathDuel(this.n, {super.key});
  @override State<MathDuel> createState() => _MathDuelS();
}
class _MathDuelS extends State<MathDuel> with Cd<MathDuel> {
  late final List<int> sc = List.filled(widget.n, 0); int a = 0, b = 0, ans = 0; bool m = false, done = false; List<int> o = []; List<bool> lock = [];
  @override void initState() { super.initState(); _q(); startCd(() {}); }
  void _q() {
    a = 2 + rnd.nextInt(10); b = 2 + rnd.nextInt(10); m = rnd.nextBool(); ans = m ? a * b : a + b;
    final x = <int>{ans}; while (x.length < 3) { x.add(max(0, ans + rnd.nextInt(11) - 5)); }
    o = x.toList()..shuffle(); lock = List.filled(widget.n, false);
  }
  void _ans(int p, int v) {
    if (cd > 0 || done || lock[p]) return;
    setState(() {
      if (v == ans) { sc[p]++; Sfx.good(); if (sc[p] >= 5) { done = true; Sfx.win(); } else { _q(); } } else { lock[p] = true; Sfx.bad(); }
    });
  }
  @override Widget build(BuildContext c) => zones(widget.n, (p) => zone(p, Column(mainAxisSize: MainAxisSize.min, children: [
        Tx('⭐ ${sc[p]}/5', style: big(24)), const SizedBox(height: 6),
        Row(children: [for (final v in o) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: GestureDetector(onTapDown: (_) => _ans(p, v), child: cart(lock[p] ? Colors.grey : Colors.white, h: 54, r: 14, child: Tx('$v', style: ts(22))))))]),
      ])), mid: mb(done ? wtxt(sc) : cd > 0 ? '$cd' : '$a ${m ? '×' : '+'} $b'));
}

// ===== 25 Bom Estafet =====
class BombGame extends StatefulWidget {
  final int n; const BombGame(this.n, {super.key});
  @override State<BombGame> createState() => _BombS();
}
class _BombS extends State<BombGame> with Cd<BombGame> {
  int h = 0; bool boom = false; double el = 0, fuse = 0; Timer? tm;
  @override void initState() {
    super.initState(); fuse = 6.0 + rnd.nextInt(14); h = rnd.nextInt(widget.n);
    startCd(() { tm = Timer.periodic(const Duration(milliseconds: 100), (_) { if (boom || !mounted) return; el += .1; if (el >= fuse) { setState(() => boom = true); Sfx.bad(); tm?.cancel(); } }); });
  }
  @override void dispose() { tm?.cancel(); super.dispose(); }
  @override Widget build(BuildContext c) => zones(widget.n, (p) => zone(p, Tx(boom ? (p == h ? '💥' : '😎') : (p == h ? '💣' : '😅'), style: const TextStyle(fontSize: 76)),
      col: p == h && !boom ? const Color(0xFFFF6B6B) : PC[p].withOpacity(.6),
      onDown: () { if (cd > 0 || boom || p != h) return; Sfx.tap(); setState(() => h = (h + 1) % widget.n); }),
      mid: boom ? mb('💥 ${EM[h]} P${h + 1} kalah!') : cd > 0 ? mb('$cd') : null);
}

// ===== 26 Henti di Tengah =====
class StopBar extends StatefulWidget {
  final int n; const StopBar(this.n, {super.key});
  @override State<StopBar> createState() => _StopS();
}
class _StopS extends State<StopBar> with Cd<StopBar> {
  static const sp = [2.0, 2.7, 3.3, 2.4];
  late final List<double?> st = List.filled(widget.n, null); late final List<int> tot = List.filled(widget.n, 0);
  int rd = 1; double t = 0; bool end = false; Timer? tm;
  @override void initState() { super.initState(); startCd(() { tm = Timer.periodic(const Duration(milliseconds: 16), (_) { if (mounted) setState(() => t += .016); }); }); }
  @override void dispose() { tm?.cancel(); super.dispose(); }
  double _pos(int p) => st[p] ?? sin(t * sp[p]);
  void _stop(int p) {
    if (cd > 0 || end || st[p] != null) return;
    Sfx.tap();
    setState(() { final v = sin(t * sp[p]); st[p] = v; tot[p] += (100 - v.abs() * 100).round(); });
    if (st.every((x) => x != null)) {
      Timer(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        if (rd >= 3) { setState(() => end = true); Sfx.win(); } else { setState(() { rd++; for (int i = 0; i < widget.n; i++) { st[i] = null; } }); }
      });
    }
  }
  @override Widget build(BuildContext c) => zones(widget.n, (p) => zone(p, Column(mainAxisSize: MainAxisSize.min, children: [
        Tx('${tot[p]}', style: big(34)), const SizedBox(height: 10),
        LayoutBuilder(builder: (c, k) => SizedBox(width: k.maxWidth - 24, height: 36, child: Stack(children: [
          Positioned.fill(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.white54, borderRadius: BorderRadius.circular(8)))),
          Center(child: Container(width: 4, height: 36, color: ink)),
          Positioned(left: (_pos(p) + 1) / 2 * (k.maxWidth - 24 - 24), child: Container(width: 24, height: 36, decoration: BoxDecoration(color: st[p] != null ? sun : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: ink, width: 3)))),
        ]))),
      ]), onDown: () => _stop(p)), mid: mb(end ? wtxt(tot) : cd > 0 ? '$cd' : 'Ronde $rd/3'));
}

// ===== 27 Hitung Detik =====
class HoldGame extends StatefulWidget {
  final int n; const HoldGame(this.n, {super.key});
  @override State<HoldGame> createState() => _HoldS();
}
class _HoldS extends State<HoldGame> {
  late final List<Stopwatch> sw = List.generate(widget.n, (_) => Stopwatch()); late final List<double?> res = List.filled(widget.n, null); Timer? tm;
  @override void initState() { super.initState(); tm = Timer.periodic(const Duration(milliseconds: 60), (_) { if (mounted) setState(() {}); }); }
  @override void dispose() { tm?.cancel(); super.dispose(); }
  bool get all => res.every((x) => x != null);
  void _up(int p) {
    if (!sw[p].isRunning) return;
    sw[p].stop(); setState(() => res[p] = sw[p].elapsedMilliseconds / 1000); Sfx.good();
    if (all) Sfx.win();
  }
  String _txt(int p) {
    if (res[p] != null) return '${res[p]!.toStringAsFixed(2)}s';
    if (sw[p].isRunning) return sw[p].elapsedMilliseconds < 2000 ? (sw[p].elapsedMilliseconds / 1000).toStringAsFixed(1) : '❓';
    return '👇 Tahan 5.0s';
  }
  @override Widget build(BuildContext c) => zones(widget.n, (p) => Listener(
        onPointerDown: (_) { if (res[p] == null && !sw[p].isRunning) { sw[p].start(); Sfx.tap(); } },
        onPointerUp: (_) => _up(p), onPointerCancel: (_) => _up(p),
        child: cart(PC[p].withOpacity(.88), r: 24, child: Tx(_txt(p), style: big(38)))),
      mid: mb(all ? wtxt([for (final r in res) (r! - 5).abs()], low: true) : 'Target: 5.0 detik'));
}

// ===== 28 Balap Lari =====
class RunGame extends StatefulWidget {
  final int n; const RunGame(this.n, {super.key});
  @override State<RunGame> createState() => _RunS();
}
class _RunS extends State<RunGame> with Cd<RunGame> {
  late final List<int> st = List.filled(widget.n, 0), last = List.filled(widget.n, -1); bool done = false;
  @override void initState() { super.initState(); startCd(() {}); }
  void _step(int p, int side) {
    if (cd > 0 || done) return;
    if (side == last[p]) { Sfx.bad(); return; }
    last[p] = side; Sfx.tap();
    setState(() { st[p]++; if (st[p] >= 30) { done = true; Sfx.win(); } });
  }
  Widget _b(int p, int side) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: GestureDetector(onTapDown: (_) => _step(p, side), child: cart(Colors.white, h: 58, r: 16, child: Text(side == 0 ? '◀' : '▶', style: ts(26))))));
  @override Widget build(BuildContext c) => zones(widget.n, (p) => zone(p, Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Tx('🏃 ${st[p]}/30', style: big(24)), const SizedBox(height: 6),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: st[p] / 30, minHeight: 10, color: sun, backgroundColor: Colors.white54))),
        const SizedBox(height: 8), Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [_b(p, 0), _b(p, 1)])),
      ])), mid: mb(done ? wtxt(st) : cd > 0 ? '$cd' : ''));
}

// ===== 29 Pop Rebutan =====
class PopRace extends StatefulWidget {
  final int n; const PopRace(this.n, {super.key});
  @override State<PopRace> createState() => _PopS();
}
class _PopS extends State<PopRace> with Cd<PopRace> {
  late final List<int> sc = List.filled(widget.n, 0); late final List<Alignment> pos = List.generate(widget.n, (_) => _r()); bool done = false;
  Alignment _r() => Alignment(rnd.nextDouble() * 1.6 - .8, rnd.nextDouble() * 1.4 - .6);
  @override void initState() { super.initState(); startCd(() {}); }
  void _pop(int p) {
    if (cd > 0 || done) return;
    Sfx.good(); setState(() { sc[p]++; pos[p] = _r(); if (sc[p] >= 10) { done = true; Sfx.win(); } });
  }
  @override Widget build(BuildContext c) => zones(widget.n, (p) => zone(p, Stack(children: [
        Positioned(top: 6, left: 0, right: 0, child: Center(child: Tx('🎈 ${sc[p]}/10', style: big(20)))),
        AnimatedAlign(alignment: pos[p], duration: const Duration(milliseconds: 150), child: GestureDetector(onTapDown: (_) => _pop(p), child: const Text('🎈', style: TextStyle(fontSize: 56)))),
      ])), mid: mb(done ? wtxt(sc) : cd > 0 ? '$cd' : ''));
}

// ===== 30 Gunting Batu Kertas =====
class RpsGame extends StatefulWidget {
  final int n; const RpsGame(this.n, {super.key});
  @override State<RpsGame> createState() => _RpsS();
}
class _RpsS extends State<RpsGame> with Cd<RpsGame> {
  static const ic = ['✊', '✋', '✌️'];
  late final List<int> sc = List.filled(widget.n, 0), ch = List.filled(widget.n, -1); int rd = 1; bool rev = false, done = false;
  @override void initState() { super.initState(); startCd(() {}); }
  void _pick(int p, int v) {
    if (cd > 0 || rev || ch[p] >= 0) return;
    Sfx.tap(); setState(() => ch[p] = v);
    if (ch.every((x) => x >= 0)) {
      setState(() {
        rev = true;
        for (int i = 0; i < widget.n; i++) { for (int j = 0; j < widget.n; j++) { if (i != j && (ch[i] - ch[j] + 3) % 3 == 1) sc[i]++; } }
      });
      Sfx.good();
      Timer(const Duration(milliseconds: 1800), () {
        if (!mounted) return;
        if (rd >= 5) { setState(() => done = true); Sfx.win(); } else { setState(() { rd++; rev = false; ch.fillRange(0, widget.n, -1); }); }
      });
    }
  }
  @override Widget build(BuildContext c) => zones(widget.n, (p) => zone(p, Column(mainAxisSize: MainAxisSize.min, children: [
        Tx('⭐ ${sc[p]}', style: big(24)), const SizedBox(height: 4),
        if (rev) Text(ic[ch[p]], style: const TextStyle(fontSize: 64)) else if (ch[p] >= 0) Tx('✔ Siap', style: big(26)) else Row(mainAxisSize: MainAxisSize.min, children: [
          for (int v = 0; v < 3; v++) Padding(padding: const EdgeInsets.all(3), child: GestureDetector(onTapDown: (_) => _pick(p, v), child: cart(Colors.white, w: 54, h: 54, r: 14, child: Text(ic[v], style: const TextStyle(fontSize: 26))))),
        ]),
      ])), mid: mb(done ? wtxt(sc) : cd > 0 ? '$cd' : 'Ronde $rd/5'));
}
