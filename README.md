# Verifica QHP - Subsídio Emergencial PBH

### Introdução

Neste repositório contém um script e os arquivos com os parâmetros básicos utilizados na verificação dos Quadros de Horários Propostos (QHPs) encaminhados pelas concessionárias operadoras do Sistema de Transporte Público Coletivo de Belo Horizonte. Para tal, são considerados os requisitos mínimos contratuais e legais vigentes (Decreto nº 18.022/2022, Portaria SUMOB Nº 004/2022 e Edital de Concorrência Pública nº 131/2008). Para execução deste script, faz-se necessário que ele esteja salvo em quaisquer diretórios e que todos os demais arquivos sigam o mesmo padrão estabelecido neste documento.

### Arquivos com os parâmetros para comparação das propostas
 
 O usuário do script *HDW e PO_qhp.R* deverá ter as seguintes informações prévias antes de executá-lo:\
 
 1. Intervalos: Arquivo CSV com os intervalos máximos permitidos no pico e no fora-pico com o modelo disponibilizado na pasta INTERVALOS e organizados no diretório **INTERVALOS**; 
 2. QHP: Arquivos txt com as propostas dos QHPs encaminhados pelas concessionárias de acordo com a Portaria SUMOB Nº 004/2022 inseridos no diretório **QHP**, e; 
 3. O Quadro de Horários vigente para a data de comparação: o Decreto estipula que as primeiras, as últimas e as viagens noturnas sejam as mesmas ofertadas no período de pré-pandemia. Para tal, estipulou-se o ofertado em 21 de janeiro de 2020 como base. Utiliza-se o relatório de Quadro de Horários extraído no BH03.

### Como executar

Após organizar os arquivos *Intervalos*, *QHP* e *Quadro de Horários vigente* no diretório escolhido, deve-se copiar o *script* para a raíz do diretório escolhido. Após a execução, será criada a pasta **RESULTADOS** com dois arquivos CSV: 
1. Analise_Intervalo_Viagens: verifica o intervalo (em minutos) entre as viagens propostas e acusa aquelas em desconformidade com os parâmetros estabelecidos no arquivo INTERVALOS, e;
2. Analise_Periodo_de_Operacao: verifica se há diferenças entre as primeiras e as últimas viagens.
 
### Desenvolvido por

Thiago Henrique de Oliveira Faustino (@thfaustino) e Guilherme Henrique Campos Botelho (@akaBotelho)
