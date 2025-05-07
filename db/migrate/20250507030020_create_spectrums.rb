class CreateSpectrums < ActiveRecord::Migration[8.0]
  def change
    create_table :spectrums do |t|
      t.string :name, null: false
      t.text :description
      t.string :low_label, default: 'Low'
      t.string :high_label, default: 'High'

      t.timestamps
    end
    
    add_index :spectrums, :name, unique: true
  end
end
