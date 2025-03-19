CREATE TABLE IF NOT EXISTS tbl_x (
	id serial8 NOT NULL,
	name varchar NOT NULL,
	timestamp timestamp NOT NULL,
	CONSTRAINT tbl_x_pk PRIMARY KEY (id)
);
CREATE TABLE IF NOT EXISTS table_name (
	id serial8 NOT NULL,
	tbl_x_id int NOT NULL,
	name varchar NOT NULL,
	amount float DEFAULT 0 NULL,
	timestamp timestamp NOT NULL,
	CONSTRAINT tbl_pk PRIMARY KEY (id),
	CONSTRAINT fk_tbl_x FOREIGN KEY(tbl_x_id)
        REFERENCES tbl_x(id),
);

TRUNCATE TABLE table_name;

INSERT INTO table_name (id, tabl_x_id, name, amount, created_date, timestamp) VALUES
(1, 1, 'A', 100, '2020-01-01', '2020-01-01 00:00:00'),
(2, 1, 'B', 200, '2020-01-02', '2020-01-02 00:00:00'),
(3, 1, 'C', 300, '2020-01-03', '2020-01-03 00:00:00'),
(4, 1, 'D', 400, '2020-01-04', '2020-01-04 00:00:00'),
(5, 1, 'E', 500, '2020-01-05', '2020-01-05 00:00:00');

INSERT INTO tbl_x (id, name, timestamp) VALUES
(1, 'X', '2020-01-01 00:00:00');