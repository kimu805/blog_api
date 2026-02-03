class ArticlesController < ApplicationController
  before_action :set_article, only: %i[show update destroy]

  def index
    articles = Article.status_published.order(published_at: :desc)
    render json: articles
  end

  def show
    render json: @article
  end

  def create
    article = Article.new(article_params)

    if article.save
      render json: article, status: :created
    else
      render json: { errors: article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @article.update(article_params)
      render json: @article
    else
      render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy!
    head :no_content
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :body, :status, :published_at)
  end
end
