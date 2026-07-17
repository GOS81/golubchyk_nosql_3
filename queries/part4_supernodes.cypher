MATCH (n)
WITH n, COUNT { (n)--() } AS rel_count
ORDER BY rel_count DESC
LIMIT 10
RETURN labels(n)[0] AS NodeType, 
       coalesce(n.title, n.name, toString(n.userId)) AS NodeName, 
       rel_count AS TotalRelationships;

       