CREATE TABLE IF NOT EXISTS sales (
	sale_id serial8 NOT NULL,
	customer_id int NOT NULL,
	product_id int NOT NULL,
	store_id int NOT NULL,
	payment_method varchar NOT NULL,
	sale_date date NOT NULL,
	sale_amount float DEFAULT 0 NULL,
	sale_timestamp varchar NOT NULL,
	timestamp_ timestamp NOT NULL,
	CONSTRAINT sales_pk PRIMARY KEY (sale_id),
	CONSTRAINT fk_customer FOREIGN KEY(customer_id)
        REFERENCES customers(customer_id),
    CONSTRAINT fk_product FOREIGN KEY(product_id)
        REFERENCES products(product_id),
    CONSTRAINT fk_store FOREIGN KEY(store_id)
        REFERENCES stores(store_id)
);
CREATE TABLE IF NOT EXISTS customers (
	customer_id serial8 NOT NULL,
	first_name varchar NOT NULL,
	last_name varchar NOT NULL,
	email varchar NOT NULL,
	birth_date date NOT NULL,
	registration_date timestamp NOT NULL,
	city varchar NOT NULL,
	state varchar NOT NULL,
	country varchar NOT NULL,
	zip_code varchar NOT NULL,
	account_status varchar NOT NULL,
	CONSTRAINT customers_pk PRIMARY KEY (customer_id)
);
CREATE TABLE IF NOT EXISTS products (
	product_id serial8 NOT NULL,
	product_name varchar NOT NULL,
	price float NOT NULL,
	"cost" float NOT NULL,
	discount_percentage float NOT NULL,
	is_seasonal bool DEFAULT FALSE NULL,
	is_active bool DEFAULT FALSE NULL,
	created_at timestamp NOT NULL,
	CONSTRAINT products_pk PRIMARY KEY (product_id)
);
CREATE TABLE IF NOT EXISTS product_category_mapping (
	product_id int NOT NULL,
	category_id int NOT NULL,
	CONSTRAINT fk_product FOREIGN KEY(product_id)
        REFERENCES products(product_id),
	CONSTRAINT fk_category FOREIGN KEY(category_id)
        REFERENCES product_categories(category_id)
)
;
CREATE TABLE IF NOT EXISTS product_categories (
	category_id serial8 NOT NULL,
	category_name varchar NOT NULL,
	parent_category varchar NOT NULL,
	top_level_category varchar NOT NULL,
	created_at timestamp NOT NULL,
	CONSTRAINT product_categories_pk PRIMARY KEY (category_id)
)
;
CREATE TABLE IF NOT EXISTS stores (
	store_id serial8 NOT NULL,
	region_id int NOT NULL,
	store_name varchar NOT NULL,
	address varchar NOT NULL,
	city varchar NOT NULL,
	state varchar NOT NULL,
	country varchar NOT NULL,
	zip_code varchar NOT NULL,
	opening_date date NOT NULL,
	square_footage float NOT NULL,
	latitude float NOT NULL,
	longitude float NOT NULL,
	is_active bool DEFAULT FALSE NOT NULL,
	CONSTRAINT stores_pk PRIMARY KEY (store_id),
	CONSTRAINT fk_region FOREIGN KEY(region_id)
        REFERENCES regions(region_id)
);
CREATE TABLE IF NOT EXISTS regions (
	region_id serial8 NOT NULL,
	region_name varchar NOT NULL,
	region_manager varchar NOT NULL,
	CONSTRAINT regions_pk PRIMARY KEY (region_id)
);