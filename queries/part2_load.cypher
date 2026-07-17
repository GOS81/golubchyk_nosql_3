// Індекс для швидкого пошуку користувачів за ID
CREATE CONSTRAINT user_id IF NOT EXISTS FOR (u:User) REQUIRE u.userId IS UNIQUE;

// Індекс для швидкого пошуку фільмів за ID
CREATE CONSTRAINT movie_id IF NOT EXISTS FOR (m:Movie) REQUIRE m.movieId IS UNIQUE;

// Індекс для швидкого пошуку жанрів за назвою
CREATE CONSTRAINT genre_name IF NOT EXISTS FOR (g:Genre) REQUIRE g.name IS UNIQUE;

LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
SET u.gender = row.gender,
    u.age = toInteger(row.age),
    u.occupation = toInteger(row.occupation);

--- Завантаження користувачів ---

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/GOS81/golubchyk_nosql_3/refs/heads/main/import/users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
SET u.gender = row.gender,
    u.age = toInteger(row.age),
    u.occupation = toInteger(row.occupation);

--- Завантаження фільмів та жанрів ---

LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/GOS81/golubchyk_nosql_3/refs/heads/main/import/movies.csv' AS row
MERGE (m:Movie {movieId: toInteger(row.movieId)})
SET m.title = row.title,
    m.genres_list = row.genres
WITH m, row
UNWIND split(row.genres, '|') AS genreName
MERGE (g:Genre {name: genreName})
MERGE (m)-[:HAS_GENRE]->(g);

--- Завантаження ребер (Оцінок) ---

CALL apoc.periodic.iterate(
  "LOAD CSV WITH HEADERS FROM 'https://raw.githubusercontent.com/GOS81/golubchyk_nosql_3/refs/heads/main/import/ratings.csv' AS row RETURN row",
  "MATCH (u:User {userId: toInteger(row.userId)})
   MATCH (m:Movie {movieId: toInteger(row.movieId)})
   MERGE (u)-[r:RATED]->(m)
   SET r.rating = toInteger(row.rating),
       r.timestamp = toInteger(row.timestamp)",
  {batchSize: 10000, parallel: false}
);