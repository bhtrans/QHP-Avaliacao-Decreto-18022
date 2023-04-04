
library(dplyr)
library(stringr)
library(tidyr)
library(plyr)

##CARREGANDO ARQUIVOS

current_path = rstudioapi::getActiveDocumentContext()$path 
setwd(dirname(current_path ))
setwd('QHP')
myfiles = list.files(path=getwd(),pattern="qh*",full.names=TRUE)
QHP = ldply(myfiles, read.delim,header=F)
DATA_VIGENCIA = str_sub(myfiles[1],start=-12,end=-5)
rm(myfiles)
setwd('..')
setwd('INTERVALOS')
myfiles = list.files(path=getwd(),pattern="*.csv",full.names=TRUE)
INTERVALO = ldply(myfiles, read.delim, sep=";")
setwd('..')
myfiles = list.files(path=getwd(),pattern="*.csv",full.names=TRUE)
QH<-read.csv2(myfiles,sep=";")
rm(current_path,myfiles)

#Separando de acordo com instrucao normativa DDI 001/2008

QHP$CONCESSIONARIA<-str_sub(QHP$V1,end=3)
QHP$LINHA<-str_sub(QHP$V1,start=4,end=9)
QHP$SUBLINHA<-str_sub(QHP$V1,start=10,end=11)
QHP$PC<-str_sub(QHP$V1,start=12,end=12)
QHP$TIPO.DIA<-str_sub(QHP$V1,start=13,end=14)
QHP$HORA<-str_sub(QHP$V1,start=15,end=16)
QHP$MINUTO<-str_sub(QHP$V1,start=17,end=18)
QHP$ELEVADOR<-str_sub(QHP$V1,start=-1)
QHP$V1<-NULL

#Substituindo QH COVID por QH T?PICO

QHP$TIPO.DIA<-gsub(32,8,QHP$TIPO.DIA)
QHP$TIPO.DIA<-gsub(33,7,QHP$TIPO.DIA)
QHP$TIPO.DIA<-gsub(34,1,QHP$TIPO.DIA)

# CRIANDO CHAVE COM LINHA
QHP$LINHA<-gsub(' ','',QHP$LINHA)
QHP$TIPO.DIA<-as.numeric(QHP$TIPO.DIA)
QHP$CHAVE<-str_c(QHP$LINHA,QHP$PC,QHP$TIPO.DIA,sep="-")

# AJUSTANTO DADOS

QHP$MIN_DIA<-(as.numeric(QHP$HORA)*60)+(as.numeric(QHP$MINUTO))
QHP<-arrange(QHP,TIPO.DIA,LINHA,PC,MIN_DIA)

#CALCULANDO HEADWAY

for(j in 1:nrow(QHP)){
  if(j==nrow(QHP)){
    QHP$HEADWAY[j]<-0
  }else if(QHP$CHAVE[j]==QHP$CHAVE[j+1]){
    QHP$HEADWAY[j]<-QHP$MIN_DIA[j+1]-QHP$MIN_DIA[j]
  }else{
    QHP$HEADWAY[j]<-0
  }
}

# LIMPANDO INFORMA??ES DESNECESS?RIAS

QHP$CHAVE<-NULL
QHP$MIN_DIA<-NULL
QHP$X<-NULL


#INTERVALO - ESPECIFICA??ES

colnames(INTERVALO)<-c("LINHA","TIPO.DIA","PICO","FORA.PICO")
INTERVALO$CHAVE<-str_c(INTERVALO$LINHA,INTERVALO$TIPO.DIA,sep="-")
INTERVALO<-INTERVALO %>% select(CHAVE,PICO,FORA.PICO)
QHP$CHAVE<-str_c(QHP$LINHA,QHP$TIPO.DIA,sep="-")
QHP<-merge(QHP,INTERVALO,by.x="CHAVE",by.y="CHAVE",all.x=T)
QHP$CHAVE<-NULL

#DEFINICAO DE FAIXA HORARIA

for(j in 1:nrow(QHP)){
  if((QHP$TIPO.DIA[j]=="8"||QHP$TIPO.DIA[j]=="9") && QHP$HORA[j] %in% c("05","06","07","16","17","18")){
    QHP$PERIODO[j]<-"PICO"
  }else if (QHP$TIPO.DIA[j]=="14" && QHP$HORA[j] %in% c("05","06","07","16","17","18")){
    QHP$PERIODO[j]<-"PICO"
  }else if(QHP$HORA[j] %in% c("00","01","02","03")){
    QHP$PERIODO[j]<-"NOTURNO"
  }else if (QHP$TIPO.DIA[j]=="7" && QHP$HORA[j] %in% c("06","07","08","11","12")){
    QHP$PERIODO[j]<-"PICO"
  }else{
    QHP$PERIODO[j]<-"FORA-PICO"
  }
}


#RESUMOS FINAIS - INTERVALO

for(j in 1:nrow(QHP)){
  if(QHP$PERIODO[j]=='PICO' && QHP$HEADWAY[j]<=QHP$PICO[j]){
  QHP$AN_INTERVALO[j]<-"OK"    
  }else if(QHP$PERIODO[j]=='PICO' && QHP$HEADWAY[j]>QHP$PICO[j]){
  QHP$AN_INTERVALO[j]<-"INTERVALO MAIOR"
  }else if(QHP$PERIODO[j]=='FORA-PICO' && QHP$HEADWAY[j]<=QHP$FORA.PICO[j]){
    QHP$AN_INTERVALO[j]<-"OK"
  }else if(QHP$PERIODO[j]=='FORA-PICO' && QHP$HEADWAY[j]>QHP$FORA.PICO[j]){
    QHP$AN_INTERVALO[j]<-"INTERVALO MAIOR"
  }else if(QHP$PERIODO[j]=='NOTURNO'){
    QHP$AN_INTERVALO[j]<-"OK"
  }
}

#PER?ODO DE OPERA??O QUADRO PROPOSTO

PER_OP<-QHP
PER_OP$HR_MIN<-(as.numeric(PER_OP$HORA)*60)+as.numeric(PER_OP$MINUTO)
PER_OP<-filter(PER_OP,HORA!="00",HORA!="01",HORA!="02",HORA!="03")
INICIO_OP<-PER_OP %>% dplyr::select(LINHA,PC,TIPO.DIA,HR_MIN) %>% dplyr::group_by(LINHA,PC,TIPO.DIA) %>% dplyr::summarise(PRIMEIRA_VIAGEM=min(HR_MIN))
TERMINO_OP<-PER_OP %>% dplyr::select(LINHA,PC,TIPO.DIA,HR_MIN) %>% dplyr::group_by(LINHA,PC,TIPO.DIA) %>% dplyr::summarise(ULTIMA_VIAGEM=max(HR_MIN))
TERMINO_OP[1:3]<-NULL
PER_OPERACAO<-cbind(INICIO_OP,TERMINO_OP)
rm(PER_OP,INICIO_OP,TERMINO_OP)

#PERIODO DE OPERACAO - QUADRO ATUAL

PER_OP<-QH
PER_OP<-filter(PER_OP,TIPO.DIA %in% c(1,7,8,9,14))
PER_OP<-filter(PER_OP,PER_OP$HORA.SAIDA %in% c(4:23))
PER_OP$HR_MIN<-(PER_OP$HORA.SAIDA*60)+PER_OP$MINUTO.SAIDA

INICIO_OP<-PER_OP %>% dplyr::select(LINHA,PC,TIPO.DIA,HR_MIN) %>% dplyr::group_by(LINHA,PC,TIPO.DIA) %>% dplyr::summarise(PRIMEIRA_VIAGEM=min(HR_MIN))
TERMINO_OP<-PER_OP %>% dplyr::select(LINHA,PC,TIPO.DIA,HR_MIN) %>% dplyr::group_by(LINHA,PC,TIPO.DIA) %>% dplyr::summarise(ULTIMA_VIAGEM=max(HR_MIN))
TERMINO_OP[1:3]<-NULL
PER_OP_PREPANDEMIA<-cbind(INICIO_OP,TERMINO_OP)
rm(PER_OP,INICIO_OP,TERMINO_OP)
colnames(PER_OP_PREPANDEMIA)[4]<-"PRIMEIRA_VIAGEM_ant"
colnames(PER_OP_PREPANDEMIA)[5]<-"ULTIMA_VIAGEM_ant"

#UNIAO DE ARQUIVOS REALIZADOS COM PRE PANDEMIA

PER_OP_PREPANDEMIA$CHAVE<-str_c(PER_OP_PREPANDEMIA$LINHA,PER_OP_PREPANDEMIA$PC,PER_OP_PREPANDEMIA$TIPO.DIA,sep=";")
PER_OPERACAO$CHAVE<-str_c(PER_OPERACAO$LINHA,PER_OPERACAO$PC,PER_OPERACAO$TIPO.DIA,sep=";")
PER_OP_PREPANDEMIA<-PER_OP_PREPANDEMIA %>% dplyr::select(CHAVE,PRIMEIRA_VIAGEM_ant,ULTIMA_VIAGEM_ant)
PER_OP_PREPANDEMIA[,1:2]<-NULL
COMP_PER_OPERACAO<-merge(PER_OPERACAO,PER_OP_PREPANDEMIA,by.x="CHAVE",by.y="CHAVE",all.x=T)
COMP_PER_OPERACAO$CHAVE<-NULL

#VIAGENS ANTERIORES E VIAGENS ATUAIS

COMP_PER_OPERACAO$Dif_First_Trip<-COMP_PER_OPERACAO$PRIMEIRA_VIAGEM_ant - COMP_PER_OPERACAO$PRIMEIRA_VIAGEM
COMP_PER_OPERACAO$Dif_Last_Trip<-COMP_PER_OPERACAO$ULTIMA_VIAGEM_ant - COMP_PER_OPERACAO$ULTIMA_VIAGEM
COMP_PER_OPERACAO$Dif_First_Trip[is.na(COMP_PER_OPERACAO$Dif_First_Trip)]<-0
COMP_PER_OPERACAO$Dif_Last_Trip[is.na(COMP_PER_OPERACAO$Dif_Last_Trip)]<-0


j<-1
k<--10

for(j in 1:nrow(COMP_PER_OPERACAO)){
  if(COMP_PER_OPERACAO$Dif_First_Trip[j]<0){
    COMP_PER_OPERACAO$Status_First[j]<-str_c("VIAGEM INICIAL ",abs(COMP_PER_OPERACAO$Dif_First_Trip[j])," MINUTOS APOS A PRIMEIRA VIAGEM DA PROGRAMACAO ATUAL") 
  }else if(COMP_PER_OPERACAO$Dif_First_Trip[j]>=k){
    COMP_PER_OPERACAO$Status_First[j]<-"OK"
  }else if(is.na(COMP_PER_OPERACAO$Dif_First_Trip[j])){
    COMP_PER_OPERACAO$Status_First[j]<-"OK"
  }
}

j<-1

for(j in 1:nrow(COMP_PER_OPERACAO)){
  if(COMP_PER_OPERACAO$Dif_Last_Trip[j]>(0)){
    COMP_PER_OPERACAO$Status_Last[j]<-str_c("LINHA ENCERRANDO OPERACAO ",COMP_PER_OPERACAO$Dif_Last_Trip[j]," MINUTOS ANTES DA PROGRAMACAO ATUAL" )
  }else{
    COMP_PER_OPERACAO$Status_Last[j]<-"OK"
  }
}

rm(INTERVALO,PER_OP_PREPANDEMIA,PER_OPERACAO,QH,DATA_VIGENCIA,j,k)

#SALVANDO ARQUIVOS FINAIS

dir.create('RESULTADOS')
setwd('RESULTADOS')
write.csv2(COMP_PER_OPERACAO,"Analise_Periodo_de_Operacao.csv",row.names = F)
write.csv2(QHP,"Analise_Intervalo_Viagens.csv",row.names = F)

