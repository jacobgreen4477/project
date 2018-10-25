# Path
# path�� �̿��� ��� R�ڵ带 �ۼ� ���� 
# IP�� �۾� ��ġ ���� ��, Path���� �ϳ��� ��Ʈ���Ͽ� �ϰ� �����ϵ��� ��

# R���� ���� File Path
RDA_Path        <- "/data/rpjt/Rda_file"                        # R������Ʈ ���� Path - ����
RDA_EXTNL_Path  <- file.path(RDA_Path, "EXTNL_DATA")            # R������Ʈ ���� Path - �ܺε����� 

# HDFS �� SPARK Path 
HDFS_Path       <- "hdfs://SPKRBIG001:8020"                     # HDFS Path
SPARK_Path      <- "spark://SPKRBIG001:7077"                    # Spark Path

# ��� �𵨿��� ���������� ���Ǵ� HDFS Path
S_EDW_Path       <- file.path(HDFS_Path,"data/S_EDW")           # HDFS - S_EDW Path
S_RDR_ETC_Path   <- file.path(HDFS_Path,"data/S_RDR_ETC")       # HDFS - S_RDR_ETC Path
S_NCS_Path       <- file.path(HDFS_Path,"data/S_NEWCUSTOMER")   # HDFS - S_NEWCUSTOMER Path(���α�)
PTASDB_Path      <- file.path(HDFS_Path,"data/PTASDB")          # HDFS - PTASDB Path(STT&TA)
MDEL_COM_Path    <- file.path(HDFS_Path,"data/MDEL/COM")        # HDFS - MDEL - COM Path(�𵨰���)
MDEL_EXTNL_Path  <- file.path(HDFS_Path,"data/MDEL/EXTNL")      # HDFS - MDEL - EXTNL Path(�𵨿ܺε�����)
MDEL_WRK_Path    <- file.path(HDFS_Path,"data/MDEL/WRK")        # HDFS - MDEL - WRK Path(���ӽü�������)
OOZIE_Path       <- file.path(HDFS_Path,"user/oozie")           # HDFS - System - oozie Path(System ���� ������)