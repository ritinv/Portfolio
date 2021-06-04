/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT * 
FROM Portfolio..Covid_deaths
WHERE continent is not NULL
ORDER By 3,4

--SELECT * 
--FROM Portfolio..Covid_Vaccinations
--ORDER By 3,4

--Select Data that we are going to be using for project

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio..Covid_deaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Portfolio..Covid_deaths
WHERE location like '%states%'
AND continent is not NULL
ORDER BY 1,2



-- Looking at Total Cases vs Population
-- Showing percentage of population that is infected
SELECT Location, date, total_cases, Population, (total_cases/population)*100 AS InfectedPopulationPercentage
FROM Portfolio..Covid_deaths
ORDER BY 1,2


-- looking at countries with highest infection rate compared to population
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectedPopulationPercentage
FROM Portfolio..Covid_deaths
-- WHERE location like '%states%'
GROUP BY Location, Population
ORDER BY InfectedPopulationPercentage desc


-- Looking at countries with highest death count per population
SELECT Location, MAX(total_deaths) AS TotalDeathCount
FROM Portfolio..Covid_deaths
-- WHERE location like '%states%'
GROUP BY Location
WHERE continent is not NULL
ORDER BY TotalDeathCount desc

-- The above query results in ambigous result which is due to the datatype of the Column, total_deaths(nvarchar)
-- Therefore, need to CAST/Convert as integer.

-- Updated query 
SELECT Location, MAX(cast(total_deaths as INT)) AS TotalDeathCount
FROM Portfolio..Covid_deaths
-- WHERE location like '%states%'
GROUP BY Location
ORDER BY TotalDeathCount desc

-- The above query shows results for entire continents and the world also in the saame result.
-- This is because of inconsistency in data. Need to modify that.

-- Countries with Highest Death Count per Population
SELECT Location, MAX(cast(total_deaths as INT)) AS TotalDeathCount
FROM Portfolio..Covid_deaths
-- WHERE location like '%states%'
WHERE continent is not NULL
GROUP BY Location
ORDER BY TotalDeathCount desc


-- Updated query filtering the continents 
-- Showing continents with the highest death count per population
SELECT continent, MAX(cast(total_deaths as INT)) AS TotalDeathCount
FROM Portfolio..Covid_deaths
-- WHERE location like '%states%'
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount desc

-- Since we wanna visualize this data, modifications are needed to be made in the original data. 


-- Looking at Global Numbers
SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as INT)) as Total_deaths, (SUM(CAST(new_deaths as INT))/SUM(new_cases))*100 AS DeathPercentage
FROM Portfolio..Covid_deaths
-- WHERE location like '%states%'
WHERE continent is not NULL
-- GROUP BY date
ORDER BY 1,2


--- Working with Vaccinations data

SELECT * 
FROM Portfolio..Covid_deaths dea
JOIN Portfolio..Covid_Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM Portfolio..Covid_deaths dea
JOIN Portfolio..Covid_Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3


-- Deep Dive 1
-- Looking at percentage of population which has recieved at least one Covid vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as VaccinationRollingCount
FROM Portfolio..Covid_deaths dea
JOIN Portfolio..Covid_Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3


--- USING CTE

WITH PopVsVac (Continent, Location, Date, Population, new_vaccinations, VaccinationRollingCount)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as VaccinationRollingCount
--- (VaccinationRollingCount/population)*100
FROM Portfolio..Covid_deaths dea
JOIN Portfolio..Covid_Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
-- ORDER BY 2,3
)
SELECT *
FROM PopVsVac


--- TEMP TABLE
-- Performing calculation on Partition by in query above

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(2545),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
VaccinationRollingCount numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as VaccinationRollingCount
--- (VaccinationRollingCount/population)*100
FROM Portfolio..Covid_deaths dea
JOIN Portfolio..Covid_Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
-- WHERE dea.continent is not NULL
-- ORDER BY 2,3

SELECT *, (VaccinationRollingCount/Population)*100
FROM #PercentPopulationVaccinated



-- Creating View to Store data for visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date)
as VaccinationRollingCount
FROM Portfolio..Covid_deaths dea
JOIN Portfolio..Covid_Vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not NULL
--ORDER BY 2,3
