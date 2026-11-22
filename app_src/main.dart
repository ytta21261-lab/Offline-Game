import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui.dart';
import 'solo1.dart';
import 'solo2.dart';
import 'mp.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PestaApp());
}

class PestaApp extends StatelessWidget {
  const PestaApp({super.key});
  @override Widget build(BuildContext c) => MaterialApp(debugShowCheckedModeBanner: false, title: 'Pesta Mini', theme: ThemeData(useMaterial3: true, colorSchemeSeed: pink), home: const Home());
}

class GI {
  final String n, i; final Color c; final Widget Function()? solo; final MpGame? mp;
  GI(this.n, this.i, this.c, {this.solo, this.mp});
}

final games = <GI>[
  GI('Pasangan Ajaib', '🧠', const Color(0xFFFFD6E8), solo: () => const MemoryGame()),
  GI('Angka 2048', '🔢', const Color(0xFFFFF1B8), solo: () => const G2048()),
  GI('Tikus Usil', '🐹', const Color(0xFFC9F2C7), solo: () => const WhackGame()),
  GI('Simon Warna', '🎨', const Color(0xFFCFE8FF), solo: () => const SimonGame()),
  GI('Kilat Hitung', '➕', const Color(0xFFFFE0B8), solo: () => const MathGame()),
  GI('Ular Lapar', '🐍', const Color(0xFFD4F7E0), solo: () => const SnakeGame()),
  GI('Lampu Padam', '💡', const Color(0xFFE6DCFF), solo: () => const LightsGame()),
  GI('Pop Balon', '🎈', const Color(0xFFFFD0D0), solo: () => const BalloonGame()),
  GI('Menara Tumpuk', '🧱', const Color(0xFFFFE9A8), solo: () => const StackGame()),
  GI('Burung Loncat', '🐥', const Color(0xFFD0F0FF), solo: () => const FlappyGame()),
  GI('Geser Angka', '🧩', const Color(0xFFE0F7C8), solo: () => const SlideGame()),
  GI('Cari Ranjau', '💣', const Color(0xFFE8E0F5), solo: () => const MineGame()),
  GI('Warna Tipu', '🌈', const Color(0xFFFFDDEE), solo: () => const ColorGame()),
  GI('Ubin Piano', '🎹', const Color(0xFFDDE8FF), solo: () => const TilesGame()),
  GI('Urut Angka', '🔟', const Color(0xFFFFEBC9), solo: () => const OrderGame()),
  GI('Pingpong Bot', '🏓', const Color(0xFFD7F5E9), solo: () => const PongGame()),
  GI('Empat Sejajar', '🔴', const Color(0xFFFFD0D0), mp: Connect4()),
  GI('Tangga Dadu', '🎲', const Color(0xFFFFE9A8), mp: DiceLadder()),
  GI('Silang Lingkar', '❌', const Color(0xFFDDF3FF), mp: TicTacToe()),
  GI('Tebak Angka', '🔮', const Color(0xFFEBDDFF), mp: GuessGame()),
];

class Home extends StatelessWidget {
  const Home({super.key});
  void _open(BuildContext c, GI g) {
    final Widget p = g.mp != null ? MpScreen(g.mp!, g.i) : GameScaffold(title: g.n, icon: g.i, build: g.solo!);
    Navigator.push(c, PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => p,
        transitionsBuilder: (_, a, __, ch) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: FadeTransition(opacity: a, child: ch))));
  }
  @override Widget build(BuildContext context) => Scaffold(
      body: Bg(child: SafeArea(child: Column(children: [
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 800), curve: Curves.elasticOut, builder: (c, v, w) => Transform.scale(scale: v, child: w), child: Text('🎈 Pesta Mini', style: ts(36))),
        Text('${games.length} game seru: offline, lawan bot & online!', style: ts(13, const Color(0xFF8A7A9B))),
        Expanded(child: GridView.builder(
            padding: const EdgeInsets.all(14),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.1),
            itemCount: games.length,
            itemBuilder: (ctx, i) {
              final g = games[i];
              return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0), duration: Duration(milliseconds: 350 + (i % 8) * 70), curve: Curves.elasticOut,
                  builder: (c, v, w) => Transform.scale(scale: v, child: w),
                  child: Pressable(onTap: () => _open(ctx, g), child: cart(g.c, r: 24, sh: 6, child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(g.i, style: const TextStyle(fontSize: 44)), const SizedBox(height: 4),
                    Text(g.n, textAlign: TextAlign.center, style: ts(15)),
                    if (g.mp != null) Text('👥 Multiplayer', style: ts(11)),
                  ]))));
            })),
      ]))));
}
