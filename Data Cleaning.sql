-- =========================================================
-- Data Cleaning Project: Global Layoffs Dataset
-- This script performs data cleaning.
-- Steps performed:
-- 1. Remove duplicates
-- 2. Standardize the data
-- 3. Handle NULL or blank values
-- 4. Remove unnecessary columns
-- =========================================================

-- ---------------------------------------------------------
-- Preview Original Dataset
-- ---------------------------------------------------------
SELECT *
FROM layoffs;

-- ---------------------------------------------------------
-- Create a Staging Table
-- ---------------------------------------------------------
/*
Staging Table: layoffs_staging

This table temporarily stores a copy of the raw layoffs dataset
so that cleaning operations can be performed safely without
modifying the original table.

The staging layer allows:
- Safe experimentation with transformations
- Duplicate detection and removal
- Data format standardization
- Handling missing or inconsistent values

After cleaning, the final dataset will remain in the staging table.
*/
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

-- Copy raw data into the staging table
INSERT layoffs_staging
SELECT *
FROM layoffs;

-- Verify data was copied successfully
SELECT *
FROM layoffs_staging;

-- =========================================================
-- 1. REMOVE DUPLICATES
-- =========================================================

/*
The table has no unique ID column, so duplicates are
identified using ROW_NUMBER() with a PARTITION BY
on all columns that should uniquely identify a record.
Any row with row_num > 1 is considered a duplicate.
*/
SELECT *,
ROW_NUMBER() OVER(
	PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Identify duplicate rows
WITH duplicates_cte AS
(
	SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date , stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicates_cte
WHERE row_num > 1;

-- Example check
SELECT *
FROM layoffs_staging
WHERE company = 'Cazoo';

-- ---------------------------------------------------------
-- We can't remove duplicates directly from this table
-- because it does not contain a unique identifier.
-- Therefore, we create a new staging table that includes
-- a ROW_NUMBER column to help identify and remove duplicates.
-- ---------------------------------------------------------
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data with row numbers
INSERT INTO layoffs_staging2
SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date , stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging;

-- View duplicates
SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Delete duplicate rows    
DELETE
FROM layoffs_staging2
WHERE row_num >1;

-- Confirm duplicates were removed
SELECT *
FROM layoffs_staging2;

-- =========================================================
-- 2. STANDARDIZE DATA
-- =========================================================

/*
Standardization ensures consistency across the dataset.
Examples:
- Removing extra spaces
- Unifying category names
- Fixing inconsistent country names
- Converting date formats
*/

-- Remove leading/trailing spaces from company names
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- Check unique industries
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

/*
Here we found that some crypto-related industries are written
as 'Crypto Currency', which essentially refers to the same
industry. To ensure consistency in the dataset, we standardize
all similar values under the label 'Crypto'.
*/
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Inspect country names
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- Fix country values with trailing periods
SELECT *
FROM layoffs_staging2
WHERE country LIKE 'United States.'
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States.';

-- Convert date column from TEXT to DATE format
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date`= STR_TO_DATE(`date`, '%m/%d/%Y');

-- Modify column type
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- =========================================================
-- 3. HANDLE NULL OR BLANK VALUES
-- =========================================================

/*
Missing values can appear as:
- NULL values
- Empty strings

These need to be corrected or filled when possible.
*/

-- Find rows with missing industry
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry='';

-- Example inspection
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- Convert blank industries to NULL
UPDATE layoffs_staging2
SET industry = null
WHERE industry = '';

-- Fill missing industry values using other rows from same company
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company=t2.company
    AND t1.location=t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company=t2.company
    AND t1.location=t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Inspect specific companies 
-- In this case, the industry value remains NULL because
-- there are no other rows for the same company that contain
-- a valid industry value to use for filling the missing data.
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Identify rows where layoff data is completely missing
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Remove rows with no useful layoff information
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT *
FROM layoffs_staging2;

-- =========================================================
-- 4. REMOVE TEMPORARY COLUMNS
-- =========================================================

/*
The row_num column was only needed for duplicate detection,
so it can now be removed from the final cleaned dataset.
*/

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final cleaned dataset
SELECT *
FROM layoffs_staging2;
