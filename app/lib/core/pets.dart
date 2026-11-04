/// The seven pets (docs/design.md "寵物"): each hatches from its own egg and
/// lives in its own home. The sea ones are washed with bubbles and play
/// with a bubble ball instead.
enum Species {
  puppy('小狗', ['豆豆', '旺旺', '小麥']),
  kitten('小貓', ['咪咪', '布丁', '喵喵']),
  bunny('小兔', ['跳跳', '棉花', '蘿蔔']),
  dino('小恐龍', ['咚咚', '小綠', '噗噗']),
  dolphin('小海豚', ['浪浪', '小藍', '噗通'], sea: true),
  octopus('小章魚', ['圈圈', '墨墨', '小八'], sea: true),
  turtle('小海龜', ['慢慢', '殼殼', '沙沙'], sea: true);

  const Species(this.zh, this.names, {this.sea = false});

  final String zh;

  /// Names to pick from when the pet has hatched (a parent can type one).
  final List<String> names;
  final bool sea;

  static Species? byName(String? name) => values.where((s) => s.name == name).firstOrNull;
}

/// How big the pet is, by its growth points. Writing right grows it much
/// faster than care alone (see [Growth]); about 5 right a day reaches
/// toddler in 2 days, child in a week, big in 2 weeks and grown in a month.
enum Stage {
  baby('寶寶', 0),
  toddler('小小孩', 100),
  child('小朋友', 300),
  big('大哥哥大姐姐', 700),
  grown('大人', 1500);

  const Stage(this.zh, this.from);

  final String zh;
  final int from;

  /// How far 0.1 goes: the later stages come with their companion features.
  static const last = toddler;

  static Stage of(int growth) {
    var s = baby;
    for (final st in values) {
      if (st.index <= last.index && growth >= st.from) s = st;
    }
    return s;
  }

  Stage? get next => index < last.index ? values[index + 1] : null;
}

/// Growth points for what the child does. About 5 right a day: 10 for the
/// letters, 17 for the cookies, 15 for the feast and some care, about 50.
abstract final class Growth {
  /// Each care tool, once an hour.
  static const care = 1;

  /// Each character written right (step 4).
  static const letter = 2;

  /// Finishing the tracing (step 3), a few times a day.
  static const traced = 1;
  static const tracedPerDay = 10;

  /// A letter cookie (3 stars): about 10 times a care.
  static const cookie = 10;

  /// Today's feast, when the daily goal is reached.
  static const feast = 15;

  static const starsPerCookie = 3;
}
