select *
from PortfolioProject..CovidDeaths
order by 3,4

--problem with data, where the continent is null, the continent has been typed in the location column
--below is the query for that
select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

select *
from PortfolioProject..CovidVaccinations
order by 3,4


--Select data that we are going to use (this comment not be used in actual project)

select location, date, total_cases, new_cases, total_deaths, population 
from PortfolioProject..CovidDeaths
order by 1,2


--Looking at Total Cases vs Total Deaths (Percentage)
--Shows likelihood of dying if you contract covid in your country
--getting data for location name which includes the word 'India'.You can use '=' if you know exact name (comment for my reference).
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%India%'
order by 1,2


--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
where location like '%India%'
order by 1,2


--Looking at Countries with Hightest Infection Rate compared to Polpulation

select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as PercentPopulationInfected
from PortfolioProject..CovidDeaths
--where location like '%India%'
where continent is not null
group by population, location
order by PercentPopulationInfected desc


--Showing Countries with Highest Death Count per Population
select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
--where location like '%India%'
where continent is not null
group by population, location
order by TotalDeathCount desc


--LET'S BREAK THINGS DOWN BY CONTINENT
--Showing continent with the highest death count per population

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
--where location like '%India%'
where continent is not null
group by continent
order by TotalDeathCount desc


-- GLOBAL NUMBERS

--Just for a look
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--where location like '%India%'
where continent is not null
order by 1,2


--Total numbers by date and time
select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--where location like '%India%'
where continent is not null
group by date
order by 1,2


-- Total numbers
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
--where location like '%India%'
where continent is not null
order by 1,2


select *
from CovidVaccinations


--Looking at Total Population vs Vaccinations
--How many have been vaccinated in the world

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from CovidDeaths as dea
 join CovidVaccinations as vac
	on dea.location = vac.location and
	dea.date = vac.date
where dea.continent is not null
order by 2,3

--Using cast
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) over (Partition by dea.location)
from CovidDeaths as dea
 join CovidVaccinations as vac
	on dea.location = vac.location and
	dea.date = vac.date
where dea.continent is not null
order by 2,3


--using convert instead of cast
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) 
	as RollingPeopleVaccinated
from CovidDeaths as dea
 join CovidVaccinations as vac
	on dea.location = vac.location and
	dea.date = vac.date
where dea.continent is not null
order by 2,3



select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int)) over (Partition by dea.location order by dea.location, dea.date) 
	as RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/dea.population)
from CovidDeaths as dea
 join CovidVaccinations as vac
	on dea.location = vac.location and
	dea.date = vac.date
where dea.continent is not null
order by 2,3
--Using a column that you have just created for query gives an error.
--Therefore use CTE or TempTables


--Use CTE

with Pop_vs_Vac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int, vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) 
	as RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/dea.population)
from CovidDeaths as dea
 join CovidVaccinations as vac
	on dea.location = vac.location and
	dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *,(RollingPeopleVaccinated/population)*100
from Pop_vs_Vac



-- TEMP TABLES .. Note: here the new_vaccination has been convertef to bigint instead of int as the numbers are very big.
-- If you use int instead, it will give you an arithemetic error.

drop table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.location, dea.date) 
	as RollingPeopleVaccinated
	-- (RollingPeopleVaccinated/population)
from CovidDeaths as dea
 join CovidVaccinations as vac
	on dea.location = vac.location and
	dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated


--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

create View PercentPopulationVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (Partition by dea.location order by dea.location, dea.date) 
	as RollingPeopleVaccinated
	-- (RollingPeopleVaccinated/population)
from CovidDeaths as dea
 join CovidVaccinations as vac
	on dea.location = vac.location and
	dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *
from PercentPopulationVaccinated