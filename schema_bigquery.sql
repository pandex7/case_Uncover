schema_table_bigquery.sql

CREATE TABLE `exemplo.uncover.leads_sales` (
  Data DATE,
  State STRING,
  Product STRING,
  Leads INT64,
  Qualified_Leads INT64,
  Sales INT64,
  Price FLOAT64
)
PARTITION BY DATE;


CREATE TABLE `exemplo.uncover.CRM` (
  Data DATE,
  State STRING,
  Count INT64
)
PARTITION BY DATE;


CREATE TABLE `exemplo.uncover.sua_tabela` (
  date DATE,
  channel STRING,
  vehicle STRING,
  campaign STRING,
  spent FLOAT64
)
PARTITION BY DATE;