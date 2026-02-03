require "rails_helper"

RSpec.describe "Comments", type: :request do
  let!(:article) { create(:article, :published, title: "テスト記事") }

  describe "GET /articles/:article_id/comments" do
    it "指定した記事のコメント一覧を新しい順で返すこと" do
      old_comment = create(:comment, article: article, author_name: "古いコメント", created_at: 1.day.ago)
      new_comment = create(:comment, article: article, author_name: "新しいコメント", created_at: Time.current)

      get "/articles/#{article.id}/comments"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json.length).to eq(2)
      expect(json[0]["author_name"]).to eq("新しいコメント")
      expect(json[1]["author_name"]).to eq("古いコメント")
    end

    it "コメントがない場合は空配列を返すこと" do
      get "/articles/#{article.id}/comments"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end

    it "存在しない記事IDの場合は404を返すこと" do
      get "/articles/999/comments"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /articles/:article_id/comments" do
    context "有効なパラメーターの場合" do
      it "コメントを作成して201を返すこと" do
        params = { comment: { author_name: "山田太郎", body: "素晴らしい記事です！" } }

        expect {
          post "/articles/#{article.id}/comments", params: params
        }.to change(article.comments, :count).by(1)

        expect(response).to have_http_status(:created)
        json = response.parsed_body
        expect(json["author_name"]).to eq("山田太郎")
        expect(json["body"]).to eq("素晴らしい記事です！")
        expect(json["article_id"]).to eq(article.id)
      end
    end

    context "無効なパラメーターの場合" do
      it "author_nameが空の場合は422とエラーメッセージを返すこと" do
        params = { comment: { author_name: "", body: "本文です" } }

        expect {
          post "/articles/#{article.id}/comments", params: params
        }.not_to change(Comment, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json["errors"]).to include("Author name を入力してください")
      end

      it "bodyが空の場合は422とエラーメッセージを返すこと" do
        params = { comment: { author_name: "山田太郎", body: "" } }

        post "/articles/#{article.id}/comments", params: params

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json["errors"]).to include("Body を入力してください")
      end

      it "author_nameが51文字の場合は422を返すこと" do
        params = { comment: { author_name: "a" * 51, body: "本文です" } }

        post "/articles/#{article.id}/comments", params: params

        expect(response).to have_http_status(:unprocessable_entity)
        json = response.parsed_body
        expect(json["errors"]).to include("Author name は1文字以上50文字以内で入力してください")
      end
    end

    it "存在しない記事IDの場合は404を返すこと" do
      params = { comment: { author_name: "山田太郎", body: "本文です" } }

      post "/articles/999/comments", params: params

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /articles/:article_id/comments/:id" do
    let!(:comment) { create(:comment, article: article) }

    it "コメントを削除して204を返すこと" do
      expect {
        delete "/articles/#{article.id}/comments/#{comment.id}"
      }.to change(article.comments, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "存在しないコメントIDの場合は404を返すこと" do
      delete "/articles/#{article.id}/comments/999"

      expect(response).to have_http_status(:not_found)
    end

    it "他の記事のコメントは削除できないこと" do
      other_article = create(:article, title: "別の記事")
      other_comment = create(:comment, article: other_article)

      delete "/articles/#{article.id}/comments/#{other_comment.id}"

      expect(response).to have_http_status(:not_found)
    end
  end
end
