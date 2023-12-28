-----  :INITIAL POINT: --------


-- Get offense_code & offense_name for Motor Vehicle theft

SELECT offense_code, offense_name 
FROM nibrs_offense_type 
WHERE offense_name IN ('Motor Vehicle Theft', 'Theft From Motor Vehicle', 'Theft of Motor Vehicle Parts or Accessories');

-- TOP 5 offense in NEVADA in 2021:

 SELECT
  o.offense_code,
  ot.offense_name,
  o.total
FROM 
  (SELECT offense_code, COUNT(*) as total
   FROM nibrs_offense
   WHERE data_year = 2021  
   GROUP BY offense_code
   ORDER BY total DESC
   LIMIT 5) o
JOIN nibrs_offense_type ot
  ON o.offense_code = ot.offense_code
ORDER BY o.total DESC;


-- Total Incident of motor vehicle theft in Nevada in 2021:

SELECT
  COALESCE(o.offense_code, 'Total') as offense_code,
  COUNT(*) as total_incidents
FROM nibrs_incident i   
JOIN nibrs_offense o ON i.incident_id = o.incident_id
WHERE o.offense_code IN ('240', '23F', '23G')  
GROUP BY ROLLUP (o.offense_code);

-- As we see here theft from motor vehicle and motor vehicle theft is on number 4 and Number 5 in our dataset, we're perfoming
-- analysis on this



-----  :MID POINT: ------


-- Motor Vehicle crime on Monthly Based in Clark County Nevada

SELECT a.ucr_agency_name, niot.offense_name, nm.month_num,  COUNT(*)
FROM nibrs_offense nio
JOIN nibrs_offense_type niot
	ON nio.offense_code = niot.offense_code
	AND niot.offense_code IN ('240', '23F', '23G')
JOIN nibrs_incident ni
	ON nio.incident_id = ni.incident_id
INNER JOIN nibrs_month nm
	ON nm.did = ni.did
JOIN agencies a
	ON nm.agency_id = a.agency_id
	AND LEFT(a.ori,5) = 'NV002'
GROUP BY a.ucr_agency_name,niot.offense_name,nm.month_num
; 


WITH MonthlyCounts AS (
    SELECT 
        nm.month_num,
        niot.offense_name,
        COUNT(*) as offense_count
    FROM nibrs_offense nio
    JOIN nibrs_offense_type niot ON nio.offense_code = niot.offense_code
    JOIN nibrs_incident ni ON nio.incident_id = ni.incident_id
    INNER JOIN nibrs_month nm ON nm.did = ni.did
    JOIN agencies a ON nm.agency_id = a.agency_id
    WHERE niot.offense_code IN ('240', '23F', '23G') AND LEFT(a.ori,5) = 'NV002'
    GROUP BY nm.month_num, niot.offense_name
)

SELECT 
    month_num,
    SUM(CASE WHEN offense_name = 'Motor Vehicle Theft' THEN offense_count ELSE 0 END) AS "Motor Vehicle Theft",
    SUM(CASE WHEN offense_name = 'Theft From Motor Vehicle' THEN offense_count ELSE 0 END) AS "Theft From Motor Vehicle",
    SUM(CASE WHEN offense_name = 'Theft of Motor Vehicle Parts or Accessories' THEN offense_count ELSE 0 END) AS "Theft of Motor Vehicle Parts or Accessories",
    SUM(offense_count) AS Total
FROM MonthlyCounts
GROUP BY month_num
ORDER BY month_num;

-- We did visualization based on above output in our report.

-- Top Locations for Motor Vehicle Thefts:

SELECT 
    location_id,
    COUNT(*) AS theft_count 
FROM nibrs_offense 
WHERE offense_code IN ('240', '23F', '23G') 
GROUP BY location_id 
ORDER BY theft_count DESC 
LIMIT 5;


SELECT 
    l.location_id,
    l.location_name,
    COUNT(*) AS theft_count 
FROM nibrs_offense o
JOIN nibrs_location_type l ON o.location_id = l.location_id
WHERE o.offense_code IN ('240', '23F', '23G') 
GROUP BY l.location_id, l.location_name 
ORDER BY theft_count DESC 
LIMIT 5;

-- As we see in the output, Majority motor vehicle theft took place in residence/home with theft_count 11735

-- Draw visualization from above output, Location based analysis.

-- Weapon Usage in Motor Vehicle Thefts:

SELECT 
    wt.weapon_id,
    wt.weapon_name,
    COUNT(w.weapon_id) AS theft_count_with_weapon 
FROM nibrs_weapon_type wt
LEFT JOIN nibrs_weapon w ON wt.weapon_id = w.weapon_id
LEFT JOIN nibrs_offense o ON w.offense_id = o.offense_id AND o.offense_code IN ('240', '23F', '23G') 
GROUP BY wt.weapon_id, wt.weapon_name 
ORDER BY theft_count_with_weapon DESC;
 -- Also, draw visualization for Weapon Usage.
 
 
---- End Point ----

--Demographics of Offenders:

SELECT 
    no.age_id, 
    no.sex_code, 
    no.race_id, 
    no.ethnicity_id, 
    COUNT(*) AS offender_count 
FROM nibrs_offender no
JOIN nibrs_offense nio ON no.incident_id = nio.incident_id
WHERE nio.offense_code IN ('240', '23F', '23G') 
GROUP BY no.age_id, no.sex_code, no.race_id, no.ethnicity_id 
ORDER BY offender_count DESC;


SELECT 
    no.age_id, 
    no.sex_code, 
    r.race_desc,
    no.ethnicity_id, 
    COUNT(*) AS offender_count 
FROM nibrs_offender no
JOIN nibrs_offense nio ON no.incident_id = nio.incident_id
JOIN REF_RACE r ON no.race_id = r.race_id
WHERE nio.offense_code IN ('240', '23F', '23G') 
GROUP BY no.age_id, no.sex_code, r.race_desc, no.ethnicity_id 
ORDER BY offender_count DESC;



SELECT 
    CASE 
        WHEN r.race_desc = 'Unknown' THEN 'Unknown'
        WHEN r.race_desc = 'White' THEN 'White'
        WHEN r.race_desc = 'Black or African American' THEN 'Black or African American'
        WHEN r.race_desc IN ('Asian', 'Asian, Native Hawaiian, or Other Pacific Islander', 'Chinese', 'Japanese') THEN 'Asian'
        WHEN r.race_desc = 'Native Hawaiian or Other Pacific Islander' THEN 'Native Hawaiian or Other Pacific Islander'
        ELSE 'Other'
    END AS race_category,
    no.age_id, 
    no.sex_code,
    no.ethnicity_id, 
    COUNT(*) AS offender_count 
FROM nibrs_offender no
JOIN nibrs_offense nio ON no.incident_id = nio.incident_id
JOIN REF_RACE r ON no.race_id = r.race_id
WHERE nio.offense_code IN ('240', '23F', '23G') 
GROUP BY 
    CASE 
        WHEN r.race_desc = 'Unknown' THEN 'Unknown'
        WHEN r.race_desc = 'White' THEN 'White'
        WHEN r.race_desc = 'Black or African American' THEN 'Black or African American'
        WHEN r.race_desc IN ('Asian', 'Asian, Native Hawaiian, or Other Pacific Islander', 'Chinese', 'Japanese') THEN 'Asian'
        WHEN r.race_desc = 'Native Hawaiian or Other Pacific Islander' THEN 'Native Hawaiian or Other Pacific Islander'
        ELSE 'Other'
    END,
    no.age_id, no.sex_code, no.ethnicity_id 
ORDER BY offender_count DESC;



SELECT 
    CASE 
        WHEN r.race_desc = 'Unknown' THEN 'Unknown'
        WHEN r.race_desc = 'White' THEN 'White'
        WHEN r.race_desc = 'Black or African American' THEN 'Black or African American'
        WHEN r.race_desc IN ('Asian', 'Asian, Native Hawaiian, or Other Pacific Islander', 'Chinese', 'Japanese') THEN 'Asian'
        WHEN r.race_desc = 'Native Hawaiian or Other Pacific Islander' THEN 'Native Hawaiian or Other Pacific Islander'
        ELSE 'Other'
    END AS race_category,
    COUNT(*) AS offender_count 
FROM nibrs_offender no
JOIN nibrs_offense nio ON no.incident_id = nio.incident_id
JOIN REF_RACE r ON no.race_id = r.race_id
WHERE nio.offense_code IN ('240', '23F', '23G') 
GROUP BY 
    CASE 
        WHEN r.race_desc = 'Unknown' THEN 'Unknown'
        WHEN r.race_desc = 'White' THEN 'White'
        WHEN r.race_desc = 'Black or African American' THEN 'Black or African American'
        WHEN r.race_desc IN ('Asian', 'Asian, Native Hawaiian, or Other Pacific Islander', 'Chinese', 'Japanese') THEN 'Asian'
        WHEN r.race_desc = 'Native Hawaiian or Other Pacific Islander' THEN 'Native Hawaiian or Other Pacific Islander'
        ELSE 'Other'
    END
ORDER BY offender_count DESC;


-- Visualization offender demographic is in report.


-- Look at victim demographics:

-- Motor Vehicle Theft VICTIMs in Nevada In 2021


SELECT
  v.age_id,
  v.sex_code, 
  COUNT(*) AS incidents
FROM nibrs_victim v
JOIN nibrs_victim_offense vo ON v.victim_id = vo.victim_id
JOIN nibrs_offense o ON vo.offense_id = o.offense_id
WHERE o.offense_code IN ('240', '23F', '23G')
GROUP BY v.age_id, v.sex_code;

-- Motor Vehicle Theft VICTIMs in Nevada 2021 BY AGE groups :
SELECT
  CASE 
    WHEN v.age_num BETWEEN 0 AND 17 THEN '0-17'
    WHEN v.age_num BETWEEN 18 AND 24 THEN '18-24'
    WHEN v.age_num BETWEEN 25 AND 30 THEN '25-30'
    WHEN v.age_num BETWEEN 31 AND 40 THEN '31-40'
    WHEN v.age_num BETWEEN 41 AND 50 THEN '41-50'
    WHEN v.age_num BETWEEN 51 AND 60 THEN '51-60'
    ELSE '61+'
  END AS age_group,
  v.sex_code,
  COUNT(*) AS incidents
FROM nibrs_victim v
JOIN nibrs_victim_offense vo ON v.victim_id = vo.victim_id
JOIN nibrs_offense o ON vo.offense_id = o.offense_id
WHERE o.offense_code IN ('240', '23F', '23G')
GROUP BY 
  age_group,
  v.sex_code;
  

-- ANALYSIS:  


--Majority of Victims are 25+:

-- The age group 25+ has the highest number of incidents.

--Gender Distribution: 

--For the age groups 0-17 and 18-24, there are more male victims than female victims.
--In the 25+ age group, while there are still more male victims, 
--the difference between male and female victims is more pronounced.


--Data Quality: 
--The presence of 3,006 victims in the 25+ age group with an 'X' for the sex code suggests that 
--there is a significant amount of missing or unspecified data for this demographic. 


--Low Unknowns for Young Adults: 
--The 18-24 age group has a very low number of victims with an unknown sex (U), 
--which suggests better data collection or reporting for this demographic compared to the other age groups.


-- NOTE: The The 'X' value for sex_code in the 25+ age group is likely indicating an invalid or unspecified sex. 

--The data suggests that adults aged 25 and above are the most affected, 
--and there are more male victims across all age groups. 
--It's also evident that there's a data quality issue with a significant number 
--of unspecified sex entries for the 25+ age group.

-- Visualization included in report
