# Combine the energy source files into one list of data frames
State = state.abb
files = paste("./data/", list.files("./data"), sep = "")
readlist = lapply(files, function(x) 
    {read.csv(x, header = TRUE, check.names = FALSE)}
    )
filenames = c("Biomass", "Coal", "Fuel Oil", "Fossil Fuels", "GDP", "Geothermal", "Hydro", 
              "Natural Gas", "Nuclear", "Petroleum", "Renewables", "Solar", "Wind")
names(readlist) = filenames

# Divide energy source files by GDP to get MM's Btu / $ GDP
readlist2 = readlist[-5]
readlist2 = lapply(readlist2, function(x) { x[, 1:18] } )
GDP = readlist$GDP
readlist2 = lapply(readlist2, function(x) { x[,2:17] / (GDP[2:17] / 1000) })
readlist2 = lapply(readlist2, function(x) { cbind(State, x)})

## SERVER

require(rCharts)
require(RColorBrewer)
options(RCHART_WIDTH = 800)
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
