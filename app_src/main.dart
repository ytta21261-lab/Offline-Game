import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui.dart';
import 'solo1.dart';
import 'solo2.dart';
import 'mp.dart';
import 'local1.dart';
import 'local2.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.load();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PestaApp());
}

class PestaApp extends StatelessWidget {
  const PestaApp({super.key});
  @override Widget build(BuildContext c) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Pesta Mini', theme: ThemeData(useMaterial3: true, colorSchemeSeed: pink), home: const Home());
}

// kind: 1 = solo, 2 = online/bot, 3 = lokal (satu HP)
class GI {
  final String n, en, i; final Color c; final int kind;
  final Widget Function()? solo; final MpGame? mp; final Widget Function(int)? local;
  GI(this.n, this.en, this.i, this.c, this.kind, {this.solo, this.mp, this.local});
  String get name => Settings.lang.value == 'en' ? en : n;
}
Color _c(int v) => Color(v);
final games = <GI>[
  GI('Pasangan Ajaib', 'Magic Pairs', '🧠', _c(0xFFFFD6E8), 1, solo: () => const MemoryGame()),
  GI('Angka 2048', '2048', '🔢', _c(0xFFFFF1B8), 1, solo: () => const G2048()),
  GI('Tikus Usil', 'Naughty Mole', '🐹', _c(0xFFC9F2C7), 1, solo: () => const WhackGame()),
  GI('Simon Warna', 'Simon Colors', '🎨', _c(0xFFCFE8FF), 1, solo: () => const SimonGame()),
  GI('Kilat Hitung', 'Math Flash', '➕', _c(0xFFFFE0B8), 1, solo: () => const MathGame()),
  GI('Ular Lapar', 'Hungry Snake', '🐍', _c(0xFFD4F7E0), 1, solo: () => const SnakeGame()),
  GI('Lampu Padam', 'Lights Out', '💡', _c(0xFFE6DCFF), 1, solo: () => const LightsGame()),
  GI('Pop Balon', 'Balloon Pop', '🎈', _c(0xFFFFD0D0), 1, solo: () => const BalloonGame()),
  GI('Menara Tumpuk', 'Tower Stack', '🧱', _c(0xFFFFE9A8), 1, solo: () => const StackGame()),
  GI('Burung Loncat', 'Hoppy Bird', '🐥', _c(0xFFD0F0FF), 1, solo: () => const FlappyGame()),
  GI('Geser Angka', 'Slide Puzzle', '🧩', _c(0xFFE0F7C8), 1, solo: () => const SlideGame()),
  GI('Cari Ranjau', 'Minesweeper', '💣', _c(0xFFE8E0F5), 1, solo: () => const MineGame()),
  GI('Warna Tipu', 'Color Trick', '🌈', _c(0xFFFFDDEE), 1, solo: () => const ColorGame()),
  GI('Ubin Piano', 'Piano Tiles', '🎹', _c(0xFFDDE8FF), 1, solo: () => const TilesGame()),
  GI('Urut Angka', 'Number Order', '🔟', _c(0xFFFFEBC9), 1, solo: () => const OrderGame()),
  GI('Pingpong Bot', 'Pingpong Bot', '🏓', _c(0xFFD7F5E9), 1, solo: () => const PongGame()),
  GI('Empat Sejajar', 'Connect Four', '🔴', _c(0xFFFFD0D0), 2, mp: Connect4()),
  GI('Tangga Dadu', 'Dice Ladder', '🎲', _c(0xFFFFE9A8), 2, mp: DiceLadder()),
  GI('Silang Lingkar', 'Tic Tac Toe', '❌', _c(0xFFDDF3FF), 2, mp: TicTacToe()),
  GI('Tebak Angka', 'Number Guess', '🔮', _c(0xFFEBDDFF), 2, mp: GuessGame()),
  GI('Adu Ketuk', 'Tap Battle', '👆', _c(0xFFFFD6E8), 3, local: (n) => TapRace(n)),
  GI('Tarik Tambang', 'Tug of War', '🪢', _c(0xFFFFF1B8), 3, local: (n) => TugGame(n)),
  GI('Reaksi Kilat', 'Lightning Reflex', '⚡', _c(0xFFC9F2C7), 3, local: (n) => ReactGame(n)),
  GI('Duel Hitung', 'Math Duel', '🧮', _c(0xFFCFE8FF), 3, local: (n) => MathDuel(n)),
  GI('Bom Estafet', 'Hot Potato Bomb', '💣', _c(0xFFFFE0B8), 3, local: (n) => BombGame(n)),
  GI('Henti di Tengah', 'Stop in the Middle', '🎯', _c(0xFFD4F7E0), 3, local: (n) => StopBar(n)),
  GI('Hitung Detik', 'Count the Seconds', '⏱️', _c(0xFFE6DCFF), 3, local: (n) => HoldGame(n)),
  GI('Balap Lari', 'Foot Race', '🏃', _c(0xFFFFD0D0), 3, local: (n) => RunGame(n)),
  GI('Pop Rebutan', 'Pop Rush', '🎈', _c(0xFFFFE9A8), 3, local: (n) => PopRace(n)),
  GI('Gunting Batu Kertas', 'Rock Paper Scissors', '✌️', _c(0xFFD0F0FF), 3, local: (n) => RpsGame(n)),
  GI('Dadu Serakah', 'Greedy Dice', '🎲', _c(0xFFE0F7C8), 3, local: (n) => PigGame(n)),
  GI('Kotak Bom', 'Bomb Boxes', '🎁', _c(0xFFE8E0F5), 3, local: (n) => BoxBomb(n)),
  GI('Nim Batang', 'Stick Nim', '🥢', _c(0xFFFFDDEE), 3, local: (n) => NimGame(n)),
  GI('Kartu Tinggi', 'High Card', '🃏', _c(0xFFDDE8FF), 3, local: (n) => HiLoGame(n)),
  GI('Rebut Wilayah', 'Territory', '🏴', _c(0xFFFFEBC9), 3, local: (n) => TerrGame(n)),
  GI('Titik Kotak', 'Dots & Boxes', '🔲', _c(0xFFD7F5E9), 3, local: (n) => DotsGame(n)),
  GI('Pompa Balon', 'Balloon Pump', '🎈', _c(0xFFFFD6E8), 3, local: (n) => PumpGame(n)),
  GI('Empat Berderet', 'Four Together', '🟣', _c(0xFFFFF1B8), 3, local: (n) => FiveGame(n)),
  GI('Memori Giliran', 'Memory Turns', '🍓', _c(0xFFC9F2C7), 3, local: (n) => MemTurn(n)),
  GI('Lempar Dart', 'Dart Throw', '🎯', _c(0xFFCFE8FF), 3, local: (n) => DartGame(n)),
];

Route<T> _route<T>(Widget p) => PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => p,
    transitionsBuilder: (_, a, __, ch) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: FadeTransition(opacity: a, child: ch)));

class Home extends StatefulWidget {
  const Home({super.key});
  @override State<Home> createState() => _HomeS();
}
class _HomeS extends State<Home> {
  int tab = 0;
  void _open(BuildContext c, GI g) {
    final Widget p = g.mp != null ? MpScreen(g.mp!, g.i)
        : g.local != null ? LocalScreen(title: g.name, icon: g.i, build: g.local!)
        : GameScaffold(title: g.name, icon: g.i, build: g.solo!);
    Navigator.push(c, _route(p));
  }
  @override Widget build(BuildContext context) => ValueListenableBuilder<String>(valueListenable: Settings.lang, builder: (context, lang, _) {
        final list = [for (final g in games) if (tab == 0 || g.kind == tab) g];
        const tabs = ['Semua', 'Solo', 'Online', 'Lokal'];
        return Scaffold(body: Bg(child: SafeArea(child: Column(children: [
          const SizedBox(height: 8),
          Row(children: [
            const SizedBox(width: 60),
            Expanded(child: Center(child: TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 800), curve: Curves.elasticOut, builder: (c, v, w) => Transform.scale(scale: v, child: w), child: Text('🎈 Pesta Mini', style: ts(34))))),
            Padding(padding: const EdgeInsets.only(right: 12), child: Pressable(onTap: () => Navigator.push(context, _route(const SettingsScreen())), child: cart(sun, w: 48, h: 48, child: const Icon(Icons.settings_rounded, color: ink)))),
          ]),
          Tx('${games.length} game seru: offline, lawan bot, online & satu HP!', style: ts(12, const Color(0xFF8A7A9B))),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (int i = 0; i < 4; i++) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Pressable(onTap: () => setState(() => tab = i), child: cart(tab == i ? pink : Colors.white, r: 16, sh: tab == i ? 2 : 4, pad: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Tx(tabs[i], style: ts(14, tab == i ? Colors.white : ink)))))]),
          Expanded(child: GridView.builder(
              key: ValueKey(tab),
              padding: const EdgeInsets.all(14),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.1),
              itemCount: list.length,
              itemBuilder: (ctx, i) {
                final g = list[i];
                return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0), duration: Duration(milliseconds: 350 + (i % 8) * 70), curve: Curves.elasticOut,
                    builder: (c, v, w) => Transform.scale(scale: v, child: w),
                    child: Pressable(onTap: () => _open(ctx, g), child: cart(g.c, r: 24, sh: 6, child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(g.i, style: const TextStyle(fontSize: 44)), const SizedBox(height: 4),
                      Text(g.name, textAlign: TextAlign.center, style: ts(15)),
                      Text(g.kind == 2 ? '👥 Online' : g.kind == 3 ? '📱 2-4 Pemain' : '', style: ts(11)),
                    ]))));
              })),
        ]))));
      });
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  Widget _lang(String code, String label, String cur) => Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Pressable(
      onTap: () { Settings.lang.value = code; Settings.save(); },
      child: cart(cur == code ? sun : Colors.white, pad: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Text(label, style: ts(17)))));
  @override Widget build(BuildContext context) => ValueListenableBuilder<String>(valueListenable: Settings.lang, builder: (context, lang, _) => Scaffold(body: Bg(child: SafeArea(child: Column(children: [
        header(context, '⚙️ ${L('Pengaturan')}'),
        Expanded(child: page([
          cart(Colors.white, pad: const EdgeInsets.all(16), child: Column(children: [
            Tx('Bahasa', style: ts(22)), const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [_lang('id', '🇮🇩 Indonesia', lang), _lang('en', '🇬🇧 English', lang)]),
          ])),
          const SizedBox(height: 18),
          cart(Colors.white, pad: const EdgeInsets.all(16), child: ValueListenableBuilder<double>(valueListenable: Settings.vol, builder: (context, v, _) => Column(children: [
            Tx('Volume suara', style: ts(22)),
            Row(children: [
              Text(v <= 0 ? '🔇' : v < .5 ? '🔈' : '🔊', style: const TextStyle(fontSize: 26)),
              Expanded(child: Slider(value: v, min: 0, max: 1, divisions: 20, activeColor: pink, onChanged: (x) => Settings.vol.value = x, onChangeEnd: (x) { Settings.save(); Sfx.good(); })),
              SizedBox(width: 48, child: Text('${(v * 100).round()}%', style: ts(16))),
            ]),
            btn('🔔 ${L('Tes suara')}', () => Sfx.win(), c: sky),
          ]))),
        ])),
      ])))));
}
