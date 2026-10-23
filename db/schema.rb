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

ActiveRecord::Schema[8.1].define(version: 2026_10_23_010000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
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
    t.boolean "admin", default: false, null: false
    t.boolean "moderator", default: false, null: false
    t.string "theme", default: "system", null: false
    t.string "username"
    t.string "display_name"
    t.string "avatar_color", default: "#7A4B2A", null: false
    t.string "time_zone"
    t.index "lower((username)::text)", name: "index_aces_on_lower_username", unique: true
    t.index ["confirmation_token"], name: "index_aces_on_confirmation_token", unique: true
    t.index ["email"], name: "index_aces_on_email", unique: true
    t.index ["reset_password_token"], name: "index_aces_on_reset_password_token", unique: true
    t.check_constraint "theme::text = ANY (ARRAY['light'::character varying, 'dark'::character varying, 'system'::character varying]::text[])", name: "aces_theme"
  end

  create_table "achievements", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.json "details"
    t.string "moderation_status", default: "approved", null: false
    t.integer "moderation_revision", default: 1, null: false
    t.bigint "created_by_id"
    t.integer "lock_version", default: 0, null: false
    t.index ["created_by_id"], name: "index_achievements_on_created_by_id"
    t.index ["moderation_status", "created_at"], name: "index_achievements_on_moderation_status_and_created_at"
    t.index ["seed_version"], name: "index_achievements_on_seed_version"
    t.index ["target_type", "target_id"], name: "index_achievements_on_target"
    t.check_constraint "moderation_status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'hidden'::character varying]::text[])", name: "achievements_moderation_status"
  end

  create_table "activations", force: :cascade do |t|
    t.bigint "contract_id"
    t.bigint "campaign_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.json "details"
    t.string "seed_version"
    t.datetime "last_seeded_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "player_id", null: false
    t.string "entity_code"
    t.index ["campaign_id"], name: "index_activations_on_campaign_id"
    t.index ["contract_id"], name: "index_activations_on_contract_id"
    t.index ["entity_code"], name: "index_activations_on_entity_code", unique: true
    t.index ["player_id", "campaign_id"], name: "index_activations_on_player_id_and_campaign_id", unique: true
    t.index ["player_id"], name: "index_activations_on_player_id"
  end

  create_table "appearances", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "contestant_id", null: false
    t.bigint "stint_id"
    t.boolean "starter"
    t.string "jersey_number"
    t.jsonb "statistics", default: {}, null: false
    t.jsonb "source", default: {}, null: false
    t.jsonb "details", default: {}, null: false
    t.string "entity_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contestant_id", "player_id"], name: "index_appearances_on_contestant_id_and_player_id", unique: true
    t.index ["contestant_id"], name: "index_appearances_on_contestant_id"
    t.index ["entity_code"], name: "index_appearances_on_entity_code", unique: true
    t.index ["player_id"], name: "index_appearances_on_player_id"
    t.index ["stint_id"], name: "index_appearances_on_stint_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "season_id", null: false
    t.text "comments", default: [], comment: "Array of comments about the campaign", array: true
    t.string "seed_version", comment: "Version when this record was seeded"
    t.datetime "last_seeded_at", comment: "When this record was last seeded"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "display_name"
    t.string "territory"
    t.string "mascot"
    t.string "abbreviation"
    t.string "logo_url"
    t.string "primary_color"
    t.string "secondary_color"
    t.bigint "stadium_id"
    t.bigint "city_id"
    t.bigint "conference_id"
    t.bigint "division_id"
    t.jsonb "details", default: {}, null: false
    t.string "entity_code"
    t.index ["city_id"], name: "index_campaigns_on_city_id"
    t.index ["conference_id"], name: "index_campaigns_on_conference_id"
    t.index ["division_id"], name: "index_campaigns_on_division_id"
    t.index ["entity_code"], name: "index_campaigns_on_entity_code", unique: true
    t.index ["season_id"], name: "index_campaigns_on_season_id"
    t.index ["stadium_id"], name: "index_campaigns_on_stadium_id"
    t.index ["team_id", "season_id"], name: "index_campaigns_on_team_id_and_season_id", unique: true
    t.index ["team_id"], name: "index_campaigns_on_team_id"
  end

  create_table "cities", force: :cascade do |t|
    t.string "name"
    t.bigint "state_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "entity_code"
    t.index ["entity_code"], name: "index_cities_on_entity_code", unique: true
    t.index ["seed_version"], name: "index_cities_on_seed_version"
    t.index ["state_id"], name: "index_cities_on_state_id"
  end

  create_table "conferences", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.string "logo_url"
    t.bigint "league_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "entity_code"
    t.index ["entity_code"], name: "index_conferences_on_entity_code", unique: true
    t.index ["league_id"], name: "index_conferences_on_league_id"
    t.index ["seed_version"], name: "index_conferences_on_seed_version"
  end

  create_table "contestants", force: :cascade do |t|
    t.bigint "contest_id", null: false
    t.bigint "campaign_id", null: false
    t.integer "placing"
    t.integer "wins"
    t.integer "losses"
    t.json "tiebreakers"
    t.string "seed_version"
    t.datetime "last_seeded_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "entity_code"
    t.index ["campaign_id"], name: "index_contestants_on_campaign_id"
    t.index ["contest_id", "campaign_id"], name: "index_contestants_on_contest_id_and_campaign_id", unique: true
    t.index ["contest_id"], name: "index_contestants_on_contest_id"
    t.index ["entity_code"], name: "index_contestants_on_entity_code", unique: true
  end

  create_table "contests", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "context_type", null: false
    t.bigint "context_id", null: false
    t.date "begin_date"
    t.date "end_date"
    t.integer "champion_id"
    t.bigint "season_id"
    t.text "comments"
    t.json "details"
    t.string "seed_version"
    t.datetime "last_seeded_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "entity_code"
    t.string "kind"
    t.index ["context_type", "context_id"], name: "index_contests_on_context"
    t.index ["entity_code"], name: "index_contests_on_entity_code", unique: true
    t.index ["kind", "begin_date"], name: "index_contests_on_kind_and_begin_date"
    t.index ["season_id"], name: "index_contests_on_season_id"
  end

  create_table "contracts", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "team_id"
    t.date "start_date"
    t.date "end_date"
    t.decimal "total_dollar_value"
    t.json "details"
    t.string "seed_version"
    t.datetime "last_seeded_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "entity_code"
    t.bigint "organization_id", null: false
    t.index ["entity_code"], name: "index_contracts_on_entity_code", unique: true
    t.index ["organization_id"], name: "index_contracts_on_organization_id"
    t.index ["player_id"], name: "index_contracts_on_player_id"
    t.index ["team_id"], name: "index_contracts_on_team_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "flag_url"
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "entity_code"
    t.index ["entity_code"], name: "index_countries_on_entity_code", unique: true
    t.index ["seed_version"], name: "index_countries_on_seed_version"
  end

  create_table "credit_accounts", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.bigint "available_cents", default: 0, null: false
    t.bigint "reserved_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id"], name: "index_credit_accounts_on_ace_id", unique: true
    t.check_constraint "available_cents >= 0 AND reserved_cents >= 0", name: "credit_nonnegative"
  end

  create_table "credit_entries", force: :cascade do |t|
    t.bigint "credit_account_id", null: false
    t.string "source_type", null: false
    t.bigint "source_id", null: false
    t.string "operation_key", null: false
    t.string "kind", null: false
    t.bigint "available_delta", null: false
    t.bigint "reserved_delta", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credit_account_id"], name: "index_credit_entries_on_credit_account_id"
    t.index ["operation_key"], name: "index_credit_entries_on_operation_key", unique: true
    t.index ["source_type", "source_id"], name: "index_credit_entries_on_source"
  end

  create_table "decision_evaluations", force: :cascade do |t|
    t.string "subject_type"
    t.bigint "subject_id"
    t.integer "revision"
    t.string "comparison_key", null: false
    t.string "provider", null: false
    t.string "model", null: false
    t.string "purpose", null: false
    t.string "policy_version", null: false
    t.string "status", default: "queued", null: false
    t.string "choice"
    t.string "error_code"
    t.jsonb "request_snapshot", default: {}, null: false
    t.jsonb "answer", default: {}, null: false
    t.bigint "input_tokens"
    t.decimal "input_usd_per_million", precision: 12, scale: 6, null: false
    t.decimal "estimated_usd", precision: 20, scale: 10
    t.integer "latency_ms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["comparison_key", "provider"], name: "index_decision_evaluations_on_comparison_key_and_provider", unique: true
    t.index ["subject_type", "subject_id"], name: "index_decision_evaluations_on_subject"
  end

  create_table "divisions", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.string "logo_url"
    t.bigint "conference_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "entity_code"
    t.index ["conference_id"], name: "index_divisions_on_conference_id"
    t.index ["entity_code"], name: "index_divisions_on_entity_code", unique: true
    t.index ["seed_version"], name: "index_divisions_on_seed_version"
  end

  create_table "entity_codes", force: :cascade do |t|
    t.string "namespace", null: false
    t.string "catalog", null: false
    t.string "code", null: false
    t.string "canonical_code", null: false
    t.string "record_type"
    t.bigint "record_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["namespace", "catalog", "canonical_code"], name: "index_entity_codes_on_namespace_and_catalog_and_canonical_code"
    t.index ["namespace", "catalog", "code"], name: "index_entity_codes_on_namespace_and_catalog_and_code", unique: true
    t.index ["record_type", "record_id"], name: "index_entity_codes_on_record"
  end

  create_table "federations", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.text "description"
    t.string "url"
    t.string "logo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.index ["seed_version"], name: "index_federations_on_seed_version"
  end

  create_table "follows", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.string "followable_type", null: false
    t.bigint "followable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id", "followable_type", "followable_id"], name: "index_follows_on_ace_id_and_followable_type_and_followable_id", unique: true
    t.index ["ace_id"], name: "index_follows_on_ace_id"
    t.index ["followable_type", "followable_id"], name: "index_follows_on_followable"
    t.check_constraint "followable_type::text = ANY (ARRAY['Team'::character varying, 'Player'::character varying]::text[])", name: "follows_supported_type"
  end

  create_table "game_attempts", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.string "game_type", null: false
    t.string "subject_entity_type", null: false
    t.bigint "subject_entity_id", null: false
    t.string "target_entity_type", null: false
    t.bigint "target_entity_id", null: false
    t.jsonb "options_presented", default: [], null: false
    t.string "chosen_entity_type"
    t.bigint "chosen_entity_id"
    t.boolean "is_correct", null: false
    t.integer "time_elapsed_ms", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "difficulty_level"
    t.bigint "game_round_id"
    t.integer "round_position"
    t.index ["ace_id"], name: "index_game_attempts_on_ace_id"
    t.index ["chosen_entity_type", "chosen_entity_id"], name: "index_game_attempts_on_chosen_entity"
    t.index ["game_round_id", "round_position"], name: "index_game_attempts_on_game_round_id_and_round_position", unique: true
    t.index ["game_round_id"], name: "index_game_attempts_on_game_round_id"
    t.index ["subject_entity_type", "subject_entity_id"], name: "index_game_attempts_on_subject_entity"
    t.index ["target_entity_type", "target_entity_id"], name: "index_game_attempts_on_target_entity"
    t.check_constraint "game_round_id IS NULL AND round_position IS NULL OR game_round_id IS NOT NULL AND round_position >= 0", name: "game_attempt_round_position"
  end

  create_table "game_rounds", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.string "game_type", null: false
    t.integer "length", null: false
    t.jsonb "scope", default: {}, null: false
    t.string "scope_label", null: false
    t.jsonb "questions", default: [], null: false
    t.integer "position", default: 0, null: false
    t.datetime "started_at", null: false
    t.datetime "finished_at"
    t.datetime "paused_at"
    t.datetime "question_started_at"
    t.integer "question_elapsed_ms", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "newly_known_player_ids", default: [], null: false
    t.index ["ace_id"], name: "index_game_rounds_on_ace_id"
    t.check_constraint "length >= 1 AND length <= 30 AND \"position\" >= 0 AND \"position\" <= length", name: "game_round_progress"
  end

  create_table "goal_achievements", force: :cascade do |t|
    t.bigint "goal_id", null: false
    t.bigint "achievement_id", null: false
    t.jsonb "player_ids", default: [], null: false
    t.jsonb "required_player_ids", default: [], null: false
    t.jsonb "practice_scope", default: {}, null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["achievement_id"], name: "index_goal_achievements_on_achievement_id"
    t.index ["goal_id", "achievement_id"], name: "index_goal_achievements_on_goal_id_and_achievement_id", unique: true
    t.index ["goal_id"], name: "index_goal_achievements_on_goal_id"
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
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "moderation_status", default: "approved", null: false
    t.integer "moderation_revision", default: 1, null: false
    t.bigint "created_by_id"
    t.integer "lock_version", default: 0, null: false
    t.index ["achievement_id"], name: "index_highlights_on_achievement_id"
    t.index ["created_by_id"], name: "index_highlights_on_created_by_id"
    t.index ["moderation_status", "created_at"], name: "index_highlights_on_moderation_status_and_created_at"
    t.index ["quest_id", "achievement_id"], name: "index_highlights_on_quest_id_and_achievement_id", unique: true
    t.index ["quest_id"], name: "index_highlights_on_quest_id"
    t.index ["seed_version"], name: "index_highlights_on_seed_version"
    t.check_constraint "moderation_status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'hidden'::character varying]::text[])", name: "highlights_moderation_status"
  end

  create_table "jersey_number_assignments", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "team_id", null: false
    t.string "number", null: false
    t.date "start_date"
    t.date "end_date"
    t.jsonb "source", default: {}, null: false
    t.jsonb "details", default: {}, null: false
    t.string "entity_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_code"], name: "index_jersey_number_assignments_on_entity_code", unique: true
    t.index ["player_id"], name: "index_jersey_number_assignments_on_player_id"
    t.index ["team_id"], name: "index_jersey_number_assignments_on_team_id"
    t.check_constraint "number::text ~ '^[0-9]{1,3}$'::text", name: "jersey_numbers_are_numeric_strings"
    t.check_constraint "start_date IS NULL OR end_date IS NULL OR end_date >= start_date", name: "jersey_numbers_have_ordered_dates"
    t.exclusion_constraint "player_id WITH =, team_id WITH =, daterange(start_date, end_date, '[]'::text) WITH &&", using: :gist, name: "jersey_numbers_do_not_overlap"
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
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "entity_code"
    t.index ["entity_code"], name: "index_leagues_on_entity_code", unique: true
    t.index ["jurisdiction_type", "jurisdiction_id"], name: "index_leagues_on_jurisdiction"
    t.index ["seed_version"], name: "index_leagues_on_seed_version"
    t.index ["sport_id"], name: "index_leagues_on_sport_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "division_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.index ["division_id"], name: "index_memberships_on_division_id"
    t.index ["seed_version"], name: "index_memberships_on_seed_version"
    t.index ["team_id"], name: "index_memberships_on_team_id"
  end

  create_table "moderation_decisions", force: :cascade do |t|
    t.string "subject_type", null: false
    t.bigint "subject_id", null: false
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "from_status"
    t.string "to_status", null: false
    t.integer "revision", null: false
    t.text "reason"
    t.jsonb "snapshot", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["actor_id"], name: "index_moderation_decisions_on_actor_id"
    t.index ["created_at", "id"], name: "index_moderation_decisions_on_created_at_and_id"
    t.index ["subject_type", "subject_id"], name: "index_moderation_decisions_on_subject"
  end

  create_table "moderation_escalations", force: :cascade do |t|
    t.string "subject_type", null: false
    t.bigint "subject_id", null: false
    t.bigint "subject_ace_id"
    t.bigint "requested_by_id"
    t.string "subject_name", null: false
    t.text "reason", null: false
    t.jsonb "snapshot", default: {}, null: false
    t.integer "revision"
    t.string "captured_status"
    t.string "request_key", limit: 128, null: false
    t.string "resolution"
    t.text "resolution_reason"
    t.bigint "resolved_by_id"
    t.datetime "resolved_at"
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["requested_by_id", "request_key"], name: "unique_escalation_request", unique: true
    t.index ["requested_by_id"], name: "index_moderation_escalations_on_requested_by_id"
    t.index ["resolved_at", "created_at", "id"], name: "idx_on_resolved_at_created_at_id_b4f1098179"
    t.index ["resolved_by_id"], name: "index_moderation_escalations_on_resolved_by_id"
    t.index ["subject_ace_id"], name: "index_moderation_escalations_on_subject_ace_id"
    t.index ["subject_type", "subject_id"], name: "index_moderation_escalations_on_subject"
    t.index ["subject_type", "subject_id"], name: "one_open_escalation_per_subject", unique: true, where: "(resolved_at IS NULL)"
  end

  create_table "moderator_notes", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.bigint "moderator_id"
    t.text "body", null: false
    t.string "request_key", limit: 128, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id", "request_key"], name: "index_moderator_notes_on_ace_id_and_request_key", unique: true
    t.index ["ace_id"], name: "index_moderator_notes_on_ace_id"
    t.index ["moderator_id"], name: "index_moderator_notes_on_moderator_id"
  end

  create_table "mutes", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.bigint "moderator_id"
    t.string "reason", limit: 2000, null: false
    t.text "note"
    t.integer "duration_hours", null: false
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.bigint "hidden_shout_out_id"
    t.string "request_key", limit: 128, null: false
    t.datetime "ended_at"
    t.bigint "ended_by_id"
    t.string "end_reason", limit: 2000
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id", "ends_at"], name: "index_mutes_on_ace_id_and_ends_at"
    t.index ["ace_id", "request_key"], name: "index_mutes_on_ace_id_and_request_key", unique: true
    t.index ["ace_id"], name: "index_mutes_on_ace_id"
    t.index ["ended_by_id"], name: "index_mutes_on_ended_by_id"
    t.index ["hidden_shout_out_id"], name: "index_mutes_on_hidden_shout_out_id"
    t.index ["moderator_id"], name: "index_mutes_on_moderator_id"
    t.check_constraint "(duration_hours = ANY (ARRAY[24, 168, 720])) AND ends_at > starts_at", name: "valid_posting_mute_duration"
  end

  create_table "organization_affiliations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "team_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.json "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "entity_code"
    t.index ["entity_code"], name: "index_organization_affiliations_on_entity_code", unique: true
    t.index ["organization_id", "team_id", "start_date"], name: "index_org_affiliations_on_org_team_start", unique: true
    t.index ["organization_id"], name: "index_organization_affiliations_on_organization_id"
    t.index ["team_id"], name: "index_organization_affiliations_on_team_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation"
    t.text "description"
    t.string "url"
    t.string "logo_url"
    t.integer "founded_year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "entity_code"
    t.index ["entity_code"], name: "index_organizations_on_entity_code", unique: true
  end

  create_table "player_group_memberships", force: :cascade do |t|
    t.bigint "player_group_id", null: false
    t.bigint "player_id", null: false
    t.string "entity_code"
    t.jsonb "source", default: {}, null: false
    t.jsonb "details", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_code"], name: "index_player_group_memberships_on_entity_code", unique: true
    t.index ["player_group_id", "player_id"], name: "idx_on_player_group_id_player_id_f1ff3bc069", unique: true
    t.index ["player_group_id"], name: "index_player_group_memberships_on_player_group_id"
    t.index ["player_id"], name: "index_player_group_memberships_on_player_id"
  end

  create_table "player_groups", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "entity_code"
    t.jsonb "source", default: {}, null: false
    t.jsonb "details", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_code"], name: "index_player_groups_on_entity_code", unique: true
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
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.bigint "sport_id"
    t.string "entity_code"
    t.index ["birth_city_id"], name: "index_players_on_birth_city_id"
    t.index ["birth_country_id"], name: "index_players_on_birth_country_id"
    t.index ["entity_code"], name: "index_players_on_entity_code", unique: true
    t.index ["seed_version"], name: "index_players_on_seed_version"
    t.index ["sport_id"], name: "index_players_on_sport_id"
    t.index ["team_id"], name: "index_players_on_team_id"
  end

  create_table "positions", force: :cascade do |t|
    t.string "name", null: false
    t.string "abbreviation"
    t.text "description"
    t.bigint "sport_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.index ["name", "sport_id"], name: "index_positions_on_name_and_sport_id", unique: true
    t.index ["seed_version"], name: "index_positions_on_seed_version"
    t.index ["sport_id"], name: "index_positions_on_sport_id"
  end

  create_table "practice_reviews", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.string "game_type", null: false
    t.string "subject_type", null: false
    t.bigint "subject_id", null: false
    t.string "target_type", null: false
    t.bigint "target_id", null: false
    t.jsonb "question", null: false
    t.integer "correct_streak", default: 0, null: false
    t.datetime "due_at", null: false
    t.bigint "last_attempt_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id", "due_at"], name: "index_practice_reviews_on_ace_id_and_due_at"
    t.index ["ace_id", "game_type", "subject_type", "subject_id", "target_type", "target_id"], name: "index_practice_reviews_on_identity", unique: true
    t.index ["ace_id"], name: "index_practice_reviews_on_ace_id"
    t.index ["last_attempt_id"], name: "index_practice_reviews_on_last_attempt_id"
  end

  create_table "quests", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.json "details"
    t.string "moderation_status", default: "approved", null: false
    t.integer "moderation_revision", default: 1, null: false
    t.bigint "created_by_id"
    t.integer "lock_version", default: 0, null: false
    t.index ["created_by_id"], name: "index_quests_on_created_by_id"
    t.index ["moderation_status", "created_at"], name: "index_quests_on_moderation_status_and_created_at"
    t.index ["seed_version"], name: "index_quests_on_seed_version"
    t.check_constraint "moderation_status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'hidden'::character varying]::text[])", name: "quests_moderation_status"
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
    t.boolean "archived", default: false, null: false
    t.index ["ace_id", "spectrum_id", "target_type", "target_id"], name: "index_ratings_on_ace_spectrum_and_target_active", unique: true, where: "(archived = false)"
    t.index ["ace_id"], name: "index_ratings_on_ace_id"
    t.index ["archived"], name: "index_ratings_on_archived"
    t.index ["spectrum_id"], name: "index_ratings_on_spectrum_id"
    t.index ["target_type", "target_id"], name: "index_ratings_on_target"
  end

  create_table "roles", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "position_id", null: false
    t.boolean "primary", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.index ["player_id", "position_id"], name: "index_roles_on_player_id_and_position_id", unique: true
    t.index ["player_id", "primary"], name: "index_roles_on_player_id_and_primary"
    t.index ["player_id"], name: "index_roles_on_player_id"
    t.index ["position_id"], name: "index_roles_on_position_id"
    t.index ["seed_version"], name: "index_roles_on_seed_version"
  end

  create_table "roster_entries", force: :cascade do |t|
    t.bigint "roster_id", null: false
    t.bigint "player_id", null: false
    t.bigint "stint_id"
    t.string "status"
    t.string "jersey_number"
    t.jsonb "source", default: {}, null: false
    t.jsonb "details", default: {}, null: false
    t.string "entity_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_code"], name: "index_roster_entries_on_entity_code", unique: true
    t.index ["player_id"], name: "index_roster_entries_on_player_id"
    t.index ["roster_id", "player_id"], name: "index_roster_entries_on_roster_id_and_player_id", unique: true
    t.index ["roster_id"], name: "index_roster_entries_on_roster_id"
    t.index ["stint_id"], name: "index_roster_entries_on_stint_id"
  end

  create_table "rosters", force: :cascade do |t|
    t.bigint "campaign_id", null: false
    t.string "kind", null: false
    t.date "effective_on"
    t.datetime "observed_at"
    t.string "coverage", default: "unknown", null: false
    t.jsonb "source", default: {}, null: false
    t.jsonb "details", default: {}, null: false
    t.string "entity_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["campaign_id", "kind", "effective_on"], name: "index_rosters_on_campaign_id_and_kind_and_effective_on"
    t.index ["campaign_id"], name: "index_rosters_on_campaign_id"
    t.index ["entity_code"], name: "index_rosters_on_entity_code", unique: true
    t.check_constraint "coverage::text = ANY (ARRAY['unknown'::character varying, 'partial'::character varying, 'complete'::character varying]::text[])", name: "rosters_have_known_coverage_labels"
  end

  create_table "seasons", force: :cascade do |t|
    t.bigint "year_id", null: false, comment: "Year when the season began"
    t.bigint "league_id", null: false, comment: "League the season belongs to"
    t.date "start_date", comment: "When the regular season started"
    t.date "end_date", comment: "When the regular season ended"
    t.date "playoff_start_date", comment: "When the playoffs started"
    t.date "playoff_end_date", comment: "When the playoffs ended"
    t.text "comments", default: [], comment: "Array of comments about the season", array: true
    t.string "seed_version", comment: "Version when this record was seeded"
    t.datetime "last_seeded_at", comment: "When this record was last seeded"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "champion_id"
    t.bigint "championship_contest_id"
    t.string "label"
    t.string "entity_code"
    t.index ["champion_id"], name: "index_seasons_on_champion_id"
    t.index ["championship_contest_id"], name: "index_seasons_on_championship_contest_id"
    t.index ["entity_code"], name: "index_seasons_on_entity_code", unique: true
    t.index ["league_id"], name: "index_seasons_on_league_id"
    t.index ["seed_version"], name: "index_seasons_on_seed_version"
    t.index ["start_date"], name: "index_seasons_on_start_date"
    t.index ["year_id", "league_id"], name: "index_seasons_on_year_and_league", unique: true
    t.index ["year_id"], name: "index_seasons_on_year_id"
  end

  create_table "shout_out_drafts", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.text "message", null: false
    t.integer "lock_version", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id"], name: "index_shout_out_drafts_on_ace_id"
    t.index ["target_type", "target_id"], name: "index_shout_out_drafts_on_target"
    t.check_constraint "target_type IS NULL OR (target_type::text = ANY (ARRAY['Team'::character varying, 'Player'::character varying]::text[]))", name: "drafts_supported_target"
  end

  create_table "shout_out_reactions", force: :cascade do |t|
    t.bigint "shout_out_id", null: false
    t.bigint "ace_id", null: false
    t.string "kind", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id"], name: "index_shout_out_reactions_on_ace_id"
    t.index ["shout_out_id", "ace_id", "kind"], name: "index_shout_out_reactions_on_shout_out_id_and_ace_id_and_kind", unique: true
    t.index ["shout_out_id"], name: "index_shout_out_reactions_on_shout_out_id"
    t.check_constraint "kind::text = ANY (ARRAY['fire'::character varying, 'love'::character varying, 'legend'::character varying]::text[])", name: "supported_shout_out_reaction"
  end

  create_table "shout_out_reports", force: :cascade do |t|
    t.bigint "shout_out_id", null: false
    t.bigint "reporter_id"
    t.string "reason", null: false
    t.text "note"
    t.string "resolution"
    t.text "decision_reason"
    t.bigint "resolved_by_id"
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reporter_id"], name: "index_shout_out_reports_on_reporter_id"
    t.index ["resolved_at", "shout_out_id"], name: "index_shout_out_reports_on_resolved_at_and_shout_out_id"
    t.index ["resolved_by_id"], name: "index_shout_out_reports_on_resolved_by_id"
    t.index ["shout_out_id", "reporter_id"], name: "index_shout_out_reports_on_shout_out_id_and_reporter_id", unique: true
    t.index ["shout_out_id"], name: "index_shout_out_reports_on_shout_out_id"
    t.check_constraint "reason::text = ANY (ARRAY['Harassment'::character varying, 'Spam'::character varying, 'Off-topic'::character varying, 'Other'::character varying]::text[])", name: "report_reason"
    t.check_constraint "resolution IS NULL AND resolved_at IS NULL OR resolution IS NOT NULL AND (resolution::text = ANY (ARRAY['kept_live'::character varying, 'hidden'::character varying]::text[])) AND resolved_at IS NOT NULL", name: "report_resolution"
  end

  create_table "shout_outs", force: :cascade do |t|
    t.bigint "created_by_id", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.bigint "team_id"
    t.bigint "league_id"
    t.bigint "shout_out_draft_id"
    t.integer "draft_revision", null: false
    t.string "target_name", null: false
    t.text "message", null: false
    t.bigint "bid_cents", null: false
    t.string "payment_method", null: false
    t.string "funding_status", default: "unfunded", null: false
    t.string "moderation_status", default: "pending", null: false
    t.integer "moderation_revision", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_shout_outs_on_created_by_id"
    t.index ["league_id"], name: "index_shout_outs_on_league_id"
    t.index ["shout_out_draft_id", "draft_revision"], name: "index_shout_outs_on_shout_out_draft_id_and_draft_revision", unique: true
    t.index ["shout_out_draft_id"], name: "index_shout_outs_on_shout_out_draft_id"
    t.index ["target_type", "target_id"], name: "index_shout_outs_on_target"
    t.index ["team_id"], name: "index_shout_outs_on_team_id"
    t.check_constraint "(payment_method::text = ANY (ARRAY['credit'::character varying, 'stripe'::character varying]::text[])) AND (funding_status::text = ANY (ARRAY['unfunded'::character varying, 'reserved'::character varying, 'spent'::character varying, 'refunded'::character varying]::text[]))", name: "shout_out_funding_states"
    t.check_constraint "bid_cents > 0", name: "positive_shout_out_bid"
  end

  create_table "spectrums", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "low_label", default: "Low"
    t.string "high_label", default: "High"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "moderation_status", default: "approved", null: false
    t.integer "moderation_revision", default: 1, null: false
    t.bigint "created_by_id"
    t.integer "lock_version", default: 0, null: false
    t.index ["created_by_id"], name: "index_spectrums_on_created_by_id"
    t.index ["moderation_status", "created_at"], name: "index_spectrums_on_moderation_status_and_created_at"
    t.index ["name"], name: "index_spectrums_on_name", unique: true
    t.index ["seed_version"], name: "index_spectrums_on_seed_version"
    t.check_constraint "moderation_status::text = ANY (ARRAY['pending'::character varying, 'approved'::character varying, 'rejected'::character varying, 'hidden'::character varying]::text[])", name: "spectrums_moderation_status"
  end

  create_table "sports", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "icon_url"
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "entity_code"
    t.index ["entity_code"], name: "index_sports_on_entity_code", unique: true
    t.index ["seed_version"], name: "index_sports_on_seed_version"
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
    t.string "logo_url"
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "entity_code"
    t.index ["city_id"], name: "index_stadiums_on_city_id"
    t.index ["entity_code"], name: "index_stadiums_on_entity_code", unique: true
    t.index ["seed_version"], name: "index_stadiums_on_seed_version"
  end

  create_table "states", force: :cascade do |t|
    t.string "name"
    t.string "abbreviation"
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "flag_url"
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "entity_code"
    t.index ["country_id"], name: "index_states_on_country_id"
    t.index ["entity_code"], name: "index_states_on_entity_code", unique: true
    t.index ["seed_version"], name: "index_states_on_seed_version"
  end

  create_table "stints", force: :cascade do |t|
    t.bigint "player_id", null: false
    t.bigint "team_id", null: false
    t.bigint "contract_id"
    t.date "start_date"
    t.date "end_date"
    t.string "status"
    t.bigint "start_transaction_id"
    t.bigint "end_transaction_id"
    t.jsonb "source", default: {}, null: false
    t.jsonb "details", default: {}, null: false
    t.string "entity_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id"], name: "index_stints_on_contract_id"
    t.index ["end_transaction_id"], name: "index_stints_on_end_transaction_id"
    t.index ["entity_code"], name: "index_stints_on_entity_code", unique: true
    t.index ["player_id", "start_date", "end_date"], name: "index_stints_on_player_id_and_start_date_and_end_date"
    t.index ["player_id"], name: "index_stints_on_player_id"
    t.index ["start_transaction_id"], name: "index_stints_on_start_transaction_id"
    t.index ["team_id", "start_date", "end_date"], name: "index_stints_on_team_id_and_start_date_and_end_date"
    t.index ["team_id"], name: "index_stints_on_team_id"
    t.check_constraint "start_date IS NULL OR end_date IS NULL OR end_date >= start_date", name: "stints_have_ordered_dates"
  end

  create_table "stripe_purchases", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.bigint "shout_out_id"
    t.bigint "amount_cents", null: false
    t.string "request_key", null: false
    t.string "status", default: "pending", null: false
    t.string "stripe_session_id"
    t.string "stripe_payment_intent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id", "request_key"], name: "index_stripe_purchases_on_ace_id_and_request_key", unique: true
    t.index ["ace_id"], name: "index_stripe_purchases_on_ace_id"
    t.index ["shout_out_id"], name: "index_stripe_purchases_on_shout_out_id"
    t.index ["stripe_payment_intent_id"], name: "index_stripe_purchases_on_stripe_payment_intent_id", unique: true
    t.index ["stripe_session_id"], name: "index_stripe_purchases_on_stripe_session_id", unique: true
    t.check_constraint "amount_cents >= 50 AND amount_cents <= 99999999 AND (status::text = ANY (ARRAY['pending'::character varying, 'paid'::character varying, 'expired'::character varying]::text[]))", name: "stripe_purchase_amount_and_status"
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
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.string "entity_code"
    t.string "text_color"
    t.index ["entity_code"], name: "index_teams_on_entity_code", unique: true
    t.index ["league_id"], name: "index_teams_on_league_id"
    t.index ["seed_version"], name: "index_teams_on_seed_version"
    t.index ["stadium_id"], name: "index_teams_on_stadium_id"
  end

  create_table "transaction_players", force: :cascade do |t|
    t.bigint "transaction_id", null: false
    t.bigint "player_id", null: false
    t.bigint "from_organization_id"
    t.bigint "to_organization_id"
    t.bigint "from_team_id"
    t.bigint "to_team_id"
    t.jsonb "details", default: {}, null: false
    t.string "entity_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["entity_code"], name: "index_transaction_players_on_entity_code", unique: true
    t.index ["from_organization_id"], name: "index_transaction_players_on_from_organization_id"
    t.index ["from_team_id"], name: "index_transaction_players_on_from_team_id"
    t.index ["player_id"], name: "index_transaction_players_on_player_id"
    t.index ["to_organization_id"], name: "index_transaction_players_on_to_organization_id"
    t.index ["to_team_id"], name: "index_transaction_players_on_to_team_id"
    t.index ["transaction_id", "player_id"], name: "index_transaction_players_on_transaction_id_and_player_id", unique: true
    t.index ["transaction_id"], name: "index_transaction_players_on_transaction_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.string "kind", null: false
    t.date "effective_on"
    t.jsonb "source", default: {}, null: false
    t.jsonb "details", default: {}, null: false
    t.string "entity_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["effective_on", "kind"], name: "index_transactions_on_effective_on_and_kind"
    t.index ["entity_code"], name: "index_transactions_on_entity_code", unique: true
  end

  create_table "warnings", force: :cascade do |t|
    t.bigint "ace_id", null: false
    t.bigint "moderator_id"
    t.string "reason", limit: 2000, null: false
    t.string "subject_type"
    t.bigint "subject_id"
    t.string "subject_name"
    t.string "request_key", limit: 128, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ace_id", "request_key"], name: "index_warnings_on_ace_id_and_request_key", unique: true
    t.index ["ace_id"], name: "index_warnings_on_ace_id"
    t.index ["moderator_id"], name: "index_warnings_on_moderator_id"
    t.index ["subject_type", "subject_id"], name: "index_warnings_on_subject"
  end

  create_table "years", force: :cascade do |t|
    t.integer "number", null: false, comment: "The year number (e.g., 2024)"
    t.string "seed_version", comment: "Version of the seed file that created or last updated this record"
    t.datetime "last_seeded_at", comment: "When this record was last updated by a seed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "entity_code"
    t.index ["entity_code"], name: "index_years_on_entity_code", unique: true
    t.index ["number"], name: "index_years_on_number", unique: true
    t.index ["seed_version"], name: "index_years_on_seed_version"
  end

  add_foreign_key "achievements", "aces", column: "created_by_id", on_delete: :nullify
  add_foreign_key "activations", "campaigns"
  add_foreign_key "activations", "contracts"
  add_foreign_key "activations", "players"
  add_foreign_key "appearances", "contestants"
  add_foreign_key "appearances", "players"
  add_foreign_key "appearances", "stints"
  add_foreign_key "campaigns", "cities"
  add_foreign_key "campaigns", "conferences"
  add_foreign_key "campaigns", "divisions"
  add_foreign_key "campaigns", "seasons"
  add_foreign_key "campaigns", "stadiums"
  add_foreign_key "campaigns", "teams"
  add_foreign_key "cities", "states"
  add_foreign_key "conferences", "leagues"
  add_foreign_key "contestants", "campaigns"
  add_foreign_key "contestants", "contests"
  add_foreign_key "contests", "seasons"
  add_foreign_key "contracts", "organizations"
  add_foreign_key "contracts", "players"
  add_foreign_key "contracts", "teams"
  add_foreign_key "credit_accounts", "aces"
  add_foreign_key "credit_entries", "credit_accounts"
  add_foreign_key "divisions", "conferences"
  add_foreign_key "follows", "aces"
  add_foreign_key "game_attempts", "aces"
  add_foreign_key "game_attempts", "game_rounds"
  add_foreign_key "game_rounds", "aces"
  add_foreign_key "goal_achievements", "achievements"
  add_foreign_key "goal_achievements", "goals"
  add_foreign_key "goals", "aces"
  add_foreign_key "goals", "quests"
  add_foreign_key "highlights", "aces", column: "created_by_id", on_delete: :nullify
  add_foreign_key "highlights", "achievements"
  add_foreign_key "highlights", "quests"
  add_foreign_key "jersey_number_assignments", "players"
  add_foreign_key "jersey_number_assignments", "teams"
  add_foreign_key "leagues", "sports"
  add_foreign_key "memberships", "divisions"
  add_foreign_key "memberships", "teams"
  add_foreign_key "moderation_decisions", "aces", column: "actor_id", on_delete: :nullify
  add_foreign_key "moderation_escalations", "aces", column: "requested_by_id", on_delete: :nullify
  add_foreign_key "moderation_escalations", "aces", column: "resolved_by_id", on_delete: :nullify
  add_foreign_key "moderation_escalations", "aces", column: "subject_ace_id", on_delete: :nullify
  add_foreign_key "moderator_notes", "aces", column: "moderator_id", on_delete: :nullify
  add_foreign_key "moderator_notes", "aces", on_delete: :cascade
  add_foreign_key "mutes", "aces", column: "ended_by_id", on_delete: :nullify
  add_foreign_key "mutes", "aces", column: "moderator_id", on_delete: :nullify
  add_foreign_key "mutes", "aces", on_delete: :cascade
  add_foreign_key "mutes", "shout_outs", column: "hidden_shout_out_id"
  add_foreign_key "organization_affiliations", "organizations"
  add_foreign_key "organization_affiliations", "teams"
  add_foreign_key "player_group_memberships", "player_groups"
  add_foreign_key "player_group_memberships", "players"
  add_foreign_key "players", "cities", column: "birth_city_id"
  add_foreign_key "players", "countries", column: "birth_country_id"
  add_foreign_key "players", "sports"
  add_foreign_key "players", "teams"
  add_foreign_key "positions", "sports"
  add_foreign_key "practice_reviews", "aces"
  add_foreign_key "practice_reviews", "game_attempts", column: "last_attempt_id", on_delete: :cascade
  add_foreign_key "quests", "aces", column: "created_by_id", on_delete: :nullify
  add_foreign_key "ratings", "aces"
  add_foreign_key "ratings", "spectrums"
  add_foreign_key "roles", "players"
  add_foreign_key "roles", "positions"
  add_foreign_key "roster_entries", "players"
  add_foreign_key "roster_entries", "rosters"
  add_foreign_key "roster_entries", "stints"
  add_foreign_key "rosters", "campaigns"
  add_foreign_key "seasons", "contests", column: "championship_contest_id"
  add_foreign_key "seasons", "leagues"
  add_foreign_key "seasons", "teams", column: "champion_id"
  add_foreign_key "seasons", "years"
  add_foreign_key "shout_out_drafts", "aces"
  add_foreign_key "shout_out_reactions", "aces", on_delete: :cascade
  add_foreign_key "shout_out_reactions", "shout_outs"
  add_foreign_key "shout_out_reports", "aces", column: "reporter_id", on_delete: :nullify
  add_foreign_key "shout_out_reports", "aces", column: "resolved_by_id", on_delete: :nullify
  add_foreign_key "shout_out_reports", "shout_outs"
  add_foreign_key "shout_outs", "aces", column: "created_by_id"
  add_foreign_key "shout_outs", "leagues", on_delete: :nullify
  add_foreign_key "shout_outs", "shout_out_drafts", on_delete: :nullify
  add_foreign_key "shout_outs", "teams", on_delete: :nullify
  add_foreign_key "spectrums", "aces", column: "created_by_id", on_delete: :nullify
  add_foreign_key "stadiums", "cities"
  add_foreign_key "states", "countries"
  add_foreign_key "stints", "contracts"
  add_foreign_key "stints", "players"
  add_foreign_key "stints", "teams"
  add_foreign_key "stints", "transactions", column: "end_transaction_id"
  add_foreign_key "stints", "transactions", column: "start_transaction_id"
  add_foreign_key "stripe_purchases", "aces"
  add_foreign_key "stripe_purchases", "shout_outs"
  add_foreign_key "teams", "leagues"
  add_foreign_key "teams", "stadiums"
  add_foreign_key "transaction_players", "organizations", column: "from_organization_id"
  add_foreign_key "transaction_players", "organizations", column: "to_organization_id"
  add_foreign_key "transaction_players", "players"
  add_foreign_key "transaction_players", "teams", column: "from_team_id"
  add_foreign_key "transaction_players", "teams", column: "to_team_id"
  add_foreign_key "transaction_players", "transactions"
  add_foreign_key "warnings", "aces", column: "moderator_id", on_delete: :nullify
  add_foreign_key "warnings", "aces", on_delete: :cascade
end
