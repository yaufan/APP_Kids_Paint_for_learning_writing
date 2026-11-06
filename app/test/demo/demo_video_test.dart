// Records a demo video of 字母寵物 being used: a scripted child (a white dot
// where the finger is) with a caption under the phone screen. The music and
// sounds the app asked for are written down frame by frame and mixed in
// afterwards by tools/demo_audio.py.
//
//   flutter test test/demo/demo_video_test.dart --dart-define=DEMO=true
//   python3 ../tools/demo_audio.py
//
// Needs ffmpeg; writes build/demo/demo.mp4, chapters.txt and sounds.txt.
// Skipped in normal test runs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide Step;
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:letter_pets/app/app.dart';
import 'package:letter_pets/app/strings.dart';
import 'package:letter_pets/core/game.dart';
import 'package:letter_pets/core/glyphs.dart';
import 'package:letter_pets/core/pet_art.dart';
import 'package:letter_pets/core/pets.dart';
import 'package:letter_pets/core/providers.dart';
import 'package:letter_pets/core/sounds.dart';
import 'package:letter_pets/core/store.dart';
import 'package:letter_pets/core/voice.dart';
import 'package:letter_pets/features/pet/pet_view.dart';
import 'package:letter_pets/features/write/glyph_painter.dart';

import '../helpers.dart' show glyphBook, loadFonts;

const _phone = Size(390, 844);
const _captionHeight = 84.0;
const _fps = 10;
const _demo = bool.fromEnvironment('DEMO');

/// The music and sounds asked for, with the frame they were asked at.
class _Track implements Sounds {
  _Track(this.frame);

  final int Function() frame;
  final lines = <String>[];
  final _holders = MusicHolders();
  Music? _playing;

  @override
  set music(bool on) {}

  @override
  set effects(bool on) {}

  @override
  void play(Sfx sfx) => lines.add('${frame()} sfx ${sfx.file}');

  @override
  void hold(Object owner, Music? music) {
    _holders.hold(owner, music);
    _changed();
  }

  @override
  void release(Object owner) {
    _holders.release(owner);
    _changed();
  }

  void _changed() {
    final now = _holders.current;
    if (now == _playing) return;
    _playing = now;
    lines.add('${frame()} music ${now?.file ?? '-'}');
  }
}

void main() {
  testWidgets('demo video', skip: !_demo, (tester) async {
    await tester.runAsync(loadFonts);
    tester.view.physicalSize = Size(_phone.width * 3, (_phone.height + _captionHeight) * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final art = (await tester.runAsync(PetArtBook.load))!;
    var frameCount = 0;
    final track = _Track(() => frameCount);
    var now = DateTime(2026, 11, 4, 16, 30);
    final finger = ValueNotifier<Offset?>(null);
    final caption = ValueNotifier<String>('');
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          SizedBox.fromSize(
            size: _phone,
            child: MediaQuery(
              data: const MediaQueryData(size: _phone, devicePixelRatio: 3, padding: EdgeInsets.only(top: 24)),
              child: Stack(children: [
                ProviderScope(
                  overrides: [
                    storeProvider.overrideWithValue(MemoryStore()),
                    glyphBookProvider.overrideWithValue(glyphBook),
                    petArtProvider.overrideWithValue(art),
                    soundsProvider.overrideWithValue(track),
                    voiceProvider.overrideWithValue(const SilentVoice()),
                    clockProvider.overrideWithValue(() => now),
                  ],
                  child: const LetterPetsApp(),
                ),
                IgnorePointer(child: ValueListenableBuilder(valueListenable: finger, builder: (_, at, _) => _Finger(at))),
              ]),
            ),
          ),
          SizedBox(
            width: _phone.width,
            height: _captionHeight,
            child: ColoredBox(
              color: const Color(0xFF5B4636),
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: caption,
                  builder: (_, text, _) => Text(text,
                      textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Huninn', color: Colors.white, fontSize: 17, height: 1.35)),
                ),
              ),
            ),
          ),
        ]),
      ),
    ));

    final rec = (await tester.runAsync(() => _Recorder.start(key)))!;
    final marks = <String>[];
    void mark(String name) => marks.add('$name $frameCount');
    Future<void> frames(int n) async {
      for (var i = 0; i < n; i++) {
        frameCount++;
        await tester.runAsync(() async {
          await rec.capture();
          await Future<void>.delayed(const Duration(milliseconds: 15));
        });
        await tester.pump(const Duration(milliseconds: 1000 ~/ _fps));
      }
    }

    Future<void> seconds(double s) => frames((s * _fps).round());
    Future<void> until(Finder f, {double max = 20}) async {
      for (var i = 0; i < max * _fps && f.evaluate().isEmpty; i++) {
        await frames(1);
      }
      expect(f, findsWidgets);
    }

    Future<void> touch(Offset at) async {
      finger.value = at;
      await frames(3);
      await tester.tapAt(at);
      await frames(2);
      finger.value = null;
    }

    Future<void> tap(Finder f) => touch(tester.getCenter(f.first));
    Future<void> label(String l) => tap(find.bySemanticsLabel(l));

    /// A finger down at [points].first, along them a frame each, and up.
    Future<void> stroke(List<Offset> points, {int every = 1}) async {
      finger.value = points.first;
      final g = await tester.startGesture(points.first);
      await frames(2);
      for (var i = 1; i < points.length; i++) {
        await g.moveTo(points[i]);
        finger.value = points[i];
        if (i % every == 0 || i == points.length - 1) await frames(1);
      }
      await g.up();
      finger.value = null;
      await frames(2);
    }

    List<Offset> line(Offset a, Offset b, int n) => [for (var i = 0; i <= n; i++) Offset.lerp(a, b, i / n)!];
    List<Offset> rub(Offset c, double w, int times) => [
          for (var i = 0; i <= times * 6; i++) c + Offset(((i % 12) < 6 ? (i % 6) / 6 : 1 - (i % 6) / 6) * w - w / 2, (i % 4) * 6.0),
        ];

    ProviderContainer container() => ProviderScope.containerOf(tester.element(find.byType(LetterPetsApp)));
    Game game() => container().read(gameProvider);
    void change(Game Function(Game g) f) => container().read(gameProvider.notifier).change((g, _) => f(g));

    /// Where the page shows glyph point [p] of [g].
    Offset Function(Offset) pageOf(Glyph g) {
      final page = tester.getRect(find.byKey(const ValueKey('page')));
      final fit = GlyphFit(g, page.size);
      return (p) => page.topLeft + fit.toScreen(p);
    }

    Future<void> write(Glyph g, {bool wobbly = true}) async {
      final at = pageOf(g);
      for (final s in g.strokes) {
        await stroke([for (final (i, p) in s.indexed) at(p) + (wobbly ? Offset((i % 5 - 2) * 0.6, 0) : Offset.zero)], every: 3);
        await frames(2);
      }
    }

    Rect petRect() => tester.getRect(find.byType(PetView).first);
    Offset mouth() {
      final r = petRect();
      final a = art[game().species!];
      return r.topLeft + a.mouth * (r.width / a.size.width);
    }

    // 1. The story.
    mark('story');
    caption.value = '第一次打開：像翻一本繪本\n「在字母森林的盡頭，有一間小小的寵物屋⋯⋯」';
    await until(find.text(Strings.storyPages.first));
    await seconds(3);
    for (var i = 0; i < Strings.storyPages.length; i++) {
      if (i == 1) caption.value = '門口出現了好多顆會發光的蛋';
      if (i == 2) caption.value = '每一顆蛋裡，都住著一個等你的小寶貝';
      await label(Strings.turnPage);
      await seconds(2.5);
    }

    // 2. An egg.
    mark('eggs');
    caption.value = '選一顆蛋：小狗、小貓、小兔、小恐龍、\n小海豚、小章魚、小海龜';
    await seconds(1.5);
    await label(Strings.eggOf(Species.kitten));
    await seconds(1);
    await label(Strings.eggOf(Species.puppy));
    await seconds(1.2);
    await label(Strings.takeHome(Species.puppy));
    mark('egg_home');
    caption.value = '蛋在小狗的家裡等著\n寫對一個字，蛋就會孵出來';
    await seconds(2.5);
    await touch(tester.getCenter(find.byType(Scaffold).first) + const Offset(-20, 200));
    await seconds(2);

    // 3. The first character, in four steps.
    mark('letters');
    caption.value = '按「寫字」：從簡單的線條和數字開始';
    await label(Strings.write);
    await seconds(2.5);
    await label('1');
    mark('write_1');
    caption.value = '第 1 關「看」：照筆順慢慢畫出來\n（同時念出「一，one」）';
    await until(find.byKey(const ValueKey('page')));
    final one = glyphBook.byId['1']!;
    await until(find.bySemanticsLabel(Strings.stepTap), max: 5);
    await seconds(0.5);
    caption.value = '第 2 關「點」：照順序點起點的星星';
    await seconds(1.5);
    await touch(pageOf(one)(one.strokes.single.first));
    await seconds(1.5);
    caption.value = '第 3 關「描」：從綠點開始沿著小路描\n描出路外會停下來等，回到路上就接著描';
    final at1 = pageOf(one);
    final s1 = one.strokes.single;
    final half = s1.length ~/ 2;
    finger.value = at1(s1.first);
    final g1 = await tester.startGesture(at1(s1.first));
    await frames(3);
    for (var i = 1; i < half; i += 2) {
      await g1.moveTo(at1(s1[i]));
      finger.value = at1(s1[i]);
      await frames(1);
    }
    final off = at1(s1[half]) + const Offset(90, 0);
    await g1.moveTo(off);
    finger.value = off;
    await seconds(2.2);
    for (var i = half; i < s1.length; i += 2) {
      await g1.moveTo(at1(s1[i]));
      finger.value = at1(s1[i]);
      await frames(1);
    }
    await g1.moveTo(at1(s1.last));
    await g1.up();
    finger.value = null;
    await seconds(2);
    caption.value = '第 4 關「寫」：只給綠點，自己寫';
    await seconds(1);
    await write(one);
    await seconds(1);
    caption.value = '寫對了！得到星星\n第一次寫對：蛋在動了！';
    await seconds(3);

    // 4. Hatching.
    mark('hatch');
    caption.value = '回家：點三下蛋殼，寵物孵出來了';
    await label(Strings.home);
    await until(find.byKey(const ValueKey('hatch-egg')));
    await seconds(1.5);
    for (var i = 0; i < 3; i++) {
      await tap(find.byKey(const ValueKey('hatch-egg')));
      await seconds(0.6);
    }
    await until(find.text(Strings.nameIt), max: 6);
    caption.value = '幫寶貝取名字（也可以請家長打字）';
    await seconds(2);
    await label('豆豆');
    await seconds(2);

    // 5. Playing.
    mark('play');
    caption.value = '寶寶戴著圍兜兜\n點一下：跳起來，叫一聲';
    await seconds(1.5);
    await touch(petRect().center);
    await seconds(1.5);
    caption.value = '摸摸：冒出愛心';
    await stroke(rub(petRect().center + const Offset(0, 30), 90, 5));
    await seconds(1);
    caption.value = '很快點三下：笑到打滾';
    for (var i = 0; i < 3; i++) {
      finger.value = petRect().center;
      await tester.tapAt(petRect().center);
      await frames(1);
    }
    finger.value = null;
    await seconds(2);
    caption.value = '手指在畫面上移動，寵物的眼睛會跟著看';
    final sky = petRect().topCenter + const Offset(0, -120);
    await stroke([for (var i = 0; i <= 40; i++) sky + Offset(130 * (i < 20 ? -1 + i / 10 : 1 - (i - 20) / 10), (i % 20 - 10).abs() * 6.0)]);
    await seconds(1);

    // 6. Care.
    mark('care');
    caption.value = '照顧：把飼料拿到嘴巴旁邊，嚼嚼嚼';
    final bowl = tester.getCenter(find.bySemanticsLabel(Strings.careName('feed')).first);
    await stroke(line(bowl, mouth() + const Offset(0, 44), 14));
    await seconds(2);
    caption.value = '洗澡：用海綿擦出泡泡';
    final sponge = tester.getCenter(find.bySemanticsLabel(Strings.careName('bath')).first);
    final body = petRect().center + Offset(0, petRect().height * 0.15 + 44);
    await stroke([...line(sponge, body, 8), ...rub(body, 120, 8)]);
    await seconds(1);
    caption.value = '再用蓮蓬頭沖乾淨';
    await until(find.bySemanticsLabel(Strings.rinse), max: 3);
    final shower = tester.getCenter(find.bySemanticsLabel(Strings.rinse).first);
    await stroke([...line(shower, body + const Offset(0, -40), 8), ...rub(body + const Offset(0, -40), 120, 10)]);
    await seconds(1.5);
    caption.value = '梳毛：亮晶晶';
    final brush = tester.getCenter(find.bySemanticsLabel(Strings.careName('brush')).first);
    await stroke([...line(brush, body, 8), ...rub(body, 110, 6)]);
    await seconds(1.5);
    caption.value = '玩球：丟出去，寵物跑去追';
    await label(Strings.careName('ball'));
    await seconds(3.5);
    caption.value = '睡覺：關燈、蓋被子、打呼（放搖籃曲）';
    await label(Strings.careName('sleep'));
    await seconds(4);
    await label(Strings.careName('wake'));
    caption.value = '早安！照顧一次，寵物長大一點點（每樣工具一小時算一次）';
    await seconds(2.5);

    // 7. Writing A, a gentle "not yet", then a letter cookie.
    mark('write_a');
    change((g) => g.copyWith(stars: 2, growth: Stage.toddler.from - 12));
    caption.value = '寫大寫 A：先看一次';
    await label(Strings.write);
    await seconds(1);
    await tester.dragUntilVisible(find.bySemanticsLabel('A'), find.byType(ListView), const Offset(0, -300));
    await seconds(1);
    await label('A');
    await seconds(4);
    await label(Strings.stepWrite);
    caption.value = '第 4 關「寫」：一筆一筆寫\n下面有淡淡的字，寫對越多次越淡';
    await seconds(2);
    final a = glyphBook.byId['A']!;
    final atA = pageOf(a);
    caption.value = '寫反了：只有這一筆慢慢消失\n寵物示範一次，再寫這一筆';
    await stroke([for (final p in a.strokes.first.reversed) atA(p)], every: 3);
    await seconds(3.5);
    caption.value = '寫對了就變彩色，下一個綠點才出現';
    await stroke([for (final p in a.strokes[0]) atA(p)], every: 3);
    await seconds(1.5);
    caption.value = '不小心點到、小點點都不算';
    await touch(atA(const Offset(70, 20)));
    await seconds(1.5);
    caption.value = '寫完最後兩筆';
    for (final st in a.strokes.skip(1)) {
      await stroke([for (final p in st) atA(p)], every: 3);
      await frames(3);
    }
    await seconds(1);
    caption.value = '寫對了！3 顆星星換一塊「A 字母餅乾」';
    await seconds(3);
    await label(Strings.home);
    await until(find.bySemanticsLabel(Strings.cookieWith('A')), max: 5);
    mark('cookie');
    caption.value = '把字母餅乾拿給寵物吃：長大很多';
    await seconds(1.5);
    await stroke(line(tester.getCenter(find.bySemanticsLabel(Strings.cookieWith('A')).first), mouth() + const Offset(0, 44), 14));
    await seconds(1.5);
    mark('grow');
    caption.value = '長大了！從「寶寶」變成「小小孩」\n小小孩會說話，寫字時會幫你加油';
    await until(find.text(Strings.grewUp('豆豆', Stage.toddler)), max: 5);
    await seconds(4);
    await label(Strings.yay);
    await seconds(1.5);

    // 8. Today's feast.
    mark('feast');
    change((g) => g.copyWith(days: {...g.days, dayOf(now): g.today(now).copyWith(right: g.settings.dailyGoal)}));
    caption.value = '每天寫對 5 個字（家長可以改）：今日大餐！';
    await seconds(2);
    await label(Strings.feast);
    await seconds(4.5);

    // 9. Seven pets, seven homes.
    mark('homes');
    caption.value = '7 種寵物，各有自己的家\n海裡的寵物用吹泡泡洗澡、玩泡泡球';
    for (final s in [Species.kitten, Species.bunny, Species.dino, Species.dolphin, Species.octopus, Species.turtle]) {
      change((g) => g.copyWith(species: s, name: s.names.first));
      await seconds(1.6);
    }
    change((g) => g.copyWith(species: Species.puppy, name: '豆豆'));
    await seconds(1);

    // 10. Today's tasks, the sticker book, finding letters.
    mark('tasks');
    caption.value = '每天的任務（左上）：寵物出 3 個字\n1 個新的、2 個複習，全部寫完送星星餅乾';
    await seconds(4);
    mark('book');
    caption.value = '字母圖鑑：寫對一個字就得到一張圖卡\n3 顆星變閃亮亮';
    await label(Strings.book);
    await seconds(2.5);
    await label(Strings.cardOf(glyphBook.byId['1']!));
    await seconds(2);
    await touch(const Offset(40, 160));
    await tester.dragUntilVisible(find.bySemanticsLabel(Strings.cardOf(a)), find.byType(ListView), const Offset(0, -300));
    await seconds(1);
    await label(Strings.cardOf(a));
    caption.value = 'A 的圖卡：蘋果 apple（會念出來）';
    await seconds(2.5);
    await touch(const Offset(40, 160));
    await label(Strings.home);
    await seconds(1);
    mark('find');
    caption.value = '找字母：寵物把字母積木藏起來\n「幫我找到 A」，找錯了只會說「這是 B 喔」';
    await label(Strings.find);
    await seconds(2);
    for (var round = 0; round < 3; round++) {
      final asked = tester.widget<Text>(find.textContaining('找到 ').first).data!.replaceFirst('找到 ', '');
      final wrong = [for (final g in glyphBook.all) if (g.show.isNotEmpty && g.show != asked && find.bySemanticsLabel(g.show).evaluate().isNotEmpty) g];
      if (round == 0 && wrong.isNotEmpty) {
        await tap(find.bySemanticsLabel(wrong.first.show));
        await seconds(1.2);
      }
      await tap(find.bySemanticsLabel(asked));
      await seconds(1.8);
    }
    await label(Strings.home);
    await seconds(1);

    // 11. Parent mode.
    mark('parent');
    caption.value = '家長模式：左上角的鎖，要先答對一題加法';
    await label(Strings.parent);
    await until(find.text(Strings.parentGateTitle));
    await seconds(1.5);
    final question = tester.widget<Text>(find.textContaining('等於多少')).data!;
    const zh = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    final parts = RegExp(r'(\S) 加 (\S)').firstMatch(question)!;
    final answer = zh.indexOf(parts.group(1)!) + zh.indexOf(parts.group(2)!);
    for (final d in '$answer'.split('')) {
      await tap(find.byKey(ValueKey('gate-key-$d')));
    }
    await until(find.text(Strings.parentTitle));
    caption.value = '看這 7 天寫對幾個字、每個字的星星、常寫錯的字';
    await seconds(3.5);
    mark('reward');
    caption.value = '家長自己設定獎勵：例如寫對 3 個字，週末去公園';
    await tester.dragUntilVisible(find.byKey(const ValueKey('add-reward')), find.byType(ListView), const Offset(0, -200));
    await seconds(1);
    await tap(find.byKey(const ValueKey('add-reward')));
    await seconds(1);
    for (var i = 0; i < 11; i++) {
      await tester.tap(find.byKey(const ValueKey('target-less')));
      await tester.pump();
    }
    await tester.enterText(find.byKey(const ValueKey('reward-text')), '週末去公園');
    await seconds(1);
    await tap(find.byKey(const ValueKey('icon-park')));
    await seconds(1.5);
    await tap(find.byKey(const ValueKey('save-reward')));
    await seconds(1.5);
    caption.value = '進度、常寫錯的字、每天的任務數量、音樂和語音的開關';
    await stroke(line(const Offset(200, 700), const Offset(200, 200), 12));
    await seconds(2.5);
    await tap(find.byTooltip(Strings.back));
    await seconds(1);
    caption.value = '小朋友在家裡看得到禮物盒和進度';
    await seconds(2.5);
    change((g) {
      var x = g;
      for (var i = 0; i < 3; i++) {
        x = x.wrote('7', 3, now);
      }
      return x;
    });
    caption.value = '達成了！禮物盒打開\n念出「爸爸媽媽說：週末去公園」';
    await seconds(5);
    await label(Strings.showParents);
    await seconds(1);
    caption.value = '';
    mark('end');
    await seconds(0.5);

    await tester.runAsync(() async {
      await rec.finish();
      File('build/demo/chapters.txt').writeAsStringSync('${marks.join('\n')}\n');
      File('build/demo/sounds.txt').writeAsStringSync('fps $_fps\nframes $frameCount\n${track.lines.join('\n')}\n');
    });
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  }, timeout: const Timeout(Duration(minutes: 30)));
}

class _Finger extends StatelessWidget {
  const _Finger(this.at);

  final Offset? at;

  @override
  Widget build(BuildContext context) {
    final p = at;
    if (p == null) return const SizedBox.expand();
    return Stack(children: [
      Positioned(
        left: p.dx - 22,
        top: p.dy - 22,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.55),
            border: Border.all(color: const Color(0xFF5B4636).withValues(alpha: 0.5), width: 3),
          ),
        ),
      ),
    ]);
  }
}

/// Streams frames of [key]'s boundary into ffmpeg.
class _Recorder {
  _Recorder(this._key, this._ffmpeg);

  final GlobalKey _key;
  final Process _ffmpeg;

  static Future<_Recorder> start(GlobalKey key) async {
    Directory('build/demo').createSync(recursive: true);
    final size = Size(_phone.width * 2, (_phone.height + _captionHeight) * 2);
    final ffmpeg = await Process.start('ffmpeg', [
      '-y', '-loglevel', 'error',
      '-f', 'rawvideo', '-pix_fmt', 'rgba', '-s', '${size.width.toInt()}x${size.height.toInt()}', '-r', '$_fps', '-i', '-',
      '-vf', 'fps=30', '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '24', '-movflags', '+faststart', 'build/demo/demo_silent.mp4',
    ]);
    ffmpeg.stderr.listen(stderr.add);
    return _Recorder(key, ffmpeg);
  }

  Future<void> capture() async {
    final boundary = _key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    _ffmpeg.stdin.add(bytes!.buffer.asUint8List());
    await _ffmpeg.stdin.flush();
  }

  Future<void> finish() async {
    await _ffmpeg.stdin.flush();
    await _ffmpeg.stdin.close();
    final code = await _ffmpeg.exitCode;
    if (code != 0) throw StateError('ffmpeg failed ($code)');
  }
}
