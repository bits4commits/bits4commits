
def make_primary_email nickname ; "#{nickname.parameterize}@example.com" ; end ;

def make_secondary_email nickname ; "#{nickname.parameterize}@some_host.net" ; end ;

def default_password ; 'a-password' ; end ;

def generate_bitcoin_address
# TODO: yep this is goofy
  (@bitcoin_address_pool ||= ['1AFgARu7e5d8Lox6P2DSFX3MW8BtsVXEn5' ,
                              '1AFgARu7e5d8Lox6P2DSFX3MW8BtsVXEn5' ,
                              '1AFgARu7e5d8Lox6P2DSFX3MW8BtsVXEn5' ,
                              '1AFgARu7e5d8Lox6P2DSFX3MW8BtsVXEn5' ,
                              '1AFgARu7e5d8Lox6P2DSFX3MW8BtsVXEn5']).pop ||
                              'TOO_MANY_USERS'
end

def find_or_create_user nickname , should_have_bitcoin_address = false
p "find_or_create_user  IN nick=#{nickname} #{User.count} users #{(User.find_by :email => (make_primary_email nickname))? 'User (exists)' : '(creating) User'}" if ENV['DEBUG']

  email = make_primary_email nickname
  user  = (User.find_by :email => email) || User.create do |user|
#     user.name            = nickname
    user.email           = email
    user.nickname        = nickname
    user.password        = default_password
    user.skip_confirmation!
  end

  should_have_bitcoin_address &&= user.bitcoin_address.nil?
  user.update :bitcoin_address => generate_bitcoin_address if should_have_bitcoin_address

print "find_or_create_user OUT nick=#{nickname} #{User.count} users\n\ttip4commit_identity=#{user.tip4commit_identity.present?}\n\tgithub_identity=#{user.github_identity.present?}\n\tbitbucket_identity=#{user.bitbucket_identity.present?}\n" if ENV['DEBUG']

  (@users ||= {})[nickname] ||= user
end

def mock_oauth_user provider , nickname
p "mock_oauth_user  IN=nick=#{nickname} #{User.count} users" if ENV['DEBUG']

  primary_email   = make_primary_email   nickname
  secondary_email = make_secondary_email nickname

  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[provider] =
  {
#   OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new {

    :provider => provider.to_s ,
    :uid      => '12345678' ,
    :info     =>
    {
      :nickname        => nickname ,
      :primary_email   => primary_email ,
      :verified_emails => [secondary_email , primary_email]
    }
#     "info" => {
#       "nickname"        => nickname ,
#       "primary_email"   => email    ,
#       "verified_emails" => [email]  ,
#     },
  }.to_ostruct
#   }
# p "mock_oauth_user MID=#{User.count}"
#   step "a developer named \"#{nickname}\" exists without a bitcoin address"
p "mock_oauth_user OUT=nick=#{nickname} #{User.count} users" if ENV['DEBUG']
end

Given /^a developer named "(.*?)" exists (with|without?) a bitcoin address$/ do |nickname , with|
p "step 'a developer exists' nickname=#{nickname} - #{(@users && @users[nickname])? 'exists in @users' : 'adding to @users'}" if ENV['DEBUG']
#print "#{(@users)? @users.keys.size : 0} @users=#{@users.to_yaml}\n" if ENV['DEBUG']

  # NOTE: this step exists to create users who have signed-up only via email but never
  #           via oauth - oauth users have more abilities (edit projects)
  #       this user will have the default Identity instance but not one of its subclasses
  has_bitcoin_address = with.eql? 'with'
  find_or_create_user nickname , has_bitcoin_address
end

Given /^I am signed in to "(.*?)" as "(.*?)"$/ do |provider , nickname|
p "step 'I am signed in to \"#{provider}\" as \"#{nickname}\"'  IN=#{User.count} users" if ENV['DEBUG']

  # NOTE: this step exists to create an oauth mock for users who have never signed in via oauth
  #       this user will not necessarily have any Identity instances
  case provider.downcase
  when 'github' ;    mock_oauth_user :github ,    nickname ;
  when 'bitbucket' ; mock_oauth_user :bitbucket , nickname ;
pending "bitbucket not yet implemented" ;
  else raise "unknown provider \"#{provider}\""
  end

p "step 'I am signed in to \"#{provider}\" as \"#{nickname}\"' OUT=#{User.count} users" if ENV['DEBUG']
end

Given /^a "(.*?)" collaborator named "(.*?)" has previously signed-in via oauth$/ do |provider , nickname|
p "step 'a \"#{provider}\" collaborator named \"#{nickname}\" has previously signed-in via oauth'  IN=#{User.count} users #{(@users.present? && @users[nickname].present? && @users[nickname].github_identity.present?)? '(user exists)' : '(creating user)'}" if ENV['DEBUG']

  # NOTE: this step exists to create users who have signed in previously via oauth
  #           but are not signed in now - oauth users have more abilities (edit projects)
  #       this user will have the default Identity instance and also one of its subclasses
  collaborator = find_or_create_user nickname
  if @users.present? && collaborator.present?
    identity_params =
    {
      :email    => (make_primary_email nickname) ,
      :nickname => nickname ,
      :user_id  => collaborator.id
    }
    case provider.downcase
    when 'github'
      if collaborator.github_identity.nil?
        collaborator.github_identity    = GithubIdentity   .create! identity_params
      end
    when 'bitbucket'
      if collaborator.bitbucket_identity.nil?
        collaborator.bitbucket_identity = BitbucketIdentity.create! identity_params
      end
    else raise "unknown provider \"#{provider}\""
    end
  end
=begin
    case provider.downcase
    when 'github' ;    identity = collaborator.github_identity ;
    when 'bitbucket' ; identity = collaborator.bitbucket_identity ;
    else raise "unknown provider \"#{provider}\""
    end
  if identity.blank?
    step "I sign out"
    step "I am signed in via \"#{provider}\" as \"#{nickname}\"" ;
    step "I sign out"
  end
=end
p "step 'a \"#{provider}\" collaborator named \"#{nickname}\" has previously signed-in via oauth' OUT=#{User.count} users" if ENV['DEBUG']
end

Then(/^one "(.*?)" identity should exist for a user named "(.*?)"$/) do |provider , nickname|
  email = make_primary_email nickname

  case provider
  when 'default' ;   (Tip4commitIdentity.where :email => email).count.should be 1
  when 'github' ;    (GithubIdentity    .where :email => email).count.should be 1
  when 'bitbucket' ; (BitbucketIdentity .where :email => email).count.should be 1
  end
end
