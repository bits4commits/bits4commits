require 'spec_helper'

describe User do
  describe 'display_name' do
    context 'when email and nickname are present and name is present' do
      let(:a_user) { create :user , :email => 'some-dood@example.com' , :nickname => 'dood-mon' , :name => 'dood mon' }

      it 'returns name' do
        expect(a_user.display_name).to eq a_user.name
      end
    end

    context 'when email and nickname are present but name is absent' do
      let(:a_user) { create :user , :email => 'some-dood@example.com' , :nickname => 'dood-mon' }

      it 'returns nickname' do
        expect(a_user.display_name).to eq a_user.nickname
      end
    end

    context 'when email is present but nickname is absent' do
      let(:a_user) { create :user , :email => 'some-dood@example.com' }

      it 'returns name split from email' do
        expect(a_user.display_name).to eq 'some-dood'
      end
    end

    context 'when email is absent' do
      it 'raises exception' do
        expect { create :user }.to raise_exception ActiveRecord::RecordInvalid
      end
    end
  end

  describe 'bitcoin_address' do
    let(:a_user) { create :user , :email => 'some-dood@example.com' }

    context 'when address is blank' do
      it 'should be valid' do
        a_user.bitcoin_address = ''
        a_user.should be_valid
      end
    end

    context 'when address is valid' do
      it 'should be valid' do
        a_user.bitcoin_address = '1M4bS4gPyA6Kb8w7aXsgth9oUZWcRk73tQ'
        a_user.should be_valid
      end
    end

    context 'when address is not valid' do
      it 'should not be valid' do
        a_user.bitcoin_address = '1M4bS4gPyA6Kb8w7aXsgth9oUZXXXXXXXX'
        a_user.should_not be_valid
      end
    end
  end
end
