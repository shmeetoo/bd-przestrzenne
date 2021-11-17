CREATE TABLE obiekty(id INT PRIMARY KEY, name VARCHAR(20), geom GEOMETRY);

INSERT INTO obiekty(id, name, geom)
VALUES (1, 'obiekt1', ST_GeomFromText('MULTICURVE(LINESTRING(0 1, 1 1), CIRCULARSTRING(1 1, 2 0, 3 1),
									  CIRCULARSTRING(3 1, 4 2, 5 1), LINESTRING(5 1, 6 1))',0)),
		(2, 'obiekt2', ST_GeomFromText('CURVEPOLYGON(COMPOUNDCURVE(LINESTRING(10 6, 14 6), CIRCULARSTRING(14 6, 16 4, 14 2),
									   CIRCULARSTRING(14 2, 12 0, 10 2), LINESTRING(10 2, 10 6)), CIRCULARSTRING(11 2, 13 2, 11 2))',0)),
		(3, 'obiekt3', ST_GeomFromText('POLYGON((7 15, 12 13, 10 17, 7 15))',0)),
		(4, 'obiekt4', ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)',0)),
		(5, 'obiekt5', ST_GeomFromText('MULTIPOINT((30 30 59), (38 32 234))',0)),
		(6, 'obiekt6', ST_GeomFromText('GEOMETRYCOLLECTION(LINESTRING(1 1, 3 2), POINT(4 2))',0));

/* tak też można dodać obiekt1, ale wtedy źle wykonuje się zad 4 - St_HasArc bierze ten obiekt za nieposiadający łuków */
INSERT INTO obiekty(id,name,geom)
VALUES (1, 'obiekt1', ST_LineToCurve(ST_GeomFromText('LINESTRING(0 1, 1 1, 2 0, 3 1, 4 2, 5 1, 6 1)',0)));
		
SELECT id, name, ST_AsText(geom) FROM obiekty;
DROP TABLE obiekty;

/* zad 1 - pole pow. bufora (dł. 5) wokół najkrótszej lini między obiektem 3 i 4 */

SELECT ST_Area(ST_Buffer(ST_ShortestLine(x.geom, y.geom),5)) AS pole_pow
FROM obiekty x, obiekty y WHERE x.name LIKE '%3' AND y.name LIKE '%4';

/* zad 2 - obiekt4 na poligon, jak warunek musi być spełniony? */
/* trzeba "zamknąć" linię, czyli dopisać pierwszy punkt na koniec */

UPDATE obiekty 
SET geom = ST_GeomFromText('POLYGON((20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5, 20 20))',0)
WHERE name = 'obiekt4';

SELECT id, name, ST_AsText(geom) FROM obiekty WHERE name = 'obiekt4';
DROP TABLE obiekty;

/* zad 3 - dodać do tabeli obiekt7 złożony z obiektu 3 i 4 */

INSERT INTO obiekty(id, name, geom)
VALUES (7,'obiekt7',(SELECT ST_Union(x.geom, y.geom) 
					 FROM obiekty x, obiekty y WHERE x.name LIKE '%3' AND y.name LIKE '%4'));
		
SELECT id, name, ST_AsText(geom) FROM obiekty WHERE name = 'obiekt7';
DELETE FROM obiekty WHERE name = 'obiekt7';

/* zad 4 - pole pow. buforów (dł. 5) utworzonych wokół obiektów nie zawierających łuków */
/* ciekawostka! - zobacz dodawanie obiektu 1 */

SELECT name, ST_Area(ST_Buffer(geom,5))
FROM obiekty WHERE NOT ST_HasArc(geom) ORDER BY ST_Area DESC;