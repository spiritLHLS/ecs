# ecs

[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FspiritLHLS%2Fecs&count_bg=%2357DEFF&title_bg=%23000000&icon=cliqz.svg&icon_color=%23E7E7E7&title=hits&edge_flat=false)](https://www.spiritlhl.net/)

[<img src="https://api.gitsponsors.com/api/badge/img?id=501535202" height="20">](https://api.gitsponsors.com/api/badge/link?p=haU3VlXCDVRGPfHZE5aj8w8TKG5twqbYUa3jtSjEzkLfg4Q9TY32mTyF8RyNmnCsp1NADZHpPEhh3aKZ039SVg1DhsoX7gsoTK2dMkHlCVVrrqx82KH/ppUK/8ryOqfjpqPCBCduftYP5VNUNidMJw==)

## 言語

[中文文档](README.md) | [English Docs](README_EN.md) | [日本語ドキュメント](README_JP.md)

## 前書き

**このプロジェクトに記載されていないシステム/アーキテクチャがある場合、またはこのプロジェクトのテストでバグが発生して検出できない場合、またはテストがローカル構成を魔改造したくない場合、または環境の変更を最小限に抑えたい場合、またはより包括的なテストを希望する場合。**

**テストには[https://github.com/oneclickvirt/ecs](https://github.com/oneclickvirt/ecs/blob/master/README_JP.md)を試してください**

サポートされているシステム：

Ubuntu 18+、Debian 8+、Centos 7+、Fedora 33+、Almalinux 8.5+、OracleLinux 8+、RockyLinux 8+、AstraLinux CE、Arch

半サポートシステム：

FreeBSD（前提条件として```pkg install -y curl bash```を実行）、Armbian

サポートされているアーキテクチャ：

amd64（x86_64）、arm64、i386、arm

サポートされている地域：

インターネットに接続できる場所ならどこでもサポート

PS: 多システム多アーキテクチャの普遍的なテストの需要を考慮して、ShellバージョンのFusion Monsterは新機能の開発を行わず、メンテナンスのみを行い、テストはGolangバージョンにリファクタリングされています（[https://github.com/oneclickvirt/ecs](https://github.com/oneclickvirt/ecs/blob/master/README_JP.md)）。

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

Fusion Monsterスクリプトは、/rootパスで実行するのが最適です。これにより、さまざまな奇妙な問題を回避できます

Fusion Monsterの結果は、現在のパスの```test_result.txt```に保存されます。```screen```または```tmux```で実行し、SSHからログアウトしてしばらくしてからファイルを確認できます

**時々、IOやCPUが非常に低性能なマシンをテストしたい場合、上記のように実行することで、テスト中にSSH接続が中断されるのを回避できます。これにより、テストが途中で中断されることはありません。screenで表示が乱れる場合でも問題ありません。結果の共有リンクには乱れがありません**

Fusion Monsterの完全版と簡易版は、テストが完了すると結果をpastebinに自動的にアップロードし、共有リンクを返します。テストの途中で終了したい場合は、```Ctrl+C```を同時に押してテストを終了できます。この場合、自動的に終了し、残りのファイルを削除します

**CDN**を使用してサーバー環境のインストールとプリファブファイルのダウンロードを加速します

Fusion Monsterテストの説明と一部のテスト結果の内容の説明（初めて使用するユーザーに推奨）：
<details>

オリジナルの内容がマークされているものを除き、他のすべてのセクションは借用および最適化されたバージョンであり、元の対応するスクリプトとは異なります

すべてのテストは並行テストの使用を考慮しており、一部の部分ではこの技術を使用しています。通常の順次実行よりも2〜3分短縮されており、独自のものであり、同様の技術を持つテストは現在ありません

システム基本情報テストは、他のいくつかの部分と私自身のパッチテスト（systl、NATタイプ検出、並行ASN検出など）を統合しており、現在最も包括的で一般的なものです

CPUテストはデフォルトでsysbenchテストスコアを使用し、yabsのgb4またはgb5ではありません（デフォルトではgeekbenchではありませんが、コマンドでgeekbenchの一般的なバージョンを指定してテストできます）。前者は単に質数を計算して速��をテストするだけであり、後者のgeekbenchはシステム全体をテストして加重スコアを計算します

sysbenchテストスコアを使用する場合、これは毎秒処理されるイベントの数です。この指標は、強力なサーバーでも低性能のサーバーでも迅速に測定できますが、geekbenchは多くの場合測定できないか、速度が非常に遅く、少なくとも2分半かかります

CPUテストの単一コアsysbenchスコアが5000以上の場合、これは第1ティアに分類されます。4000から5000ポイントは第2ティアに分類され、1000ポイントごとに1つのクラスに分類されます。自分がどのクラスにいるかを確認してください

AMDの7950xの単一コアのフルブラッドパフォーマンススコアは約6500であり、AMDの5950xの単一コアのフルブラッドパフォーマンススコアは約5700です。Intelの通常のCPU（E5など）は約1000〜800であり、500未満の単一コアCPUは性能が低いと言えます

IOテストには2種類が含まれており、lemonbenchのddディスクテストとyabsのfioディスクテストから派生しています。総合的に見ると、前者は誤差が大きいかもしれませんが、テスト速度が速く、ハードディスクのサイズに制限がありません。後者はより現実的ですが、テスト速度が遅く、ハードディスクとメモリのサイズに制限があります

ストリーミングメディアテストには2種類が含まれており、1つはgoでコンパイルされたバイナリファイルで、もう1つはshellスクリプトバージョンです。両方にはそれぞれの利点と欠点があり、相互に比較して確認できます

tiktokテストにはsuperbenchとlmc999の2つのバージョンがあり、どちらかが無効になると、最新のスクリプトに更新される可能性があります

バックホールルーティングテストには、GOでコンパイルされたバイナリバージョンと友人のPRバージョンが選択されており、複数のIPリストに適応し、一部のクエリを統合するために最適化されています

IP品質テストは純粋にオリジナルであり、バグや追加のデータベースソースがある場合は、issuesで提起できます。日常的にはIP2LocationデータベースのIPタイプを確認できます。25ポートのメールボックスに到達できる場合、郵便局を構築できます

Fusion MonsterのIP品質チェックは簡略化されており、Cloudflareの脅威スコアを照会しません。個人のオリジナルセクションのIP品質チェックが完全版です（または、リポジトリの説明に記載されているIP品質チェックのコマンドも完全版です）

速度テストには自作の速度テストスクリプトを使用し、最新のノードと最新のコンポーネントを使用して速度テストを行い、予備の第三者goバージョンの速度テストカーネルがあり、速度テストノードリストを自動更新し、システム環境に適応して速度テストを行います

他の第三者スクリプトは第三者スクリプトエリアにまとめられており、同じタイプのスクリプトが異なる著者によって提供されています。融合モンスターが満足できない場合やエラーがある場合は、その部分を確認してください

オリジナルスクリプトエリアは個人のオリジナル部分であり、時折確認することができます。偏ったスクリプトや独自のスクリプトが更新される可能性があります

VPSテスト、VPS速度テスト、VPS総合性能テスト、VPSバックホールルーティングテスト、VPSストリーミングテストなど、すべてのテストを融合したスクリプトです。このスクリプトは融合できるものをすべて融合しています

</details>

**[トップに戻る](https://github.com/spiritLHLS/ecs/blob/main/README_JP.md#top)**

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

**[トップに戻る](https://github.com/spiritLHLS/ecs/blob/main/README_JP.md#top)**

# スクリーンショット

![画像](https://github.com/spiritLHLS/ecs/assets/103393591/0acecaea-8cbc-43a0-9262-e2fa157fb8e9)

![画像](https://github.com/spiritLHLS/ecs/assets/103393591/d25713e1-eeb0-48c0-9d6f-6ac1a0f6b6df)

![画像](https://github.com/spiritLHLS/ecs/assets/103393591/1b578739-4809-4ab0-8187-b860a502c8d9)

![画像](https://github.com/spiritLHLS/ecs/assets/103393591/010d4e5d-561e-4aa3-8313-e592f29405d1)

![画像](https://github.com/spiritLHLS/ecs/assets/103393591/bfe775ad-323c-4f6e-8d81-fcf787644653)

# Stargazers_over_time

[![Stargazers over time](https://starchart.cc/spiritLHLS/ecs.svg)](https://starchart.cc/spiritLHLS/ecs)

# 感謝

感謝 [ipinfo.io](https://ipinfo.io) [ip.sb](https://ip.sb) [cheervision.co](https://cheervision.co) [cip.cc](http://www.cip.cc) [scamalytics.com](https://scamalytics.com) [abuseipdb.com](https://www.abuseipdb.com/) [virustotal.com](https://www.virustotal.com/) [ip2location.com](ip2location.com/) [ip-api.com](https://ip-api.com) [ipregistry.co](https://ipregistry.co/) [ipdata.co](https://ipdata.co/) [ipgeolocation.io](https://ipgeolocation.io) [ipwhois.io](https://ipwhois.io) [ipapi.com](https://ipapi.com/) [ipapi.is](https://ipapi.is/) [ipqualityscore.com](https://www.ipqualityscore.com/) [bigdatacloud.com](https://www.bigdatacloud.com/) ~~[ipip.net](https://en.ipip.net)~~ ~~[abstractapi.com](https://abstractapi.com/)~~ などのサイトが提供するAPIを使用してテストを行い、インターネット上のさまざまなサイトが提供するクエリリソースに感謝します

すべてのオープンソースプロジェクトに感謝し、元のテストスクリプトを提供してくれたことに感謝します

感謝

<a href="https://h501.io/?from=69" target="_blank">
  <img src="https://github.com/spiritLHLS/ecs/assets/103393591/dfd47230-2747-4112-be69-b5636b34f07f" alt="h501">
</a>

このオープンソースプロジェクトをサポートするためにホスティングを提供してくれました

また、以下のプラットフォームに編集およびテストのサポートを提供してくれたことに感謝します

![PyCharm logo](https://resources.jetbrains.com/storage/products/company/brand/logos/PyCharm.png)

**[トップに戻る](https://github.com/spiritLHLS/ecs/blob/main/README_JP.md#top)**
