class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
#   before_action :load_omniauth_info, only: :github
#   before_action :load_omniauth_info, only: [:github , :bitbucket]
  before_action :load_omniauth_info
def dump_user
  User.all.each {|user| p " " ; p "dump_user (#{User.count}) User[#{user.id}]" ;
      p "email              = '#{user.email}'" ;
      p "name               = '#{user.name}'" ;
      p "nickname           = '#{user.nickname}'" ;
      p "display_name       = '#{user.display_name}'" ;
  print "identity           = '#{(user.tip4commit_identity) ? user.tip4commit_identity.to_yaml           : 'nil'}'\n" ;
  print "github_identity    = '#{(user.github_identity)     ? user.github_identity.to_yaml    : 'nil'}'\n" ;
  print "bitbucket_identity = '#{(user.bitbucket_identity)  ? user.bitbucket_identity.to_yaml : 'nil'}'\n"} ; ""
end
ORIG=false

  def github
if ORIG
    @user = User.find_by(nickname: @omniauth_info.nickname) ||
            User.find_by(email: @omniauth_info.verified_emails)
else
    identity = (GithubIdentity    .find_by :nickname => @auth_nick) ||
               (Tip4commitIdentity.find_by :email    => @auth_emails)
    @user    = identity.user if identity
end
print "OmniauthCallbacksController#github  IN identity=#{identity.to_yaml} user=#{@user}\n" if ENV['DEBUG']

    if @user.present?
p "OmniauthCallbacksController#github got user identity=#{(@user.tip4commit_identity)? 'OK' : 'nil'} github_identity=#{(@user.github_identity)? 'OK' : 'nil'}" if ENV['DEBUG']

if ORIG
      if @omniauth_info.primary_email.present? && @user.email != @omniauth_info.primary_email
        # update email if it has been changed
        @user.update email: @omniauth_info.primary_email
      end
else
      # create new identity if merging with existing user (other identity found by email)
      # or update email if provider primary email has changed (identity found by nickname)
      if    @user.github_identity.nil?
#           @user.github_identity = GithubIdentity.create :email    => auth_email ,
#                                                         :nickname => auth_nick ,
#                                                         :user_id  => @user.id
        @user.create_github_identity! :email    => @auth_email ,
                                      :nickname => @auth_nick
      elsif @user.github_identity.email != @auth_email
        @user.github_identity.update :email => @auth_email
      end
end
    else # user not found
p "OmniauthCallbacksController#github user not found - creating" if ENV['DEBUG']

      @user = User.create_with_omniauth! @auth_provider , @auth_email , @auth_nick
    end
print "OmniauthCallbacksController#github OUT identity=#{(@user.tip4commit_identity)? 'OK' : 'nil'} github_identity=#{(@user.github_identity)? 'OK' : 'nil'}\n\n" if ENV['DEBUG']
dump_user if ENV['DEBUG']

    @user.update :name => @auth_name , :image => @auth_image

    sign_in_and_redirect @user, event: :authentication
    set_flash_message(:notice, :success, kind: 'GitHub') if is_navigational_format?
  end

  def bitbucket # TODO: dry these out
p "OmniauthCallbacksController#bitbucket IN"

    identity = (BitbucketIdentity .find_by :nickname => @auth_nick) ||
               (Tip4commitIdentity.find_by :email    => @auth_emails)
    @user    = identity.user if identity

print "OmniauthCallbacksController#bitbucket identity=#{identity.to_yaml} user=#{@user}\n" if ENV['DEBUG']

    if @user.present?
p "OmniauthCallbacksController#bitbucket got user" if ENV['DEBUG']

      # create new identity if merging with existing user (other identity found by email)
      # or update email if provider primary email has changed (identity found by nickname)
      if    @user.bitbucket_identity.nil?
        @user.create_bitbucket_identity! :email    => @auth_email ,
                                         :nickname => @auth_nick
      elsif @user.bitbucket_identity.email != @auth_email
        @user.bitbucket_identity.update :email => @auth_email
      end
    else
p "OmniauthCallbacksController#bitbucket user not found - creating" if ENV['DEBUG']

      @user = User.create_with_omniauth! @auth_provider , @auth_email , @auth_nick
    end
print "OmniauthCallbacksController#bitbucket OUT identity=#{(@user.tip4commit_identity)? 'OK' : 'nil'} github_identity=#{(@user.github_identity)? 'OK' : 'nil'}\n\n" if ENV['DEBUG']
dump_user if ENV['DEBUG']

    @user.update :name => @auth_name , :image => @auth_image

    sign_in_and_redirect @user, event: :authentication
    set_flash_message(:notice, :success, kind: 'BitBucket') if is_navigational_format?
  end


  private

  def load_omniauth_info
print "\n\nload_omniauth_info auth_hash=#{request.env['omniauth.auth'].to_yaml}\n" if ENV['DEBUG']
=begin
request.env['omniauth.auth']['uid'].eql? '1642691'
Started GET "/users/auth/github/callback?code=0ed602b8fa5630ee116a&state=3537903a543e2a1b74588de99d2db719b8c5a4f638f49da4" for 24.151.132.111 at 2014-11-11 01:05:40 +0000
Processing by Users::OmniauthCallbacksController#github as HTML
  Parameters: {"code"=>"0ed602b8fa5630ee116a", "state"=>"3537903a543e2a1b74588de99d2db719b8c5a4f638f49da4"}
ider: github
=end

    (auth_hash      = request.env['omniauth.auth'])                            &&
    (@auth_provider = request.env['omniauth.auth']['provider'])                &&
    (auth_info      = request.env['omniauth.auth']['info'])                    &&
    (@auth_nick     = request.env['omniauth.auth']['info']['nickname'])        &&
    (@auth_email    = request.env['omniauth.auth']['info']['primary_email'])   &&
    (@auth_emails   = request.env['omniauth.auth']['info']['verified_emails']) &&
    (@auth_name     = request.env['omniauth.auth']['info']['name'])            &&
    (@auth_image    = request.env['omniauth.auth']['info']['image'])           &&

#     unless @omniauth_info
    if    auth_hash.nil? || auth_info.nil?
      failure_reason = I18n.t('devise.errors.omniauth_info')
    elsif @auth_email.nil?
      failure_reason = I18n.t('devise.errors.primary_email')
    elsif @auth_provider.nil? || @auth_nick.nil? ||
          !(User.omniauth_providers.include? @auth_provider.to_sym)
      failure_reason ="unknown omniauth error"

p "load_omniauth_info @auth_provider.nil?=#{@auth_provider.nil?} @auth_nick.nil?=#{@auth_nick.nil?} " + ((@auth_provider)? "include?=#{!(User.omniauth_providers.include? @auth_provider.to_sym)}" : "nil") if ENV['DEBUG']

    end

p "load_omniauth_info " + ((failure_reason.nil?)? "OK" : "failed=#{failure_reason}") if ENV['DEBUG']

    if failure_reason.present?
      set_flash_message(:error, :failure, kind: 'GitHub', reason: failure_reason)
      redirect_to new_user_session_path and return
    end
  end
end
