CREATE TABLE merchants (
    merchant_id INT PRIMARY KEY,
    merchant_name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    country VARCHAR(100),
    onboarding_date DATE,
    risk_tier VARCHAR(50)
); 

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    age INT,
    city VARCHAR(100),
    segment VARCHAR(50),
    join_date DATE
); 

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    merchant_id INT,
    amount DECIMAL(10, 2),
    transaction_date TIMESTAMP,
    is_fraud INT, 
    is_refund INT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
); 

CREATE TABLE complaints (
    complaint_id INT PRIMARY KEY,
    transaction_id INT,
    merchant_id INT,
    complaint_type VARCHAR(100),
    complaint_date DATE,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
); 

CREATE TABLE chargebacks (
    chargeback_id INT PRIMARY KEY,
    transaction_id INT,
    merchant_id INT,
    amount DECIMAL(10, 2),
    chargeback_date DATE,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    FOREIGN KEY (merchant_id) REFERENCES merchants(merchant_id)
); 

-- 1. Load Customers
COPY customers(customer_id, age, city, segment, join_date)
FROM 'D:\DATA Analysis\Projects\Merchant Risk & Opportunity Intelligence System\Raw_CSVs\customers.csv'
DELIMITER ',' CSV HEADER;

-- 2. Load Merchants
COPY merchants(merchant_id, merchant_name, category, country, onboarding_date, risk_tier)
FROM 'D:\DATA Analysis\Projects\Merchant Risk & Opportunity Intelligence System\Raw_CSVs\merchants.csv'
DELIMITER ',' CSV HEADER;

-- 3. Load Transactions
COPY transactions(transaction_id, customer_id, merchant_id, amount, transaction_date, is_fraud, is_refund)
FROM 'D:\DATA Analysis\Projects\Merchant Risk & Opportunity Intelligence System\Raw_CSVs\transactions.csv'
DELIMITER ',' CSV HEADER;

-- 4. Load Complaints
COPY complaints(complaint_id, transaction_id, merchant_id, complaint_type, complaint_date)
FROM 'D:\DATA Analysis\Projects\Merchant Risk & Opportunity Intelligence System\Raw_CSVs\complaints.csv'
DELIMITER ',' CSV HEADER;

-- 5. Load Chargebacks
COPY chargebacks(chargeback_id, transaction_id, merchant_id, amount, chargeback_date)
FROM 'D:\DATA Analysis\Projects\Merchant Risk & Opportunity Intelligence System\Raw_CSVs\chargebacks.csv'
DELIMITER ',' CSV HEADER;

-- Sanity Checks
SELECT COUNT(*) FROM customers; -- = 5000
SELECT COUNT(*) FROM merchants; -- = 200
SELECT COUNT(*) FROM transactions; -- = 60000
SELECT COUNT(*) FROM complaints; -- = 3500
SELECT COUNT(*) FROM chargebacks; -- = 2500

SELECT COUNT(*) FROM transactions WHERE customer_id IS NULL; -- = 0
SELECT COUNT(*) FROM transactions WHERE merchant_id IS NULL; -- = 0

SELECT MIN(transaction_date), MAX(transaction_date) FROM transactions; -- = 2024-01-01 to 2025-12-30

-- Total Transactions and Revenue

CREATE VIEW merchant_base AS -- Creates a view which can be viewed anytime and has no affect in the main data
SELECT
    m.merchant_id,
    m.merchant_name,
    m.category,
    m.country,
    COUNT(t.transaction_id) AS total_transactions,
    COUNT(DISTINCT t.customer_id) AS active_customers,
    SUM(t.amount) AS total_revenue,
    AVG(t.amount) AS avg_ticket_size
FROM merchants m
LEFT JOIN transactions t
    ON m.merchant_id = t.merchant_id
GROUP BY m.merchant_id, m.merchant_name, m.category, m.country;

-- Fraud and Redund rate

CREATE VIEW merchant_risk_metrics AS
SELECT
    merchant_id,
    COUNT(*) AS total_txn,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS fraud_rate,
    SUM(CASE WHEN is_refund = 1 THEN 1 ELSE 0 END) * 1.0 / COUNT(*) AS refund_rate
FROM transactions
GROUP BY merchant_id;

SELECT * FROM merchant_risk_metrics;

--  Complaint rates

CREATE VIEW merchant_complaint_metrics AS
SELECT
    t.merchant_id,
    COUNT(c.complaint_id) * 1.0 / COUNT(DISTINCT t.transaction_id) AS complaint_rate
FROM transactions t
LEFT JOIN complaints c
    ON t.transaction_id = c.transaction_id
GROUP BY t.merchant_id;

SELECT * FROM merchant_complaint_metrics;

-- Chargeback rates

CREATE VIEW merchant_chargeback_metrics AS
SELECT
    t.merchant_id,
    COUNT(cb.chargeback_id) * 1.0 / COUNT(DISTINCT t.transaction_id) AS chargeback_rate
FROM transactions t
LEFT JOIN chargebacks cb
    ON t.transaction_id = cb.transaction_id
GROUP BY t.merchant_id;

SELECT * FROM merchant_chargeback_metrics;

-- Computing last 3 months vs Previous 3 months revenue

CREATE VIEW merchant_growth AS
WITH monthly_revenue AS (
    SELECT
        merchant_id,
        DATE_TRUNC('month', transaction_date) AS month,
        SUM(amount) AS revenue
    FROM transactions
    GROUP BY merchant_id, DATE_TRUNC('month', transaction_date)
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY merchant_id ORDER BY month DESC) AS rn
    FROM monthly_revenue
)
SELECT
    merchant_id,
    SUM(CASE WHEN rn BETWEEN 1 AND 3 THEN revenue ELSE 0 END) AS last_3m_revenue,
    SUM(CASE WHEN rn BETWEEN 4 AND 6 THEN revenue ELSE 0 END) AS prev_3m_revenue,
    CASE 
        WHEN SUM(CASE WHEN rn BETWEEN 4 AND 6 THEN revenue ELSE 0 END) = 0 THEN NULL
        ELSE
        (SUM(CASE WHEN rn BETWEEN 1 AND 3 THEN revenue ELSE 0 END) -
         SUM(CASE WHEN rn BETWEEN 4 AND 6 THEN revenue ELSE 0 END)) * 1.0 /
         SUM(CASE WHEN rn BETWEEN 4 AND 6 THEN revenue ELSE 0 END)
    END AS growth_rate
FROM ranked
GROUP BY merchant_id;

SELECT * FROM merchant_growth;

-- Feature Table

CREATE VIEW merchant_features AS
SELECT
    b.merchant_id,
    b.merchant_name,
    b.category,
    b.country,
    b.total_transactions,
    b.active_customers,
    b.total_revenue,
    b.avg_ticket_size,
    r.fraud_rate,
    r.refund_rate,
    c.complaint_rate,
    cb.chargeback_rate,
    g.growth_rate
FROM merchant_base b
LEFT JOIN merchant_risk_metrics r ON b.merchant_id = r.merchant_id
LEFT JOIN merchant_complaint_metrics c ON b.merchant_id = c.merchant_id
LEFT JOIN merchant_chargeback_metrics cb ON b.merchant_id = cb.merchant_id
LEFT JOIN merchant_growth g ON b.merchant_id = g.merchant_id;

SELECT * FROM merchant_features LIMIT 20;

-- merchants by performance and risk using window functions

SELECT
    *,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    NTILE(4) OVER (ORDER BY total_revenue DESC) AS revenue_quartile,
    NTILE(4) OVER (ORDER BY fraud_rate ASC) AS risk_quartile
FROM merchant_features;

-- Risk Buckets

SELECT
    *,
    CASE 
        WHEN fraud_rate > 0.08 OR chargeback_rate > 0.05 THEN 'High Risk'
        WHEN fraud_rate > 0.04 OR chargeback_rate > 0.02 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_bucket
FROM merchant_features;

--Business View

CREATE VIEW merchant_business_view AS
SELECT
    *,
    CASE 
        WHEN growth_rate > 0.2 AND fraud_rate < 0.04 THEN 'High Opp / Low Risk'
        WHEN growth_rate > 0.2 AND fraud_rate >= 0.04 THEN 'High Opp / High Risk'
        WHEN growth_rate <= 0.2 AND fraud_rate < 0.04 THEN 'Low Opp / Low Risk'
        ELSE 'Low Opp / High Risk'
    END AS business_quadrant
FROM merchant_features;
SELECT * FROM merchant_business_view;


-- Merchant BI view

CREATE VIEW merchant_bi_view AS
WITH base_txn AS (
    SELECT
        t.merchant_id,
        COUNT(*) AS total_txns,
        SUM(t.amount) AS total_revenue,
        SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END) AS fraud_txns,
        SUM(CASE WHEN t.is_refund = 1 THEN 1 ELSE 0 END) AS refund_txns
    FROM transactions t
    GROUP BY t.merchant_id
),

chargebacks_agg AS (
    SELECT
        merchant_id,
        COUNT(*) AS chargeback_cnt
    FROM chargebacks
    GROUP BY merchant_id
),

complaints_agg AS (
    SELECT
        merchant_id,
        COUNT(*) AS complaint_cnt
    FROM complaints
    GROUP BY merchant_id
),

-- Revenue growth: last 3 months vs previous 3 months (Postgres syntax)
revenue_growth AS (
    SELECT
        t.merchant_id,
        SUM(
            CASE 
                WHEN t.transaction_date >= CURRENT_DATE - INTERVAL '3 months'
                THEN t.amount ELSE 0 
            END
        ) AS recent_revenue,
        SUM(
            CASE 
                WHEN t.transaction_date <  CURRENT_DATE - INTERVAL '3 months'
                 AND t.transaction_date >= CURRENT_DATE - INTERVAL '6 months'
                THEN t.amount ELSE 0 
            END
        ) AS past_revenue
    FROM transactions t
    GROUP BY t.merchant_id
),

metrics AS (
    SELECT
        m.merchant_id,
        m.merchant_name,
        m.category,
        m.country,

        bt.total_revenue,

        -- growth rate
        CASE 
            WHEN rg.past_revenue = 0 OR rg.past_revenue IS NULL THEN NULL
            ELSE (rg.recent_revenue - rg.past_revenue) / rg.past_revenue
        END AS growth_rate,

        -- rates
        bt.fraud_txns * 1.0 / NULLIF(bt.total_txns, 0) AS fraud_rate,
        COALESCE(cb.chargeback_cnt, 0) * 1.0 / NULLIF(bt.total_txns, 0) AS chargeback_rate,
        COALESCE(cp.complaint_cnt, 0) * 1.0 / NULLIF(bt.total_txns, 0) AS complaint_rate

    FROM merchants m
    LEFT JOIN base_txn bt ON m.merchant_id = bt.merchant_id
    LEFT JOIN chargebacks_agg cb ON m.merchant_id = cb.merchant_id
    LEFT JOIN complaints_agg cp ON m.merchant_id = cp.merchant_id
    LEFT JOIN revenue_growth rg ON m.merchant_id = rg.merchant_id
),

scored AS (
    SELECT
        *,
        CASE
            WHEN fraud_rate > 0.05 OR chargeback_rate > 0.03 THEN 'High Risk'
            WHEN fraud_rate > 0.02 OR chargeback_rate > 0.01 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS risk_bucket
    FROM metrics
),

final_ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        NTILE(4) OVER (ORDER BY total_revenue DESC) AS revenue_quartile
    FROM scored
)

SELECT
    merchant_id,
    merchant_name,
    category,
    country,
    total_revenue,
    growth_rate,
    fraud_rate,
    chargeback_rate,
    complaint_rate,
    risk_bucket,

    CASE
        WHEN growth_rate > 0 AND risk_bucket = 'Low Risk' THEN 'Grow & Invest'
        WHEN growth_rate > 0 AND risk_bucket <> 'Low Risk' THEN 'Grow but Fix Risk'
        WHEN growth_rate <= 0 AND risk_bucket = 'Low Risk' THEN 'Stable / Optimize'
        ELSE 'At Risk'
    END AS business_quadrant,

    revenue_rank,
    revenue_quartile

FROM final_ranked;


SELECT * FROM merchant_bi_view LIMIT 20;
