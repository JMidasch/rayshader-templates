#Package, that allows for directly installing packages from github
install.packages("devtools")
#The most important packages for this project:
devtools::install_github("tylermorganwall/rayshader")
devtools::install_github("tylermorganwall/rayrender")
#An optional package for importing some preset color palettes
devtools::install_github("BlakeRMills/MetBrewer")
#Installing other necessary packages:
install.packages("rgl")
install.packages("glue")
install.packages("ambient")
install.packages("sf")
install.packages("av")
install.packages("gifski")
install.packages("MetBrewer")
#Activating the installed packages
library(rayrender)
library(sp)
library(av)
library(raster)
library(scales)
library(magick)
library(MetBrewer)
library(sf)
library(rayshader)
library(glue)
library(ambient)
library(gifski)
#---------------------Here the actual project starts--------------------------------------------
#You can get global and frequent NDVI data from https://appeears.earthdatacloud.nasa.gov/

#Creates a list of paths for all files in the given directory
#The directory should only contain all your NDVI TIFFs
ndvilist <- list.files(path = "path/to/ndvi/directory", full.names = TRUE)

#Color scheme for the model
colors <- c("#960000", "#E1FF19", "#0A7800")

#Increase if you want to increase the length of the animation/slow down the rotation of the camera
#R will switch to the next NDVI data set every n frames
n <- 2

#Creates angles for camera rotation
angles= seq(0,360,length.out = n*(length(ndvilist)+1))[-1]

#Magical for-loop 
for(i in 0:length(angles)) {
  #Creates a new 3D Plot every n loops
  if(i%%n==0){
    m <- (i/n)+1
    #Get data set
    NDVI <- raster::raster(ndvilist[m])
    NDVImat <- raster_to_matrix(NDVI)
    #Resize matrix to a size around 1 million if it is too big
    #elmat <-resize_matrix(elmat, 0.2)
    NDVImat |>
      #apply colors to data set
      height_shade(texture = grDevices::colorRampPalette(colors)(256), range=NULL, keep_user_par = TRUE) |>
      #apply shadows to model
      add_shadow(ambient_shade(NDVImat))|>
      add_shadow(ray_shade(NDVImat))|>
      #create the model
      plot_3d(heightmap = NDVImat, 
              windowsize = c(980,980), 
              solid = TRUE,                  
              zscale = 60,                   #height exaggeration, might need adjusting depending on the data set
              baseshape = "rectangle",
              zoom = 0.7,
              fov= 60,
              phi=50,
              theta=0,
              close_previous = TRUE
              ) 
    #NEEDS ADJUSTING based on path length and or may not work at all depending on file naming
    year <-substr(ndvilist[m],92,95)
    doy <-as.numeric(as.character(substr(ndvilist[m],96,98)))
    date <- toString(as.Date(doy, origin = paste(year,"01","01", sep="-")))
    print(date)
  }
  #Slightly moves the camera every loop
  render_camera(theta=angles[i+1])
  #Creates a new frame every loop
  render_snapshot(filename = sprintf("path/to/output/directory/ndvi_frame_%i.png", i), title_text=date, title_font="Bahnschrift", title_color="#222222", title_bar_color = "#EEEEEE", title_size=40)
}

#Creates a video from the previously created frames
av::av_encode_video(sprintf("path/to/output/directory/ndvi_frame_%d.png",seq(length(angles),by=1)), framerate = 30,
                    output = "path/to/output/directory/ndvi_animation.mp4")

