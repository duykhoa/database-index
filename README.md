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
> Took 0.000551 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SCAN TABLE products

> Add index for [name]
> Took 0.000103 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)

| use OR
> Took 0.000134 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE ("products"."name" = ? OR "products"."name" = ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1

| use NOT
> Took 0.000073 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" != ? [["name", "Product 998"]]
0|0|0|SCAN TABLE products

| In a range of value
> Took 0.000109 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" IN (?, ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1

| name > serial
> Took 0.000056 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)

| serial > name
> Took 0.000053 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)

> Add index for [name]
> Add index for [serial]
| name > serial
> Took 0.000134 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_serial (serial=?)

| serial > name
> Took 0.000062 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_serial (serial=?)

| name use OR
> Took 0.000149 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE ("products"."name" = ? OR "products"."serial" = ?) [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|SEARCH TABLE products USING INDEX index_products_on_serial (serial=?)

| name use NOT
> Took 0.000082 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" != ? [["name", "Product 998"]]
0|0|0|SCAN TABLE products

| serial use NOT
> Took 0.000128 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" != ? [["serial", "P-0999-0-1"]]
0|0|0|SCAN TABLE products

| In a range of value
> Took 0.000157 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" IN (?, ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1

> Add index for [name, serial]
| name > serial
> Took 0.000127 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name_and_serial (name=? AND serial=?)

| serial > name
> Took 0.000074 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name_and_serial (name=? AND serial=?)

| single column name
> Took 0.000047 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name_and_serial (name=?)

| single column serial
> Took 0.000048 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? [["serial", "P-0999-0-1"]]
0|0|0|SCAN TABLE products

| price isn't included
> Took 0.000066 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? AND "products"."price" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"], ["price", 300]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name_and_serial (name=? AND serial=?)

| price isn't included
> Took 0.000128 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE ("products"."name" = ? AND "products"."serial" = ? OR "products"."price" = ?) [["name", "Product 999"], ["serial", "P-0999-0-1"], ["price", 200]]
0|0|0|SCAN TABLE products

| price isn't included
> Took 0.000117 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? AND "products"."price" IN (?, ?) [["name", "Product 999"], ["serial", "P-0999-0-1"], ["price", 100], ["price", 200]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name_and_serial (name=? AND serial=?)

| use OR
> Took 0.000125 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE ("products"."name" = ? OR "products"."name" = ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name_and_serial (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1

| In a range of value
> Took 0.000074 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" IN (?, ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name_and_serial (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1
```

There are quite a lot of information, how do we start?

I must say the execution time is more less for reference, not a good evidence to say this approach is faster than
others.

## Experiment for index with 1 column

Without index, the query `Product.where(name: "Proudct 999").explain` uses `SCAN` strategy

`SCAN` means the database simply iterate through each record and compare each record with `WHERE` clause.

We add an index for column `name`, and the explanation for the same query tells us it now uses
`SEARCH` strategy with the the new index. Here is the explanation of the log for the explanation

```
EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
```

Because there is an index for column name, it uses the `SEARCH` on the index.

We also experiment if the index is useful when the query is for more than 1 column, and the explanation proves that.

```
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
```

How's about `OR` query, or `IN`

```
| use OR
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE ("products"."name" = ? OR "products"."name" = ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1

| In a range of value
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" IN (?, ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1
```

Cool, the index is still useful. However, SQLite3 doesn't say what is `EXECUTE LIST SUBQUERY`. We can look at the
document to find out what is it exactly, or experiment with another database (e.g. Postgres).

## Experiment for index with multiple (2) columns

We learn that database looks for index for the searched column, if there is no index, it will use `SCAN` strategy.

Most of modern database system supports multiple columns, we can index some columns together in one index, instead of
several indexes.

```
> Add index for [name, serial]
| name > serial
> Took 0.000120 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=? AND serial=?)

| serial > name
> Took 0.000064 seconds
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=? AND serial=?)
```

The `SEARCH` strategy is applied til. `COVERING INDEX` is used instead of `INDEX` as previous section.
What is different? I think it is faster, otherwise people don't want to use it.

Next, we try to query on 1 column to see if the multi columns index is reusable.

```
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? [["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING COVERING INDEX index_products_on_name_and_serial (name=?)

> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? [["serial", "P-0999-0-1"]]
0|0|0|SCAN TABLE products
```

There is a difference, finally. Only the query for column `name` reuses the index, while the query for column `serial`
falls back to `SCAN` (ignores the index). It is an interesting figuring out, huh?

How's about 2 indexes for name and serial columns

```
> Add index for [name]
> Add index for [serial]
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" = ? AND "products"."serial" = ? [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_serial (serial=?)

| serial > name
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" = ? AND "products"."name" = ? [["serial", "P-0999-0-1"], ["name", "Product 999"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_serial (serial=?)

| name use OR
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE ("products"."name" = ? OR "products"."serial" = ?) [["name", "Product 999"], ["serial", "P-0999-0-1"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|SEARCH TABLE products USING INDEX index_products_on_serial (serial=?)

| name use NOT
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" != ? [["name", "Product 998"]]
0|0|0|SCAN TABLE products

| serial use NOT
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."serial" != ? [["serial", "P-0999-0-1"]]
0|0|0|SCAN TABLE products

| In a range of value
> Run explanation for given query: EXPLAIN for: SELECT "products".* FROM "products" WHERE "products"."name" IN (?, ?) [["name", "Product 999"], ["name", "Product 998"]]
0|0|0|SEARCH TABLE products USING INDEX index_products_on_name (name=?)
0|0|0|EXECUTE LIST SUBQUERY 1
```

`NOT` query doesn't use index at all, at least for the `BTREE` type of index. I will try again with Postgres database
and show you the result. For now, we keep in mind that fact.

With 2 indexes, it only uses 1 of them if the query is and AND query. With the OR query, it uses 2 indexes. A bit complicated,
right?

# Conclusion

Index comes like a handly tool to improve the database query performance.
However, we may not understand how it work, we try to add index to every column in our database and wonder why
performance still sucks. That really depends on the way we index, type of index, etc.

By knowing this, we can design a better and faster database system and write a better application. We also know when to
add or not to add a new database index.
