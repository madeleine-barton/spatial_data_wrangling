# Some example code of how we might use the raster package to 
# work with .nc files 

# from the original script, have tried to replicate what was written 
# using the netcdf4 package, but with raster.
# to load, extract, plot and select desired data

# the raster package:
#***  Robert J. Hijmans & Jacob van Etten (2012). raster: Geographic
#***  analysis and modeling with raster data. R package version 2.0-12.
#***  http://CRAN.R-project.org/package=raster




rm(list=ls()) #this clears all objects from the environment, so we start with a clean slate :)


#install and load the raster package
#install.packages("raster")
library(raster)
library(tidyverse)

#here, cheching that the working directory is correct (we're in the "netCDF_examples" project)
getwd()


#making  a list of the .nc files - I've also downloaded them to my hard-drive, but might be worth
#exploring how you can call them straight from OSM
#again, change path according to your machine
#just calling in two files at the moment, for simplicity
all_files <- list.files(path = "./data/", pattern =".nc")
precip_files <- all_files[8:9]

#call in the files in the list using the raster package "brick" function 
#each layer in the brick is a raster map of the data, for each day of the year. 
#stacked on top of each other (so three dimensions, like an array)
#for this call, we need to know the varname of the .nc files, usually in the 
#corresponding metadata files
#(or a previous script written for the files :))


pr_historical_1960s <- brick(paste("./data/", precip_files[1], sep=""), varname="pr")
pr_historical_1970s <- brick(paste("./data/", precip_files[2], sep=""), varname="pr")

# # filter the data for 1986 - 2005, the same period as the observations data
# historical_1960s <- subset(all_data_historical, 9498:16802)
# station_number <- 29448
# dummy_lon <-
# dummy_lat <-
#     
#     
# #DATA: BOM_stations_filtered NA
#     
# # obtain a raster variable for each observation station
# for (row in 1:nrow(BoM_stations_filtered)){
#     station <- BoM_stations_filtered$Station_Number[row]
#     station_lon <- BoM_stations_filtered$Longitude[row]
#     station_lat <- BoM_stations_filtered$Latitude[row]
#     #print(station)
#     #print(station_lon)
#     #print(station_lat)
#     point_pr_ID <- 
#         raster::extract(historical_1986_2005, 
#                         SpatialPoints(cbind(station_lon[row], 
#                                             station_lat[row] )))[1:nlayers(historical_1986_2005)]
#     new_name <- paste("point_pr_", station, sep="")
#     assign(new_name, point_pr_ID)
#     str_replace(string = 'point_pr_ID', pattern = 'ID', replacement = station)
#     if(row ==1){
#         point_pr_combined <- point_pr_ID
#     }else{
#         point_pr_combined <- rbind(point_pr_combined, point_pr_ID)
#     }
#     
# }


#try plotting the brick:
#the first few layers (days):
plot(pr_historical_1970s)
#the very first layer (day):
plot(pr_historical_1970s$X1970.01.01) #by name
plot(pr_historical_1970s[[1]]) # or via indexing - similar to indexing a list within a list
plot(pr_historical_1970s[[1:4]])


#We can drill down into a specific location, and extract the time series data for that location
#here, generate some dummy co-ordinate variables (e.g. these might be weather station locations):
dummy_lat <- -36
dummy_lon <- 148
#extract the data from all the layers(days) at that location:
#note, we need to specify the layers, otherwise raster brings back the layer names, not the data inside them
point_precip_1960s <- raster::extract(pr_historical_1960s, SpatialPoints(cbind(dummy_lon, dummy_lat)))[1:nlayers(pr_historical_1960s)]
#here, there's another package somewhere that uses "extract", so best to specify the function defined within
#the raster package, using "raster:extract"

#check the data look ok by plotting:
plot(point_precip_1960s) #units ok?



#we can run arithemtic functions on raster objects, so if you need to change units:
pr_historical_1960s_mm  <- pr_historical_1960s * 1000
#this will affect ALL the data, in all of the layers...
plot(pr_historical_1960s_mm[[1:4]]) #note the change in units in the legends
plot(pr_historical_1960s[[1:4]]) #note the change in units in the legends




#to extract a list of the dates from the rasters, call the "z" dimention:
rast_time <- as_tibble(getZ(pr_historical_1960s))
#here, saving it straight into a tibble, to avoid issues with data classes 
#(changing from date to numeric issues)


#and bind these dates to the point data, so was have a data frame for the precipitation for our dummy location
#and the corresponding dates (3653 rows/days in the table)
precip_site1 <- cbind(rast_time, point_precip_1960s)



#to generate a list of the lats/lons in the raster
raster_coords<- as.data.frame(rasterToPoints(pr_historical_1960s[[1]]))
#this extracts the first layer (day) of the brick and writing it straight into a dataframe
head(raster_coords)
#change the column names for easier use
colnames(raster_coords)<-c("lon","lat","precip")
#save the lat/lon as objects for later use (these lines can be reduced down to one if needed)
rast_lat <- raster_coords$lat
rast_lon <- raster_coords$lon

#note also, here we have the precipitation for this fist day, across all the locations:

decadal_mean_pr_historical_1960s <- calc(pr_historical_1960s_mm, mean)

precip_day1 <- raster_coords$precip
mystack <- stack(pr_historical_1960s)
x <- mean(mystack[[1:5]])
x
plot(x)

rs1 <- calc(mystack[[1:5]], mean)
plot(rs1)

annual_mean_pr_historical_1960s <- calc(pr_historical_1960s_mm[[1:365]], mean)

start <- c(1,366)
end <- c(365, 730)


annual_mean_pr_historical_1960s_year1 <- calc(pr_historical_1960s_mm[[start[1]:end[1]]], mean)
annual_mean_pr_historical_1960s_2 <- calc(pr_historical_1960s_mm[[start[1]:end[1]]], mean)

#===================================================================================================================
#Following functions generate LARGE objects
#===================================================================================================================

#to extract EVERYTHING from the raster brick:

my_stack <- stack(pr_historical_1960s) #first convert the brick to a raster, 
#similar to a brick bit a bit easier to work within R (though some of the metadata
#from the original .nc file is dropped)
summary(my_stack)

#WARNING: computer crashes!
raster_as_data<- as.data.frame(rasterToPoints(my_stack))
#this takes ages, and generates a huge dataframe - avoid if possible


#To bind multiple bricks into one stack (if you want to extract the full
#timeseries from 1960 to current day in one go), we can stack the bricks together into one
all_data <- stack(pr_historical_1960s, pr_historical_1970s)
all_data #note the number of layers now 7305 (but metadata has been dropped from the bricks...)

