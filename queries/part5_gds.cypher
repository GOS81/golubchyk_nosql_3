MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE size([(m1)<-[:RATED]-() | 1]) > 20
  AND size([(m2)<-[:RATED]-() | 1]) > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 2000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;


CALL gds.graph.project(
  'movieGraph',
  'Movie',
  'CO_RATED',
  {
    relationshipProperties: ['weight'],
    undirectedRelationshipTypes: ['CO_RATED'],
    memory: '2GB'
  }
)
YIELD graphName, nodeCount, relationshipCount;


CALL gds.pageRank.stream('movieGraph')
YIELD nodeId, score
RETURN gds.util.asNode(nodeId).title AS MovieTitle, score AS PageRankScore
ORDER BY score DESC
LIMIT 10;


CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() DELETE co;


MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 2000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

CALL gds.graph.project(
  'userSimilarity',
  'User',
  'SIMILAR',
  {
    relationshipProperties: ['weight'],
    undirectedRelationshipTypes: ['SIMILAR'],
    memory: '2GB'
  }
)
YIELD graphName, nodeCount, relationshipCount;

CALL gds.louvain.write('userSimilarity', { writeProperty: 'communityId' })
YIELD communityCount, nodePropertiesWritten, modularity;

MATCH (u:User)-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE r.rating >= 4 AND u.communityId IS NOT NULL
WITH u.communityId AS clusterId, g.name AS genre, count(r) AS ratingCount
ORDER BY clusterId, ratingCount DESC
WITH clusterId, collect(genre)[0..3] AS topGenres, sum(ratingCount) AS totalRatings
ORDER BY totalRatings DESC
LIMIT 5
RETURN clusterId AS Cluster, topGenres AS Top3Genres, totalRatings AS TotalHighRatings;

CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-() DELETE sim;

MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating >= 4 AND r2.rating >= 4 AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
ORDER BY weight DESC
LIMIT 2000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

WITH 1 AS dummy
CALL gds.graph.project(
  'userGraph',
  'User',
  'SIMILAR',
  {
    relationshipProperties: ['weight'],
    undirectedRelationshipTypes: ['SIMILAR'],
    memory: '2GB'
  }
)
YIELD graphName, nodeCount, relationshipCount
RETURN graphName, nodeCount, relationshipCount;

MATCH path = shortestPath((u1:User)-[:SIMILAR*1..5]-(u2:User))
WHERE id(u1) < id(u2) AND length(path) > 1
RETURN u1.userId AS StartNode, u2.userId AS EndNode, length(path) AS PathLength
LIMIT 5;

MATCH (start:User {userId: 10}), (end:User {userId: 36})
CALL gds.shortestPath.dijkstra.stream('userGraph', {
    sourceNode: start,
    targetNode: end
})
YIELD totalCost, nodeIds
RETURN totalCost AS Hops,
       [id IN nodeIds | gds.util.asNode(id).userId] AS Path;

CALL gds.graph.drop('userGraph');
MATCH ()-[sim:SIMILAR]-() DELETE sim;

