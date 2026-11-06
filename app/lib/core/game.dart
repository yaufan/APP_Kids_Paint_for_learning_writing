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
  const GlyphProgress({this.best = 0, this.right = 0, this.traced = 0, this.streak = 0, this.misses = 0, this.lastAt});

  /// The most stars ever (0 to 3).
  final int best;

  /// Times written right (step 4).
  final int right;

  /// Times traced to the end (step 3).
  final int traced;

  /// Written right lately without much trouble: the faint letter under the
  /// writing fades as it grows ([guide]).
  final int streak;

  /// Strokes that were not right yet, all together (for parents: the
  /// characters that are often written the wrong way).
  final int misses;

  /// When it was last written right (for review).
  final DateTime? lastAt;

  /// How much help the writing step shows: 0 the faint letter, 1 a dotted
  /// line, 2 only the green dots.
  int get guide => streak >= 4 ? 2 : (streak >= 2 ? 1 : 0);

  GlyphProgress copyWith({int? best, int? right, int? traced, int? streak, int? misses, DateTime? lastAt}) => GlyphProgress(
        best: best ?? this.best,
        right: right ?? this.right,
        traced: traced ?? this.traced,
        streak: streak ?? this.streak,
        misses: misses ?? this.misses,
        lastAt: lastAt ?? this.lastAt,
      );

  Map<String, dynamic> toJson() => {
        'best': best,
        'right': right,
        'traced': traced,
        'streak': streak,
        'misses': misses,
        if (lastAt != null) 'lastAt': lastAt!.toIso8601String(),
      };

  factory GlyphProgress.fromJson(Map<String, dynamic> j) => GlyphProgress(
        best: j['best'] as int? ?? 0,
        right: j['right'] as int? ?? 0,
        traced: j['traced'] as int? ?? 0,
        streak: j['streak'] as int? ?? 0,
        misses: j['misses'] as int? ?? 0,
        lastAt: DateTime.tryParse(j['lastAt'] as String? ?? ''),
      );
}

/// What one day held: characters written right (and which), tracings
/// finished, whether today's feast was had and the tasks' bonus given.
class DayLog {
  const DayLog({this.right = 0, this.traced = 0, this.feast = false, this.glyphs = const [], this.tasksBonus = false});

  final int right;
  final int traced;
  final bool feast;

  /// The characters written right that day.
  final List<String> glyphs;
  final bool tasksBonus;

  DayLog copyWith({int? right, int? traced, bool? feast, List<String>? glyphs, bool? tasksBonus}) => DayLog(
        right: right ?? this.right,
        traced: traced ?? this.traced,
        feast: feast ?? this.feast,
        glyphs: glyphs ?? this.glyphs,
        tasksBonus: tasksBonus ?? this.tasksBonus,
      );

  Map<String, dynamic> toJson() => {'right': right, 'traced': traced, 'feast': feast, 'glyphs': glyphs, 'tasksBonus': tasksBonus};

  factory DayLog.fromJson(Map<String, dynamic> j) => DayLog(
        right: j['right'] as int? ?? 0,
        traced: j['traced'] as int? ?? 0,
        feast: j['feast'] as bool? ?? false,
        glyphs: [for (final g in j['glyphs'] as List? ?? const []) if (g is String) g],
        tasksBonus: j['tasksBonus'] as bool? ?? false,
      );
}

/// What a reward is for (docs/design.md "自訂獎勵").
enum RewardGoal { right, learned, days }

/// A reward a parent set: reach [target] of [goal] (counted from when it
/// became the current one) and the child gets what [text] says.
class Reward {
  const Reward({required this.id, required this.goal, required this.target, required this.text, required this.icon, this.from, this.reachedAt, this.seenAt, this.redeemedAt});

  final int id;
  final RewardGoal goal;
  final int target;
  final String text;

  /// One of the pictures in assets/art/rewards/.
  final String icon;

  /// The count when it became the current reward (null: waiting its turn).
  final int? from;
  final DateTime? reachedAt;

  /// The child has seen the celebration.
  final DateTime? seenAt;

  /// The parent gave it (parent mode), and the next one starts.
  final DateTime? redeemedAt;

  static const icons = ['ice_cream', 'park', 'toy', 'book', 'hug', 'star'];

  Reward copyWith({int? from, DateTime? reachedAt, DateTime? seenAt, DateTime? redeemedAt}) => Reward(
        id: id,
        goal: goal,
        target: target,
        text: text,
        icon: icon,
        from: from ?? this.from,
        reachedAt: reachedAt ?? this.reachedAt,
        seenAt: seenAt ?? this.seenAt,
        redeemedAt: redeemedAt ?? this.redeemedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'goal': goal.name,
        'target': target,
        'text': text,
        'icon': icon,
        'from': ?from,
        if (reachedAt != null) 'reachedAt': reachedAt!.toIso8601String(),
        if (seenAt != null) 'seenAt': seenAt!.toIso8601String(),
        if (redeemedAt != null) 'redeemedAt': redeemedAt!.toIso8601String(),
      };

  static Reward? fromJson(Map<String, dynamic> j) {
    final goal = RewardGoal.values.where((g) => g.name == j['goal']).firstOrNull;
    final id = j['id'], target = j['target'], text = j['text'];
    if (goal == null || id is! int || target is! int || text is! String) return null;
    final icon = j['icon'] as String?;
    return Reward(
      id: id,
      goal: goal,
      target: target.clamp(1, 999),
      text: text,
      icon: icons.contains(icon) ? icon! : 'star',
      from: j['from'] as int?,
      reachedAt: DateTime.tryParse(j['reachedAt'] as String? ?? ''),
      seenAt: DateTime.tryParse(j['seenAt'] as String? ?? ''),
      redeemedAt: DateTime.tryParse(j['redeemedAt'] as String? ?? ''),
    );
  }
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
    this.dailyTasks = 3,
    this.full = true,
  });

  final Strictness strictness;
  final bool leftHanded;
  final bool music;
  final bool sounds;
  final bool voice;

  /// Characters written right in a day for today's feast.
  final int dailyGoal;

  /// Characters the pet asks for each day (1 new, the rest to review).
  final int dailyTasks;

  /// The full version (lowercase, the child's name, all seven pets…).
  /// Bought once in parent mode later; the test builds have it all open.
  final bool full;

  Settings copyWith({Strictness? strictness, bool? leftHanded, bool? music, bool? sounds, bool? voice, int? dailyGoal, int? dailyTasks, bool? full}) => Settings(
        strictness: strictness ?? this.strictness,
        leftHanded: leftHanded ?? this.leftHanded,
        music: music ?? this.music,
        sounds: sounds ?? this.sounds,
        voice: voice ?? this.voice,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        dailyTasks: dailyTasks ?? this.dailyTasks,
        full: full ?? this.full,
      );

  Map<String, dynamic> toJson() => {
        'strictness': strictness.name,
        'leftHanded': leftHanded,
        'music': music,
        'sounds': sounds,
        'voice': voice,
        'dailyGoal': dailyGoal,
        'dailyTasks': dailyTasks,
        'full': full,
      };

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        strictness: Strictness.values.where((s) => s.name == j['strictness']).firstOrNull ?? Strictness.lenient,
        leftHanded: j['leftHanded'] as bool? ?? false,
        music: j['music'] as bool? ?? true,
        sounds: j['sounds'] as bool? ?? true,
        voice: j['voice'] as bool? ?? true,
        dailyGoal: (j['dailyGoal'] as int? ?? 5).clamp(1, 20),
        dailyTasks: (j['dailyTasks'] as int? ?? 3).clamp(1, 5),
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
    this.rewards = const [],
    this.taskDay,
    this.tasks = const [],
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

  /// The parent's rewards, in order; the first not yet given is the
  /// current one.
  final List<Reward> rewards;

  /// The characters the pet asked for on [taskDay].
  final String? taskDay;
  final List<String> tasks;

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
    List<Reward>? rewards,
    String? taskDay,
    List<String>? tasks,
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
        rewards: rewards ?? this.rewards,
        taskDay: taskDay ?? this.taskDay,
        tasks: tasks ?? this.tasks,
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

  /// [id] written right with [stars] (step 4), after [misses] strokes that
  /// were not right yet: a star towards a cookie (a third makes one),
  /// growth, and the first one hatches the egg. A letter written without
  /// much trouble needs less help next time ([GlyphProgress.guide]).
  Game wrote(String id, int stars, DateTime now, {int misses = 0}) {
    final p = glyphs[id] ?? const GlyphProgress();
    final day = dayOf(now);
    final log = today(now);
    var s = this.stars + 1;
    var c = cookies;
    if (s >= Growth.starsPerCookie) {
      s -= Growth.starsPerCookie;
      c = [...cookies, id];
    }
    final streak = misses >= 3 ? math.max(0, p.streak - 2) : p.streak + 1;
    var newLog = log.copyWith(right: log.right + 1, glyphs: log.glyphs.contains(id) ? log.glyphs : [...log.glyphs, id]);
    // Today's tasks all done: a bonus cookie, once.
    if (taskDay == day && tasks.isNotEmpty && !newLog.tasksBonus && tasks.every(newLog.glyphs.contains)) {
      newLog = newLog.copyWith(tasksBonus: true);
      c = [...c, bonusCookie];
    }
    return copyWith(
      hatched: species != null ? true : hatched,
      growth: growth + (hatched ? Growth.letter : 0),
      stars: s,
      cookies: c,
      glyphs: {...glyphs, id: p.copyWith(best: math.max(p.best, stars), right: p.right + 1, streak: streak, misses: p.misses + misses, lastAt: now)},
      days: {...days, day: newLog},
    )._checkRewards(now);
  }

  /// The cookie for doing all of today's tasks.
  static const bonusCookie = '★';

  /// Strokes not right yet on [id], when the child gave up on it.
  Game missed(String id, int misses) {
    if (misses <= 0) return this;
    final p = glyphs[id] ?? const GlyphProgress();
    return copyWith(glyphs: {...glyphs, id: p.copyWith(misses: p.misses + misses, streak: math.max(0, p.streak - 1))});
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

  // --- Today's tasks ------------------------------------------------------

  /// Picks today's characters if it has not been done today: the next new
  /// one in [order], and the rest from those already learned, the fewest
  /// stars and the longest ago first.
  Game withTasks(DateTime now, List<String> order) {
    final day = dayOf(now);
    if (taskDay == day && tasks.isNotEmpty) return this;
    final n = settings.dailyTasks;
    final fresh = suggest(order);
    final learned = [for (final id in order) if ((glyphs[id]?.best ?? 0) > 0 && id != fresh) id];
    learned.sort((a, b) {
      final pa = glyphs[a]!, pb = glyphs[b]!;
      final byStars = pa.best.compareTo(pb.best);
      if (byStars != 0) return byStars;
      return (pa.lastAt ?? DateTime(2000)).compareTo(pb.lastAt ?? DateTime(2000));
    });
    final picked = <String>[?fresh, ...learned.take(fresh == null ? n : n - 1)];
    // Not enough learned yet: the next new ones.
    for (final id in order) {
      if (picked.length >= n) break;
      if (!picked.contains(id)) picked.add(id);
    }
    return copyWith(taskDay: day, tasks: picked);
  }

  /// Today's tasks done so far.
  Set<String> tasksDone(DateTime now) => taskDay == dayOf(now) ? {for (final t in tasks) if (today(now).glyphs.contains(t)) t} : const {};

  // --- Rewards ------------------------------------------------------------

  /// How many there are of what [goal] counts.
  int count(RewardGoal goal) => switch (goal) {
        RewardGoal.right => totalRight,
        RewardGoal.learned => glyphs.values.where((p) => p.best >= 3).length,
        RewardGoal.days => days.values.where((d) => d.right > 0).length,
      };

  /// The reward being worked towards (or reached and not given yet).
  Reward? get currentReward => rewards.where((r) => r.redeemedAt == null).firstOrNull;

  int progress(Reward r) => math.max(0, count(r.goal) - (r.from ?? count(r.goal)));

  /// A reached reward the child has not seen the celebration for.
  Reward? get rewardToShow {
    final r = currentReward;
    return r != null && r.reachedAt != null && r.seenAt == null ? r : null;
  }

  Game _checkRewards(DateTime now) {
    final r = currentReward;
    if (r == null || r.reachedAt != null || progress(r) < r.target) return this;
    return _replace(r.copyWith(reachedAt: now));
  }

  Game _replace(Reward r) => copyWith(rewards: [for (final x in rewards) x.id == r.id ? r : x]);

  Game addReward(RewardGoal goal, int target, String text, String icon) {
    final id = rewards.fold(0, (m, r) => math.max(m, r.id)) + 1;
    final active = currentReward == null;
    return copyWith(rewards: [
      ...rewards,
      Reward(id: id, goal: goal, target: target, text: text.trim(), icon: icon, from: active ? count(goal) : null),
    ]);
  }

  Game sawReward(int id, DateTime now) {
    final r = rewards.where((x) => x.id == id).firstOrNull;
    return r == null ? this : _replace(r.copyWith(seenAt: now));
  }

  /// The parent gave reward [id]; the next one starts counting now.
  Game redeem(int id, DateTime now) {
    final r = rewards.where((x) => x.id == id).firstOrNull;
    if (r == null) return this;
    var g = _replace(r.copyWith(redeemedAt: now, reachedAt: r.reachedAt ?? now, seenAt: r.seenAt ?? now));
    final next = g.currentReward;
    if (next != null && next.from == null) g = g._replace(next.copyWith(from: g.count(next.goal)))._checkRewards(now);
    return g;
  }

  Game removeReward(int id) {
    final wasCurrent = currentReward?.id == id;
    var g = copyWith(rewards: [for (final r in rewards) if (r.id != id) r]);
    final next = g.currentReward;
    if (wasCurrent && next != null && next.from == null) g = g._replace(next.copyWith(from: g.count(next.goal)));
    return g;
  }

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
        'rewards': [for (final r in rewards) r.toJson()],
        'taskDay': ?taskDay,
        'tasks': tasks,
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
      rewards: [
        for (final r in j['rewards'] as List? ?? const [])
          if (r is Map) ?Reward.fromJson(r.cast<String, dynamic>()),
      ],
      taskDay: j['taskDay'] as String?,
      tasks: [for (final t in j['tasks'] as List? ?? const []) if (t is String) t],
    );
  }
}
