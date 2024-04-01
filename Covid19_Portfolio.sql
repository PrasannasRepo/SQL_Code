/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

-- Select Data that we are going to be starting with
select *  from Portfolio..Covid_Deaths 
where continent is not null  
order by 3,4

select * from Portfolio..Covid_Vaccination 
order by 3,4  

-- Altering column data types
alter table portfolio..covid_deaths alter column total_cases numeric(15,5)
alter table portfolio..covid_deaths alter column total_deaths numeric(15,5)

-- Looking at Total Cases vs Total Deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)* 100 as Death_Percentage 
from Portfolio..Covid_Deaths where location = 'India' and order by 1,2

-- Looking at Total Cases vs Population
select location, total_cases, population, (total_cases/population)* 100 as percentage_of_affected_population
from Portfolio..Covid_Deaths 
--where location = 'India'

-- Looking at countries with highest infection rate compared to Population
select location, max(total_cases), population, max((total_cases/population)* 100) as PercentPopulationAffected
from Portfolio..Covid_Deaths 
group by location, population 
order by PercentPopulationAffected desc

-- Total Deaths by Country
select location, MAX(cast (total_deaths as int)) as TotalDeaths
from Portfolio..Covid_Deaths where continent is not null 
group by LOCATION 
order by TotalDeaths desc

-- Showing Countries with Highest Death Count per polulation
select location, max(population) as Population, max(total_deaths) as total_dead_people, (max(total_deaths)/max(population))*100 as death_percent 
from covid_deaths where continent is not null 
group by location 
order by death_percent desc

 -- Showing continents with Highest Death count per Population
 select continent, max(total_deaths) Total_Deaths, max((total_deaths/population)*100) as PercentDeathsVsPopulation 
 from Covid_Deaths where continent is not null 
 group by continent 
 order by Total_Deaths desc
 
-- Global Numbers
select sum(new_cases) as TotalCases, sum(new_deaths) as TotalDeaths,  
(sum(new_deaths)/nullif(sum(new_cases), 0))*100 as DeathPercentage
from covid_Deaths where continent is not null 
group by date 
order by DeathPercentage desc

SELECT * FROM Covid_Deaths dt inner join Covid_Vaccination vc on dt.location = vc.location and vc.date = dt.date

--Looking at total population Vs Vaccination
SELECT dt.date,dt.continent, dt.location ,dt.population, cast(vc.new_vaccinations as numeric(15, 5)) as NewVaccination,
nullif(sum(cast(vc.new_vaccinations as numeric(15, 5))) over (partition by dt.location), 0) as Fixed_Sum_of_Vaccination
FROM Covid_Deaths dt inner join Covid_Vaccination vc on dt.location = vc.location and vc.date = dt.date
where dt.continent is not null 
order by location 

--Modifying above Partition Statement 
SELECT dt.date,dt.continent, dt.location ,dt.population, cast(vc.new_vaccinations as numeric(15, 2)) as NewVaccination,
nullif(sum(cast(vc.new_vaccinations as numeric(15, 2))) over (partition by dt.location order by dt.location, dt.date), 0) as Rolling_Sum_of_Vaccination
FROM Covid_Deaths dt inner join Covid_Vaccination vc on dt.location = vc.location and vc.date = dt.date
where dt.continent is not null 
order by location 

-- Adding CTE to above statement
with VaccinatedPopulation(Date, Continet, location, Population, NewVaccination, Rolling_Sum_of_Vaccination)
as 
(SELECT dt.date,dt.continent, dt.location ,dt.population as Population, cast(vc.new_vaccinations as numeric(15, 2)) as NewVaccination,
nullif(sum(cast(vc.new_vaccinations as numeric(15, 2))) over (partition by dt.location order by dt.location, dt.date), 0) as Rolling_Sum_of_Vaccination
FROM Covid_Deaths dt inner join Covid_Vaccination vc on dt.location = vc.location and vc.date = dt.date
where dt.continent is not null 
-- order by location 
)
select *, (Rolling_Sum_of_Vaccination/population)*100 as Rolling_Percent_of_Vaccination from VaccinatedPopulation 

-- Creating temp table
Drop table if exists #VaccinatedPopulation
create table #VaccinatedPopulation
(
Date datetime,
Continent nvarchar(100),
Location nvarchar(100),
Population int,
NewVaccination Numeric(15, 5),
Rolling_Sum_of_Vaccination Numeric(15, 5)
)

insert into #VaccinatedPopulation 
SELECT dt.date,dt.continent, dt.location ,dt.population as Population, cast(vc.new_vaccinations as numeric(15, 2)) as NewVaccination,
nullif(sum(cast(vc.new_vaccinations as numeric(15, 2))) over (partition by dt.location order by dt.location, dt.date), 0) as Rolling_Sum_of_Vaccination
FROM Covid_Deaths dt inner join Covid_Vaccination vc on dt.location = vc.location and vc.date = dt.date
where dt.continent is not null 
-- order by location 

select *, (Rolling_Sum_of_Vaccination/Population)*100 from #VaccinatedPopulation

--Creating View to Store Data for Visulizations
Create View PercentPopulationVaccinated as
SELECT dt.date,dt.continent, dt.location ,dt.population as Population, cast(vc.new_vaccinations as numeric(15, 2)) as NewVaccination,
nullif(sum(cast(vc.new_vaccinations as numeric(15, 2))) over (partition by dt.location order by dt.location, dt.date), 0) as Rolling_Sum_of_Vaccination
FROM Covid_Deaths dt inner join Covid_Vaccination vc on dt.location = vc.location and vc.date = dt.date
where dt.continent is not null 
-- order by location 

select * from PercentPopulationVaccinated
-- drop view PercentPopulationVaccinated