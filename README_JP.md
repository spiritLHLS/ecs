# ecs

[![Hits](https://hits.spiritlhl.net/ecs.svg?action=hit&title=Hits&title_bg=%23555555&count_bg=%2324dde1&edge_flat=false)](https://hits.spiritlhl.net)

## 言語

[中文文档](README.md) | [English Docs](README_EN.md) | [日本語ドキュメント](README_JP.md)

## 前書き
**以下の状況に遭遇した場合：**
- **このプロジェクトに記載されていないシステム/アーキテクチャ**
- **このプロジェクトのテストにバグがあり検出できない**
- **ローカル構成の変更を最小限に抑えたい**
- **より包括的なテストを希望する**

**テストには [https://github.com/oneclickvirt/ecs](https://github.com/oneclickvirt/ecs/blob/master/README_JP.md) をご利用ください**

### 互換性情報

| カテゴリ | サポートオプション |
|----------|------------------|
| **完全サポートシステム** | Ubuntu 18+, Debian 8+, Centos 7+, Fedora 33+, Almalinux 8.5+, OracleLinux 8+, RockyLinux 8+, AstraLinux CE, Arch |
| **部分サポートシステム** | FreeBSD (前提条件: `pkg install -y curl bash` を実行)、Armbian |
| **サポートアーキテクチャ** | amd64 (x86_64)、arm64、i386、arm |
| **サポート地域** | **インターネット接続可能なすべての地域** |

**注意：** 多システム多アーキテクチャの普遍的なテスト需要を考慮し、Shellバージョンは新機能開発を行わず、メンテナンスのみを行います。すべてのテスト機能はGolangバージョン ([https://github.com/oneclickvirt/ecs](https://github.com/oneclickvirt/ecs/blob/master/README_JP.md)) に再構築され、追加の環境依存を最小限に抑え、サードパーティのシェルファイル参照を完全に排除しています。

# メニュー
- [前書き](#前書き)
- [メニュー](#メニュー)
- [VPS_Fusion_Monster_Server_Test_Script](#VPS_Fusion_Monster_Server_Test_Script)
  - [Fusion_Monster_command](#Fusion_Monster_command)
    - [インタラクティブ形式](#インタラクティブ形式)
    - [非インタラクティブ形式](#非インタラクティブ形式)
  - [IP_Quality_Inspection](#IP_Quality_Inspection)
  - [Fusion_Monster_Description](#Fusion_Monster_Description)
  - [Fusion_Monster_Function](#Fusion_Monster_Function)
- [フレンドリーリンク](#フレンドリーリンク)
  - [レビュー_チャンネル](#レビュー_チャンネル)
    - [https://t.me/vps\_reviews](#httpstmevps_reviews)
- [Stargazers_over_time](#Stargazers_over_time)
- [感謝](#感謝)

<a id="top"></a>
------
<a id="artical_1"></a>

# VPS_Fusion_Monster_Server_Test_Script

## Fusion_Monster_command

### インタラクティブ形式

```bash
curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -en
```

または

```bash
curl -L https://github.com/spiritLHLS/ecs/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -en
```

または

```
bash <(wget -qO- bash.spiritlhl.net/ecs) -en
```

### 非インタラクティブ形式

```bash
curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -en -m 1
```

または

```bash
curl -L https://github.com/spiritLHLS/ecs/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh -en -m 1
```

または

```
curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh
```

スクリプトファイルをダウンロードし、次のように使用します

```bash
bash ecs.sh -en -m 1
```

このようなパラメータ化されたコマンドでオプションを指定して実行します

以下はパラメータの説明です：

| コマンド | 項目 | 説明 | 備考 |
| ---- | ---- | ----------- | ---- |
| -m | 必須 | 元のメニューの対応するオプションを指定します。最大3レベルの選択をサポートします。例：```bash ecs.sh -m 5 1 1```を実行すると、メインメニューのオプション5のサブオプション1のオプション1のスクリプトが実行されます | デフォルトでは1つのパラメータのみを指定します。例：``` -m 1```を実行すると、融合モンスターの完全体が実行されます。```-m 1 0```および```-m 1 0 0```を実行すると、どちらも融合モンスターの完全体が実行されます。 |
| -en | オプション | 強制的に英語で出力します | このコマンドがない場合、デフォルトで中国語で出力されます |
| -i | オプション | バックホールルーティングテストのターゲットIPV4アドレスを指定します | ```ip.sb```、```ipinfo.io```などのサイトからローカルIPV4アドレスを取得して指定します |
| -base | オプション | 基本的なシステム情報のみをテストします | このコマンドがない場合、デフォルトでメニューオプションの組み合わせに従ってテストします |
| -ctype | オプション | CPUをテストする方法を指定します。オプションは```gb4```, ```gb5```, ```gb6```で、それぞれgeekbenchのバージョン4、5、6に対応します | このコマンドがない場合、デフォルトでsysbenchを使用します |
| -dtype | オプション | ハードディスクのIOをテストするプログラムを指定します。オプションは```dd```, ```fio```で、前者は高速で後者は低速です | このコマンドがない場合、デフォルトで両方を使用してテストします |
| -mdisk | オプション | 複数のマウントされたディスクのIOをテストします | このコマンドにはシステムディスクのテストが含まれます |
| -stype | オプション | ```cn```または```net```のデータを使用して速度をテストすることを指定します | このコマンドがない場合、デフォルトで```net```データを優先して速度をテストし、使用できない場合は```cn```データに切り替えます |
| -bansp | オプション | 強制的に速度テストを行わないことを指定します | このコマンドがない場合、デフォルトで速度をテストします |
| -banup | オプション | 強制的に共有リンクを生成しないことを指定します | このコマンドがない場合、デフォルトで共有リンクを生成します |

## IP_Quality_Inspection

- 複数のデータベース検索とブラックリスト検索を含むIP品質検査
- ```IPV4```および```IPV6```の検査を含み、ASNおよびアドレス検索を含む

```bash
bash <(wget -qO- bash.spiritlhl.net/ecs-ipcheck)
```

または

```bash
bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/ecs/main/ipcheck.sh)
```

または

事前に```dos2unix```をインストールする必要があります

```bash
wget -qO ipcheck.sh --no-check-certificate https://gitlab.com/spiritysdx/za/-/raw/main/ipcheck.sh
dos2unix ipcheck.sh
bash ipcheck.sh
```

## Fusion_Monster_Description

このプロジェクトは環境依存の問題を避けるため、`/root`パスで実行することをお勧めします。デフォルトでパッケージマネージャーを自動更新しますが、本番環境での使用は避けてください。ローカル設定を変更しないよう、前述のGoバージョンを使用することをお勧めします。

「融合モンスター」の実行結果は、現在のディレクトリの`test_result.txt`に保存されます。`screen`や`tmux`で実行し、SSH接続を一度切断して時間をおいてからファイルを確認することで、不安定なSSH接続によるテスト中断を避けることができます。

**非常に低スペックのマシンをテストする場合、この方法で実行することで古いIOやCPUによるSSH接続の中断を防げます。screenで文字化けが表示されても問題ありません。共有リンクの結果には文字化けは含まれません。**

融合モンスターの完全版と簡易版は、実行完了時に自動的に結果をpastebinにアップロードし、共有リンクを返します。テスト中に終了したい場合は、`Ctrl+C`を押してテストを中止できます。これにより自動的に終了し、残りの環境依存ファイルを削除します。

最低スペックのマシンのテスト例（47分で完了）：[リンク](https://github.com/spiritLHLS/ecs/blob/main/lowpage/README.md)

このプロジェクトには**国内**と**国外**のサーバーテスト環境インストールとプリセットファイルダウンロードを加速する**CDN**サポートが組み込まれていますが、中国本土ではCDNの接続性や帯域幅の制限により読み込みが遅くなる場合があります。

**このプロジェクトを初めて使用する場合は、説明を確認することをお勧めします：[ジャンプ](https://github.com/oneclickvirt/ecs/blob/master/README_NEW_USER.md)**

その他の情報：
<details>
<summary>クリックして展開</summary>
マークされているオリジナルコンテンツを除き、他のすべてのセクションは借用して最適化されたバージョンであり、元のスクリプトとは異なります。

すべての検出方法は並列テストを考慮しており、一部のコンポーネントではこの技術が使用されています。通常の順次実行と比較して2〜3分の最適化が図られています。

システム基本情報テストは、複数のソースと自己修正の検出部分（sysctl、NATタイプ検出、同時ASN検出など）を組み合わせています。

CPUテストはデフォルトでsysbenchスコアリングを使用し、yabsのgb4やgb5は使用しません（デフォルトではgeekbenchではありませんが、コマンドで一般的なgeekbenchバージョンを指定してテストできます）。関連する説明はGoバージョンの融合モンスター説明の最後にあるQ&Aを参照してください。

IOテストには、lemonbenchのddディスクテストとyabsのfioディスクテストの2種類が含まれています。前者はエラーが大きい可能性がありますが、ディスクサイズの制限なく高速にテストでき、後者はより正確ですが速度が遅く、ディスクとメモリサイズに制限があります。

ストリーミングメディアテストには、goコンパイルバイナリファイルとシェルスクリプトバージョンの2種類があります。それぞれに長所と短所があり、必要に応じて比較してください。

TikTokテストにはsuperbenchとlmc999の両バージョンがあります。どちらかが機能しなくなった場合、いずれかのバージョンに更新される可能性があります。最新のスクリプトを参照してください。

リターンルートテストには、GOコンパイルバイナリバージョンと友人からのPRバージョンを使用しています。複数のIPリストに適応し、部分的なクエリをマージするための最適化が行われています。

IP品質検出は完全にオリジナルです。バグや追加のデータベースソースがある場合は、issuesで提起してください。一般的に、IP2LocationデータベースのIPタイプを確認してください。ポート25がメール用にアクセス可能であれば、郵便局を設定できます。

融合モンスターのIP品質検出は、Cloudflareの脅威スコアを照会せずに簡略化されています。個人オリジナルセクションのIP品質検出（またはリポジトリの説明に記載されているIP品質検出コマンド）が完全版です。

三ネットワーク速度テストでは、自作スクリプトを使用し、可能な限り最新のノードとコンポーネントを使用しています。また、バックアップとして第三者のgoバージョンテストコアを備え、速度テストノードリストの自己更新とシステム環境に適応したテストを提供しています。

その他のサードパーティスクリプトはサードパーティスクリプトセクションに分類されており、異なる作者による同じタイプのさまざまな競合スクリプトを見つけることができます。融合モンスターが満足できない場合やエラーがある場合は、そのセクションを確認してください。

オリジナルスクリプトセクションには個人的に作成された部分が含まれており、時々確認して、ニッチまたはユニークなスクリプトの更新を確認することができます。

VPSテスト、VPS速度テスト、VPS総合パフォーマンステスト、VPSリターンルートテスト、VPSストリーミングメディアテストなど、すべてのテスト融合スクリプト - このスクリプトは統合可能なすべてを統合しています。
</details>

## Fusion_Monster_Function

- [x] テスト方向と個別テストの自由な組み合わせ、および第三者スクリプトのコレクション。Fusion Monsterのテストは自己最適化および修正されており、元のスクリプトとは異なります。
- [x] 基本情報のクエリ - [bench.sh](https://github.com/teddysun/across/blob/master/bench.sh)、[superbench.sh](https://www.oldking.net/350.html)、[yabs](https://github.com/masonr/yet-another-bench-script)、[lemonbench](https://github.com/LemonBench/LemonBench)のオープンソースに感謝します。私は整理、修正、最適化し、元のバージョンとは一致しません。
- [x] CPUテスト - [lemonbench](https://github.com/LemonBench/LemonBench)および[yabs](https://github.com/masonr/yet-another-bench-script)のオープンソースに感謝します。私は整理、修正、最適化しました。
- [x] メモリテスト - [lemonbench](https://github.com/LemonBench/LemonBench)のオープンソースに感謝します。私は整理、修正、最適化しました。
- [x] ディスクdd読み書きテスト - [lemonbench](https://github.com/LemonBench/LemonBench)のオープンソースに感謝します。私は整理、修正、最適化しました。
- [x] ハードディスクfio読み書きテスト - [yabs](https://github.com/masonr/yet-another-bench-script)のオープンソースに感謝します。私は整理、修正、最適化しました。
- [x] Mikadoストリーミング解除テスト - [sjlleoのバイナリファイル](https://github.com/sjlleo?tab=repositories)に感謝します。私は修正、整理、最適化しました。
- [x] ストリーミングメディア解除テスト - [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck)のオープンソースに感謝します。私は整理、修正、最適化しました。
- [x] Tiktok解除 - [TikTokCheck](https://github.com/lmc999/TikTokCheck)のオープンソースに感謝します。私は整理、修正、最適化しました。
- [x] バックホールルーティングおよび帯域幅タイプの検出（ビジネスワイド/ホームワイド/データセンター） - [fscarmen](https://github.com/fscarmen)のPRおよび私の技術的なアイデアに感謝します。私は修正、最適化、メンテナンスを行いました。
- [x] IP品質およびポート25の検出（IPV4およびIPV6を含む） - このスクリプトはオリジナルであり、インターネットが提供するクエリリソースに感謝します。
- [x] speedtest速度テスト - 自作の[ecsspeed](https://github.com/spiritLHLS/ecsspeed)リポジトリを使用し、速度テストサーバーIDを自動更新し、常に手動で速度テストIDを更新する問題を解決します。

# フレンドリーリンク

## レビュー_チャンネル

### https://t.me/vps_reviews

# スクリーンショット

<details>
<summary>Click to show</summary>

![画像](https://github.com/spiritLHLS/ecs/assets/103393591/0acecaea-8cbc-43a0-9262-e2fa157fb8e9)

![画像](https://github.com/spiritLHLS/ecs/assets/103393591/d25713e1-eeb0-48c0-9d6f-6ac1a0f6b6df)

![画像](https://github.com/spiritLHLS/ecs/assets/103393591/1b578739-4809-4ab0-8187-b860a502c8d9)

![画像](https://github.com/spiritLHLS/ecs/assets/103393591/010d4e5d-561e-4aa3-8313-e592f29405d1)

![画像](https://github.com/spiritLHLS/ecs/assets/103393591/bfe775ad-323c-4f6e-8d81-fcf787644653)

<details>

# Stargazers_over_time

[![Stargazers over time](https://starchart.cc/spiritLHLS/ecs.svg)](https://starchart.cc/spiritLHLS/ecs)

# 感謝

感謝 [ipinfo.io](https://ipinfo.io) [ip.sb](https://ip.sb) [cheervision.co](https://cheervision.co) [scamalytics.com](https://scamalytics.com) [abuseipdb.com](https://www.abuseipdb.com/) [virustotal.com](https://www.virustotal.com/) [ip2location.com](https://ip2location.com/) [ip-api.com](https://ip-api.com) [ipregistry.co](https://ipregistry.co/) [ipdata.co](https://ipdata.co/) [ipgeolocation.io](https://ipgeolocation.io) [ipwhois.io](https://ipwhois.io) [ipapi.com](https://ipapi.com/) [ipapi.is](https://ipapi.is/) [ipqualityscore.com](https://www.ipqualityscore.com/) [bigdatacloud.com](https://www.bigdatacloud.com/)  などのサイトが提供するAPIを使用してテストを行い、インターネット上のさまざまなサイトが提供するクエリリソースに感謝します

すべてのオープンソースプロジェクトに感謝し、元のテストスクリプトを提供してくれたことに感謝します

感謝

<a href="https://h501.io/?from=69" target="_blank">
  <img src="https://github.com/spiritLHLS/ecs/assets/103393591/dfd47230-2747-4112-be69-b5636b34f07f" alt="h501">
</a>

このオープンソースプロジェクトをサポートするためにホスティングを提供してくれました

また、以下のプラットフォームに編集およびテストのサポートを提供してくれたことに感謝します

![PyCharm logo](https://resources.jetbrains.com/storage/products/company/brand/logos/PyCharm.png)


