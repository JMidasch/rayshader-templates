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
options(rgl.useNULL = FALSE)
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
elevation <- raster::raster("path/to/your/dem.tif")
elmat <- raster_to_matrix(elevation)
#Resize to matrix to a size around 1 - 2 million
elmat <-resize_matrix(elmat, 0.25)

#color scheme for the model
colors <- c("#000000","#000000","#000000", "#0A210F","#0A210F","#0A210F","#0A210F", "#D4F9E9", "#699180", "#04490D","#BCFDE2")
#Creates the 3d plot of your DEM
elmat |>
  height_shade(texture = grDevices::colorRampPalette(colors)(256)) |>
  add_shadow(ambient_shade(elmat))|>
  add_shadow(ray_shade(elmat))|>
  plot_3d(heightmap = elmat, 
          windowsize = c(1650,980), 
          solid = TRUE,                  
          zscale = 40,                   
          zoom = 0.7,
          fov= 60,
          phi=55,
          theta=0,
          close_previous = TRUE
  )   
#list of sea level values, for example 20k BCE - 2k CE in 100year steps
sealevel=c(-127.000, -126.900, -126.799, -126.699, -126.598, -126.498, -126.397, -126.297, -126.196, -126.096, -125.995, -125.895, -125.795, -125.694, -125.594, -125.493, -125.393, -125.292, -125.192, -125.091, -124.982, -124.781, -124.580, -124.379, -124.178, -123.977, -123.776, -123.575, -123.374, -123.174, -122.959, -122.658, -122.356, -122.055, -121.753, -121.452, -121.151, -120.849, -120.548, -120.247, -119.945, -119.644, -119.342, -119.041, -118.740, -118.438, -118.137, -117.836, -117.534, -117.233, -116.932, -116.630, -116.329, -116.027, -115.726, -115.425, -115.123, -114.822, -114.521, -114.219, -113.890, -113.489, -113.087, -112.685, -112.283, -111.881, -111.479, -111.078, 
           -110.676, -110.274, -109.169, -106.557, -103.945, -101.333, -98.721, -96.110, -93.498, -90.886, -88.274, -85.662, -83.781, -83.178, -82.575, -81.973, -81.370, -80.767, -80.164, -79.562, -78.959, -78.356, -77.384, -75.877, -74.370, -72.863, -71.356, -69.849, -68.342, -66.836, -65.329, -63.822, -62.863, -62.562, -62.260, -61.959, -61.658, -61.356, -61.055, -60.753, -60.452, -60.151, -59.196, -57.589, -55.982, -54.374, -52.767, -51.160, -49.553, -47.945, -46.338, -44.731, -43.123, -41.516, -39.909, -38.301, -36.694, -35.087, -33.479, -31.872, -30.265, -28.658, -27.050, -25.443, -23.836, -22.228, -20.621, -19.014, -17.406, -15.799, -14.192, -12.584, -11.489, -10.685, -9.881, -9.078, -8.274, -7.470, -6.667, -5.863, -5.059, -4.256, -3.932, -3.831, -3.731, -3.630, -3.530, -3.429, -3.329, -3.228, -3.128, -3.027, -2.963, -2.913, -2.863, -2.813, -2.763, -2.712, -2.662, -2.612, -2.562, -2.511, -2.461, -2.411, -2.361, -2.311, -2.260, -2.210, -2.160, -2.110, -2.059, -2.009, -1.959, -1.909, -1.858, -1.808, -1.758, -1.708, -1.658, -1.607, -1.557, -1.507, -1.457, -1.406, -1.356, -1.306, -1.256, -1.205, -1.155, -1.105, -1.055, -1.005, -0.954, -0.904, -0.854, -0.804, -0.753, -0.703, -0.653, -0.603, -0.553, -0.502, -0.452, -0.402, -0.352, -0.301, -0.251, -0.201, -0.151, -0.100, -0.050, 0.000)#
#reversed list of sea level values to make it loopable
sealevelrev=rev(sealevel)

#Increase if you want to increase the length of the animation/slow down the rotation of the camera
#R will switch to the next sea level every n frames
n <- 2

#Creates angles for camera rotation
angles= seq(0,360,length.out = n*(length(ndvilist)+1))[-1]

#magical for-loop 
for(i in 0:length(angles)) {
  #Renders a new sea level every n loops
  if (i%%n==0){
    render_water(elmat, zscale=40, waterdepth = sealevel[i/n+1], wateralpha = 0.8, remove_water = TRUE)
    #adjust years depending on your data
    year <- 20000-i*50
    if (year<=0){
      yearstr <- paste(toString(year*(-1)), "CE")
    } else{
      yearstr <- paste(toString(year), "BCE")   
    }
  }
  #Slightly moves the camera every loop
  render_camera(theta=angles[i+1])
  #Creates a new frame every loop
  render_snapshot(filename = sprintf("path/to/output/directory/sealevel_frame_%i.png", i), title_text=paste("Approximate sea level in",yearstr), title_font="Bahnschrift", title_color="#222222", title_bar_color = "#EEEEEE", title_size=40)
}
#magical for-loop with reverse water level
for(i in 0:length(angles)) {
  #Renders a new sea level every n loops
  if (i%%2==0){
    render_water(elmat, zscale=30, waterdepth = sealevelrev[i/2], wateralpha = 0.8, remove_water = TRUE)
    #adjust years depending on your data
    year <- 2000-i*50
    if (year<=0){
      yearstr <- paste(toString(year*(-1)), "BCE")
    } else{
      yearstr <- paste(toString(year), "CE")   
    }
  }
  #Slightly moves the camera every loop
  render_camera(theta=angles[i+1])
  #Creates a new frame every loop
  render_snapshot(filename = sprintf("path/to/output/directory/sealevel_frame_%i.png", i+length(angles)), title_text=paste("Approximate sea level in",yearstr), title_font="Bahnschrift", title_color="#222222", title_bar_color = "#EEEEEE", title_size=40)
}
#Creates a video from the previously created frames
av::av_encode_video(sprintf("path/to/output/directory/sealevel_frame_%d.png",seq(0,2*length(angles),by=1)), framerate = 30,
                    output = "path/to/output/directory/sealevel_animation.mp4")


