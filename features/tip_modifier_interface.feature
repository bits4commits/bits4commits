Feature: A project collaborator can change the tips of commits
  Background:
    Given a project
    And the project collaborators are:
      | seldon  |
      | daneel  |
    And our fee is "0"
    And a deposit of "500"
    And the last known commit is "AAA"
    And a new commit "BBB" with parent "AAA"
    And a new commit "CCC" with parent "BBB"
    And the author of commit "BBB" is "yugo"
    And the author of commit "CCC" is "seldon"

  Scenario: Without anything modified
    When the new commits are read
    Then there should be a tip of "5" for commit "BBB"
    And there should be a tip of "4.95" for commit "CCC"
    And there should be 1 email sent

  Scenario: A collaborator wants to alter the tips
    Given I'm logged in as "seldon"
    And I go to the project page
    And I click on "Change project settings"
    And I check "Do not send the tips immediatly. Give collaborators the ability to modify the tips before they're sent"
    And I click on "Save the project settings"
    Then I should see "The project settings have been updated"

    When the new commits are read
    Then the tip amount for commit "BBB" should be undecided
    And the tip amount for commit "CCC" should be undecided
    And there should be 0 email sent

    When I go to the project page
    And I click on "Decide tip amounts"
    Then I should see "BBB"
    And I should see "CCC"
    And I should not see "AAA"

    When I choose the amount "Tiny: 0.1%" on commit "BBB"
    And I click on "Send the selected tip amounts"
    Then there should be a tip of "0.5" for commit "BBB"
    And the tip amount for commit "CCC" should be undecided
    And there should be 1 email sent

    When the email counters are reset
    And I choose the amount "Free: 0%" on commit "CCC"
    And I click on "Send the selected tip amounts"
    Then there should be a tip of "0.5" for commit "BBB"
    And there should be a tip of "0" for commit "CCC"
    And there should be 0 email sent

