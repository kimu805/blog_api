require "rails_helper"

RSpec.describe "Articles", type: :request do
  describe "GET /articles" do
    it "公開記事のみ新しい順で返すこと" do
      create(:article, title: "下書き記事")
      old = create(:article, :published, title: "古い記事", published_at: 1.day.ago)
      new_article = create(:article, :published, title: "新しい記事", published_at: Time.current)
      create(:article, :archived, title: "アーカイブ記事")

      get "/articles"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.length).to eq(2)
      expect(json[0]["title"]).to eq("新しい記事")
      expect(json[1]["title"]).to eq("古い記事")
    end

    it "公開記事がない場合は空配列を返すこと" do
      create(:article)

      get "/articles"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end
  end

  describe "GET /articles/:id" do
    it "記事の詳細を返すこと" do
      article = create(:article, :published, title: "テスト記事")

      get "/articles/#{article.id}"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["title"]).to eq("テスト記事")
      expect(json["status"]).to eq("published")
    end

    it "存在しないIDの場合は404を返すこと" do
      get "/articles/999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /articles" do
    context "有効なパラメーターの場合" do
      it "記事を作成して201を返すこと" do
        params = { article: { title: "新規記事", body: "記事の本文です。" } }

        expect { post "/articles", params: params }.to change(Article, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["title"]).to eq("新規記事")
        expect(json["status"]).to eq("draft")
      end

      it "published状態で作成するとpublished_atが自動設定されること" do
        params = { article: { title: "公開記事", body: "本文です。", status: "published" } }

        post "/articles", params: params

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["published_at"]).not_to be_nil
      end
    end

    context "無効なパラメーターの場合" do
      it "titleが空の場合は422とエラーメッセージを返すこと" do
        params = { article: { title: "", body: "本文です。" } }

        expect { post "/articles", params: params }.not_to change(Article, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json["errors"]).to include("Title を入力してください")
      end

      it "bodyが空の場合は422とエラーメッセージを返すこと" do
        params = { article: { title: "タイトル", body: "" } }

        post "/articles", params: params

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json["errors"]).to include("Body を入力してください")
      end
    end
  end

  describe "PATCH /articles/:id" do
    let!(:article) { create(:article, title: "元のタイトル", body: "元の本文") }

    context "有効なパラメーターの場合" do
      it "記事を更新して返すこと" do
        params = { article: { title: "更新後のタイトル" } }

        patch "/articles/#{article.id}", params: params

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["title"]).to eq("更新後のタイトル")
      end

      it "statusをpublishedに変更するとpublished_atが設定されること" do
        params = { article: { status: "published" } }

        patch "/articles/#{article.id}", params: params

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["status"]).to eq("published")
        expect(json["published_at"]).not_to be_nil
      end
    end

    context "無効なパラメーターの場合" do
      it "titleを空にすると422を返すこと" do
        params = { article: { title: "" } }

        patch "/articles/#{article.id}", params: params

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json["errors"]).to include("Title を入力してください")
      end
    end
  end

  describe "DELETE /articles/:id" do
    it "記事を削除して204を返すこと" do
      article = create(:article)

      expect { delete "/articles/#{article.id}" }.to change(Article, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "存在しないIDの場合は404を返すこと" do
      delete "/articles/999"

      expect(response).to have_http_status(:not_found)
    end
  end
end
