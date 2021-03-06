require "active_record"
require_relative "./experiment"

include Experiment

class Product < ActiveRecord::Base
  establish_connection adapter: "sqlite3", database: "product-database.db"

  class << self
    def migrate!(with_sample_data: true, sample_data_size: 1000)
      unless connection.table_exists?(table_name)
        connection.create_table table_name do |t|
          t.string :serial
          t.string :name
          t.integer :price
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

        Product.create!(name: name, serial: serial, price: [100,200,300,400].sample)
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
# With experiment, we can see the difference in time consumed to execute the query.
# It isn't accurate since the overhead time in ActiveRecord and Ruby, plus the magic caching
# mechanism of ActiveRecord.
experiment { Product.where(name: "Product 999") }

# Add index for name
# Rerun same query and see the different
Product.add_index "name", unique: true
experiment { Product.where(name: "Product 999") }

# OR, NOT, IN operator
experiment("use OR") { Product.where(name: "Product 999").or(Product.where(name: "Product 998")) }
experiment("use NOT") { Product.where.not(name: "Product 998") }
experiment("In a range of value") { Product.where(name: ["Product 999", "Product 998"]) }

# Experiment with multiple columns query
experiment("name > serial") { Product.where(name: "Product 999", serial: "P-0999-0-1") }
experiment("serial > name") { Product.where(serial: "P-0999-0-1", name: "Product 999") }

# With 2 separate index
Product.reset!

# With no index
Product.reset!
Product.add_index "name", unique: true
Product.add_index "serial", unique: true

experiment("name > serial") { Product.where(name: "Product 999", serial: "P-0999-0-1") }
experiment("serial > name") { Product.where(serial: "P-0999-0-1", name: "Product 999") }
experiment("name use OR") { Product.where(name: "Product 999").or(Product.where(serial: "P-0999-0-1")) }
experiment("name use NOT") { Product.where.not(name: "Product 998") }
experiment("serial use NOT") { Product.where.not(serial: "P-0999-0-1") }
experiment("In a range of value") { Product.where(name: ["Product 999", "Product 998"]) }

# With only one index for name and serial
Product.reset!
Product.add_index ["name", "serial"]

experiment("name > serial") { Product.where(name: "Product 999", serial: "P-0999-0-1") }

# Reverse order of serial and name column in where clause
experiment("serial > name") { Product.where(serial: "P-0999-0-1", name: "Product 999") }

# See if single column query can use multiple columns index
experiment("single column name") { Product.where(name: "Product 999") }
experiment("single column serial") { Product.where(serial: "P-0999-0-1") }

# Run query for a column isn't in the index
experiment("price isn't included") { Product.where(name: "Product 999", serial: "P-0999-0-1", price: 300) }
experiment("price isn't included") { Product.where(name: "Product 999", serial: "P-0999-0-1").or(Product.where(price: 200)) }
experiment("price isn't included") { Product.where(name: "Product 999", serial: "P-0999-0-1", price: [100,200]) }

# OR and IN operator
experiment("use OR") { Product.where(name: "Product 999").or(Product.where(name: "Product 998")) }
experiment("In a range of value") { Product.where(name: ["Product 999", "Product 998"]) }
