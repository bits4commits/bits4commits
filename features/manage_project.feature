Feature: Collaborators may manage project
  Background:
    Given a "github" project named "seldon/seldons-project" exists


  Scenario: New projects should show "Pending initial fetch" in place of edit button
    Given I am not signed in
    When  I visit the "seldon/seldons-project github-project" page
    Then  I should be on the "seldon/seldons-project github-project" page
    And   I should see "seldon/seldons-project"
    And   I should see "Pending initial fetch"
    But   I should not see "Change project settings"
    And   I should not see "Decide tip amounts"

    When  the project syncs with the remote repo
    And   I visit the "seldon/seldons-project github-project" page
    Then  I should be on the "seldon/seldons-project github-project" page
    And   I should see "seldon/seldons-project"
    But   I should not see "Pending initial fetch"
    And   I should not see "Change project settings"
    But   I should not see "Decide tip amounts"

  Scenario: Visitors may not manage projects
    Given the project syncs with the remote repo
    And   I am not signed in
    When  I visit the "seldon/seldons-project github-project" page
    Then  I should be on the "seldon/seldons-project github-project" page
    And   I should see "seldon/seldons-project"
    And   I should not see "Pending initial fetch"
    But   I should not see "Change project settings"
    And   I should not see "Decide tip amounts"

    When  I visit the "seldon/seldons-project github-project edit" page
    Then  I should be on the "home" page
    And   I should see "You are not authorized to perform this action"

  Scenario: Non-collaborators should not be able to manage project
    Given the project syncs with the remote repo
    And   the project has undecided tips
    And   I am signed in via "email" as "someone-else"
    When  I visit the "seldon/seldons-project github-project" page
    Then  I should be on the "seldon/seldons-project github-project" page
    And   I should see "seldon/seldons-project"
    But   I should not see "Pending initial fetch"
    And   I should not see "Change project settings"
    And   I should not see "Decide tip amounts"

    When  I visit the "seldon/seldons-project github-project edit" page
    Then  I should be on the "home" page
    And   I should see "You are not authorized to perform this action"

  Scenario: Collaborators must sign in at least once via oauh to manage project
    Given the project syncs with the remote repo
    And   I am signed in via "email" as "seldon"
    When  I visit the "seldon/seldons-project github-project" page
    Then  I should be on the "seldon/seldons-project github-project" page
    And   I should see "seldon/seldons-project"
    And   I should not see "Pending initial fetch"
    But   I should not see "Change project settings"
    And   I should not see "Decide tip amounts"

    Given I sign out
    And   I sign in via "github" as "seldon"
    And   I visit the "seldon/seldons-project github-project" page
    Then  I should be on the "seldon/seldons-project github-project" page
    And   I should see "seldon/seldons-project"
    And   I should see "Change project settings"
    But   I should not see "Pending initial fetch"
    And   I should not see "Decide tip amounts"

    When I click "Change project settings"
    Then I should be on the "seldon/seldons-project github-project edit" page
    And  I should see "seldon/seldons-project project settings"
    When I click "Save the project settings"
    Then I should be on the "seldon/seldons-project github-project" page
    And  I should see "The project settings have been updated"

    When  the project has undecided tips
    And   I visit the "seldon/seldons-project github-project" page
    Then  I should be on the "seldon/seldons-project github-project" page
    And   I should see "seldon/seldons-project"
    But   I should not see "Pending initial fetch"
    And   I should see "Change project settings"
    But   I should see "Decide tip amounts"
