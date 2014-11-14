require 'spec_helper'

describe UsersController do
  describe 'GET #index' do
    let(:subject) { get :index }

    it 'renders index template' do
      expect(subject).to render_template :index
    end

    it 'returns 200 status code' do
      expect(subject.status).to eq 200
    end

    it 'assigns @users' do
      subject
      expect(assigns[:users].name).to eq 'User'
    end
  end

  describe '#show' do
    let(:user)    { create :user , :email => "me@somehost.net" }
    let(:subject) { get :show , :nickname => user.nickname }

    context 'when logged in' do
      login_user

      context 'when user found' do
        context 'when viewing own page' do
          before { allow(user).to receive(:nickname).and_return(@current_user.nickname) }
          it 'renders show template' do
            expect(subject).to render_template :show
          end

          it 'returns 200 status code' do
            expect(subject.status).to eq 200
          end

          it 'assigns @user' do
            subject
            expect(assigns[:user].class)   .to eq User
            expect(assigns[:user].nickname).to eq 'current-user'
          end

          it 'assigns @user_tips' do
            subject
            expect(assigns[:user_tips].class).to eq ActiveRecord::Associations::CollectionProxy::ActiveRecord_Associations_CollectionProxy_Tip
          end

          it 'assigns @recent_tips' do
            subject
            expect(assigns[:recent_tips].class).to eq Array
          end
        end

        context 'when viewing other\'s page' do
          let(:new_user) { create :user , :email => "some-dood@somehost.net" }
          let(:subject)  { get :show, id: new_user.id }

          it 'redirect to users_path' do
            expect(subject).to redirect_to users_path
          end

          it 'sets flash error message' do
            subject
            expect(flash[:error]).to eq('You are not authorized to perform this action!')
          end
        end
      end

      context 'when user not found' do
        context 'by id' do
          let(:subject) { get :show, id: 999999 }

          it 'redirect to users_path' do
            expect(subject).to redirect_to users_path
          end

          it 'sets flash error message' do
            subject
            expect(flash[:error]).to eq('User not found')
          end
        end

        context 'by nickname' do
          let(:subject) { get :show , :nickname => 'unknown-user' }

          it 'redirect to users_path' do
            expect(subject).to redirect_to users_path
          end

          it 'sets flash error message' do
            subject
            expect(flash[:error]).to eq('User not found')
          end
        end
      end
    end

    context 'when not logged in' do
      it 'redirects to login page' do
        expect(subject).to redirect_to new_user_session_path
      end

      it 'sets flash alert message' do
        subject
        expect(flash[:alert]).to eq('You need to sign in or sign up before continuing.')
      end
    end
  end

  describe "routing" do
    it "routes GET /users to User#index" do
      { :get => "/users" }.should route_to(
        :controller => "users" ,
        :action     => "index" )
    end

    it "routes GET /users/1 to User#show" do
      { :get => "/users/1" }.should route_to(
        :controller => "users" ,
        :action     => "show"  ,
        :id         => "1"     )
    end

    it "routes GET /users/login to User#login" do
      { :get => "/users/login" }.should route_to(
        :controller => "users" ,
        :action     => "login" )
    end

    it "routes GET /users/1/tips to Tips#index" do
      { :get => "/users/1/tips" }.should route_to(
        :controller => "tips"  ,
        :action     => "index" ,
        :user_id    => "1"     )
    end
  end

  describe "pretty url routing" do
    let(:user) { create :user , :email => "some-dood@somehost.net" }

    it "regex rejects reserved user paths" do
      # accepted pertty url usernames
      should_accept = [' ' , 'logi' , 'ogin' , 's4c2' , '42x' , 'nick name' , 'some-dood']
      # reserved routes (rejected pertty url usernames)
      should_reject = ['' , '1' , '42']

      accepted = should_accept.select {|ea|  ea =~ /\D+/}
      rejected = should_reject.select {|ea| (ea =~ /\D+/).nil? }
      (accepted.size.should eq should_accept.size) &&
      (rejected.size.should eq should_reject.size)
    end

    it "routes GET /users/:nickname to User#show" do
      { :get => "/users/#{user.nickname}" }.should route_to(
        :controller => "users" ,
        :action     => "show"  ,
        :nickname   => "some-dood"    )
    end

    it "routes GET /users/:nickname/tips to Tips#index" do
      { :get => "/users/#{user.nickname}/tips" }.should route_to(
        :controller => "tips"  ,
        :action     => "index" ,
        :nickname   => "some-dood"    )
    end
  end
end
