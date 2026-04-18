# 📊 E-Commerce Customer Retention Analysis (SQL Project)

## 📌 Project Overview

Customer retention is one of the most important growth levers for any e-commerce business. While acquiring new customers can be expensive, retaining existing customers often leads to higher lifetime value and stronger profitability.

In this project, I analyzed a real-world e-commerce dataset using SQL to understand:

- Why most customers purchased only once
- Whether delivery experience impacts repeat purchase behavior
- Whether customer satisfaction predicts retention
- Which customers generate the highest value
- Which product categories drive repeat purchases

This project was completed using **MySQL Workbench** with a business-first analytical approach.

---

## 🎯 Business Problem

The platform had a large number of completed purchases, but repeat customer behavior appeared weak.

The goal was to identify:

1. Key drivers of repeat purchases  
2. Customer experience factors reducing retention  
3. High-value customer segments  
4. Product categories that naturally create loyalty

---

## 🛠 Tools Used

- MySQL Workbench
- SQL
- GitHub

---

## 🧠 SQL Skills Applied

- Joins
- Common Table Expressions (CTEs)
- Window Functions (`ROW_NUMBER`, `LAG`)
- CASE WHEN Segmentation
- Aggregations
- Views for reusable analytics layers
- Data Validation & Cleaning

---

## 🗂 Dataset Tables Used

- Orders
- Customers
- Payments
- Reviews
- Order Items
- Products

---

# 🔍 Analysis Performed

---

## 1️⃣ Overall Customer Retention

Retention was defined as:

> Customers who made at least one additional delivered purchase after their first purchase.

### Result

- Total Customers: **73,248**
- Repeat Customers: **1,747**
- Retention Rate: **2.39%**

### Insight

The business appears strong in acquisition but weak in repeat behavior.

---

## 2️⃣ Delivery Delay vs Retention

Measured whether first-order delivery delays impacted future repeat purchase.

### Result

- On-Time Delivery: **2.41%**
- Delayed Delivery: **2.12%**

### Insight

Customers experiencing delayed first deliveries were less likely to return.

---

## 3️⃣ Review Score vs Retention

Measured whether customer satisfaction predicted future loyalty.

### Result

- High Review (4–5): **2.44%**
- Low Review (1–2): **2.28%**
- Medium Review (3): **2.16%**

### Insight

Higher satisfaction correlated with stronger retention. Neutral experiences underperformed even some negative reviews.

---

## 4️⃣ Customer Value Comparison

Compared repeat customers vs one-time buyers.

### Result

| Segment | Avg Total Spend |
|--------|----------------|
| One-Time Customers | 160.59 |
| Repeat Customers | 309.99 |

### Insight

Repeat customers generated nearly **2x higher revenue per customer**.

---

## 5️⃣ Spend Tier vs Retention

Measured whether higher first-order spend created stronger loyalty.

### Result

- Low Spend: **2.50%**
- Medium Spend: **2.36%**
- High Spend: **2.06%**

### Insight

Large first purchases did not translate into stronger retention.

---

## 6️⃣ Category-Level Retention

Measured repeat behavior based on first purchase category.

### Top Categories by Retention

| Category | Retention |
|---------|----------|
| Appliances | 6.58% |
| Fashion Accessories | 4.96% |
| Air Conditioning | 4.68% |
| Living Room Furniture | 4.64% |

### Insight

Category mix was a stronger loyalty predictor than first-order basket size.

---

# 📌 Key Business Conclusions

## Customers Return When:

- First delivery experience is reliable
- Satisfaction is high
- Initial purchase comes from repeat-friendly categories

## Customers Do Not Return When:

- Delivery expectations are missed
- Experience is average/forgettable
- Purchase is one-time high-ticket category driven

---

# 🚀 Recommendations

## 1. Improve First-Order Experience

Prioritize on-time delivery for new customers.

## 2. Focus on Second Purchase Conversion

Use CRM campaigns, reorder nudges, and incentives.

## 3. Invest in High-Retention Categories

Promote categories with strong repeat behavior.

## 4. Monitor Medium Satisfaction Customers

They may silently churn without complaints.

---

# 📁 Project Structure

```text
E-Commerce Retention Analysis/
│── SQL Queries.sql
│── Dataset Files
│── README.md
