
def create_github_project project_name
  if (@github_project_1.present? && (project_name.eql? @github_project_1.full_name)) ||
     (@github_project_2.present? && (project_name.eql? @github_project_2.full_name))
    raise "duplicate project_name '#{project_name}'"
  elsif @github_project_3.present?
    raise "the maximum of three test projects already exist"
  end

# @current_project is also assigned in the "regarding the .. project named ..." step
  @current_project = Project.create! :full_name       => project_name , # e.g. "me/my-project"
                                     :github_id       => Digest::SHA1.hexdigest(project_name) ,
                                     :bitcoin_address => 'mq4NtnmQoQoPfNWEPbhSvxvncgtGo6L8WY'
  if    @github_project_2.present? ; @github_project_3 = @current_project ;
  elsif @github_project_1.present? ; @github_project_2 = @current_project ;
  else                               @github_project_1 = @current_project ;
  end
end

def create_bitbicket_project project_name
  raise "unknown provider" # nyi
end

When /^regarding the "(.*?)" project named "(.*?)"$/ do |provider , project_name|
# @current_project is also assigned in create_github_project and create_bitbucket_project

  @current_project = find_project provider , project_name
end

def dict_do provider , method_dict
=begin usage e.g.
  dict_do 'github' , {'github'    => lambda {create_github_project    project_name} ,
                      'bitbucket' => lambda {create_bitbicket_project project_name} }
=end
  (method_dict.has_key? provider)? method_dict[provider].call : (raise "unknown provider")
end

Given(/^a "(.*?)" project named "(.*?)" exists$/) do |provider , project_name|
  dict_do provider , {'github'    => lambda {create_github_project    project_name} ,
                      'bitbucket' => lambda {create_bitbicket_project project_name} }
end

def project_provider project
  github_projects    = [@github_project_1 , @github_project_2 , @github_project_3]
  bitbucket_projects = [@bitbucket_project_1 , @bitbucket_project_2 , @bitbucket_project_3]

  if    github_projects   .include? project ; :github ;
  elsif bitbucket_projects.include? project ; :bitbucket ;
  else  raise "unknown provider"
  end
end

Given(/^the project collaborators are:$/) do |table|
  project_name = @current_project.full_name

  (@collaborators ||= {})[project_name] = []
  table.raw.each do |collaborator_name,|
    @collaborators[project_name] << collaborator_name unless @collaborators[project_name].include? collaborator_name
  end
end

Given(/^the project collaborators are loaded$/) do
  raise "no project exists" if @current_project.nil?
  raise "no collaborators"  if @collaborators.blank?

  # NOTE: this step is best called at an early stage (preferably in the Background)
  #           as other steps depend on it and it may exit with the session signed out
  provider     = project_provider @current_project
  project_name = @current_project.full_name
  raise "no project collaborators" if @collaborators[project_name].blank?

  @current_project.reload
  @current_project.collaborators.each(&:destroy)
  @collaborators[@current_project.full_name].each do |collaborator_name,|
p "step 'collaborators are loaded' collaborator_name=#{collaborator_name}"
    @current_project.collaborators.create!(login: collaborator_name)
    step "a \"#{provider}\" collaborator named \"#{collaborator_name}\" has previously signed-in via oauth"
  end
end

When /^the project syncs with the remote repo$/ do
p "step 'the project syncs with the remote repo'" if DBG

  # NOTE: in the real world a project has no information regarding commits
  #           nor collaborators until the worker thread initially fetches the repo
  #           so new_commits and collaborators are cache ed and loading defered
  #           to this step which is intended to simulate the BitcoinTipper::work method
  #       this step must preceed any step "the project has undecided tips"
  #           and must be preceeded by a step "a '...' project named '...' exists"
  #           and then by step "the project collaborators are:"
  project_name                   = @current_project.full_name
  owner_name                     = (project_name.split '/').first
  @new_commits                 ||= {@current_project.id => Hash.new}
  @collaborators               ||= Hash.new
#   @collaborators[project_name] ||= [owner_name]
  @collaborators[project_name] ||= Array.new
#   @collaborators[project_name]  << owner_name unless @collaborators[project_name].include? owner_name

  step 'the new commits are loaded'
  step 'the project collaborators are loaded'
end

Then /^there should (.*)\s*be a project avatar image visible$/ do |should|
  avatar_xpath = "//img[contains(@src, \"githubusercontent\")]"
  if should.eql? 'not '
    page.should_not have_xpath avatar_xpath
  else
    page.should have_xpath avatar_xpath
  end
end
