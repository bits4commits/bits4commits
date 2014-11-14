Before do
  ActionMailer::Base.deliveries.clear

  # mock branches method to prevent api call
  Project.any_instance.stub(:branches).and_return(%w(master))

  # preload sti models
  load File.join "app","models","identity.rb"

  @default_tip     = CONFIG["tip"]
  @default_our_fee = CONFIG["our_fee"]
  @default_min_tip = CONFIG["min_tip"]
end

After do |scenario|
  OmniAuth.config.test_mode = false
  User.omniauth_providers.each {|provider| OmniAuth.config.mock_auth.delete provider }

  CONFIG["tip"]     = @default_tip
  CONFIG["our_fee"] = @default_our_fee
  CONFIG["min_tip"] = @default_min_tip

  Cucumber.wants_to_quit = true if scenario.status.eql? :failed
  Cucumber.wants_to_quit = true if scenario.status.eql? :undefined
#   Cucumber.wants_to_quit = true if scenario.status.eql? :pending
end

def sign_in_via_email nickname
  step "a developer named \"#{nickname}\" exists with a bitcoin address"
  step "I am not signed in"
  step "I visit the \"sign_in\" page"
  step "I fill \"E-mail\" with: \"#{make_primary_email nickname}\""
  step "I fill \"Password\" with: \"#{default_password}\""
  step "I click \"Sign in\""
end

Given /^I am signed in via "(.*?)" as "(.*?)"$/ do |provider , nickname|
p "step 'I am signed in via \"#{provider}\" as \"#{nickname}\"'  IN=#{User.count} users" if ENV['DEBUG']

  is_email_sign_in  = provider.downcase.eql? 'email'

  # NOTE: scenarios that click oauth links directly will have no entry in test @users
  step "a developer named \"#{nickname}\" exists without a bitcoin address"

  (step "I confirm the email address: \"#{make_primary_email nickname}\"") rescue true
  step "I am signed in to \"#{provider}\" as \"#{nickname}\"" unless is_email_sign_in
  step "I visit the \"sign_in\" page"

  case provider.downcase
  when 'email' ;     sign_in_via_email nickname ;        flash = "Signed in successfully" ;
  when 'github' ;    click_on "Sign in with GitHub" ;    flash = "Successfully authenticated" ;
  when 'bitbucket' ; click_on "Sign in with BitBucket" ; flash = "Successfully authenticated" ;
  else fail "unknown sign in option \"#{provider}\""
  end

user = User.find_by :nickname => nickname ; print "step 'I am signed in via \"#{provider}\" as \"#{nickname}\"' OUT=#{User.count} users\n\ttip4commit_identity=#{user.tip4commit_identity.present?}\n\tgithub_identity=#{user.github_identity.present?}\n\tbitbucket_identity=#{user.bitbucket_identity.present?}\n" if ENV['DEBUG']

  page.should have_content flash
end
=begin
Given /^I'm signed in as "(.*?)"$/ do |nickname|
  step "I am signed in via \"email\" as \"#{nickname}\""
#=begin
p "step 'I'm signed in as'  IN=#{nickname} #{User.count} users"
# TODO: IS refactored to allow email (default) github and bitbucket sign-in
#    transition to step "I am signed in via \"email\" as \"#{nickname}\""

  mock_oauth_user :github , nickname
  visit root_path
  first(:link, "Sign in").click
  click_on "Sign in with GitHub"

p "step 'I'm signed in as' OUT=#{nickname} #{User.count} users"

  page.should have_content("Successfully authenticated")
#=end
end
=end
Given /^I am not signed in$/ do
p "step 'I sign out'=#{User.count} users" if ENV['DEBUG']

  visit root_path
  if page.has_content?("Sign out")
    click_on "Sign out"
    page.should have_content("Signed out successfully")
  else
    page.should have_content("Sign in")
  end

  OmniAuth.config.test_mode = false
end

Given /^I sign in via "(.*?)" as "(.*?)"$/ do |provider , nickname|
  step "I am signed in via \"#{provider}\" as \"#{nickname}\""
end

Given (/^I sign out$/) { step "I am not signed in" }

def parse_path_from_page_string page_string
  path = nil

  # explicit cases
  # e.g. "a-user/a-project github-project edit"
  # e.g. "a-user user edit"
  tokens     = page_string.split ' '
  name       = tokens[0]
  model      = tokens[1]
  action     = tokens[2] || '' # '' => 'show'
  is_user    = model.eql? 'user'
  is_project = ['github-project' , 'bitbucket-project'].include? model
  if is_project
    projects_paths = ['' , 'edit' , 'decide_tip_amounts' , 'tips' , 'deposits']
    is_valid_path  = projects_paths.include? action
    service        = model.split('-').first
    path           = "/#{service}/#{name}/#{action}" if is_valid_path
  elsif is_user
    user_paths     = ['' , 'tips']
    is_valid_path  = user_paths.include? action
    path           = "/users/#{name}/#{action}" if is_valid_path # TODO: nyi

  # implicit cases
  else case page_string
    when 'home' ;            path = root_path ;
    when 'sign_up' ;         path = new_user_registration_path ;
    when 'sign_in' ;         path = new_user_session_path ;
    when 'users' ;           path = users_path ;
    when 'projects' ;        path = projects_path ;
    when 'search' ;          path = search_projects_path ;
    when 'tips' ;            path = tips_path ;
    when 'deposits' ;        path = deposits_path ;
    when 'withdrawals' ;     path = withdrawals_path ;
    end
  end

  path || (raise "unknown page")
end

Given(/^I visit the "(.*?)" page$/) do |page_string|
  visit parse_path_from_page_string page_string
end

Given(/^I browse to the explicit path "(.*?)"$/) do |url|
  visit url
end

Then(/^I should be on the "(.*?)" page$/) do |page_string|
  expected = parse_path_from_page_string page_string rescue expected = page_string
  actual   = page.current_path

  expected.chop! if (expected.end_with? '/') && (expected.size > 1)
  actual  .chop! if (actual  .end_with? '/') && (actual  .size > 1)

  actual.should eq expected
end

def find_element node_name
  case node_name
  when "header" ; page.find '.masthead'
  end
end

Given(/^I click "(.*?)"$/) do |arg1|
  click_on(arg1)
end

Given(/^I click "(.*?)" within the "(.*?)" area$/) do |link_text , node_name|
  within (find_element node_name) { click_on link_text }
end

Given(/^I check "(.*?)"$/) do |arg1|
  check(arg1)
end

Then(/^I should see "(.*?)"$/) do |arg1|
  page.should have_content(arg1)
end

Then(/^I should not see "(.*?)"$/) do |arg1|
  page.should have_no_content(arg1)
end

Given(/^I fill "(.*?)" with:$/) do |arg1, string|
  fill_in arg1, with: string
end

Given(/^I fill "(.*?)" with: "(.*?)"$/) do |text_field, string|
  fill_in text_field, with: string
end

Then(/^there should be (\d+) email sent$/) do |arg1|
  ActionMailer::Base.deliveries.size.should eq(arg1.to_i)
end

When(/^the email counters are reset$/) do
  ActionMailer::Base.deliveries.clear
end

When(/^I confirm the email address: "(.*?)"$/) do |email|
  this_mail = ActionMailer::Base.deliveries.select {|ea| ea.to.first.eql? email}.first
  (ActionMailer::Base.deliveries.delete this_mail) || (raise "no confirmation pending for \"#{email}\"")

  mail_body = this_mail.body.raw_source
  token     = mail_body.split('?confirmation_token=')[1].split('">Confirm my account').first
  visit "/users/confirmation?confirmation_token=#{token}"
end
