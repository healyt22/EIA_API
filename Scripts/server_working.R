setwd("~/healyt22/EIA_API/DDP_App/data")

files = list.files(getwd(), recursive = TRUE, pattern = "Summary.csv")
readlist = lapply(files, function(x) {read.table(x, header = TRUE, sep = ",")})
readlist = lapply(readlist, function(x) {colnames(x) [1] <- "Year"; x})
filenames = c("Biomass", "Coal", "Fuel Oil", "Fossil Fuels", "GDP", "Geothermal", "Hydro", 
              "Natural Gas", "Nuclear", "Petroleum", "Renewables", "Solar", "Wind")
names(readlist) = filenames
readlist2 = readlist[-5]
readlist2 = lapply(readlist2, function(x) { x[38:54,] } )
GDP = readlist$GDP
GDP$Year = 1
readlist2 = lapply(readlist2, function(x) { x / GDP })

library(shiny)

shinyServer(function(input, output) {
    
    output$map = renderPlot({
        toggle = switch(input$source)
        dat_toggle = readlist2[[toggle]] 
        
        datm <- melt(dat_toggle, 'Year', 
                     variable.name = 'State',
                     value.name = 'Btu'
        )
        datm$Year <- as.numeric(datm$Year)
        datm$Btu <- as.numeric(datm$Btu)
        datm$State <- as.character(datm$State)
        
        Btu_vals <- subset(datm$Btu, datm$Btu > 0)
        
        datm2 <- transform(datm,
                           fillKey = cut(Btu, quantile(Btu_vals, probs = seq(0, 1, 1/5)), labels = LETTERS[1:5])
        )
        datm2$fillKey <- as.character(datm2$fillKey)
        datm2[, 4][is.na(datm2[, 4])] <- "F"
        
        if(toggle %in% c("Solar", "Wind", "Biomass", "Geothermal", "Hydro", "Renewables")) {
            fills = setNames(
                c(RColorBrewer::brewer.pal(5, 'Greens'), 'white'),
                c(LETTERS[1:5], "F")
            )
            } else { 
            fills = setNames(
                c(RColorBrewer::brewer.pal(5, 'Reds'), 'white'),
                c(LETTERS[1:5], "F")
            )
        }
        
        dat2 <- dlply(na.omit(datm2), "Year", function(x){
            y = toJSONArray2(x, json = F)
            names(y) = lapply(y, '[[', 'State')
            return(y)
        })
    
        options(rcharts.cdn = TRUE)
        map <- Datamaps$new()
        map$set(
            dom = 'map',
            scope = 'usa',
            fills = fills,
            data = dat2[[reactive(input$year)]],
            labels = TRUE
        )
        return(map)
    })
})

