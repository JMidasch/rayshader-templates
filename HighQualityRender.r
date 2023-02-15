#Based on the following tutorial:
#https://spencerschien.info/post/data_viz_how_to/high_quality_rayshader_visuals/

#Suggested Data Sources:
#You can get Elevation Data with the Open Topography DEM Downloader Plugin in QGIS
#You can get the borders of countries, national parks, counties etc. via the Quick OSM Plugin in QGIS
#and use them to cut down the Elevation Data to your area of interest with the Raster Tools


#It is recommended to not execute the entire code at once
#but instead in blocks as defined by the ------comments--------

#---------------------You should only need to execute this part once----------------------

#You sometimes have to use a github token to install from github, so just in case:
#usethis::create_github_token()
#usethis::edit_r_environ()

#Package, that allows for directly installing packages from github
install.packages("devtools")
devtools::install_github("tylermorganwall/rayshader")
devtools::install_github("tylermorganwall/rayrender")
install.packages("MetBrewer")
install.packages("rgl")
install.packages("glue")
install.packages("sp")
install.packages("sf")
install.packages("magick")
install.packages("raster")
install.packages("ambient")
#---------------------This needs to be executed everytime you open the project----------------------
#Activating the installed packages
library(rayrender)
library(sp)
library(raster)
library(scales)
library(magick)
library(MetBrewer)
library(sf)
library(rayshader)
library(glue)
library(ambient)
#---------------------Here the actual project starts--------------------------------------------
#Load in the original DEM and turn it into a matrix
elevation <- raster::raster("path/to/example_dem.tif")
elmat <- raster_to_matrix(elevation)

#Resize matrix to a size around 1 - 2 million. If the matrix is too big render_highquality may not work
elmat <-resize_matrix(elmat, 0.5)

# Pick color palette from Met Brewer (https://raw.githubusercontent.com/BlakeRMills/MetBrewer/main/PaletteImages/Examples/AllPalettes.png)
pal <- "Navajo"
colors <- met.brewer(pal)

# You could also create your own, it's just a list of hex rgb values. But choosing a preset is way easier...
# Template for a custom color scheme:
#colors <- c("#660d20", "#e56a32", "#ffce69", "#29373E", "#e1d5aa")

#--------------------This creates a 3d plot of your DEM as a low quality preview------------------

#Close windows of previous plot_3d manually or using the following command
#rgl::rgl.close()

#The current camera angle of this plot is the camera angle used for the rendering
elmat |>
  height_shade(texture = grDevices::colorRampPalette(colors)(256)) |>
  #Here you could add add_shadow() functions, but they aren't needed. We get enough shadows in the rendering already
  #If you want to map some bodies of water
  #add_water(detect_water(elmat,zscale = 7, min_area = 200), color="#003366") |>
  plot_3d(heightmap = elmat, 
          windowsize = c(1280,720), 
          solid = FALSE,                #creates a solid grey base for the model if TRUE
          zscale = 4,                   #lower values -> more exaggerated topography (dependent on matrix size)
          #baseshape = "hex"            
          )                     

#More parameters for shadows, water, background etc etc can be found in the documentation:
#https://www.rayshader.com/reference/plot_3d.html

#--------------------Creates a high quality image based on the previously chosen camera angle-------------------------
#render_water(elmat, zscale=20, wateralpha=0)
#render_clouds(elmat, zscale = 20, start_altitude = 2500, end_altitude = 2800, fractal_levels = 32, clear_clouds = T)
#render_scalebar(limits=c(0, 25, 50, 100, 250),label_unit = "km",position = "E", y=150,
#                color_first = colors[length(colors)], color_second = colors[1])
#This requires the 3D Plot to still be open
render_highquality(
  #Double-check you set a valid output path, otherwise it will render for ~1h and not return any results
  "path/to/export/example1.png", 
  parallel = TRUE, 
  samples = 300,
  light = FALSE, 
  interactive = FALSE,
  #We turn the lights off, because we want to use environmental lighting via a HDR file instead
  #Free ones can be found all over the internet, for example:
  #https://polyhaven.com/a/phalzer_forest_01
  environment_light = "path/to/phalzer_forest_01_4k.hdr",
  intensity_env = 1.5,
  rotate_env = 90, 
  #You can ofc choose any resolution you like, the following results in 4k images
  width = 3840,
  height = 2160)

#More parameters for lighting etc can be found in the documentation:
#https://www.rayshader.com/reference/render_highquality.html

#---------------Execute the code below with different parameters (mostly location) until it looks nice-------
#Note that this part can also be done in any image editing software

# Read in image, save to `img` object
img <- image_read("path/to/export/example1.png")

# I recommend using colors from the previously chosen colorscheme for the text

# Title
img_ <- image_annotate(img, "National Park", font = "Bahnschrift",
                       color = text_color, size = 125, gravity = "north",
                       location = "+1000+750")
# Subtitle
img_ <- image_annotate(img_, "Placeholder", weight = 700, 
                       font = "Bahnschrift", location = "+1000+500",
                       color = text_color, size = 200, gravity = "north")
# Area
img_ <- image_annotate(img_, glue("Area: xyz sq km"),
                       font = "Bahnschrift", location = "+300+450",
                       color = text_color, size = 100, gravity = "west")

# Elevation range
img_ <- image_annotate(img_, glue("Elevation Range: xyz m"),
                       font = "Bahnschrift", location = "+300+250",
                       color = text_color, size = 100, gravity = "west")

# Credit where credit is due
img_ <- image_annotate(img_, glue("Graphics by <name> on <date>, Data by NASA and OSM"),
                       font = "Bahnschrift", location = "+1300+100",
                       color = alpha(colors[1], 0.75), size = 50, gravity = "south")
img_ <- image_annotate(img_, glue("Created for xyz"),
                       font = "Bahnschrift", location = "+1350+200",
                       color = alpha(colors[1], 0.75), size = 50, gravity = "south")

# Export with annotations (Make sure to choose a new file name so you don't overwrite your original render)
image_write(img_, glue("path/to/export/example2.png"))

#Slightly adjusting composition, lighting, contrast and colors in a image editing software improves the results by a lot
