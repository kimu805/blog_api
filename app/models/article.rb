class Article < ApplicationRecord
  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft, prefix: true

  validates :title,  presence: { message: "を入力してください" },
                     length:   { maximum: 255, message: "は255文字以内で入力してください" }
  validates :body,   presence: { message: "を入力してください" },
                     length:   { maximum: 100_000, message: "は100000文字以内で入力してください" }
  validates :status, presence: { message: "を入力してください" }

  validate :validate_published_at_presence

  before_validation :set_published_at, if: -> { status_published? && published_at.blank? }
  before_validation :clear_published_at, if: -> { !status_published? }

  private

  def validate_published_at_presence
    if status_published? && published_at.blank?
      errors.add(:published_at, "を入力してください")
    end
  end

  def set_published_at
    self.published_at = Time.current
  end

  def clear_published_at
    self.published_at = nil
  end
end
