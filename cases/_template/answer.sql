SELECT * FROM table_name
JOIN tbl_x ON table_name.tbl_x_id = tbl_x.id
WHERE table_name.amount > 0
ORDER BY table_name.amount DESC;