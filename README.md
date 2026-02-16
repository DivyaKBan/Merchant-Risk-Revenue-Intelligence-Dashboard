# 📊 Merchant Risk & Revenue Intelligence Dashboard

## 🔎 Project Overview

This Business Intelligence project analyzes merchant-level revenue, growth trends, fraud exposure, chargeback behavior, complaint rates, and geographic performance.

The objective is to provide a risk-adjusted performance framework that helps stakeholders:

- Identify revenue-driving merchants
- Monitor fraud and operational risk
- Optimize merchant portfolio performance
- Make strategic growth decisions

---

## 🎯 Business Problem

In a payment ecosystem with 200 merchants operating across multiple countries and categories, leadership requires visibility into:

- Revenue distribution
- Merchant growth patterns
- Risk concentration
- Geographic exposure
- Portfolio balance

This dashboard delivers structured insights to support risk-aware decision-making.

---

## 📌 Key KPIs

| Metric | Value |
|--------|-------|
| **Total Revenue** | ₹179.9M |
| **Average Growth Rate** | 18.81% |
| **Average Fraud Rate** | 4.51% |
| **Average Chargeback Rate** | 4.17% |
| **Average Complaint Rate** | 27.13% |
| **High-Risk Merchants** | 9.05% |

---

## 🧠 Analytical Framework

A consolidated SQL view (`merchant_bi_view`) was built using:

- CTEs
- Window Functions (`RANK()`, `NTILE()`)
- Revenue growth comparison (Last 3 months vs Previous 3 months)
- Risk bucket classification logic
- Business quadrant segmentation

### 🔹 Risk Bucket Logic

- **High Risk** → fraud_rate > 5% OR chargeback_rate > 3%
- **Medium Risk** → fraud_rate > 2% OR chargeback_rate > 1%

### 🔹 Business Quadrant Classification

Merchants were segmented into:

- Grow & Invest
- Grow but Fix Risk
- Stable / Optimize
- At Risk

---

## 📈 Dashboard Breakdown

### 1️⃣ Merchant Performance
<img width="1298" height="728" alt="Screenshot 2026-02-17 021907" src="https://github.com/user-attachments/assets/f862f953-2fe2-4197-8b22-b1a98d94d15b" />

- Top 10 merchants generate ~₹10.5M each
- Revenue quartile distribution:
  - Q1: ₹49M
  - Q2: ₹46M
  - Q3: ₹44M
  - Q4: ₹41M
- Growth vs Revenue scatter plot highlights several merchants with negative growth

**Insight:**  
Revenue distribution is relatively balanced, reducing concentration risk. However, multiple merchants show declining growth despite overall positive average growth.

---

### 2️⃣ Fraud & Risk Monitoring
<img width="1291" height="721" alt="Screenshot 2026-02-17 021917" src="https://github.com/user-attachments/assets/db0a2508-c4c3-4430-a447-c466d5efc2a7" />

- Fraud Rate: 4.51%
- Chargeback Rate: 4.17%
- Complaint Rate: 27.13% (critical operational indicator)
- 9.05% merchants classified as High Risk
- Healthcare and Travel categories show relatively higher fraud exposure

**Insight:**  
Fraud levels are moderate, but complaint rates indicate operational inefficiencies requiring immediate attention.

---

### 3️⃣ Geography & Growth Analysis
<img width="1284" height="720" alt="Screenshot 2026-02-17 021926" src="https://github.com/user-attachments/assets/964d6a65-5429-4567-b51a-c03365b6f7ab" />

Revenue by Country:

- India (~₹49M)
- UAE (~₹42M)
- UK (~₹40M)
- Singapore (~₹26M)
- USA (~₹26M)

High-risk merchants are distributed across major regions.

**Insight:**  
India and UAE are primary revenue drivers. Risk exposure is geographically diversified, requiring region-specific monitoring strategies.

---

## 🔍 Key Insights

1. Strong total revenue with 18.81% average growth.
2. Revenue is evenly distributed across quartiles.
3. Several merchants show negative growth trends.
4. Complaint rate (27.13%) is the most concerning KPI.
5. High-risk merchants represent 9.05% of portfolio.
6. India and UAE present strong growth opportunities.

---

## 🎯 Strategic Recommendations

- Investigate drivers behind high complaint rate.
- Implement proactive monitoring for high-risk merchants.
- Focus retention efforts on high-revenue merchants with declining growth.
- Strengthen fraud controls in Healthcare & Travel segments.
- Expand strategically in high-performing geographies.

---

## 🛠️ Tech Stack

- PostgreSQL (CTEs, Window Functions)
- Power BI
- DAX Measures
- Risk Segmentation Logic
- Revenue Growth Modeling

---

## 💡 Skills Demonstrated

- Advanced SQL
- Data Modeling
- KPI Engineering
- Risk Classification
- Growth Analysis
- Business Intelligence Dashboarding
- Executive Reporting

---

## 🚀 Project Impact

This project demonstrates the ability to:

- Build production-ready analytical views
- Translate business objectives into measurable KPIs
- Apply risk-adjusted performance frameworks
- Deliver executive-grade BI dashboards
- Generate actionable insights from transactional data

---

## 📂 Repository Structure

