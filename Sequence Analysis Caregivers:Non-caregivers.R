#### History of SA in Social Sciences ####
# although sequence analysis has been used for a long time, it only took off
# in social science
# since the development of TraMineR package in R (thanks to Geneva team)
# although the name of the package is commonly pronounced as truh-mai-ner
# it is likely that originally it should be truh-mee-ner
# because it's a type of grape

# IMPORTANT
# sequence analysis is largely a descriptive technique


#### Loading Necessary Packages ####
if (!require("pacman")) install.packages("pacman")
library(pacman)

# load and install packages
pacman::p_load(TraMineR, TraMineRextras, cluster, RColorBrewer, devtools, haven, 
               tidyverse, reshape2, WeightedCluster, nnet)

## load dta dataset
## remember that in r, it's forward slashes
## unlike read.dta read_dta reads all versions of stata
data<-read_csv("diary.csv")

## create id if id is not present in the dataset
data$id <- as.numeric(data$X1)

## specify the names for the activity variables
activities<-c()
for(i in 0:1439) {
  activities<-c(activities, paste("var", i, sep = ""))
}

activities



#### Sequence Analysis #####

# I create an object with intervals' labels. Sequences start at 04:00 AM:
# depending on your own sequence intervals these labels need to be adjusted
t_intervals_labels <-  format( seq.POSIXt(as.POSIXct("2021-11-08 04:00:00 GMT"), as.POSIXct("2021-11-09 03:59:00 GMT"), by = "1 min"),
                               "%H:%M", tz="GMT")

#### colour palette ####

## let's brew some colours first
## number of colours is the number of states (in the alphabet)
## interesting resource on colors (cheatsheet): 
## https://www.nceas.ucsb.edu/sites/default/files/2020-04/colorPaletteCheatsheet.pdf
colourCount = 13
getPalette = colorRampPalette(brewer.pal(9, "Set3"))

## to check the created pallette: 
## define labels first and count:
labels = c("sleep", "housework", 
           "childcare", "adult care",
           "paidwork", "shopping", "leisure", 
           "travel")
colourCount = length(labels)
getPalette = colorRampPalette(brewer.pal(8, "Set3"))

## let's see how our colours look like
axisLimit <- sqrt(colourCount)+1
colours=data.frame(x1=rep(seq(1, axisLimit, 1), length.out=colourCount), 
                   x2=rep(seq(2, axisLimit+1, 1), length.out=colourCount), 
                   y1=rep(1:axisLimit, each=axisLimit,length.out=colourCount), 
                   y2=rep(2:(axisLimit+1), each=axisLimit,length.out=colourCount), 
                   t=letters[1:colourCount], r=labels)


ggplot() + 
  scale_x_continuous(name="x") + 
  scale_y_continuous(name="y") +
  geom_rect(data=colours, mapping=aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2, fill=t), color="black", alpha=0.5) +
  geom_text(data=colours, aes(x=x1+(x2-x1)/2, y=y1+(y2-y1)/2, label=r), size=4) + 
  scale_fill_manual(values = getPalette(colourCount)) + theme(legend.position = "none")



#### define the sequence object ####
# 
# subset the data if you need to
# data <- data[which(data$v19==1),]
MyData <- as_tibble(data)


## you want to use the full categories of states:
## (you need to change if you only focus on specific activities)
gentime_seq <- seqdef(MyData,
                        var = activities,
                        cnames = t_intervals_labels,
                        alphabet = c("1", "3", "4", "5",
                                     "6", "7", "10",
                                     "11"), 
                        labels = labels,
                        cpal = getPalette(colourCount),
                        xtstep = 18, ##step between displayed tick-marks and labels on the time x-axis
                        id = MyData$id)
## if you have weights then add ===>  weights = MyData$Weight)

## check how the sequence looks like
print(gentime_seq[1:5, ], format = "STS")
## "STS" format shows each step

#### PLOTTING SEQUENCES ####

#### sequence index plots ####
## tlim used to show the sequences to plot
## now they use idxs 
## the default is 1:10 plotting the first 10 sequences
## if you set it to 0, it plots all
seqiplot(gentime_seq, border = NA, with.legend = "right", legend.prop=0.4)

##also to plot all you can use seqIplot
seqIplot(gentime_seq, border = NA, with.legend = "right", legend.prop=0.4, idxs = 1:4)
## seqIplot(gentime_seq, border = NA, with.legend = "right", legend.prop=0.4)
## the difference is that capital I has idxs=0 as default -- do not run the commented line right now, it will take forever

## MOST FREQUENT SEQUENCES --usually useless for time-use sequences with many steps
## tabulate 4 frequent sequences:
## because there are 96 steps there are barely any
## this is more useful for shorter sequences with many commonalities (as in life-course research)
seqtab(gentime_seq, idxs = 1:4)

## Plot of the 10 most frequent sequences
#seqplot(gentime_seq, type="f", with.legend = "right", legend.prop=0.4)

##also can plot frequencies using seqfplot
seqfplot(gentime_seq, border = NA, with.legend = "right", legend.prop=0.4)
##again, frequencies is not very useful for TU seqs
##because very few of them repeat themselves with 96 steps

## state distribution plots (aka tempogram aka chronogram)
## this is an easy way to plot a tempogram 
seqdplot(gentime_seq, border = NA, with.legend = "right", legend.prop=0.4)

#### Transitions ####

## transitions from state to state (in probabilities)
trate <- seqtrate(gentime_seq)
round(trate, 2)

## heatmap of the transitions matrix
heatTrate=melt(trate)
head(heatTrate)

ggplot(heatTrate, aes(Var2, Var1)) +
  geom_tile(aes(fill = value)) +
  geom_text(aes(label = round(value, 2))) +
  scale_fill_continuous(high = "#132B43", low = "#56B1F7", name="Transitions")


#### changing granularity (number of steps in a sequence) ####
## changing the number of steps
## to the first method = "first", to the last = "last", or most frequent = "mostfreq"
## 15 means every 15 min
gentime15_seq <- seqgranularity(gentime_seq,
                                  tspan=15, method="mostfreq")

seqdplot(gentime15_seq, border = NA, with.legend = "right", legend.prop=0.4)

#### Modal states sequence ####

#seqplot(gentime_seq, type="ms", with.legend = "right", legend.prop=0.4)
## same as
seqmsplot(gentime15_seq, with.legend = "right", legend.prop=0.4, main="Modal Sequences")

#transversal enthropy of state distributions
#the number of valid states and the Shannon entropy of the transversal state
#distribution.
seqHtplot(gentime15_seq, with.legend = "right", legend.prop=0.4)



#### calculating dissimilarities #####

# seqdist() = for pairwise dissimilarities
# seqsubm() = to compute own substitution matrix
#"TRATE", the costs are determined from the estimated transition rates
scost <- seqsubm(gentime15_seq, method = "TRATE")
round(scost, 3)
## calculated in this way, all are close to 2 anyway (for this dataset) 2 is default
## or we can use the usual default one of constant 2:
ccost <- seqsubm(gentime15_seq, method="CONSTANT", cval=2)
round(ccost, 3)

##optimal matching include both substitutions and indels
##The cost minimization is achieved through dynamic programming, the algorithm
##implemented in TraMineR being essentially that of Needleman and Wunsch (1970)
##For the illustration how the algorithm works go to:
## https://blogs.ubc.ca/kamilakolpashnikova/optimal-matching-algorithm-interactive-app-for-social-scientists/

## if heavy, calculate only the upper part of the matrix by full.matrix = FALSE
## remember that With a
##constant substitution cost of 2 and an indel cost equal to 1, OM is just LCS (longest common subsequence)
## default is that substitution cost is twice the indel cost, and default indel cost is 1
om_gentime <- seqdist(gentime15_seq, method = "OM", indel = 1, sm = scost)
## this results in a dissimilarity matrix which you can look at using:
round(om_gentime[1:10, 1:10], 1)

#### cluster analysis ####

## let's run cluster analysis on our dissimilarity matrix
clusterward <- agnes(om_gentime, diss = TRUE, method = "ward")
## other common methods are "average", "single", "complete"  
## "average" and "single" do not work well for time-use data (check)
## "complete can" be an option

# Convert hclust into a dendrogram and plot
hcd <- as.dendrogram(clusterward)

# Default plot
plot(hcd, type = "rectangle", ylab = "Height")

## Triangle plot
# plot(hcd, type = "triangle", ylab = "Height")

#### testing cluster solution ####

#inspect the splitting steps
ward.tree <- as.seqtree(clusterward, seqdata = gentime15_seq, 
                            diss = om_gentime, 
                            ncluster = 25)
seqtreedisplay(ward.tree, type = "d", border = NA, show.depth = TRUE) 

#### Checking Clustering Results ####

#test cluster solution quality
wardtest <- as.clustrange(clusterward,
                         diss = om_gentime, 
                          ncluster = 25)

#plot the quality criteria
#plot(wardtest,  lwd = 4)
#plot(wardtest, norm = "zscore", lwd = 4)
plot(wardtest, stat = c("ASW", "HC", "PBC"), norm = "zscore", lwd = 4)
#different available statistics:
#PBC
#Point Biserial Correlation. Correlation between the given distance matrice and a distance which equal to zero for individuals in the same cluster and one otherwise.
#
#HG
#Hubert's Gamma. Same as previous but using Kendall's Gamma coefficient.
#
#HGSD
#Hubert's Gamma (Somers'D). Same as previous but using Somers' D coefficient.
#
#ASW
#Average Silhouette width (observation).
#
#ASWw
#Average Silhouette width (weighted).
#
#CH
#Calinski-Harabasz index (Pseudo F statistics computed from distances).
#
#R2
#Share of the discrepancy explained by the clustering solution.
#
#CHsq
#Calinski-Harabasz index (Pseudo F statistics computed from squared distances).
#
#R2sq
#Share of the discrepancy explained by the clustering solution (computed using squared distances).
#
#HC
#Hubert's C coefficient.
#
#ASW:
#  The Average Silhouette Width of each cluster, one column for each ASW measure.



#### cluster solution ####

#cut tree

c10 <- cutree(clusterward, k = 8)
MyData<-cbind(MyData, c10)

#plot cluster solution
png("test.png", 1200, 800)
seqdplot(gentime15_seq, group = c10, border = NA)
dev.off()

# subset data by cluster
cl1<-(gentime15_seq[MyData$c10 ==  "1",])

# plot the selected cluster 
par(mfrow=c(1,1))
seqdplot(cl1, main = "",
         cex.main = 1.7, 
         with.legend = FALSE, 
         yaxis = FALSE, 
         cpal = getPalette(colourCount), 
         ylab = "",
         border = NA)

write.csv(MyData, "clustered_EC.csv")
