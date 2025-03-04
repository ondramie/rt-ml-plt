-- src/arroyo/fraud_pipeline.sql

CREATE TABLE transactions_raw (
    id VARCHAR,
    amount DOUBLE,
    ip VARCHAR
) WITH (
    connector = 'kafka',
    topic = 'transactions_raw',
    type = 'source',
    bootstrap_servers = 'kafka:9092',
    format = 'json'
);

CREATE TABLE transaction_scores (
    id VARCHAR,
    action VARCHAR,
    score DOUBLE
) WITH (
    connector = 'kafka',
    type = 'sink',
    topic = 'transaction_scores',
    bootstrap_servers = 'kafka:9092',
    format = 'json'
);

INSERT INTO transaction_scores
SELECT
    id,
    CASE
        WHEN amount > 10000 AND ip = 'foreign' THEN 'BLOCK'
        ELSE 'PASS'
    END AS action,
    CASE
        WHEN amount > 5000 THEN 0.8
        ELSE 0.1
    END AS score
FROM transactions_raw;
