-- Sample data source for Superset: a separate database next to the Superset metadata database.
CREATE DATABASE analytics;
\connect analytics
CREATE TABLE orders (
  id serial PRIMARY KEY,
  ordered_at date NOT NULL,
  country text NOT NULL,
  product text NOT NULL,
  quantity int NOT NULL,
  amount numeric(10, 2) NOT NULL
);
INSERT INTO orders (ordered_at, country, product, quantity, amount) VALUES
  ('2026-01-05', 'DE', 'keyboard', 2, 120.00),
  ('2026-01-11', 'TR', 'monitor', 1, 210.50),
  ('2026-02-02', 'US', 'keyboard', 5, 300.00),
  ('2026-02-14', 'DE', 'mouse', 10, 150.00),
  ('2026-03-01', 'TR', 'mouse', 4, 60.00),
  ('2026-03-20', 'US', 'monitor', 2, 420.00);
