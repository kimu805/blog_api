require 'rails_helper'

RSpec.describe Article, type: :model do
  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, published: 1, archived: 2).with_default(:draft).with_prefix }
  end

  describe 'validations' do
    subject { build(:article) }

    # --- 正常系 ---
    describe '正常系' do
      it 'デフォルトのファクトリ属性で有効であること' do
        expect(build(:article)).to be_valid
      end

      it 'published状態でpublished_atありなら有効であること' do
        expect(build(:article, :published)).to be_valid
      end

      it 'archived状態で有効であること' do
        expect(build(:article, :archived)).to be_valid
      end
    end

    # --- 異常系 ---
    describe '異常系' do
      it { is_expected.to validate_presence_of(:title).with_message('を入力してください') }
      it { is_expected.to validate_presence_of(:body).with_message('を入力してください') }

      context 'statusがpublishedでpublished_atが明示的にnilの場合' do
        it 'コールバックにより自動設定されて有効になること' do
          article = build(:article, status: :published, published_at: nil)
          expect(article).to be_valid
          expect(article.published_at).not_to be_nil
        end
      end
    end

    # --- 境界値 ---
    describe '境界値' do
      describe 'titleの文字数' do
        it { is_expected.to validate_length_of(:title).is_at_most(255).with_message('は255文字以内で入力してください') }

        it '255文字で有効であること' do
          expect(build(:article, title: 'a' * 255)).to be_valid
        end

        it '256文字で無効であること' do
          article = build(:article, title: 'a' * 256)
          expect(article).not_to be_valid
          expect(article.errors[:title]).to include('は255文字以内で入力してください')
        end
      end

      describe 'bodyの文字数' do
        it { is_expected.to validate_length_of(:body).is_at_most(100_000).with_message('は100000文字以内で入力してください') }

        it '100000文字で有効であること' do
          expect(build(:article, body: 'a' * 100_000)).to be_valid
        end

        it '100001文字で無効であること' do
          article = build(:article, body: 'a' * 100_001)
          expect(article).not_to be_valid
          expect(article.errors[:body]).to include('は100000文字以内で入力してください')
        end
      end
    end
  end

  describe 'callbacks' do
    describe '#set_published_at' do
      it 'published時にpublished_atが自動設定されること' do
        article = build(:article, status: :published, published_at: nil)
        freeze_time do
          article.valid?
          expect(article.published_at).to eq(Time.current)
        end
      end

      it '既にpublished_atがある場合は上書きしないこと' do
        specific_time = Time.zone.parse('2026-01-01 12:00:00')
        article = build(:article, status: :published, published_at: specific_time)
        article.valid?
        expect(article.published_at).to eq(specific_time)
      end
    end

    describe '#clear_published_at' do
      it 'draftに変更するとpublished_atがクリアされること' do
        article = create(:article, :published)
        article.status = :draft
        article.valid?
        expect(article.published_at).to be_nil
      end

      it 'archivedに変更するとpublished_atがクリアされること' do
        article = create(:article, :published)
        article.status = :archived
        article.valid?
        expect(article.published_at).to be_nil
      end
    end
  end

  describe 'scopes' do
    it '.status_publishedで公開記事のみ取得できること' do
      create(:article)
      published = create(:article, :published, title: '公開記事')
      create(:article, :archived, title: 'アーカイブ記事')

      expect(Article.status_published).to eq([published])
    end
  end
end
