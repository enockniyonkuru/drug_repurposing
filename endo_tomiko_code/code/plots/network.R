library(ggplot2)
library(ggnetwork)
library(network)
library(sna)
library(igraph)
library(dplyr)

targetstop20 <- read.csv("~/Desktop/endometriosis/code/plots/targetstop20.csv")
targetstop20 <- targetstop20[,2:3] #get rid of x column


#Make a ggnetwork network dataframe
data <- ggnetwork::ggnetwork(targetstop20, layout = "target")
nodes <- data[data$x == data$xend & data$y == data$yend,]
rownames(nodes) <- nodes$vertex.names
(nodes <- nodes[,1:2])






dup <- targetstop20[2]
dup$multiple <- duplicated(dup) | duplicated(dup, fromLast=TRUE)
dup <- distinct(dup)
write.csv(dup, "~/Desktop/endometriosis/code/plots/targetstop20_xy.csv")
#data2 <- ggnetwork::ggnetwork(data, layout = as.matrix(nodes))

#set colors
color <- distinct(data[3])
color$id  <- 1:nrow(color)
color <- merge(color, dup, by.x = "vertex.names", by.y = "gene_name", all.x=TRUE)
color <- color[order(color$id), ]
color$multiple[color$multiple=="FALSE"]<-"skyblue"
color$multiple[color$multiple=="TRUE"]<-"darkorange2" #"royalblue4"
color$multiple[is.na(color$multiple)]<-"darkorchid" #"darkorange2"

#################################################
#To Plot the above interactome, use this section#
#################################################
#Plot the interactome! ggplot elements are super modular and ggnetwork claims to work with all of them.
#options(ggrepel.max.overlaps = Inf) 
ggplot(data, aes(x = x, y = y, xend = xend, yend = yend)) +
  geom_edges(color = "white") +
  geom_nodelabel_repel(aes(label = vertex.names), 
                       fontface = "bold", color = color$multiple, segment.colour = "black") +
  theme_blank(base_size=100)

