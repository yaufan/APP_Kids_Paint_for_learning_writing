import '../core/game.dart';
import '../core/glyphs.dart';
import '../core/pets.dart';
import '../core/writing.dart';

/// Everything the app says, in Traditional Chinese (Taiwan). The English
/// that is read out is the letters' own words, in glyphs.json.
abstract final class Strings {
  static const appName = '字母寵物';

  // The opening story (docs/design.md "故事").
  static const storyPages = [
    '在字母森林的盡頭，有一間小小的寵物屋。',
    '有一天，門口出現了好多顆會發光的蛋⋯⋯',
    '每一顆蛋裡，都住著一個等你的小寶貝。你要帶哪一顆回家呢？',
  ];
  static const turnPage = '翻下一頁';
  static const pickEgg = '選一顆蛋';
  static String eggOf(Species s) => '${s.zh}的蛋';
  static String takeHome(Species s) => '帶${s.zh}的蛋回家';

  // Home.
  static const write = '寫字';
  static const eggHint = '寫對一個字，蛋就會孵出來喔！';
  static const eggWobble = '蛋動了一下！';
  static const parent = '家長';
  static const belly = '肚子';
  static const clean = '乾淨';
  static const happy = '開心';
  static String stars(int n) => '星星 $n／3';
  static String cookies(int n) => '字母餅乾 $n 塊';
  static const growth = '長大';
  static String careName(String c) => const {
        'feed': '餵飼料',
        'bath': '洗澡',
        'bubbles': '吹泡泡',
        'brush': '梳毛',
        'ball': '玩球',
        'bubbleBall': '泡泡球',
        'sleep': '睡覺',
        'wake': '起床',
      }[c]!;
  static const dragHint = '拿到寶貝身上喔';
  static const feedHint = '拿到嘴巴旁邊喔';
  static const rinse = '沖水';
  static const cookie = '字母餅乾';
  static String cookieWith(String c) => '$c 字母餅乾';
  static const feast = '今日大餐';
  static const feastReady = '今天寫好多字！大餐來了！';
  static const goodNight = '晚安，好夢喔';
  static const wakeUp = '早安！';

  // Hatching and naming.
  static const hatching = '蛋要孵出來了！點點看';
  static String hello(Species s) => '哇！是${s.zh}！';
  static const nameIt = '幫寶貝取個名字';
  static const typeName = '家長幫忙打字';
  static const nameField = '寶貝的名字';
  static const ok = '好了';
  static String hi(String name) => '你好，我是$name！';

  // Growing up.
  static String grewUp(String name, Stage s) => '$name長大了！\n變成${s.zh}了';
  static String newPower(Stage s) => switch (s) {
        Stage.toddler => '會說話了：寫字的時候會幫你加油，還會念字母和數字給你聽。',
        _ => '',
      };
  static const yay = '太棒了';

  // Picking a character.
  static const pickLetter = '要寫哪一個呢？';
  static const back = '回去';
  static const home = '回家';
  static String groupLabel(GlyphGroup g) => g.label;
  static String glyphLabel(Glyph g) => g.kind == GlyphKind.warmup ? g.zh : g.show;

  // Writing.
  static const stepWatch = '看';
  static const stepTap = '點';
  static const stepTrace = '描';
  static const stepWrite = '寫';
  static const watchAgain = '再看一次';
  static const tapStars = '照順序點星星';
  static const traceRoad = '從綠點開始，沿著小路描';
  static const backOnRoad = '回到小路上喔';
  static const startAtDot = '從綠點開始喔';
  static const writeYourself = '換你自己寫！從綠點開始';
  static const clear = '重寫';
  static const great = '好棒！';
  static const almost = '差一點點，我們再看一次';
  static const traceAgain = '再描一次';
  static const again = '再寫一次';
  static const next = '下一個';
  static const eggMoved = '蛋在動了！回家看看';
  static const cheers = ['加油！', '你好厲害！', '慢慢來喔', '我陪你寫'];
  static const startAtStar = '從星星開始喔';
  static const followArrow = '方向反了喔，跟著箭頭寫';
  static const oneMore = '差一點點，再寫一次這一筆';
  static const alongRoad = '沿著小路寫寫看';

  /// What is read out in Mandarin when a character is shown ("A，蘋果").
  static String sayZh(Glyph g) => switch (g.kind) {
        GlyphKind.warmup => g.zh,
        GlyphKind.digit => g.zh,
        GlyphKind.capital => g.zh,
      };

  /// What is read out in English after it ("A, apple"; "three").
  static String? sayEn(Glyph g) => switch (g.kind) {
        GlyphKind.warmup => null,
        GlyphKind.digit => g.en,
        GlyphKind.capital => '${g.show}, ${g.en}',
      };

  // Today's tasks, the sticker book, finding letters (0.2).
  static const tasks = '今天的任務';
  static String task(Glyph g) => '任務：${glyphLabel(g)}';
  static const tasksDone = '今天的任務完成了！送你一塊星星餅乾';
  static const book = '字母圖鑑';
  static const bookHint = '寫對一個字，就得到一張圖卡';
  static String cardOf(Glyph g) => '${glyphLabel(g)} 圖卡';
  static String locked(Glyph g) => '寫對 ${glyphLabel(g)}，就會得到這張圖卡喔';
  static const shiny = '3 顆星：閃亮亮的圖卡';
  static const find = '找字母';
  static const findTitle = '幫寶貝找字母';
  static const findAsk = '幫我找到';
  static String findAskShown(Glyph g) => '找到 ${g.show}';
  static const findRight = '找到了！';
  static String thisIs(Glyph g) => '這是 ${g.show} 喔';
  static const allFound = '全部找到了！你好厲害';
  static const playAgain = '再玩一次';

  // Rewards (0.2): the gift box and the special screen.
  static const gift = '禮物';
  static String giftProgress(int n, int target) => '$n／$target';
  static const reached = '達成了！';
  static String parentsSay(String text) => '爸爸媽媽說：$text';
  static const showParents = '拿給爸爸媽媽看';

  // Parent gate (as in 畫畫小鎮).
  static const callParent = '請爸爸媽媽來幫忙喔！';
  static const parentGateTitle = '家長確認';
  static String gateQuestion(String a, String b) => '$a 加 $b 等於多少？';
  static const gateRules = '答錯三次要等一分鐘。';
  static const wrongAnswer = '不對喔，換一題。';
  static String gateWait(int s) => '請等 $s 秒再試';
  static const backspace = '刪掉';
  static const cancel = '取消';

  // Parent mode.
  static const parentTitle = '家長模式';
  static const progress = '進度';
  static String todayRight(int n, int goal) => '今天寫對 $n 個字（目標 $goal 個）';
  static String allRight(int n) => '全部寫對 $n 次';
  static String learned(int n, int all) => '拿到星星的字：$n／$all';
  static String petLine(String name, Species s, Stage st) => '$name（${s.zh}）：${st.zh}';
  static const noPet = '還沒有寵物';
  static const writing = '寫字';
  static const strictness = '寬鬆程度';
  static String strictnessName(Strictness s) => switch (s) {
        Strictness.lenient => '寬鬆（3～4 歲，筆順不限）',
        Strictness.normal => '普通（要照筆順）',
        Strictness.strict => '嚴格（5 歲以上，線要更準）',
      };
  static const leftHanded = '左撇子';
  static const leftHandedNote = '寵物和提示換到右邊，不擋手。';
  static const dailyGoal = '每天的目標';
  static String goalCount(int n) => '寫對 $n 個字，有今日大餐';
  static const sound = '聲音';
  static const music = '背景音樂';
  static const effects = '音效';
  static const voice = '語音（念字母和說明）';
  static const dailyTasks = '每天的任務';
  static String tasksCount(int n) => '寵物每天出 $n 個字：1 個新的，其他複習';
  static const thisWeek = '這 7 天';
  static String weekLine(int right, int days) => '寫對 $right 個字，練習了 $days 天';
  static String daysPracticed(int n) => '有練習的天數：$n 天';
  static const eachLetter = '每個字';
  static const oftenWrong = '常寫錯的字';
  static const noneWrong = '還沒有';
  static const rewards = '獎勵';
  static const rewardsNote = '自己設定獎勵，一個達成、你按「已經兌現」後，換下一個。小朋友在寵物的家看得到禮物盒和進度。';
  static const addReward = '新增獎勵';
  static const rewardGoal = '目標';
  static String goalName(RewardGoal g) => switch (g) {
        RewardGoal.right => '寫對幾個字',
        RewardGoal.learned => '學會幾個字（拿到 3 顆星）',
        RewardGoal.days => '有練習的天數',
      };
  static String goalShort(RewardGoal g, int n) => switch (g) {
        RewardGoal.right => '寫對 $n 個字',
        RewardGoal.learned => '學會 $n 個字',
        RewardGoal.days => '練習 $n 天',
      };
  static const rewardCount = '數量';
  static const rewardText = '獎勵是什麼（例如：週末去公園）';
  static const rewardIcon = '圖示';
  static String rewardIconName(String id) => const {
        'ice_cream': '冰淇淋',
        'park': '公園',
        'toy': '玩具',
        'book': '故事書',
        'hug': '擁抱',
        'star': '其他',
      }[id]!;
  static String rewardState(Reward r, int progress) => r.redeemedAt != null
      ? '已經兌現'
      : (r.reachedAt != null ? '達成了，等你兌現' : (r.from == null ? '排隊中' : '進行中 $progress／${r.target}'));
  static const redeem = '已經兌現';
  static const remove = '刪掉';
  static const edition = '版本';
  static const full = '完整版';
  static const fullNote = '免費：數字 0～9、大寫 A～Z、1 隻寵物。完整版（一次買斷）：小寫、寫自己的名字、全部 7 隻寵物、換裝、新的地方、印學習單。測試版先全部打開。';
  static const fullTest = '完整版（測試版的開關）';
  static const about = '關於';
  static String version(String v) => '字母寵物 $v';
  static const privacy = '不連網、不定位、沒有廣告、沒有帳號。資料不會傳給任何人，只存在這支手機（和家長自己帳號的手機備份）裡。';
}
