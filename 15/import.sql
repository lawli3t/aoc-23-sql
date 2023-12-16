CREATE TABLE instructions (
    id int,
    elements char[]
);

INSERT INTO instructions
SELECT
    idx,
    string_to_array(elem, NULL)
FROM input, unnest(string_to_array(line, ',')) WITH ORDINALITY AS a (elem, idx);
