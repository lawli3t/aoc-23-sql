DROP TABLE IF EXISTS walk;
DROP TABLE IF EXISTS nodes;
DROP TYPE IF EXISTS direction;

CREATE TYPE direction AS ENUM ('L', 'R');

CREATE TABLE walk (
    id SERIAL,
    direction direction
);

CREATE UNIQUE INDEX ON walk(id);

INSERT INTO walk(direction)
SELECT direction::direction FROM (
    SELECT unnest(string_to_array(line, NULL)) AS direction FROM input WHERE id = 1
) x;

CREATE TABLE nodes (
    id SERIAL,
    name TEXT,
    l int,
    l_name TEXT,
    r int,
    r_name TEXT
);

CREATE UNIQUE INDEX ON nodes(id);

INSERT INTO nodes (name, l_name, r_name)
SELECT split[1], split[2], split[3] FROM (
    SELECT regexp_match(line, '.*([A-Z]{3}).*([A-Z]{3}).*([A-Z]{3})') split FROM input WHERE id > 2
) x;

UPDATE nodes SET l = (SELECT id FROM nodes n WHERE n.name = nodes.l_name);
UPDATE nodes SET r = (SELECT id FROM nodes n WHERE n.name = nodes.r_name);
