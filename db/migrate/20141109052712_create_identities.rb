class CreateIdentities < ActiveRecord::Migration
  def change
    create_table :identities do |t|
      t.string  :nickname , :null => false
      t.string  :email ,    :null => false
      t.integer :user_id ,  :null => false
      t.string  :type

      t.timestamps
    end

    add_index :identities , :nickname
    add_index :identities , :email
    add_index :identities , :user_id
  end
end
