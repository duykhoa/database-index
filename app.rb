require "active_record"

class Product < ActiveRecord::Base
  establish_connection adapter: "sqlite3", database: "product-database.db"

  def self.migrate!(with_sample_data: true, sample_data_size: 1000)
    unless connection.table_exists?(table_name)
      connection.create_table table_name do |t|
        t.string :serial
        t.string :name
        t.timestamp
      end

      sample_data(sample_data_size) if with_sample_data
    end
  end

  private

  def self.sample_data(size)
    size.times do |i|
      name = "Product #{i}"
      serial = "P-D#{ i } }"

      Product.create!(name: name, serial: serial)
    end
  end
end

# This commands below is used to demonstrate the advantage of database index in Rails.

# Run the migration to create products table in product-database
Product.migrate!
