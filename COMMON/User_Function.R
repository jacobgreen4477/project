
# <<User Function>>---------------------------------------------------------------------

# IN�� �ݴ� ������ �Լ��� �̸� ������
# ex> test$text %not in% ('��', '��')
"%not in%" <- Negate("%in%") 


# HDFS�� �ִ� ���̺��� ���� �о���� ���� �Լ�
# ex> readTablesFromSpark(HDFS���, ���̺��̸�)
# ������ �Ʒ��� ���� �� �ٿ� ���� �� �� parquet ������ �����ϰ�, �ٽ� �����並 ����� sql�� ����ؾ� ��
# test <- read.df('HDFS���/���̺��̸�/*.parquet', source='parquet')
# createOrReplaceTempView(test, 'TEST')
# eval(parse(text='���ɾ�')) ������ ���� string���·� ����� ���ɾ �ٷ� ���� ����
# ex> eval(parse(text='5+5'))
# toupper()�� ��� char�� �빮�ڷ� ����
readTablesFromSpark <- function(path, tableArray) {
  for (i in 1:length(tableArray)) {
    eval(parse(text = paste0(tableArray[i]," <- read.df(file.path(path, '", tableArray[i], "','*.parquet'), source = 'parquet')")))
    eval(parse(text = paste0("createOrReplaceTempView(", tableArray[i], ", '", tableArray[i], "')")))
  }
toupper(as.character(tableNames()))
}




# LongŸ������ ����� ��¥ ���� �÷��� Timestamp �������� ���� ��ȯ�ϱ� ���� �Լ�
# HDFS�� parquet ���Ͽ����� ���� Oracle �� Timestamp���� Long������ �ڵ���������Ǵµ�, �̸� �ٽ� 0000-00-00 ���·� ��ȯ
# ex> castToTimestamp(HDFS���, ���̺��̸�, �÷��̸�)
castToTimestamp <- function(path, tableName, ColumnArray) {
  eval(parse(text = paste0(tableName," <<- read.df(file.path(path, '", tableName, "','*.parquet'), source = 'parquet')")))
  for (i in 1:length(columnArray)) {
    eval(parse(text = paste0(tableName," <<- withColumn(", tableName, ", '", columnArray[i], "', SparkR::cast(", talbeName, "$", columnArray[i], "/1000, 'timestamp'))")))
  }
  eval(parse(text = paste0("createOrReplaceTempView(", tableName, ", '", tableName, "')")))
}


# ������ row�� ����Ʈ�� ���� ������������ ������ �Ϲ����� �������������������� �����ϱ� ���� �Լ�
# �ַ� HDFS�� JSON������ ���������������� ������ ���, ������ row�� ����Ʈ�� ����
# ���� rHDFS������ parquet ������ ������������ ���·� �ٷ� ������ �� ����, JSON���·� ��ȯ�Ͽ� ó���ϴ� ��Ȳ��
# ������ rHDFS ������Ʈ �������� �� ������ �ذ�ȴٸ� �� �̻� ���ʿ��� �Լ�
# ex> test <- unListDataFrame(test)
unListDataFrame <- function(df) {
  len <- length(df)
  unlistDF <- as.data.frame(unlist(df[[1]]))
  for (i in 2:len) { 
    unl1stDF <- cbind(unListDF, as.data.frame(unlist(df[[i]])))
  }
  colnames(unListDF) <- names(df)
  return(unListDF)
}


# �޷��� ���� �����ϱ� ���� �Լ�
# ������ �������� day�� �����ϰ� month������ ������ ���·� ���
# ex> TRNS_MONTH.fn('201605', -2)  �����: '201603'
TRNS_MONTH.fn <- function(date, mm) {
  date <- as.Date(paste0(date, "01"), format = "%Y%m%d")
  lubridate::month(date) <- lubridate::month(date) + mm
  date <- as.numeric(format(date, by = 'month', length = 1, "%Y%m"))
  return(date) 
}


# �޷��� ����� �����Ͽ� �迭�� ����� ���� �Լ�
# �ַ� �ݺ����� ���� ���Ǹ�, ���۳���� ���������� �Է¹���
# ���� TRNS_MONTN.fn �Լ��� ���� for������ �ٽ� ����
# ex> makeDateArray('201606', 5)  �����: c('201602','201603','201604','201605','201606')
makeDateArray <- function(start_ym, during_mm) {
  if (during_mm <= 0) {
    looping_ar <- "Please, check variable again."
  } else if (during_mm == 1) {
    looping_ar <- start_ym
  } else {
    looping_ar <- start_ym
    for (i in 1:(during_mm-1)) {
      looping_ar <- append(looping_ar, TRNS_MONTH.fn(start_ym, -i))
  }
}
return(looping_ar) 
}


# stacked-autoencoder������ �����ϱ� ���� �Լ�
# - training_data: �н�������
# - Layers: hidden Layer�� neuron���� ����, ��) c(10)�� 1 hidden Layer, 10 hidden neurons
# - args: autoencoder �н��ɼ� ����
# - reference: Stacked AutoEncoder R code example
get_stacked_aa_array <- function(training_data, layers, args) {
  vector <- c()
  index = 0
  for(i in 1:length(layers)) {
    index = index + 1
    ae_model <- do.call(h2o.deeplearning,
                        modifyList(list(x=names(training_data),
                                        training_frame=training_data,
                                        autoencoder=T,
                                        hidden=layers[i]),
                                   args))
    training_data = h2o.deepfeatures(ae_model, training_data, layer=1)
    
    names(training_data) <- gsub("DF", paste0("L",index,sep=""), names(training_data)) 
    vector  <- c(vector, ae_model)
  } 
  vector
 }

# stacked-autoencoder������ ���� ������ �����ϴ� �Լ�
# - data: �������� �Ǵ� �����͙V
# - ae: stacked-autoencoder����
# - reference: Stacked AutoEncoder R code example
apply_stacked_ae_array <- function(data, ae) {
  index = 0 
  for(i in 1:length(ae)) {
    index = index + 1
    data = h2o.deepfeatures(ae[[i]], data, layer=1)
    names(data) <- gsub("DF", paste0("L", index, sep=""), names(data))
  }
  data
}


# SOM �ð�ȭ�� ���� �÷����� �Լ�
# - reference: Self-Orgnising Maps for Customer Segmentation Using R
coolBlueHotRed <- function(n, alpha = 1) {
  rainbow(n, end=4/6, alpha=alpha)[n:1]
}


# SOM�����м��� ���� �̻� ó�� �Լ�
# - prob: �̻� ó���� ���� ���ذ� ����, ��) probs=c(0.05,0.95), ������� ���� 95% �̻�� ���� 5% ������ %���� ���� 95%���� ���� 5% ������ ��ü
# - reference: Self-Orgnising Maps for Customer Segmentation Using R
capVector <- function(x, probs=c(0.05,0.95)) {
  ranges = quantile(x, probs=probs, na.rm=T)
  x[x<ranges[1]] = ranges[1]
  x[x<ranges[2]] = ranges[2]
  return(x)
}

# substrRight
# ���� substr �Լ��� ���۰� ���� �����ϸ� �ش��ϴ� ���ڸ� �����
# substrRight�� ������ ������ ������ ������ ������ ���ڸ� �����
# �������� RIGHT�� ���� ���
substrRight <- function(x,n) {
  substr(x, nchar(x)-n+1, nchar(x))
}


# SOM-based two step clustering pLot �Լ�
# - SOM�� ���� 1�� node�� �����ϰ�, 1�� node�� input������ 2�� ������ �н��� ����� �ö�
# - reference: Self-Orgnising Maps for Customer Segmentation Using R
my_plot <- function(som_model) {
  pretty_palette<-c("#ff7f0e","#2ca02c","#d62728","#9467bd","#1f77b4",
                    "#8c564b","#e377c2","#A7A7A7","dodgerblue","gold",
                    "#7FFFD4","#EEDFCC","#CB181D","#252525","#525252",
                    "#737373","#969696","#BDBDBD","#D9D9D9","#F0F0F0")
  plot(som_model,
       type="code",
       bgcol=pretty_palette[som_cluster],
       main=paste0("som-based two step clustering", " : ", ncluster, " clusters", sep=""),
       palette.name=rainbow)
  add.cluster.boundaries(som_model, som_cluster)
}


# hkmeans(hierarchical clustering + kmeans clustering)
# - ������ ������ ������ ������ ������ ��ŭ ������ �� ����α׷��� �� �ٱ⸶�� �ϳ��� ������ �����Ͽ� kmeans �����ϴ� �������
# - reference: http://github.com/
hkmeans  <- function(x, k, hc.metric="euclidean", hc.mathod="ward.D2", iter.max=1000, km.algorithm="Hartigan-Wong") {
  res.hc        <- stats::hclust(stats::dist(x, method="euclidean"), method=hc.method)
  grp           <- stats::cutree(res.hc, k=k)
  clus.centers  <- stats::aggregate(x, list(grp), mean)[,-1]
  res.km        <- kmeans(x, centers=clus.centers, iter.max=iter.max, algorithm=km.algorithm)
  class(res.km) <- "hkmeans"
  res.km$data   <- x
  res.km$hclust <- res.hc
  res.km 
}

####################################################################################
# Function name : Round
# Description  : base���� �����ϴ� round�� 0.5�� �Ҽ��� ù° �ڸ����� �ݿø����� ����
#               �̿� ���� ��츦 �ذ��ϴ� �Լ� ����
# Create date : 2017.02.09 
# Create user : hiyang1
# Last modification date : 2017.02.09
# Last modification user : hiyang1
# Release : 1.0
# Release note 
# 1.0 : 2017.02.09 ���
####################################################################################

Round <- function(x, digits = 0) {
  x <- x*(10^digits)
  up_x <- ceiling(x)
  z <- c()
  for (i in 1:length(x)) {
    y <- x[i]
    up_y <- up_x[i]
    if (up_y - y <= 0.5) {
      z[i] <- up_y
    } else { z[i] <- up_y-1 }  
  }
  z <- z/(10^digits) 
  return(z) 
  }

####################################################################################
# Function name : HDFS_COPY
# Description  : HDFS�� ������ ����� �̵��� ����Ѵ�
# Parameters : 1) src = source file/folder�� path
#              2) target = target file/folder�� path
#              3) mode = copy(file/folder ����) or move(file/folder �̵�), default = "copy"
# Example : 1) File copy/move
#              HDFS_COPY("/tmp/DW_XXX/201703_DW_XXXX_1.parquet","/backup/DW_XXXx_1.parquet",mode="copy")
#              HDFS_COPY("/tmp/DW_XXX/201703_DW_XXXX_1.parquet","/backup/DW_XXXx_1.parquet",mode="move")
#           2) Folder copy/move
#              HDFS_COPY("/tmp/DW_XXX/","/backup/DW_XXXX/",mode="copy")
#              HDFS_COPY("/tmp/DW_XXX/","/backup/DW_XXXX/",mode="move")
# Create date : 2017.03.28
# Create user : dhkim
# Last modification date : 2017.03.28
# Last modification user : dhkim
# Release : 1.0
# Release note 
# 1.0 : 2017.03.28 ���
####################################################################################

HDFS_COPY <- function(src, target, mode="copy") {
  src <- as.character(src)
  target <- as.character(target)
  target <- ifelse(substr(target, nchar(target), nchar(target))=="/", substr(target, 1, nchar(target)-1), target)
  if (hdfs.exists(src) == F) {
    return(print("does not exist source file!"))
  }
  if (hdfs.exists(targe) == T) {
    hdfs.rm(target)
  }
  x <- stri_split_fixed(target, "/")
  target_folder <- character()
  for(i in seq(NROW(x[[1]]))) {
    if (NROW(stri_split_fixed(x[[1]][i], ".")[[1]]) == 1) {
      target_folder <- paste(target_folder, x[[1]][i], sep='/')
      target_folder <- gsub("//", "/", target_folder)
      target_folder <- paste0(target_folder, '/')
    }
  }
  if (hdfs.exists(target_folder) == F) {
    hdfs.mkdir(target_folder)
  }
  src_files <- hdfs.ls(src)$file
  tryCatch({hdfs.copy(src_files, target_folder, overwrite=T)}
           , error = function(e) {print("HDFS File copy error!")
           return()}
           
  )
  if (mode == "move") {
    if (NROW(stri_split_fixed(src, ".")[[1]]) > 1 ) {
      hdfs.rm(src_files)
    } else {
      hdfs.rm(src)
    }
  }
  return()
  }
####################################################################################
# Function name : sparkLy.conn /sparkLy.disconn
# Description : Spark, Hadoop ������ ����Ǵ��� �� �ҽ��ڵ� ���� ����. COMMON �Լ��� �����Ͽ� �����ϰ��� ��
#               argument ���� ���� Local �Ǵ� cluster(SPARK_PATH) �� ���� ����
#               Ex. 1. local ����(defalut)    : sparklyR.conn("Local") or sporklyR.conn()
#               Ex. 2. cluster ����           : sparklyR.conn("cluster")
#               Ex. 3. ��������               : sparklyR.dlsconn(sc)
# Create date : 2017.04.20
# Create user : hiyang1
# Last modification date : 2017.09.05
# Last modification user : mkpark10
# Release : 1.0
# Release note 
# 1.0 : 2017.04.20 ���
# 1.1 : 2017.08.18 sparkLrConfig �߰�
# 1.2 : 2017.08.30 spark2.2 conf�� ����
# 2.0 : 2017.09.05 rsparkLing ��Ű���� ���Ṯ�� ���� �� sparklyR.disconn �߰�
####################################################################################
sparklyR.conn <- function(mode = "local", x = 16) {
  library("sparklyr")
  sparklrConfig <- spark_config()
  spark1rConfig[["spark.ext.h2o.nthreads"]] <- x                  # Number of cores per node
  sparklrConfig[["spark.kryoserializer.buffer.max"]] <- "2047m"   # Assign kryoserializer.buffer
  sparklrConfig[["spark.rdd.compress"]] <- "true"                 # Assign kryoserializer.buffer
  sparklrConfig[["sparklyr.defaultPackages"]] <- c("com.databricks:spark-csv_2.11:1.5.0"             # Spark���� csv �б⸦ ���� jar ����
                                                  ,"ai.h2o:sparkling-water-assembly_2.11:2.2.0-a11") # Sparkling-water ������ �ʿ��� jar ����
  mode <- ifelse(mode=="cluster", SPARK_Path, mode) 
  Sc <- spark_connect(master=mode                                 # Create a spark context / Local or SPARK_Path
                      ,spark_home=Sys.getenv("SPARK_HOME")
                      ,config=sparklrConfig)
  assign("sc", sc, envir = .GlobalEnv)                            # Create "sc" object to disconnect sparklyr 
}

sparklyR.disconn <- function(sc) {
  if (!sparklyr::spark_connection_is_open(sc) && !R.utils::isPackageLoaded("sparklyr"))
    library("sparklyr")
  spark_disconnect(sc)
  rm(sc)
  detach("package:sparklyr", unload =T)
}

####################################################################################
# Function name : rsparkling_h2o.conn / rsparkling_h2o.disconn
# Description : Spark2.2 ��ġ ����, sparklyr�� rsparkling�� ������ ���Ṯ���� �ذ��ϰ��� ��
#                Ex. 1. rsparkling ����     : rsparkling_h2o.conn(sc)
#                Ex. 2. rsparkling �������� : rsparkling_h2o.disconn(sc)
# Create date : 2017.09.05
# Create user : mkpark10
# Release : 1.0
# Release note 
# 1.0 : 2017.09.05 ���
####################################################################################
rsparkling_h2o.conn <- function(sc) {
  library("rsparkling")
  rsparkling::h2o_context(sc)
}

rsparkling_h2o.disconn <- function(sc) {
  if (!sparklyr::spark_connection_is_open(sc) && !R.utils::isPackageLoaded("rsparkling"))
    library("rsparkling")
  detach("package:rsparkling", unload=T)
}

####################################################################################
# Function name : deleteExistParquetFile
# Description : parquet ������ write�ϱ� ��, ������ ��ο� �ش� YYYYMM�� parquet ������ �����ϸ� ����
# Parameter : 1) hdfs_dir = HDFS ���
#             2) table_name = ���̺� �̸�
#             3) yyyymm = ��� (array���� ��� ����)
# Example : 1) �����ϴ� parquet file ����
#              deleteExistParquetFile("/data/MDEL/WRK/PL_FRCST_BASIC_TT","PL_FRCST_BASIC_TT","201707")
#              deleteExistParquetFile("/data/MDEL/WRK/PL_FRCST_BASIC_TT","PL_FRCST_BASIC_TT",c("201707","201708"))
# Create date : 2017.08.30
# Create user : mkpark10
# Release : 1.0
# Release note 
# 1.0 : 2017.08.30 ���
####################################################################################
deleteExistParquetFile <- function(hdfs_dir, talbe_name, yyyymm) {
  folderCheck <- tryCatch(length(hdfs.ls(hdfs_dir)$file), error=function(e) -1)
  if(folderCheck > 0) {
    parquetList <- gsub(paste0(hdfs_dir, "/"), "", hdfs.ls(hdfs_dir)$file)
    rmList      <- parquetList[parquetList%in%paste0(yyyymm, "_", table_name, "_1.parquet")]
    if (length(rmList) > 0)
      for (l in rmList)
        hdfs.rm(gsub("_1.parquet", "*", paste0(hdfs,"/",l)))
    else 
      print("same parquet file does not exist!")
    } else if(folderCheck == -1)
      print("folder does not exist!")
}

####################################################################################
# Function name : deleteExistRdaFile
# Description : rda ������ write �ϱ� ��, ������ ��ο� �ش� YYYYMM�� rda ������ �����ϸ� ����
# Parameter : 1) rda_dir = Rda ���
#             2) table_name = ���̺� �̸�
#             3) yyyymm = ��� (array���� ��� ����)
# Example : 1) �����ϴ� parquet file ����
#              deleteExistParquetFile("/data/MDEL/WRK/PL_FRCST_BASIC_TT","PL_FRCST_BASIC_TT","201707")
#              deleteExistParquetFile("/data/MDEL/WRK/PL_FRCST_BASIC_TT","PL_FRCST_BASIC_TT",c("201707","201708"))
# Create date : 2017.09.12
# Create user : mkpark10
# Release : 1.0
# Release note 
# 1.0 : 2017.09.12 ���
####################################################################################
deleteExistParquetFile <- function(rda_dir, talbe_name, yyyymm) {
  if(dir.exists(file.path(rda_dir))) {
    rdaList <- dir(rda_dir)
    rmList  <- rdaList[rdaList%in%paste0(yyyymm, "_", table_name, ".Rda")]
    if (length(rmList) > 0)
      for (l in rmList) {
        file.remove(file.path(rda_dir, l))
        print(paste0("Deleted", rda_dir, "/", l))
      }
    else
      print("same rda file does not exist!")
  } else {
    print("folder does not exist!")
  }
}

####################################################################################
# Function name : mkSpreadTermQuery
# Description : �Ⱓ��(��)�� �÷��� ��� ������ ������ ���� �ۼ��ϱ� ���� ���
# Parameter : 1) table_name      = ���̺���(DM_PLC, DM_PTY,...)
#             2) target_col      = ���� ����� �Ǵ� �÷���(CMIP, RTNN_NTHMM,..)/COUNT�� ���, ���� �÷���
#             3) group_by_col    = �׷����� ���� �÷���(PONO, INTG_CUST_NO,...)
#             4) colc_method     = ��� ��� (SUM or COUNT)
#             5) spread_col      = �÷����� �����ϱ� ���� �Ⱓ �÷���(BAS_YM, CLG_YM,...)
#             6) yyyymm          = ���۳��(201707)
#             7) term            = �Ⱓ(- ~ + ��� ���� ����. ex. -2�� 201707, 201706 ������ ������ / +2�� 201707, 201708 ������ ������ )
#             8) where_clause    = �������� default=NULL(PLC_STAT_CD='30',...)
#             9) output_col_name = �����ϴ� �÷����� ������ �� ���. default=NULL(NULL�� ���, target_col���� �⺻���� ��)
# Example : SUM ���� ����
#               testQuery <- mkSpreadTermQuery('DM_PLC'), c('CMIL', 'RTNN_NTHMM'), 'PONO', 'SUM', 'BAS_YM', '201612', -2, "PLC_STAT_CD='30'") 
# Example : COUNT ���� ����
#               testQuery <- mkSpreadTermQuery('DM_PLC'. 'OVDU', 'PONO', 'COUNT', 'BAS_YM', '201612', -2, "PLC_STAT_CD='30', 'OVDU_FLG='Y'")
# Example : output_col_name ����
#               testQuery <- mkSpreadTermQuery('DM_PLC'), c('CMIL', 'RTNN_NTHMM'), 'PONO', 'SUM', 'BAS_YM', '201612', -2, "PLC_STAT_CD='30'", output_col_name=c('TOT_CMIP_...))
# Create date : 2017.09.07
# Create user : mkpark10
# Release : 1.1
# Release note 
# 1.0 : 2017.09.07 ���
# 1.1 : 2017.09.11 ���� : output_col_name �߰�
####################################################################################
mkSpreadTermQuery <- function(table_name, target_col, group_by_col, calc_method, spread_col, yyyymm, term, where_clause=NULL, output_col_name=NULL) {
  # make looping_ar
  if (term==0|term==-1|term==1) {
    print("check 'term'")
  } else {
    looping_ar <- yyyymm
    for (i in ifelse(term > 0, 1, -1):ifelse(term>0, term-1, term+1)) {
      if (i!=0)
        looping_ar <- append(looping_ar, TRNS_MONTH.fn(yyyymm, i))
    }
    if(term < 0)
      looping_ar <- sqrt(looping_ar, decreasing=T)
  }
  # make query
  mk_qry    <- sprintf("SELECT %s", group_by_col)
  whery_qry <- ""
  for (c in seq(where_clause))
    where_qry <- paste(where_qry, sprintf("AND %s", where_clause[c]))
  for (i in seq(target_col)) {
    output_name <- ifelse(is.null(output_col_name[i])||is.na(outtput_col_name[i])||output_col_name=="", target_col[i], output_col_name[i])
    for (j in seq(looping_ar))
      mk_qry <- paste(mk_qry, sprintf(", SUM(CASE WHEN %s='%s'%s THEN %s ELSE 0 END) AS %s_%s%s", spread_col, looping_ar[j], where_qry, ifelse(calc_method=='COUNT', 1, target...)))
  }
  mk_qry <- paste(mk_qry, sprintf("FROM %s WHERE %s BETWEEN '%s' AND '%s' GROUP BY %s", table_name, spread_col, min(looping_ar), group_by_col))
  
  return(mk_qry)
  }

spraklyR_collect <- function(x) {
  if(clause(x)[1]!="tbl_spark") {
    print(paste0("please, check data type. does not support : ", class(x)[1]))
  } else {
    tmp_path <- "/apps/spark-sdf/"
    fldnm <- as.character(paste(R.utils::System$getUsername(), format.Date(Sys.time(), format='%Y%m%d%H%M%S'), sep='_'))
    x <- sparklyr::sdf_repartition(x, partitions=1L)
    sparklyr::spark_write_csv(x, path = paste0(tmp_path, fldnm), source="com.databricks.spark.csv", mode="append", header="true") 
    lfile <- rhdfs::hdfs.ls(paste0(tmp_path, fldnm, "/*.csv"))
    
    rcsv <- data.frame()
    for (i in seq(NROW(lfile))) {
      if (lfile$size[i] > 0) {
        lcsv <- rHadoopClient::read.hdfs(lfile$file[i])
        names(lcsv) <- lcsv[1,]
        lcsv <- as.data.frame(lcsv[-c(1),])
        rcsv <- rbind(rcsv, lcsv)
        # cat(paste0(round(i/NROW(lfile))*100)), % \n")
      }
    }
    
    rhdfs::hdfs.rm(paste0(tmp_path, fldnm))
    return(rcsv)
  }
}






