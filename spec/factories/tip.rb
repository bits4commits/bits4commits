FactoryGirl.define do
  factory :tip do
    association :project # project is required - pass this in
    association :user    # user    is required - pass this in
    amount 1
    commit { Digest::SHA1.hexdigest(SecureRandom.hex) }

    factory :undecided_tip do
      amount nil
    end
  end
end
