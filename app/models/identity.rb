class Identity < ActiveRecord::Base
  belongs_to :user
  validates :type , :presence => true
end

class Tip4commitIdentity < Identity
  validates :nickname , :presence => true , :uniqueness => true
  validates :email ,    :presence => true , :uniqueness => true
  validates :user_id ,  :presence => true , :uniqueness => true
end

class GithubIdentity < Identity
  validates :nickname , :presence => true , :uniqueness => true
  validates :email ,    :presence => true , :uniqueness => true
  validates :user_id ,  :presence => true , :uniqueness => true
end

class BitbucketIdentity < Identity
  validates :nickname , :presence => true , :uniqueness => true
  validates :email ,    :presence => true , :uniqueness => true
  validates :user_id ,  :presence => true , :uniqueness => true
end
