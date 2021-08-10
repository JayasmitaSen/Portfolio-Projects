USE portfolio;


--Checking the tables to be worked with

SELECT * FROM covid_deaths;
SELECT * FROM covid_vaccination;


--Changing the column name 'date' in both the tables to 'covid_date'
EXEC sp_rename 'covid_deaths.date','covid_date','Column';
EXEC sp_rename 'covid_vaccination.date','covid_date','Column';


--Selecting the relevant data for the analysis in the covid_deaths table

SELECT location,covid_date,population,total_cases,new_cases,total_deaths,new_deaths,icu_patients,hosp_patients
FROM covid_deaths
ORDER BY 1,2;


--Checking the datatypes of the selected data

SELECT DATA_TYPE FROM information_schema.columns
WHERE TABLE_NAME='covid_deaths' AND COLUMN_NAME in ('location','covid_date','population','total_cases','new_cases','total_deaths','new_deaths','icu_patients','hosp_patients');


--Selecting the relevant data for the analysis in the covid_vaccination table

SELECT location,covid_date,positive_rate,total_vaccinations,people_vaccinated,people_fully_vaccinated,new_vaccinations
FROM covid_vaccination
ORDER BY 1,2;


--Checking the datatypes of the selected data

SELECT DATA_TYPE FROM information_schema.columns
WHERE TABLE_NAME='covid_vaccination' AND COLUMN_NAME in ('location','covid_date','positive_rate','total_vaccinations','people_vaccinated','people_fully_vaccinated','new_vaccinations');


--Joining the two tables and changing the datatypes

CREATE VIEW covid_data AS
(SELECT d.location,convert(date, d.covid_date, 105) AS covid_date,CAST(d.population as bigint) AS population,
CAST(d.total_cases as bigint) AS total_cases,CAST(d.new_cases as bigint) AS new_cases,CAST(d.total_deaths as bigint) AS total_deaths,
CAST(d.new_deaths as bigint) AS new_deaths,CAST(d.icu_patients as bigint) AS icu_patients,CAST(d.hosp_patients as bigint) AS hosp_patients,
CAST(v.positive_rate as float) AS positive_rate,CAST(v.total_vaccinations as bigint) AS total_vaccinations,CAST(v.people_vaccinated as bigint) AS people_vaccinated,
CAST(v.people_fully_vaccinated as bigint) AS people_fully_vaccinated,CAST(v.new_vaccinations as bigint) AS new_vaccinations
FROM covid_deaths d,covid_vaccination v
WHERE d.location=v.location and d.covid_date=v.covid_date);


--Finding death percentage from number of positive cases

SELECT location,covid_date,total_cases,total_deaths,CAST(total_deaths as decimal)*100/CAST(total_cases as decimal) AS death_pct
FROM covid_data
WHERE total_cases>0
ORDER BY location,covid_date;


--Total cases vs. Population for India

SELECT location,covid_date,total_cases,population,CAST(total_cases as decimal)*100/CAST(population as decimal) AS cases_pct
FROM covid_data
WHERE location='India'
ORDER BY covid_date;


--Highest infection rate per country compared to the population

SELECT location,MAX(total_cases) as max_cases,population,CAST(MAX(total_cases) as decimal)*100/CAST(population as decimal) AS max_infection_rate
FROM covid_data
WHERE population>0
GROUP BY location,population
ORDER BY max_infection_rate desc;


--Average death percentage per population

SELECT location,population,AVG(total_deaths) AS avg_death_counts
,CAST(AVG(total_deaths) as decimal)*100/CAST(population as decimal) AS country_avg_death_pct
FROM covid_data
WHERE population>0
GROUP BY location,population
ORDER BY country_avg_death_pct desc;


-- Checking the death percentage as compared to the global population

SELECT DISTINCT location,
SUM(population) OVER() AS global_population,
SUM(new_deaths) OVER(PARTITION BY location) AS total_deaths,
CAST((SUM(new_deaths) OVER(PARTITION BY location)) AS decimal)*100/CAST((SUM(population) OVER()) AS decimal) AS global_death_pct
FROM covid_data
ORDER BY global_death_pct;


--Checking vaccinated population percentage per country

SELECT DISTINCT location,population,
SUM(new_vaccinations) OVER(PARTITION BY location) AS vaccinated,
CAST((SUM(new_vaccinations) OVER(PARTITION BY location)) AS decimal)*100/CAST(population AS decimal) AS vaccinated_rate
FROM covid_data
WHERE population>0;
