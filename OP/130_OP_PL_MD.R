# ---
# title   : 130_OP_PL_MD
# version : 1.0
# author  : 2e consulting
# desc.   : OP �̰� �� ���������̺�(TT) ����
# ---

#-------------------
# PL_PLC DM�̰�
#-------------------
# ���� ���̺� �� ��ġ ����
WRK_table <- "OP_PL_PLC_TT"
WRK_dir   <- file.path(gsub(HDFS_Path,"",MDEL_WRK_Path),WRK_table)

DM_table  <- "OP_PL_PLC_BASIC"
DM_dir    <- file.path(gsub(HDFS_Path,"",MDEL_PL_Path),DM_table)

# ���� parquet ���� ����
deleteExistParquetFile(DM_dir, DM_table, looping_ar)

# WRK���� MDEL�� DM �̰�
src <- grep(".parquet", hdfs.ls(WRK_dir)$file, value=TRUE)
dest <- gsub(WRK_table, DM_table, gsub(WRK_dir, DM_dir, src))
for(p in seq(src)) hdfs.mv(src=src[p], dest=dest[p])

# ������ ���̺��� ���ؼ� ����ڵ��� ���� �߰�
if(isTRUE(chmod_777)) system(paste0("hdfs dfs -chmod -R 777 ", MDEL_PL_Path,"/",DM_table))

# ���õ� ��� ������ ���̺� ����
hdfs.rm(WRK_dir)
print(paste0("<<< ",DM_table," - DONE!! >>>"))

# delete table name, dir path
rm(WRK_table)
rm(WRK_dir)
rm(DM_table)
rm(DM_dir)

#-------------------
# PL_PTY DM�̰�
#-------------------
# ���� ���̺� �� ��ġ ����
WRK_table <- "OP_PL_PTY_TT"
WRK_dir   <- file.path(gsub(HDFS_Path,"",MDEL_WRK_Path),WRK_table)

DM_table  <- "OP_PL_PTY_BASIC"
DM_dir    <- file.path(gsub(HDFS_Path,"",MDEL_PL_Path),DM_table)

# ���� parquet ���� ����
deleteExistParquetFile(DM_dir, DM_table, looping_ar)

# WRK���� MDEL�� DM �̰�
src <- grep(".parquet", hdfs.ls(WRK_dir)$file, value=TRUE)
dest <- gsub(WRK_table, DM_table, gsub(WRK_dir, DM_dir, src))
for(p in seq(src)) hdfs.mv(src=src[p], dest=dest[p])

# ������ ���̺��� ���ؼ� ����ڵ��� ���� �߰�
if(isTRUE(chmod_777)) system(paste0("hdfs dfs -chmod -R 777 ", MDEL_PL_Path,"/",DM_table))

# ���õ� ��� ������ ���̺� ����
hdfs.rm(WRK_dir)
print(paste0("<<< ",DM_table," - DONE!! >>>"))

# delete table name, dir path
rm(WRK_table)
rm(WRK_dir)
rm(DM_table)
rm(DM_dir)


