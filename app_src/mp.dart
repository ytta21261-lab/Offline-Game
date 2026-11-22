import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'ui.dart';

// ================= Jembatan PeerJS (WebView tersembunyi) =================
const _html = r'''<!DOCTYPE html><html><body><script src="https://unpkg.com/peerjs@1.5.4/dist/peerjs.min.js"></script><script>
let p,cs={},hc;
function B(o){Bridge.postMessage(JSON.stringify(o))}
function X(){try{p&&p.destroy()}catch(e){}p=null;cs={};hc=null}
function H(c){X();if(typeof Peer=='undefined')return B({t:'err',e:'tidak ada internet'});
p=new Peer('pm-'+c);p.on('open',()=>B({t:'open'}));p.on('error',e=>B({t:'err',e:e.type}));
p.on('connection',k=>{k.on('open',()=>{cs[k.peer]=k;B({t:'join',id:k.peer})});k.on('data',d=>B({t:'msg',id:k.peer,d:d}));k.on('close',()=>{delete cs[k.peer];B({t:'left',id:k.peer})})})}
function J(c){X();if(typeof Peer=='undefined')return B({t:'err',e:'tidak ada internet'});
p=new Peer();p.on('error',e=>B({t:'err',e:e.type}));
p.on('open',()=>{hc=p.connect('pm-'+c);hc.on('open',()=>B({t:'open'}));hc.on('data',d=>B({t:'msg',d:d}));hc.on('close',()=>B({t:'closed'}))})}
function S(to,d){if(to=='*'){for(const k in cs)cs[k].send(d)}else if(to=='host'){hc&&hc.send(d)}else{cs[to]&&cs[to].send(d)}}
</script></body></html>''';

class Net {
  final wc = WebViewController();
  bool ready = false; final q = <String>[]; void Function(Map)? onMsg;
  Net() {
    wc
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('Bridge', onMessageReceived: (m) { try { onMsg?.call(jsonDecode(m.message) as Map); } catch (_) {} })
      ..setNavigationDelegate(NavigationDelegate(onPageFinished: (_) { ready = true; for (final s in q) { wc.runJavaScript(s); } q.clear(); }))
      ..loadHtmlString(_html, baseUrl: 'https://pesta.local/');
  }
  void _js(String s) { if (ready) { wc.runJavaScript(s); } else { q.add(s); } }
  void host(String code) => _js("H('$code')");
  void join(String code) => _js("J('$code')");
  void send(String to, Map m) => _js('S(${jsonEncode(to)},${jsonEncode(jsonEncode(m))})');
  void close() { try { wc.runJavaScript('X()'); } catch (_) {} }
}

// ================= Kerangka game multiplayer =================
class MpCtx {
  final int me; final List<bool> human; final void Function(dynamic) send;
  MpCtx(this.me, this.human, this.send);
}
abstract class MpGame {
  String get title;
  int get minP; int get maxP;
  Map<String, dynamic> init(int n);
  bool act(Map<String, dynamic> s, int p, dynamic m);
  dynamic bot(Map<String, dynamic> s, int p);
  Widget view(BuildContext c, Map<String, dynamic> s, MpCtx x);
}

class MpScreen extends StatefulWidget {
  final MpGame g; final String icon;
  const MpScreen(this.g, this.icon, {super.key});
  @override State<MpScreen> createState() => _MpS();
}
class _MpS extends State<MpScreen> {
  String phase = 'lobby', info = '', code = '';
  int n = 2, me = 0; bool host = true; Net? net; List<bool> human = [];
  final slot = <String, int>{}; Map<String, dynamic>? s; final tc = TextEditingController();
  MpGame get g => widget.g;
  @override void dispose() { net?.close(); tc.dispose(); super.dispose(); }

  String _nm(int i) => '${EM[i]} P${i + 1}${i == me ? ' (kamu)' : (i < human.length && human[i] ? '' : ' 🤖')}';
  void _bots() { host = true; me = 0; human = [true, ...List.filled(n - 1, false)]; _begin(); }
  void _hostOnline() {
    host = true; me = 0; human = [true, ...List.filled(n - 1, false)];
    code = List.generate(5, (_) => 'abcdefghjkmnpqrstuvwxyz23456789'[rnd.nextInt(31)]).join();
    net = Net()..onMsg = _onMsg; net!.host(code);
    setState(() { phase = 'wait'; info = ''; });
  }
  void _join() {
    final c = tc.text.trim().toLowerCase(); if (c.isEmpty) return;
    host = false; net = Net()..onMsg = _onMsg; net!.join(c);
    setState(() { phase = 'joining'; info = ''; });
  }
  void _onMsg(Map m) {
    if (!mounted) return;
    final t = m['t'];
    if (t == 'err') { setState(() { info = 'Gagal: ${m['e']}'; if (!host && phase != 'play') phase = 'lobby'; }); return; }
    if (host) {
      if (t == 'join') {
        final id = m['id'] as String; final i = human.indexOf(false);
        if (i < 0 || s != null) { net!.send(id, {'t': 'full'}); return; }
        slot[id] = i; human[i] = true; net!.send(id, {'t': 'w', 'i': i, 'n': n}); setState(() {});
      } else if (t == 'msg') {
        final d = jsonDecode(m['d'] as String); final i = slot[m['id']];
        if (d['t'] == 'a' && i != null) _act(i, d['m']);
      } else if (t == 'left') {
        final i = slot.remove(m['id']);
        if (i != null) { human[i] = false; if (s != null) { _bc(); _loop(); } setState(() {}); }
      }
    } else {
      if (t == 'closed') { setState(() { info = 'Terputus dari host'; phase = 'lobby'; s = null; }); return; }
      if (t == 'msg') {
        final d = jsonDecode(m['d'] as String);
        if (d['t'] == 'w') { setState(() { me = d['i']; n = d['n']; phase = 'waitc'; }); }
        else if (d['t'] == 'full') { setState(() { info = 'Room penuh'; phase = 'lobby'; }); }
        else if (d['t'] == 's' && (phase == 'waitc' || phase == 'play')) {
          setState(() { s = Map<String, dynamic>.from(d['s']); human = List<bool>.from(d['h']); phase = 'play'; });
        }
      }
    }
  }
  void _bc() { net?.send('*', {'t': 's', 's': s, 'h': human}); setState(() {}); }
  void _begin() { s = g.init(n); phase = 'play'; _bc(); _loop(); }
  void _act(int i, dynamic m) {
    final st = s;
    if (st == null || st['win'] != null || st['turn'] != i) return;
    if (!g.act(st, i, m)) return;
    HapticFeedback.selectionClick(); _bc(); _loop();
  }
  void _loop() {
    final cur = s!; final t = cur['turn'] as int;
    if (cur['win'] != null || human[t]) return;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || !identical(s, cur) || cur['turn'] != t || cur['win'] != null) return;
      _act(t, g.bot(cur, t));
    });
  }
  void _send(dynamic m) { if (host) { _act(0, m); } else { net!.send('host', {'t': 'a', 'm': m}); } }

  Widget _lobby() => page([
        cart(Colors.white, pad: const EdgeInsets.all(16), child: Column(children: [
          Text(g.maxP > g.minP ? 'Jumlah pemain: $n' : 'Pemain: ${g.minP}', style: ts(20)),
          if (g.maxP > g.minP) Slider(min: g.minP.toDouble(), max: g.maxP.toDouble(), divisions: g.maxP - g.minP, value: cl(n.toDouble(), g.minP.toDouble(), g.maxP.toDouble()), activeColor: pink, onChanged: (v) => setState(() => n = v.round())),
          const SizedBox(height: 8), btn('🤖 Lawan Bot', _bots), const SizedBox(height: 10), btn('🏠 Buat Room Online', _hostOnline, c: const Color(0xFF4DB6E8)),
          const SizedBox(height: 6), Text('Slot kosong diisi bot', style: ts(12, const Color(0xFF8A7A9B))),
        ])),
        const SizedBox(height: 16),
        cart(Colors.white, pad: const EdgeInsets.all(16), child: Column(children: [
          Text('Gabung teman', style: ts(20)), const SizedBox(height: 8),
          SizedBox(width: 160, child: TextField(controller: tc, textAlign: TextAlign.center, maxLength: 5, textCapitalization: TextCapitalization.none, style: ts(22), decoration: const InputDecoration(hintText: 'KODE', counterText: '', border: OutlineInputBorder()))),
          const SizedBox(height: 8), btn('🔗 Gabung', _join, c: const Color(0xFF3DBE6C)),
        ])),
        if (info.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(info, style: ts(16, Colors.red))),
      ]);
  Widget _wait() => page([cart(Colors.white, pad: const EdgeInsets.all(20), child: Column(children: [
        Text('Kode room', style: ts(18)), Text(code.toUpperCase(), style: ts(48)),
        const SizedBox(height: 6), Text('Pemain online: ${human.where((x) => x).length}/$n', style: ts(18)),
        Text('Slot kosong diisi bot 🤖', style: ts(13, const Color(0xFF8A7A9B))), const SizedBox(height: 12),
        btn('▶ Mulai', _begin, c: const Color(0xFF3DBE6C)),
        if (info.isNotEmpty) Text(info, style: ts(14, Colors.red)),
      ]))]);
  Widget _play() {
    final st = s!; final w = st['win']; final t = st['turn'] as int;
    return Column(children: [
      const SizedBox(height: 8),
      status(w == null ? 'Giliran: ${_nm(t)}' : (w < 0 ? '🤝 Seri!' : '🏆 ${_nm(w)} menang!')),
      Expanded(child: Center(child: SingleChildScrollView(child: g.view(context, st, MpCtx(me, human, _send))))),
      if (w != null && host) Padding(padding: const EdgeInsets.all(12), child: btn('🔁 Main lagi', _begin)),
    ]);
  }
  @override Widget build(BuildContext context) {
    Widget body;
    switch (phase) {
      case 'lobby': body = _lobby(); break;
      case 'wait': body = _wait(); break;
      case 'play': body = _play(); break;
      default: body = page([Text(phase == 'joining' ? '⏳ Menyambung…' : '⏳ Menunggu host memulai…', style: ts(22)), if (info.isNotEmpty) Text(info, style: ts(14, Colors.red))]);
    }
    return Scaffold(body: Bg(child: SafeArea(child: Stack(children: [
      Column(children: [header(context, '${widget.icon} ${g.title}'), Expanded(child: body)]),
      if (net != null) Positioned(left: 0, top: 0, width: 1, height: 1, child: WebViewWidget(controller: net!.wc)),
    ]))));
  }
}

// ================= Empat Sejajar =================
class Connect4 extends MpGame {
  String get title => 'Empat Sejajar';
  @override int get minP => 2; @override int get maxP => 4;
  @override Map<String, dynamic> init(int n) => {'n': n, 'b': List.filled(42, -1), 'turn': 0, 'win': null};
  List<int>? _drop(List<int> b, int c, int p) {
    for (int r = 5; r >= 0; r--) { if (b[r * 7 + c] < 0) { final x = [...b]; x[r * 7 + c] = p; return x; } }
    return null;
  }
  bool _four(List<int> b, int p) {
    for (int r = 0; r < 6; r++) { for (int c = 0; c < 7; c++) { for (final d in const [[1, 0], [0, 1], [1, 1], [1, -1]]) {
      int k = 0;
      for (; k < 4; k++) { final x = c + d[0] * k, y = r + d[1] * k; if (x < 0 || x > 6 || y < 0 || y > 5 || b[y * 7 + x] != p) break; }
      if (k == 4) return true;
    } } }
    return false;
  }
  @override bool act(Map<String, dynamic> s, int p, dynamic m) {
    final nb = _drop(List<int>.from(s['b']), m as int, p); if (nb == null) return false;
    s['b'] = nb;
    if (_four(nb, p)) { s['win'] = p; } else if (nb.every((x) => x >= 0)) { s['win'] = -1; } else { s['turn'] = (p + 1) % (s['n'] as int); }
    return true;
  }
  @override dynamic bot(Map<String, dynamic> s, int p) {
    final b = List<int>.from(s['b']); final ok = [for (int c = 0; c < 7; c++) if (_drop(b, c, p) != null) c];
    final order = [p, ...[for (int q = 0; q < (s['n'] as int); q++) if (q != p) q]];
    for (final q in order) { for (final c in ok) { if (_four(_drop(b, c, q)!, q)) return c; } }
    ok.sort((a, c) => ((a - 3).abs() - (c - 3).abs()) * 2 + rnd.nextInt(3) - 1);
    return ok.first;
  }
  @override Widget view(BuildContext c, Map<String, dynamic> s, MpCtx x) {
    final b = List<int>.from(s['b']);
    return Padding(padding: const EdgeInsets.all(12), child: cart(const Color(0xFF5B8DEF), r: 22, pad: const EdgeInsets.all(8), child: AspectRatio(aspectRatio: 7 / 6, child: Column(children: [
      for (int r = 0; r < 6; r++) Expanded(child: Row(children: [
        for (int cc = 0; cc < 7; cc++) Expanded(child: GestureDetector(onTap: () => x.send(cc), child: Padding(padding: const EdgeInsets.all(2), child: Container(
            decoration: BoxDecoration(color: const Color(0xFFEAF2FF), shape: BoxShape.circle, border: Border.all(color: ink, width: 2)),
            child: AnimatedScale(scale: b[r * 7 + cc] < 0 ? 0 : 1, duration: const Duration(milliseconds: 450), curve: Curves.bounceOut,
                child: Container(decoration: BoxDecoration(color: PC[max(0, b[r * 7 + cc])], shape: BoxShape.circle, border: Border.all(color: ink, width: 2))))))))
      ])),
    ]))));
  }
}

// ================= Tangga Dadu =================
const _jm = {7: 16, 13: 22, 20: 29, 17: 6, 27: 14, 35: 23};
Offset _cellC(int n, double cs) {
  if (n <= 0) return Offset(cs * 4, cs * 5.5);
  final i = n - 1, r = i ~/ 8; int c = i % 8; if (r.isOdd) c = 7 - c;
  return Offset((c + .5) * cs, (4 - r + .5) * cs);
}
class _BoardP extends CustomPainter {
  @override void paint(Canvas cv, Size s) {
    final cs = s.width / 8;
    for (int n = 1; n <= 40; n++) {
      final o = _cellC(n, cs); final r = Rect.fromCenter(center: o, width: cs, height: cs);
      cv.drawRect(r, Paint()..color = n % 2 == 0 ? const Color(0xFFFFF3D6) : const Color(0xFFD6F0FF));
      final tp = TextPainter(text: TextSpan(text: '$n', style: TextStyle(fontSize: cs * .28, color: ink.withOpacity(.5), fontWeight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
      tp.paint(cv, r.topLeft + const Offset(3, 2));
    }
    cv.drawRect(Rect.fromLTWH(0, 0, s.width, cs * 5), Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = ink);
    _jm.forEach((a, b) {
      final p1 = _cellC(a, cs), p2 = _cellC(b, cs); final up = b > a;
      final col = up ? const Color(0xFF2BA84A) : const Color(0xFFE63946);
      final paint = Paint()..color = col..strokeWidth = cs * .14..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
      if (up) { cv.drawLine(p1, p2, paint); }
      else { cv.drawPath(Path()..moveTo(p1.dx, p1.dy)..quadraticBezierTo((p1.dx + p2.dx) / 2 + cs * .9, (p1.dy + p2.dy) / 2, p2.dx, p2.dy), paint); }
      cv.drawCircle(p2, cs * .13, Paint()..color = col);
    });
    final tp = TextPainter(text: TextSpan(text: '🏁 START', style: TextStyle(fontSize: cs * .4, fontWeight: FontWeight.w900, color: ink)), textDirection: TextDirection.ltr)..layout();
    tp.paint(cv, Offset(cs * 4 - tp.width / 2 - cs * 1.2, cs * 5.5 - tp.height / 2));
  }
  @override bool shouldRepaint(_BoardP o) => false;
}
class DiceLadder extends MpGame {
  String get title => 'Tangga Dadu';
  @override int get minP => 2; @override int get maxP => 6;
  @override Map<String, dynamic> init(int n) => {'n': n, 'pos': List.filled(n, 0), 'd': 0, 'cnt': 0, 'turn': 0, 'win': null};
  @override bool act(Map<String, dynamic> s, int p, dynamic m) {
    final pos = List<int>.from(s['pos']); final d = 1 + rnd.nextInt(6);
    final v = min(40, pos[p] + d); pos[p] = _jm[v] ?? v;
    s['pos'] = pos; s['d'] = d; s['cnt'] = (s['cnt'] as int) + 1;
    if (pos[p] >= 40) { s['win'] = p; } else if (d != 6) { s['turn'] = (p + 1) % (s['n'] as int); }
    return true;
  }
  @override dynamic bot(Map<String, dynamic> s, int p) => 0;
  @override Widget view(BuildContext c, Map<String, dynamic> s, MpCtx x) {
    final pos = List<int>.from(s['pos']); final d = s['d'] as int; final mine = s['turn'] == x.me && s['win'] == null;
    return Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      cart(Colors.white, r: 16, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: LayoutBuilder(builder: (c, k) {
        final cs = k.maxWidth / 8;
        return SizedBox(width: k.maxWidth, height: cs * 6, child: Stack(children: [
          CustomPaint(size: Size(k.maxWidth, cs * 6), painter: _BoardP()),
          for (int i = 0; i < pos.length; i++) AnimatedPositioned(
              duration: const Duration(milliseconds: 600), curve: Curves.easeInOut,
              left: _cellC(pos[i], cs).dx - cs * .26 + (i % 3 - 1) * cs * .2, top: _cellC(pos[i], cs).dy - cs * .3 + (i ~/ 3 - .5) * cs * .22,
              child: Text(EM[i], style: TextStyle(fontSize: cs * .5))),
        ]));
      }))),
      const SizedBox(height: 10),
      AnimatedSwitcher(duration: const Duration(milliseconds: 450),
          transitionBuilder: (w, a) => RotationTransition(turns: Tween<double>(begin: .5, end: 0.0).animate(a), child: ScaleTransition(scale: a, child: w)),
          child: Text(d == 0 ? '🎲' : '⚀⚁⚂⚃⚄⚅'[d - 1], key: ValueKey(s['cnt']), style: const TextStyle(fontSize: 64))),
      Opacity(opacity: mine ? 1 : .4, child: btn('Lempar Dadu 🎲', () => x.send(0))),
      const SizedBox(height: 6),
      Text('🟩 Tangga naik · 🟥 Ular turun · Angka 6 = lempar lagi', textAlign: TextAlign.center, style: ts(12, const Color(0xFF8A7A9B))),
    ]));
  }
}

// ================= Silang Lingkar =================
class TicTacToe extends MpGame {
  String get title => 'Silang Lingkar';
  @override int get minP => 2; @override int get maxP => 2;
  static const _L = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]];
  bool _w(List<int> b, int p) => _L.any((l) => l.every((i) => b[i] == p));
  @override Map<String, dynamic> init(int n) => {'n': 2, 'b': List.filled(9, -1), 'turn': 0, 'win': null};
  @override bool act(Map<String, dynamic> s, int p, dynamic m) {
    final b = List<int>.from(s['b']); final i = m as int; if (b[i] >= 0) return false;
    b[i] = p; s['b'] = b;
    if (_w(b, p)) { s['win'] = p; } else if (!b.contains(-1)) { s['win'] = -1; } else { s['turn'] = 1 - p; }
    return true;
  }
  @override dynamic bot(Map<String, dynamic> s, int p) {
    final b = List<int>.from(s['b']); final e = [for (int i = 0; i < 9; i++) if (b[i] < 0) i];
    for (final q in [p, 1 - p]) { for (final i in e) { final t = [...b]; t[i] = q; if (_w(t, q)) return i; } }
    if (e.contains(4)) return 4;
    return e[rnd.nextInt(e.length)];
  }
  @override Widget view(BuildContext c, Map<String, dynamic> s, MpCtx x) {
    final b = List<int>.from(s['b']);
    return Padding(padding: const EdgeInsets.all(24), child: AspectRatio(aspectRatio: 1, child: GridView.count(physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10, children: [
      for (int i = 0; i < 9; i++) GestureDetector(onTap: () => x.send(i), child: cart(Colors.white, r: 20,
          child: AnimatedScale(scale: b[i] < 0 ? 0 : 1, duration: const Duration(milliseconds: 400), curve: Curves.elasticOut, child: Text(b[i] == 1 ? '⭕' : '❌', style: const TextStyle(fontSize: 52))))),
    ])));
  }
}

// ================= Tebak Angka =================
class GuessGame extends MpGame {
  String get title => 'Tebak Angka';
  @override int get minP => 2; @override int get maxP => 6;
  @override Map<String, dynamic> init(int n) => {'n': n, 'secret': 1 + rnd.nextInt(100), 'lo': 1, 'hi': 100, 'log': <String>[], 'turn': 0, 'win': null};
  @override bool act(Map<String, dynamic> s, int p, dynamic m) {
    final g = m as int; final sec = s['secret'] as int; final log = List<String>.from(s['log']);
    if (g < s['lo'] || g > s['hi']) return false;
    if (g == sec) { s['win'] = p; log.add('${EM[p]} $g ✅ BENAR!'); }
    else {
      if (g < sec) { s['lo'] = g + 1; log.add('${EM[p]} $g ⬆️ terlalu kecil'); } else { s['hi'] = g - 1; log.add('${EM[p]} $g ⬇️ terlalu besar'); }
      s['turn'] = (p + 1) % (s['n'] as int);
    }
    s['log'] = log; return true;
  }
  @override dynamic bot(Map<String, dynamic> s, int p) {
    final lo = s['lo'] as int, hi = s['hi'] as int;
    return min(hi, max(lo, ((lo + hi) / 2).round() + rnd.nextInt(5) - 2));
  }
  @override Widget view(BuildContext c, Map<String, dynamic> s, MpCtx x) => _GuessPad(s, x);
}
class _GuessPad extends StatefulWidget {
  final Map<String, dynamic> s; final MpCtx x;
  const _GuessPad(this.s, this.x);
  @override State<_GuessPad> createState() => _GuessPadS();
}
class _GuessPadS extends State<_GuessPad> {
  int v = 50;
  @override Widget build(BuildContext c) {
    final s = widget.s; final lo = s['lo'] as int, hi = s['hi'] as int; final log = List<String>.from(s['log']);
    final val = min(hi, max(lo, v)); final mine = s['turn'] == widget.x.me && s['win'] == null;
    Widget step(String t, int d) => Pressable(onTap: () => setState(() => v = min(hi, max(lo, val + d))), child: cart(sky, w: 54, h: 48, r: 14, child: Text(t, style: ts(16, Colors.white))));
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Text('Angkanya antara $lo – $hi', style: ts(20)), const SizedBox(height: 12),
      Text('$val', style: ts(64)), const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [step('−10', -10), const SizedBox(width: 8), step('−1', -1), const SizedBox(width: 8), step('+1', 1), const SizedBox(width: 8), step('+10', 10)]),
      const SizedBox(height: 12),
      Opacity(opacity: mine ? 1 : .4, child: btn('🔮 Tebak!', () => widget.x.send(val))),
      const SizedBox(height: 12),
      for (final l in log.reversed.take(5)) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(l, style: ts(15))),
    ]));
  }
}
