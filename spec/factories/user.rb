FactoryGirl.define do
  factory :user do
    email       nil # required - pass this in
    nickname    { ((email || "").split '@').first }
    password    "password"
    login_token "login_token"
  end
end
