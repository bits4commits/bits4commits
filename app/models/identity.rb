class Identity < ActiveRecord::Base
  belongs_to :user
end

class Tip4commitIdentity < Identity
  validates :user_id ,  :presence => true , :uniqueness => true
  validates :email ,    :presence => true , :uniqueness => true
  validates :nickname , :presence => true , :uniqueness => true
end

class GithubIdentity < Identity
  validates :user_id ,  :presence => true , :uniqueness => true
  validates :email ,    :presence => true , :uniqueness => true
  validates :nickname , :presence => true , :uniqueness => true
end

class BitbucketIdentity < Identity
  validates :user_id ,  :presence => true , :uniqueness => true
  validates :email ,    :presence => true , :uniqueness => true
  validates :nickname , :presence => true , :uniqueness => true
end
