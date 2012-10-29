class AddTitleIndexToSanSubject < ActiveRecord::Migration
  def self.up
    add_index :san_subjects, :title, {:name=> "title_index", :unique=>true}
  end

  def self.down
    remove_index :san_subjects, :title
  end
end
