# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_05_07_030100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "aces", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_aces_on_confirmation_token", unique: true
    t.index ["email"], name: "index_aces_on_email", unique: true
    t.index ["reset_password_token"], name: "index_aces_on_reset_password_token", unique: true
  end

  create_table "achievements", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["target_type", "target_id"], name: "index_achievements_on_target"
  end

  create_table "cities", force: :cascade do |t|
    t.string "name"
    t.bigint "state_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state_id"], name: "index_cities_on_state_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "federations", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.text "description"
    t.string "url"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "goals", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.bigint "quest_id", null: false
    t.string "status"
    t.integer "progress"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id"], name: "index_goals_on_ace_id"
    t.index ["quest_id"], name: "index_goals_on_quest_id"
  end

  create_table "highlights", force: :cascade do |t|
    t.bigint "quest_id", null: false
    t.bigint "achievement_id", null: false
    t.integer "position"
    t.boolean "required", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_id"], name: "index_highlights_on_achievement_id"
    t.index ["quest_id", "achievement_id"], name: "index_highlights_on_quest_id_and_achievement_id", unique: true
    t.index ["quest_id"], name: "index_highlights_on_quest_id"
  end

  create_table "leagues", force: :cascade do |t|
    t.bigint "sport_id", null: false
    t.string "name"
    t.string "abbreviation"
    t.string "url"
    t.string "ios_app_url"
    t.integer "year_of_origin"
    t.string "official_rules_url"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jurisdiction_type"
    t.bigint "jurisdiction_id"
    t.index ["jurisdiction_type", "jurisdiction_id"], name: "index_leagues_on_jurisdiction"
    t.index ["sport_id"], name: "index_leagues_on_sport_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "nicknames", default: [], array: true
    t.date "birthdate"
    t.bigint "birth_city_id"
    t.bigint "birth_country_id"
    t.string "current_position"
    t.integer "debut_year"
    t.integer "draft_year"
    t.boolean "active"
    t.text "bio", default: [], array: true
    t.text "photo_urls", default: [], array: true
    t.bigint "team_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["birth_city_id"], name: "index_players_on_birth_city_id"
    t.index ["birth_country_id"], name: "index_players_on_birth_country_id"
    t.index ["team_id"], name: "index_players_on_team_id"
  end

  create_table "positions", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation"
    t.text "description"
    t.bigint "sport_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "sport_id"], name: "index_positions_on_name_and_sport_id", unique: true
    t.index ["sport_id"], name: "index_positions_on_sport_id"
  end

  create_table "quests", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "ratings", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.bigint "spectrum_id", null: false
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.bigint "value", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id", "spectrum_id", "target_type", "target_id"], name: "index_ratings_on_ace_spectrum_and_target", unique: true
    t.index ["ace_id"], name: "index_ratings_on_ace_id"
    t.index ["spectrum_id"], name: "index_ratings_on_spectrum_id"
    t.index ["target_type", "target_id"], name: "index_ratings_on_target"
  end

  create_table "roles", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "position_id", null: false
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["player_id", "position_id"], name: "index_roles_on_player_id_and_position_id", unique: true
    t.index ["player_id", "primary"], name: "index_roles_on_player_id_and_primary"
    t.index ["player_id"], name: "index_roles_on_player_id"
    t.index ["position_id"], name: "index_roles_on_position_id"
  end

  create_table "spectrums", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "low_label", default: "Low"
    t.string "high_label", default: "High"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_spectrums_on_name", unique: true
  end

  create_table "sports", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "stadiums", force: :cascade do |t|
    t.string "name"
    t.bigint "city_id", null: false
    t.integer "capacity"
    t.integer "opened_year"
    t.string "url"
    t.string "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["city_id"], name: "index_stadiums_on_city_id"
  end

  create_table "states", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_states_on_country_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "mascot"
    t.string "territory"
    t.bigint "league_id", null: false
    t.bigint "stadium_id"
    t.integer "founded_year"
    t.string "abbreviation"
    t.string "url"
    t.string "logo_url"
    t.string "primary_color"
    t.string "secondary_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id"], name: "index_teams_on_league_id"
    t.index ["stadium_id"], name: "index_teams_on_stadium_id"
  end

  add_foreign_key "cities", "states"
  add_foreign_key "goals", "aces"
  add_foreign_key "goals", "quests"
  add_foreign_key "highlights", "achievements"
  add_foreign_key "highlights", "quests"
  add_foreign_key "leagues", "sports"
  add_foreign_key "players", "cities", column: "birth_city_id"
  add_foreign_key "players", "countries", column: "birth_country_id"
  add_foreign_key "players", "teams"
  add_foreign_key "positions", "sports"
  add_foreign_key "ratings", "aces"
  add_foreign_key "ratings", "spectrums"
  add_foreign_key "roles", "players"
  add_foreign_key "roles", "positions"
  add_foreign_key "stadiums", "cities"
  add_foreign_key "states", "countries"
  add_foreign_key "teams", "leagues"
  add_foreign_key "teams", "stadiums"
end
