
Key <- "2EBB5C2112CCA0446F6A06DDAF2EB80A"
states <- state.abb
library(jsonlite)
library(curl)
library(plyr)

PullEIA <- function(id) {

    dat = list()
    for( i in states) {
        ID = paste("SEDS", id, i, "A", sep = ".")
        url = paste("http://api.eia.gov/series/?api_key=", Key, "&series_id=", ID,  
            sep = "")
        text = readLines(curl(url))
        dat_raw = fromJSON(text)
        dat_iter = dat_raw$series$data
        dat = c(dat, dat_iter)
    }

    names(dat) = states

    dat2 = lapply(dat, as.data.frame)
    dat2 = mapply(cbind, dat2, "State" = states, SIMPLIFY=F)
    dat2 = do.call("rbind", dat2)
    colnames(dat2) = c("Year", "Btu", "State")

    datm = dat2
    datm$Year <- as.numeric(as.character(datm$Year))
    datm$Btu <- as.numeric(as.character(datm$Btu))
    datm$State <- as.character(datm$State)
    
    Btu_vals <- subset(datm$Btu, datm$Btu > 0)
    
    datm2 <- transform(datm,
                       fillKey = cut(Btu, quantile(Btu_vals, probs = seq(0, 1, 1/5)), labels = LETTERS[1:5])
    )
    datm2$fillKey <- as.character(datm2$fillKey)
    datm2[, 4][is.na(datm2[, 4])] <- "F"
    
    fills = setNames(
        c(RColorBrewer::brewer.pal(5, 'Greens'), 'white'),
        c(LETTERS[1:5], "F")
    )
    
    dat2 <- dlply(na.omit(datm2), "Year", function(x){
        y = toJSONArray2(x, json = F)
        names(y) = lapply(y, '[[', 'State')
        return(y)
    })
    
    options(rcharts.cdn = TRUE)
    map <- Datamaps$new()
    map$set(
        dom = 'chart_1',
        scope = 'usa',
        fills = fills,
        data = dat2[[54]],
        labels = TRUE
    )
    
    map2 = map$copy()
    map2$set(
        bodyattrs = "ng-app ng-controller='rChartsCtrl'"
    )
    map2$addAssets(
        jshead = "http://cdnjs.cloudflare.com/ajax/libs/angular.js/1.2.1/angular.min.js"
    )
    
    map2$setTemplate(chartDiv = "
                <div id = 'chart_1' class = 'rChart datamaps'>
                <input id='slider' type='range' min=1989 max=2013 ng-model='year' width=200>
                <span ng-bind='year'></span>
                 
                <script>
                function rChartsCtrl($scope){
                $scope.year = '1989';
                $scope.$watch('year', function(newYear){
                mapchart_1.updateChoropleth(chartParams.newData[newYear]);
                })
                }
                </script>
                </div>   "
    )
    
    map2$set(newData = dat2)
    map2    
        
}

PullEIA("SOHCB")
