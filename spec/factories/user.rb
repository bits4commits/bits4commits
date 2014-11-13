FactoryGirl.define do
  # preload Identity sti models
  load File.join "app","models","identity.rb"

  factory :user do
    email       nil # required - pass this in
    nickname    { ((email || "").split '@').first }
    password    "password"
    login_token "login_token"
  end
end
