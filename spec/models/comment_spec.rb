require "rails_helper"

RSpec.describe Comment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:article) }
  end

  describe "validations" do
    subject { build(:comment) }

    # --- 正常系 ---
    describe "正常系" do
      it "デフォルトのファクトリ属性で有効であること" do
        expect(build(:comment)).to be_valid
      end

      it "author_nameが1文字で有効であること" do
        expect(build(:comment, author_name: "A")).to be_valid
      end

      it "author_nameが50文字で有効であること" do
        expect(build(:comment, author_name: "a" * 50)).to be_valid
      end
    end

    # --- 異常系 ---
    describe "異常系" do
      it { is_expected.to validate_presence_of(:author_name).with_message("を入力してください") }
      it { is_expected.to validate_presence_of(:body).with_message("を入力してください") }

      it "author_nameが空の場合は無効であること" do
        comment = build(:comment, author_name: "")
        expect(comment).not_to be_valid
        expect(comment.errors[:author_name]).to include("を入力してください")
      end

      it "bodyが空の場合は無効であること" do
        comment = build(:comment, body: "")
        expect(comment).not_to be_valid
        expect(comment.errors[:body]).to include("を入力してください")
      end

      it "articleが存在しない場合は無効であること" do
        comment = build(:comment, article: nil)
        expect(comment).not_to be_valid
      end
    end

    # --- 境界値 ---
    describe "境界値" do
      it "author_nameが51文字の場合は無効であること" do
        comment = build(:comment, author_name: "a" * 51)
        expect(comment).not_to be_valid
        expect(comment.errors[:author_name]).to include("は1文字以上50文字以内で入力してください")
      end
    end
  end
end
