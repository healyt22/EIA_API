---
title: "US State Energy Consumption"
author: "Tim Healy"
date: "October 25, 2015"
output: ioslides_presentation
runtime: shiny

---
## Table of Contents
- About
- Data Source
- Methodology
- Application

---
## About
This application visualizes state energy consumption from 1998 - 2013. Using data from the Energy Information Administration (EIA), it plots a choropleth map to show relative consumption from renewable and fossil-fuel based sources.

---
## Data Source

```r
setwd( # set working directory to store data )
Key <- # You will need your own API key to reproduce
State <- state.abb
library(jsonlite)
library(curl)
library(plyr)
```
- Set a working directory to store data pulled from the EIA API. 
- Users can register to access the API at the following address: [EIA API] (http://www.eia.gov/beta/api/register.cfm).

---
## Data Source

```r
PullEIA <- function(id) {
    
    dat = data.frame()
    for( i in State) {
        ID = paste("SEDS", id, i, "A", sep = ".")
        url = paste("http://api.eia.gov/series/?api_key=", Key, "&series_id=", ID,  
                    sep = "")
        text = readLines(curl(url))
        dat_raw = fromJSON(text)
        dat_iter = dat_raw$series$data [[1]]
        btus = as.numeric(dat_iter[, 2])
        dat = rbind(dat, btus)
    }
    
    rownames(dat) = State
    colnames(dat) = dat_iter[,1]
    write.csv(dat, paste(id, ".csv", sep = ""))
}
```

---
## Data Source
- Energy source ID is inputted into the above function to pull data. 
- Function downloads time series of energy consumption in Btus for each state and binds together state time series into a summary dataframe. 
- Summary dataframe is saved into user's working directory.

---
## Data Source
Here are the function calls for each of the energy sources used in this analysis. 

```r
PullEIA("SOTCB") # Solar
PullEIA("WYTCB") # Wind
PullEIA("BMTCB") # Biomass
PullEIA("GETCB") # Geothermal
PullEIA("HYTCB") # Hydro
PullEIA("RETCB") # Renewables
PullEIA("CLTCB") # Coal
PullEIA("PATCB") # Petroleum
PullEIA("DFTCB") # Fuel Oil
PullEIA("NGTCB") # Natural Gas
PullEIA("FFTCB") # Fossil Fuels
PullEIA("NUETB") # Nuclear
PullEIA("GDPRX") # GDP
```

---
## Methodology
Example of a summary file, for solar: 

```r
##        2013  2012  2011  2010  2009  2008  2007  2006  2005  2004  2003
## 1 AL    147   129   122   104    86    83    77    74    62    61    75
## 2 AK     10     7     5     4     4     3     0     0     0     0     0
## 3 AZ  35310 21256 10351  5990  4426  3975  3394  3201  2975  2997  3034
## 4 AR    145   138   123   105    82    70    67   112   104   270   406
## 5 CA 109342 74848 60321 46654 37194 33866 28525 25406 23081 22368 21985
## 6 CO   6757  5063  3808  2187  1230   981   463   262   220   199   204
```

---
## Methodology
The summary files are then bundled together into a list of dataframes:

```r
# Combine the energy source files into one list of data frames
State = state.abb
files = paste("./data/", list.files("./data"), sep = "")
readlist = lapply(files, function(x) 
    {read.csv(x, header = TRUE, check.names = FALSE)}
    )
filenames = c("Biomass", "Coal", "Fuel Oil", "Fossil Fuels", "GDP", "Geothermal", "Hydro", 
              "Natural Gas", "Nuclear", "Petroleum", "Renewables", "Solar", "Wind")
names(readlist) = filenames
```

---
## Methodology
These summary files are then divided by each state's real Gross Domestic Product (GDP) to normalize each states energy use per dollar of real GDP. 

```r
# Divide energy source files by GDP to get MM's Btu / $ GDP
readlist2 = readlist[-5]
readlist2 = lapply(readlist2, function(x) { x[, 1:18] } )
GDP = readlist$GDP
readlist2 = lapply(readlist2, function(x) { x[,2:17] / (GDP[2:17] / 1000) })
readlist2 = lapply(readlist2, function(x) { cbind(State, x)})
```

---
## Application
The user inputs the energy source, and toggles the year using a slider

```r
library(rCharts)
options(RCHART_LIB = 'datamaps')
shinyUI(pageWithSidebar(
    headerPanel("State Energy Consumption"),
    
    sidebarPanel( "MMBtu / GDP (Real USD)",
        selectInput("source", 
                label = "Energy Source:",
                choices = c("Solar", "Wind", "Biomass", "Geothermal", "Hydro", "Renewables", 
                            "Coal", "Petroleum", "Fuel Oil", "Natural Gas", "Fossil Fuels", "Nuclear"),
                selected = "Renewables"),
            
        sliderInput("year", 
                label = "Year:",
                min = 1998, max = 2013, value = 1998, sep = "", ticks = FALSE)
        ),
        
    mainPanel(showOutput("energy_map", "datamaps"))
    )
)
```

```
## Error in eval(expr, envir, enclos): could not find function "shinyUI"
```

---
## Application

```r
shinyServer(function(input, output) {
    output$energy_map <- renderChart({
        SOURCE = input$source
        source_dat = readlist2[[SOURCE]]
        
        YEAR = as.character(input$year)
        source_dat = source_dat[, c("State", YEAR)]
        
        if(SOURCE %in% c("Solar", "Wind", "Biomass", "Geothermal", "Hydro", "Renewables")){
            cols = 'Greens'
        } else {
            cols = 'Reds'
        }
        
        energy_map = rCharts::choropleth(
            cut(source_dat[, YEAR], 5, labels = F) ~ State,
            data = source_dat,
            pal = cols
        )
        energy_map$addParams(dom = "energy_map")
        energy_map
    })
})
```


