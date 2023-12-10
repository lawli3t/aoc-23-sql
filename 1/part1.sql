WITH digits AS (
    SELECT
	substring(line from '\d') AS digit1,
	substring(reverse(line) from '\d') AS digit2
    FROM input
)

SELECT SUM((digit1 || digit2)::int) FROM digits;
