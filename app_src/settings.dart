import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  static final lang = ValueNotifier<String>('id');
  static final vol = ValueNotifier<double>(.8);
  static Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      lang.value = p.getString('lang') ?? 'id';
      vol.value = p.getDouble('vol') ?? .8;
    } catch (_) {}
  }
  static Future<void> save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('lang', lang.value);
      await p.setDouble('vol', vol.value);
    } catch (_) {}
  }
}

class Sfx {
  static final _ps = <AudioPlayer>[];
  static int _i = 0;
  static void p(String n) {
    final v = Settings.vol.value;
    if (v <= 0) return;
    try {
      if (_ps.isEmpty) { for (int k = 0; k < 4; k++) { _ps.add(AudioPlayer()); } }
      final pl = _ps[_i++ % 4];
      pl.setVolume(v).catchError((_) {});
      pl.play(AssetSource('sfx/$n.wav')).catchError((_) {});
    } catch (_) {}
  }
  static void tap() { HapticFeedback.selectionClick(); p('tap'); }
  static void good() { HapticFeedback.lightImpact(); p('good'); }
  static void bad() { HapticFeedback.heavyImpact(); p('bad'); }
  static void win() { HapticFeedback.mediumImpact(); p('win'); }
}

const _en = <List<String>>[
  ['Pengaturan', 'Settings'], ['Bahasa', 'Language'], ['Volume suara', 'Sound volume'], ['Tes suara', 'Test sound'],
  ['game seru: offline, lawan bot, online & satu HP!', 'fun games: offline, vs bot, online & one phone!'],
  ['Semua', 'All'], ['Solo', 'Solo'], ['Online', 'Online'], ['Lokal', 'Local'],
  ['Berapa pemain?', 'How many players?'], ['Satu HP, main bareng!', 'One phone, play together!'], ['Pemain online:', 'Online players:'], ['Pemain:', 'Players:'], ['Pemain', 'Players'],
  ['Langkah: ', 'Moves: '], ['Selesai dalam', 'Done in'], ['langkah', 'moves'], ['Skor', 'Score'], ['geser layar!', 'swipe the screen!'],
  ['Selesai!', 'Finished!'], ['Tekan Mulai', 'Press Start'], ['Perhatikan… level', 'Watch… level'], ['Giliranmu!', 'Your turn!'], ['Salah!', 'Wrong!'],
  ['▶ Mulai', '▶ Start'], ['Matikan semua lampu! Langkah', 'Turn off all lights! Moves'], ['Menang dalam', 'Won in'], ['geser untuk belok', 'swipe to turn'],
  ['tekan 🔄', 'press 🔄'], ['Roboh! Tinggi', 'Collapsed! Height'], ['Tinggi:', 'Height:'], ['ketuk untuk menjatuhkan', 'tap to drop'],
  ['Ketuk untuk terbang!', 'Tap to fly!'], ['Kena ranjau!', 'Hit a mine!'], ['Semua ranjau terhindar!', 'All mines avoided!'], ['10 ranjau tersembunyi', '10 hidden mines'],
  ['⛏️ Gali', '⛏️ Dig'], ['🚩 Bendera', '🚩 Flag'], ['Apa WARNA tulisannya?', 'What COLOR is the text?'],
  ['Ketuk kolom ubin hitam paling bawah!', 'Tap the column of the lowest black tile!'], ['Cari angka:', 'Find number:'], ['detik', 'seconds'],
  ['Kamu menang!', 'You win!'], ['Bot menang!', 'Bot wins!'], ['MERAH', 'RED'], ['BIRU', 'BLUE'], ['HIJAU', 'GREEN'], ['KUNING', 'YELLOW'],
  ['Jumlah pemain:', 'Players:'], ['🤖 Lawan Bot', '🤖 Vs Bot'], ['🏠 Buat Room Online', '🏠 Create Online Room'], ['Slot kosong diisi bot', 'Empty slots are filled by bots'],
  ['Gabung teman', 'Join a friend'], ['🔗 Gabung', '🔗 Join'], ['Kode room', 'Room code'], ['Menyambung…', 'Connecting…'], ['Menunggu host memulai…', 'Waiting for host…'],
  ['Giliran:', 'Turn:'], ['menang!', 'wins!'], ['Seri!', 'Draw!'], ['🔁 Main lagi', '🔁 Play again'], ['(kamu)', '(you)'], ['Gagal:', 'Failed:'],
  ['Terputus dari host', 'Disconnected from host'], ['Room penuh', 'Room full'], ['Lempar Dadu 🎲', 'Roll Dice 🎲'], ['Tangga naik', 'Ladder up'], ['Ular turun', 'Snake down'],
  ['Angka 6 = lempar lagi', 'Rolling 6 = roll again'], ['Angkanya antara', 'The number is between'], ['🔮 Tebak!', '🔮 Guess!'], ['terlalu kecil', 'too low'], ['terlalu besar', 'too high'], ['BENAR!', 'CORRECT!'],
  ['Ronde', 'Round'], ['Tunggu…', 'Wait…'], ['Siap', 'Ready'], ['Tim Atas', 'Top team'], ['Tim Bawah', 'Bottom team'], ['Tarik!', 'Pull!'], ['Tahan', 'Hold'], ['Target: ', 'Target: '],
  ['kalah!', 'loses!'], ['gugur!', 'is out!'], ['Giliran', 'Turn'], ['Lempar', 'Throw'], ['LEMPAR!', 'THROW!'], ['Simpan', 'Keep'], ['Poin giliran ini:', 'Turn points:'],
  ['Ambil 1-3 batang. Yang mengambil batang terakhir kalah!', 'Take 1-3 sticks. Whoever takes the last stick loses!'], ['Lebih Tinggi', 'Higher'], ['Lebih Rendah', 'Lower'],
  ['Pompa', 'Pump'], ['Lemparan', 'Throw'], ['Pilih kotak, jangan kena bom!', 'Pick a box, avoid the bomb!'], ['Lengkapi kotak untuk giliran ekstra!', 'Complete a box for an extra turn!'],
  ['Rebut sebanyak mungkin wilayah!', 'Capture as many cells as you can!'], ['Susun 4 sejajar!', 'Make 4 in a row!'], ['Cari pasangan!', 'Find the pairs!'],
  ['Balon meletus bila terlalu besar!', 'The balloon bursts if it gets too big!'], ['Pertama yang mencapai', 'First to reach'],
];
final _sorted = ([..._en]..sort((a, b) => b[0].length - a[0].length));
String L(String s) {
  if (Settings.lang.value != 'en') return s;
  var r = s;
  for (final e in _sorted) { r = r.replaceAll(e[0], e[1]); }
  return r;
}
