# 字母寵物的圖（故事書風格）

這裡的程式畫出 APP 裡所有的圖，寫進 `app/assets/art/`（APP 圖示寫進 `app/android/` 和 `app/ios/`）。全部用 Python 產生 SVG，每次跑出來都一模一樣（隨機的抖動用固定的種子）。

## 畫風：繪本、故事書
和畫畫小鎮的著色本不一樣，這裡是像繪本裡的水彩、廣告顏料畫：
- **沒有黑色粗框線**。要框線的地方，用比填色深一點的同色系，細到中等，線條有一點點手畫的抖動。
- 溫暖柔和的顏色：奶油、蜜桃、鼠尾草綠、灰藍、珊瑚、芥末黃。
- 每個形狀裡面左上亮、邊緣稍暗，像顏料暈開；家、蛋、故事圖上有很淡的紙張顆粒（小點點）。
  不用 SVG 濾鏡，因為 APP 用的 flutter_svg 不會畫濾鏡。
- 寵物：圓圓的大頭、小身體、小手小腳，小小亮亮的黑點眼睛（一個白色反光）、紅紅的臉頰、小小的微笑。

## 檔案
| 程式 | 畫什麼 | 寫到哪裡 |
|---|---|---|
| `storybook.py` | 共用的畫法：抖動的形狀、柔和填色、框線顏色、紙張顆粒、眼睛 | （給其他程式用） |
| `pets.py` | 7 隻寵物（含開心、睡覺的眼睛）、`pets.json`、蛋（整顆和裂成兩半）、`eggs.json`、照顧用的小圖、寶寶圍兜和帽子 | `pets/`、`eggs/`、`items/`、`wear/` |
| `homes.py` | 7 個寵物的家（背景，1080×1920） | `homes/` |
| `story.py` | 開場故事 3 張（1080×1080） | `story/` |
| `words.py` | 貼紙簿的 26 張單字圖（A apple～Z zebra）、家長設定的 6 個獎勵圖示、積木、放大鏡、貼紙簿、今天的任務 | `words/`、`rewards/`、`items/` |
| `icon.py` | APP 圖示：小狗抱著寫著 A 的木頭積木 | Android、iOS 的圖示資料夾 |
| `preview.py` | 全部的圖排在一張大圖上（單字圖和獎勵圖還會用手機上的大小 90 像素再排一次），順便檢查寵物有沒有站在圖的最下緣 | 你指定的 PNG |

## 怎麼跑
在這個資料夾裡：
```
python3 pets.py                    # 寵物、蛋、小圖、圍兜和帽子
python3 homes.py                   # 寵物的家
python3 story.py                   # 開場故事
python3 words.py                   # 單字圖、獎勵圖、積木、放大鏡、貼紙簿、任務卡
python3 icon.py preview 圖示.png    # 圖示預覽：圓形、圓角方形、方形，48／96／192 像素
python3 icon.py export             # 寫進 Android 和 iOS
python3 preview.py 預覽.png         # 全部的圖排成一張，看看對不對
```
`pets.py`、`homes.py`、`story.py`、`words.py` 只要 Python 3。`icon.py` 和 `preview.py` 還要 Pillow、Node.js 和 Playwright（用 Chromium 把 SVG 畫成 PNG，借用畫畫小鎮的 `docs/design/v6/render_alpha.js`；沒有那個資料夾時，把它複製一份到這裡）。

## 給 APP 用的說明
### 寵物 `pets/`
- `<寵物>.svg`：裁到剛好包住寵物，四周留 5 單位，**最下面那一點就是圖的下緣**（APP 讓寵物站在腳上）。陸地的寵物面向你，海豚面向右邊。
- `<寵物>_happy.svg`（眼睛 ^ ^，摸摸、搔癢時）和 `<寵物>_sleep.svg`（閉著眼睛，睡覺時）：大小和位置完全一樣，可以直接換。
- 眼睛都放在 `<g id="eyes">` 裡：APP 可以把它藏起來，自己畫會跟著手指看的眼珠。
- 寵物的 id：puppy、kitten、bunny、dino、dolphin、octopus、turtle。

`pets.json`，每隻寵物一筆，數字都是那張 SVG 自己的單位：
```json
"puppy": {
  "viewBox": {"width": 288, "height": 359},
  "mouth": {"x": 143.4, "y": 170.0},
  "head": {"cx": 143.4, "cy": 114.0, "r": 114},
  "eyes": [{"x": 98.4, "y": 120.0, "r": 13.5}, {"x": 188.4, "y": 120.0, "r": 13.5}],
  "body": {"x": 63.4, "y": 194.0, "w": 160, "h": 160},
  "sea": false
}
```
- `mouth`：食物要拖到的地方。`head`：頭的圓（戴帽子、眼睛從這裡看）。`eyes`：每隻眼睛的中心和半徑（海豚只有一隻看得到）。`body`：海綿可以擦的範圍。`sea`：海裡的寵物（dolphin、octopus、turtle）。

### 蛋 `eggs/`
- `<寵物>.svg`：200×250，每顆蛋外形和大小都一樣，顏色和花紋暗示裡面是誰（小狗咖啡色斑點、小貓橘色條紋、小兔粉紅色加小紅蘿蔔、恐龍綠色凸點、海豚藍色海浪、章魚紫色吸盤、海龜綠色六角形）。蛋的最下面是圖的下緣。
- `<寵物>_top.svg`、`<寵物>_bottom.svg`：沿著鋸齒裂成上下兩半，大小和整顆一樣，疊起來就是整顆蛋（孵蛋動畫用）。
- `eggs.json`：`egg.viewBox`、`egg.wobble`（搖晃的支點：底部中間）、`egg.crack`（裂縫鋸齒的點）、`ids`。

### 家 `homes/`
1080×1920，不透明。寵物站在 y≈1450 的中間；最上面 250、最下面 400 很單純（放按鈕），中間不擠。海豚的家在 y≈1450 有一圈水波，海豚在水面上。

### 小圖 `items/`、穿戴 `wear/`
都是 120×120：bowl、cookie（中間空著，APP 自己寫字母）、sponge、shower、ball、bubbleBall、moon、star、heart、giftClosed、giftOpen、brush、blanket、zzz、feast_closed、feast_open、sun。
`wear/bib.svg`、`wear/cap.svg`；`wear/wear.json` 寫著對齊點：圍兜的脖子在 (60, 24)，放在 `mouth` 下面一點；帽子的帽緣在 (60, 90)，放在頭頂（`head.cy - head.r × 0.8` 附近）。

另外四張（`words.py` 畫的，一樣 120×120）：
- `block.svg`：木頭積木，前面是空的，APP 自己印字母。前面那一面是 (21, 25) 起、78×78，中心在 (60, 64)（`words.py` 的 `BLOCK_FACE`）。
- `magnifier.svg`：放大鏡（找字母的按鈕）。
- `book.svg`：合起來的繪本，封面有一顆星星（貼紙簿的按鈕）。
- `task.svg`：夾板上的小清單，打了兩個勾（今天的任務；APP 用 30 像素也看得懂）。

### 單字圖 `words/`
貼紙簿裡每學會一個大寫字母，就貼上它的單字圖。240×240，背景透明，東西放在正中間、四周留 12 單位。檔名就是英文單字（空格和 `-` 換成 `_`），和 `glyphs.json` 的 `en` 對得上：
apple、ball（海灘球）、cat（灰色小貓，和橘色的寵物小貓不一樣）、dog（白色小狗，咖啡色耳朵和紅項圈）、egg（鳥窩裡一顆蛋）、fish、grapes、hat（草帽）、ice_cream（兩球加櫻桃）、juice（一杯柳橙汁）、kite、lion、moon、nose（小熊的臉，大大的鼻子是重點）、orange（一顆加一片）、pig、queen（戴皇冠的小皇后，不是真的人）、rabbit（咖啡色兔子抱紅蘿蔔，和白色的寵物小兔不一樣）、sun、tree、umbrella、violin、watermelon、xylophone、yo_yo、zebra。
動物和寵物一樣：圓圓的頭、亮亮的黑點眼睛、紅紅的臉頰。

### 獎勵圖 `rewards/`
家長設定獎勵時選的圖示，240×240，和單字圖一樣的格式：ice_cream（一球的甜筒）、park（樹和盪鞦韆）、toy（上發條的玩具車）、book（打開的故事書）、hug（兩顆愛心抱在一起）、star（大星星，「其他」用）。

### 開場故事 `story/`
1. 字母森林的邊上，黃昏，一間有圓門和暖暖窗戶的小屋（樹間飄著幾個發光的小字母，像螢火蟲；不要的話把 `story.py` 的 `LETTER_FIREFLIES` 改成 False）。
2. 同一個門口，七顆蛋在草地上微微發光（就是 `eggs/` 的蛋）。
3. 桌上一本打開的繪本，蛋從書頁裡探出頭：「選一顆」。
圖裡沒有字，故事的字由 APP 印。

### APP 圖示
`python3 icon.py export` 寫出：
- Android：`mipmap-{mdpi…xxxhdpi}/ic_launcher.png`（48～192，整張方形）；`mipmap-anydpi-v26/ic_launcher.xml` 加上 `drawable-{mdpi…xxxhdpi}/ic_launcher_foreground.png`、`ic_launcher_background.png`（108dp，小狗和積木都在中間 66dp 的安全圓裡）。`AndroidManifest.xml` 的 `android:icon` 是 `@mipmap/ic_launcher`。
- iOS：`AppIcon.appiconset/Contents.json` 列的每一張 PNG，照它的大小重畫，不透明。

## 改一張圖
1. 改對應的函式（例如 `pets.py` 的 `kitten`）。
2. 跑那支程式，再跑 `python3 preview.py 預覽.png` 看一下，最後幾行會印出每隻寵物四周留的空白（下面要是 0）。
