This simple repository use ActiveRecord and SQLite3 database to demonstrate how database index work.

# Why

To improve the performance of application in database level, usually we heard about database index.
However, adding database index requires basic knowledge to make it right, otherwise, it could make
the situation worse.

With a list of examples, we will see how index improves the system performance and go deeper to
analyze how database use the index. The result of this are some practical tips that we can apply to
the work/side projects.

A side notes. Database index is an important technique that every developer should know. However, it
isn't the only way to optimize the system's performance. To optimize the application, it starts with
the design of application (code level), database design, database index, caching, search engine,
infrastructure, and ofcourse depend on the business requirements as well. There is no such general
solution can be applied for all situation.

# How database index work

When running the command `ruby app.rb`, we should see the output that is similar to:

```
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SCAN TABLE products
Took 0.000290 seconds
> Add index for [name]
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
Took 0.000199 seconds
use OR  EXPLAIN for: SELECT "products".* FROM "products" WHERE ("products"."name" = ? OR "products"."name" = ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1
Took 0.002029 seconds
In a range of value     EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" IN (?, ?) [["serial", "Product 999"], ["serial", "Product 998"]]
0|0|0|SCAN TABLE products
Took 0.002354 seconds
There is only index for name, not for serial column
name > serial   Took 0.001837 seconds
serial > name   Took 0.002013 seconds
There is no index
name > serial   Took 0.001964 seconds
serial > name   Took 0.001623 seconds
> Add index for [name, serial]
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=? AND serial=?)
name > serial   EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=? AND serial=?)
Took 0.001182 seconds
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=? AND serial=?)
serial > name   EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=? AND serial=?)
Took 0.001265 seconds
single column name      EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=?)
Took 0.001280 seconds
single column serial    EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? [["serial", "P-0999-0-1"]]
0|0|0|SCAN TABLE products
Took 0.001449 seconds
use OR  EXPLAIN for: SELECT "products".* FROM "products" WHERE ("products"."name" = ? OR "products"."name" = ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1
Took 0.001880 seconds
In a range of value     EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" IN (?, ?) [["serial", "Product 999"], ["serial", "Product 998"]]
0|0|0|SCAN TABLE products
Took 0.001714 seconds
```

## Experiment for index with 1 column

Without index, the query `Product.where(name: "Proudct 999").explain` uses SCAN strategy

Scan basically means look up one by one record.

We then add an index for column `name`, and the explaination for the same query tells us it now uses
SEARCH strategy with the the new index. The time is slightly faster. Here is the explanation of the
log for the explanation

```
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
Took 0.000199 seconds
```

When there is index for a column appeared in search query, database will use the index to speed up the
search, if there is no existing index, the database fallbacks to SCAN strategy, and the query take
longer to run without an index.

## Experiment for index with multiple (2) columns

# Conclusion
