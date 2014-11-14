class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable
  devise :database_authenticatable, :registerable, :recoverable,
         :rememberable, :trackable, :validatable, :confirmable

  devise :omniauthable, :omniauth_providers => [:github , :bitbucket]

  # Validations
  validates :bitcoin_address, bitcoin_address: true

  # Associations
  has_many :tips ,                inverse_of: :user
  has_one  :tip4commit_identity , inverse_of: :user , :autosave => true , :dependent => :destroy
  has_one  :github_identity ,     inverse_of: :user , :autosave => true , :dependent => :destroy
  has_one  :bitbucket_identity ,  inverse_of: :user , :autosave => true , :dependent => :destroy

  # Callbacks
  before_create :set_login_token!, unless: :login_token?
  before_create :build_default_identity , :autosave => true

  # Instance Methods
  def github_url
    "https://github.com/#{nickname}"
  end

  def balance
    tips.decided.unpaid.sum(:amount)
  end

  def display_name
    attributes['display_name'].presence || name.presence || nickname.presence || email
  end

  def subscribed?
    !unsubscribed?
  end

  # Class Methods
  def self.update_cache
    includes(:tips).find_each do |user|
      user.update commits_count: user.tips.count
      user.update withdrawn_amount: user.tips.paid.sum(:amount)
    end
  end

  def self.create_with_omniauth! provider , email , nickname
p "create_with_omniauth  IN provider=#{provider} email=#{email} nick=#{nickname}" if ENV['DEBUG']

    generated_password = Devise.friendly_token.first(Devise.password_length.min)
user =
    create! do |user|
      user.email    = email
      user.password = generated_password
      user.nickname = nickname

      user.skip_confirmation!
    end

    identity_params = { :email => email , :nickname => nickname }
    case provider
    when 'github' ;    user.build_github_identity    identity_params ;
    when 'bitbucket' ; user.build_bitbucket_identity identity_params ;
#     when 'github' ;
# p "create_with_omniauth BUILDING user_id=#{user.id}" if ENV['DEBUG']
#         user.build_github_identity    identity_params ;
#       user.github_identity = (GithubIdentity.create!    :email => email , :nickname => nickname , :user_id => user.id) ;
    end

print "create_with_omniauth OUT nick=#{user.nickname} email=#{user.email} github_identity=#{(user.github_identity)? user.github_identity.to_yaml : "nil"}\n" if ENV['DEBUG']
user
  end

  def self.find_by_commit(commit)
    email = commit.commit.author.email
    nickname = commit.author.try(:login)

    find_by(email: email) || find_by(nickname: nickname) # TODO: nickname per provider
  end

  private

  def set_login_token!
    loop do
      self.login_token = SecureRandom.urlsafe_base64
      break login_token unless User.exists?(login_token: login_token)
    end
  end

  def build_default_identity
p "build_default_identity nickname  IN='#{self.nickname || (email.split '@').first}'" if ENV['DEBUG']

    self.nickname ||= (email.split '@').first
    build_tip4commit_identity :email => email , :nickname => nickname
  end
end
