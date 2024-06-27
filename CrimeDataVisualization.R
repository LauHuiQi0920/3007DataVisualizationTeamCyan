## -----------------------------------------------------------------------------
#| output: false
# Load necessary libraries
library(dplyr)
library(ggplot2)
library(tidyverse)
library(readxl)
library(lubridate)
library(DT)
library(sf)


## -----------------------------------------------------------------------------
#| label: data import
#| output: false
# Set the path to the CSV file
file_path <- "Crime_Data_from_2020_to_Present_20240607.csv"

# Read the CSV file into a data frame
crime_data <- read.csv(file_path)

# View the first few rows of the data
head(crime_data)


## -----------------------------------------------------------------------------
#| label: data-cleaning - keep selected column
#| output: false

crime_data <- crime_data |>
  select(Date.Rptd, DATE.OCC, TIME.OCC, AREA, AREA.NAME, Rpt.Dist.No, Crm.Cd, Crm.Cd.Desc, Crm.Cd.1, Crm.Cd.2, Crm.Cd.3, Crm.Cd.4, LOCATION, Cross.Street, LAT, LON)

# View the first few rows of the modified data
head(crime_data)


## -----------------------------------------------------------------------------
#| label: data cleaning - remove rows if null for certain column, remove multiple spaces if any

# Remove rows with NA values in the specified columns
cleaned_crime_data <- crime_data %>%
  filter(
    !is.na(Date.Rptd) &
    !is.na(DATE.OCC) &
    !is.na(TIME.OCC) &
    !is.na(AREA) &
    !is.na(AREA.NAME) &
    !is.na(Rpt.Dist.No) &
    !is.na(LOCATION) &
    !is.na(LAT) &
    !is.na(LON)
  )

# Function to replace multiple spaces with a single space in a string
replace_multiple_spaces <- function(x) {
  gsub("\\s+", " ", x)
}

# Apply the function to all character columns in the data frame
cleaned_crime_data <- cleaned_crime_data %>%
  mutate(across(where(is.character), replace_multiple_spaces))

# View the first few rows of the cleaned data
head(cleaned_crime_data)


## -----------------------------------------------------------------------------
#| label: data-formating

# Convert DATE.OCC to Date format
cleaned_crime_data$DATE.OCC <- as.Date(cleaned_crime_data$DATE.OCC, format="%m/%d/%Y %I:%M:%S %p")

# Extract month and year from DATE.OCC
cleaned_crime_data <- cleaned_crime_data %>%
  mutate(
    DATE.OCC.MONTH = month(DATE.OCC),
    DATE.OCC.YEAR = year(DATE.OCC)
  )

cleaned_crime_data <- cleaned_crime_data %>%
  select(Date.Rptd, DATE.OCC, DATE.OCC.MONTH, DATE.OCC.YEAR, everything())

# View the first few rows of the cleaned data with new columns
datatable(head(cleaned_crime_data))


## -----------------------------------------------------------------------------
#| label: data-preparation
#| message: false

#Counts of crime in each area
crime_counts_by_area <- cleaned_crime_data %>%
  mutate(AREA.NAME = toupper(AREA.NAME)) %>%
  group_by(AREA, AREA.NAME) %>%
  summarise(Crime_Count = n(), .groups = 'drop')

crime_counts_by_area[8, "AREA.NAME"] <- "WEST LOS ANGELES"
crime_counts_by_area[15, "AREA.NAME"] <- "NORTH HOLLYWOOD"

crime_counts_by_area


## -----------------------------------------------------------------------------
#Based of crime code, find top 5 crime codes and the corresponding crime description based on each area
top_crime_codes_by_area <- cleaned_crime_data %>%
  mutate(AREA.NAME = toupper(AREA.NAME)) %>%
  mutate(
    AREA.NAME = replace(AREA.NAME, AREA == 8, "WEST LOS ANGELES"), # Fix Short Form Names
    AREA.NAME = replace(AREA.NAME, AREA == 15, "NORTH HOLLYWOOD"),
    AREA.NAME = replace(AREA.NAME, AREA == 3, "SOUTHWEST"), # Fix AREA with wrong names
  ) %>%
  group_by(AREA, AREA.NAME, Crm.Cd, Crm.Cd.Desc) %>%
  summarise(Crime_Count = n(), .groups = 'drop') %>%
  arrange(desc(Crime_Count)) %>%
  group_by(AREA, AREA.NAME) %>%
  slice_head(n = 5)

top_crime_codes_by_area


## -----------------------------------------------------------------------------
#| label: data-visualisation - total crimes by area
#| message: false

#Plot the number of crimes in each area in a map
crime_counts_by_area_map <- crime_counts_by_area %>%
  ggplot(aes(x = AREA, y = AREA.NAME, size = Crime_Count)) +
  geom_point(aes(colour = Crime_Count), alpha = 0.7) +
  scale_size_continuous(range = c(2, 12)) +
  labs(title = "Number of Crimes in Each Area", x = "Area", y = "Area Name") +
  theme_minimal()

crime_counts_by_area_map


## -----------------------------------------------------------------------------
#| label: data-preparation - centroids
#| warning: false

la <- st_read("City_Boundary.geojson")

la_centroids <- la %>%
  st_centroid() %>%
  rename(centroids = geometry) %>%
  st_coordinates() %>%
  as.data.frame() %>%
  setNames(c("long_center", "lat_center")) %>%
  mutate(APREC = la$APREC)

# Join the total crime counts by area with the centroids
la_count <- la %>%
  left_join(crime_counts_by_area, by = c("APREC" = "AREA.NAME", "PREC" = "AREA")) %>%
  left_join(la_centroids, by = c("APREC" = "APREC"))

# Join the top crime codes by area with the centroids
top_crimes_la_count <- top_crime_codes_by_area %>%
  left_join(la, by = c("AREA.NAME" = "APREC", "AREA" = "PREC")) %>%
  left_join(la_centroids, by = c("AREA.NAME" = "APREC"))


## -----------------------------------------------------------------------------
#| label: data-preparation - jitter coords for top 5 crimes

# Define the number of points and radius for the circular spread
n_points <- 5  # Number of top crimes
radius <- 4000  # Radius for the spread

# Function to generate circular points around a centroid
generate_circular_points <- function(lon, lat, n_points, radius) {
  angles <- seq(0, 2 * pi, length.out = n_points + 1)[-1]
  tibble(
    jittered_long = lon + radius * cos(angles),
    jittered_lat = lat + radius * sin(angles)
  )
}

# Generate circular points for each row in the dataset
top_crimes_la_count <- top_crimes_la_count %>%
  group_by(AREA) %>%
  mutate(id = row_number()) %>%
  ungroup() %>%
  rowwise() %>%
  mutate(
    circular_coords = list(generate_circular_points(long_center, lat_center, n_points, radius)),
    jittered_long = circular_coords$jittered_long[id],
    jittered_lat = circular_coords$jittered_lat[id]
  ) %>%
  select(-circular_coords, -id) %>%
  ungroup()


## -----------------------------------------------------------------------------
#| label: data-preparation - jitter coords for top 5 crimes (alternative)
top_crimes_la_count <- top_crimes_la_count %>%
  group_by(AREA) %>%
  mutate(
    rank = rank(Crime_Count),
    jittered_long = long_center - 5000,
    jittered_lat = lat_center - 10000 + rank * 3000
  ) %>%
  ungroup()


## ----fig.height=15, fig.width=15----------------------------------------------
#| label: data-visualisation - number of top 5 crimes by area map

# Plot the top 5 crime codes in each area map with jittered points
top_crime_codes_by_area_map <- top_crime_codes_by_area %>%
  ggplot(aes(x = AREA, y = AREA.NAME, size = Crime_Count, colour = factor(Crm.Cd.Desc))) +
  geom_point(alpha = 0.5, position = position_jitter(width = 0.9, height = 0.8)) +
  scale_size_continuous(name = "Crime Count", range = c(2, 12)) +
  scale_colour_viridis_d(name = "Crime Type", option = "turbo", begin = 0.6, end = 1) +
  labs(title = "Number of Top 5 Crimes in Each Area", x = "Area", y = "Area Name") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 25, face = "bold"),
    axis.title.x = element_text(size = 12),
    axis.title.y = element_text(size = 12),
    axis.text.x = element_text(size = 10),
    axis.text.y = element_text(size = 10),
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 10)
  )

# Display the plot
top_crime_codes_by_area_map


## ----fig.height=15, fig.width=15----------------------------------------------
#| label: data-visualisation - number of top 5 crimes and total crimes by area using geom_sf

# Define a set of shapes to use
shape_values <- c("\U1F52A", "\U1F44A", "\U1F3E0", "\U1F513", "\U1F494", "\U1F6CD", "\U1F3AD", "\U1F4B8", "\U1F58C", "\U1F693")

# Plot the number of top 5 crimes and total crimes in each area map using geom_sf
top_crime_codes_by_area_map_sf <- ggplot() +
  geom_sf(data = la_count, aes(fill = Crime_Count)) +
  geom_point(data = la_count, aes(x = long_center - 500, y = lat_center - 500), color = "black", size = 3, show.legend = FALSE) +
  geom_point(data = top_crimes_la_count, 
             aes(x = jittered_long , y = jittered_lat, shape = factor(Crm.Cd.Desc)), size = 3.5) +
  geom_segment(data = top_crimes_la_count, aes(x = long_center, y = lat_center, xend = jittered_long, yend = jittered_lat),
               color = "black") +
  scale_shape_manual(name = "Crime Type", values = shape_values) +
#  scale_size_continuous(name = "Crime Count per Crime Type",
#                        range = c(5, 5)) +
  scale_fill_gradient(low = "#fee8c8",
                      high = "#e34a33",
                      name = "Total Crime Count",
                      limits = c(25000, 65000),
                      breaks = c(30000, 40000, 50000, 60000),
                      labels = c("30k", "40k", "50k", "60k")) +
#  scale_colour_viridis_c(name = "Crime Count per Crime Type",
#                         option = "turbo",
#                         begin = 0.7,
#                         end = 1) +
#  labs(title = "Number of Top 5 Crimes and Total Crimes in Each Area of Los Angeles (LA)") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 25, face = "bold"),
    axis.title.x = element_blank(),  
    axis.title.y = element_blank(),  
    axis.text.x = element_blank(),   
    axis.text.y = element_blank(),   
    axis.ticks.x = element_blank(),  
    axis.ticks.y = element_blank(),  
    panel.grid.major = element_blank(),  
    panel.grid.minor = element_blank(),
    legend.title = element_text(size = 15),  
    legend.text = element_text(size = 15)
  ) +
  guides(shape = guide_legend(override.aes = list(size = 6)),  # Adjust the size of the shapes in the legend
         colour = guide_legend(override.aes = list(size = 6)))  # Adjust the size of the points in the legend

# Display the plot
top_crime_codes_by_area_map_sf
