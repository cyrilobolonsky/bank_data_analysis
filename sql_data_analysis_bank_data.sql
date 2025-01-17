/* 1. Creating a table in Postgresql (using pgAdmin 4) to import the the sourcing file (BankChurners.csv [Source: https://www.kaggle.com/datasets/sakshigoyal7/credit-card-customers/data]).*/

CREATE TABLE bank_data_raw (
    clientnum BIGINT,
    attrition_flag VARCHAR(50),
    customer_age INT,
    gender VARCHAR(10),
    dependent_count INT,
    education_level VARCHAR(50),
    marital_status VARCHAR(50),
    income_category VARCHAR(50),
    card_category VARCHAR(50),
    months_on_book INT,
	total_relationship_count INT,
	months_inactive_12_mon INT,	
	contacts_count_12_mon INT,
    credit_limit DECIMAL(15, 2),
    total_revolving_bal INT,
    avg_open_to_buy DECIMAL(15, 2),
    total_amt_chng_q4_q1 DECIMAL(10, 3),
    total_trans_amt INT,
    total_trans_ct INT,
    total_ct_chng_q4_q1 DECIMAL(10, 3),
    avg_utilization_ratio DECIMAL(10, 3),
    naive_bayes_1 DECIMAL(10, 6),
    naive_bayes_2 DECIMAL(10, 6)
);

/* 	2. Uploading the table through the Export/Import function by clicking on the created table in pgAdmin 4.
	3. Adding an index column */
	
ALTER TABLE bank_data_raw
	ADD COLUMN bank_data_raw_id SERIAL;

/*	4. Creating a description table and inserting the descripttion data*/

CREATE TABLE bank_data_description (
	description_id SERIAL PRIMARY KEY, attribute TEXT, value TEXT
);

INSERT INTO bank_data_description (attribute, value)
VALUES ('clientnum', 'Client number - unique identifier for the customer holding the account'),
       ('attrition_flag', 'Internal event (customer activity) variable - if the account is closed then 1 else 0'),
       ('customer_age', 'Demographic variable - Customer''s Age in Years'),
       ('gender', 'Demographic variable - M=Male, F=Female'),
       ('dependent_count', 'Demographic variable - Number of dependents'),
       ('education_level', 'Demographic variable - Educational Qualification of the account holder (example: high school, college graduate, etc.)'),
       ('marital_status', 'Demographic variable - Married, Single, Divorced, Unknown'),
       ('income_category', 'Demographic variable - Annual Income Category of the account holder (< $40K, $40K - 60K, $60K - $80K, $80K-$120K, > $120K, Unknown)'),
       ('card_category', 'Product Variable - Type of Card (Blue, Silver, Gold, Platinum)'),
       ('months_on_book', 'Period of relationship with bank'),
       ('total_relationship_count', 'Total no. of products held by the customer'),
       ('months_inactive_12_mon', 'No. of months inactive in the last 12 months'),
       ('contacts_count_12_mon', 'No. of Contacts in the last 12 months'),
       ('credit_limit', 'Credit Limit on the Credit Card'),
       ('total_revolving_bal', 'Total Revolving Balance on the Credit Card'),
       ('avg_open_to_buy', 'Open to Buy Credit Line (Average of last 12 months)'),
       ('total_amt_chng_q4_q1', 'Change in Transaction Amount (Q4 over Q1) '),
       ('total_trans_amt', 'Total Transaction Amount (Last 12 months)'),
       ('total_trans_ct', 'Total Transaction Count (Last 12 months)'),
       ('total_ct_chng_q4_q1', 'Change in Transaction Count (Q4 over Q1) '),
       ('avg_utilization_ratio', 'Average Card Utilization Ratio'),
	   ('naive_bayes_1', 'Naive Bayes Classifier 1'),
	   ('naive_bayes_2', 'Naive Bayes Classifier 2'),
	   ('bank_data_raw_id', 'Index nb');

-- altering description table

ALTER TABLE bank_data_description
	ADD COLUMN data_type TEXT; 

UPDATE bank_data_description as BD
	SET data_type = c.data_type
	FROM (
			SELECT column_name, data_type
			FROM information_schema.columns
			WHERE table_name='bank_data_raw' 			
		) AS c
	WHERE bd.attribute = c.column_name;
	

/* 5. Filtering data */

-- filtering the names of the table columns

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'bank_data_raw';

-- NULL
SELECT *
FROM bank_data_raw
WHERE clientnum 'Unknown'
	OR attrition_flag 'Unknown'
	OR gender 'Unknown'
	OR card_category 'Unknown'
	OR education_level 'Unknown'
	OR marital_status 'Unknown'
	OR customer_age 'Unknown'
	OR gender 'Unknown';

CREATE OR REPLACE FUNCTION check_nulls_in_table(p_table_name TEXT)
    RETURNS TABLE
            (
                c_name    TEXT,
                has_nulls BOOLEAN
            )
AS
$$
DECLARE
    col_name TEXT;
    has_null BOOLEAN;
BEGIN
    FOR col_name IN (SELECT column_name FROM information_schema.columns WHERE table_name = p_table_name)
        LOOP
            EXECUTE FORMAT('SELECT EXISTS (SELECT 1 FROM %I WHERE %I IS NULL)', p_table_name, col_name) INTO has_null;
            RETURN QUERY SELECT col_name, has_null;
        END LOOP;
END;
$$
    LANGUAGE plpgsql;

--PL Wywołanie funkcji check_nulls_in_table dla tabeli bank_data_raw
--EN Call the check_nulls_in_table function for the bank_data_raw table
SELECT *
FROM check_nulls_in_table('bank_data_raw');

-- DISTINCT function

SELECT DISTINCT attrition_flag FROM bank_data_raw;

SELECT DISTINCT gender FROM bank_data_raw;

-- substracting repeating observations 

SELECT DISTINCT * FROM bank_data_raw;

SELECT DISTINCT COUNT (*) FROM bank_data_raw;

SELECT COUNT(*) AS n
FROM (
	SELECT customer_age, gender, education_level, marital_status, income_category, COUNT(*) AS records
	FROM bank_data_raw
	GROUP BY customer_age, gender, education_level, marital_status, income_category) AS bdr
WHERE records > 1;

SELECT *
FROM (
	SELECT customer_age, gender, education_level, marital_status, income_category, COUNT(*) AS records
	FROM bank_data_raw
	GROUP BY customer_age, gender, education_level, marital_status, income_category) AS bdr
WHERE records > 1;

SELECT COUNT(*) AS total_records, (SELECT DISTINCT COUNT(*) FROM bank_data_raw) AS unique_records
FROM bank_data_raw;

-- GROUP BY

SELECT DISTINCT income_category, COUNT(*) AS n
FROM bank_data_raw
GROUP BY income_category
HAVING COUNT (*) > 1;

SELECT DISTINCT gender, COUNT(*) AS n
FROM bank_data_raw
GROUP BY gender
HAVING COUNT (*) > 1;

/*6. Creating a view of a cleaned data*/

CREATE OR REPLACE VIEW cleaned_bank_data_raw as
	SELECT attrition_flag,
	customer_age,
	gender,
	dependent_count,
	education_level,
	marital_status,
	income_category,
	card_category,
	months_on_book,
	total_relationship_count,
	months_inactive_12_mon,
	contacts_count_12_mon,
	credit_limit,
	total_revolving_bal,
	avg_open_to_buy,
	total_amt_chng_q4_q1,
	total_trans_amt,
	total_trans_ct,
	total_ct_chng_q4_q1,
	avg_utilization_ratio,
	naive_bayes_1,
	naive_bayes_2
	FROM bank_data_raw
	WHERE 	education_level <> 'Unknown'
			AND marital_status <> 'Unknown'
			AND income_category <> 'Unknown'
			AND card_category <> 'Unknown'
			AND gender <> 'Unknown'
			AND attrition_flag <> 'Unknown';

--DROP VIEW cleaned_bank_data_raw;

/*7. Attrition Analysis */

-- gender

CREATE OR REPLACE VIEW attrition_analysis_gender AS
	SELECT 	gender,
			COUNT(*) AS total_nb_customers,
			ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(), 2) AS gender_ratio,
			SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS attrited_customers,
			ROUND((SUM(CASE WHEN attrition_flag='Attrited Customer' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*))*100,2) AS attrition_ratio
	FROM 	cleaned_bank_data_raw
	GROUP BY gender;

CREATE OR REPLACE VIEW attrition_analysis_marital_status AS
	SELECT 	marital_status,
			COUNT(*) AS total_nb_customers,
			ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(), 2) AS marital_status_ratio,
			SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS attrited_customers,
			ROUND((SUM(CASE WHEN attrition_flag='Attrited Customer' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*))*100,2) AS attrition_ratio
	FROM 	cleaned_bank_data_raw
	GROUP BY marital_status;

CREATE OR REPLACE VIEW attrition_analysis_education_level AS
	SELECT 	education_level,
			COUNT(*) AS total_nb_customers,
			ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(), 2) AS education_level_ratio,
			SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS attrited_customers,
			ROUND((SUM(CASE WHEN attrition_flag='Attrited Customer' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*))*100,2) AS attrition_ratio
	FROM 	cleaned_bank_data_raw
	GROUP BY education_level;

-- min and max age

SELECT MIN(customer_age), MAX(customer_age) FROM cleaned_bank_data_raw;

-- age groups

CREATE OR REPLACE VIEW attrition_analysis_age_range AS
	SELECT 
			CASE 	WHEN customer_age BETWEEN 20 AND 30 THEN '20-30'
			 		WHEN customer_age BETWEEN 31 AND 40 THEN '31-40'
					WHEN customer_age BETWEEN 41 AND 50 THEN '41-50'
					WHEN customer_age BETWEEN 51 AND 60 THEN '51-60'
					WHEN customer_age BETWEEN 61 AND 70 THEN '61-70'
					ELSE 'Over 70'
			END															AS age_range,
			COUNT(*)													AS nb_customers,
			ROUND(COUNT(*)*100/SUM(COUNT(*)) OVER(), 2) AS age_range_ratio,
			SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS attrited_customers,
			ROUND((SUM(CASE WHEN attrition_flag='Attrited Customer' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*))*100,2) AS attrition_ratio
	
	FROM 	cleaned_bank_data_raw
	
	GROUP BY age_range
	ORDER BY age_range;

DROP VIEW attrition_analysis_age_range;

CREATE OR REPLACE VIEW attrition_analysis_income_category AS
	SELECT 	income_category,
			COUNT(*) AS total_nb_customers,
			SUM(CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END) AS attrited_customers,
			ROUND((SUM(CASE WHEN attrition_flag='Attrited Customer' THEN 1 ELSE 0 END)::NUMERIC / COUNT(*))*100,2) AS attrition_ratio
	FROM 	cleaned_bank_data_raw
	GROUP BY income_category
	ORDER BY income_category DESC;

-- age group vs. education level
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * FROM crosstab(
	'SELECT DISTINCT income_category, education_level, COUNT(*)::integer
	FROM cleaned_bank_data_raw
	GROUP BY 1,2
	ORDER BY 1,2') AS contingency_table(income_category CHARACTER VARYING, Uneducated INT, High_school INT, College INT, Graduate INT, Doctorate INT, Post_Graduate INT);