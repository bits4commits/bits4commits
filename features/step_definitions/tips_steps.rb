
Given(/^our fee is "(.*?)"$/) do |arg1|
  CONFIG["our_fee"] = arg1.to_f
end

Given(/^the tip percentage per commit is "(.*?)"$/) do |arg1|
  CONFIG["tip"] = arg1.to_f
end

Given(/^the minimum tip amount is "(.*?)"$/) do |arg1|
  CONFIG["min_tip"] = arg1.to_f * 1e8
end

Given(/^a deposit of "(.*?)" is made$/) do |deposit|
  Deposit.create!(project: @current_project, amount: deposit.to_d * 1e8, confirmations: 2)
end

def add_new_commit commit_id , nickname , params = {}
  raise "duplicate commit_id" if (find_new_commit commit_id).present?

  defaults = {
    sha: commit_id,
    commit: {
      message: "Some changes",
      author: {
        email: (make_primary_email nickname) ,
      },
    },
  }

  project_id                            = @current_project.id
  @new_commits                        ||= {}
  @new_commits[project_id]            ||= {}
  @new_commits[project_id][commit_id]   = defaults.deep_merge params

p "add_new_commit nickname='#{nickname}' commit_id='#{commit_id}' - #{@new_commits[project_id].keys.size} for #{@current_project.full_name}" if DBG
end

def find_new_commit commit_id
  (@new_commits || {}).each_value do |commits|
    return commits[commit_id] unless commits[commit_id].nil?
  end

  nil
end

Given(/^a new commit "([^"]*?)" is made by a developer named "(.*?)"$/) do |commit_id , nickname|
  add_new_commit commit_id , nickname
end

Given(/^(\d+) new commit.? (?:is|are) made by a developer named "(.*?)"$/) do |n_commits , nickname|
  n_commits.to_i.times do
    add_new_commit Digest::SHA1.hexdigest(SecureRandom.hex) , nickname
  end
end

Given(/^a new commit "([^"]*?)" is made$/) do |commit_id|
  add_new_commit commit_id , "unknown-user"
end

Given(/^a new commit "(.*?)" is made with parent "([^"]*?)"$/) do |commit_id, parent_commit_id|
  add_new_commit commit_id , "unknown-user" , parents: [{sha: parent_commit_id}]
end

Given(/^a new commit "(.*?)" is made with parent "(.*?)" and "(.*?)"$/) do |commit_id, parentA_commit_id, parentB_commit_id|
  params = { parents: [{sha: parentA_commit_id}, {sha: parentB_commit_id}], commit: {message: "Merge #{parentA_commit_id} and #{parentB_commit_id}"} }
  add_new_commit commit_id , "unknown-user" , params
end

Given(/^the author of commit "(.*?)" is "(.*?)"$/) do |commit_id , nickname|
  commit = find_new_commit commit_id
  raise "no such commit" if commit.nil?

  email = make_primary_email nickname
  commit.deep_merge!(author: {login: nickname}, commit: {author: {email: email}})
end

Given(/^the message of commit "(.*?)" is "(.*?)"$/) do |commit_id , commit_msg|
  commit = find_new_commit commit_id
  raise "no such commit" if commit.nil?

  commit.deep_merge!(commit: {message: commit_msg})
end

Given(/^the most recent commit is "(.*?)"$/) do |commit_id|
  @current_project.update! last_commit: commit_id
end

Then(/^the most recent commit should be "(.*?)"$/) do |commit_id|
  @current_project.reload.last_commit.should eq commit_id
end

When(/^the new commits are loaded$/) do
  raise "no commits have been assigned" if @new_commits.nil?

  [@github_project_1 , @github_project_2 , @github_project_3].each do |project|
    next if project.nil?

    project.reload
    new_commits = @new_commits[project.id].values.map(&:to_ostruct)
    project.should_receive(:new_commits).and_return(new_commits)
    project.tip_commits
  end
end

Given(/^the project holds tips$/) do
  @current_project.update(hold_tips: true)
end

Then(/^there should be no tip for commit "(.*?)"$/) do |arg1|
  Tip.where(commit: arg1).to_a.should eq([])
end

Then(/^there should be a tip of "(.*?)" for commit "(.*?)"$/) do |arg1, arg2|
  amount = Tip.find_by(commit: arg2).amount
  amount.should_not be_nil
  (amount.to_d / 1e8).should eq(arg1.to_d)
end

Then(/^the tip amount for commit "(.*?)" should be undecided$/) do |arg1|
  Tip.find_by(commit: arg1).undecided?.should eq(true)
end

When(/^I choose the amount "(.*?)" on commit "(.*?)"$/) do |arg1, arg2|
  within find(".decide-tip-amounts-table tbody tr", text: arg2) do
    choose arg1
  end
end

When(/^I choose the amount "(.*?)" on all commits$/) do |arg1|
  all(".decide-tip-amounts-table tbody tr").each do |tr|
    within tr do
      choose arg1
    end
  end
end

When(/^I send a forged request to enable tip holding on the project$/) do
  page.driver.browser.process_and_follow_redirects(:patch, project_path(@current_project), project: {hold_tips: "1"})
end

Then(/^I should see an access denied$/) do
  page.should have_content("You are not authorized to perform this action!")
end

Then(/^the project should not hold tips$/) do
  @current_project.reload.hold_tips.should eq(false)
end

Then(/^the project should hold tips$/) do
  @current_project.reload.hold_tips.should eq(true)
end

Given(/^the project has undecided tips$/) do
  # NOTE: these are attributed to the first collaborator of the @current_project
  #           which will result in a User instantiated if none exists
  #       this user's password will be changed to default_password
  #       this step must be preceeded by step "the project syncs with the remote repo"
  #           which itself must be preceeded by step "a '...' project named '...' exists"
  #           and then by step "the project collaborators are:"
  raise "no project exists"        if @current_project.nil?
  raise "no project collaborators" if @current_project.collaborators.blank?

  collaborator_name = @current_project.collaborators.first.login
  user              = @users[collaborator_name]
  user.password     = default_password
  provider          = project_provider @current_project

  create :undecided_tip , :project => @current_project , :user => user
  @current_project.reload.should have_undecided_tips
end

Given(/^the project has (\d+) undecided tip$/) do |n_tips|
  raise "no project exists" if @current_project.nil?

  @current_project.tips.undecided.each &:destroy
  n_tips.to_i.times { step "the project has undecided tips" }
end

Then(/^the project should have (\d+) undecided tips$/) do |arg1|
  @current_project.tips.undecided.size.should eq(arg1.to_i)
end

Given(/^I send a forged request to set the amount of the first undecided tip of the project$/) do
print "step 'I send a forged request' tips=#{@current_project.tips.undecided.to_yaml}\n" if DBG
  tip = @current_project.tips.undecided.first
  tip.should_not be_nil
  params = {
    project: {
      tips_attributes: {
        "0" => {
          id: tip.id,
          amount_percentage: "5",
        },
      },
    },
  }

  page.driver.browser.process_and_follow_redirects(:patch, decide_tip_amounts_project_path(@current_project), params)
end

When(/^I send a forged request to change the percentage of commit "(.*?)" to "(.*?)"$/) do |commit , percentage|
  tip = @current_project.tips.detect { |t| t.commit == commit }
  tip.should_not be_nil
  params = {
    project: {
      tips_attributes: {
        "0" => {
          id: tip.id,
          amount_percentage: percentage,
        },
      },
    },
  }

  path = decide_tip_amounts_project_path @current_project
  page.driver.browser.process_and_follow_redirects :patch , path , params
end
