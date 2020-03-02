# This code computes the "population weighted center" of New Zealand
# using Stats NZ pop data and meshblock/statistical area shapefiles

# Load packages
library(rgdal); library(dplyr); library(readxl); library(ggmap)

# Set shapefile folder names
folder_01 = "./data/statsnzmeshblock-2001-SHP"
folder_18 = "./data/statsnzstatistical-area-1-2018-generalised-SHP"

# Add google API key here
google_key = "key here"

# -----------------------
# Tidy Shapefiles
# -----------------------

# Read 2001 meshblock shapefile: https://datafinder.stats.govt.nz/layer/25744-meshblock-2001/
d01 <- readOGR(dsn = folder_01, layer = "meshblock-2001")

# Read 2018 statistical area shapefile: https://datafinder.stats.govt.nz/layer/92210-statistical-area-1-2018-generalised/
d18 <- readOGR(dsn = folder_18, layer = "statistical-area-1-2018-generalised")

# Transform coordinates
d01 <- spTransform(d01, CRS("+init=epsg:4326"))
d18 <- spTransform(d18, CRS("+init=epsg:4326"))

# Get centroids of each meshblock
cents01 = as.data.frame(rgeos::gCentroid(d01,byid=TRUE))
cents18 = as.data.frame(rgeos::gCentroid(d18,byid=TRUE))

# Extract dataframe from shapefile and add centroid coordinates for 2001 data
temp01 = d01@data %>% mutate(mb  = as.character(MB2001_V1_),
                             lon = cents01$x,
                             lat = cents01$y)

# Extract dataframe from shapefile and add centroid coordinates for 2018 data
temp18 = d18@data %>% mutate(sa = as.character(SA12018_V1),
                             lon = cents18$x,
                             lat = cents18$y)

# -----------------------
# Tidy Stats NZ Population Count Data
# -----------------------

# Read 2001 population data
df01 = read_excel("./data/2001-part1-mb01-curpc91-96-01.xlsx", sheet = 1, skip = 1,
                col_types = c("text", "numeric", "numeric", "numeric"),
                col_names =  c("mb2001","pop91","pop96","pop01")) %>%
  mutate(mb = gsub("MB ","",mb2001))

# Read 2018 population data
df18 = read_excel("./data/2018-sa1-curpc.xlsx", sheet = 1, skip = 2,
                  col_types = c("text", "numeric", "numeric", "numeric"),
                  col_names =  c("sa","pop06","pop13","pop18")) 

# Join each with the shapefile dataframes
join01 = df01 %>% left_join(temp01,by="mb") %>% select(mb,pop91,pop96,pop01,lon,lat)
join18 = df18 %>% left_join(temp18,by="sa") %>% select(sa,pop06,pop13,pop18,lon,lat) %>%
  mutate(pop06 = replace(pop06,pop06 == 0,NA),
         pop13 = replace(pop13,pop13 == 0,NA),
         pop18 = replace(pop18,pop18 == 0,NA))

# -----------------------
# Computations
# -----------------------

# Compute Weighted Center for 2001 Data
join01 = join01 %>% mutate(wlat91 = lat * pop91,
                           wlat96 = lat * pop96,
                           wlat01 = lat * pop01,
                           wlon91 = lon * pop91,
                           wlon96 = lon * pop96,
                           wlon01 = lon * pop01)

lat91 = sum(join01$wlat91,na.rm = T) / sum(join01$pop91,na.rm = T)
lon91 = sum(join01$wlon91,na.rm = T) / sum(join01$pop91,na.rm = T)
lat96 = sum(join01$wlat96,na.rm = T) / sum(join01$pop96,na.rm = T)
lon96 = sum(join01$wlon96,na.rm = T) / sum(join01$pop96,na.rm = T)
lat01 = sum(join01$wlat01,na.rm = T) / sum(join01$pop01,na.rm = T)
lon01 = sum(join01$wlon01,na.rm = T) / sum(join01$pop01,na.rm = T)

# Compute Weighted Center for 2018 Data
join18 = join18  %>% mutate(wlat06 = lat * pop06,
                            wlat13 = lat * pop13,
                            wlat18 = lat * pop18,
                            wlon06 = lon * pop06,
                            wlon13 = lon * pop13,
                            wlon18 = lon * pop18)

lat06 = sum(join18$wlat06,na.rm = T) / sum(join18$pop06,na.rm = T)
lon06 = sum(join18$wlon06,na.rm = T) / sum(join18$pop06,na.rm = T)
lat13 = sum(join18$wlat13,na.rm = T) / sum(join18$pop13,na.rm = T)
lon13 = sum(join18$wlon13,na.rm = T) / sum(join18$pop13,na.rm = T)
lat18 = sum(join18$wlat18,na.rm = T) / sum(join18$pop18,na.rm = T)
lon18 = sum(join18$wlon18,na.rm = T) / sum(join18$pop18,na.rm = T)

# Combine coordinates
points = data.frame(lat = c(lat91,lat96,lat01,lat06,lat13,lat18),
                    lon = c(lon91,lon96,lon01,lon06,lon13,lon18),
                    label = c(1991,1996,2001,2006,2013,2018)) %>%
  mutate(coords = paste(lat,",",lon))

# -----------------------
# Distance Calculations
# -----------------------

distmat <- points %>% select(lon,lat) %>% as.matrix() %>% geosphere::distm()
per_survey_dist = distmat[row(distmat) == (col(distmat) - 1)]
annual_dist_km = sum(per_survey_dist) / (2018 - 1991) / 1000

# -----------------------
# Static Map
# -----------------------

register_google(key = google_key)
nz_map <- get_map(location = c(173.2, -40.8, 176, -38))

ggmap(nz_map) +
  geom_point(data=points,aes(x=lon,y=lat),alpha=0.9,size=2.4,color="red") +
  geom_text(data=points,aes(label=label),hjust=-0.3, vjust=0.4,size=3,fontface='bold')+ 
  ggthemes::theme_fivethirtyeight() +
  theme(legend.position='None',
        panel.grid.major = element_blank(),
        axis.text=element_blank(),
        axis.ticks=element_blank(),
        plot.title=element_text(face="bold",hjust=.012,vjust=.8,colour="#3C3C3C",size=13),
        plot.caption = element_text(size=8),
        plot.subtitle=element_text(size=10, hjust=0.012, face="italic", color="black")) +
  labs(title="Population Weighted Center of New Zealand",
       subtitle = "Annual average movement of 1.28 km",
       caption = "Source: Stats NZ Census Data & Geographic Data Service")
ggsave("map1.png",width = 8.4, height = 9)

# -----------------------
# Interactive Map
# -----------------------

library(leaflet)
leaflet(points) %>% addTiles() %>%
  addMarkers(~lon,~lat,label=~coords,labelOptions = labelOptions(noHide = F)) %>%
  addLabelOnlyMarkers(~lon, ~lat, label = ~label, 
                      labelOptions = labelOptions(noHide = T, direction = 'right',
                                                  textOnly = T,textsize='15px',
                                                  'font-style'= 'bold')) %>%
  setView(zoom = 10,lat=mean(points$lat), lng=mean(points$lon))

