# this factory is unused - Identities are generally created via association with a User

FactoryGirl.define do
  # preload Identity sti models
  load File.join "app","models","identity.rb"

  factory :tip4commit_identity do
    email    ""
    nickname ""
    user_id  42
  end

  factory :github_identity do
    email    ""
    nickname ""
    user_id  42
  end

  factory :bitbucket_identity do
    email    ""
    nickname ""
    user_id  42
  end
end
