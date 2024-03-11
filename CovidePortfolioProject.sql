select * from CovidDeaths order by 3,4
select * from CovidVaccinations order by 3,4

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths order by 1,2

-- Total case vs total deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathRate
from CovidDeaths 
where location like '%Germany%' and total_deaths is NOT NULL AND total_cases is NOT NULL
and continent is not null 
order by 1,2

-- Total case versis population
select location, date, population, total_cases, (total_cases/population)*100 as SpreadRate
from CovidDeaths 
where location like '%Germany%' and total_deaths is NOT NULL AND total_cases is NOT NULL
and continent is not null 
order by 1,2

-- Looking for countries with highest infection rate per population
select location, population, MAX(total_cases) as HighestInfectedCount, 
MAX((total_cases/population))*100 as PercentpopulationInfected
from CovidDeaths 
where continent is not null 
group by location, population
order by PercentpopulationInfected desc

-- Looking for countries with highest death count per location
select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths 
where continent is not null 
group by location
order by TotalDeathCount desc

-- Looking for continents with highest death count per Continent
select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths 
where continent is not null 
group by continent
order by TotalDeathCount desc

-- Global count of death rate 
select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, 
sum(cast(new_deaths as int))/ sum(new_cases) * 100 as DeathRateOverall
from CovidDeaths 
where  continent is not null 
order by 1,2

-- Total population vs total vaccinations 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is NOT NULL
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is NOT NULL
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From CovidDeaths dea
Join CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
