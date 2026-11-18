# 第5回教材の保守

正本は教員が保存済みの2026年度第5回PowerPoint全38枚．本リポジトリはC17による組合せ回路の教材．Signalはbool，WordはSignal[32]，bit0がLSB．旧年度の型・APIへ戻さない．

## 公開境界

公開するのは配布ゲート・MUX・Word変換・NAND例，未完成課題，観察ドライバー，数値テスト，runner，説明文書，report/の記入ガイドと空欄Word雛形．課題の完成解答・別解・誤実装・解答生成スクリプト・内部証跡・PowerPoint・PDF・教員TA用Excel・ツール本体を公開しない．別名関数・バイナリ・fallbackへ解答を隠すことも禁止．正解は公開作業ツリー外の隔離コピーだけで検証する．期待値を実測結果と表示しない．

## 教育条件

- AはXOR，full_adder，rca．Bはalu1，alu32とSUB対応．MUX・NANDを学生課題に増やさない．第6/7回機能・フラグ・未使用制御の仕様を追加しない．
- XORは基本ゲート，FAは基本ゲートとXOR等，RCAはFA32段，alu1はゲート・FA・MUX，alu32はalu1を32段．Word整数化・直接演算・比較式によるビット演算・Cの^/!=でのXOR・分岐によるMUX代用・答え一覧・期待値関数呼出しは禁止．ループ・添字・等価な接続補助は可．
- op[2:0]=000/001/010/110とCの配列順を区別．alu1でBを条件反転，coutはFAの出力．alu32のC0=op[2]，C32は内部のみ．RCAは独立Cin/Cout．
- 出力は毎回代入．NULL/alias対応を新課題にしない．未完成はコンパイル可能で，部品名と非0を返す．
- TODO外・公式テスト・配布部品は保護．独自テストはtests/student_cases.c．CRLFは許容．

## 検査・運用

READMEの全ターゲットを維持．help/cleanはコンパイラ不要．checkはホストC17のcompile/link/run，allは課題合格を要求しない．testはA不良でもBの状態を報告．Bの依存はXOR/FAでありRCA全体の合格を条件にしない．skipを合格件数へ含めない．

機能・境界値・固定seed・再呼出し・有効なbool番兵を検査．Word変換を独立照合．uint64_tによるRCA期待値，uint32_t剰余，inttypes書式を使用．signed overflowや幅以上のshiftに依存しない．

機能合格と回路構成の適合は別．任意Cの構造を自動証明したと主張しない．コメント・添字・i++まで弾く文字列検査を加えない．教員TAが図・コード・実測の対応を確認する．

毎回別runへ再生成し，時間・出力を制限．対象PID/group/jobのみ後始末．cleanを通常ビルドへ混ぜない．symlink/reparse先を削除しない．悪意あるCの完全なsandboxとは説明しない．

runner変更後は配布版，隔離正解，等価別解，機能誤実装，異常系，日本語・空白パス，並行実行，シグナル終了を確認．O0/O2と利用可能なSanitizerを比較．OSの未確認状態を保持し，macOSだけの実測でLinux/Windows全般を保証しない．

公開前は明示したパスをstageして全文確認．完成解答を一度commitして戻す方法は禁止．通常pushのみ．公開Wordは空欄雛形だけとし，完成解答・内部配点を含めない．PowerPoint・PDF・教員TA用Excelは公開リポジトリ外で管理し，LMS・他回教材を変更しない．締切はScience Tokyo LMSで通知し，具体的な日付・遅延減点率・新ライセンスを決めない．

正式提出は学籍番号_ex05_code.zipと学籍番号_ex05_report.pdf．ZIP直下はtasks/adder_task.c，tasks/alu_task.c，tests/student_cases.cだけ．正式ガイド・Word・README間の提出仕様を一致させ，スクリーンショットを必須化しない．
