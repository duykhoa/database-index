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
> Took 0.000948 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SCAN TABLE products

> Add index for [name]
> Took 0.000249 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)

| use OR
> Took 0.000557 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE ("products"."name" = ? OR "products"."name" = ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1

| In a range of value
> Took 0.000233 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" IN (?, ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1

| name > serial
> Took 0.000172 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)

| serial > name
> Took 0.000169 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)

There is no index
| name > serial
> Took 0.000147 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SCAN TABLE products

| serial > name
> Took 0.000090 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SCAN TABLE products

> Add index for [name, serial]
| name > serial
> Took 0.000120 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=? AND serial=?)

| serial > name
> Took 0.000064 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=? AND serial=?)

| single column name
> Took 0.000055 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=?)

| single column serial
> Took 0.000059 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? [["serial", "P-0999-0-1"]]
0|0|0|SCAN TABLE products

| use OR
> Took 0.000151 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE ("products"."name" = ? OR "products"."name" = ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1

| In a range of value
> Took 0.000083 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" IN (?, ?) [["serial", "Product 999"], ["serial", "Product 998"]]
0|0|0|SCAN TABLE products
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

We learn that database looks for index for the searched column, if the index doesn't exist, the database uses the SCAN
strategy.

In this section, we will learn how it is applied for multiple columns appearing on the search query, together with
different strategy of indexing the data.

With the same index name previous example (on name column), and the query is searching for `name` and `serial`

`Product.where(name: "Product 999", serial: "P-0999-0-1").explain`

```
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
```

The SEARCH strategy still works, although there is no index on the `serial` column. Let's change the
order of query condition

```
There is only index for name, not for serial column
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
name > serial   Took 0.000263 seconds
serial > name   Took 0.000259 seconds
```

My hypothesis is that the first query should be faster, but end up there is no significant difference.

Let's go to the next experiment with 2 columns index

```
Product.add_index ["name", "serial"]

puts Product.where(name: "Product 999", serial: "P-0999-0-1").explain
timelog("name > serial") { puts Product.where(name: "Product 999", serial: "P-0999-0-1").explain }

# Reverse order of serial and name column in where clause
puts Product.where(serial: "P-0999-0-1", name: "Product 999").explain
timelog("serial > name") { puts Product.where(serial: "P-0999-0-1", name: "Product 999").explain }
```

and the result is

```
There is no index
name > serial   Took 0.002333 seconds
serial > name   Took 0.001623 seconds

> Add index for [name, serial]
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=? AND serial=?)
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=? AND serial=?)
name > serial   Took 0.000878 seconds
serial > name   Took 0.000739 seconds
```

There is no different when changing the order of 2 columns in search query.

It is quite clear that with index, the execution time is faster. However, we can't say 
# Conclusion
