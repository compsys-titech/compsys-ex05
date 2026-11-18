# 計算機システム（演習）2026年度 第5回

目次

- [目的と今回の範囲](#purpose)
- [準備と確認環境](#setup)
- [取得と更新](#checkout)
- [ファイルと編集範囲](#files)
- [型・部品・関数の契約](#interfaces)
- [ALUの制御と依存関係](#control)
- [実行コマンド](#commands)
- [例題と実装の進め方](#examples)
- [公式テストと独自テスト](#tests)
- [結果とエラーの読み方](#results)
- [レポート・提出](#report)
- [困ったとき](#troubleshooting)
- [出典](#sources)

<a id="purpose"></a>
## 目的と今回の範囲

回路部品をC関数，内部配線を`Signal`変数，32本の配線を`Word`として表し，部品を接続して演算器を作ります．前段の出力を計算してから後段へ渡す呼出し順が，配線の依存関係に対応します．電圧・物理的伝播遅延・実機性能の測定は行いません．

第4回は命令を判定，第5回は計算する部品，第6回はレジスタ・メモリ，第7回はPC・デコード・制御と統合します．今回はA・Bの値と制御を直接入力し，AND／OR／ADD／SUBを行う32ビットALUまでを作ります．命令語をALUへ直接渡しません．

配布部品はAND・OR・NOT・MUX・Word変換・NAND接続例です．課題AはXOR・全加算器・RCA，課題Bは1ビットALU・32ビットALUです．NANDとMUXは新たな実装課題ではありません．SLT・シフト・乗除算・overflow/zeroフラグ，レジスタ・メモリ・プロセッサ全体は対象外です．

<a id="setup"></a>
## 準備と確認環境

必要なものはGit，GNU Make 3.81以降，C17対応の**ホスト用**Cコンパイラ，OS標準シェルです．ホストOSでコンパイル・リンクした実行ファイルをそのPC上で動かします．32ビットALUを模擬するために，実行ファイル自体を32ビット化する必要はありません．

第1・2回の`riscv-none-elf-gcc`，RARS・Java，QEMU・GDB，RISC-V用リンカスクリプトは使用しません．Python・Node.js・Docker・CMake・外部テストライブラリも不要です．

| 環境 | 状態 |
|---|---|
| macOS 27.2.1，Apple M4（arm64），Apple Clang 17.0.0，GNU Make 3.81 | ネイティブ実行を検証 |
| Debian GNU/Linux 13.6／x86_64，AMD EPYC 9V74，GCC 14.2.0，GNU Make 4.4.1 | 下記の範囲で検証済み。Clangは未導入のため未確認 |
| Windows x64 | TA確認待ち |
| 西8実習室 GNU/Linux | TA確認待ち |

Debian GNU/Linuxの上記環境では，C17のコンパイル・リンク・ネイティブ実行，配布版の正常ターゲットと未完成課題の想定非0，隔離した正解・有効な別解，機能誤実装16種，異常系，日本語・空白パス，読取り専用HOME，timeout，並行実行，GCCのASan＋UBSan，プロセス・ゾンビの後始末を確認しました．構成違反5種は数値テストの合格とソースの手動判定による不適合を区別しています．この結果は記載した環境の確認であり，GNU/Linux全般やClangでの動作確認を意味しません．

### macOS

既存のApple ClangとMakeを確認します．

```sh
git --version
make --version
xcode-select -p
clang --version
make check
```

通常は`/usr/bin/clang`（PATH上の`clang`）を使います．AppleのドライバーがSDKを選択します．`xcrun --find clang`で見つけた内部バイナリのパスへ置き換えると，SDKの選択条件が変わる場合があります．

Command Line ToolsやSDKが不足する場合は教員・TAに相談してください．バージョン表示だけでは環境確認になりません．`make check`がC17と標準ヘッダーを使う小さなプログラムを実際にコンパイル・リンク・実行します．

### Debian GNU/Linux

既存のネイティブGCCまたはClangとGNU Makeを使います．

```sh
cc --version
make --version
make check
make CC=gcc check
# Clangがある場合
make CC=clang check
```

不足ツールの導入は各環境の管理方針に従ってください．Debianでの独立検証は後続工程です．

### Windows x64（PowerShell）

ネイティブWindows向けMinGW-w64 GCCとGNU Makeを使用します．WSL，MSYS2シェル，Git Bashは必須ではありません．既にある第1回用GNU Makeは再利用できますが，xPackのRISC-V GCCはホスト用コンパイラにはなりません．

追加取得が必要な場合の固定候補は，公式[WinLibs](https://winlibs.com/)のWin64／UCRT／POSIX版です．

- tag: `16.2.0posix-23.1.3-14.0.0-ucrt-r3`
- [公式リリース](https://github.com/brechtsanders/winlibs_mingw/releases/tag/16.2.0posix-23.1.3-14.0.0-ucrt-r3)
- [ZIPを取得](https://github.com/brechtsanders/winlibs_mingw/releases/download/16.2.0posix-23.1.3-14.0.0-ucrt-r3/winlibs-x86_64-posix-seh-gcc-16.2.0-mingw-w64ucrt-14.0.0-r3.zip)
- ファイル名: `winlibs-x86_64-posix-seh-gcc-16.2.0-mingw-w64ucrt-14.0.0-r3.zip`
- [配布元のSHA-512](https://github.com/brechtsanders/winlibs_mingw/releases/download/16.2.0posix-23.1.3-14.0.0-ucrt-r3/winlibs-x86_64-posix-seh-gcc-16.2.0-mingw-w64ucrt-14.0.0-r3.zip.sha512)

公式SHA-512値（ZIP本体の自己計算値ではありません）：

```text
fdd7a649946bd0aaa50585b9902b91f58c9f7caa6de29901e46013b9f9f4187b8bc16dfb6beecadd12141f6417a044a54c63956bf34cdac97bcd5f724d100997
```

取得したZIPについて，PowerShellで次を実行し，上記公式値との一致を確認してから展開します．

```powershell
Get-FileHash -Algorithm SHA512 -LiteralPath "$HOME\Downloads\winlibs-x86_64-posix-seh-gcc-16.2.0-mingw-w64ucrt-14.0.0-r3.zip"
```

教材リポジトリ外のユーザー領域へ展開してください．例えば`$HOME\tools\winlibs-ex05\mingw64\bin`に実在する`gcc.exe`と`mingw32-make.exe`を使う場合：

```powershell
$compiler = Join-Path $HOME 'tools\winlibs-ex05\mingw64\bin\gcc.exe'
$makeExe = Join-Path $HOME 'tools\winlibs-ex05\mingw64\bin\mingw32-make.exe'
Test-Path -LiteralPath $compiler
Test-Path -LiteralPath $makeExe
& $compiler --version
& $makeExe --version
$env:CC = $compiler
& $makeExe check
& $makeExe examples
& $makeExe all
```

展開先に合わせてパスを変え，`Test-Path`が両方とも`True`になることを確認します．既存の`make.exe`を使う場合も，`$makeExe`へその実在するフルパスを設定します．恒久PATH変更は不要です．実行時DLLの探索には，runnerが当該PowerShellプロセス内だけでコンパイラのディレクトリをPATHへ追加します．実機での導入・実行確認はTA確認待ちです．

<a id="checkout"></a>
## 取得と更新

```sh
git clone https://github.com/compsys-titech/compsys-ex05.git
cd compsys-ex05
make
make check
make examples
make all
```

無引数`make`はhelpです．WindowsでMakeがPATHにない場合は，以下の`make`を`& $makeExe`に読み替えます．

更新前には`git status --short`と`git diff`で自分の変更を確認し，編集ファイルを別の場所へバックアップします．変更がないときは`git pull --ff-only`で更新できます．変更がある場合や更新が拒否された場合は，自分のコードを保持したままTAに相談してください．

<a id="files"></a>
## ファイルと編集範囲

| ファイル | 役割・編集 |
|---|---|
| [include/compsys.h](include/compsys.h) | 共通の型・公開API．変更不要 |
| [src/gates.c](src/gates.c)，[src/mux.c](src/mux.c)，[src/word.c](src/word.c) | 配布済み部品．変更不要 |
| [tasks/adder_task.c](tasks/adder_task.c) | 課題A．各TODO内を編集 |
| [tasks/alu_task.c](tasks/alu_task.c) | 課題B．各TODO内を編集 |
| [examples/gates_and_wires.c](examples/gates_and_wires.c) | 完成済み例題1 |
| [examples/observe_adder.c](examples/observe_adder.c) | 自分のFA・RCAを呼ぶ例題2 |
| [examples/observe_alu.c](examples/observe_alu.c) | 自分のALUを呼ぶ例題3 |
| [tests/student_cases.c](tests/student_cases.c) | **独自テストの編集場所．ファイル全体を編集可** |
| [tests/test_parts.c](tests/test_parts.c) | 配布部品の公式検査 |
| [tests/test_adder.c](tests/test_adder.c)，[tests/test_alu.c](tests/test_alu.c) | 課題A・Bの公式検査 |
| [tests/test_support.c](tests/test_support.c)，[tests/test_support.h](tests/test_support.h) | 入力準備・期待値・比較・表示 |
| [tests/test_main.c](tests/test_main.c) | 検査グループの入口 |
| `tests/*_task.original.c`，`tests/protected.fnv` | 未完成原本・配布ファイル照合情報．変更不要 |
| [Makefile](Makefile)，`tools/run.sh`，`tools/run.ps1` | OS別入口 |
| `tools/guard.c`，`tools/probe.c` | 実行監視・編集範囲検査・C17環境確認 |
| `build/run-*` | 毎回生成する実行ファイルとログ．Git管理対象外 |

境界は`/* TODO-BEGIN XOR */`と`/* TODO-END XOR */`のように一意です．課題Aは`A_HELPERS／XOR／FA／RCA`，課題Bは`B_HELPERS／ALU1／ALU32`です．補助関数はそれぞれの`HELPERS`領域へ置きます．関数宣言と境界外を維持してください．境界欠落・重複・署名変更・配布部品や公式テストの変更は`SOURCE`になります．LFとCRLFだけの違いは許容します．

<a id="interfaces"></a>
## 型・部品・関数の契約

```c
#include <stdbool.h>
#include <stdint.h>
typedef bool Signal;
typedef struct { Signal bit[32]; } Word;

void word_set_value(Word *w, uint32_t value);
uint32_t word_get_value(Word w);
void and_gate(Signal a, Signal b, Signal *out);
void or_gate(Signal a, Signal b, Signal *out);
void not_gate(Signal a, Signal *out);
void nand_example(Signal a, Signal b, Signal *out);
void mux2(Signal d0, Signal d1, Signal select, Signal *out);
void mux4(Signal d0, Signal d1, Signal d2, Signal d3,
          Signal s1, Signal s0, Signal *out);

void xor_circuit(Signal a, Signal b, Signal *out);
void full_adder(Signal a, Signal b, Signal cin, Signal *sum, Signal *cout);
void rca(Word a, Word b, Signal carry_in, Word *sum, Signal *carry_out);
void alu1(const Signal op[3], Signal a, Signal b, Signal cin,
          Signal *s, Signal *cout);
void alu32(const Signal op[3], Word a, Word b, Word *s);
```

`bit[0]`がLSB，`bit[31]`がMSBです．`Word`は論理的な32本の線であり，`sizeof(Word)==4`とは仮定しません．MUXのC関数名・引数順は今回確定したものです．スライドp.14に対応し，`mux2`は`select=0/1`で`d0/d1`，`mux4`は上位`s1`・下位`s0`で`d0/d1/d2/d3`を選択します．

ポインタには有効で互いに重ならない出力先を渡します．NULL対応は課題ではありません．各出力を毎回書き込み，前回の出力や`static`状態に依存させません．

課題の実装条件：

- XORはAND・OR・NOT，全加算器は基本ゲートと自作XOR等，RCAは全加算器32段で構成します．
- alu1は基本ゲート・FA・MUX等，alu32はalu1を32段つなぎます．
- 内部Signal，配列，ループ，添字計算，出力代入，同等なゲート接続の補助関数は使用できます．
- Wordを整数へ戻して直接演算，各ビットを算術式・比較式だけで計算，`^`・`!=`でXORを代用，`if/switch/?:`でMUXや回路接続を代用，入力別の答え一覧，テスト期待値関数の呼出しは禁止です．

入力準備・表示・テストの期待値では整数演算や分岐を使えます．回路本体とテストを区別してください．数値テストの合格だけでは回路構成の適合を証明できません．図とコードの対応は教員・TAが確認します．ループの`i++`，コメントなどを単純な文字列規則で禁止する検査は行いません．

<a id="control"></a>
## ALUの制御と依存関係

| 演算 | 表示`op[2:0]` | C配列`{op[0],op[1],op[2]}` |
|---|---|---|
| AND | 000 | `{false,false,false}` |
| OR | 001 | `{true,false,false}` |
| ADD | 010 | `{false,true,false}` |
| SUB | 110 | `{false,true,true}` |

`op[2]`はBinvert，`op[1]`・`op[0]`は結果選択です．これは教材内部の制御で，命令語のopcodeではありません．

alu1内でBとNOT(B)をNOT＋mux2，または自作XOR回路で切り替えます．AND・OR・FAの出力をmux4へ接続し，未使用の第4入力は`false`にします．`cout`は常にそのFAのキャリー出力です．AND/ORのCPUフラグではありません．alu1は受け取った`cin`をそのまま使用します．

alu32は全段へ同じopを渡し，最下位だけ`C0=op[2]`，以降は前段のCoutを次段のCinへ接続します．Bの反転は各alu1内で行い，外側で二重反転しません．C32は内部で受け，返すのは下位32ビットのWordです．RCAは独立した`carry_in`と`carry_out`を持ちます．

必須制御は表の4つだけです．未使用制御は新たな演算や採点対象にしません．Bの検査に必要なのはAのXORとFAです．**RCAだけが未完成・不合格でもBを検証できます**．

<a id="commands"></a>
## 実行コマンド

| コマンド | 内容 | 未完成配布版 |
|---|---|---|
| `make` / `make help` | ヘルプ．コンパイラ不要 | 0 |
| `make check` | C17のcompile・link・run | 0 |
| `make examples` | 配布部品を実行・照合する例題1 | 0 |
| `make all` | 環境・配布部品の検査と課題・全ドライバーのビルド | 0 |
| `make test-a` | XOR・FA・RCA | 未完成による非0 |
| `make test-b` | XOR・FAを確認しALU1・ALU32 | 未完成による非0 |
| `make test` | A・B双方を報告 | 未完成による非0 |
| `make example-adder` | 自作FA・RCAの観察 | 未完成による非0 |
| `make example-alu` | 自作ALU32の観察 | 未完成による非0 |
| `make test-student` | 下位部品確認後，独自テストA/Bを別々に実行 | 未完成による非0 |
| `make clean` | 生成したrun領域を削除．コンパイラ不要 | 0 |

`all`は課題の合格宣言ではありません．未完成スタブは出力を初期化したうえで部品名を表示し終了します．表示や`exit(3)`を消しただけでは，実値の検査に合格しません．

コンパイラを明示できます．`CC`は引数を含めない**1つの実行ファイルパス**です．明示したCCが不正な場合，他へ切り替えません．Make組込みの`CC=cc`は既定値として扱い，macOSは`clang`，GNU/Linuxは`cc`，Windowsは`gcc`を選びます．

```sh
make CC=clang test
make CC="/path with spaces/clang" check
make CFLAGS="-O2" test
```

常に`-std=c17 -Wall -Wextra -Wpedantic`を付け，CFLAGSの既定は観察用の`-O0 -g`です．`-O2`は最適化の影響の比較に使います．CFLAGS/LDFLAGSは空白区切りの引数として扱い，シェル構文を再評価しません．引用符を含む複雑な1引数，コンパイラパスをCFLAGSへ混ぜる指定はサポートしません．

<a id="examples"></a>
## 例題と実装の進め方

1. `make check`で環境，`make examples`でAND・OR・NOT・NAND・MUX・Wordを確認します．NANDの`inner`から出力先への接続は`src/gates.c`で読めます．
2. 課題AのXOR，FA，RCAを順に実装し，`make test-a`を実行します．
3. `make example-adder`でFAの全8通りとスライドp.25のRCA6例を観察します．期待値・自分の実出力・carryを区別して読みます．
4. 課題Bのalu1・alu32を実装し，`make test-b`，`make example-alu`を実行します．5と3の4演算，0と1の境界例を自分の回路で確かめます．
5. 独自テストを増やし，`make test-student`と`make test`の記録を保存します．

例題2・3は学生の関数を呼ぶ観察用ドライバーです．完成した加算器・ALUの代替実装は含みません．実装前に出た期待値を実測値として扱わないでください．

<a id="tests"></a>
## 公式テストと独自テスト

| 検査 | 入力組・検査内容 | 合格時の比較件数 |
|---|---|---:|
| 配布部品 | AND4・OR4・NOT2・NAND4・MUX2は8・MUX4は64．Word38値の独立set/getと往復 | 362 |
| XOR | 全4入力 | 8 |
| FA | 全8入力，SumとCout | 16 |
| RCA | 268入力組（6例・入替6・各桁/キャリー128・固定seed128） | 536 |
| alu1 | 4制御×8入力，sとFAのcout | 64 |
| alu32 | 820入力組（境界52・各桁/キャリー256・固定seed512） | 1640 |

同じ入力をfalse/trueの出力初期値で再度与え，途中に別入力を挟みます．1行は両出力を含む1回の比較です．32ビット入力全体を網羅した検査ではありません．全公式グループ合格時は2626比較で，`test-b`はRCAを含めず2090比較です．依存不良で省略したグループは0件です．

Wordはbitごとに照合します．RCAの期待値は演算前に`uint64_t`へ拡張して計算します．ADD/SUBの期待値は32ビット剰余演算で，「負数」も32ビットのビット列で比較します．表示は8桁16進です．

乱数入力はOSの`rand()`を使いません．`x=(1664525*x+1013904223) mod 2^32`で，RCA seedは`0x202605a1`，ALU32は`0x202605b2`です．それぞれ128組のA/Bを順に生成し，ALU32は各組を4制御で調べます．RCAのCinはケース番号の偶奇で交互です．IDと入力は毎回再現します．

独自テストは`tests/student_cases.c`へ追加し，`make test-student`で実行します．小さな初期例はRCA2入力（4比較），ALU32の1入力組（2比較）です．`case_rca("独自ID",A,B,Cin)`，`case_alu32("独自ID",control,A,B)`等を追加してください．この補助関数の`control`番号は`0=AND,1=OR,2=ADD,3=SUB`で，opビット配列そのものではありません．`test_ops`に対応表があります．

各ケースの前に`puts("REASON ...")`等で選定理由を書けます．入力・期待値・実値・合否は補助関数が学生実装を呼んで表示します．中間信号を観察するときも自分の関数・変数の値を読み，期待値モデルの途中値と混同しないでください．配布済みの数例だけでレポート完成とはなりません．

<a id="results"></a>
## 結果とエラーの読み方

`[PASS] / [FAIL]`の行には安定したID・入力・制御・期待値・実値が出ます．末尾の`RESULT グループ PASS cases=... failures=0`まで確認してください．終了0だけで最終結果が欠けた実行は合格にしません．

| 分類 | 意味 | runner終了値 |
|---|---|---:|
| ENV | コンパイラ不足，C17/SDK不良，ホストで実行不能 | 2 |
| UNFINISHED | 未実装スタブが呼ばれた | 3 |
| BUILD | 課題等のコンパイル・リンク失敗 | 4 |
| FAIL | 実値と期待値の不一致 | 5 |
| TIMEOUT | 実時間上限 | 6 |
| RUNTIME | 異常終了，出力過多，最終報告欠落，シグナル | 7 |
| SOURCE | 編集範囲・配布物の変更 | 8 |
| DEPENDENCY / 集約非0 | 必要部品不良，またはグループの非0を含む | 9 |

`test-a/b/test/test-student`の集約値9では，`SUMMARY`と各グループの値・診断を読んで原因を判定します．下位不良でBを実行できなかった状態はB固有の論理不良と断定しません．未変更のスタブ領域はsource確認時にも部品別に表示します．

GNU Makeはレシピの非0を通常2として返します．末尾の`Error 9`等がrunnerの値です．直接確認する場合はmacOS/Linuxで`sh tools/run.sh test; echo $?`，Windowsでは`powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/run.ps1 test`の後に`$LASTEXITCODE`を確認します．

各実行は`build/run-*`へ新規生成し，設定，コンパイラ情報，起動引数，PID，実行時間，終了値，標準出力・標準エラーを保存します．前回のバイナリ・PASSログは再利用しません．学生プログラム1実行は既定20秒・合計1MiB，コンパイルは別に120秒で監視します．`EX05_RUN_TIMEOUT`，`EX05_BUILD_TIMEOUT`，`EX05_OUTPUT_LIMIT`で正の整数を指定できます（出力は1024以上，監視時間3600以下，出力64MiB以下）．

タイムアウト・中断では今回のプロセスグループ（WindowsはJob Object）を終了・回収します．悪意ある任意Cプログラムに対する完全なセキュリティサンドボックスではありません．編集範囲の照合も，回路構成や意図的な検査改変を完全に証明するものではありません．

独立した2実行や`make -j2 all`は別run領域で動きます．実行中の`make clean`は行わないでください．cleanは`build/run-*`だけを削除し，学生ファイルを保持します．build自体がシンボリックリンク等なら停止します．記録を残したいログはclean前に別の場所へ保存してください．

<a id="report"></a>
## レポート・提出

指定部品の接続，全出力と境界値の検証，図・コード・実結果の対応，期待値と実測の区別を確認します．数値テスト合格は成績・満点を保証しません．

- XOR4通りとFA8通りの実結果．
- FAの図または論理式，内部信号とコードの対応．
- RCAのキャリー伝播図．4ビット抜粋による説明は可能ですが，実装・検査は32ビットです．
- ALUのAND・OR・FA・MUX・Binvertの部品接続図と自分の関数・配線・制御値．
- SUBのB反転，C0=1，結果のビット列を，自分で選んだ入力で説明．
- 入力・Cin/制御・期待値・実値・合否・選定理由の表，不一致があれば理由．図番号を本文から参照．

スクリーンショットは任意です．テキストや結果表で実出力を記録できます．

提出名は`学籍番号_ex05_code.zip`と`学籍番号_ex05_report.pdf`．提出先・締切はScience Tokyo LMSで通知します．Word雛形・正式記入ガイド・ZIPの正式な内容は後続の資料で案内します．現時点の編集対象は課題2ファイルと`tests/student_cases.c`です．

<a id="troubleshooting"></a>
## 困ったとき

- **UNFINISHED**：課題の実装が必要です．`check/examples/all`の成功とは別です．
- **ENV**：`CC`のパス，ホスト用コンパイラか，SDK/標準ヘッダー，実行時DLLを確認し，`make check`をやり直します．既存ツールの削除や無断の設定変更は不要です．
- **BUILD**：最初のコンパイラ/リンカー診断を読み，宣言，変数，出力先，未定義関数を確認します．古い成功実行ファイルへは戻りません．
- **SOURCE**：境界名・署名・配布ファイルを確認します．自分のコードをバックアップし，公式配布との差分をTAへ示してください．
- **FAIL**：最初のIDの入力・期待値・実値を追います．LSBからの順序，毎回の出力設定，FAの両出力，opの添字，SUBのC0と二重反転を確認します．
- **DEPENDENCY**：まず必要な下位部品を直します．RCAだけの不具合なら`test-b`を実行できます．
- **TIMEOUT/RUNTIME**：無限ループ，範囲外アクセス，異常終了，大量出力を確認します．最終RESULTのないログを成功と扱わないでください．

質問時はOS・CPU，CCの実パスと`--version`，Makeの版，実行コマンド，終了値，最初の診断，対応ログを示してください．

<a id="sources"></a>
## 出典

授業資料`Compsys2026_ex05.pptx`（全38枚）を仕様の基点とします．2025年度第5・6回資料は教育意図の参考とし，型・課題分担・APIは2026年度に合わせています．

運用構成は[第4回教材](https://github.com/compsys-titech/compsys-ex04/tree/b2e60f510c526c5f778611ddd925c877394dc1ce)を参考にしました．Windows配布候補は[WinLibs公式](https://winlibs.com/)です．ツール本体・Office資料・完成解答・内部検証記録は本リポジトリに含めません．
