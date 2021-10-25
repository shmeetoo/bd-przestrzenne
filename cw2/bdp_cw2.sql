/* zad 4 - liczba budynków w odl. < 1000m od głównych rzek, zapisać budynki do tableB */

SELECT COUNT(p.f_codedesc) FROM popp p, majrivers mr
WHERE ST_Distance(p.geom,mr.geom) < 1000 AND p.f_codedesc = 'Building';

SELECT p.* INTO tableB FROM popp p, majrivers mr
WHERE St_Distance(p.geom,mr.geom) < 1000 AND p.f_codedesc = 'Building';

SELECT * FROM tableB;

/* zad 5 */ 
/* import danych do airportsNew */
			
SELECT name, geom, elev INTO airportsNew FROM airports;

/* znaleźć lotnisko najbardziej na: 
   -wschód */
SELECT name, ST_X(geom) FROM airportsNew
ORDER BY ST_X(geom) DESC LIMIT 1;

/* -zachód */
SELECT name, ST_X(geom) FROM airportsNew
ORDER BY ST_X(geom) ASC LIMIT 1;
			
/* dodać nowe lotnisko położone w punkcie środkowym drogi między lotniskami wyżej */

INSERT INTO airportsNew(name, geom, elev)
VALUES ('airportB', (SELECT ST_Centroid(ST_MakeLine((SELECT geom FROM airportsNew WHERE name = 'ANNETTE ISLAND'),
								  					(SELECT geom FROM airportsNew WHERE name = 'ATKA')))), 150);
										  
SELECT * FROM airportsNew;

/* zad 6 - pole obszaru oddalonego o 1000 od najkrótszej lini łączącej Iliamna lake  i lotniko AMBLER */

SELECT ST_Area(ST_Buffer(ST_ShortestLine(l.geom, a.geom), 1000)) 
FROM lakes l, airports a WHERE l.names = 'Iliamna Lake' AND a.name = 'AMBLER';


/* zad 7 - zwrócić sumaryczne pole pow. poligonów reprezentujących poszczególne typy drzew znajdujących się na obszarze tundry i bagien */

SELECT SUM(ST_Area(tr.geom)), tr.vegdesc FROM trees tr, swamp s, tundra tu
WHERE ST_Within(tr.geom, tu.geom) OR ST_Within(tr.geom, s.geom)
GROUP BY tr.vegdesc;

