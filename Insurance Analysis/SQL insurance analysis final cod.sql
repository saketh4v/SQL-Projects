CREATE DATABASE insurance_analytics;
USE insurance_analytics;

## KPI 1 - Number of Invoice by Account Executive

SELECT `Account Executive`,
    SUM(CASE WHEN income_class = 'Cross Sell' THEN 1 ELSE 0 END) AS Cross_Sell_count,
    SUM(CASE WHEN income_class = 'New' THEN 1 ELSE 0 END) AS New_count,
    SUM(CASE WHEN income_class = 'Renewal' THEN 1 ELSE 0 END) AS Renewal_count,
    SUM(CASE WHEN income_class IS NULL OR income_class = '' THEN 1 ELSE 0 END) AS NULL_invoice_count,
    COUNT(invoice_number) AS Invoice_count
FROM invoice
GROUP BY `Account Executive`
ORDER BY Invoice_count DESC
LIMIT 1000;


## KPI 2 - Yearly Meeting Count

SELECT YEAR(STR_TO_DATE(meeting_date, '%d-%m-%y')) AS Meeting_Year,
       COUNT(*) AS Meeting_count
FROM meeting
WHERE YEAR(STR_TO_DATE(meeting_date, '%d-%m-%y')) IN (2019, 2020)
GROUP BY Meeting_Year
ORDER BY Meeting_Year;


# KPI 3 - Target, Invoice, Achieved, Placed_Achvmt_percent
# Invoice_Achvmt_percent by Income_Class
# (Cross Sell, New, Renewal)


DELIMITER //

CREATE PROCEDURE `Data_by_IncomeClass` (IN IncomeClass VARCHAR(20))
BEGIN
    DECLARE Budget_val DOUBLE;

    -- Targets
    SET @Cross_Sell_Target = (SELECT SUM(`Cross sell bugdet`) FROM `Individual Budgets - Copy`);
    SET @New_Target = (SELECT SUM(`New Budget`) FROM `Individual Budgets - Copy`);
    SET @Renewal_Target = (SELECT SUM(`Renewal Budget`) FROM `Individual Budgets - Copy`);

    -- Invoice and Achieved values
    SET @Invoice_val = (SELECT SUM(Amount) FROM invoice WHERE income_class = IncomeClass);
    SET @Achieved_val = (
        (SELECT SUM(Amount) FROM brokerage WHERE income_class = IncomeClass) +
        (SELECT SUM(Amount) FROM fees WHERE income_class = IncomeClass)
    );

    -- Budget assignment
    IF IncomeClass = "Cross Sell" THEN
        SET Budget_val = @Cross_Sell_Target;
    ELSEIF IncomeClass = "New" THEN
        SET Budget_val = @New_Target;
    ELSEIF IncomeClass = "Renewal" THEN
        SET Budget_val = @Renewal_Target;
    ELSE
        SET Budget_val = 0;
    END IF;

    -- Percentage Calculations
    SET @placed_achvmt = CONCAT(FORMAT((@Achieved_val / Budget_val) * 100, 2), '%');
    SET @Invoice_achvmt = CONCAT(FORMAT((@Invoice_val / Budget_val) * 100, 2), '%');

    -- Final Output
    SELECT
        IncomeClass AS Income_Class,
        FORMAT(Budget_val, 0) AS Target,
        FORMAT(@Invoice_val, 0) AS Invoice,
        FORMAT(@Achieved_val, 0) AS Achieved,
        @placed_achvmt AS Placed_Achievement_Percentage,
        @Invoice_achvmt AS Invoice_Achievement_Percentage;
END //

DELIMITER ;

CALL Data_by_IncomeClass('Cross Sell');
CALL Data_by_IncomeClass('New');
CALL Data_by_IncomeClass('Renewal');

## KPI 4 - Stage Funnel by Revenue

SELECT stage,
       COALESCE(SUM(revenue_amount), 0) AS Revenue_amt
FROM opportunity
GROUP BY stage
ORDER BY Revenue_amt DESC;


## KPI 5 - Number of Meetings by Account Executive


SELECT `Account Executive`,COUNT(*) AS Meeting_count
FROM meeting
GROUP BY `Account Executive`
ORDER BY Meeting_count DESC;


## KPI 6 - Top 5 Opportunities by Revenue


SELECT opportunity_name,
       SUM(revenue_amount) AS Revenue_amt
FROM opportunity
GROUP BY opportunity_name
ORDER BY Revenue_amt DESC
LIMIT 5;

## Opportunity - Product Distribution

SELECT product_group,
       COUNT(`Account Executive`) AS oppt_count,
       CONCAT(FORMAT(COUNT(`Account Executive`) * 100.0 / SUM(COUNT(`Account Executive`)) OVER (), 2), '%') AS Total_percent
FROM opportunity
GROUP BY product_group;


DROP PROCEDURE IF EXISTS Data_by_IncomeClass;

USE insurance_analytics;

