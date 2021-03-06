# TraMineR (developed by scholars in Geneva)
# is the main package for sequence analysis in R

# IMPORTANT
# sequence analysis is largely a descriptive technique


#### Loading Necessary Packages ####
if (!require("pacman")) install.packages("pacman")
library(pacman)

# load and install packages
pacman::p_load(TraMineR, TraMineRextras, downloader, cluster, RColorBrewer, devtools, haven, 
               tidyverse, reshape2, WeightedCluster, nnet, plyr)


#' Download, unzip, and create a dataframe from ATUS files. Note: the zipped file will be downloaded as "data" in your working directory.
#' 
#' @param url A string containing a link to a zipped file from the Bureau of Labor Statistics website.
#' @return The dataframe for ATUS.
#' @examples
#' zip_to_df("https://www.bls.gov/tus/special.requests/atusact-0320.zip")
#' zip_to_df("https://www.bls.gov/tus/special.requests/atusrostec-1120.zip")
zip_to_df<-function(url) {
  d <- "data"
  download(url, destfile=d)
  data <- read.table(unzip(d, files=paste(str_replace(str_split(tail(str_split(url, "/")[[1]], 1), "\\.")[[1]][1], "-", "_"), ".dat", sep="")), header = T, sep = ",", colClasses = "character")
  return(data)
}

## download the part of ATUS that contains diaries
df <- zip_to_df("https://www.bls.gov/tus/special.requests/atusact-0320.zip")
head(df)

## download the part of ATUS with the information about self-reported elder caregivers
df_ec <- zip_to_df("https://www.bls.gov/tus/special.requests/atusrostec-1120.zip")
head(df_ec)

### Filtering elder caregivers

## select ids in diaries dataframe that are in eldercare dataframe
data <- df[df$TUCASEID %in% df_ec$TUCASEID,]
head(data)

## subset the data to the variables needed
data <- data[c('TUCASEID', 'TUACTIVITY_N', 'TRCODEP', 'TUACTDUR24', 'TUSTARTTIM', 'TUSTOPTIME')]

## drop na
diary = data[complete.cases(data), ]

## rename columns to readable names
colnames(diary) <- c('caseid', 'actline', 'activity', 'duration', 'start', 'stop')
head(diary)

## create activity dictionary
## this list contains information to reducing activity coding to 11 main categories (listed below this)
## you can rename the original categories yourself, but you have to figure it out on your own
act_dict <-  c("010101" = 1, "010102" = 1, "010199" = 1, "010201" = 2, "010299" = 2, "010301" = 2, "010399" = 2, "010401" = 2, "010499" = 2, "010501" = 2, "010599" = 2, "019999" = 2, "020101" = 3, "020102" = 3, "020103" = 3, "020104" = 3, "020199" = 3, "020201" = 3, "020202" = 3, "020203" = 3, "020299" = 3, "020301" = 3, "020302" = 3, "020303" = 3, "020399" = 3, "020400" = 3, "020401" = 3, "020402" = 3, "020499" = 3, "020500" = 3, "020501" = 3, "020502" = 3, "020599" = 3, "020600" = 3, "020601" = 3, "020602" = 3, "020603" = 3, "020681" = 10, "020699" = 3, "020700" = 3, "020701" = 3, "020799" = 3, "020800" = 3, "020801" = 3, "020899" = 3, "020900" = 3, "020901" = 3, "020902" = 3, "020903" = 3, "020904" = 3, "020905" = 3, "020999" = 3, "029900" = 3, "029999" = 3, "030100" = 4, "030101" = 4, "030102" = 4, "030103" = 4, "030104" = 4, "030105" = 4, "030106" = 4, "030107" = 4, "030108" = 4, "030109" = 4, "030110" = 4, "030111" = 4, "030112" = 4, "030199" = 4, "030200" = 4, "030201" = 4, "030202" = 4, "030203" = 4, "030204" = 4, "030299" = 4, "030300" = 4, "030301" = 4, "030302" = 4, "030303" = 4, "030399" = 4, "040100" = 4, "040101" = 4, "040102" = 4, "040103" = 4, "040104" = 4, "040105" = 4, "040106" = 4, "040107" = 4, "040108" = 4, "040109" = 4, "040110" = 4, "040111" = 4, "040112" = 4, "040199" = 4, "040200" = 4, "040201" = 4, "040202" = 4, "040203" = 4, "040204" = 4, "040299" = 4, "040300" = 4, "040301" = 4, "040302" = 4, "040303" = 4, "040399" = 4, "030186" = 4, "040186" = 4, "030000" = 5, "030400" = 5, "030401" = 5, "030402" = 5, "030403" = 5, "030404" = 5, "030405" = 5, "030499" = 5, "030500" = 5, "030501" = 5, "030502" = 5, "030503" = 5, "030504" = 5, "030599" = 5, "039900" = 5, "039999" = 5, "040000" = 5, "040400" = 5, "040401" = 5, "040402" = 5, "040403" = 5, "040404" = 5, "040405" = 5, "040499" = 5, "040500" = 5, "040501" = 5, "040502" = 5, "040503" = 5, "040504" = 5, "040505" = 5, "040506" = 5, "040507" = 5, "040508" = 5, "040599" = 5, "049900" = 5, "049999" = 5, "050000" = 6, "050100" = 6, "050101" = 6, "050102" = 6, "050103" = 6, "050104" = 6, "050199" = 6, "050200" = 6, "050201" = 6, "050202" = 6, "050203" = 6, "050204" = 6, "050205" = 6, "050299" = 6, "050300" = 6, "050301" = 6, "050302" = 6, "050303" = 6, "050304" = 6, "050305" = 6, "050399" = 6, "050400" = 6, "050401" = 6, "050403" = 6, "050404" = 6, "050405" = 6, "050499" = 6, "059900" = 6, "059999" = 6, "060000" = 6, "060100" = 6, "060101" = 6, "060102" = 6, "060103" = 6, "060104" = 6, "060199" = 6, "060200" = 6, "060201" = 6, "060202" = 6, "060203" = 6, "060204" = 6, "060299" = 6, "060300" = 6, "060301" = 6, "060302" = 6, "060303" = 6, "060399" = 6, "060400" = 6, "060401" = 6, "060402" = 6, "060403" = 6, "060499" = 6, "069900" = 6, "069999" = 6, "050481" = 6, "050389" = 6, "050189" = 6, "060289" = 6, "050289" = 6, "070000" = 7, "070100" = 7, "070101" = 7, "070102" = 7, "070103" = 7, "070104" = 7, "070105" = 7, "070199" = 7, "070200" = 7, "070201" = 7, "070299" = 7, "070300" = 7, "070301" = 7, "070399" = 7, "079900" = 7, "079999" = 7, "080000" = 7, "080100" = 7, "080101" = 7, "080102" = 7, "080199" = 7, "080200" = 7, "080201" = 7, "080202" = 7, "080203" = 7, "080299" = 7, "080300" = 7, "080301" = 7, "080302" = 7, "080399" = 7, "080400" = 7, "080401" = 7, "080402" = 7, "080403" = 7, "080499" = 7, "080500" = 7, "080501" = 7, "080502" = 7, "080599" = 7, "080600" = 7, "080601" = 7, "080602" = 7, "080699" = 7, "080700" = 7, "080701" = 7, "080702" = 7, "080799" = 7, "080800" = 7, "080801" = 7, "080899" = 7, "089900" = 7, "089999" = 7, "090000" = 7, "090100" = 7, "090101" = 7, "090102" = 7, "090103" = 7, "090104" = 7, "090199" = 7, "090200" = 7, "090201" = 7, "090202" = 7, "090299" = 7, "090300" = 7, "090301" = 7, "090302" = 7, "090399" = 7, "090400" = 7, "090401" = 7, "090402" = 7, "090499" = 7, "090500" = 7, "090501" = 7, "090502" = 7, "090599" = 7, "099900" = 7, "099999" = 7, "100000" = 7, "100100" = 7, "100101" = 7, "100102" = 7, "100103" = 7, "100199" = 7, "100200" = 7, "100201" = 7, "100299" = 7, "100300" = 7, "100303" = 7, "100304" = 7, "100399" = 7, "100400" = 7, "100401" = 7, "100499" = 7, "109900" = 7, "109999" = 7, "120303" = 8, "120304" = 8, "110000" = 9, "110100" = 9, "110101" = 9, "110199" = 9, "110200" = 9, "110201" = 9, "110299" = 9, "119900" = 9, "110289" = 9, "119999" = 9, "120000" = 10, "120100" = 10, "120101" = 10, "120199" = 10, "120200" = 10, "120201" = 10, "120202" = 10, "120299" = 10, "120300" = 10, "120301" = 10, "120302" = 10, "120305" = 10, "120306" = 10, "120307" = 10, "120308" = 10, "120309" = 10, "120310" = 10, "120311" = 10, "120312" = 10, "120313" = 10, "120399" = 10, "120400" = 10, "120401" = 10, "120402" = 10, "120403" = 10, "120404" = 10, "120405" = 10, "120499" = 10, "120500" = 10, "120501" = 10, "120502" = 10, "120503" = 10, "120504" = 10, "120599" = 10, "129900" = 10, "129999" = 10, "130000" = 10, "130100" = 10, "130101" = 10, "130102" = 10, "130103" = 10, "130104" = 10, "130105" = 10, "130106" = 10, "130107" = 10, "130108" = 10, "130109" = 10, "130110" = 10, "130111" = 10, "130112" = 10, "130113" = 10, "130114" = 10, "130115" = 10, "130116" = 10, "130117" = 10, "130118" = 10, "130119" = 10, "130120" = 10, "130121" = 10, "130122" = 10, "130123" = 10, "130124" = 10, "130125" = 10, "130126" = 10, "130127" = 10, "130128" = 10, "130129" = 10, "130130" = 10, "130131" = 10, "130132" = 10, "130133" = 10, "130134" = 10, "130135" = 10, "130136" = 10, "130199" = 10, "130200" = 10, "130201" = 10, "130202" = 10, "130203" = 10, "130204" = 10, "130205" = 10, "130206" = 10, "130207" = 10, "130208" = 10, "130209" = 10, "130210" = 10, "130211" = 10, "130212" = 10, "130213" = 10, "130214" = 10, "130215" = 10, "130216" = 10, "130217" = 10, "130218" = 10, "130219" = 10, "130220" = 10, "130221" = 10, "130222" = 10, "130223" = 10, "130224" = 10, "130225" = 10, "130226" = 10, "130227" = 10, "130228" = 10, "130229" = 10, "130230" = 10, "130231" = 10, "130232" = 10, "130299" = 10, "130300" = 10, "130301" = 10, "130302" = 10, "130399" = 10, "130400" = 10, "130401" = 10, "130402" = 10, "130499" = 10, "139900" = 10, "139999" = 10, "140000" = 10, "140100" = 10, "140101" = 10, "140102" = 10, "140103" = 10, "140104" = 10, "140105" = 10, "149900" = 10, "149999" = 10, "150000" = 10, "150100" = 10, "150101" = 10, "150102" = 10, "150103" = 10, "150104" = 10, "150105" = 10, "150106" = 10, "150199" = 10, "150200" = 10, "150201" = 10, "150202" = 10, "150203" = 10, "150204" = 10, "150299" = 10, "150300" = 10, "150301" = 10, "150302" = 10, "150399" = 10, "150400" = 10, "150401" = 10, "150402" = 10, "150499" = 10, "150500" = 10, "150501" = 10, "150599" = 10, "150600" = 10, "150601" = 10, "150602" = 10, "150699" = 10, "150700" = 10, "150701" = 10, "150799" = 10, "150800" = 10, "150801" = 10, "150899" = 10, "159900" = 10, "159999" = 10, "160000" = 10, "160100" = 10, "160101" = 10, "160102" = 10, "160103" = 10, "160104" = 10, "160105" = 10, "160106" = 10, "160107" = 10, "160108" = 10, "160199" = 10, "160200" = 10, "160201" = 10, "160299" = 10, "169900" = 10, "169999" = 10, "159989" = 10, "169989" = 10, "110281" = 10, "100381" = 10, "100383" = 10, "180000" = 11, "180100" = 11, "180101" = 11, "180199" = 11, "180200" = 11, "180201" = 11, "180202" = 11, "180203" = 11, "180204" = 11, "180205" = 11, "180206" = 11, "180207" = 11, "180208" = 11, "180209" = 11, "180280" = 11, "180299" = 11, "180300" = 11, "180301" = 11, "180302" = 11, "180303" = 11, "180304" = 11, "180305" = 11, "180306" = 11, "180307" = 11, "180399" = 11, "180400" = 11, "180401" = 11, "180402" = 11, "180403" = 11, "180404" = 11, "180405" = 11, "180406" = 11, "180407" = 11, "180482" = 11, "180499" = 11, "180500" = 11, "180501" = 11, "180502" = 11, "180503" = 11, "180504" = 11, "180599" = 11, "180600" = 11, "180601" = 11, "180602" = 11, "180603" = 11, "180604" = 11, "180605" = 11, "180699" = 11, "180700" = 11, "180701" = 11, "180702" = 11, "180703" = 11, "180704" = 11, "180705" = 11, "180782" = 11, "180799" = 11, "180800" = 11, "180801" = 11, "180802" = 11, "180803" = 11, "180804" = 11, "180805" = 11, "180806" = 11, "180807" = 11, "180899" = 11, "180900" = 11, "180901" = 11, "180902" = 11, "180903" = 11, "180904" = 11, "180905" = 11, "180999" = 11, "181000" = 11, "181001" = 11, "181002" = 11, "181099" = 11, "181100" = 11, "181101" = 11, "181199" = 11, "181200" = 11, "181201" = 11, "181202" = 11, "181203" = 11, "181204" = 11, "181205" = 11, "181206" = 11, "181283" = 11, "181299" = 11, "181300" = 11, "181301" = 11, "181302" = 11, "181399" = 11, "181400" = 11, "181401" = 11, "181499" = 11, "181500" = 11, "181501" = 11, "181599" = 11, "181600" = 11, "181601" = 11, "181699" = 11, "181800" = 11, "181801" = 11, "181899" = 11, "189900" = 11, "189999" = 11, "180481" = 11, "180381" = 11, "180382" = 11, "181081" = 11, "180589" = 11, "180682" = 11, "500000" = 11, "500100" = 11, "500101" = 11, "500102" = 11, "500103" = 11, "500104" = 11, "500105" = 11, "500106" = 11, "500107" = 11, "509900" = 11, "509989" = 11, "509999" = 11)

## this list is not used but it contains the codes for the 11 main activities
act = c("1" = "Sleep",
        "2" = "Personal Care",
        "3" = "Housework",
        "4" = "Child Care",
        "5" = "Adult Care",
        "6" = "Work and Education",
        "7" = "Shopping",
        "8" = "TV Watching",
        "9" = "Eating",
        "10" = "Leisure",
        "11" = "Travel and Other")

### recode the activities using the activity dictionary
diary$lst_act <- revalue(diary$activity, act_dict)
head(diary)

## print out unique values for activities
unique(diary$lst_act)

## rename some of the activities even to fewer categories
## the activity dictionary created above gives 11 categories of activities
## in case some of the activities need to be combined you can follow the same logic in the following lines:
diary$lst_act = revalue(diary$lst_act, c("2" = 1, "8" = 10, "9" = 10))
unique(diary$lst_act)

## create sequences of activities per activity (result: long list of combined sequences)
sequences = rep(as.numeric(diary$lst_act), as.numeric(diary$duration))

## separate the long list into sequences (1440 min in each sequence)
seq = matrix(sequences, nrow=length(sequences)/1440, ncol=1440, byrow=T)
seq

## specify the names for the activity variables 
activities<-c()
for(i in 0:1439) {
  activities<-c(activities, paste("var", i, sep = ""))
}

## transform matrix to dataframe
data <- as.data.frame(seq, row.names = unique(diary$caseid))

## used created vars names to name the columns in the dataframe
colnames(data) <-activities

## create id
data$id <- as.numeric(row.names(data))


#### Sequence Analysis #####

# I create an object with intervals' labels. Sequences start at 04:00 AM:
# depending on your own sequence intervals (if you are not using the ATUS) these labels need to be adjusted
t_intervals_labels <-  format( seq.POSIXt(as.POSIXct("2021-11-08 04:00:00 GMT"), as.POSIXct("2021-11-09 03:59:00 GMT"), by = "1 min"),
                               "%H:%M", tz="GMT")

#### colour palette ####

## let's brew some colours first
## number of colours is the number of states (in the alphabet)
## interesting resource on colors (cheatsheet): 
## https://www.nceas.ucsb.edu/sites/default/files/2020-04/colorPaletteCheatsheet.pdf

## define labels first and count:
labels = c("sleep", "housework", 
           "childcare", "adult care",
           "paid work", "shopping", "leisure", 
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


## check the created pallette: 
ggplot() + 
  scale_x_continuous(name="x") + 
  scale_y_continuous(name="y") +
  geom_rect(data=colours, mapping=aes(xmin=x1, xmax=x2, ymin=y1, ymax=y2, fill=t), color="black", alpha=0.5) +
  geom_text(data=colours, aes(x=x1+(x2-x1)/2, y=y1+(y2-y1)/2, label=r), size=4) + 
  scale_fill_manual(values = getPalette(colourCount)) + theme(legend.position = "none")



#### define the sequence object ####
## subsetting is not necessary, but for the sake of efficiency in here I'll subset it to 2000 observations
MyData <- as_tibble(data[1:2000,])


## you want to use the full categories of states:
## (you need to change if you only focus on specific activities)
seq <- seqdef(MyData,
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
print(seq[1:5, ], format = "STS")
## "STS" format shows each step

#### PLOTTING SEQUENCES ####

#### sequence index plots ####
## the default is 1:10 (or, idxs= 1:10) plotting the first 10 sequences
## if you set idxs to 0, it plots all (not recommended with big number of observations)
seqiplot(seq, border = NA, with.legend = "right", legend.prop=0.4)

##also to plot all you can use seqIplot
seqIplot(seq, border = NA, with.legend = "right", legend.prop=0.4, idxs = 1:4)
## seqIplot(seq, border = NA, with.legend = "right", legend.prop=0.4)

## MOST FREQUENT SEQUENCES --usually useless for time-use sequences because time-use diaries have too many steps
## tabulate 4 frequent sequences:
## because there are 1440 steps there are barely any
## this is more useful for shorter sequences with many commonalities (as in life-course research)
seqtab(seq, idxs = 1:4)

##also can plot frequencies using seqfplot
seqfplot(seq, border = NA, with.legend = "right", legend.prop=0.4)

## state distribution plots (aka tempogram aka chronogram)
## this is an easy way to plot a tempogram 
seqdplot(seq, border = NA, with.legend = "right", legend.prop=0.4)

#### Transitions ####

## transitions from state to state (in probabilities)
trate <- seqtrate(seq)
round(trate, 2)

## heatmap of the transitions matrix
heatTrate=melt(trate)
head(heatTrate)

## plot the heatmap
ggplot(heatTrate, aes(Var2, Var1)) +
  geom_tile(aes(fill = value)) +
  geom_text(aes(label = round(value, 2))) +
  scale_fill_continuous(high = "#132B43", low = "#56B1F7", name="Transitions")


#### changing granularity (number of steps in a sequence) ####
## changing the number of steps
## to the first step method = "first", to the last = "last", or the most frequent = "mostfreq"
## 15 means every 15 min
time15_seq <- seqgranularity(seq, tspan=15, method="mostfreq")

## plot the tempogram
seqdplot(time15_seq, border = NA, with.legend = "right", legend.prop=0.4)

#### Modal states sequence ####

#seqplot(time15_seq, type="ms", with.legend = "right", legend.prop=0.4)
## same as
seqmsplot(time15_seq, with.legend = "right", legend.prop=0.4, main="Modal Sequences")

#transversal entropy of state distributions
#the number of valid states and the Shannon entropy of the transversal state distribution
# shows the measure of 'chaos' (diversity of activities) in the diaries
seqHtplot(time15_seq, with.legend = "right", legend.prop=0.4)



#### calculating dissimilarities #####

# seqdist() = for pairwise dissimilarities
# seqsubm() = to compute own substitution matrix
#"TRATE" option, the costs are determined from the estimated transition rates
scost <- seqsubm(time15_seq, method = "TRATE")
round(scost, 3)
## calculated in this way, all are close to 2 anyway (for this dataset) 2 is default
## or we can use the usual default one of constant 2:
ccost <- seqsubm(time15_seq, method="CONSTANT", cval=2)
round(ccost, 3)

##optimal matching include both substitutions and indels
##The cost minimization is achieved through dynamic programming, the algorithm
##implemented in TraMineR being essentially that of Needleman and Wunsch (1970)
##For the illustration how the algorithm works go to:
## https://blogs.ubc.ca/kamilakolpashnikova/optimal-matching-algorithm-interactive-app-for-social-scientists/

## if computationally heavy, calculate only the upper part of the matrix by full.matrix = FALSE
## remember that with a
## constant substitution cost of 2 and an indel cost equal to 1, OM is just LCS (longest common subsequence)
## default is that substitution cost is twice the indel cost, and default indel cost is 1
om_time <- seqdist(time15_seq, method = "OM", indel = 1, sm = scost)
## this results in a dissimilarity matrix which you can look at using:
round(om_time[1:10, 1:10], 1)

#### cluster analysis ####

## run cluster analysis on the calculated dissimilarity matrix
clusterward <- agnes(om_time, diss = TRUE, method = "ward")
## other common methods are "average", "single", "complete" (instead of "ward")  
## "average" and "single" do not work well for time-use data (check if you want)
## "complete" can be an option
## "ward" is the "industry standard"

# Convert hclust into a dendrogram and plot
hcd <- as.dendrogram(clusterward)

# plot the dendrogram
plot(hcd, type = "rectangle", ylab = "Height")

## Triangle plot (other way to plot the dendrogram)
# plot(hcd, type = "triangle", ylab = "Height")

#### testing cluster solution ####

#inspect the splitting steps
ward.tree <- as.seqtree(clusterward, seqdata = time15_seq, 
                        diss = om_time, 
                        ncluster = 25)
## plot the tree of tempograms to check how it splits the diaries
seqtreedisplay(ward.tree, type = "d", border = NA, show.depth = TRUE) 

#### Checking Clustering Results ####

#test cluster solution quality
wardtest <- as.clustrange(clusterward,
                          diss = om_time, 
                          ncluster = 25)

#plot the quality criteria
plot(wardtest, stat = c("ASW", "HC", "PBC"), norm = "zscore", lwd = 4)
#different available statistics (instead of "ASW", "HC", "PBC")
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

## none of these measures is perfect.


#### cluster solution ####

## cut tree
## because the solutions for clusters showed that 8 clusters would be ok, we cut at 8 clusters
c8 <- cutree(clusterward, k = 8)
MyData<-cbind(MyData, c8)

#plot cluster solution
png("plot_clusters.png", 1200, 800)
seqdplot(time15_seq, group = c8, border = NA)
dev.off()

# subset data by cluster
cl1<-(time15_seq[MyData$c8 ==  "1",])

# plot the selected cluster 
par(mfrow=c(1,1))
seqdplot(cl1, main = "",
         cex.main = 1.7, 
         with.legend = FALSE, 
         yaxis = FALSE, 
         cpal = getPalette(colourCount), 
         ylab = "",
         border = NA)

## write new data to csv if needed
#write.csv(MyData, "clustered_EC.csv")
