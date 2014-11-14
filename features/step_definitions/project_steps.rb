
def create_github_project project_name
  if (@github_project_1.present? && (project_name.eql? @github_project_1.full_name)) ||
     (@github_project_2.present? && (project_name.eql? @github_project_2.full_name))
    raise "duplicate project_name '#{project_name}'"
  elsif @github_project_3.present?
    raise "the maximum of three test projects already exist"
  end

  new_project = Project.create! :full_name       => project_name , # e.g. "me/my-project"
                                :github_id       => Digest::SHA1.hexdigest(project_name) ,
                                :bitcoin_address => 'mq4NtnmQoQoPfNWEPbhSvxvncgtGo6L8WY'
  if    @github_project_2.present? ; @github_project_3 = new_project ;
  elsif @github_project_1.present? ; @github_project_2 = new_project ;
  else                               @github_project_1 = new_project ;
  end

  new_project
end

def create_bitbicket_project project_name
  raise "unknown provider" # nyi
end

def find_project service , project_name
  project = Project.where(:host => service , :full_name => project_name).first
  project || (raise "Project '#{project_name.inspect}' not found")
end

Given(/^a "(.*?)" project named "(.*?)" exists$/) do |provider , project_name|
  # NOTE: project owner will be automatically added as a collaborator
  #           e.g. "seldon" if project_name == "seldon/a-project"
  #       @current_project is also assigned in step 'regarding the "..." project named "..."'
  case provider.downcase
  when 'github'
    @current_project = create_github_project    project_name
  when 'bitbucket'
    @current_project = create_bitbicket_project project_name
  else raise "unknown provider \"#{provider}\""
  end

  step "the project collaborators are:" , (Cucumber::Ast::Table.new [])
end

When /^regarding the "(.*?)" project named "(.*?)"$/ do |provider , project_name|
  # NOTE: @current_project is also assigned in step 'a "..." project named "..." exists'
  @current_project = find_project provider , project_name
end

def github_projects
  [@github_project_1 , @github_project_2 , @github_project_3].compact
end

def bitbucket_projects
  [@bitbucket_project_1 , @bitbucket_project_2 , @bitbucket_project_3].compact
end

def project_provider project
  if    github_projects   .include? project ; :github ;
  elsif bitbucket_projects.include? project ; :bitbucket ;
  else  raise "unknown provider"
  end
end

Given(/^the project collaborators are:$/) do |table|
p "the project collaborators are:  IN=#{table.raw.flatten.join ','}" if ENV['DEBUG']

  project_name          = @current_project.full_name
  owner_name            = (project_name.split '/').first
  project_collaborators = (Set.new table.raw.flatten) << owner_name
  provider              = project_provider @current_project

  (@collaborators ||= Hash.new)[project_name] = project_collaborators
#   @collaborators[project_name].each do |collaborator_name|
#     step "a \"#{provider}\" collaborator named \"#{collaborator_name}\" has previously signed-in via oauth"
#   end

p "the project collaborators are: OUT=#{@collaborators[project_name].to_a.join ','}" if ENV['DEBUG']
end

def load_project_collaborators
  raise "no project exists" if @current_project.nil?

  project_name = @current_project.full_name
#   owner_name   = (project_name.split '/').first
#   ((@collaborators ||= Hash.new)[project_name] ||= Set.new) << owner_name

  @current_project.reload
  @current_project.collaborators.each &:destroy
  @collaborators[project_name].each do |collaborator_name|
    @current_project.collaborators.create! :login => collaborator_name
  end

p "load_project_collaborators=#{@collaborators[project_name].to_a.join ','}" if ENV['DEBUG']
end

When /^the project syncs with the remote repo$/ do
p "step 'the project syncs with the remote repo'" if ENV['DEBUG']

  # NOTE: in the real world a project has no information regarding commits
  #           nor collaborators until the worker thread initially fetches the repo
  #           so new_commits and collaborators are cached and loading defered
  #           to this step which is intended to simulate the BitcoinTipper::work method
  #       this step must be preceeded by a step "a '...' project named '...' exists"
  raise "no project exists" if @current_project.nil?

  load_project_collaborators
  load_new_commits
end

Then /^there should (.*)\s*be a project avatar image visible$/ do |should|
  avatar_xpath = "//img[contains(@src, \"githubusercontent\")]"
  if should.eql? 'not '
    page.should_not have_xpath avatar_xpath
  else
    page.should have_xpath avatar_xpath
  end
end
