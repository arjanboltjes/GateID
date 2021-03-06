##install all packages using install.packages() prior to running the following lines
# install.packages("geometry")
# install.packages("sp")
# install.packages("Rmalschains")
# install.packages("GA")
# install.packages("overlap")
# install.packages("flowCore")
# install.packages("scales")
# install.packages("XML")
# install.packages("plyr")
# install.packages("affy")

library("GA")
library("geometry")
library("sp")
library("Rmalschains")
library("overlap")
library("scales")
library("flowCore")
library("XML")
library("plyr")
library("affy")

pip.in <- function(polypoints = polypoints, testpoints = testpoints) {
  library(sp)
  if (dim(testpoints)[2] != 2) {stop("test data should be two dimensional")}
  if (dim(polypoints)[2] != 2) {stop("polygon data should be two dimensional")}
  
  res <- point.in.polygon(point.x = testpoints[,1], point.y = testpoints[,2], pol.x = polypoints[,1], pol.y = polypoints[,2])
  # res[res > 0] <- 1
  res[res != 1] <- 0
  res <- as.logical(res)
  return(res)
}

pip.out <- function(polypoints = polypoints, testpoints = testpoints) {
  library(sp)
  if (dim(testpoints)[2] != 2) {stop("test data should be two dimensional")}
  if (dim(polypoints)[2] != 2) {stop("polygon data should be two dimensional")}
  
  res <- point.in.polygon(point.x = testpoints[,1], point.y = testpoints[,2], pol.x = polypoints[,1], pol.y = polypoints[,2])
  res[res > 0] <- 1
  # res[res != 1] <- 0
  res <- as.logical(res)
  return(res)
}

orderCW <- function(x = points, nverts = 4) {
  x.coor <- x[1:nverts]
  y.coor <- x[(nverts+1):(nverts*2)]
  bc <- c(mean(x.coor), mean(y.coor))
  at <- matrix(0, nrow = nverts, byrow = T)
  for (i in 1:nverts) {
    at[i] <- atan2(y.coor[i] - bc[2], x.coor[i] - bc[1])
  }
  ord <- sort(at, decreasing = T, index.return = T)$ix
  x.coor <- x.coor[ord]
  y.coor <- y.coor[ord]
  return(cbind(x.coor, y.coor))
}

is.convex <- function(x, nverts = nverts) {
  pro <- matrix(0, nrow = nverts, ncol = 1)
  sol <- x
  x = sol[, 1]
  y = sol[, 2]
  for (k in 1:nverts) {
    dx1 = x[k+1]-x[k]
    dy1 = y[k+1]-y[k]
    
    if (k == nverts) {k = 0}
    dx2 = x[k+2]-x[k+1]
    dy2 = y[k+2]-y[k+1]
    if (k == 0) {k = nverts}
    pro[k, 1] <- dx1*dy2 - dy1*dx2
  }
  
  con <- FALSE
  if (sum(pro <= 0) == nverts || sum(pro >= 0) == nverts) {con <- TRUE}
  return(con)
}

li <- function(x) {
  is.neg <- sum(x < 0)
  sol <- list()
  sol <- lapply(ji, function(y) as.matrix(orderCW(x[y:(y+(nd-1))],4)))
  sol2 <- lapply(sol, function(y) as.matrix(rbind(y, y[1, ])))
  
  selfinclude <- lapply(1:length(sol), function(y) (pip.in(polypoints = sol[[y]], testpoints = d2.desired[[y]])))
  selfinclude <- sum(Reduce('+', selfinclude) == numgates) >= numpoints.thresh
  impurity <- lapply(1:length(sol), function(y) (pip.out(polypoints = sol[[y]], testpoints = d2.nondesired[[y]])))
  impurity <- sum(Reduce('+', impurity) == numgates)
  con <- sum(unlist(lapply(sol2, function(y) is.convex(y,nverts = nverts)))) == numgates
  if ( selfinclude == FALSE || is.neg > 0 || con == FALSE) { impurity <- sum(!bool.desired) }
  return(as.numeric(impurity))
}

li.ga <- function(x) {
  is.neg <- sum(x < 0)
  sol <- list()
  sol <- lapply(ji, function(y) as.matrix(orderCW(x[y:(y+(nd-1))],4)))
  sol2 <- lapply(sol, function(y) as.matrix(rbind(y, y[1, ])))
  
  selfinclude <- lapply(1:length(sol), function(y) (pip.in(polypoints = sol[[y]], testpoints = d2.desired[[y]])))
  selfinclude <- sum(Reduce('+', selfinclude) == numgates) >= numpoints.thresh
  impurity <- lapply(1:length(sol), function(y) (pip.out(polypoints = sol[[y]], testpoints = d2.nondesired[[y]])))
  impurity <- sum(Reduce('+', impurity) == numgates)
  con <- sum(unlist(lapply(sol2, function(y) is.convex(y,nverts = nverts)))) == numgates
  if ( selfinclude == FALSE || is.neg > 0 || con == FALSE) { impurity <- sum(!bool.desired) }
  return(as.numeric(-impurity))
}

my <- function (x){
  is.neg <- sum(x < 0)
  sol <- list()
  sol <- lapply(ji, function(y) as.matrix(orderCW(x[y:(y+(nd-1))],4)))
  sol2 <- lapply(sol, function(y) as.matrix(rbind(y, y[1, ])))
  
  selfinclude <- lapply(1:length(sol), function(y) (pip.in(polypoints = sol[[y]], testpoints = d2.desired[[y]])))
  selfinclude <- (sum(Reduce('+', selfinclude) == numgates))/sum(bool.desired)
  
  nacells <- lapply(1:length(sol), function(y) (pip.out(polypoints = sol[[y]], testpoints = d2.nondesired[[y]])))
  nacells <- sum(Reduce('+', nacells) == numgates)
  con <- sum(unlist(lapply(sol2, function(y) is.convex(y,nverts = nverts)))) == numgates
  if ( nacells > impurity || is.neg > 0 || con == F) {selfinclude <- 0}
  return(as.numeric(-selfinclude))
}

my.ga <- function (x){
  is.neg <- sum(x < 0)
  sol <- list()
  sol <- lapply(ji, function(y) as.matrix(orderCW(x[y:(y+(nd-1))],4)))
  sol2 <- lapply(sol, function(y) as.matrix(rbind(y, y[1, ])))
  
  selfinclude <- lapply(1:length(sol), function(y) (pip.in(polypoints = sol[[y]], testpoints = d2.desired[[y]])))
  selfinclude <- (sum(Reduce('+', selfinclude) == numgates))/sum(bool.desired)
  
  nacells <- lapply(1:length(sol), function(y) (pip.out(polypoints = sol[[y]], testpoints = d2.nondesired[[y]])))
  nacells <- sum(Reduce('+', nacells) == numgates)
  con <- sum(unlist(lapply(sol2, function(y) is.convex(y,nverts = nverts)))) == numgates
  if ( nacells > impurity || is.neg > 0 || con == F) {selfinclude <- 0}
  return(as.numeric(selfinclude))
}

asses.overlap <- function(data = data, bool = bool, plot = F) {
  # This function calculates the area of the non-overlapping region of univariate densities for each of the 
  # channels in the index data, between desired and undesired cells. This is just to understand if desired and 
  # undesired cells are separated for a certain channel
  # To use overplapTrue(){overlap} the scale must be in radian (i.e. 0 to 2pi)
  # To keep the *relative* value of a and b the same, combine a and b in the
  # same dataframe before rescaling. You'll need to load the ???scales??? library.
  # But first add a "Source" column to be able to distinguish between a and b
  # after they are combined.
 
  dims <- dim(data)[2]
  nonover <- matrix(0,  nrow = 1 , ncol = dims)
  par(mfrow = c(round(ncol(data[,-1])/4),4))
  par(pty = "s")
  
  for (i in 1:dims) {
    desired = data.frame(value = data[bool, i], source = "desired")
    undesired = data.frame(value = data[!bool, i], source = "undesired")
    all = rbind(desired, undesired)
    all$value <- rescale( all$value, to = c(0,2*pi) )
    
    # Now you can create the rescaled desired and undesired vectors
    desired <- all[all$source == "desired", 1]
    undesired <- all[all$source == "undesired", 1]
    
    lower <- min(all$value, na.rm = T)-1 
    upper <- max(all$value, na.rm = T)+1
    ddesired <- density(desired, from=lower, to=upper, adjust = 1, na.rm = T)
    dundesired <- density(undesired, from=lower, to=upper, adjust = 1, na.rm = T)
    nonover[,i] <- 1 - overlapTrue(ddesired$y,dundesired$y)
    if (plot) {
      plot(as.numeric(ddesired$y), col = "red", type = "l", ylim=c(0,max(c(ddesired$y, dundesired$y))), main = colnames(data)[i], lwd = 3, cex.axis = 1.3, cex.lab = 1.8, 
           ylab = "Density")
      lines(as.numeric(dundesired$y), lwd = "3")
    }
  }
  return(nonover)
}

dhull.ga <- function (channels = channels, dataset = data, bool.desired = bool.desired, sort.thresh = thresh, seed = seed, popsize = 100, iter = 1000) {
  
  nverts = 4
  d2.desired <- dataset[bool.desired,channels]
  d2.undesired <- dataset[!bool.desired,channels]
  numpoints.thresh <- round(dim(d2.desired)[1] * sort.thresh)
  
  xrange <- abs(quantile(d2.desired[,1], probs = c(0.02, 0.98)))
  minx <- as.numeric(min(d2.desired[,1]))
  maxx <- as.numeric(xrange[2])
  
  yrange <- abs(quantile(d2.desired[,2], probs = c(0.02, 0.98)))
  miny <- as.numeric(min(d2.desired[,2]))
  maxy <- as.numeric(yrange[2])
  
  # internal function - Lower impurity in the gate
  lower.impurity <- function(x) {
    numpoints.thresh <- round(dim(d2.desired)[1] * sort.thresh)
    is.neg <- sum(x < 0)
    sol <- orderCW(x, nverts = nverts)
    sol2 <- rbind(sol, sol[1, ])
    selfinclude <- sum(pip.in(polypoints = sol, desiredcells = d2.desired))
    impurity <- -sum(pip.out(polypoints = sol, undesiredcells = d2.undesired))
    con <- is.convex(sol2, nverts = nverts)
    if ( selfinclude < numpoints.thresh || is.neg > 0 || con==F) {impurity <- -sum(!bool.desired)}
    return(as.numeric(impurity))
  }
  
  # GA needs a gate to start with
  p1 <- c(minx, miny)
  p2 <- c(minx, maxy)
  p3 <- c(maxx, maxy)
  p4 <- c(maxx, miny)
  gas <- as.numeric(as.matrix(orderCW(rbind(p1,p2,p3,p4), nverts = nverts)))
  
  # Lower and upper bounds for GA opt
  lower = c(rep(minx, nverts), rep(miny, nverts))
  upper = c(rep(maxx, nverts), rep(maxy, nverts))
  
  # optimization, first pass, lowering impurity
  gam1 <- ga(type = "real-valued",  fitness = lower.impurity, min = lower, max = upper, popSize = popsize, 
             keepBest = T, maxiter = iter, run = 200, pmutation = 0.2, pcrossover = 0.8, 
             elitism = 0.05, maxFitness = 0, optim = T, suggestions = gas, seed = seed, 
             crossover = gareal_spCrossover, mutation = gareal_nraMutation, selection = gareal_sigmaSelection,
             optimArgs = list(pressel = 0.8, popoptim = 0.5))
  
  impurity <- abs(gam1@fitnessValue)
  sol <- orderCW(gam1@solution[1, ], nverts = nverts)
  
  # internal function - Increase desired cells within gate without compromising on purity
  maximize.in <- function (x){
    is.neg <- sum(x < 0)
    sol <- orderCW(x, nverts = nverts)
    sol2 <- rbind(sol, sol[1, ])
    selfinclude <- sum(pip.in(polypoints = sol, desiredcells = d2.desired))
    selfinclude <- selfinclude/dim(d2.desired)[1]
    nacells <- sum(pip.out(polypoints = sol, undesiredcells = d2.undesired))
    con <- is.convex(sol2, nverts = nverts)
    if ( nacells > impurity || is.neg > 0 || con==F) {selfinclude <- 0}
    return(selfinclude)
  }
  
  gam2 <- ga(type = "real-valued",  fitness = maximize.in, min = c(rep(0, nverts), rep(0, nverts)), 
             max = c(rep(max(d2.desired[,1])*1.05, nverts), rep(max(d2.desired[,2])*1.05, nverts)), 
             popSize = popsize, keepBest = F, maxiter = iter, run = 200, pmutation = 0.2, pcrossover = 0.8, 
             elitism = 0.1, suggestions = gam1@solution, maxFitness = 1, optim = T, seed = seed+1,
             crossover = gareal_spCrossover, mutation = gareal_nraMutation, selection = gareal_sigmaSelection,
             optimArgs = list(pressel = 0.8, popoptim = 0.5))
  
  # In case of more than 1 equivalent solutions in terms of objective, find one with minimum area
  areas <- apply(gam2@solution, 1, function(x) polyarea(orderCW(x, nverts = nverts)[,1], orderCW(x, nverts = nverts)[,2]))
  sol <- which(areas == min(areas))
  sol <- orderCW(gam2@solution[sol, ], nverts = nverts)
  sol <- rbind(sol, sol[1, ])
  temp.nv <- nverts + 1 # number of vertices+1
  sol <- cbind(val[[1]][1:temp.nv], val[[1]][(temp.nv+1):(temp.nv*2)])
  return(sol)
}

dhull.mals <- function (channels = channels, dataset = data, bool.desired = bool.desired, sort.thresh = thresh, seed = seed, popsize = 50, iter = 20000) {
  
  nverts = 4
  d2.desired <- dataset[bool.desired,channels]
  d2.undesired <- dataset[!bool.desired,channels]
  numpoints.thresh <- round(dim(d2.desired)[1] * sort.thresh)
  
  ##below setting the x and y coordinate of the initial gate to start optimizing on
  xrange <- abs(quantile(d2.desired[,1], probs = c(0.02, 0.98)))
  minx <- as.numeric(min(d2.desired[,1]))
  maxx <- as.numeric(xrange[2])
  
  yrange <- abs(quantile(d2.desired[,2], probs = c(0.02, 0.98)))
  miny <- as.numeric(min(d2.desired[,2]))
  maxy <- as.numeric(yrange[2])
  
  # internal function - Lower impurity in the gate
  lower.impurity2 <- function(x) {
    numpoints.thresh <- round(dim(d2.desired)[1] * sort.thresh)
    is.neg <- sum(x < 0)
    sol <- orderCW(x, nverts = nverts)
    sol2 <- rbind(sol, sol[1, ])
    selfinclude <- sum(pip.in(polypoints = sol, desiredcells = d2.desired))
    impurity <- sum(pip.out(polypoints = sol, undesiredcells = d2.undesired))
    con <- is.convex(sol2, nverts = nverts)
    if ( selfinclude < numpoints.thresh || is.neg > 0 || con==F) {impurity <- sum(!bool.desired)}
    return(as.numeric(impurity))
  }
  
  p1 <- c(minx, miny)
  p2 <- c(minx, maxy)
  p3 <- c(maxx, maxy)
  p4 <- c(maxx, miny)
  # initial gate for optmization
  gas <- as.numeric(as.matrix(orderCW(rbind(p1,p2,p3,p4), nverts = nverts)))
  
  ##give upper and lower bounds of the area the optimization go in
  lb = c(rep(minx, nverts), rep(miny, nverts))
  ub = c(rep(maxx, nverts), rep(maxy, nverts))
  ###the actual business optimization: the goal of this optimization is lower as much as possible the undesired cells while keeping the minimum yield as defined by user
  res = malschains(lower.impurity2, lower = lb, upper = ub, maxEvals = iter, seed = seed, initialpop = gas, verbosity = 0,
                   control = malschains.control(optimum = 0, istep = 100, ls = "sw", effort = 0.55, alpha = 0.5, popsize = popsize))
  impurity <- res$fitness
  sol <- orderCW(res$sol, nverts = nverts)
  # plotg.log(data = dataset, bool.desired = bool.desired, channels = channels, sol = sol)
  
  
  ###now this below will take each solution (=each gate for each combination of channel=66) and try to optimize the gate again to keep the same number of impurities but increase the yield as much as possible
  maximize.in2 <- function (x){
    is.neg <- sum(x < 0)
    sol <- orderCW(x, nverts = nverts)
    sol2 <- rbind(sol, sol[1, ])
    selfinclude <- sum(pip.in(polypoints = sol, desiredcells = d2.desired))
    selfinclude <- -selfinclude/dim(d2.desired)[1]
    nacells <- sum(pip.out(polypoints = sol, undesiredcells = d2.undesired))
    con <- is.convex(sol2, nverts = nverts)
    if ( nacells > impurity || is.neg > 0 || con==F) {selfinclude <- 0}
    return(selfinclude)
  }
  
  lb = c(rep(0, nverts), rep(0, nverts))
  ub = c(rep(max(d2.desired[,1])*1.05, nverts), rep(max(d2.desired[,2])*1.05, nverts))
  res2 = malschains(maximize.in2, lower = lb, upper = ub, maxEvals = iter, initialpop = res$sol, seed = seed, verbosity = 0,
                    control = malschains.control( istep = 300, ls = "cmaes", effort = 0.55, alpha = 0.5, popsize = popsize))
  
  sol <- orderCW(res2$sol, nverts = nverts)
  sol <- rbind(sol, sol[1, ])
  return(sol)
}

plot.gate <- function(data = data, bool.desired = bool.desired, channels = channels, gate = gate, final.undesired = final.undesired, index = i) {
  
  dims <- seq(1,ncol(final.undesired),1)
  sol = gate
  d2.desired <- data[bool.desired, channels]
  d2.undesired <- data[!bool.desired, channels]
  
  isneg <- which(sol < 0, arr.ind = T)
  sol.log <- gate
  if (dim(isneg)[1] > 0) {
    for (i in 1:nrow(isneg)) {
      sol.log[isneg[i,1], isneg[i,2]] <- -sol.log[isneg[i,1], isneg[i,2]]
    }
  }
  sol.log <- data.frame(sol.log)
  colnames(sol.log) <- colnames(d2.desired)
  
  desired <- d2.desired
  undesired <- d2.undesired
  
  minx <- min(desired[,1], undesired[,1], sol.log[,1])
  if (minx < 0) {minx <- 0.0001}
  maxx <- max(desired[,1], undesired[,1], sol.log[,1])
  miny <- min(desired[,2], undesired[,2], sol.log[,2])
  if (miny < 0) {miny <- 0.0001}
  maxy <- max(desired[,2], undesired[,2], sol.log[,2])
  
  xname <- colnames(data)[channels[1]]
  yname <- colnames(data)[channels[2]]
  
  x <- desired
  x$type <- "Desired"
  y <- undesired
  y$type <- "Undesired"
  
  if (length(dims)-1 == 1) {
    highlight <- final.undesired[, which(index != dims)] == 1
  }  else {
    highlight <- apply(final.undesired[, which(index != dims)], 1, function(x) sum(x)) == length(dims)-1
  }
  if (sum(highlight) > 0) {y[highlight, ]$type <- "Undesired & in all other gates"}
  
  par(pty="s")
  plot(rbind(d2.desired, d2.undesired), cex.lab = 1.5, cex.axis = 1.3, xlim=c(minx, maxx), ylim = c(miny, maxy))
  points(d2.undesired, pch=19, col="grey")
  points(d2.desired, pch=19, col="red")
  points(d2.undesired[highlight,], pch=19, col="darkblue")
  points(sol.log, type = "l", lwd = 3.5)
}

combine.gates <- function (k = 2, desired.sorted = desired.sorted, undesired.sorted = undesired.sorted, bool.desired = bool.desired) {
  
  numdim = k
  # all gate combinations in AND, that is 
  dim2 <- (t(combn(1:dim(desired.sorted)[2], numdim)))
  
  # 1st column = Fraction of desired cells; 2nd column = Fraction of undesired cells; 3rd column = Purity
  perc <- matrix(0, dim(dim2)[1], 3)
  t.d <- sum(bool.desired)
  for (i in 1:dim(dim2)[1]) {
    n.d <- sum(rowSums(desired.sorted[,dim2[i,]])==numdim)
    un.d <- sum(rowSums(undesired.sorted[,dim2[i,]])==numdim)
    purity <- n.d/(n.d + un.d)
    perc[i,] <- c(n.d/t.d, un.d, purity)
  }
  
  x <- perc[,1]
  y <- perc[,3]
  d = data.frame(x,y)
  par(pty = "s")
  D = d[order(d$y,d$x,decreasing=TRUE),]
  pareto.front = D[which(!duplicated(cummax(D$x))),]
  plot(x,y, cex=0.7, main = paste("combination of",numdim,"gates - Pareto front"),
       xlab = "Yield", ylab = "Purity", pch=20, cex.axis = 1.4, cex.lab = 1.7)
  points(pareto.front, pch=19, col = "red") # Pareto front
  lines(pareto.front, pch=19, col = "red", lwd = 3)
  
  # Combinations of gates in the same order of the pareto front. If a certain yield/purity ratio is given my 
  gate.combs <- matrix(0, nrow = 1, ncol = numdim+2)
  p = as.matrix(pareto.front)
  for (i in 1:dim(pareto.front)[1]) {
    
    temp = (dim2[which(perc[,1] == pareto.front[i,1] & pareto.front[i, 2] == perc[,3]), ])
    if (is.null(nrow(temp))) {
      temp <- c(as.integer(t(as.matrix(temp))), as.matrix(pareto.front[i,]))
    } else {
      t2 = matrix(0, nrow = nrow(temp), ncol = numdim+2)
      for (j in 1:nrow(temp)) {
        t2[j,] = c(temp[j,], (p[i,]))
      }
      temp = t2
    }
    gate.combs <- rbind(gate.combs, temp)
  }
  gate.combs <- gate.combs[-1, ]
  rownames(gate.combs) <- seq(1, nrow(gate.combs), 1)
  
  return((gate.combs))
  
}

print.stats <- function(final.undesired, final.desired, combs.final, bool.desired) {
  
  print(c("Number of nondesired cells",sum(rowSums(final.undesired)== dim(combs.final)[1])))
  print(c("Number of desired cells",sum(rowSums(final.desired)== dim(combs.final)[1])))
  print(c("Purity in %",sum(rowSums(final.desired)== dim(combs.final)[1])/ (sum(rowSums(final.desired)== dim(combs.final)[1]) + sum(rowSums(final.undesired)== dim(combs.final)[1]))))
  print(c("% of desired cells",(sum(rowSums(final.desired)== dim(combs.final)[1])/sum(bool.desired))*100))
  
}

pip.in2 <- function(polypoints = polypoints, desiredcells = desiredcells) {
  # polypoints = polygon or gate
  if (dim(desiredcells)[2] != 2) {stop("test data should be two dimensional")}
  if (dim(polypoints)[2] != 2) {stop("polygon data should be two dimensional")}
  
  res <- point.in.polygon(point.x = desiredcells[,1], point.y = desiredcells[,2], pol.x = polypoints[,1], pol.y = polypoints[,2])
  # res[res > 0] <- 1
  res[res != 1] <- 0
  res <- as.logical(res)
  return(res)
}

pip.out2 <- function(polypoints = polypoints, undesiredcells = desiredcells) {
  # polypoints = polygon or gate
  
  if (dim(undesiredcells)[2] != 2) {stop("test data should be two dimensional")}
  if (dim(polypoints)[2] != 2) {stop("polygon data should be two dimensional")}
  
  res <- point.in.polygon(point.x = undesiredcells[,1], point.y = undesiredcells[,2], pol.x = polypoints[,1], pol.y = polypoints[,2])
  res[res > 0] <- 1
  # res[res != 1] <- 0
  res <- as.logical(res)
  return(res)
}

cal.gate.efficacy <- function(trainingdata = data, bool.desired = bool.desired, gates = gates, dims = dims, plot = F, verbose = T) {
  
  
  if (length(gates) == 1) {
    dims = t(as.matrix(dims))
    
    yield = sum(pip.in2(polypoints = gates[[1]], desiredcells = trainingdata[bool.desired, dims]))
    yield.p = sum(pip.in2(polypoints = gates[[1]], desiredcells = trainingdata[bool.desired, dims]))/sum(bool.desired)
    impurity = sum(pip.out2(polypoints = gates[[1]], undesiredcells = trainingdata[!bool.desired, dims]))
    valid.nsc = (pip.out2(polypoints = gates[[1]], undesiredcells = trainingdata[!bool.desired, dims]))
    
    if (verbose & plot) {
      print(c("Number of non-desired cells", impurity))
      print(c("Number of desired cells", yield))
      print(c("% of desired cells",(yield/sum(bool.desired))*100))
      print(c("Purity",(yield/(yield + impurity))*100))
      
      par(pty="s")
      plot(trainingdata[, dims], cex.lab = 1.5, cex.axis = 1.3)
      points(trainingdata[!bool.desired, dims], pch=19, col="grey")
      points(trainingdata[bool.desired, dims], pch=19, col="red")
      tp = trainingdata[!bool.desired, dims]
      points(tp[valid.nsc,], pch=19, col="darkblue")
      points(gates[[1]], type = "l", lwd = 3.5)
    }
    else {
      return(c(yield.p, (yield/(impurity + yield))))
    }
    
  }
  else {
    
    valid.sc <- matrix(0, nrow = sum(bool.desired), ncol = nrow(dims))
    valid.nsc <- matrix(0, nrow = sum(!bool.desired), ncol = nrow(dims))
    
    for (i in 1:length(gates)) {
      valid.sc[, i] <- pip.in2(polypoints = gates[[i]], desiredcells = trainingdata[bool.desired, dims[i,]]) 
      valid.nsc[, i] <- pip.out2(polypoints = gates[[i]], undesiredcells = trainingdata[!bool.desired, dims[i,]])
    }  
    
    impurity = sum(rowSums(valid.nsc)== length(gates))
    yield = sum(rowSums(valid.sc)== length(gates))
    yield.p = sum(rowSums(valid.sc)== length(gates))/sum(bool.desired)
    
    if (verbose & plot) {
      print(c("Number of non-desired cells",sum(rowSums(valid.nsc)== length(gates))))
      print(c("Number of desired cells",(sum(rowSums(valid.sc)== length(gates)))))
      print(c("% of desired cells",(sum(rowSums(valid.sc)== length(gates))/sum(bool.desired))*100))
      print(c("Purity",(yield/(yield + impurity))*100))
      if (plot){
        par(mfrow = c(2,2))
        par(pty = "s")
        for (i in 1:length(gates)) {
          plot.gate(data = trainingdata, bool.desired =  bool.desired, channels = dims[i,], gate = gates[[i]], final.undesired = valid.nsc, index = i)
        }
      }
    }
    else {
      return(c(yield.p, (yield/(impurity + yield))))
    }
    
  }
}
