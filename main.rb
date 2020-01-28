require "dxopal"
require "dxruby"
require "csv"
include DXOpal

font = Font.new(48)
font_1 = Font.new(32)
wazafont = Font.new(24)

$wazawaza = 0
$times = 1

#Font.install("pkmn_s.ttf")
pkmn = Font.new(32, font_name = "PKMN Strict")
pkmn_name = Font.new(18, font_name = "PKMN Strict")
pkmn_vocabrary = Font.new(12, font_name = "PKMN Strict")
pkmn_lib = Font.new(48, font_name = "PKMN Strict")
GROUND_Y = 400
Image.register(:player, "images/uda.png")
# アイテム用の画像を宣言
Image.register(:apple, "images/book.png")
Image.register(:bomb, "images/bomb.png")
Image.register(:background, "images/background.png")
Image.register(:school, "images/gakkou.png")
Image.register(:tsukuba, "images/tsukuba.png")
Image.register(:sentou, "images/sentou.png")
Image.register(:akagi, "images/nagata1.png")
Image.register(:black, "images/black.png")
Image.register(:title_logo, "images/touitsu.png")
Image.register(:toshimori, "images/toshimori.png")

# 読み込みたい音声を登録する
Sound.register(:get, "sounds/get.wav")
Sound.register(:explosion, "sounds/explosion.wav")

$kougeki = 10

waza = ["ISBN", "インターネット", "HTML", "SQL", "絵本", "重みづけ",
        "クエリ", "コレクション", "コンテンツ", "索引", "書架", "JKJ",
        "資料", "著作権", "ツイッター", "データベース", "テキスト", "読書", "本",
        "ビックデータ", "ビブリオ", "標目表", "プロ演", "プロトコル", "ブラウザ",
        "マークアップ", "メディア", "目録", "モジュール", "ユニオン", "読み聞かせ",
        "リポジトリ", "アーカイブズ", "Atom", "アプリケーション", "インターフェース",
        "引用文献", "webAPI", "エンコーディング", "オープンアクセス", "OPAC",
        "重みづけ", "機械学習", "記録遺産", "コミュニケーション",
        "参考図書", "シソーラス",
        "情報サービス", "情報探索", "ソーシャルメディア", "ソフトウェア",
        "対話システム", "大学図書館", "地域資料", "知識資源", "Tulips",
        "データサイエンス", "データ分析", "テキスト処理",
        "分類記号", "マイクロ資料", "レファレンス",
        "学術情報流通", "学校図書館",
        "ガマジャンパー", "検索エンジン", "公共図書館", "国立国会図書館",
        "CiNii", "情報リテラシー", "シンデレラ階段",
        "請求番号", "逐次刊行物", "知的財産権",
        "電子図書館", "図書館情報学", "トランザクション", "Python", "ハッシュタグ",
        "ビブリオバトル", "インタラクティブ", "ウェブプログラミング",
        "学術情報流通システム", "クラウドコンピューティング",
        "情報行動モデル", "テクニカルコミュニケーション", "ディジタルドキュメント",
        "ディジタルライブラリ", "図書館情報学を学ぶ人のために",
        "レファレンス共同サービス", "プログラミング演習", "知識情報・図書館学類",
        "サイエンスコミュニケーション", "ヒューマンインターフェース",
        "情報基礎実習"]

GAME_INFO = {
  scene: :opening, #現在のシーン　起動直後は:title
  score: 0, #現在のスコア
}

# プレイヤーを表すクラスを定義
class Player < Sprite
  def initialize
    x = Window.width / 2
    y = GROUND_Y - Image[:player].height
    image = Image[:player]
    super(x, y, image)
    # 当たり判定を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 16]
  end

  # 移動処理(xからself.xになった)
  def update
    if Input.key_down?(K_LEFT) && self.x > 0
      self.x -= 6
    elsif Input.key_down?(K_RIGHT) && self.x < (Window.width - Image[:player].width)
      self.x += 6
    end
  end
end

# クラスここまで

# アイテムを表すクラスを追加
class Item < Sprite
  # imageを引数にとるようにした
  def initialize(image)
    x = rand(Window.width - image.width)
    y = 0
    super(x, y, image)
    @speed_y = rand(4) + 2
  end

  def update
    self.y += @speed_y
    if self.y > Window.height
      self.vanish
    end
  end
end

# 加点アイテムのクラスを追加
class Apple < Item
  def initialize
    super(Image[:apple])
    # 衝突範囲を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 45]
  end

  # playerと衝突したとき呼ばれるメソッドを追加
  def hit
    #効果音
    Sound[:get].play
    self.vanish
    GAME_INFO[:score] += rand(50) + 50
  end
end

# 妨害アイテムのクラスを追加
class Bomb < Item
  def initialize
    super(Image[:bomb])
    # 衝突範囲を円で設定(中心x, 中心y, 半径)
    self.collision = [image.width / 2, image.height / 2, 42]
  end

  # playerと衝突したとき呼ばれるメソッドを追加
  def hit
    # 効果音
    Sound[:explosion].play
    self.vanish
    GAME_INFO[:score] += 0
    GAME_INFO[:temporary] = GAME_INFO[:score]
    GAME_INFO[:scene] = :game_over # :game_overに移動
  end
end

# アイテム群を管理するクラスを追加
class Items
  # 同時に出現するアイテムの個数
  N = 5

  def initialize
    @items = []
  end

  # playerを引数に取るようにした
  def update(player)
    @items.each { |x| x.update(player) }
    # playerとitemsが衝突しているかチェックする。衝突していたらhitメソッドが呼ばれる
    Sprite.check(player, @items)
    Sprite.clean(@items)

    (N - @items.size).times do
      # どっちのアイテムにするか、ランダムで決める
      if rand(1..100) < 70
        @items.push(Apple.new)
      else
        @items.push(Bomb.new)
      end
    end
  end

  def draw
    # 各スプライトのdrawメソッドを呼ぶ
    Sprite.draw(@items)
  end
end

# クラスここまで

wazanum = (0..94).to_a.sample(4)

Window.load_resources do
  player = Player.new
  # Itemsクラスのオブジェクトを作る
  items = Items.new
  $hitpoint1 = 250000
  GAME_INFO[:highscore] = 0
  GAME_INFO[:atack] = 0
  Window.loop do
    Window.draw(0, 0, Image[:background])
    player.update

    #シーンごとの処理
    case GAME_INFO[:scene]
    when :opening
      Window.draw(0, 0, Image[:black])
      Window.draw_font(50, 50, "そうさせつめいね", pkmn)
      Window.draw_font(50, 100, "ENTERで「つぎへ」みたいな。", pkmn)
      Window.draw_font(50, 150, "ESCでタイトルにもどる。", pkmn)
      Window.draw_font(50, 200, "いくせいもーどは", pkmn)
      Window.draw_font(50, 250, "やじるしでそうさするよ。", pkmn)
      Window.draw_font(50, 300, "バグがあったら", pkmn)
      Window.draw_font(50, 350, "ごめんなさい。。。", pkmn)

      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening1
      end
    when :opening1
      Window.draw(0, 0, Image[:black])
      #   Window.draw(0, 0, Image[:title_logo])
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening2
      end
    when :opening2
      Window.draw(0, 0, Image[:black])
      Window.draw_font(50, 50, "筑波大学、春日エリア7A-505.", font_1)
      Window.draw_font(50, 100, "そこには、図書館情報大学の復活を", font_1)
      Window.draw_font(50, 150, "目論む一派が存在していた.", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening3
      end
    when :opening3
      Window.draw(0, 0, Image[:black])
      Window.draw_font(50, 50, "筑波大学、春日エリア7A-505.", font_1)
      Window.draw_font(50, 100, "そこには、図書館情報大学の復活を", font_1)
      Window.draw_font(50, 150, "目論む一派が存在していた.", font_1)
      Window.draw_font(50, 200, "彼らは図書館学第五禁止法則を犯し、", font_1)
      Window.draw_font(50, 250, "秘密裏に研究を進め、禁忌とされる", font_1)
      Window.draw_font(50, 300, "図書内有機生命体を生み出していた.", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening4
      end
    when :opening4
      Window.draw(0, 0, Image[:black])
      Window.draw_font(50, 50, "筑波大学、春日エリア7A-505.", font_1)
      Window.draw_font(50, 100, "そこには、図書館情報大学の復活を", font_1)
      Window.draw_font(50, 150, "目論む一派が存在していた.", font_1)
      Window.draw_font(50, 200, "彼らは図書館学第五禁止法則を犯し、", font_1)
      Window.draw_font(50, 250, "秘密裏に研究を進め、禁忌とされる", font_1)
      Window.draw_font(50, 300, "図書内有機生命体を生み出していた.", font_1)
      Window.draw_font(50, 350, "それを使役する唯一の存在として、", font_1)
      Window.draw_font(50, 400, "君に白羽の矢が立てられた・・・.", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening5
      end
    when :opening5
      Window.draw(0, 0, Image[:black])
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening6
      end
    when :opening6
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw_font(50, 50, "[7A-505 教室内]", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening7
      end
    when :opening7
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw_font(50, 50, "[7A-505 教室内]", font_1)
      Window.draw_font(45, 340, "「・・・・・・・・・・・フフフ", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening8
      end
    when :opening8
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw_font(50, 50, "[7A-505 教室内]", font_1)
      Window.draw_font(45, 340, "あっ 初めまして！", font_1)
      Window.draw_font(45, 390, "図書館情報学の 世界へ ようこそ！", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening9
      end
    when :opening9
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw_font(50, 50, "[7A-505 教室内]", font_1)
      Window.draw_font(45, 340, "私の名前は トシモリ みんなからは", font_1)
      Window.draw_font(45, 390, "図書館情報学 博士と 慕われています", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening10
      end
    when :opening10
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw(200, 200, Image[:player])
      #   Window.draw(190, 200, Image[:teacher1])
      #  Window.draw(210, 200, Image[:teacher2])
      Window.draw_font(50, 50, "[7A-505 教室内]", font_1)
      Window.draw_font(45, 340, "この 世界には ライブラリーモンスター", font_1)
      Window.draw_font(45, 390, "縮めて ラリモン と 呼ばれる", font_1)
      Window.draw_font(45, 440, "生き物たちが 至る所に 住んでいる！", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening11
      end
    when :opening11
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw(200, 200, Image[:player])
      Window.draw_font(50, 50, "[7A-505 教室内]", font_1)
      Window.draw_font(45, 340, "その ラリモン という 生き物に", font_1)
      Window.draw_font(45, 390, "人は 論文を 書かせたり 学会に", font_1)
      Window.draw_font(45, 440, "出させたり 論破 しあっている・・・", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening12
      end
    when :opening12
      Window.draw(0, 0, Image[:black])
      Window.draw(200, 200, Image[:player])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw_font(50, 50, "[7A-505 教室内]", font_1)
      Window.draw_font(45, 340, "そして… 私はこの ラリモンの 研究を", font_1)
      Window.draw_font(45, 390, "している　という訳です", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening14
      end
    when :opening14
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw(200, 200, Image[:player])
      Window.draw_font(50, 50, "[7A-505 教室内]", font_1)
      Window.draw_font(45, 340, "これから 君だけの 物語が", font_1)
      Window.draw_font(45, 390, "始まろうと している！", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening15
      end
    when :opening15
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw(200, 200, Image[:player])
      Window.draw_font(50, 50, "[7A-505 教室内]", font_1)
      Window.draw_font(45, 340, "未来と 想像と 緑に 満ちた", font_1)
      Window.draw_font(45, 390, "図書館情報学の 世界へ 勇気を持って", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening16
      end
    when :opening16
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw(200, 200, Image[:player])
      Window.draw_font(50, 50, "[7A-505 教室内]", font_1)
      Window.draw_font(45, 340, "飛び込んで　みてくれ！」", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :opening17
      end
    when :opening17
      Window.draw(0, 0, Image[:black])
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :title
      end
    when :title
      #タイトル画面
      Window.draw(0, 0, Image[:tsukuba])
      Window.draw_font(80, 60, "つくばだいがくとういつけいかく", pkmn, :color => [255, 0, 0])
      Window.draw_font(30, 200, "いくせいもーど : PRESS 1", pkmn, :color => [0, 255, 255])
      Window.draw_font(30, 250, "ばとるもーど : PRESS 2", pkmn, :color => [0, 255, 255])
      Window.draw_font(30, 300, "HIGHSCORE : #{GAME_INFO[:highscore]}", pkmn, :color => [0, 255, 255])

      # エンたーキーが押されたらシーンを変える
      if Input.key_push?(K_1)
        GAME_INFO[:score] = 0
        GAME_INFO[:scene] = :playing
      elsif Input.key_push?(K_2)
        GAME_INFO[:scene] = :battle
      end
    when :playing
      #ゲーム中
      if Input.key_push?(K_ESCAPE)
        GAME_INFO[:scene] = :title
      end
      player.update
      #  アイテムの作成・移動・削除
      Window.draw_font(0, 0, "SCORE: #{GAME_INFO[:score]}", font_1)
      Window.draw_font(0, 50, "HICHSCORE: #{GAME_INFO[:highscore]}", font_1)
      player.update
      items.update(player)

      player.draw
      items.draw
    when :game_over
      #ゲームオーバー

      Window.draw_font(170, 200, "GAME OVER", pkmn, :color => [255, 0, 0])
      if GAME_INFO[:temporary] >= GAME_INFO[:highscore]
        GAME_INFO[:highscore] = GAME_INFO[:temporary]
      end

      Window.draw_font(90, 250, "HIGHSCORE : #{GAME_INFO[:highscore]}", pkmn, :color => [255, 0, 0])
      # エンターキーが押されたらゲームの状態をリセットし、シーンを変える
      if Input.key_push?(K_ENTER)
        player = Player.new
        items = Items.new

        GAME_INFO[:score] = 0
        GAME_INFO[:scene] = :title
      end
    when :battle

      #スコア、ボキャブラリー変換　
      GAME_INFO[:vocabrary] = GAME_INFO[:highscore] ** 1.2
      #GAME_INFO[:vocabrary] = 50000
      #戦闘フェーズ
      if Input.key_push?(K_ESCAPE)
        GAME_INFO[:scene] = :title
      end
      Window.draw(0, 0, Image[:school])
      Window.draw_font(80, 60, "LIBRARY", pkmn_lib)
      Window.draw_font(220, 120, "MONSTER", pkmn_lib)
      Window.draw_font(150, 270, "PRESS ENTER", pkmn, :color => [255, 255, 0])
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :sentou1
      end
    when :sentou1
      Window.draw(0, 0, Image[:sentou])
      Window.draw(400, 0, Image[:akagi])
      Window.draw_font(520, 295, "#{GAME_INFO[:vocabrary].floor}", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(550, 245, "00", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(430, 295, "ごいりょく", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(45, 370, "あ、", pkmn)
      Window.draw_font(100, 370, "がくちょう", pkmn)
      Window.draw_font(270, 370, "の", pkmn)
      Window.draw_font(320, 370, "NGT", pkmn)
      Window.draw_font(45, 425, "が、しょうぶをしかけてきた！", pkmn)
      Window.draw_font(80, 67, "NGT", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(230, 73, "??", pkmn_name, :color => [0, 0, 0])
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :sentou2
      end
      if Input.key_push?(K_ESCAPE)
        GAME_INFO[:scene] = :title
      end
    when :sentou2
      Window.draw(0, 0, Image[:sentou])
      Window.draw(400, 0, Image[:akagi])
      Window.draw_font(550, 245, "00", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(430, 295, "ごいりょく", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(520, 295, "#{GAME_INFO[:vocabrary].floor}", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(80, 67, "NGT", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(45, 370, "きみは、どうする？", pkmn)
      Window.draw_font(45, 425, "こうげきは、あと", pkmn)
      Window.draw_font(310, 425, $kougeki, pkmn)
      Window.draw_font(385, 425, "かいだ！", pkmn)
      Window.draw_font(230, 73, "??", pkmn_name, :color => [0, 0, 0])

      if Input.key_push?(K_ENTER)
        $kougeki = $kougeki - 1
        GAME_INFO[:scene] = :sentou3
      end
      if Input.key_push?(K_ESCAPE)
        GAME_INFO[:scene] = :title
      end
    when :sentou3
      Window.draw(0, 0, Image[:sentou])
      Window.draw(400, 0, Image[:akagi])
      Window.draw_font(550, 245, "00", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(430, 295, "ごいりょく", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(520, 295, "#{GAME_INFO[:vocabrary].floor}", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(80, 67, "NGT", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(230, 73, "??", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(40, 370, "1:", pkmn_name)
      Window.draw_font(315, 370, "2:", pkmn_name)
      Window.draw_font(40, 425, "3:", pkmn_name)
      Window.draw_font(315, 425, "4:", pkmn_name)
      Window.draw_font(75, 370, waza[wazanum[0]], pkmn_name)
      Window.draw_font(345, 370, waza[wazanum[1]], pkmn_name)
      Window.draw_font(75, 425, waza[wazanum[2]], pkmn_name)
      Window.draw_font(345, 425, waza[wazanum[3]], pkmn_name)

      if Input.key_push?(K_1)
        $wazawaza = wazanum[0]
        GAME_INFO[:scene] = :sentou4
      elsif Input.key_push?(K_2)
        $wazawaza = wazanum[1]
        GAME_INFO[:scene] = :sentou4
      elsif Input.key_push?(K_3)
        $wazawaza = wazanum[2]
        GAME_INFO[:scene] = :sentou4
      elsif Input.key_push?(K_4)
        $wazawaza = wazanum[3]
        GAME_INFO[:scene] = :sentou4
      elsif Input.key_push?(K_ESCAPE)
        GAME_INFO[:scene] = :title
      end
    when :sentou4
      if $wazawaza >= 0 && $wazawaza <= 24
        $bairitsu = 0.5
        $cost = 100
      elsif $wazawaza >= 25 && $wazawaza <= 49
        $bairitsu = 0.75
        $cost = 150
      elsif $wazawaza >= 50 && $wazawaza <= 74
        $bairitsu = 1
        cost = 200
      elsif $wazawaza >= 75 && $wazawaza <= 94
        $bairitsu = 1.25
        $cost = 300
      end

      GAME_INFO[:atack] = GAME_INFO[:vocabrary] * $bairitsu

      Window.draw(0, 0, Image[:sentou])
      Window.draw(400, 0, Image[:akagi])
      Window.draw_font(550, 245, "00", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(430, 295, "ごいりょく", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(520, 295, "#{GAME_INFO[:vocabrary].floor}", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(80, 67, "NGT", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(45, 370, "NGT", pkmn)
      Window.draw_font(180, 370, "に", pkmn)
      Window.draw_font(230, 370, "#{GAME_INFO[:atack].floor}", pkmn)
      Window.draw_font(45, 425, "のダメージ！！！", pkmn)
      Window.draw_font(0, 0, $hitpoint1, pkmn)
      Window.draw_font(0, 50, $bairitsu, pkmn)
      Window.draw_font(230, 73, "??", pkmn_name, :color => [0, 0, 0])

      if Input.key_push?(K_ENTER)
        $hitpoint1 = $hitpoint1 - GAME_INFO[:atack].floor
        wazanum = (0..94).to_a.sample(4)
        GAME_INFO[:scene] = :keisan
      end
      if Input.key_push?(K_ESCAPE)
        $times = 0
        GAME_INFO[:scene] = :title
      end
    when :keisan
      Window.draw(0, 0, Image[:sentou])
      Window.draw(400, 0, Image[:akagi])
      Window.draw_font(550, 245, "00", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(430, 295, "ごいりょく", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(230, 73, "??", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(520, 295, "#{GAME_INFO[:vocabrary].floor}", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(80, 67, "NGT", pkmn_name, :color => [0, 0, 0])
      if $hitpoint1 <= 0
        GAME_INFO[:scene] = :win1
      elsif $kougeki == 0
        GAME_INFO[:scene] = :lose1
      elsif $hitpoint != 0
        GAME_INFO[:scene] = :sentou2
      end
    when :win1
      Window.draw(0, 0, Image[:sentou])
      Window.draw(400, 0, Image[:akagi])
      Window.draw_font(550, 245, "00", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(430, 295, "ごいりょく", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(230, 73, "??", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(520, 295, "#{GAME_INFO[:vocabrary].floor}", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(80, 67, "NGT", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(45, 370, "IMAGINE THE", pkmn)
      Window.draw_font(45, 425, "        FUTURE.", pkmn)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :win2
      end
    when :win2
      Window.draw(0, 0, Image[:sentou])
      # Window.draw(400, 0, Image[:akagi])
      Window.draw_font(550, 245, "00", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(430, 295, "ごいりょく", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(230, 73, "??", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(520, 295, "#{GAME_INFO[:vocabrary].floor}", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(80, 67, "NGT", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(45, 370, "NGTは倒れた！！", pkmn)
      #Window.draw_font(45, 425, "", pkmn)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :win3
      end
    when :win3
      Window.draw(0, 0, Image[:sentou])
      # Window.draw(400, 0, Image[:akagi])
      Window.draw_font(550, 245, "00", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(430, 295, "ごいりょく", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(230, 73, "??", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(520, 295, "#{GAME_INFO[:vocabrary].floor}", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(80, 67, "NGT", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(45, 370, "倒した！！！", pkmn)
      Window.draw_font(45, 425, "やったね！！！", pkmn)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending
      end
    when :lose1
      Window.draw(0, 0, Image[:sentou])
      Window.draw(400, 0, Image[:akagi])
      Window.draw_font(550, 245, "00", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(430, 295, "ごいりょく", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(230, 73, "??", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(520, 295, "#{GAME_INFO[:vocabrary].floor}", pkmn_vocabrary, :color => [0, 0, 0])
      Window.draw_font(80, 67, "NGT", pkmn_name, :color => [0, 0, 0])
      Window.draw_font(45, 370, "倒しきれなかった・・・", pkmn)
      Window.draw_font(45, 425, "GAME OVER", pkmn)
      if Input.key_push?(K_ENTER)
        $kougeki = 10
        $hitpoint = 250000
        GAME_INFO[:scene] = :title
      end
    when :ending
      Window.draw(0, 0, Image[:black])
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending1
      end
    when :ending1
      Window.draw(0, 0, Image[:black])
      Window.draw_font(50, 50, "図書館情報大学は復活し、", font_1)
      Window.draw_font(50, 100, "筑波大学の歴史は幕を閉じた.", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending2
      end
    when :ending2
      Window.draw(0, 0, Image[:black])
      Window.draw_font(50, 50, "図書館情報大学は復活し、", font_1)
      Window.draw_font(50, 100, "筑波大学の歴史は幕を閉じた.", font_1)
      Window.draw_font(50, 150, "本学は春日に定められ、", font_1)
      Window.draw_font(50, 200, "全生徒の必修科目に知識情報概論と", font_1)
      Window.draw_font(50, 250, "図書館概論が追加された.", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending3
      end
    when :ending3
      Window.draw(0, 0, Image[:black])
      Window.draw_font(50, 50, "図書館情報大学は復活し、", font_1)
      Window.draw_font(50, 100, "筑波大学の歴史は幕を閉じた.", font_1)
      Window.draw_font(50, 150, "本学は春日に定められ、", font_1)
      Window.draw_font(50, 200, "全生徒の必修科目に知識情報概論と", font_1)
      Window.draw_font(50, 250, "図書館概論が追加された.", font_1)
      Window.draw_font(50, 300, "こうして図書館情報大学は", font_1)
      Window.draw_font(50, 350, "あらたな一歩を踏み出した.", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending4
      end
    when :ending4
      Window.draw(0, 0, Image[:black])
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending5
      end
    when :ending5
      Window.draw(0, 0, Image[:black])
      Window.draw_font(220, 200, "は ず だ っ た", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending6
      end
    when :ending6
      Window.draw(0, 0, Image[:black])
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending7
      end
    when :ending7
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending8
      end
    when :ending8
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw_font(45, 340, "「どうやら 彼は うまく やってくれた", font_1)
      Window.draw_font(45, 390, "ようですね」", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending9
      end
    when :ending9
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw_font(45, 340, "「束の間の 天下を 存分に ", font_1)
      Window.draw_font(250, 390, "楽しんで いなさい.」", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending10
      end
    when :ending10
      Window.draw(0, 0, Image[:black])
      Window.draw(100, 20, Image[:toshimori])
      Window.draw_font(45, 340, "「さて、第二回戦といきますか...」", font_1)
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending11
      end
    when :ending11
      Window.draw(0, 0, Image[:black])
      if Input.key_push?(K_ENTER)
        GAME_INFO[:scene] = :ending12
      end
    when :ending12
      Window.draw(0, 0, Image[:black])
      Window.draw_font(45, 390, "TO BE CONTINUED...", pkmn)
      if Input.key_push?(K_ENTER)
        $kougeki = 10
        $hitpoint = 500000
        GAME_INFO[:highscore] = 0
        GAME_INFO[:scene] = :title
      end
    end
  end
end
