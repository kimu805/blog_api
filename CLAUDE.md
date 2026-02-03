# Blog API

## プロジェクト概要
個人ブログサイトのバックエンドAPI

### API構成
- **モデル**
  - Article: ブログ記事（title, body, status, published_at）
  - Comment: 記事へのコメント（article_id, author_name, body）

- **コントローラー**
  - ArticlesController: 記事のCRUD操作（index, show, create, update, destroy）
  - CommentsController: コメントの操作（index, create, destroy）

- **ルーティング**
  - 記事: `/articles`, `/articles/:id`
  - コメント: `/articles/:article_id/comments`（ネストされたリソース）

## 技術スタック
- Ruby on Rails 8.0.4 (API mode)
- SQLite3（Railsのデフォルト）
- RSpec（テストフレームワーク）
- FactoryBot（テストデータ作成）

## 開発ルール

### 一般
- テストは必ず書く（RSpec）
- コミットは日本語で記述

### バリデーション
- エラーメッセージは日本語で記述
- 例: `presence: { message: 'を入力してください' }`

### enum
- integer型で定義し、値は明示的に指定
- **prefix: true を使用すること**（メソッド名の衝突を防ぐため）
- 例: `enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft, prefix: true`
- 結果: `status_draft?`, `status_published?`, `status_archived?` のメソッドが生成される

### カスタムバリデーション
- メソッド名: validate_カラム名_チェック内容
- 例: `validate_published_at_presence`

## テスト規約

### テストの構成順序
1. 正常系（有効なケース）
2. 異常系（無効なケース）
3. 境界値（制限値付近のケース）

### ファクトリ
- デフォルトは最小限の有効な状態
- バリエーションはtraitで定義

## テストの実行方法

### RSpecコマンド
```bash
# rbenvの初期化が必要な場合
eval "$(rbenv init -)"

# 全テストを実行
bundle exec rspec

# 特定のファイルを実行
bundle exec rspec spec/models/article_spec.rb
bundle exec rspec spec/requests/articles_spec.rb

# 特定の行番号のテストを実行
bundle exec rspec spec/models/article_spec.rb:17
```

### FactoryBotの使い方
```ruby
# 基本的な使い方
article = build(:article)              # メモリ上にインスタンスを作成（保存しない）
article = create(:article)             # DBに保存されたインスタンスを作成

# traitを使う
article = create(:article, :published) # publishedトレイトを使用
article = create(:article, :archived)  # archivedトレイトを使用

# 属性を上書き
article = create(:article, title: "カスタムタイトル", body: "カスタム本文")

# アソシエーション
comment = create(:comment, article: article) # 既存のarticleに関連付け
comment = create(:comment)                   # 自動的にarticleも作成される
```

## 開発時の注意点

### コントローラー
- ArticlesController#index は公開記事のみ返す（`Article.status_published`）
- CommentsController はネストされたリソース
- コメントの操作は必ず親記事経由で行う（セキュリティのため）

### エラーハンドリング
- 存在しないリソースは404 (not_found) を返す
- バリデーションエラーは422 (unprocessable_entity) を返す
- エラーメッセージ形式: `{ errors: [...] }`

### マイグレーション
- `t.references` は自動的にインデックスを作成するため、手動で `add_index` しない

## コーディング規約

### 命名規則
- モデル: 単数形（Article, Comment）
- コントローラー: 複数形（ArticlesController, CommentsController）
- ファクトリ: 単数形（:article, :comment）

### コールバック
- `before_validation` で属性の自動設定を行う
- 複雑なロジックはカスタムバリデーションメソッドに分離

### アソシエーション
- 親子関係では `dependent: :destroy` を指定（Articleが削除されたらCommentも削除）
- ネストされたリソースでは `@article.comments` のようにスコープを絞る
