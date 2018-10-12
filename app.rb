require "active_record"
require_relative "./timelog"

include Timelog

class Product < ActiveRecord::Base
  establish_connection adapter: "sqlite3", database: "product-database.db"

  class << self
    def migrate!(with_sample_data: true, sample_data_size: 1000)
      unless connection.table_exists?(table_name)
        connection.create_table table_name do |t|
          t.string :serial
          t.string :name
          t.timestamp
        end

        sample_data(sample_data_size) if with_sample_data
      end
    end

    def display
      printf "%-5s%-20s%-20s\n" % %w[Id Serial Name]
      all.each do |product|
        printf "%-5d%-20s%-20s\n" % [ product.id, product.serial, product.name ]
      end
    end

    def reset!
      drop_table! if connection.table_exists?(table_name)
      migrate!
    end

    def add_index(column_name, options = {})
      printf "> Add index for [%s]\n" % [column_name].join(", ")
      connection.add_index table_name, column_name, options
    end

    private

    def sample_data(size)
      size.times do |i|
        name = "Product #{i}"
        serial = "P-D#{ i }"

        Product.create!(name: name, serial: serial)
      end
    end

    def drop_table!
      connection.drop_table table_name
    end
  end
end

Product.connection.disable_query_cache!
# This commands below is used to demonstrate the advantage of database index in Rails.

# Run the migration to create products table in product-database
# NOTE: Turn me off after use
Product.reset!

# Display all data in products table
# Product.display

# Explain the simple SQL query
# With timelog, we can see the difference in time consumed to execute the query.
# It isn't accurate since the overhead time in ActiveRecord and Ruby, plus the magic caching
# mechanism of ActiveRecord.
puts Product.where(name: "Product 999").explain
timelog { Product.where(name: "Product 999") }

# Add index for name
# Rerun same query and see the different
Product.add_index "name", unique: true
puts Product.where(name: "Product 999").explain
timelog { Product.where(name: "Product 999") }

# OR and IN operator
timelog("use OR") { puts Product.where(name: "Product 999").or(Product.where(name: "Product 998")).explain }
timelog("In a range of value") { puts Product.where(serial: ["Product 999", "Product 998"]).explain }

# Experiment with multiple columns query
puts "There is only index for name, not for serial column"
timelog("name > serial") { Product.where(name: "Product 999", serial: "P-0999-0-1").explain }
timelog("serial > name") { Product.where(serial: "P-0999-0-1", name: "Product 999").explain }

# With no index
Product.reset!

puts "There is no index"
timelog("name > serial") { Product.where(name: "Product 999", serial: "P-0999-0-1").explain }
timelog("serial > name") { Product.where(serial: "P-0999-0-1", name: "Product 999").explain }

# With Index for name and serial
Product.reset!
Product.add_index ["name", "serial"]

puts Product.where(name: "Product 999", serial: "P-0999-0-1").explain
timelog("name > serial") { puts Product.where(name: "Product 999", serial: "P-0999-0-1").explain }

# Reverse order of serial and name column in where clause
puts Product.where(serial: "P-0999-0-1", name: "Product 999").explain
timelog("serial > name") { puts Product.where(serial: "P-0999-0-1", name: "Product 999").explain }

# See if single column query can use multiple columns index
timelog("single column name") { puts Product.where(name: "Product 999").explain }
timelog("single column serial") { puts Product.where(serial: "P-0999-0-1").explain }

# OR and IN operator
timelog("use OR") { puts Product.where(name: "Product 999").or(Product.where(name: "Product 998")).explain }
timelog("In a range of value") { puts Product.where(serial: ["Product 999", "Product 998"]).explain }
