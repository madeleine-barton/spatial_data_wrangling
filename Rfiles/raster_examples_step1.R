# Some example code of how we might use the raster package to 
# work with .nc files 

# calling in some example data, ".nc" files for temperature across either 
# NSW or Tasmania. sourced from the SILO database


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

###############################################################################
#the difference between a raster, stack and brick
###############################################################################
#raster = 1 layer of data
#stack = >1 layer of data: smaller: easier to work with within R
#brick = >1 layer of data: larger, but maintains metadata; easier to read/write to file


#FROM: https://geoscripting-wur.github.io/IntroToRaster/
# RasterStack and RasterBrick are very similar, the difference being in the virtual 
# characteristic of the RasterStack. While a RasterBrick has to refer to one 
# multi-layer file or is in itself a multi-layer object with data loaded in 
# memory, a RasterStack may ''virtually'' connect several raster objects written 
# to different files or in memory. Processing will be more efficient for a 
# RasterBrick than for a RasterStack, but RasterStack has the advantage of 
# facilitating pixel based calculations on separate raster layers


#making  a list of the .nc files in the data folder
example_files <- list.files(path = "./data/", pattern =".nc")
example_files

#call in the files in the list using the raster package "brick" function 
#each layer in the brick is a raster map of the data, for each day of the year. 
#stacked on top of each other (so three dimensions, like an array)
#for this call, we need to know the varname of the .nc files, usually in the 
#corresponding metadata files
#(or a previous script written for the files :))

#starting with the maximum temperature in 2002:
#both raster() and stack() funcitons can call in these data, but brick()
#is much more efficient for large datasets. 
#if varname is incorrect, R will suggest the correct one in an error message
temp_raster <- raster(paste("./data/", example_files[1], sep=""), varname="max_temp")
#only first layer(or band) is called
temp_stack <- stack(paste("./data/", example_files[1], sep=""), varname="max_temp")
#all there, but missing some metadata, and a "Large RasterStack" = potential memory problems
temp_brick <- brick(paste("./data/", example_files[1], sep=""), varname="max_temp")
#better

#explore some of the different variables of the brick
temp_brick #details of the temperature brick
plot(temp_brick) #plotting the brick
nlayers(temp_brick) #the number of layers (days)
names(temp_brick) #the names of each layer
extent(temp_brick) #the boundaries of the  map
res(temp_brick) #the resolution of the cells
projection(temp_brick) #the projection of the map
hasValues(temp_brick) #check the values are included


#select out the first four days (raster layers) of the brick
new_years <- subset(temp_brick, 1:4)
new_years
plot(new_years)


#We can modify values within the map with simple equations
#e.g. if we want to turn the temperautre into Kelvin:
new_years_K <- new_years + 273.15
new_years_K
plot(new_years_K)

#or transform temperature into the decimal
new_years_d <- new_years/10
new_years_d
plot(new_years_d)


#or take the mean of the first 4 days in january 
#(this will take the  mean value for each location across all the layers)
new_years_mean1 <-mean(subset(temp_brick, 1:4))
plot(new_years_mean1)
new_years_mean1 #this has been condensed into one rasterlayer (note the change in object type from a brick to a raster layer)

#or, the maximum temperature during this time:
new_years_max1 <-max(subset(temp_brick, 1:4))
plot(new_years_max1)

#another way of doing this is with the calc funciton
new_years_mean2 <- calc(temp_brick[[1:4]], mean)
plot(new_years_mean2)
new_years_max2 <- calc(temp_brick[[1:4]], max)
plot(new_years_max2)

#check these two methods have done the same thing (Two ways of doing this)
compareRaster(new_years_max1, new_years_max2)
all.equal(new_years_max1, new_years_max2)



#CROPPING
#we can zoom in on a region of interest by setting the extent (boundaries)
#to be between a certain lat/lon range
#in the summary, "extent" values listed by west to east, south to north 
#first just call the first layer of the brick:
jan_one <- subset(temp_brick, 1)
extent(jan_one) #check the extent
#crop this map
south_east_aus <- crop(jan_one, extent(130, 154.025, -44.025, -30))
plot(south_east_aus)

#extract the minimum and maximum values from the raster layer
minValue(south_east_aus)
maxValue(south_east_aus)

#AGGREGATE
#can conbine adjacent cells into one, so that the resolution increases, 
#here we van take the mean value among the adjcent cells, the min of max etc. 
aggregated_SE <- aggregate(south_east_aus, fun=max, na.rm=TRUE, fact=9) 
#combine the 9 adjacent cells, taking the mean, and remove any cells where an "NA" is calculated
plot(aggregated_SE)

disaggregated_SE <- disaggregate(south_east_aus, 9) #separate out the 9 adjacent cells
plot(disaggregated_SE)


#COMBINING two raster layers into a stack:
#first create two rasters:
jan_one <- subset(temp_brick, 1)
jan_two <- subset(temp_brick, 2)

jan_stack <- stack(jan_one, jan_two)
jan_stack
plot(jan_stack)





#extracting the values:
getValues(south_east_aus) # there are some cells where the data are missing


#convert the rasterLayer to a dataframe: 
p <- rasterToPoints(south_east_aus)
newdata <- as.data.frame(p)
colnames(newdata)
colnames(newdata) <- c("Lat","Lon","Temperature")


#convert the rasterSTACK/Brick to a dataframe: 
p <- rasterToPoints(new_years)
newdata <- as.data.frame(p)
colnames(newdata) #each layer/day gets its own column
#Use tidyverse to manipuate this where required


#write the raster ojbect to an .nc file
#the raster object here can be a raster stack or brick, but automatically
#converts a stack to a brick. So to call the file
#back into R, we need to treat it as a brick (see above :))
writeRaster(new_years, filename= "./data/new_years_edited.nc", overwrite=TRUE)
#NB: wary of overwirte :)


#=======================================================================================
#Drilling down into the raster layers to extract data from a specific location
#=======================================================================================
#Interested in Canberra's weather over January:
lat_CBR <- -35
lon_CBR <- 149

CBR_temps<- raster::extract(temp_brick, SpatialPoints(cbind(lon_CBR,lat_CBR)))[1:365]
CBR_temps
#this generates a list of numbers, so for easier use, save as atibble
CBR_temps <- as_tibble(CBR_temps)
#Use tidyverse to manipuate this where required



#for summer only, we can select out the summer layers with the indexing []
CBR_summer<- raster::extract(temp_brick, SpatialPoints(cbind(lon_CBR,lat_CBR)))[1:31]
CBR_summer
#this generates a list of numbers, so for easier use, save as atibble
CBR_summer <- as_tibble(CBR_summer)
#Use tidyverse to manipuate this where required



#to generate a list of the lats/lons in the raster
raster_coords<- as_tibble(rasterToPoints(temp_brick[[1]]))



