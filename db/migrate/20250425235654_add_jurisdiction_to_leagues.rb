class AddJurisdictionToLeagues < ActiveRecord::Migration[8.0]
  def change
    add_reference :leagues, :jurisdiction, polymorphic: true, null: true
  end
end
