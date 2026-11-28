import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'ui.dart';
import 'local1.dart';

// ===== Utilitas giliran =====
Widget chips(int n, int turn, List<String> sc, {List<bool>? alive}) => Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
      for (int i = 0; i < n; i++) AnimatedScale(scale: i == turn ? 1.15 : .9, duration: const Duration(milliseconds: 200),
          child: Opacity(opacity: alive == null || alive[i] ? 1 : .3, child: cart(PC[i], r: 14, sh: i == turn ? 5 : 2, pad: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text('P${i + 1}  ${sc[i]}', style: ts(15, Colors.white))))),
    ]);
Widget turnMsg(String s) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Tx(s, textAlign: TextAlign.center, style: ts(18)));
Widget hint(String s) => Tx(s, textAlign: TextAlign.center, style: ts(13, const Color(0xFF8A7A9B)));
String tn(int p) => '${EM[p]} P${p + 1}';
int nextAlive(List<bool> a, int t) { int x = (t + 1) % a.length; while (!a[x]) { x = (x + 1) % a.length; } return x; }
List<int> aliveIdx(List<bool> a) => [for (int i = 0; i < a.length; i++) if (a[i]) i];

// ===== 31 Dadu Serakah =====
class PigGame extends StatefulWidget {
  final int n; const PigGame(this.n, {super.key});
  @override State<PigGame> createState() => _PigS();
}
class _PigS extends State<PigGame> {
  late final List<int> sc = List.filled(widget.n, 0); int turn = 0, tt = 0, d = 0, cnt = 0, win = -1;
  void _roll() {
    if (win >= 0) return;
    final r = 1 + rnd.nextInt(6);
    setState(() { d = r; cnt++; if (r == 1) { tt = 0; Sfx.bad(); turn = (turn + 1) % widget.n; } else { tt += r; Sfx.tap(); } });
  }
  void _hold() {
    if (win >= 0 || tt == 0) return;
    setState(() { sc[turn] += tt; tt = 0; if (sc[turn] >= 40) { win = turn; Sfx.win(); } else { turn = (turn + 1) % widget.n; Sfx.good(); } });
  }
  @override Widget build(BuildContext c) => page([
        chips(widget.n, turn, sc.map((e) => '$e').toList()),
        turnMsg(win >= 0 ? '🏆 ${tn(win)} menang!' : 'Giliran: ${tn(turn)}'),
        AnimatedSwitcher(duration: const Duration(milliseconds: 400), transitionBuilder: (w, a) => RotationTransition(turns: Tween<double>(begin: .5, end: 0.0).animate(a), child: ScaleTransition(scale: a, child: w)),
            child: Text(d == 0 ? '🎲' : '⚀⚁⚂⚃⚄⚅'[d - 1], key: ValueKey(cnt), style: const TextStyle(fontSize: 90))),
        Tx('Poin giliran ini: $tt', style: ts(22)), const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [btn('Lempar 🎲', _roll), btn('Simpan 💾', _hold, c: const Color(0xFF3DBE6C))]),
        const SizedBox(height: 10), hint('Pertama yang mencapai 40! Dapat angka 1 = poin hangus.'),
      ]);
}

// ===== 32 Kotak Bom =====
class BoxBomb extends StatefulWidget {
  final int n; const BoxBomb(this.n, {super.key});
  @override State<BoxBomb> createState() => _BoxS();
}
class _BoxS extends State<BoxBomb> {
  late final List<bool> alive = List.filled(widget.n, true); List<bool> op = List.filled(12, false); int bomb = rnd.nextInt(12), turn = 0, win = -1; String msg = '';
  void _open(int i) {
    if (win >= 0 || op[i]) return;
    setState(() {
      op[i] = true;
      if (i == bomb) {
        alive[turn] = false; Sfx.bad(); msg = '💥 ${tn(turn)} gugur!';
        final l = aliveIdx(alive);
        if (l.length == 1) { win = l[0]; Sfx.win(); } else { turn = nextAlive(alive, turn); op = List.filled(12, false); bomb = rnd.nextInt(12); }
      } else { Sfx.good(); turn = nextAlive(alive, turn); msg = ''; }
    });
  }
  @override Widget build(BuildContext c) => page([
        chips(widget.n, turn, [for (final a in alive) a ? '❤️' : '💀'], alive: alive),
        turnMsg(win >= 0 ? '🏆 ${tn(win)} menang!' : 'Giliran: ${tn(turn)}'), if (msg.isNotEmpty) turnMsg(msg),
        board(4, [for (int i = 0; i < 12; i++) GestureDetector(onTap: () => _open(i), child: cart(op[i] ? const Color(0xFFC9F2C7) : PC[turn], child: Text(op[i] ? '⭐' : '🎁', style: const TextStyle(fontSize: 34))))], gap: 10),
        const SizedBox(height: 10), hint('Pilih kotak, jangan kena bom!'),
      ]);
}

// ===== 33 Nim Batang =====
class NimGame extends StatefulWidget {
  final int n; const NimGame(this.n, {super.key});
  @override State<NimGame> createState() => _NimS();
}
class _NimS extends State<NimGame> {
  late int sticks = 15 + 5 * (widget.n - 2); int turn = 0, loser = -1;
  void _take(int k) {
    if (loser >= 0 || k > sticks) return;
    setState(() { sticks -= k; Sfx.tap(); if (sticks == 0) { loser = turn; Sfx.bad(); } else { turn = (turn + 1) % widget.n; } });
  }
  @override Widget build(BuildContext c) => page([
        chips(widget.n, turn, List.filled(widget.n, '')),
        turnMsg(loser >= 0 ? '💥 ${tn(loser)} kalah!' : 'Giliran: ${tn(turn)}'),
        Wrap(alignment: WrapAlignment.center, spacing: 2, children: [for (int i = 0; i < sticks; i++) const Text('🥢', style: TextStyle(fontSize: 30))]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (int k = 1; k <= 3; k++) Opacity(opacity: k <= sticks ? 1 : .3, child: btn('$k', () => _take(k), c: PC[k]))]),
        const SizedBox(height: 10), hint('Ambil 1-3 batang. Yang mengambil batang terakhir kalah!'),
      ]);
}

// ===== 34 Kartu Tinggi =====
class HiLoGame extends StatefulWidget {
  final int n; const HiLoGame(this.n, {super.key});
  @override State<HiLoGame> createState() => _HiLoS();
}
class _HiLoS extends State<HiLoGame> {
  static const cn = ['', 'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
  late final List<int> lives = List.filled(widget.n, 3); int turn = 0, card = 1 + rnd.nextInt(13), win = -1; String msg = '';
  void _guess(bool hi) {
    if (win >= 0) return;
    final nx = 1 + rnd.nextInt(13); final ok = hi ? nx >= card : nx <= card;
    setState(() {
      msg = '${cn[card]} → ${cn[nx]} ${ok ? '✅' : '❌'}'; card = nx;
      if (ok) { Sfx.good(); } else { Sfx.bad(); lives[turn]--; }
      final al = [for (int k = 0; k < widget.n; k++) if (lives[k] > 0) k];
      if (al.length == 1) { win = al[0]; Sfx.win(); return; }
      int x = (turn + 1) % widget.n; while (lives[x] <= 0) { x = (x + 1) % widget.n; }
      turn = x;
    });
  }
  @override Widget build(BuildContext c) => page([
        chips(widget.n, turn, [for (final l in lives) l > 0 ? '❤️' * l : '💀'], alive: [for (final l in lives) l > 0]),
        turnMsg(win >= 0 ? '🏆 ${tn(win)} menang!' : 'Giliran: ${tn(turn)}'),
        AnimatedSwitcher(duration: const Duration(milliseconds: 300), transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
            child: KeyedSubtree(key: ValueKey('$card$msg'), child: cart(Colors.white, w: 130, h: 180, r: 20, child: Text(cn[card], style: ts(64, card >= 11 || card == 1 ? const Color(0xFFE63946) : ink))))),
        turnMsg(msg), const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [btn('⬆️ Lebih Tinggi', () => _guess(true), c: const Color(0xFF3DBE6C)), btn('⬇️ Lebih Rendah', () => _guess(false), c: const Color(0xFFE67E22))]),
      ]);
}

// ===== 35 Rebut Wilayah =====
class TerrGame extends StatefulWidget {
  final int n; const TerrGame(this.n, {super.key});
  @override State<TerrGame> createState() => _TerrS();
}
class _TerrS extends State<TerrGame> {
  final b = List.filled(25, -1); int turn = 0;
  bool get full => !b.contains(-1);
  void _tap(int i) {
    if (b[i] >= 0 || full) return;
    setState(() {
      b[i] = turn; final r = i ~/ 5, c = i % 5;
      for (final o in const [[1, 0], [-1, 0], [0, 1], [0, -1]]) { final y = r + o[0], x = c + o[1]; if (y >= 0 && y < 5 && x >= 0 && x < 5 && b[y * 5 + x] >= 0) b[y * 5 + x] = turn; }
      Sfx.tap(); if (full) { Sfx.win(); } else { turn = (turn + 1) % widget.n; }
    });
  }
  @override Widget build(BuildContext c) {
    final sc = [for (int p = 0; p < widget.n; p++) b.where((x) => x == p).length];
    return page([
      chips(widget.n, turn, sc.map((e) => '$e').toList()), turnMsg(full ? wtxt(sc) : 'Giliran: ${tn(turn)}'),
      board(5, [for (int i = 0; i < 25; i++) GestureDetector(onTap: () => _tap(i), child: AnimatedContainer(duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(color: b[i] < 0 ? Colors.white : PC[b[i]], borderRadius: BorderRadius.circular(12), border: Border.all(color: ink, width: 3))))], gap: 6),
      const SizedBox(height: 10), hint('Rebut sebanyak mungkin wilayah!'),
    ]);
  }
}

// ===== 36 Titik Kotak =====
class DotsGame extends StatefulWidget {
  final int n; const DotsGame(this.n, {super.key});
  @override State<DotsGame> createState() => _DotsS();
}
class _DotsS extends State<DotsGame> {
  final h = List.filled(12, -1), v = List.filled(12, -1), bx = List.filled(9, -1); int turn = 0;
  bool get full => bx.every((x) => x >= 0);
  bool _box(int r, int c) => h[r * 3 + c] >= 0 && h[(r + 1) * 3 + c] >= 0 && v[r * 4 + c] >= 0 && v[r * 4 + c + 1] >= 0;
  void _line(List<int> L, int i) {
    if (L[i] >= 0 || full) return;
    setState(() {
      L[i] = turn; int got = 0;
      for (int r = 0; r < 3; r++) { for (int c = 0; c < 3; c++) { if (bx[r * 3 + c] < 0 && _box(r, c)) { bx[r * 3 + c] = turn; got++; } } }
      if (got > 0) { Sfx.good(); } else { Sfx.tap(); turn = (turn + 1) % widget.n; }
      if (full) Sfx.win();
    });
  }
  Widget _cell(int i, int j) {
    if (i.isEven && j.isEven) return Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: ink, shape: BoxShape.circle)));
    if (i.isEven) { final k = (i ~/ 2) * 3 + (j - 1) ~/ 2; return GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _line(h, k), child: Container(margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2), decoration: BoxDecoration(color: h[k] >= 0 ? PC[h[k]] : const Color(0xFFE0D8EE), borderRadius: BorderRadius.circular(6)))); }
    if (j.isEven) { final k = ((i - 1) ~/ 2) * 4 + j ~/ 2; return GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => _line(v, k), child: Container(margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6), decoration: BoxDecoration(color: v[k] >= 0 ? PC[v[k]] : const Color(0xFFE0D8EE), borderRadius: BorderRadius.circular(6)))); }
    final o = bx[((i - 1) ~/ 2) * 3 + (j - 1) ~/ 2];
    return AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.all(2), alignment: Alignment.center, decoration: BoxDecoration(color: o >= 0 ? PC[o].withOpacity(.45) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text(o >= 0 ? EM[o] : '', style: const TextStyle(fontSize: 26)));
  }
  @override Widget build(BuildContext c) {
    final sc = [for (int p = 0; p < widget.n; p++) bx.where((x) => x == p).length];
    return page([
      chips(widget.n, turn, sc.map((e) => '$e').toList()), turnMsg(full ? wtxt(sc) : 'Giliran: ${tn(turn)}'),
      AspectRatio(aspectRatio: 1, child: Column(children: [for (int i = 0; i < 7; i++) Expanded(flex: i.isEven ? 2 : 5, child: Row(children: [for (int j = 0; j < 7; j++) Expanded(flex: j.isEven ? 2 : 5, child: _cell(i, j))]))])),
      const SizedBox(height: 10), hint('Lengkapi kotak untuk giliran ekstra!'),
    ]);
  }
}

// ===== 37 Pompa Balon =====
class PumpGame extends StatefulWidget {
  final int n; const PumpGame(this.n, {super.key});
  @override State<PumpGame> createState() => _PumpS();
}
class _PumpS extends State<PumpGame> {
  late final List<bool> alive = List.filled(widget.n, true); int turn = 0, sz = 0, thr = 8 + rnd.nextInt(18), win = -1; String msg = '';
  void _pump(int k) {
    if (win >= 0) return;
    setState(() {
      sz += k; Sfx.tap();
      if (sz >= thr) {
        alive[turn] = false; Sfx.bad(); msg = '💥 ${tn(turn)} gugur!';
        final l = aliveIdx(alive);
        if (l.length == 1) { win = l[0]; Sfx.win(); } else { sz = 0; thr = 8 + rnd.nextInt(18); turn = nextAlive(alive, turn); }
      } else { msg = ''; turn = nextAlive(alive, turn); }
    });
  }
  @override Widget build(BuildContext c) => page([
        chips(widget.n, turn, [for (final a in alive) a ? '❤️' : '💀'], alive: alive),
        turnMsg(win >= 0 ? '🏆 ${tn(win)} menang!' : 'Giliran: ${tn(turn)}'), if (msg.isNotEmpty) turnMsg(msg),
        SizedBox(height: 200, child: Center(child: AnimatedScale(scale: .5 + sz * .055, duration: const Duration(milliseconds: 300), curve: Curves.elasticOut, child: const Text('🎈', style: TextStyle(fontSize: 80))))),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (int k = 1; k <= 3; k++) btn('Pompa +$k', () => _pump(k), c: PC[k])]),
        const SizedBox(height: 10), hint('Balon meletus bila terlalu besar!'),
      ]);
}

// ===== 38 Empat Berderet (6x6, 2-4 pemain) =====
class FiveGame extends StatefulWidget {
  final int n; const FiveGame(this.n, {super.key});
  @override State<FiveGame> createState() => _FiveS();
}
class _FiveS extends State<FiveGame> {
  final b = List.filled(36, -1); int turn = 0, win = -2;
  bool _four(int p) {
    for (int r = 0; r < 6; r++) { for (int c = 0; c < 6; c++) { for (final d in const [[1, 0], [0, 1], [1, 1], [1, -1]]) {
      int k = 0;
      for (; k < 4; k++) { final x = c + d[0] * k, y = r + d[1] * k; if (x < 0 || x > 5 || y < 0 || y > 5 || b[y * 6 + x] != p) break; }
      if (k == 4) return true;
    } } }
    return false;
  }
  void _tap(int i) {
    if (b[i] >= 0 || win != -2) return;
    setState(() {
      b[i] = turn; Sfx.tap();
      if (_four(turn)) { win = turn; Sfx.win(); } else if (!b.contains(-1)) { win = -1; } else { turn = (turn + 1) % widget.n; }
    });
  }
  @override Widget build(BuildContext c) => page([
        chips(widget.n, turn, List.filled(widget.n, '')),
        turnMsg(win == -2 ? 'Giliran: ${tn(turn)}' : win == -1 ? '🤝 Seri!' : '🏆 ${tn(win)} menang!'),
        cart(const Color(0xFFDDF3FF), r: 20, pad: const EdgeInsets.all(8), child: board(6, [for (int i = 0; i < 36; i++) GestureDetector(onTap: () => _tap(i), child: Container(
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: ink, width: 2)),
            child: AnimatedScale(scale: b[i] < 0 ? 0 : 1, duration: const Duration(milliseconds: 350), curve: Curves.elasticOut, child: Container(decoration: BoxDecoration(color: PC[max(0, b[i])], shape: BoxShape.circle)))))], gap: 4)),
        const SizedBox(height: 10), hint('Susun 4 sejajar!'),
      ]);
}

// ===== 39 Memori Giliran =====
class MemTurn extends StatefulWidget {
  final int n; const MemTurn(this.n, {super.key});
  @override State<MemTurn> createState() => _MemTurnS();
}
class _MemTurnS extends State<MemTurn> {
  late final List<String> d; final up = List.filled(16, false), ok = List.filled(16, false);
  late final List<int> sc = List.filled(widget.n, 0); int turn = 0; int? a; bool lock = false;
  @override void initState() {
    super.initState();
    final e = '🍎🍌🍇🍓🍉🍒🥝🍍'.runes.map((r) => String.fromCharCode(r)).toList();
    d = [...e, ...e]..shuffle();
  }
  bool get done => ok.every((x) => x);
  void _tap(int i) {
    if (lock || up[i] || ok[i]) return;
    Sfx.tap(); setState(() => up[i] = true);
    if (a == null) { a = i; return; }
    final b = a!; a = null;
    if (d[b] == d[i]) { Sfx.good(); setState(() { ok[b] = true; ok[i] = true; sc[turn]++; }); if (done) Sfx.win(); }
    else {
      lock = true;
      Future.delayed(const Duration(milliseconds: 900), () { if (!mounted) return; setState(() { up[b] = false; up[i] = false; lock = false; turn = (turn + 1) % widget.n; }); });
    }
  }
  Widget _card(int i) => GestureDetector(onTap: () => _tap(i), child: TweenAnimationBuilder<double>(
      tween: Tween(end: up[i] ? pi : 0.0), duration: const Duration(milliseconds: 350), curve: Curves.easeOut,
      builder: (c, v, _) => Transform(alignment: Alignment.center, transform: Matrix4.identity()..setEntry(3, 2, 0.002)..rotateY(v),
          child: v > pi / 2
              ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(pi), child: cart(ok[i] ? const Color(0xFFC9F2C7) : Colors.white, child: Text(d[i], style: const TextStyle(fontSize: 32))))
              : cart(PC[turn], child: Text('?', style: ts(30, Colors.white))))));
  @override Widget build(BuildContext c) => page([
        chips(widget.n, turn, sc.map((e) => '$e').toList()), turnMsg(done ? wtxt(sc) : 'Giliran: ${tn(turn)}'),
        board(4, List.generate(16, _card)), const SizedBox(height: 8), hint('Cari pasangan!'),
      ]);
}

// ===== 40 Lempar Dart =====
class DartGame extends StatefulWidget {
  final int n; const DartGame(this.n, {super.key});
  @override State<DartGame> createState() => _DartS();
}
class _DartS extends State<DartGame> {
  late final List<int> sc = List.filled(widget.n, 0); int turn = 0, throws = 0; double t = 0; String msg = ''; Timer? tm;
  @override void initState() { super.initState(); tm = Timer.periodic(const Duration(milliseconds: 16), (_) { if (mounted) setState(() => t += .016); }); }
  @override void dispose() { tm?.cancel(); super.dispose(); }
  bool get done => throws >= 3 * widget.n;
  Offset get ch => Offset(sin(t * 2.1), sin(t * 3.3));
  void _throw() {
    if (done) return;
    final pts = max(0, 10 - (ch.distance * 8).round());
    setState(() {
      sc[turn] += pts; msg = '${EM[turn]} +$pts'; throws++; turn = (turn + 1) % widget.n;
      if (done) { Sfx.win(); } else if (pts >= 7) { Sfx.good(); } else { Sfx.tap(); }
    });
  }
  @override Widget build(BuildContext c) => page([
        chips(widget.n, turn, sc.map((e) => '$e').toList()),
        turnMsg(done ? wtxt(sc) : 'Giliran: ${tn(turn)}  •  Lemparan ${throws ~/ widget.n + 1}/3'), if (msg.isNotEmpty && !done) turnMsg(msg),
        SizedBox(width: 280, height: 280, child: GestureDetector(onTap: _throw, child: CustomPaint(painter: _DartP(ch)))),
        const SizedBox(height: 12), btn('🎯 LEMPAR!', _throw),
      ]);
}
class _DartP extends CustomPainter {
  final Offset ch; _DartP(this.ch);
  @override void paint(Canvas cv, Size s) {
    final c = s.center(Offset.zero), R = s.width / 2;
    for (int k = 8; k >= 1; k--) { cv.drawCircle(c, R * k / 8, Paint()..color = k % 2 == 0 ? const Color(0xFFFFF3D6) : const Color(0xFFFF8FAB)); }
    cv.drawCircle(c, R / 16, Paint()..color = const Color(0xFFE63946));
    cv.drawCircle(c, R, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = ink);
    final p = Offset(c.dx + ch.dx * R, c.dy + ch.dy * R); final lp = Paint()..color = ink..strokeWidth = 4..strokeCap = StrokeCap.round;
    cv.drawLine(p + const Offset(-14, 0), p + const Offset(14, 0), lp); cv.drawLine(p + const Offset(0, -14), p + const Offset(0, 14), lp);
    cv.drawCircle(p, 9, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = ink);
  }
  @override bool shouldRepaint(_DartP o) => true;
}
