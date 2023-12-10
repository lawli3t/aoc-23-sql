WITH digit_words AS (
    VALUES
    ('one', 1),
    ('two', 2),
    ('three', 3),
    ('four', 4),
    ('five', 5),
    ('six', 6),
    ('seven', 7),
    ('eight', 8),
    ('nine', 9)
),
digits AS (
    SELECT
	substring(line from '\d|one|two|three|four|five|six|seven|eight|nine') AS digit1,
	substring(line from '^.*(\d|one|two|three|four|five|six|seven|eight|nine).*$') AS digit2
    FROM input
)

SELECT SUM(digit1_value * 10 + digit2_value) FROM (
    SELECT
	COALESCE(d1.column2, digit1::int) AS digit1_value,
	COALESCE(d2.column2, digit2::int) AS digit2_value 
    FROM digits
	LEFT OUTER JOIN digit_words d1 ON d1.column1 = digit1
	LEFT OUTER JOIN digit_words d2 ON d2.column1 = digit2
) AS x;
