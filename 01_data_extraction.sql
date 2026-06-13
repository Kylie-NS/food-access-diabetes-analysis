-- Phase 1: Flatten and clean the USDA Food Environment data
WITH clean_usda AS (
    SELECT 
        FIPS,
        State,
        County,
        MAX(CASE WHEN Variable_code = 'PCT_LACCESS_LOWI19' AND Value >= 0 THEN Value END) AS pct_low_income_low_access,
        MAX(CASE WHEN Variable_code = 'PCT_LACCESS_HHNV19' AND Value >= 0 THEN Value END) AS pct_no_car_low_access,
        COALESCE(MAX(CASE WHEN Variable_code = 'GROCPTH20' AND Value >= 0 THEN Value END), 0) + 
        COALESCE(MAX(CASE WHEN Variable_code = 'SUPERCPTH20' AND Value >= 0 THEN Value END), 0) AS healthy_retailers_per_1k,
        MAX(CASE WHEN Variable_code = 'CONVSPTH20' AND Value >= 0 THEN Value END) AS convenience_stores_per_1k,
        MAX(CASE WHEN Variable_code = 'FFRPTH20' AND Value >= 0 THEN Value END) AS fast_food_per_1k
    FROM raw_usda_data
    GROUP BY FIPS, State, County
),

-- Phase 2: Flatten and clean the CDC PLACES health data
clean_cdc AS (
    SELECT 
        LocationID,
        -- Pivot out the specific crude prevalence percentages
        MAX(CASE WHEN MeasureId = 'DIABETES' AND Data_Value_Type = 'Crude prevalence' THEN Data_Value END) AS diabetes_rate,
        MAX(CASE WHEN MeasureId = 'OBESITY' AND Data_Value_Type = 'Crude prevalence' THEN Data_Value END) AS obesity_rate
    FROM raw_cdc_data
    GROUP BY LocationID
)

-- Phase 3: Marry both universes together using the unique FIPS code
SELECT 
    u.FIPS,
    u.State,
    u.County,
    u.pct_low_income_low_access,
    u.pct_no_car_low_access,
    u.healthy_retailers_per_1k,
    u.convenience_stores_per_1k,
    u.fast_food_per_1k,
    c.diabetes_rate,
    c.obesity_rate
FROM clean_usda u
LEFT JOIN clean_cdc c 
    ON CAST(u.FIPS AS INTEGER) = CAST(c.LocationID AS INTEGER)
ORDER BY u.State, u.County;