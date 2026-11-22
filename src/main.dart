import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const App());
final rnd = Random();
const ink = Color(0xFF4A3B5C);
const em = ['🔴', '🔵', '🟢', '🟡', '🟣', '🟠'];
const ts = TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: ink);
const big = TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: ink);
var tms = <Timer>[];

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Pesta Mini', theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFFFF8FAB)), home: const Home());
}

BoxDecoration pop(Color c, [double r = 20]) => BoxDecoration(color: c, borderRadius: BorderRadius.circular(r), border: Border.all(color: ink, width: 3), boxShadow: const [BoxShadow(color: ink, offset: Offset(0, 4))]);
Widget page(String t, Widget b, {List<Widget>? act}) => Scaffold(
    backgroundColor: const Color(0xFFFFF3D6),
    appBar: AppBar(title: Text(t, style: ts), backgroundColor: const Color(0xFFFFD6E8), foregroundColor: ink, actions: act),
    body: SafeArea(child: Center(child: SingleChildScrollView(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: b)))));
Widget txt(String t) => Padding(padding: const EdgeInsets.all(8), child: Text(t, style: ts, textAlign: TextAlign.center));
Widget tile(String t, Color c, VoidCallback? f, {double s = 30}) => GestureDetector(onTap: f, child: Container(decoration: pop(c, 16), alignment: Alignment.center, child: FittedBox(child: Padding(padding: const EdgeInsets.all(4), child: Text(t, style: TextStyle(fontSize: s, fontWeight: FontWeight.w800, color: ink))))));
Widget btn(String t, VoidCallback f) => Padding(padding: const EdgeInsets.all(6), child: GestureDetector(onTap: f, child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), decoration: pop(const Color(0xFFFF8FAB), 18), child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)))));
Widget grid(int cols, int n, Widget Function(int) b, {double gap = 8}) => GridView.count(crossAxisCount: cols, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: gap, crossAxisSpacing: gap, padding: const EdgeInsets.all(12), children: List.generate(n, b));
Widget sb(Widget Function(void Function(VoidCallback)) b) => StatefulBuilder(builder: (c, s) => b(s));
Timer tm(int ms, void Function() f, {bool rep = false}) {
  final t = rep ? Timer.periodic(Duration(milliseconds: ms), (_) => f()) : Timer(Duration(milliseconds: ms), f);
  tms.add(t);
  return t;
}

// ================= SINGLE PLAYER =================
Widget memory() {
  const e = ['🐶', '🐱', '🦊', '🐸', '🐵', '🐼', '🦄', '🐙'];
  final d = [...e, ...e]..shuffle(rnd);
  final open = <int>[], done = <int>{};
  var m = 0, lock = false;
  return sb((set) => Column(children: [
        txt(done.length == 16 ? '🎉 Menang! $m langkah' : 'Langkah: $m'),
        grid(4, 16, (i) {
          final up = open.contains(i) || done.contains(i);
          return tile(up ? d[i] : '❓', up ? const Color(0xFFFFF3B0) : Colors.white, () {
            if (lock || up) return;
            set(() {
              open.add(i);
              if (open.length == 2) {
                m++;
                if (d[open[0]] == d[open[1]]) {
                  done.addAll(open);
                  open.clear();
                } else {
                  lock = true;
                  tm(700, () => set(() {
                        open.clear();
                        lock = false;
                      }));
                }
              }
            });
          });
        })
      ]));
}

Widget g2048() {
  final g = List.filled(16, 0);
  var sc = 0;
  void add() {
    final z = [for (var i = 0; i < 16; i++) if (g[i] == 0) i];
    if (z.isNotEmpty) g[z[rnd.nextInt(z.length)]] = rnd.nextInt(10) == 0 ? 4 : 2;
  }
  add();
  add();
  return sb((set) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanEnd: (d) {
        final v = d.velocity.pixelsPerSecond;
        final h = v.dx.abs() > v.dy.abs();
        final dx = h ? (v.dx > 0 ? 1 : -1) : 0, dy = h ? 0 : (v.dy > 0 ? 1 : -1);
        var ch = false;
        for (var k = 0; k < 4; k++) {
          final L = [for (var j = 0; j < 4; j++) dx != 0 ? (dx > 0 ? k * 4 + 3 - j : k * 4 + j) : (dy > 0 ? (3 - j) * 4 + k : j * 4 + k)];
          final v2 = [for (final i in L) if (g[i] != 0) g[i]], o = <int>[];
          for (var j = 0; j < v2.length; j++) {
            if (j + 1 < v2.length && v2[j] == v2[j + 1]) {
              o.add(v2[j] * 2);
              sc += v2[j] * 2;
              j++;
            } else {
              o.add(v2[j]);
            }
          }
          while (o.length < 4) o.add(0);
          for (var j = 0; j < 4; j++) {
            if (g[L[j]] != o[j]) ch = true;
            g[L[j]] = o[j];
          }
        }
        if (ch) add();
        set(() {});
      },
      child: Column(children: [
        txt('Skor $sc — geser layar!'),
        grid(4, 16, (i) => tile(g[i] == 0 ? '' : '${g[i]}', HSLColor.fromAHSL(1, (40 + log(g[i] + 1) / ln2 * 28) % 360, .9, g[i] == 0 ? .92 : .72).toColor(), null))
      ])));
}

Widget whack() {
  var s = 0, t = 30, h = -1;
  void Function(VoidCallback) up = (f) => f();
  tm(750, () { if (t > 0) up(() { h = rnd.nextInt(9); }); }, rep: true);
  tm(1000, () { if (t > 0) up(() { t--; if (t == 0) h = -1; }); }, rep: true);
  return sb((set) {
    up = set;
    return Column(children: [
      txt(t > 0 ? '⏱ $t   ⭐ $s' : 'Selesai! Skor $s 🎉'),
      grid(3, 9, (i) => tile(i == h ? '🐹' : '', const Color(0xFFC9F2C7), () { if (i == h && t > 0) set(() { s++; h = -1; }); }, s: 44))
    ]);
  });
}

Widget simon() {
  const C = [Color(0xFFFF6B6B), Color(0xFF4DD4AC), Color(0xFF4D96FF), Color(0xFFFFD93D)];
  final q = <int>[];
  var p = 0, lit = -1, msg = 'Tekan Mulai';
  var ok = false;
  void Function(VoidCallback) up = (f) => f();
  void flash(int i, int ms) => tm(ms, () { up(() { lit = i; }); tm(300, () { up(() { lit = -1; }); }); });
  void play() {
    q.add(rnd.nextInt(4));
    ok = false;
    p = 0;
    up(() { msg = 'Perhatikan… level ${q.length}'; });
    for (var k = 0; k < q.length; k++) flash(q[k], 700 * k + 400);
    tm(700 * q.length + 400, () { up(() { ok = true; msg = 'Giliranmu!'; }); });
  }
  return sb((set) {
    up = set;
    return Column(children: [
      txt(msg),
      grid(2, 4, (i) => Opacity(opacity: lit == i ? .3 : 1, child: tile('', C[i], () {
            if (!ok) return;
            set(() { lit = i; });
            tm(250, () { up(() { lit = -1; }); });
            if (q[p] != i) { ok = false; set(() { msg = 'Salah! Skor ${q.length - 1}'; }); return; }
            p++;
            if (p == q.length) { ok = false; tm(700, play); }
          }))),
      btn('Mulai', () { q.clear(); play(); })
    ]);
  });
}

Widget mathG() {
  var s = 0, t = 30, a = 0, b = 0, ans = 0, m = false;
  var o = <int>[];
  void Function(VoidCallback) up = (f) => f();
  void nx() {
    a = 1 + rnd.nextInt(12); b = 1 + rnd.nextInt(12); m = rnd.nextBool(); ans = m ? a * b : a + b;
    final z = <int>{ans};
    while (z.length < 3) z.add(max(0, ans + rnd.nextInt(10) - 5));
    o = z.toList()..shuffle(rnd);
  }
  nx();
  tm(1000, () { if (t > 0) up(() { t--; }); }, rep: true);
  return sb((set) {
    up = set;
    if (t <= 0) return txt('Selesai! Skor $s 🎉');
    return Column(children: [
      txt('⏱ $t   ⭐ $s'),
      Text('$a ${m ? "×" : "+"} $b', style: big),
      ...o.map((v) => Padding(padding: const EdgeInsets.all(6), child: SizedBox(height: 60, child: tile('$v', Colors.white, () { set(() { if (v == ans) s++; nx(); }); }))))
    ]);
  });
}

Widget snake() {
  var s = [[6, 6]], d = [1, 0], fd = [3, 3], sc = 0;
  var dead = false;
  void Function(VoidCallback) up = (f) => f();
  tm(180, () {
    if (dead) return;
    up(() {
      final h = [s[0][0] + d[0], s[0][1] + d[1]];
      if (h[0] < 0 || h[1] < 0 || h[0] > 11 || h[1] > 11 || s.any((p) => p[0] == h[0] && p[1] == h[1])) { dead = true; return; }
      s.insert(0, h);
      if (h[0] == fd[0] && h[1] == fd[1]) { sc++; fd = [rnd.nextInt(12), rnd.nextInt(12)]; } else { s.removeLast(); }
    });
  }, rep: true);
  return sb((set) {
    up = set;
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanEnd: (e) {
          final v = e.velocity.pixelsPerSecond;
          final h = v.dx.abs() > v.dy.abs();
          final n = h ? [v.dx > 0 ? 1 : -1, 0] : [0, v.dy > 0 ? 1 : -1];
          if (n[0] != -d[0] || n[1] != -d[1]) d = n;
        },
        child: Column(children: [
          txt(dead ? 'Game over 🐍 Skor $sc' : 'Skor $sc — geser untuk belok'),
          grid(12, 144, (i) {
            final x = i % 12, y = i ~/ 12;
            final hd = s[0][0] == x && s[0][1] == y, bd = s.any((p) => p[0] == x && p[1] == y);
            return Container(decoration: BoxDecoration(color: hd ? const Color(0xFF2A9D8F) : bd ? const Color(0xFF4DD4AC) : (fd[0] == x && fd[1] == y) ? const Color(0xFFFF6B6B) : const Color(0xFFE8FFF0), borderRadius: BorderRadius.circular(6)));
          }, gap: 2)
        ]));
  });
}

Widget lights() {
  final g = List.filled(25, 0);
  var mv = 0;
  void tg(int i) {
    final x = i % 5, y = i ~/ 5;
    for (final p in const [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]]) {
      final X = x + p[0], Y = y + p[1];
      if (X >= 0 && X < 5 && Y >= 0 && Y < 5) g[Y * 5 + X] ^= 1;
    }
  }
  for (var k = 0; k < 12; k++) tg(rnd.nextInt(25));
  return sb((set) => Column(children: [
        txt(g.contains(1) ? 'Matikan semua lampu! Langkah $mv' : '🎉 Menang $mv langkah!'),
        grid(5, 25, (i) => tile(g[i] == 1 ? '💡' : '', g[i] == 1 ? const Color(0xFFFFD93D) : const Color(0xFFD9D2E9), () { set(() { tg(i); mv++; }); }))
      ]));
}

Widget slide() {
  final b = [1, 2, 3, 4, 5, 6, 7, 8, 0];
  var mv = 0;
  bool sw(int i) {
    final z = b.indexOf(0);
    final ok = (i % 3 == z % 3 && (i - z).abs() == 3) || (i ~/ 3 == z ~/ 3 && (i - z).abs() == 1);
    if (ok) { b[z] = b[i]; b[i] = 0; }
    return ok;
  }
  for (var k = 0; k < 300; k++) sw(rnd.nextInt(9));
  return sb((set) => Column(children: [
        txt(b.join() == '123456780' ? '🎉 Selesai $mv langkah!' : 'Urutkan 1–8 · langkah $mv'),
        grid(3, 9, (i) => b[i] == 0 ? const SizedBox() : tile('${b[i]}', const Color(0xFFFFE9A8), () { set(() { if (sw(i)) mv++; }); }, s: 40))
      ]));
}

Widget mines() {
  final m = List.filled(64, false), r = List.filled(64, false), fl = List.filled(64, false);
  var placed = false, dead = false, flag = false;
  Iterable<int> nb(int i) sync* {
    final x = i % 8, y = i ~/ 8;
    for (var a = -1; a <= 1; a++) {
      for (var b = -1; b <= 1; b++) {
        final X = x + a, Y = y + b;
        if ((a != 0 || b != 0) && X >= 0 && X < 8 && Y >= 0 && Y < 8) yield Y * 8 + X;
      }
    }
  }
  int cnt(int i) => nb(i).where((j) => m[j]).length;
  void reveal(int i) {
    final st = [i];
    while (st.isNotEmpty) {
      final c = st.removeLast();
      if (r[c] || fl[c]) continue;
      r[c] = true;
      if (!m[c] && cnt(c) == 0) st.addAll(nb(c));
    }
  }
  return sb((set) {
    final won = !dead && placed && r.where((x) => x).length == 54;
    return Column(children: [
      txt(dead ? '💥 Kena ranjau!' : won ? '🎉 Menang!' : 'Ranjau: 10 · ${flag ? "🚩 mode bendera" : "👆 mode buka"}'),
      grid(8, 64, (i) {
        final op = r[i];
        final label = fl[i] && !op ? '🚩' : !op ? (dead && m[i] ? '💣' : '') : m[i] ? '💣' : (cnt(i) == 0 ? '' : '${cnt(i)}');
        return tile(label, op ? const Color(0xFFFFF3B0) : const Color(0xFFD9D2E9), () {
          if (dead || won) return;
          set(() {
            if (flag) { if (!op) fl[i] = !fl[i]; return; }
            if (!placed) {
              placed = true;
              final ex = {i, ...nb(i)};
              var k = 0;
              while (k < 10) {
                final j = rnd.nextInt(64);
                if (!m[j] && !ex.contains(j)) { m[j] = true; k++; }
              }
            }
            if (m[i]) { dead = true; r[i] = true; return; }
            reveal(i);
          });
        }, s: 18);
      }),
      btn('🚩 Ganti mode', () { set(() { flag = !flag; }); })
    ]);
  });
}

Widget rps() {
  var a = 0, b = 0, pl = -1, bt = -1;
  const e = ['✊', '✋', '✌️'];
  return sb((set) => Column(children: [
        txt('Kamu $a  :  $b Bot'),
        Text(pl < 0 ? '❔' : '${e[pl]}  vs  ${e[bt]}', style: big),
        grid(3, 3, (i) => tile(e[i], Colors.white, () {
              set(() {
                pl = i; bt = rnd.nextInt(3);
                if (pl != bt) { if ((pl - bt + 3) % 3 == 1) { a++; } else { b++; } }
              });
            }, s: 40))
      ]));
}

Widget reflex() {
  var st = 0, t0 = 0;
  var res = 'Tap untuk mulai';
  Timer? w;
  void Function(VoidCallback) up = (f) => f();
  return sb((set) {
    up = set;
    return GestureDetector(
        onTap: () => set(() {
              if (st == 0) {
                st = 1; res = 'Tunggu hijau…';
                w = tm(1000 + rnd.nextInt(2500), () { up(() { st = 2; t0 = DateTime.now().millisecondsSinceEpoch; }); });
              } else if (st == 1) {
                w?.cancel(); st = 0; res = 'Terlalu cepat! Tap untuk ulang';
              } else {
                st = 0; res = '⚡ ${DateTime.now().millisecondsSinceEpoch - t0} ms — tap untuk ulang';
              }
            }),
        child: Container(height: 320, margin: const EdgeInsets.all(12), alignment: Alignment.center, decoration: pop(st == 2 ? const Color(0xFF7BE495) : st == 1 ? const Color(0xFFFF8FAB) : Colors.white), child: Text(res, style: ts, textAlign: TextAlign.center)));
  });
}

Widget stroop() {
  const nmz = ['MERAH', 'BIRU', 'HIJAU', 'KUNING'];
  const cl = [Color(0xFFE63946), Color(0xFF1D6FF2), Color(0xFF2BA84A), Color(0xFFE0A800)];
  var s = 0, t = 30, w = 0, c = 0;
  void Function(VoidCallback) up = (f) => f();
  void nx() { w = rnd.nextInt(4); c = rnd.nextInt(4); }
  nx();
  tm(1000, () { if (t > 0) up(() { t--; }); }, rep: true);
  return sb((set) {
    up = set;
    if (t <= 0) return txt('Selesai! Skor $s 🎉');
    return Column(children: [
      txt('⏱ $t   ⭐ $s'),
      const Text('Pilih WARNA tulisan!', style: ts),
      Text(nmz[w], style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: cl[c])),
      grid(2, 4, (i) => tile(nmz[i], Colors.white, () { set(() { if (i == c) s++; nx(); }); }, s: 22))
    ]);
  });
}

Widget guess() {
  final n = 1 + rnd.nextInt(100);
  var g = 50, tries = 0;
  var msg = 'Tebak angka 1–100';
  return sb((set) => Column(children: [
        txt(msg),
        Text('$g', style: big),
        Slider(min: 1, max: 100, divisions: 99, value: g.toDouble(), onChanged: (v) => set(() { g = v.round(); })),
        btn('Tebak!', () { set(() { tries++; msg = g == n ? '🎉 Benar! $tries tebakan' : g < n ? 'Terlalu kecil ⬆️' : 'Terlalu besar ⬇️'; }); })
      ]));
}

Widget hilo() {
  var c = 1 + rnd.nextInt(13), s = 0;
  var msg = 'Kartu berikutnya lebih tinggi atau rendah?';
  String cd(int v) => const ['', 'A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'][v];
  void pick(bool hi) {
    final n = 1 + rnd.nextInt(13);
    if (n == c) { msg = 'Sama! Lanjut'; } else if ((n > c) == hi) { s++; msg = '✅ Benar! (${cd(n)})'; } else { msg = '❌ Salah! Streak akhir $s'; s = 0; }
    c = n;
  }
  return sb((set) => Column(children: [
        txt('Streak: $s'),
        Container(width: 120, height: 170, alignment: Alignment.center, decoration: pop(Colors.white), child: Text(cd(c), style: big)),
        txt(msg),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [btn('⬆️ Tinggi', () { set(() { pick(true); }); }), btn('⬇️ Rendah', () { set(() { pick(false); }); })])
      ]));
}

Widget flood() {
  const C = [Color(0xFFFF6B6B), Color(0xFF4DD4AC), Color(0xFF4D96FF), Color(0xFFFFD93D), Color(0xFFC77DFF), Color(0xFFFF9F1C)];
  final g = List.generate(64, (_) => rnd.nextInt(6));
  var mv = 0;
  void fill(int k) {
    final o = g[0];
    if (o == k) return;
    final st = [0], seen = <int>{};
    while (st.isNotEmpty) {
      final i = st.removeLast();
      if (!seen.add(i) || g[i] != o) continue;
      g[i] = k;
      final x = i % 8, y = i ~/ 8;
      if (x > 0) st.add(i - 1);
      if (x < 7) st.add(i + 1);
      if (y > 0) st.add(i - 8);
      if (y < 7) st.add(i + 8);
    }
    mv++;
  }
  return sb((set) {
    final won = g.every((x) => x == g[0]);
    return Column(children: [
      txt(won ? '🎉 Menang $mv langkah!' : mv >= 22 ? 'Kalah 😢' : 'Langkah $mv / 22'),
      grid(8, 64, (i) => Container(decoration: BoxDecoration(color: C[g[i]], borderRadius: BorderRadius.circular(6))), gap: 2),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var k = 0; k < 6; k++) Padding(padding: const EdgeInsets.all(4), child: GestureDetector(onTap: () { if (!won && mv < 22) set(() { fill(k); }); }, child: Container(width: 44, height: 44, decoration: pop(C[k], 22))))
      ])
    ]);
  });
}

Widget order() {
  final d = List.generate(16, (i) => i + 1)..shuffle(rnd);
  var n = 1;
  final w = Stopwatch()..start();
  return sb((set) => Column(children: [
        txt(n > 16 ? '🎉 ${(w.elapsedMilliseconds / 1000).toStringAsFixed(1)} detik' : 'Cari angka $n'),
        grid(4, 16, (i) => d[i] < n ? Container(decoration: pop(const Color(0xFFE6E6E6), 16)) : tile('${d[i]}', Colors.white, () { if (d[i] == n) set(() { n++; if (n > 16) w.stop(); }); }))
      ]));
}

Widget nim() {
  var n = 21;
  var msg = 'Ambil 1–3 bola. Pengambil bola TERAKHIR kalah!';
  void take(int k) {
    n -= k;
    if (n <= 0) { n = 0; msg = 'Kamu ambil bola terakhir… kalah! 😢'; return; }
    final r = (n - 1) % 4, t = r == 0 ? 1 : r;
    n -= t;
    msg = n == 0 ? 'Bot ambil bola terakhir — kamu menang! 🎉' : 'Bot ambil $t bola';
  }
  return sb((set) => Column(children: [
        txt(msg),
        Padding(padding: const EdgeInsets.all(12), child: Wrap(alignment: WrapAlignment.center, children: [for (var i = 0; i < n; i++) const Text('⚪', style: TextStyle(fontSize: 28))])),
        if (n > 0) Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var k = 1; k <= 3; k++) if (k <= n) btn('Ambil $k', () { set(() { take(k); }); })])
      ]));
}

// ================= MULTIPLAYER (host-authoritative) =================
class MPG {
  final String n, i;
  final int min, max;
  final Map<String, dynamic> Function(int) init;
  final void Function(Map<String, dynamic>, int, dynamic) act;
  final dynamic Function(Map<String, dynamic>, int) bot;
  final Widget Function(Map<String, dynamic>, void Function(dynamic)) view;
  MPG(this.n, this.i, this.min, this.max, this.init, this.act, this.bot, this.view);
}

bool four(List b, int p) {
  for (var r = 0; r < 6; r++) {
    for (var c = 0; c < 7; c++) {
      for (final d in const [[1, 0], [0, 1], [1, 1], [1, -1]]) {
        var k = 0;
        for (; k < 4; k++) {
          final x = c + d[0] * k, y = r + d[1] * k;
          if (x < 0 || x > 6 || y < 0 || y > 5 || b[y * 7 + x] != p) break;
        }
        if (k == 4) return true;
      }
    }
  }
  return false;
}

List? drop(List b, int c, int p) {
  for (var r = 5; r >= 0; r--) {
    if (b[r * 7 + c] < 0) { final n = List.of(b); n[r * 7 + c] = p; return n; }
  }
  return null;
}

final c4 = MPG('Empat Sejajar', '🔴', 2, 4, (n) => {'n': n, 'b': List.filled(42, -1), 'turn': 0, 'win': null}, (s, p, c) {
  final nb = drop(s['b'], c, p);
  if (nb == null) return;
  s['b'] = nb;
  if (four(nb, p)) { s['win'] = p; } else if (nb.every((x) => x >= 0)) { s['win'] = -1; } else { s['turn'] = (p + 1) % (s['n'] as int); }
}, (s, p) {
  final ok = [for (var c = 0; c < 7; c++) if (drop(s['b'], c, p) != null) c];
  final o = [p, for (var q = 0; q < (s['n'] as int); q++) if (q != p) q];
  for (final q in o) { for (final c in ok) { if (four(drop(s['b'], c, q)!, q)) return c; } }
  ok.shuffle(rnd);
  ok.sort((a, b) => (a - 3).abs() - (b - 3).abs());
  return ok[0];
}, (s, send) => grid(7, 42, (i) {
  final v = s['b'][i] as int;
  return tile(v < 0 ? '' : em[v], const Color(0xFFCFE8FF), () => send(i % 7), s: 22);
}, gap: 4));

const lad = {7: 16, 13: 22, 20: 29, 17: 6, 27: 14, 35: 23};
final dice = MPG('Tangga Dadu', '🎲', 2, 6, (n) => {'n': n, 'pos': List.filled(n, 0), 'd': 0, 'turn': 0, 'win': null}, (s, p, m) {
  final d = 1 + rnd.nextInt(6);
  s['d'] = d;
  final List ps = s['pos'];
  final int v = min<int>(40, (ps[p] as int) + d);
  ps[p] = lad[v] ?? v;
  if (ps[p] >= 40) { s['win'] = p; } else if (d != 6) { s['turn'] = (p + 1) % (s['n'] as int); }
}, (s, p) => 0, (s, send) {
  final List ps = s['pos'];
  return Column(children: [
    Text('🎲 ${s['d']}', style: big),
    for (var i = 0; i < ps.length; i++)
      Container(height: 40, margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12), decoration: pop(Colors.white, 20), child: LayoutBuilder(builder: (c, b) => Stack(children: [AnimatedPositioned(duration: const Duration(milliseconds: 400), left: (b.maxWidth - 34) * (ps[i] as int) / 40, child: Text(em[i], style: const TextStyle(fontSize: 26)))]))),
    btn('Lempar Dadu 🎲', () => send(0)),
    const Padding(padding: EdgeInsets.all(8), child: Text('Tangga 7→16 · 13→22 · 20→29\nUlar 17→6 · 27→14 · 35→23\nDapat 6 = lempar lagi', textAlign: TextAlign.center))
  ]);
});

const l3 = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]];
int? tw(List b) {
  for (final l in l3) { if (b[l[0]] >= 0 && b[l[0]] == b[l[1]] && b[l[1]] == b[l[2]]) return b[l[0]] as int; }
  return null;
}

final ttt = MPG('Silang Nol', '❌', 2, 2, (n) => {'n': 2, 'b': List.filled(9, -1), 'turn': 0, 'win': null}, (s, p, c) {
  final List b = s['b'];
  if (b[c] >= 0) return;
  b[c] = p;
  if (tw(b) != null) { s['win'] = p; } else if (b.every((x) => x >= 0)) { s['win'] = -1; } else { s['turn'] = 1 - p; }
}, (s, p) {
  final List b = s['b'];
  final e = [for (var i = 0; i < 9; i++) if (b[i] < 0) i];
  for (final q in [p, 1 - p]) { for (final i in e) { final t = List.of(b); t[i] = q; if (tw(t) == q) return i; } }
  return e.contains(4) ? 4 : e[rnd.nextInt(e.length)];
}, (s, send) => grid(3, 9, (i) {
  final v = s['b'][i] as int;
  return tile(v < 0 ? '' : v == 0 ? '❌' : '⭕', Colors.white, () => send(i), s: 44);
}));

class Lobby extends StatefulWidget {
  final MPG g;
  const Lobby(this.g, {super.key});
  @override
  State<Lobby> createState() => _L();
}

class _L extends State<Lobby> {
  late MPG g = widget.g;
  int n = 2, me = 0, phase = 0;
  bool host = true;
  List<bool> h = [];
  final cn = <int, Socket>{};
  Map<String, dynamic>? s;
  Socket? sock;
  ServerSocket? srv;
  String ip = '', msg = '';
  final ipc = TextEditingController();

  @override
  void dispose() {
    srv?.close();
    sock?.destroy();
    for (final c in cn.values) { c.destroy(); }
    super.dispose();
  }

  void lines(Socket c, void Function(Map) f, void Function() done) {
    c.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen((l) => f(jsonDecode(l) as Map), onDone: done, onError: (_) => done(), cancelOnError: true);
  }

  void snd(Socket c, Map m) {
    try { c.write('${jsonEncode(m)}\n'); } catch (_) {}
  }

  void startBots() {
    h = List.filled(n, false);
    h[0] = true;
    begin();
  }

  Future<void> hostOn() async {
    h = List.filled(n, false);
    h[0] = true;
    try {
      srv = await ServerSocket.bind(InternetAddress.anyIPv4, 4567, shared: true);
    } catch (e) {
      setState(() => msg = 'Gagal membuat room: $e');
      return;
    }
    final l = await NetworkInterface.list(type: InternetAddressType.IPv4);
    ip = l.expand((x) => x.addresses).where((a) => !a.isLoopback).map((a) => a.address).join(' / ');
    if (!mounted) return;
    setState(() => phase = 1);
    srv!.listen((c) {
      final i = h.indexOf(false);
      if (i < 0 || s != null) { c.destroy(); return; }
      h[i] = true;
      cn[i] = c;
      snd(c, {'t': 'w', 'i': i, 'n': n});
      lines(c, (m) { if (m['t'] == 'a') act(i, m['m']); }, () {
        if (!mounted) return;
        h[i] = false;
        cn.remove(i);
        if (s != null) { bc(); loop(); } else { setState(() {}); }
      });
      setState(() {});
    });
  }

  Future<void> join() async {
    try {
      sock = await Socket.connect(ipc.text.trim(), 4567, timeout: const Duration(seconds: 6));
    } catch (e) {
      setState(() => msg = 'Gagal tersambung: $e');
      return;
    }
    host = false;
    setState(() => phase = 1);
    lines(sock!, (m) {
      if (m['t'] == 'w') { me = m['i']; n = m['n']; }
      if (m['t'] == 's') { s = Map<String, dynamic>.from(m['s'] as Map); h = List<bool>.from(m['h'] as List); phase = 2; }
      if (mounted) setState(() {});
    }, () { if (mounted) setState(() { msg = 'Terputus dari host'; phase = 0; s = null; host = true; }); });
  }

  void begin() { s = g.init(n); phase = 2; bc(); loop(); }

  void bc() {
    for (final c in cn.values) { snd(c, {'t': 's', 's': s, 'h': h}); }
    if (mounted) setState(() {});
  }

  void act(int i, dynamic m) {
    final S = s;
    if (S == null || S['win'] != null || S['turn'] != i) return;
    g.act(S, i, m);
    bc();
    loop();
  }

  void loop() {
    final S = s;
    if (S == null || S['win'] != null) return;
    final int t = S['turn'];
    if (h[t]) return;
    Timer(const Duration(milliseconds: 900), () {
      if (mounted && identical(s, S) && S['turn'] == t && S['win'] == null) act(t, g.bot(S, t));
    });
  }

  String nm(int i) => '${em[i]} P${i + 1}${i == me ? " (kamu)" : h[i] ? "" : " 🤖"}';

  @override
  Widget build(BuildContext c) {
    Widget body;
    if (phase == 0) {
      body = Column(children: [
        txt('Jumlah pemain: $n'),
        Slider(min: g.min.toDouble(), max: g.max.toDouble(), divisions: g.max > g.min ? g.max - g.min : null, value: n.toDouble(), onChanged: (v) => setState(() => n = v.round())),
        btn('🤖 Lawan Bot', startBots),
        btn('🏠 Buat Room (WiFi/Hotspot sama)', hostOn),
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: ipc, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'IP host, mis. 192.168.1.5', filled: true, fillColor: Colors.white))),
        btn('🔗 Gabung', join),
        txt(msg)
      ]);
    } else if (phase == 1) {
      body = host
          ? Column(children: [txt('Alamat room (beritahu teman):'), Text(ip.isEmpty ? '-' : ip, style: ts), txt('Pemain terhubung: ${h.where((x) => x).length}/$n\nSlot kosong diisi bot 🤖'), btn('▶ Mulai', begin)])
          : txt('Terhubung! Menunggu host memulai…');
    } else {
      final S = s!;
      final w = S['win'];
      body = Column(children: [
        txt(w == null ? 'Giliran: ${nm(S['turn'])}' : w < 0 ? '🤝 Seri!' : '🏆 ${nm(w)} menang!'),
        g.view(S, (m) => host ? act(0, m) : snd(sock!, {'t': 'a', 'm': m})),
        if (host && w != null) btn('🔁 Main lagi', begin)
      ]);
    }
    return page('${g.i} ${g.n}', body);
  }
}

// ================= HOME =================
class G {
  final String n, i;
  final Color c;
  final Widget Function()? w;
  final MPG? mp;
  G(this.n, this.i, this.c, {this.w, this.mp});
}

final games = <G>[
  G('Pasangan Ajaib', '🧠', const Color(0xFFFFD6E8), w: memory),
  G('Angka 2048', '🔢', const Color(0xFFFFF1B8), w: g2048),
  G('Tikus Usil', '🐹', const Color(0xFFC9F2C7), w: whack),
  G('Simon Warna', '🎨', const Color(0xFFCFE8FF), w: simon),
  G('Kilat Hitung', '➕', const Color(0xFFFFE0B8), w: mathG),
  G('Ular Lapar', '🐍', const Color(0xFFD4F7E0), w: snake),
  G('Lampu Padam', '💡', const Color(0xFFE6DCFF), w: lights),
  G('Geser Angka', '🧩', const Color(0xFFFFE9A8), w: slide),
  G('Ranjau Lucu', '💣', const Color(0xFFE0E0F0), w: mines),
  G('Suit Jari', '✌️', const Color(0xFFFFD0D0), w: rps),
  G('Tes Refleks', '⚡', const Color(0xFFD0F4F7), w: reflex),
  G('Warna Pengecoh', '🌈', const Color(0xFFF7D0F4), w: stroop),
  G('Tebak Angka', '🎯', const Color(0xFFD9F7BE), w: guess),
  G('Kartu Tinggi Rendah', '🃏', const Color(0xFFFFDDC1), w: hilo),
  G('Banjir Warna', '🌊', const Color(0xFFC1E4FF), w: flood),
  G('Urut Angka', '🔟', const Color(0xFFFFF0C1), w: order),
  G('Ambil Bola', '⚪', const Color(0xFFE8E8F8), w: nim),
  G('Empat Sejajar', '🔴', const Color(0xFFFFD0D0), mp: c4),
  G('Tangga Dadu', '🎲', const Color(0xFFFFE9A8), mp: dice),
  G('Silang Nol', '❌', const Color(0xFFD0E8FF), mp: ttt),
];

void open(BuildContext c, G g) {
  if (g.mp != null) { Navigator.push(c, MaterialPageRoute(builder: (_) => Lobby(g.mp!))); return; }
  final mine = <Timer>[];
  tms = mine;
  final w = g.w!();
  Navigator.push(c, MaterialPageRoute(builder: (_) => page('${g.i} ${g.n}', w, act: [IconButton(icon: const Icon(Icons.refresh), onPressed: () { Navigator.pop(c); open(c, g); })]))).then((_) { for (final t in mine) { t.cancel(); } });
}

class Home extends StatelessWidget {
  const Home({super.key});
  @override
  Widget build(BuildContext c) => page(
      '🎈 Pesta Mini',
      GridView.count(
          crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(14), mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.05,
          children: [
            for (final g in games)
              GestureDetector(
                  onTap: () => open(c, g),
                  child: Container(decoration: pop(g.c), alignment: Alignment.center, child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(g.i, style: const TextStyle(fontSize: 40)),
                    Text(g.n, textAlign: TextAlign.center, style: ts),
                    if (g.mp != null) const Text('👥 Multiplayer', style: TextStyle(fontSize: 11, color: ink))
                  ])))
          ]));
}
