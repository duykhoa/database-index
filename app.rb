require "active_record"
require_relative "./timelog"

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

  def self.display
    printf "%-5s%-20s%-20s\n" % %w[Id Serial Name]
    all.each do |product|
      printf "%-5d%-20s%-20s\n" % [ product.id, product.serial, product.name ]
    end
  end

  def self.reset!
    drop_table! && migrate!
  end

  private

  def self.sample_data(size)
    size.times do |i|
      name = "Product #{i}"
      serial = "P-D#{ i }"

      Product.create!(name: name, serial: serial)
    end
  end

  def self.add_index(column_name, options = {})
    connection.add_index table_name, column_name, options
  end

  def self.drop_table!
    connection.drop_table table_name
  end

  def self.reset!
    drop_table! && migrate!
  end
end

# This commands below is used to demonstrate the advantage of database index in Rails.

# Run the migration to create products table in product-database
# NOTE: Turn me off after use
#Product.migrate!

# Display all data in products table
#Product.display

# Explain the simple SQL query
#puts Product.where(name: "Product 999").explain
#
# Add index for name
# Rerun same query and see the different
#Product.add_index "name", unique: true
#puts Product.where(name: "Product 999").explain
