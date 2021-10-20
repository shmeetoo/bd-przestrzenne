/* zad 4 & 5 - tworzenie i uzupełnianie tabel */

CREATE TABLE buildings(id INT PRIMARY KEY NOT NULL, geometry GEOMETRY, name VARCHAR(30) NOT NULL);
CREATE TABLE roads(id INT PRIMARY KEY NOT NULL, geometry GEOMETRY, name VARCHAR(30) NOT NULL);
CREATE TABLE poi(id INT PRIMARY KEY NOT NULL, geometry GEOMETRY, name VARCHAR(30) NOT NULL);

INSERT INTO buildings(id, geometry, name)
VALUES (1, ST_GeomFromText('POLYGON((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))', 0), 'BuildingA'),
		(2, ST_GeomFromText('POLYGON((4 5, 6 5, 6 7, 4 7, 4 5))', 0), 'BuildingB'),
		(3, ST_GeomFromText('POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))', 0), 'BuildingC'),
		(4, ST_GeomFromText('POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))', 0), 'BuildingD'),
		(5, ST_GeomFromText('POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))', 0), 'BuildingF');

INSERT INTO roads(id, geometry, name)
VALUES (1, ST_GeomFromText('LINESTRING(7.5 0, 7.5 10.5)', 0), 'RoadY'),
		(2, ST_GeomFromText('LINESTRING(0 4.5, 12 4.5)', 0), 'RoadX');
		
INSERT INTO poi(id, geometry, name)
VALUES (1, ST_GeomFromText('POINT(1 3.5)', 0), 'G'),
		(2, ST_GeomFromText('POINT(5.5 1.5)', 0), 'H'),
		(3, ST_GeomFromText('POINT(9.5 6)', 0), 'I'),
		(4, ST_GeomFromText('POINT(6.5 6)', 0), 'J'),
		(5, St_GeomFromText('POINT(6 9.5)', 0), 'K');
		
/* zad 6a - całkowita długość dróg */

SELECT SUM(ST_Length(geometry)) FROM roads WHERE name LIKE 'Road%';

/* zad 6b - wypisać geometrię, pole pow. i obwód poligonu "BuildingA" */

SELECT ST_AsText(geometry) AS geometry, ST_Area(geometry) AS pole_powierzchni, ST_Perimeter(geometry) AS obwod
FROM buildings WHERE name = 'BuildingA';

/* zad 6c - nazwy i pola pow. poligonow z tab. buildings posortowane alfabetycznie */

SELECT name, ST_Area(geometry) FROM buildings ORDER BY name;

/* zad 6d - wypisać nazwy i obwody 2 największych budynków */

SELECT name, ST_Perimeter(geometry) FROM buildings
ORDER BY ST_Area(geometry) DESC LIMIT 2;

/* zad 6e - najkrótsza odległość między BuildingC a pkt G */

SELECT ST_Distance(buildings.geometry, poi.geometry) AS odleglosc FROM buildings, poi
WHERE buildings.name LIKE 'BuildingC' AND poi.name LIKE 'G';

/* zad 6f - pole pow. części BuildingC, która jest dalej niż 0.5 od BuildingB */

SELECT ST_Area(ST_Difference((SELECT geometry FROM buildings WHERE name = 'BuildingC'),
							 ST_Buffer((SELECT geometry FROM buildings WHERE name = 'BuildingB'), 0.5)));

/* zad 6g - budynki, których centroid znajduje się powyżej RoadX */

SELECT buildings.name FROM buildings, roads 
WHERE ST_Y(ST_Centroid(buildings.geometry)) > ST_Y(ST_Centroid(roads.geometry)) 
AND roads.name = 'RoadX';

/* zad 6g - pole pow. części BuildingC i poligonu, które nie są wspólne dla tych dwóch obiektów */

SELECT ST_Area(ST_SymDifference(geometry, ST_GeomFromText('POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))', 0)))
FROM buildings WHERE name = 'BuildingC';

DROP TABLE buildings, roads, poi;