-- postgres -D C:/testDB -p 5555
-- psql -d test -p 5555 -U admin

-- \l
-- \c test
-- \dn
-- \dt

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO public;
GRANT ALL ON SCHEMA public TO admin;

CREATE TABLE series (
id SERIAL PRIMARY KEY,
name VARCHAR NOT NULL,
description VARCHAR,
language VARCHAR,
isFinished BOOLEAN DEFAULT FALSE,
isScanlated BOOLEAN DEFAULT FALSE,
isLicensed BOOLEAN DEFAULT FALSE,
startDate DATE,
endDate DATE
);

CREATE TABLE authors (
id SERIAL PRIMARY KEY,
name VARCHAR NOT NULL,
description VARCHAR,
birthDate DATE,
deathDate DATE,
isWorking BOOLEAN
);

CREATE TABLE scanlators (
id SERIAL PRIMARY KEY,
name VARCHAR NOT NULL,
description VARCHAR,
website VARCHAR,
twitter VARCHAR,
facebook VARCHAR,
email VARCHAR
);

CREATE TABLE releases (
id SERIAL PRIMARY KEY,
seriesID INTEGER REFERENCES series(id),
description VARCHAR NOT NULL,
numChapters INTEGER DEFAULT 1,
scanlatorID1 INTEGER REFERENCES scanlators(id),
scanlatorID2 INTEGER REFERENCES scanlators(id),
scanlatorID3 INTEGER REFERENCES scanlators(id),
hyperlink VARCHAR,
releaseDate DATE
);

CREATE TABLE tags (
id SERIAL PRIMARY KEY,
name VARCHAR NOT NULL,
description VARCHAR
);

CREATE TABLE magazines (
id SERIAL PRIMARY KEY,
name VARCHAR NOT NULL,
description VARCHAR,
startDate DATE,
endDate DATE
);


-- Entries that are related to each other
CREATE TABLE seriesToSeries (
seriesID1 INTEGER REFERENCES series(id),
seriesID2 INTEGER REFERENCES series(id),
description VARCHAR,
PRIMARY KEY (seriesID1, seriesID2)
);

CREATE TABLE seriesToAuthor (
seriesID INTEGER REFERENCES series(id),
authorID INTEGER REFERENCES authors(id),
description VARCHAR,
PRIMARY KEY (seriesID, authorID)
);

CREATE TABLE seriesToMagazine (
seriesID INTEGER REFERENCES series(id),
magazineID INTEGER REFERENCES magazines(id),
startDate DATE,
endDate DATE,
PRIMARY KEY (seriesID, magazineID, startDate)
);

CREATE TABLE seriesToTag (
seriesID INTEGER REFERENCES series(id),
tagID INTEGER REFERENCES tags(id),
isSpoiler BOOLEAN DEFAULT FALSE,
PRIMARY KEY (seriesID, tagID)
);

CREATE TABLE magazineToMagazine (
magazineID1 INTEGER REFERENCES magazines(id),
magazineID2 INTEGER REFERENCES magazines(id),
description VARCHAR,
PRIMARY KEY (magazineID1, magazineID2)
);


-- Entries with alternate names
CREATE TABLE seriesAltName (
seriesID INTEGER REFERENCES series(id),
name VARCHAR,
PRIMARY KEY (seriesID, name)
);

CREATE TABLE authorAltName (
authorID INTEGER REFERENCES authors(id),
name VARCHAR,
PRIMARY KEY (authorID, name)
);

CREATE TABLE scanlatorAltName (
scanlatorID INTEGER REFERENCES scanlators(id),
name VARCHAR,
PRIMARY KEY (scanlatorID, name)
);



-- Views
CREATE OR REPLACE VIEW authorToAuthor AS
SELECT a1.authorID as authorID1, a2.authorID as authorID2, a1.seriesID
FROM seriesToAuthor a1, seriesToAuthor a2
WHERE a1.seriesID=a2.seriesID AND a1.authorID!=a2.authorID;

CREATE OR REPLACE VIEW authorToMagazine AS
SELECT a.authorID, m.magazineID, count(m.seriesID)
FROM seriesToAuthor a,
(SELECT DISTINCT magazineID, seriesID
FROM seriesToMagazine) m
WHERE m.seriesID=a.seriesID
GROUP BY a.authorID, m.magazineID;

CREATE OR REPLACE VIEW authorToTag AS
SELECT a.authorID, t.tagID, count(a.seriesID)
FROM seriesToAuthor a, seriesToTag t
WHERE a.seriesID=t.seriesID
GROUP BY a.authorID, t.tagID;

CREATE OR REPLACE VIEW magazineToTag AS
SELECT m.magazineID, t.tagID, count(m.seriesID)
FROM seriesToTag t,
(SELECT DISTINCT magazineID, seriesID
FROM seriesToMagazine) m
WHERE m.seriesID=t.seriesID
GROUP BY m.magazineID, t.tagID;


-- SELECT * FROM scanlatorToSeries WHERE <<input>>=scanlatorID1 OR <<input>>=scanlatorID2 OR <<input>>=scanlatorID3;
CREATE OR REPLACE VIEW scanlatorToSeries AS
SELECT DISTINCT r.scanlatorID1, r.scanlatorID2, r.scanlatorID3, r.seriesID, t.tagID
FROM releases r, seriesToTag t
WHERE r.seriesID=t.seriesID;

-- SELECT * FROM scanlatorToTag WHERE <<input>>=scanlatorID1 OR <<input>>=scanlatorID2 OR <<input>>=scanlatorID3;
CREATE OR REPLACE VIEW scanlatorToTag AS
SELECT scanlatorID1, scanlatorID2, scanlatorID3, tagID, count(seriesID)
FROM scanlatorToSeries
GROUP BY scanlatorID1, scanlatorID2, scanlatorID3, tagID;