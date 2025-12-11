# https://quarto.org/docs/interactive/shiny/execution.html#multiple-files

library(ggplot2)
library(Ryacas)
library(dplyr)
library(plotly)
library(shiny)

treball_plusvalua <- function(jornada, intensitat,
                              productivitat, preu_treball) {
  valor <- jornada * intensitat * productivitat
  plusvalua <- valor - preu_treball
  treball_necessari <- preu_treball / (intensitat * productivitat)
  
  out <- data.frame(valor, plusvalua, treball_necessari)
  
  return(out)
}

taxa_benefici <- function(p, c, v) {
  p / (c + v)
}
  
taxa_plusvalua <- function(p, v) {
  p / v
}
