\name{SoilGrids-class}
\docType{class}
\encoding{latin1}
\alias{SoilGrids-class}
\alias{SoilGrids}
\title{A class for SoilGrids --- soil property and/or class maps}
\description{A class containing predictions and prediction error (or multiple realizations) of some of the target global soil property at six standard depths. Standard depths used are based on the \href{http://globalsoilmap.net/specifications}{GlobalSoilMap.net specifications}: \code{sd1} = 2.5 cm (0--5), \code{sd2} = 10 cm (5--15), \code{sd3} = 22.5 cm (15--30), \code{sd4} = 45 cm (30--60), \code{sd5} = 80 cm (60--100), \code{sd6} = 150 cm (100--200).}
\section{Slots}{
  \describe{    
    \item{\code{varname}:}{object of class \code{"character"}; abbreviated variable name registered in the Global Soil Data registry}
    \item{\code{TimeSpan}:}{object of class \code{"list"}; contains begin and end of the sampling period of class \code{"POSIXct"}}
    \item{\code{sd1}:}{object of class \code{"SpatialPixelsDataFrame"}; predictions and variances, or number of realizations of the target variable at depth 2.5 cm (0--5)}
    \item{\code{sd2}:}{object of class \code{"SpatialPixelsDataFrame"}; predictions and variances, or number of realizations of the target variable at depth 10 cm (5--15)}
    \item{\code{sd3}:}{object of class \code{"SpatialPixelsDataFrame"}; predictions and variances, or number of realizations of the target variable at depth 22.5 cm (15--30)}
    \item{\code{sd4}:}{object of class \code{"SpatialPixelsDataFrame"}; predictions and variances, or number of realizations of the target variable at depth 45 cm (30--60)}
    \item{\code{sd5}:}{object of class \code{"SpatialPixelsDataFrame"}; predictions and variances, or number of realizations of the target variable at depth 80 cm (60--100)}
    \item{\code{sd6}:}{object of class \code{"SpatialPixelsDataFrame"}; predictions and variances, or number of realizations of the target variable at depth 150 cm (100--200)}
}
Gridded data submitted to \code{sd*} slots of the \code{"SoilGrids"} class must satisfy all of the following requirements (class validity):
  \itemize{
   \item All grids submitted must have the same grid topology (identical \code{grid} slot in the object of class \code{"SpatialPixelsDataFrame"});
   \item All grids must be projected in the referent coordinate system \href{http://spatialreference.org/ref/epsg/4326/}{WGS84} (geographical coordinates), with 3D dimension (altitude) expressed as distance from the land surface in meters (e.g. altitude of \code{-.025} corresponds to the 2.5 cm depth);
   \item The grid cell size must correspond to some standard resolution e.g. 0.0008333333 (1/1200 or about 100 m), 0.0016666667 (1/600 or about 250 m) or similar;
   \item Only standard abbreviated names registered in the Global Soil Data registry can be used in the \code{varname} slot; 
  } 
}
\section{Methods}{
  \describe{
	\item{summary}{\code{signature(x = "SoilGrids")}: generates summary statistics for the object}
  }
}
\references{
\itemize{
  \item SoilGrids --- a system for automated soil mapping (\url{https://soilgrids.org})
}
}
\author{ Tomislav Hengl and Robert A. MacMillan }
\seealso{ \code{\link{GlobalSoilMap-class}}, \code{\link{SpatialComponents-class}}, \code{\link{geosamples-class}} 
}
\examples{
# load soil samples from the plotKML package: 
library(plotKML)
library(aqp)
library(plyr)
library(splines)
library(rgdal)
library(raster)

data(eberg)
## subset data to 10%:
eberg <- eberg[runif(nrow(eberg)) < .1,]
## sites table:
s.lst <- c("ID", "soiltype", "TAXGRSC", "X", "Y")
h.lst <- c("UHDICM","LHDICM","SNDMHT","SLTMHT","CLYMHT")
sites <- eberg[,s.lst]
## get horizons table:
horizons <- getHorizons(eberg, idcol="ID", sel=h.lst)
## create object of type "SoilProfileCollection"
eberg.spc <- join(horizons, sites, type='inner')
depths(eberg.spc) <- ID ~ UHDICM + LHDICM
site(eberg.spc) <- as.formula(paste("~", paste(s.lst[-1], collapse="+"), sep=""))
coordinates(eberg.spc) <- ~X+Y
proj4string(eberg.spc) <- CRS("+init=epsg:31467")
## convert to logits:
eberg.spc@horizons$SNDMHT.t <- log((eberg.spc@horizons$SNDMHT/100)/
    (1-eberg.spc@horizons$SNDMHT/100))
## convert to geosamples:
eberg.geo <- as.geosamples(eberg.spc)
## load gridded data:
data(eberg_grid)
gridded(eberg_grid) <- ~x+y
proj4string(eberg_grid) <- CRS("+init=epsg:31467")
## derive spc's:
formulaString <- ~ PRMGEO6+DEMSRT6+TWISRT6+TIRAST6
eberg_spc <- spc(eberg_grid, formulaString)
## build a 3D "gstatModel": 
glm.formulaString = as.formula(paste("SNDMHT.t ~ ", 
     paste(names(eberg_spc@predicted), collapse="+"), "+ ns(altitude, df=4)"))
\dontrun{
SNDMHT.m <- fit.gstatModel(observations=eberg.geo, glm.formulaString, 
     covariates=eberg_spc@predicted)
summary(SNDMHT.m@regModel)
SNDMHT.m@vgmModel
## prepare new locations (6 standard depths): 
new3D <- sp3D(eberg_spc@predicted)
## Make predictions at six depths:
sd.l <- lapply(new3D, FUN=function(x){predict(SNDMHT.m, predictionLocations=x, nfold=0)})
## back-transformation function:
invlogit = function(x){exp(x)/(1+exp(x))*100}
## for the back-transformation for the mean value see Diggle and Ribeiro, 2007, p. 148:
invlogit.m = function(x, v){((1+exp(-x))^(-1)-.5*v*exp(-x)*(1-exp(-x))*(1+exp(-x))^(-3) )*100}
## back-transform values from logits:
for(j in 1:length(sd.l)){ 
    sd.l[[j]]@predicted$M <- round(invlogit.m(sd.l[[j]]@predicted$SNDMHT.t,
       sd.l[[j]]@predicted$var1.var))
    sd.l[[j]]@predicted$L <- round(invlogit(sd.l[[j]]@predicted$SNDMHT.t
     - 1.645*sqrt(sd.l[[j]]@predicted$var1.var)))
    sd.l[[j]]@predicted$U <- round(invlogit(sd.l[[j]]@predicted$SNDMHT.t
     + 1.645*sqrt(sd.l[[j]]@predicted$var1.var))) 
}
str(sd.l[[1]]@predicted@data)

## reproject to WGS84 system (100 m resolution):
p = get("cellsize", envir = GSIF.opts)[1]
s = get("stdepths", envir = GSIF.opts)
sd.ll <- sapply(1:length(sd.l), FUN=function(x){ 
     make.3Dgrid(sd.l[[x]]@predicted[c("L","M","U")],
     pixsize=p, stdepths=s[x])})
## save to a "SoilGrids" object:
SNDMHT.gsm <- SoilGrids(obj=sd.ll, varname="SNDPPT", 
             TimeSpan=list(begin="1999-02-01", end="2001-07-01"))
str(SNDMHT.gsm, max.level=2)
## visualize all maps in Google Earth:
data(R_pal)
z0 = mean(eberg_grid$DEMSRT6, na.rm=TRUE)
## export grids:
for(j in 1:length(sd.ll)){
  kml(slot(SNDMHT.gsm, paste("sd", j, sep="")), 
     folder.name = paste("eberg_sd", j, sep=""),
     file = paste("SNDMHT_sd", j, ".kml", sep=""), 
     colour = M, z.lim=c(10,85),
     raster_name = paste("SNDMHT_sd", j, ".png", sep=""), 
     altitude = z0+5000+(s[j]*2500))
}
}
}
\keyword{classes}