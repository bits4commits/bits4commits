FactoryGirl.define do
  # preload Identity sti models
  load File.join "app","models","identity.rb"

  factory :tip4commit_identity do
    nickname ""
    email    ""
    user_id  nil
  end

  factory :github_identity do
    nickname ""
    email    ""
    user_id  nil
  end

  factory :bitbucket_identity do
    nickname ""
    email    ""
    user_id  nil
  end
end
