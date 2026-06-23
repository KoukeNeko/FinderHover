# FinderHover

**macOS のための、欠けていた「データ HUD」。**
ファイルのメタデータを瞬時に確認。`Cmd+I` は不要です。

<p align="center">
  <a href="README.md">🇺🇸 English</a> | <a href="README_zh-Hant.md">🇹🇼 繁體中文</a> | <a href="README_ja.md">🇯🇵 日本語</a>
</p>

<p align="center">
  <img src="/FinderHover/Assets.xcassets/AppIcon.appiconset/Icon-256.png" alt="FinderHover Icon" width="128">
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/KoukeNeko/FinderHover?style=for-the-badge&logo=github&logoColor=white&label=Release" alt="Release">
  <img src="https://img.shields.io/github/downloads/KoukeNeko/FinderHover/total?style=for-the-badge&logo=github&logoColor=white&label=Downloads" alt="Downloads">
  <img src="https://img.shields.io/badge/Homebrew-Available-FBB040?style=for-the-badge&logo=homebrew&logoColor=white" alt="Homebrew">
  <img src="https://img.shields.io/badge/macOS-14.0+-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 14.0+">
  <img src="https://img.shields.io/badge/Swift-5.0-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift 5.0">
  <img src="https://img.shields.io/github/license/KoukeNeko/FinderHover?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/github/stars/KoukeNeko/FinderHover?style=for-the-badge&logo=github&logoColor=white" alt="Stars">
</p>

---

<p align="center">
  <img src="docs/demo.gif" alt="FinderHover デモ" width="800">
</p>

---

## 📝 最新情報

### v1.9.0 - メモ
- **メモ：** ホバーポップアップから任意のファイルに個人的なメモを追加 —— メモはファイル自体（拡張属性）に保存されるため、再起動後も保持され、ファイルをコピー・移動すると一緒に移動します
- **高さ自動調整：** 最低 3 行で、入力に応じて拡張。編集中はフォーカスされた入力欄スタイルを表示
- **より安定：** アクセシビリティの問い合わせをメインスレッド外に移動（Finder の応答が遅くても UI が固まりません）。さらに大きなファイルをより軽量・安全に読み込み、多数の修正
- **修正：** フォーカス時に Liquid Glass ポップアップの背後に出ていた黒い角
- 🙏 **[@zmlim](https://github.com/zmlim) さんに心より感謝します。** メモ機能を設計・実装してくださいました（[#14](../../pull/14)）。本リリースはその成果の上に成り立っています

### v1.8.0 - 正式なコード署名と Liquid Glass
- **署名と公証：** Gatekeeper の回避が不要になり、App がすぐに開きます
- **Liquid Glass：** macOS 26 (Tahoe) 向けの新しいビジュアルエフェクトオプション
- **Universal Binary：** Hardened Runtime に対応した arm64 + x86_64

### v1.8.1 - バグ修正
- **修正：** 英語のダウンロードメタデータラベルを短縮し、配置を改善

[変更履歴の全文を見る](CHANGELOG.md)

---

## ⚡️ なぜ FinderHover なのか？

**抱えている問題：**
画像の解像度を確認したい？動画のコーデックは？圧縮ファイルの中身は？そのたびに、こうする必要があります：
1. 右クリック → 情報を見る（または `Cmd+I`）
2. ウィンドウが開くのを待つ
3. 手動で閉じる
4. ファイルごとに繰り返す

**解決策：**
FinderHover は Finder にかぶせる **X 線レイヤー** として機能します。どんなファイルでもマウスを重ねるだけで、必要なデータが瞬時に表示されます。

### 比較：情報を見る vs FinderHover

|  | macOS 情報を見る (`Cmd+I`) | FinderHover |
|---|---|---|
| **起動方法** | 右クリック → 情報を見る（または `Cmd+I`） | マウスを重ねる |
| **速度** | 遅く、ウィンドウが積み重なる | 瞬時に表示、自動で消える |
| **情報の深さ** | 基本情報（サイズ、種類、日付） | **詳細なメタデータ**（EXIF、コーデック、アーカイブの中身、Git 情報） |
| **ワークフロー** | 作業を中断させる | 邪魔にならないオーバーレイ |

---

## ✨ 機能

### 🔍 Finder を超える情報量
FinderHover は、Finder が**決して表示しない**メタデータを明らかにします：

#### 📦 アーカイブの X 線透視
`zip`、`rar`、`7z`、`tar.gz`、`iso` の中身を**解凍せずに**のぞき見できます。
- 📋 ファイル一覧とファイル数を即座に表示
- 🔐 暗号化の有無を検出（開く前にパスワード保護されているか分かる）
- 📊 圧縮率と実際の展開後サイズを確認

#### 💻 開発者目線
開発者が、開発者のために作りました。
- **コードの洞察：** **38 以上の言語**に対応した、瞬時の行数カウントと構文検出
- **Git 認識：** リポジトリフォルダーで現在のブランチ、コミット数、リモート URL、未コミットの変更を表示
- **バイナリ解析：** 実行ファイルの Mach-O ヘッダー、アーキテクチャ（`arm64`/`x86_64`/Universal）、コード署名状態、SDK バージョンを検査
- **Xcode プロジェクト：** ターゲット、ビルド構成、Swift バージョン、デプロイメントターゲットを表示

#### 📸 写真とメディア
- **写真：** カメラ機種、レンズ情報、焦点距離、ISO、絞り、シャッタースピード、GPS 座標、IPTC/XMP メタデータ（作成者、著作権、キーワード、評価）
- **動画：** コーデック（H.264、HEVC など）、解像度、ビットレート、フレームレート、HDR 形式（Dolby Vision、HDR10、HLG）、チャプター、字幕トラック
- **オーディオ：** トラック名、アーティスト、アルバム、ジャンル、再生時間、ビットレート、サンプルレート、チャンネル数

---

### 🎨 賢く、カスタマイズ自在

#### 🧠 インテリジェントな状況認識
- **瞬時のプレビュー：** ホバー遅延を調整可能（0.1 秒 〜 2.0 秒）
- **自動非表示：** ファイルのリネーム中、項目のドラッグ中、コンテキストメニュー使用中は自動で消える
- **QuickLook 連携：** PDF、画像、書類のネイティブなサムネイル表示

#### 🌈 2 つの表示スタイル
- **macOS スタイル：** サムネイル、アイコン、完全なメタデータを備えたリッチな表示
- **Windows スタイル：** 必要な情報のみを表示する、最小限のツールチップ風表示

#### 🎛️ 完全なコントロール
- ウィンドウサイズ、不透明度（70〜100%）、フォントスケールを調整可能
- **レイアウトエディター：** メタデータフィールドをドラッグして並べ替え、カテゴリーごとに表示/非表示を切り替え
- **多言語対応：** **英語**、**繁体字中国語（繁體中文）**、**日本語**をネイティブにサポート

---

### 📊 豊富なメタデータ対応（120 以上のファイル形式）

| カテゴリー | 対応メタデータ |
|----------|-------------------|
| **📷 写真** | カメラ機種、レンズ、ISO、絞り、シャッタースピード、GPS、IPTC/XMP データ、カラープロファイル、HDR ゲインマップ |
| **🎬 動画** | コーデック、解像度、ビットレート、フレームレート、HDR 形式（Dolby Vision、HDR10、HLG）、チャプター、字幕トラック |
| **🎵 オーディオ** | トラック名、アーティスト、アルバム、ジャンル、再生時間、ビットレート、サンプルレート、チャンネル数 |
| **💻 コード** | 38 以上の言語の行数カウント、ファイルエンコーディング、構文検出 |
| **📝 Markdown** | タイトル、フロントマター（YAML/TOML/JSON）、見出し/画像/リンク/コードブロック数 |
| **🌐 HTML/Web** | タイトル、メタディスクリプション、キーワード、作成者、言語、Open Graph タグ |
| **⚙️ 設定ファイル** | JSON/YAML/TOML のキー数、ネストの深さ、構文の妥当性 |
| **🎨 デザイン** | PSD のレイヤー/カラーモード/ビット深度、SVG/AI の寸法、フォントのグリフ数 |
| **📦 アーカイブ** | 形式タイプ、ファイル数、圧縮率、暗号化状態 |
| **📚 電子書籍** | タイトル、著者、出版社、ISBN、言語 |
| **🖼️ ベクター** | SVG の viewBox、EPS のカラーモード、要素数 |
| **📱 App バンドル** | Bundle ID、バージョン、最低 macOS、コード署名、エンタイトルメント、アーキテクチャ |
| **⚡ 実行ファイル** | アーキテクチャ（arm64/x86_64）、コード署名、最低 OS、SDK バージョン |
| **🗄️ SQLite** | テーブル/インデックス/トリガー/ビュー数、総行数、スキーマバージョン、エンコーディング |
| **📂 Git リポジトリ** | 現在のブランチ、コミット数、リモート URL、未コミットの変更、タグ |
| **💿 ディスクイメージ** | 形式（DMG、ISO）、圧縮率、暗号化状態、パーティションスキーム |
| **🧊 3D モデル** | 頂点/面数、メッシュ/マテリアル数、アニメーション、バウンディングボックス |
| **🛠️ Xcode** | プロジェクト名、ターゲット、ビルド構成、Swift バージョン、デプロイメントターゲット |
| **🏷️ システム** | Finder タグ、ダウンロード元、検疫情報、iCloud 状態、シンボリックリンク先 |

---

## 🛡️ プライバシー第一

> **100% ローカル処理。**
> FinderHover は macOS の**アクセシビリティ API** を使ってカーソル下のファイルを検出します。メタデータの抽出はすべて**あなたのマシン上**で行われます——ネットワーク通信なし、解析なし、トラッキングなし。

- ✅ **ネットワークアクセスゼロ：** すべての処理はローカルで完結
- ✅ **オープンソース：** GitHub でコードを自分で確認できる
- ✅ **Apple ネイティブ：** Swift、AVFoundation、PDFKit などのネイティブフレームワークで構築

**なぜアクセシビリティ API なのか？**
低速な AppleScript ポーリングに頼る従来のツールとは異なり、FinderHover はシステムのアクセシビリティイベントストリームを直接監視するため、高いパフォーマンスと極めて低い負荷を実現します。

---

## 📦 インストール

### Homebrew（推奨）

```bash
brew install koukeneko/tap/finderhover
```

---

### 直接ダウンロード

1. [Releases](../../releases) から `FinderHover.app.zip` をダウンロード
2. 解凍して「アプリケーション」フォルダーに移動
3. 確認が表示されたらアクセシビリティ権限を許可

---

### ソースからビルド

```bash
git clone https://github.com/KoukeNeko/FinderHover.git
cd FinderHover
xcodebuild -scheme FinderHover -configuration Release
```

**必要環境：** Xcode 15 以上、macOS Sonoma 14.0 以上

> **注意：** macOS 26.4 Beta 1 は非対応です。Beta 2 以降にアップデートしてください。

---

## ⚙️ セットアップと使い方

### 初回起動

1. Launchpad または「アプリケーション」から FinderHover を起動
2. App が**メニューバー**に表示されます
3. **アクセシビリティ権限**を許可（システム設定 → プライバシーとセキュリティ → アクセシビリティ）
4. Finder で任意のファイルにマウスを重ねると、メタデータが表示されます

### 設定

メニューバーのアイコンをクリックして設定パネルを開きます。

**ヒント：** 「ログイン時に起動」を有効にすると、Mac の起動時に FinderHover が自動的に立ち上がります。

> **既知の問題（macOS 27 beta）：** 現在 macOS 27 beta では、設定画面が正しく表示されないことがあります。ただし、主要な機能はすべて正常に動作します。

---

## 🚀 技術的なハイライト

### ⚡️ 高性能アーキテクチャ
- **リアクティブな UI 更新：** **Combine** フレームワークと `debounce` 演算子を活用し、CPU 使用率を極小に保ちながら滑らかな UI 更新を実現
- **ネイティブフレームワーク：** Apple の `AVFoundation`、`PDFKit`、`QuickLookThumbnailing`、`SQLite3`、`CoreGraphics` を基盤とし、外部依存なし
- **スマートキャッシュ：** サムネイルとメタデータのキャッシュにより、重複処理を削減

### 🛠️ 堅牢なメタデータエンジン
**120 以上のファイル形式**に対応し、深い検査機能を備えています：
- **アーカイブ：** `libarchive` とネイティブ API を使い、解凍せずに zip/rar/7z/iso の構造を読み取り
- **メディア：** `AVFoundation` を使って動画コーデック、HDR メタデータ、オーディオ仕様を抽出
- **コード：** 38 以上のプログラミング言語を検出し、行数を正確にカウント
- **Git：** `.git` ディレクトリを解析し、ブランチ、コミット、リモート情報を取得
- **バイナリ：** Mach-O ヘッダーを解析し、アーキテクチャとコード署名を確認

---

## 🛠️ プロジェクト構成

```
FinderHover/
├── App/          # アプリケーションのライフサイクル（FinderHoverApp、HoverManager）
├── Core/         # MouseTracker、FinderInteraction、FileInfo
├── Extractors/   # メタデータ抽出ロジック（ArchiveExtractor、DeveloperExtractor など）
├── UI/
│   ├── Windows/  # フローティングホバーウィンドウ、設定コンテナ
│   └── Settings/ # モジュール化された設定ページ
└── Utilities/    # ローカライズ、ロギング、フォーマット補助
```

---

## 📸 スクリーンショット

<p float="left">
  <img src="https://github.com/user-attachments/assets/fe969256-a07d-4db6-8715-a3bb3226782b" width="45%" />
  <img src="https://github.com/user-attachments/assets/f492dc51-9fd8-49f2-b854-d9fc4ac026a6" width="45%" />
</p>
<p float="left">
  <img src="https://github.com/user-attachments/assets/dc04ba05-2bcb-4308-b0cc-bd5ed2259d07" width="45%" />
  <img src="https://github.com/user-attachments/assets/140accdd-6034-4b2d-b4d9-ccc55a28586c" width="45%" />
</p>

---

## 🤝 コントリビューション

コントリビューションを歓迎します！協力できる方法は以下のとおりです：

- **エクストラクターの追加：** メタデータ抽出ロジックは [Core/FileInfo.swift](FinderHover/Core/FileInfo.swift) を参照
- **UI の改善：** ビジュアルの強化は [UI/Windows/](FinderHover/UI/Windows/) を参照
- **ローカライズ：** [Localizable.strings](FinderHover/Utilities/Localizable.strings) に翻訳を追加

**機能リクエストとバグ報告：** [GitHub Issues](../../issues) で issue を作成してください。

### 🙏 謝辞

貢献してくださったすべての方々に感謝します —— 特に、v1.9.0 の目玉機能「メモ」を設計・実装してくださった [@zmlim](https://github.com/zmlim) さんに感謝します（[#14](../../pull/14)）。

---

## 📄 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照してください。

---

<p align="center">
  <strong>❤️ と Swift で作りました</strong><br>
  パワーユーザー、開発者、そしてファイルコレクターのために
</p>
