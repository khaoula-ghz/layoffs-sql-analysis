-- =========================================================
-- Exploratory Data Analysis (EDA)
-- Dataset: World Layoffs
-- This section explores patterns and trends in the cleaned
-- dataset stored in layoffs_staging2.
-- =========================================================

-- ---------------------------------------------------------
-- Preview the cleaned dataset
-- ---------------------------------------------------------
SELECT *
FROM layoffs_staging2;

-- ---------------------------------------------------------
-- Identify the largest layoffs recorded
-- (maximum total layoffs and highest percentage laid off)
-- ---------------------------------------------------------
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- ---------------------------------------------------------
-- Companies that laid off 100% of their workforce
-- Ordered by the amount of funding they had raised
-- ---------------------------------------------------------
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- ---------------------------------------------------------
-- Total layoffs by company
-- Shows which companies laid off the most employees
-- ---------------------------------------------------------
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- ---------------------------------------------------------
-- Determine the time range of the dataset
-- ---------------------------------------------------------
SELECT MIN(date), MAX(date)
FROM layoffs_staging2;

-- ---------------------------------------------------------
-- Total layoffs by industry
-- Helps identify the industries most affected by layoffs
-- ---------------------------------------------------------
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- ---------------------------------------------------------
-- Total layoffs by country
-- Shows geographic distribution of layoffs
-- ---------------------------------------------------------
SELECT country, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- ---------------------------------------------------------
-- Total layoffs per year
-- Useful for identifying yearly layoff trends
-- ---------------------------------------------------------
SELECT YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(date)
ORDER BY 1 DESC;

-- ---------------------------------------------------------
-- Layoffs grouped by company funding stage
-- ---------------------------------------------------------
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- ---------------------------------------------------------
-- Monthly layoffs trend
-- Extracts year-month from the date to analyze layoffs
-- over time on a monthly basis
-- ---------------------------------------------------------
SELECT substring(date, 1, 7) AS MONTH, SUM(total_laid_off)
FROM layoffs_staging2
WHERE substring(date, 1, 7) IS NOT NULL
GROUP BY MONTH
ORDER BY 1 ASC;

-- ---------------------------------------------------------
-- Rolling cumulative layoffs over time
-- Shows how layoffs accumulated month by month
-- ---------------------------------------------------------
WITH Rolling_Total AS
(
	SELECT DATE_FORMAT(date,'%Y-%m') AS MONTH, SUM(total_laid_off) AS Total_OFF
	FROM layoffs_staging2
	WHERE DATE_FORMAT(date,'%Y-%m') IS NOT NULL
	GROUP BY MONTH
	ORDER BY 1 ASC
)
SELECT MONTH, Total_OFF,
SUM(Total_OFF) OVER (ORDER BY MONTH) AS rolling_total
FROM Rolling_Total;

-- ---------------------------------------------------------
-- Layoffs by company per year
-- Helps observe which companies had layoffs in which years
-- ---------------------------------------------------------
SELECT company, YEAR(date), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(date)
ORDER BY 3 DESC;

-- ---------------------------------------------------------
-- Top 5 companies with the most layoffs each year
-- Using DENSE_RANK to rank companies within each year
-- ---------------------------------------------------------
WITH Company_Year (company, years, total_laid_off)AS  
(
	SELECT company, YEAR(date), SUM(total_laid_off)
	FROM layoffs_staging2
	GROUP BY company, YEAR(date)
), Company_Year_Rank AS
(
	SELECT *,
	DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
	FROM Company_Year
	WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5 ;


-- ---------------------------------------------------------
-- Top 5 industries with the most layoffs each year
-- ---------------------------------------------------------
WITH Industry_Year (industry, years, total_laid_off) AS  
(
	SELECT industry, YEAR(date), SUM(total_laid_off)
	FROM layoffs_staging2
	GROUP BY industry, YEAR(date)
), Industry_Year_Rank AS
(
	SELECT *,
	DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
	FROM Industry_Year
	WHERE years IS NOT NULL
)
SELECT *
FROM Industry_Year_Rank
WHERE Ranking <= 5 ;


-- ---------------------------------------------------------
-- Top 5 countries with the most layoffs each year
-- ---------------------------------------------------------
WITH Country_Year (country, years, total_laid_off)AS  
(
	SELECT country, YEAR(date), SUM(total_laid_off)
	FROM layoffs_staging2
	GROUP BY country, YEAR(date)
), Country_Year_Rank AS
(
	SELECT *,
	DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
	FROM Country_Year
	WHERE years IS NOT NULL
)
SELECT *
FROM Country_Year_Rank
WHERE Ranking <= 5 ;

-- ---------------------------------------------------------
-- Month-to-month layoffs trend with percentage change
-- Helps identify growth or decline in layoffs over time
-- ---------------------------------------------------------
WITH monthly_layoffs AS
(
	SELECT DATE_FORMAT(date, '%Y-%m') AS MONTH,
	SUM(total_laid_off) AS total_layoffs
	FROM layoffs_staging2
	GROUP BY MONTH
)
SELECT MONTH,
total_layoffs,
LAG(total_layoffs) OVER (ORDER BY MONTH) AS previous_month,
ROUND(
	(total_layoffs - LAG(total_layoffs) OVER (ORDER BY MONTH))
	/ LAG(total_layoffs) OVER (ORDER BY month) * 100, 2
) AS percent_change
FROM monthly_layoffs
WHERE MONTH IS NOT NULL;

-- ---------------------------------------------------------
-- Percentage share of layoffs by industry
-- Shows which industries were most affected overall
-- ---------------------------------------------------------
SELECT industry,
SUM(total_laid_off) AS total_layoffs,
ROUND(
	SUM(total_laid_off) * 100 /
	(SELECT SUM(total_laid_off) FROM layoffs_staging2),
2) AS layoff_percentage
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_layoffs DESC;


-- ---------------------------------------------------------
-- Companies with multiple layoff events
-- Identifies companies that had repeated layoffs
-- ---------------------------------------------------------
SELECT company,
COUNT(*) AS layoff_events,
SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
HAVING COUNT(*) > 1
ORDER BY layoff_events DESC;
