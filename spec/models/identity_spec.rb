require 'spec_helper'

describe Identity do
  context "should be an abstract class" do
    let(:a_user) { create :user , :email => 'some-dood@somehost.net' }

    it "requires type attribute" do
      (Identity.new :nickname => "some-dood" ,
                    :email    => "some-dood@somehost.net" ,
                    :user_id     => a_user.id).should_not be_valid
    end

    it "requires type attribute to match a subclass" do
      expect {Identity.new :nickname => "some-dood" ,
                           :email    => "some-dood@somehost.net" ,
                           :user_id     => a_user.id ,
                           :type     => "UnknownClassName"}.to raise_exception ActiveRecord::SubclassNotFound
    end

    it "allows subclass instantiation only" do
      (Identity.new :nickname => "some-dood" ,
                    :email    => "some-dood@somehost.net" ,
                    :user_id     => a_user.id ,
                    :type     => "GithubIdentity").should be_valid
    end

    it "should have not valid factory" do
      expect {FactoryGirl.build :identity ,
                                :nickname => "some-dood" ,
                                :email    => "some-dood@somehost.net" ,
                                :user_id     => a_user.id}.to raise_exception ArgumentError
    end
  end
end

describe Tip4commitIdentity do
  let(:a_user)       { create :user , :email => 'some-dood@somehost.net' }
  let(:another_user) { create :user , :email => 'some-other-dood@somehost.net' }

  it "should be created automatically for each user" do
    a_user.tip4commit_identity.class.should eq Tip4commitIdentity
  end

  it "should have valid factory" do
    (FactoryGirl.build :tip4commit_identity ,
                       :nickname => 'another_user.nickname' ,
                       :email    => 'another_user.email' ,
                       :user_id     => 42).should be_valid
  end
end

shared_context 'testing_subclass' do |a_class , factory_symbol|
  let(:a_user) { create :user , :email => 'some-dood@somehost.net' }

  it "should require a nickname" do
    (a_class.new :nickname => "" ,
                 :email    => "some-dood@somehost.net" ,
                 :user_id     => a_user.id).should_not be_valid
  end

  it "should require an email" do
    (a_class.new :nickname => "some-dood" ,
                 :email    => "" ,
                 :user_id     => a_user.id).should_not be_valid
  end

  it "should require a User" do
    (a_class.new :nickname => "some-dood" ,
                 :email    => "some-dood@somehost.net" ,
                 :user_id     => nil).should_not be_valid
  end

  it "should be valid with valid params" do
    (a_class.new :nickname => "some-dood" ,
                 :email    => "some-dood@somehost.net" ,
                 :user_id     => a_user.id).should be_valid
  end

  it "should have valid factory" do
    (FactoryGirl.build factory_symbol ,
                       :nickname => "some-dood" ,
                       :email    => "some-dood@somehost.net" ,
                       :user_id     => a_user.id).should be_valid
  end
end

describe GithubIdentity do
  include_context 'testing_subclass' , GithubIdentity , :github_identity
end

describe BitbucketIdentity do
  include_context 'testing_subclass' , BitbucketIdentity , :bitbucket_identity
end
