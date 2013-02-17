class AddTitleIndexToSanSubject < ActiveRecord::Migration
  def self.up
    add_index :san_subjects, [:title, :kind],  {:name=> "title_kind_index", :unique=>true}
  end

  def self.down
    remove_index :san_subjects, "title_kind_index"
  end
end
