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

ActiveRecord::Schema[8.0].define(version: 2025_03_24_024633) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "families", force: :cascade do |t|
    t.string "name"
    t.string "phone"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "confirmed", default: false
  end

  create_table "families_whatsapp_messages", id: false, force: :cascade do |t|
    t.bigint "whatsapp_message_id", null: false
    t.bigint "family_id", null: false
    t.index ["family_id"], name: "index_families_whatsapp_messages_on_family_id"
    t.index ["whatsapp_message_id"], name: "index_families_whatsapp_messages_on_whatsapp_message_id"
  end

  create_table "gift_items", force: :cascade do |t|
    t.string "name"
    t.decimal "price"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "members", force: :cascade do |t|
    t.string "name"
    t.integer "age"
    t.string "gender"
    t.bigint "family_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "confirmed", default: false
    t.index ["family_id"], name: "index_members_on_family_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "gift_item_id", null: false
    t.integer "quantity", default: 1
    t.decimal "price", precision: 8, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["gift_item_id"], name: "index_order_items_on_gift_item_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "family_id"
    t.string "status", default: "pending"
    t.decimal "total", precision: 8, scale: 2
    t.string "customer_name"
    t.string "customer_email"
    t.string "customer_phone"
    t.string "asaas_payment_id"
    t.string "asaas_customer_id"
    t.string "payment_method"
    t.string "payment_url"
    t.text "payment_data", default: "{}"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "customer_cpf_cnpj"
    t.text "error_message"
    t.datetime "paid_at"
    t.index ["family_id"], name: "index_orders_on_family_id"
  end

  create_table "processed_webhooks", force: :cascade do |t|
    t.string "event_id", null: false
    t.text "payload"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_processed_webhooks_on_event_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "whatsapp_messages", force: :cascade do |t|
    t.text "content"
    t.string "status", default: "pending", null: false
    t.integer "sent_count", default: 0, null: false
    t.integer "failed_count", default: 0, null: false
    t.integer "total_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "members", "families"
  add_foreign_key "order_items", "gift_items"
  add_foreign_key "order_items", "orders"
  add_foreign_key "orders", "families"
end
