class AddIndex < ActiveRecord::Migration
  def change
    add_index :articles, :name, :unique => true
  end
end
