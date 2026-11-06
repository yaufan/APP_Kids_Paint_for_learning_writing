# 字母寵物

給 3 歲以上小朋友的 APP：照著筆順學寫 0～9、大寫 A～Z、小寫 a～z。寫對了，寵物得到特殊糧食，長得比較快；寵物越大，越會陪小朋友。家長可以看進度、自己設定獎勵。

- 設計：[docs/design.md](docs/design.md)
- 和「[畫畫小鎮](https://github.com/yaufan/APP_Kids_Paint)」是兄弟 APP：同一個作者、同一套技術；畫風不同，是繪本故事風格。
- 不連網、不定位、沒有廣告、不賣東西、沒有帳號。

## 下載（Android）
- 最新版：[Releases](https://github.com/yaufan/APP_Kids_Paint_for_learning_writing/releases/latest)，一般手機下載 `letter-pets-版本-arm64.apk`。
- 用手機掃描 [docs/download-qr.png](docs/download-qr.png)。

## 目前進度
- 0.2.0（測試版，2026-11-06）：一筆一筆寫、提示慢慢變淡、每天的任務、字母圖鑑、找字母、家長自訂獎勵和看進度。
- 0.1.0（測試版，2026-11-04）：開場故事、選蛋、孵蛋取名字、寵物的家（照顧和互動）、寫字的四個關卡（看、點、描、寫）、數字 0～9 和大寫 A～Z、特殊糧食和今日大餐、背景音樂和音效、家長模式。
- 版本紀錄：[CHANGELOG.md](CHANGELOG.md)。

## 程式
- `app/`：Flutter 程式（Android 和 iOS）。
- `design/`：用程式產生的字形、圖和聲音。

## 授權
- 非商業使用授權：自己、家人使用，或學校、非營利團體的教學，都可以免費使用、修改、分享，要註明出處。
- 商業用途（販賣、收費、廣告、上架）要先取得作者書面同意。也不可以拿來訓練 AI。
- 細節見 [LICENSE](LICENSE)。
