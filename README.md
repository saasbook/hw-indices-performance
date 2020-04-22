Overview
=======

You have been assigned to improve the database performance of a new version of the Rotten Potatoes site.

# Setup
----

Fork this repo and clone your fork to your development environment.

Now in your development environment run:

```
bundle install --without production
rake db:create
rake db:migrate
```

and

```
rake db:seed
``` 

The seed command may take a while as it generates roughly 5000
database entries. If the seed command is taking too long, consider
lowering the amount of data that it creates by changing the values o`
movie_count` and `review_count` in `db/seeds.rb`.

# Part 1: Improve database performance with indices

This version of the app has some changes:

`Review` and `Moviegoer` models have been added.
Take a look at the model files in `app/models/` to get a better understanding of the relationship between the models. Note that:


<details>
<summary>
Looking at the <code>Movie</code> model as an example, you can see
that a movie has many reviews, and a review belongs to a movie. 
By analogy, what is the relationship between
moviegoers and reviews?  Express the answer in both directions, that
is, the relationship of moviegoers to reviews, and of reviews to moviegoers.
</summary>
<p><blockquote>
A moviegoer has many reviews; a review belongs to a moviegoer.
</blockquote></p>
</details>


<details>
<summary>
Given the above answer, what change(s) need to be made to the
<code>movies</code> and <code>reviews</code> database tables in order
to implement those relationships using foreign keys?
</summary>
<p><blockquote>
The <code>reviews</code> table gets a new column which is the foreign
key to the movie that "owns" that review.  No changes are made to the
<code>movies</code> table.
</blockquote></p>
</details>

<details>
<summary>
What is the relationship between movies and moviegoers, again in both directions?
</summary>
<p><blockquote>
A movie has many moviegoers, through reviews.  That is: a movie has
many reviews, and each of those reviews belongs to a moviegoer, so the
relationship from movies to moviegoers is many-to-many.  Similarly, a
moviegoer has many reviews, each of which belongs to a movie, so the
relationship from moviegoers to movies is also many-to-many.
</blockquote></p>
</details>


<details>
<summary>
What line(s) of code in the <code>Movie</code> model capture the
relationship between movies and moviegoers?
</summary>
<p><blockquote>
You need both <code>movie has_many :reviews</code> and 
<code>movie has_many :moviegoers, :through => :reviews</code> to
capture the relationship.
</blockquote></p>
</details>

New features for users in various stages of completion:

**Implemented:**

* A user can now view the average score for a film. Handled by `MoviesController#score`
* A user can now view all films reviewed by the reviewers of a given film. Handled by `MoviesController#viewed_with`

**Planned:**

* A user should be able to see all of a Moviegoer's Reviews

This will involve a query that looks like `moviegoer.reviews`

Unfortunately, the way that the prototype database is set up will prevent these great new features from scaling very well. As the number of Reviews grows, the performance will drop significantly.

To help you document the performance of the queries the designer has added a benchmarking action that will provide a very rough estimate of query performance. You can get an approximate idea of how long some sample queries take for a small data set by starting up the server and then visiting:

`http://localhost:3000/benchmark/movies`

or

`http://localhost:3000/benchmark/moviegoers`

Take a look at the code in `app/controller/movies_controller.rb` to see how the preceding commands work. There are a few things to take note of:

* These times are approximations, there is significant overhead caused by loading ActiveRecord objects, so the time spent executing queries is not the same as the time displayed on the page.
* The database may not contain enough movies for these to show significant improvements after you apply migrations to improve the query performance.
* If you wish to see the time spent running database queries, look at the terminal running the rails server and look for a line that looks like:

```
Completed 200 OK in 423ms 
(Views: 8.0ms | ActiveRecord: 200.0ms)
```

The time after ActiveRecord is a better approximation of the actual query time.

A more qualitative method to evaluate performance is to look at what your database's query planner will use to execute the queries. If you are running the virtual machine you can do this by running commands:

```
cd db
sqlite3 development.sqlite3
```

you should see a prompt that looks like:

```
sqlite>
```

If you want to see the plan that sqlite3 expects to use, along with its estimation of the number of rows that it will look through, run:

```
EXPLAIN QUERY PLAN <query>;
```

with <query> replaced by the query you want to investigate. The score action uses

```
@movie.reviews
```

this gets translated to the query:

```
SELECT "reviews".* FROM "reviews" WHERE "reviews"."movie_id" = 1;
```

putting this all together you can see the estimated number of rows viewed by typing in:

```
explain query plan SELECT "reviews".* FROM "reviews" WHERE "reviews"."movie_id" = 1;
```

You will get a result that looks like:

```
SCAN TABLE reviews (~# rows)
```
The number of rows is an approximation, but it is useful for comparing performance between different schema. The skeleton code performs a Table Scan to execute this query. This is one of the reasons that the current implementation will lose performance as the amount of Reviews grows.


Your task is to add a migration, or migrations that will improve the
performance by eliminate the use of table scans for queries such as 
`moviegoer.movies` and `movie.moviegoers`.
```

<details>
<summary>
  To avoid table scan(s) for the query <code>moviegoer.movies</code>, state which
  column(s) of which table(s) should be indexed, and justify your
  answer.
</summary>
<p><blockquote>
To get the movies associated with a moviegoer can be thought of as a
2-step process: (1) get the reviews for that moviegoer; (2) for
each review, get its movie.  Step 1 means that for a given moviegoer
whose id is <code>i</code>,
we want to find all the reviews whose <code>moviegoer_id</code> foreign key has
the value <code>i</code>.  Indexing the <code>moviegoer_id</code> field of <code>reviews</code> will
allow this lookup to happen without scanning the entire <code>reviews</code> table.
</blockquote></p>
</details>


<details>
<summary>
Similarly, state and justify which column(s) of which table(s) should
be indexed to avoid a table scan for <code>movie.moviegoers</code>.
</summary>
<p><blockquote>
By similar logic, the <code>movie_id</code> field of
<code>reviews</code> should be indexed.
</blockquote></p>
</details>


<details>
<summary>
With some databases, the performance boost of an index can be even
faster if the index can be declared <i>unique</i>, that is, if you can
guarantee that there are no repeated values in the indexed column(s).
Can you declare the necessary indices as unique?  Explain why or why not.
</summary>
<p><blockquote>
No, you cannot.  Consider the <code>reviews.movie_id</code> index.  If
a given movie has, say, 5 reviews, there will be 5 rows of the
<code>reviews</code> table where the <code>movie_id</code> column has
the same value.  A similar argument applies for <code>reviews.moviegoer_id</code>.
</blockquote></p>
</details>

Create and apply a
[migration](http://guides.rubyonrails.org/migrations.html) to add the
above indices to the database and deploy to production.

Now re-run the benchmarks and verify using the techniques used
previously that no table scans are being performed.

Note: It may be necessary to add
more Reviews to make this noticeable. You can modify `db/seeds.rb` to
do so.  Why would you expect that differences in performance would be
most noticeable as Reviews are added, but not very noticeable if
Movies and/or Moviegoers are added?



TBD: Come up with a way to have the student express performance
improvement, and under reasonable assumptions, have them use that to
estimate how many times more users they could now serve without adding
more hardware capacity.

# Part 2: Caching

TBD

Some self check questions on caching:


<details>
<summary>
Which design pattern is used to invalidate a cached page after the
underlying data has changed? 
</summary>
<p><blockquote>
The Observer pattern.  Observing a class and interposing on the
ActiveRecord before-save hook lets us know that particular record(s)
are about to be modified, giving us a chance to invalidate any cached
data based on those records.
</blockquote></p>
</details>


<details> <summary> 
Which operations can be avoided when serving views in the Movie model
that have been enhanced with fragment caching?
(a) querying the database; (b) executing the code in the controller
action; (c) generating certain parts of the view; (d) invoking the
Rails app (logic tier) from the web server (presentation tier).
</summary> 
<p><blockquote>
(a) and (c).  If a particular fragment of a view has been previously
computed and cached, the database will not be contacted again, nor
will the view subsystem need to "reconstitute" that view fragment from
the underlying data.  But the controller method (b) still needs to run
(for example, to determine which fragments to select for display in
the view), therefore the app itself (d) must run as well.
</blockquote></p>
</details>
