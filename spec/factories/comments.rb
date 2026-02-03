FactoryBot.define do
  factory :comment do
    association :article
    author_name { "テストユーザー" }
    body { "これはコメント本文です。" }
  end
end
