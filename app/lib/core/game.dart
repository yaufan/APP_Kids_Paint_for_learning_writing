import 'dart:math' as math;

import 'pets.dart';
import 'writing.dart';

/// The day [t] falls on, as 'yyyy-mm-dd' (the phone's own time zone).
String dayOf(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

/// The care tools on the home screen (docs/design.md "照顧").
enum Care { feed, bath, brush, ball, sleep }

/// The three hearts: belly, clean, happy. Each empties slowly over time,
/// but never all the way: a pet left for days only looks like it misses
/// the child, and one care brings it right back.
enum Heart {
  belly(Duration(hours: 8)),
  clean(Duration(hours: 24)),
  happy(Duration(hours: 12));

  const Heart(this.empties);

  /// How long a full heart takes to run down to [low].
  final Duration empties;

  static const low = 0.2;
}

/// One heart: how full it was at [at].
class HeartLevel {
  const HeartLevel(this.value, this.at);

  final double value;
  final DateTime at;

  double now(Heart heart, DateTime now) {
    final gone = now.difference(at).inSeconds / heart.empties.inSeconds * (1 - Heart.low);
    return (value - math.max(0, gone)).clamp(math.min(value, Heart.low), 1.0);
  }

  Map<String, dynamic> toJson() => {'v': value, 'at': at.toIso8601String()};

  static HeartLevel fromJson(Object? j, DateTime fallback) {
    if (j is! Map) return HeartLevel(1, fallback);
    return HeartLevel((j['v'] as num?)?.toDouble() ?? 1, DateTime.tryParse(j['at'] as String? ?? '') ?? fallback);
  }
}

/// What the child has done with one character.
class GlyphProgress {
  const GlyphProgress({this.best = 0, this.right = 0, this.traced = 0});

  /// The most stars ever (0 to 3).
  final int best;

  /// Times written right (step 4).
  final int right;

  /// Times traced to the end (step 3).
  final int traced;

  GlyphProgress copyWith({int? best, int? right, int? traced}) =>
      GlyphProgress(best: best ?? this.best, right: right ?? this.right, traced: traced ?? this.traced);

  Map<String, dynamic> toJson() => {'best': best, 'right': right, 'traced': traced};

  factory GlyphProgress.fromJson(Map<String, dynamic> j) =>
      GlyphProgress(best: j['best'] as int? ?? 0, right: j['right'] as int? ?? 0, traced: j['traced'] as int? ?? 0);
}

/// What one day held: characters written right, tracings finished, and
/// whether today's feast was had.
class DayLog {
  const DayLog({this.right = 0, this.traced = 0, this.feast = false});

  final int right;
  final int traced;
  final bool feast;

  DayLog copyWith({int? right, int? traced, bool? feast}) =>
      DayLog(right: right ?? this.right, traced: traced ?? this.traced, feast: feast ?? this.feast);

  Map<String, dynamic> toJson() => {'right': right, 'traced': traced, 'feast': feast};

  factory DayLog.fromJson(Map<String, dynamic> j) =>
      DayLog(right: j['right'] as int? ?? 0, traced: j['traced'] as int? ?? 0, feast: j['feast'] as bool? ?? false);
}

/// What a parent set (parent mode).
class Settings {
  const Settings({
    this.strictness = Strictness.lenient,
    this.leftHanded = false,
    this.music = true,
    this.sounds = true,
    this.voice = true,
    this.dailyGoal = 5,
    this.full = true,
  });

  final Strictness strictness;
  final bool leftHanded;
  final bool music;
  final bool sounds;
  final bool voice;

  /// Characters written right in a day for today's feast.
  final int dailyGoal;

  /// The full version (lowercase, the child's name, all seven pets…).
  /// Bought once in parent mode later; the test builds have it all open.
  final bool full;

  Settings copyWith({Strictness? strictness, bool? leftHanded, bool? music, bool? sounds, bool? voice, int? dailyGoal, bool? full}) => Settings(
        strictness: strictness ?? this.strictness,
        leftHanded: leftHanded ?? this.leftHanded,
        music: music ?? this.music,
        sounds: sounds ?? this.sounds,
        voice: voice ?? this.voice,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        full: full ?? this.full,
      );

  Map<String, dynamic> toJson() => {
        'strictness': strictness.name,
        'leftHanded': leftHanded,
        'music': music,
        'sounds': sounds,
        'voice': voice,
        'dailyGoal': dailyGoal,
        'full': full,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        strictness: Strictness.values.where((s) => s.name == j['strictness']).firstOrNull ?? Strictness.lenient,
        leftHanded: j['leftHanded'] as bool? ?? false,
        music: j['music'] as bool? ?? true,
        sounds: j['sounds'] as bool? ?? true,
        voice: j['voice'] as bool? ?? true,
        dailyGoal: (j['dailyGoal'] as int? ?? 5).clamp(1, 20),
        full: j['full'] as bool? ?? true,
      );
}

/// Everything the app keeps: the story read, the pet, stars and cookies,
/// each character's progress, each day's count and the parent's settings.
/// Saved as one small file (see store.dart).
class Game {
  const Game({
    this.storyRead = false,
    this.species,
    this.hatched = false,
    this.name,
    this.growth = 0,
    this.stageSeen = Stage.baby,
    this.hearts = const {},
    this.lastCare = const {},
    this.stars = 0,
    this.cookies = const [],
    this.glyphs = const {},
    this.days = const {},
    this.settings = const Settings(),
  });

  final bool storyRead;

  /// The egg picked (null: not yet).
  final Species? species;
  final bool hatched;

  /// The pet's name (null: hatched but not named yet).
  final String? name;
  final int growth;

  /// The stage the child has seen the grow-up page for.
  final Stage stageSeen;
  final Map<Heart, HeartLevel> hearts;

  /// When each care tool last made the pet grow.
  final Map<Care, DateTime> lastCare;

  /// Stars towards the next cookie (0 to 2).
  final int stars;

  /// Letter cookies not eaten yet: each has the character that earned it.
  final List<String> cookies;
  final Map<String, GlyphProgress> glyphs;
  final Map<String, DayLog> days;
  final Settings settings;

  Stage get stage => Stage.of(growth);

  /// A new stage the child has not seen the grow-up page for.
  bool get grewUp => hatched && stage.index > stageSeen.index;

  /// How far to the next stage (0..1); 1 at the last one.
  double get toNextStage {
    final next = stage.next;
    if (next == null) return 1;
    return ((growth - stage.from) / (next.from - stage.from)).clamp(0, 1);
  }

  double heart(Heart h, DateTime now) => (hearts[h] ?? HeartLevel(1, now)).now(h, now);

  DayLog today(DateTime now) => days[dayOf(now)] ?? const DayLog();

  /// Whether a care tool makes the pet grow now (once an hour each).
  bool careGrows(Care c, DateTime now) {
    final last = lastCare[c];
    return last == null || now.difference(last) >= const Duration(hours: 1);
  }

  /// Characters written right, all days.
  int get totalRight => days.values.fold(0, (a, d) => a + d.right);

  Game copyWith({
    bool? storyRead,
    Species? species,
    bool? hatched,
    String? name,
    int? growth,
    Stage? stageSeen,
    Map<Heart, HeartLevel>? hearts,
    Map<Care, DateTime>? lastCare,
    int? stars,
    List<String>? cookies,
    Map<String, GlyphProgress>? glyphs,
    Map<String, DayLog>? days,
    Settings? settings,
  }) =>
      Game(
        storyRead: storyRead ?? this.storyRead,
        species: species ?? this.species,
        hatched: hatched ?? this.hatched,
        name: name ?? this.name,
        growth: growth ?? this.growth,
        stageSeen: stageSeen ?? this.stageSeen,
        hearts: hearts ?? this.hearts,
        lastCare: lastCare ?? this.lastCare,
        stars: stars ?? this.stars,
        cookies: cookies ?? this.cookies,
        glyphs: glyphs ?? this.glyphs,
        days: days ?? this.days,
        settings: settings ?? this.settings,
      );

  // --- What happens -------------------------------------------------------

  Game pickEgg(Species s) => species == null ? copyWith(species: s, storyRead: true) : this;

  Game named(String n) {
    final t = n.trim();
    return t.isEmpty ? this : copyWith(name: t.length > 8 ? t.substring(0, 8) : t);
  }

  Game _withHeart(Heart h, double by, DateTime now) =>
      copyWith(hearts: {...hearts, h: HeartLevel((heart(h, now) + by).clamp(0.0, 1.0), now)});

  /// A care tool used: it fills its hearts, and once an hour each, the pet
  /// grows a little.
  Game care(Care c, DateTime now) {
    var g = switch (c) {
      Care.feed => _withHeart(Heart.belly, 0.5, now),
      Care.bath => _withHeart(Heart.clean, 1, now),
      Care.brush => _withHeart(Heart.clean, 0.25, now)._withHeart(Heart.happy, 0.2, now),
      Care.ball => _withHeart(Heart.happy, 0.5, now),
      Care.sleep => _withHeart(Heart.happy, 0.25, now),
    };
    if (hatched && careGrows(c, now)) {
      g = g.copyWith(growth: growth + Growth.care, lastCare: {...lastCare, c: now});
    }
    return g;
  }

  /// Patted or tickled: happier, no growth.
  Game cuddled(DateTime now, [double by = 0.05]) => _withHeart(Heart.happy, by, now);

  /// [id] written right with [stars] (step 4): a star towards a cookie (a
  /// third makes one), growth, and the first one hatches the egg.
  Game wrote(String id, int stars, DateTime now) {
    final p = glyphs[id] ?? const GlyphProgress();
    final day = dayOf(now);
    final log = today(now);
    var s = this.stars + 1;
    var c = cookies;
    if (s >= Growth.starsPerCookie) {
      s -= Growth.starsPerCookie;
      c = [...cookies, id];
    }
    return copyWith(
      hatched: species != null ? true : hatched,
      growth: growth + (hatched ? Growth.letter : 0),
      stars: s,
      cookies: c,
      glyphs: {...glyphs, id: p.copyWith(best: math.max(p.best, stars), right: p.right + 1)},
      days: {...days, day: log.copyWith(right: log.right + 1)},
    );
  }

  /// [id] traced to the end (step 3): a little growth, a few times a day.
  Game traced(String id, DateTime now) {
    final p = glyphs[id] ?? const GlyphProgress();
    final log = today(now);
    final grows = hatched && log.traced < Growth.tracedPerDay;
    return copyWith(
      growth: growth + (grows ? Growth.traced : 0),
      glyphs: {...glyphs, id: p.copyWith(traced: p.traced + 1)},
      days: {...days, dayOf(now): log.copyWith(traced: log.traced + 1)},
    );
  }

  /// A cookie fed to the pet.
  Game ateCookie(DateTime now) {
    if (cookies.isEmpty || !hatched) return this;
    return copyWith(cookies: cookies.sublist(1), growth: growth + Growth.cookie)._withHeart(Heart.belly, 0.3, now)._withHeart(Heart.happy, 0.2, now);
  }

  /// Whether today's feast is ready (the goal reached, not had yet).
  bool feastReady(DateTime now) => hatched && !today(now).feast && today(now).right >= settings.dailyGoal;

  Game hadFeast(DateTime now) {
    if (!feastReady(now)) return this;
    final log = today(now);
    return copyWith(growth: growth + Growth.feast, days: {...days, dayOf(now): log.copyWith(feast: true)})
        ._withHeart(Heart.belly, 1, now)
        ._withHeart(Heart.happy, 1, now);
  }

  Game sawStage() => copyWith(stageSeen: stage);

  /// The next character to learn: the first in [order] without stars.
  String? suggest(List<String> order) => order.where((id) => (glyphs[id]?.best ?? 0) == 0).firstOrNull;

  // --- Saving -------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'version': 1,
        'storyRead': storyRead,
        'species': species?.name,
        'hatched': hatched,
        'name': name,
        'growth': growth,
        'stageSeen': stageSeen.name,
        'hearts': {for (final e in hearts.entries) e.key.name: e.value.toJson()},
        'lastCare': {for (final e in lastCare.entries) e.key.name: e.value.toIso8601String()},
        'stars': stars,
        'cookies': cookies,
        'glyphs': {for (final e in glyphs.entries) e.key: e.value.toJson()},
        'days': {for (final e in days.entries) e.key: e.value.toJson()},
        'settings': settings.toJson(),
      };

  /// Reads what was saved; anything missing or broken starts fresh rather
  /// than losing the rest.
  factory Game.fromJson(Map<String, dynamic>? j, DateTime now) {
    if (j == null) return const Game();
    Map<String, dynamic> map(Object? o) => o is Map ? o.cast<String, dynamic>() : const {};
    return Game(
      storyRead: j['storyRead'] as bool? ?? false,
      species: Species.byName(j['species'] as String?),
      hatched: j['hatched'] as bool? ?? false,
      name: j['name'] as String?,
      growth: j['growth'] as int? ?? 0,
      stageSeen: Stage.values.where((s) => s.name == j['stageSeen']).firstOrNull ?? Stage.baby,
      hearts: {
        for (final h in Heart.values)
          if (map(j['hearts']).containsKey(h.name)) h: HeartLevel.fromJson(map(j['hearts'])[h.name], now),
      },
      lastCare: {
        for (final c in Care.values) c: ?DateTime.tryParse(map(j['lastCare'])[c.name] as String? ?? ''),
      },
      stars: (j['stars'] as int? ?? 0).clamp(0, Growth.starsPerCookie - 1),
      cookies: [for (final c in j['cookies'] as List? ?? const []) if (c is String) c],
      glyphs: {for (final e in map(j['glyphs']).entries) if (e.value is Map) e.key: GlyphProgress.fromJson(map(e.value))},
      days: {for (final e in map(j['days']).entries) if (e.value is Map) e.key: DayLog.fromJson(map(e.value))},
      settings: Settings.fromJson(map(j['settings'])),
    );
  }
}
