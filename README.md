# case_Uncover


# O Projeto


Este projeto implementa uma solução para centralizar dados de diferentes fontes de uma empresa em um ambiente unificado de armazenamento e consulta, com o objetivo de integrar essas informações à plataforma Uncover. A solução automatiza a coleta e o armazenamento de dados de CSVs recorrentes, Google Sheets, e bancos de dados, facilitando o acesso centralizado para análise e tomada de decisão.

![imagem](https://github.com/pandex7/case_Uncover/blob/main/assets/1.png)


## Seções de Wiki

-Visão geral sobre o ambiente GCP e o processo.

-Detalhes do Processo ETL

-Processo de Monitoramento.



## Tecnologia

- Serviços GCP: BigQuery, DataForm, Dataflow, Cloud Storage, Secret Manager, Composer.



## Ambientes e Execução

## Componentes

O projeto é hospedado na GCP e utiliza uma ampla gama de serviços disponibilizados pela Google, entre eles:

-Google Cloud Composer: é um serviço de orquestração de fluxos de trabalho totalmente gerenciado, baseado no projeto de código aberto Apache Airflow;

-Google Cloud BigQuery: serviço de banco de dados em nuvem, contendo os schemas e a database principal;

-Google Cloud Dataform: utilizado para a realização da ETL, fazendo a transformação dos dados entre camadas (Apenas demonstração não temos T do ETL nessa etapa);

-Google Cloud Dataflow: recebe os Jobs criados no Airflow, realizando a conexão entre bancos de origem e destino, criação de tabelas e ingestão;

-Google Cloud Storage: armazena os arquivos de configuração, CSV e arquivos temporários se necessário;

-Google Cloud Secret Manager: contém todas as chaves de bancos de dados e API's se necessário.



## Sistema de Origem

Utilizaremos 3 sistema de origem, sendo banco, CSV e Planilha do Google Sheets.

- Banco de dados (' SQL-Server Exemplo')

- Cloud Functions (Planilha do google Sheets)

- Arquivo CSV : SFTP 


# Execução

## Concepção do Processo ETL

O processo foi concebido para centralizar dados de diferentes fontes de uma empresa em um ambiente unificado de armazenamento com o objetivo de integrar essas informações à plataforma Uncover.



## Encadeamento geral do processo - SFTP


Observação, para concater os arquivos CSV usaremos um pipeline do dataflow com Apache Beam, ele é configurado para detectar novos arquivos CSV no bucket. Ele lê o conteúdo de cada arquivo e concatena as linhas ao conjunto de dados existente.
Ou podemos utiliza tabela externa no bigquery onde le os arquivos específicos com base no timestamp.

Verificar o fluxograma para melhor entendimento.

O processo de ingestão do SFTP é feito da forma em que, os arquivos CSV são colocados no bucket do GCP via Apache NiFI (Conectando no SFTP do Cliente), após isso é estabelecida uma conexão com esse bucket do GCP que contém os arquivos, então esses dados são enviados para a LAND, após isso feito o dado é passado para as camadas superiores com base no particionamento e por fim feita a transformação dos dados. Fila de processos em ordem de execução, feita pelo orquestrador:

- Arquivos colocados no bucket do GCP via Apache NiFI;

- Conexão com o bucket do GCP;

- Arquivos são processados e enviados para a LAND do BigQuery;

- Scripts do Dataform são executados realizando a ETL;

- Camadas RAW e TRUSTED recebem os dados;

- RAW recebe o dado com particionamento mais recente;

- TRUSTED recebe o dado com tipagem correta e devidamente atualizado;

- Ao término do processo, os dados ficam guardados para integrar com a plataforma Uncover.



## Encadeamento geral do processo - APIs

O processo de ingestão das APIs  é feito via funções do Google Cloud Functions em que, os arquivos pegos na resposta das requisições dessas APIs são colocados no bucket do GCP, após isso esse arquivo é processado em uma pasta onde ocorrem as transformações se necessárias do tipo do arquivo, na DAG é estabelecida uma conexão com esse bucket do GCP que contém os arquivos com os dados de cada API e esses dados são enviados para a LAND. Por fim o dado é passado para as camadas superiores com base no particionamento e feita a transformação dos dados. Fila de processos em ordem de execução, feita pelo orquestrador:

- Arquivos com dados das APIs colocados no bucket do GCP via Google Cloud Functions;

- Conexão com o bucket do GCP;

- Arquivos são processados e enviados para a LAND do BigQuery;

- Scripts do Dataform são executados realizando a ETL;

- Camadas RAW e TRUSTED recebem os dados;

- RAW recebe o dado com particionamento mais recente;

- TRUSTED recebe o dado com tipagem correta e devidamente atualizado;

- Ao término do processo, os dados ficam guardados para integrar com a plataforma Uncover.


Para começar, estabelecemos as variáveis que serão usadas no código no momento de configurações para determinar o sistema de origem, o tipo de carga e o ambiente no qual a DAG está sendo executada.

sistema_de_origem = "sheets"
típo_carga = "full/incri"
env = Variable.get("ENV")

Após a configuração dessas variáveis, uma solicitação é enviada à origem da API para obter um token essencial, com objetivo de termos a autorização das requisições do endpoint em que esta DAG realizará a ingestão de dados. Depois de concluir a autenticação, é chamada a função do Google Cloud Functions que será a responsável por fazer toda a parte de obtenção dos dados até o bucket do Google Cloud Storage.


## Detalhes do processo ETL no Dataform (Não é Necessário o T para esse exercicio.)

Verificar o Fluxograma para um melhor entendimento entre as camadas.

O Google Cloud Dataform contém os scripts de transformação de cada camada do sistema, partindo da LAND e indo até a REFINED.


## Camada Land para Raw


O processo da transição da camada LAND para a RAW utiliza uma data de particionamento para controlar a inserção de dados, garantindo que somente os dados mais recentes e/ou aqueles que ainda não foram ingeridos sejam incluídos.

Assim, a consulta SQL no BigQuery utiliza scripts SQL para executar instruções de inserção (INSERT) na camada RAW, mantendo a tipagem dos dados como strings e preservando as colunas de "change tracking" para o "banco de dados" (monitoramento de mudanças) de cada registro da camada LAND. Neste cenário, as tabelas não precisam ser criadas antecipadamente no BigQuery; quando é feita a primeira ingestão elas são criadas e populadas com os dados totais contidos na LAND. Dessa forma, se a tabela não existir no BigQuery, será feita uma transição FULL da camada LAND para a RAW, onde a transição por particionamento é apenas iniciada após a primeira ingestão





## Camada RAW para TRUSTED

Posteriormente, na transferência de dados da camada RAW para a camada TRUSTED de cada sistema, é utilizado um script SQL de "Merge." Esse script faz uso do ID e das informações de alteração de cada registro para verificar se o ID do novo registro está presente. Se o ID for confirmado, um comando de atualização (UPDATE) é executado no registro da camada TRUSTED. Caso o ID não exista, um comando de inserção (INSERT) é utilizado para adicionar esse novo registro à camada TRUSTED.




Ficando a mesma logica para a google sheets (API), lembrando que o bigquery suporta array.
então na camada LAND E RAW podera fica dentro dos seus array.
e na camada TRUSTED sera feita a criação sem destinção se necessário.





--------------------------------------------------------------------------------------------------------------------------------------------------------


# Processo de monitoramento

## Monitoramento automático de execução.

** Ideia de monitoramento **

Exemplo de uso.
Estou apenas descrevendo possiveis ideias para monitorar o ambiente automáticamente.



DAG:

Criação de dag, Exemplo: A DAG "airflow_monitoring" é executado a cada 10 minutos para verificar o funcionamento com sucesso das DAGs do Airflow.

** Cloud Functions ** :

- A função "function-monitoring-dags-run" é executada a cada hora para monitorar o funcionamento das DAGs do airflow, enviar essa informação para o SQL e disponibilizar isso como visualização no grafana.

A função "function-monitoring-bucket-arquivos_CSV" é executada todos os dias às 7 horas da manhã para verificar se os documentos dos sistemas SFTP estão atualizados no bucket.

** Alertas do Zabbix ** :

- Os alertas ligados aos sistemas SFTP são referentes às datas de atualização dos arquivos existentes nas respectivas pastas do bucket, indicando que o arquivo em questão no alerta não está atualizado no sistema.

-Os alertas ligados às DAGs são referentes ao sucesso ou não das execuções das DAGs, indicando que a DAG em questão no alerta falhou.

-O alerta ligado ao bucket é referente à data de última atualização do bucket que contém os arquivos utilizados para definir as regras e os critérios, indicando que algum arquivo existente nesse bucket foi alterado.

FIM.
