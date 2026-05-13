# Global Layoffs — Data Cleaning & Exploratory Data Analysis (SQL)

A complete end-to-end SQL project analyzing global tech layoffs.  
Covers data cleaning from raw to analysis-ready, followed by exploratory analysis to uncover trends across companies, industries, countries, and time.

---

## Project Structure

```
layoffs-sql-analysis/
│
├── Data_Cleaning.sql                  # Step-by-step data cleaning script
├── Exploratory_Data_Analysis_(EDA).sql  # Full EDA with trends and rankings
├── layoffs.csv                        # Raw dataset (source: Alex the Analyst)
└── README.md
```

---

## Part 1 — Data Cleaning

The raw dataset required significant cleaning before analysis. All operations were performed on a **staging table** to preserve the original data.

### Steps performed

**1. Remove Duplicates**
- No unique ID column existed, so `ROW_NUMBER()` with `PARTITION BY` across all relevant columns was used to identify exact duplicates
- A second staging table (`layoffs_staging2`) was created to include the row number column, allowing safe deletion of duplicate rows

**2. Standardize the Data**
- Trimmed leading/trailing whitespace from company names
- Unified crypto-related industry labels (`Crypto Currency`, `CryptoCurrency` → `Crypto`)
- Removed trailing periods from country names (`United States.` → `United States`)
- Converted the `date` column from `TEXT` to proper `DATE` format using `STR_TO_DATE()`

**3. Handle NULL and Blank Values**
- Converted empty string industry values to `NULL`
- Used a **self-join** to fill missing industry values by matching on company and location
- Removed rows where both `total_laid_off` and `percentage_laid_off` were NULL (no useful information)

**4. Remove Temporary Columns**
- Dropped the `row_num` helper column used for duplicate detection

---

## Part 2 — Exploratory Data Analysis

### Key Questions Answered

| Question | Technique Used |
|---|---|
| Which companies had the most layoffs overall? | `GROUP BY` + `SUM` |
| Which industries were hit hardest? | Aggregation + percentage share |
| How did layoffs trend over time (monthly)? | `SUBSTRING` date extraction |
| What is the rolling cumulative total of layoffs? | `SUM() OVER` window function |
| Which companies laid off 100% of their workforce? | Filter on `percentage_laid_off = 1` |
| Which were the top 5 companies per year? | `DENSE_RANK()` with `PARTITION BY` year |
| How did layoffs change month to month? | `LAG()` window function + % change |
| Which companies had multiple layoff events? | `HAVING COUNT(*) > 1` |

### Highlights

- **Largest single layoff event**: identified using `MAX(total_laid_off)`
- **Companies that shut down entirely**: several well-funded startups with millions raised laid off 100% of staff
- **Industry breakdown**: Consumer and Retail sectors were among the hardest hit
- **Geographic distribution**: The United States accounted for the majority of global layoffs
- **Rolling total**: cumulative layoffs visualized month by month to show the acceleration of the trend
- **Year-over-year ranking**: `DENSE_RANK()` used to rank the top 5 companies, industries, and countries per year

---

## Tools Used

- **MySQL** — all queries written and tested in MySQL
- **SQL Concepts**: CTEs, Window Functions (`ROW_NUMBER`, `DENSE_RANK`, `LAG`, `SUM OVER`), Joins, Aggregations, String functions, Date formatting

---

## Dataset

- **Source**: [Alex the Analyst]([https://github.com/AlexTheAnalyst](https://github.com/AlexTheAnalyst/MySQL-YouTube-Series/blob/main/layoffs.csv)) — World Layoffs dataset
- **Records**: ~2,000+ companies across multiple industries and countries

---

## Key Takeaways

- Window functions are essential for ranking, running totals, and period-over-period comparisons
- Self-joins are a powerful technique for imputing missing values from related records
- Staging tables protect the original data during iterative cleaning

---

## Author

**Khaoula** — Data Science & Intelligent Systems 
📌 Specialization: NLP, Machine Learning, Data Analysis  
🔗 [Tableau Public]([https://public.tableau.com](https://public.tableau.com/app/profile/khaoula.ghimouze/vizzes)) | [Hugging Face](https://huggingface.co/khaoula-ghz)
