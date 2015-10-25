setwd("~/healyt22/EIA_API/CP_App") # set working directory to store data
Key <- "2EBB5C2112CCA0446F6A06DDAF2EB80A" # You will need your own API key to reproduce
State <- state.abb
library(jsonlite)
library(curl)
library(plyr)

# Function to call the Energy Information Administration API for state energy data
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

# Calling for various energy sources
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

