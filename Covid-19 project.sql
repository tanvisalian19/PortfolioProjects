select * 
from PortfolioProject.coviddeaths
where continent is not null
order by 3,4;


UPDATE coviddeaths 
SET date = DATE_FORMAT(STR_TO_DATE(date, '%m/%d/%y'), '%Y/%m/%d');

UPDATE covidvaccinations 
SET date = DATE_FORMAT(STR_TO_DATE(date, '%m/%d/%y'), '%Y/%m/%d');

select * 
from PortfolioProject.covidvaccinations
order by 3,4;

-- Selecting Data for use
select location, date, total_cases, new_cases, total_deaths, population
from coviddeaths
order by 1,2;

-- Comparing total cases vs deaths
-- Likelihood of dying if I contract covid in my home country
select location, date, total_cases, total_deaths, (total_deaths)/(total_cases)*100 as death_percentage
from coviddeaths
where location = 'India'
order by 1,2;

-- Total cases vs Population
-- Showing what percent of population got covid
select location, date, total_cases, population, (total_cases)/(population)*100 as PercentPopulationInfected
from coviddeaths
-- where location = 'India'
order by 1,2;

-- Looking at countries with Highest Infection Rate compared to Population
select location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases)/(population))*100 as PercentPopulationInfected
from coviddeaths
group by location, population
order by PercentPopulationInfected desc;

-- Looking at countries with Highest Death Count by pcountry
Select location, MAX(COALESCE(CAST(total_deaths AS SIGNED), 0)) AS HighestDeathCount
from coviddeaths
where continent is not null
AND location NOT IN ('Asia', 'Europe', 'European Union','Africa', 'North America', 'South America', 'Oceania', 'World')
group by location
order by HighestDeathCount desc; 

-- Breaking things down by continent
Select continent, MAX(COALESCE(CAST(total_deaths AS SIGNED), 0)) AS HighestDeathCount
from coviddeaths
where continent is not null
AND continent IN ('Asia', 'Europe', 'European Union','Africa', 'North America', 'South America', 'Oceania')
group by continent
order by HighestDeathCount desc; 

-- Global deaths
select sum(new_cases) as total_cases, sum(coalesce(cast(new_deaths as signed),0))as total_deaths, (sum(coalesce(cast(new_deaths as signed),0))/sum(new_cases))*100 as death_percentage
from coviddeaths
where continent is not null
order by 1,2;

-- Rolling total of vaccinated by population

WITH PopvsVac(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS(
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(COALESCE(CAST(vac.new_vaccinations AS SIGNED), 0)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    where dea.continent is not null
)

Select *, (RollingPeopleVaccinated/population)*100 as percentage
FROM PopvsVac;


-- Creating a Temp Table
DROP TABLE IF EXISTS PopulationVaccinatedPercent;
CREATE TEMPORARY TABLE PopulationVaccinatedPercent (
    continent VARCHAR(255),
    location VARCHAR(255),
    date DATE,  
    population DECIMAL(18,2),
    new_vaccinations INT,
    RollingPeopleVaccinated DECIMAL(18,2)
);

INSERT INTO PopulationVaccinatedPercent
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    CAST(NULLIF(vac.new_vaccinations, '') AS SIGNED) AS new_vaccinations,
    SUM(COALESCE(CAST(NULLIF(vac.new_vaccinations, '') AS SIGNED), 0)) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
        AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date;

SELECT *, 
       (RollingPeopleVaccinated / population) * 100 AS PercentageVaccinated
FROM PopulationVaccinatedPercent;

-- Creating a view to store data for later visualization
Create view PercentPopulationVaccinated as
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(COALESCE(CAST(vac.new_vaccinations AS SIGNED), 0)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
    where dea.continent is not null
