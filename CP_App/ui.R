library(rCharts)
options(RCHART_LIB = 'datamaps')
shinyUI(pageWithSidebar(
    headerPanel("State Energy Consumption"),
    
    sidebarPanel( "MMBtu / GDP (Real USD)", width = "3",
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
