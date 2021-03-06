\name{gstatModel-class}
\docType{class}
\alias{gstatModel-class}
\alias{validate,gstatModel-method}
\alias{plot,gstatModel,ANY-method}
\alias{validate}
\alias{print.gstatModel}
\alias{plot.gstatModel}
\title{A class for a geostatistical model}
\description{A class containing fitted parameters of a geostatistical model to be used to run predictions by regression-kriging. It comprises regression model (e.g. a GLM), variogram model, and observation locations of sampled values used to fit the model.}
\section{Slots}{
  \describe{
    \item{\code{regModel}:}{object of class \code{"ANY"}; output of fitting a generalized linear model (GLM) or any similar regression model}
    \item{\code{svgmModel}:}{object of class \code{"data.frame"}; sample variogram with semivariances and distances}
    \item{\code{vgmModel}:}{object of class \code{"data.frame"}; the fitted gstat variogram model parameters containing variogram model, nugget, sill, range and the five anisotropy parameters}
    \item{\code{sp}:}{object of class \code{"SpatialPointsDataFrame"}; observation locations}
  }
}
\section{Methods}{
  \describe{
	\item{predict}{\code{signature(obj = "gstatModel")}: makes predictions for a set of given predictionLocations (gridded maps) at block support corresponding to the \code{cellsize} slot in the object of class \code{"SpatialPixelsDataFrame"}; to produce predictions at point support, submit the \code{predictionLocations} as \code{"SpatialPointsDataFrame"} }
	\item{validate}{\code{signature(obj = "gstatModel")}: runs \emph{n}-fold cross-validation of the existing gstatModel (it re-fits the model using existing formula string and model data, then estimates the mapping error at validation locations)}
  \item{plot}{\code{signature(obj = "gstatModel", ...)}: plots goodness of fit and variogram model}
  }
}
\details{ Any model passed to the \code{regModel} slot must come with generic functions such as \code{residuals}, \code{fitted.values}, \code{summary}, \code{formula} and \code{predict}.
}
\note{ \code{"SpatialPredictions"} saves results of predictions for a single target variable, which can be of type numeric or factor. Multiple variables can be combined into a list. When using \code{nsim} argument with the \code{predict} method, the output result will be of type:\cr

 \code{plotKML::RasterBrickSimulations-class} \cr

i.e. \emph{N} number of equiprobable realizations. To generate an object of type:\cr 

\code{plotKML::SpatialPredictions-class}\cr

set \code{nsim = 0}. 
}
\author{ Tomislav Hengl and Gerard B.M. Heuvelink }
\seealso{ \code{\link{predict.gstatModel}}, \code{\link{test.gstatModel}}, \code{plotKML::SpatialPredictions-class}, \code{plotKML::RasterBrickSimulations-class}, \code{gstat::gstat}, \code{stats::glm}
}
\examples{ 
## load observations:
library(plotKML)
library(sp)
library(maptools)
demo(meuse, echo=FALSE)
data(meuse)
coordinates(meuse) <- ~x+y
proj4string(meuse) <- CRS("+init=epsg:28992")
## load grids:
data(meuse.grid)
coordinates(meuse.grid) <- ~x+y
gridded(meuse.grid) <- TRUE
proj4string(meuse.grid) <- CRS("+init=epsg:28992")
## fit a model:
omm <- fit.gstatModel(meuse, om~dist+ffreq, 
  fit.family=gaussian(link="log"), meuse.grid)
plot(omm)
## produce SpatialPredictions:
om.rk <- predict(omm, predictionLocations = meuse.grid)
plot(om.rk)
## run a proper cross-validation:
rk.cv <- validate(omm)
## RMSE:
sqrt(mean((rk.cv$validation$var1.pred-rk.cv$validation$observed)^2))
}
\keyword{classes}
