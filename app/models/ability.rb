class Ability
  include CanCan::Ability

  def initialize(user)
#     if user and user.nickname.present?
#       can [:update, :decide_tip_amounts], Project, collaborators: {login: user.nickname}
    if user
      if    user.github_identity.present?
        can [:update, :decide_tip_amounts], Project, collaborators: {login: user.github_identity.nickname}
#       can [:update, :decide_tip_amounts] , GithubProject ,
#           :collaborators => { :login => user.github_identity.nickname }
      elsif user.bitbucket_identity.present?
#       can [:update, :decide_tip_amounts] , BitbucketProject ,
#           :collaborators => { :login => user.bitbucket_identity.nickname }
      end
    end
  end
end
