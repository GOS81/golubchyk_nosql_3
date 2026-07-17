**Запит 1. Знайти всі фільми жанру «Thriller» із середнім рейтингом вище 4.0**

MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre {name: 'Thriller'})
MATCH (u:User)-[r:RATED]->(m)
WITH m, avg(r.rating) AS avgRating
WHERE avgRating > 4.0
RETURN m.title AS MovieTitle, avgRating AS AverageRating
ORDER BY avgRating DESC
LIMIT 10;

**Запит 2. Знайти користувачів, які поставили оцінку 5 більш ніж 50 фільмам**

MATCH (u:User)-[r:RATED]->(m:Movie)
WHERE r.rating = 5
WITH u, count(m) AS fiveStarCount
WHERE fiveStarCount > 50
RETURN u.userId AS UserID, fiveStarCount AS MoviesCount
ORDER BY fiveStarCount DESC
LIMIT 10;

**Запит 3. Знайти фільми, які обидва користувачі оцінили високо**

MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: 2})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.title AS MovieTitle, r1.rating AS User1Rating, r2.rating AS User2Rating
ORDER BY MovieTitle
LIMIT 10;

**Запит 4. Знайти жанри, чиї фільми стабільно отримують високі оцінки**

MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)<-[r:RATED]-()
WITH g.name AS Genre, avg(r.rating) AS AverageRating, count(r) AS RatingsCount
WHERE RatingsCount > 1000
RETURN Genre, AverageRating, RatingsCount
ORDER BY AverageRating DESC
LIMIT 10;

**Запит 5. Рекомендація «користувачі зі схожими смаками також дивилися»**

// Знаходимо користувача та інших людей, які високо оцінили ті ж самі фільми
MATCH (u:User {userId: 1})-[r1:RATED]->(m1:Movie)<-[r2:RATED]-(similarUser:User)
WHERE r1.rating >= 4 AND r2.rating >= 4

// Шукаємо інші фільми, які високо оцінили ці "схожі" користувачі
MATCH (similarUser)-[r3:RATED]->(m2:Movie)
WHERE r3.rating >= 4

// Виключаємо фільми, які наш цільовий користувач уже бачив
AND NOT (u)-[:RATED]->(m2)

// Рахуємо, скільки схожих користувачів рекомендують кожен фільм
WITH m2, count(DISTINCT similarUser) AS recommendationScore
ORDER BY recommendationScore DESC
LIMIT 10

RETURN m2.title AS RecommendedMovie, recommendationScore AS Score;

**Запит 6. Знайти найкоротший ланцюжок зв’язку між двома користувачами через спільні фільми**

MATCH (u1:User {userId: 1}), (u2:User {userId: 3})
MATCH p = shortestPath((u1)-[:RATED*..6]-(u2))
RETURN p, length(p) AS pathLength;

