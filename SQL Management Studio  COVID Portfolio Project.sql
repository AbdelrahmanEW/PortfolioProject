-- Use the ProtofiluProject database
USE ProtofiluProject
GO

-- Select the data we are going to use

-- 1. Looking at total cases vs total deaths
-- Show the likelihood of dying if you contract COVID-19 in Egypt
SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE 'egypt' AND continent IS NOT NULL
ORDER BY 1, 2;

-- 2. Looking at total cases vs population
-- Show what percentage of the population got COVID-19 in Egypt
SELECT location, date, total_cases, population, (total_cases / population) * 100 AS PercentPopulationInfection
FROM CovidDeaths
WHERE location LIKE 'egypt' AND continent IS NOT NULL
ORDER BY 1, 2;

-- 3. Looking at countries with high infection rates compared to population
-- Show countries with the highest infection count and the percentage of population infected
SELECT location, MAX(total_cases) AS HighestInfectionCount, population, MAX(total_cases / population) * 100 AS PercentPopulationInfection
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfection DESC;

-- 4. Showing countries with the highest death count per population
-- Show countries with the highest total death count
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- 5. Let's break things down by continent
-- Show total death count by continent
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- 6. Showing continents with the highest death count per population
-- Show continents with the highest total death count
SELECT continent, MAX(total_deaths) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- 7. Global numbers
-- Show global sum of new cases and new deaths per date and calculate death percentage
SELECT date, SUM(new_cases) AS SumOfNewCases, SUM(new_deaths) AS SumOfDeaths, SUM(new_deaths) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2;

-- Show global sum of new cases and new deaths, and calculate overall death percentage
SELECT SUM(new_cases) AS SumOfNewCases, SUM(new_deaths) AS SumOfDeaths, SUM(new_deaths) / SUM(new_cases) * 100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL;

-- 8. Looking at total population vs vaccinated
-- Show rolling sum of people vaccinated per location and date
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidVaccinations vac
JOIN CovidDeaths dea
    ON vac.location = dea.location AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2;

-- 9. Using CTE (Common Table Expression)
-- Define CTE to calculate rolling sum of people vaccinated per location and date
WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
    FROM CovidVaccinations vac
    JOIN CovidDeaths dea
        ON vac.location = dea.location AND vac.date = dea.date
    WHERE dea.continent IS NOT NULL
)
-- Select from CTE and calculate percentage of population vaccinated
SELECT *, (RollingPeopleVaccinated / population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;

-- 10. Using Temporary Table
-- Drop temp table if it exists
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

-- Create temp table
CREATE TABLE #PercentPopulationVaccinated (
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    NewVaccinations NUMERIC,
    RollingPopulationVaccinated NUMERIC
);

-- Insert into temp table
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidVaccinations vac
JOIN CovidDeaths dea
    ON vac.location = dea.location AND vac.date = dea.date
WHERE dea.continent IS NOT NULL;

-- Select from temp table and calculate percentage of population vaccinated
SELECT *, (RollingPopulationVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM #PercentPopulationVaccinated;

-- 11. Create View
-- Create view to calculate rolling sum of people vaccinated per location and date
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidVaccinations vac
JOIN CovidDeaths dea
    ON vac.location = dea.location AND vac.date = dea.date
WHERE dea.continent IS NOT NULL;
