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
install.packages("plot.matrix")
#---------------------This needs to be executed everytime you open the project----------------------
#Activating the installed packages
library(plot.matrix)
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
#Load in the original DEM and turn it into a matrix
elevation <- raster::raster("path/to/dem.tif")
elmat <- raster_to_matrix(elevation)
#Resize matrix to a size around 1 - 2 million
elmat <-resize_matrix(elmat, 0.2)

#Creates a list of paths for all files in the given directory
#The directory should only contain all the TIFFs of a given color
redList <- list.files(path = "path/to/directory/red", full.names = TRUE)
greenList <- list.files(path = "path/to/directory/green", full.names = TRUE)
blueList <- list.files(path = "path/to/directory/blue", full.names = TRUE)

#Increase if you want to increase the length of the animation/slow down the rotation of the camera
#R will switch to the next data set every n frames
n <- 8

#Creates angles for camera rotation
angles= seq(0,360,length.out = n*(length(redlist)+1))[-1]

#Magical for-loop 
for(i in 0:length(angles)) {
  #Creates a new 3D Plot every n loops
  if (i%%n==0){
    m=(i/n)+1
    #get raster bands as raster
    raster_red <- raster::raster(redList[m])
    raster_blue <- raster::raster(blueList[m])
    raster_green <- raster::raster(greenList[m])
    #convert raster to matrix
    matrix_red <- rayshader::raster_to_matrix(raster_red)
    matrix_green <- rayshader::raster_to_matrix(raster_green)
    matrix_blue <-rayshader::raster_to_matrix(raster_blue)
    #combine matrices to array
    array_rgb <- array(0, dim=c(nrow(matrix_red), ncol(matrix_red),3))
    array_rgb[,,1] = matrix_red/255
    array_rgb[,,2] = matrix_green/255
    array_rgb[,,3] = matrix_blue/255
    #rearrange the array for R reasons
    array_rgb <- aperm(array_rgb, c(2, 1, 3))
    #increase contrast of the imagery
    array_rgb_contrast <- scales::rescale(array_rgb, to=c(0,1))
    #create the model
    plot_3d(array_rgb_contrast, 
            elmat, 
            windowsize = c(980,980), 
            zscale = 15, 
            shadowdepth = 50,
            zoom=0.5, 
            phi=45,
            theta=-45,
            fov=60,
            close_previous = TRUE
            )
  }
  #Slightly moves the camera every loop
  render_camera(theta=angles[i+1])
  #Creates a new frame every loop
  render_snapshot(filename = sprintf("path/to/output/directory/RGB_frame_%i.png", i))
}

#Creates a video from the previously created frames
av::av_encode_video(sprintf("path/to/output/directory/RGB_frame_%d.png",seq(0,871,by=1)), framerate = 30,
                    output = "path/to/output/directory/RGB_animation.mp4")

