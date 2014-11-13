class CreateIdentities < ActiveRecord::Migration
  def change
    create_table :identities do |t|
      t.string  :nickname
      t.string  :email
      t.string  :type
      t.integer :user_id

      t.timestamps
    end

    add_index :identities , :nickname
    add_index :identities , :email
    add_index :identities , :user_id
  end
end
