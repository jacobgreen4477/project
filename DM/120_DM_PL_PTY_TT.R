# ---
# title   : 120_DM_PL_PTY_TT
# version : 1.0
# author  : 2e consulting
# desc.   : [�������̺�] DM_PL_PTY ������ ���� ������ ���̺�
# ---

# <<<<!---DM ���� ���ø� ������ ���� ��� ���ø� �ڵ� �ۼ�---!>>>

# <<Data Load>> ----------------------------------
# Read HDFS Table 
readTablesFromSpark(S_EDW_Path, c("CO_CLG_YM"              # �������
                                  ,"CO_DATE"                # CD �����ڵ�
                                  ,"CD_JBKND"               # �����ڵ�
                                  ,"CO_OCPN_CD"             # CD_�����ڵ�
                                  ,"CD_RL"                  # �����ڵ�
                                  ,"CD_SALE_CHNL"           # �Ǹ�ä���ڵ�
                                  ,"DM_FC_BASIC"            # FC�⺻
                                  ,"DM_FC_STAT"             # FC���� 
                                  ,"DM_MKTG_PROD_GRP"       # �����û�ǰ�׷�
                                  ,"DM_PLC"                 # ���
                                  ,"DM_PTY"                 # �����
                                  ,"DW_AUTO_TRSF"           # �ڵ���ü
                                  ,"DW_AUTO_TRSF_CNLT_DES"  # �ڵ���ü�������� 
                                  ,"DW_CUST_ACNT_RL"        # �������°���
                                  ,"DW_INS"                 # ����
                                  ,"DW_INS_PROD"            # �����ǰ 
                                  ,"DW_INSD"                # �Ǻ�����
                                  ,"DW_OWN_PLC"             # ���ΰ��
                                  ,"DW_PERPLC_DPS_TRNS_CLG" # ��ະ�Ա�TX��������
                                  ,"DW_PL"                  # ���������
                                  ,"DW_PL_MM_CLG"           # ��������������
                                  ,"DW_PL_BALC_MM_CLG"      # ����������ܰ�������
                                  ,"DW_PLC_TRNS_DES"        # ���ŷ�����
                                  ,"DW_PYM_MM_CLG"          # ���޿�����
                                  ,"DW_PYM_TRNS"            # ���ްŷ�
                                  ,"FT_CLAIM"               # FTû��
                                  ,"FT_PLC"                 # FT���
                                  ,"FT_PLC_PYMT"            # FT��ೳ��
                                  ,"FT_VR_PLC"              # FT���װ��
                                  ,"AC_MEND_RSV"            # AC�����غ��
                                  ,"DW_INS_PLC_LOAN_INTRT"  # DW�������������
                                  ,"DW_PAID_PRM_VRF"        # DW���
                                  ,"DW_PRINSU_PYM_TRNS_DES" # DW�����ŷ�����
                                  ,"DW_EXRT_MGMT"           # ȯ������
                                  
))

# set timestamp(��¥������ TIMESTAMP Ÿ������ ��ȯ)
castToTimestamp(S_EDW_Path,"CO_CLG_YM",c("CLG_ST_DATE","CLG_END_DATE"))
castToTimestamp(S_EDW_Path,"DW_CNTCT","CNTCT_ST_DTTM")
castToTimestamp(S_EDW_Path,"DW_CUST_INFO_CHG_DES","HSTY_EFTV_END_DTTM")     
castToTimestamp(S_EDW_Path,"DW_PYM_TRNS","PYM_DATE")
castToTimestamp(S_EDW_Path,"FT_PLC",c("LST_PLC_TRSF_DATE","LST_RNL_DATE"))     
castToTimestamp(S_EDW_Path,"TBL_CNSL_HSTR","CNSL_DTM")    

for(i in 1:length(looping_ar)){
  
  # --------------------------
  # set the time variables
  v_BAS_YM1    <- looping_ar[i]                    # ���س��  (M����)
  v_BAS_YM12   <- TRNS_MONTH.fn(V_BAS_YM1, -11)    # ���س��12(M-11����)
  v_FRCST_YM1  <- TRNS_MONTH.fn(V_BAS_YM1, +1)     # �������12(M+1����)
  v_FRCST_YM2  <- TRNS_MONTH.fn(V_BAS_YM1, +2)     # �������12(M+2����)
  
  # --------------------------
  # create DRIVING_TABLE
  PL_DRIVING_TABLE_TT <- SparkR::sql(paste0("
      SELECT      A1.BAS_YM                                                              /*���س��*/
                 ,A1.PONO                                                                /*���ǹ�ȣ*/
                 ,CASE WHEN A2.PYM_TIMES IS NULL
                       THEN 'N'
                  ELSE 'Y' END                                   AS PL_FLG               /*���⿩��(TARGET)*/
                 ,A1.PLHD_INTG_CUST_NO                                                   /*��������հ�����ȣ*/
                 ,A1.MINSD_INTG_CUST_NO                                                  /*���Ǻ��������հ�����ȣ*/
                 ,A1.SLFC_NO                                                             /*����FC��ȣ*/
                 ,A1.SVFC_NO                                                             /*����FC��ȣ*/
      FROM        DM_PLC A1
      LEFT OUTER JOIN (
          SELECT  '",v_BAS_YM1,"'                                AS BAS_YM               /*���س��*/
                  ,B1.PONO                                                               /*���ǹ�ȣ*/
                  ,COUNT(B3.PYM_DATE)                            AS PYM_TIMES            /*����Ƚ��*/
          FROM (
               SELECT  PYM_TRNS_ID
                      ,PONO
               FROM    DW_PYM_TRNS
               WHERE   PYM_PRC_CD       = 'TPL0'                                         /*����ó�� : ��������*/
                 AND   PYM_PRC_DETL_CD  IN ('PL0100','PL0200)                            /*���ްŷ��� : ���������(�ű�,�߰�)*/
                 AND   DATE_FORMAT(PYM_DATE, 'yyyyMM')                                   /*�������ڱ���*/
                       BETWEEN '",v_FRCST_YM1,"' AND '",v_FRCST_YM2,"'                   /*���������� M+1~M+2����*/
               EXCEPT
               SELECT  REF_TRNS_ID
                      ,PONO
               FROM    DW_PYM_TNS                                                        /*������� ���ްŷ����� ����*/
               WHERE   PYM_PRC_CD       = 'TPL4'                                         /*����ó�� : �������*/
               AND     PYM_PRC_DETL_CD  IN ('PL0100','PL0200)                            /*���ްŷ��� : ���������(�ű�,�߰�)*/
               ) B1
               INNER JOIN DW_PYM_TRNS B2
                       ON B1.PYM_TRNS_ID    = B2.PYM_TRNS_ID
                      AND B1.PONO           = B2.PONO
               GROUP BY   B1.PONO
      ) A2
                    ON  A1.BAS_YM            = A2.BAS_YM
                   AND  A1.PONO              = A2.PONO
      INNER JOIN  DW_INS_PROD A3
              ON  A1.PROD_CD           = A3.PROD_CD
             AND  A1.PROD_VER_CD       = A3.PROD_VER_CD
      INNER JOIN  DW_PL A4
              ON  A1.PONO              = A4.PONO
      INNER JOIN  DM_PTY A5
              ON  A1.BAS_YM            = A5.BAS_YM
             AND  A1.PLHD_INTG_CUST_NO = A5.INTG_CUST_NO
      INNER JOIN  DM_FC_BASIC A6
              ON  A1.BAS_YM            = A6.BAS_YM
             AND  A1.SVFC_NO           = A6.FC_NO
      WHERE       A1.BAS_YM            = '",v_BAS_YM1,"'                                 /*���س��*/
        AND      (A1.PLC_STAT_CD       = '30'                                            /*�����°� ������ ���*/
                  OR (A1.PLC_STAT_CD   = '40'                                            /*�����°� ��ȿ�̸鼭�� ���Ⱑ���� ��ǰ �߰�*/
                      AND A1.FST_PLC_DATE < '2005-04-01'))                               /*����û������ 2005-04-01 ������ ��ȿ������ ���*/
        AND       A1.PYMT_STAT_CD      != '06'                                           /*�Աݻ��� �������Ը���(06) ����*/
        AND      !(A1.FST_PLC_DATE     < '2007-11-26'                  
                   AND A3.PROD_REPT_TYP_CD LIKE '%V%')                                   /*����û������ 2007-11-26 �����̸� ��ǰ�����������ڵ忡 V�� ���Ե� ��� ����*/
        AND       A3.PL_PSB_TYP_CD     != '01'                                           /*�������Ұ� ��ǰ ����*/
        AND       A4.PL_TYP_CD         = '01'                                            /*���������(APL����)*/
        AND       A5.CUST_DETL_TYP_CD  IN ('11','12','22')                               /*�����������ڵ�. ������(11),�ܱ���(12),���λ����(22)*/
        AND      !(A1.SFPLC_FLG        = 'Y'                                             /*����Ȱ������FC���ΰ�� ����*/
                   AND A6.FC_STAT_CD   = '1')
     "))
  createOrReplaceTempView(PL_DRIVING_TABLE_TT,"PL_DRIVING_TABLE_TT")
  
  # ���������� �籸��
  PL_DRIVING_TABLE <- SparkR::sql(paste0("
      SELECT    A1.BAS_YM                                                                /*���س��*/
               ,A1.PLHD_INTG_CUST_NO                                                     /*��������հ�����ȣ*/
      FROM      PL_DRIVING_TABLE_TT A1
      GROUP BY  A1.BAS_YM
               ,A1.PLHD_INTG_CUST_NO
  "))
  
  # --------------------------
  # Create Temp Table(1)
  PTY_ATTR_TT_01 <- SparkR::sql(paste0("
   SELECT     A1.BAS_YM                                                                   /*���س��*/
             ,A1.PLHD_INTG_CUST_NO                         AS INTG_CUST_NO                /*��������հ�����ȣ*/
             ,SUM(CASE WHEN A1.PLC_STAT_CD = '30'
                       THEN 1
                  ELSE      0 END)                         AS INPLC_CNT                   /*�������Ǽ�*/
             ,SUM(CASE WHEN A1.PLC_STAT_CD = '40'
                       THEN 1
                  ELSE      0 END)                         AS LPS_PLC_CNT                 /*��ȿ���Ǽ�*/
             ,SUM(CASE WHEN A1.PLC_STAT_CD = '50'
                       THEN 1
                  ELSE      0 END)                         AS CNPLC_CNT                   /*�ؾ���Ǽ�*/
             ,SUM(CASE WHEN A1.PLC_STAT_CD = '14'
                       THEN 1
                  ELSE      0 END)                         AS APP_RJT_CNT                 /*û��������Ǽ�*/
             ,SUM(CASE WHEN A1.PLC_STAT_CD IN ('16','18)
                       THEN 1
                  ELSE      0 END)                         AS WTDAL_PLC_CNT               /*û��öȸ���Ǽ�*/
             ,SUM(CASE WHEN A1.PLC_STAT_CD = '52' AND A1.CNLT_RSN_CD = '111'
                       THEN 1
                  ELSE      0 END)                         AS QUALY_GRTE_CNLT_CNT         /*ǰ�������������Ǽ�*/
             ,SUM(CASE WHEN A1.PLC_STAT_CD = '52' AND A1.CNLT_RSN_CD = '112'
                       THEN 1
                  ELSE      0 END)                         AS APEAL_CNPLC_CNT             /*�ο��������Ǽ�*/
             ,SUM(CASE WHEN A1.PLC_STAT_CD NOT IN ('14','16','18','30','40','50','52')
                       THEN 1
                  ELSE      0 END)                         AS OT_PLC_CNT                  /*��Ÿ���Ǽ�*/
   FROM       DM_PLC A1
   WHERE      A1.BAS_YM    = '",v_BAS_YM1,"'
   GROUP BY   A1.BAS_YM
             ,A1.PLHD_INTG_CUST_NO
  "))
  
  # --------------------------
  # ���Ӽ�TT - ����
  createOrRplaceTempView(PL_DRIVING_TABLE,"PL_DRIVING_TABLE")
  createOrRplaceTempView(PTY_ATTR_TT_01,"PTY_ATTR_TT_01")
  
  # ������_TT
  PL_PTY_TT <- SparkR::sql(paste0("
     SELECT       A1.BAS_YM                           
                 ,A1.PLHD_INTG_CUST_NO
                 ,CAST(A2.INPLC_CNT               AS DOUBLE) AS INPLC_CNT                /*�������Ǽ�*/
                 ,CAST(A2.LPS_PLC_CNT             AS DOUBLE) AS LPS_PLC_CNT              /*��ȿ���Ǽ�*/
                 ,CAST(A2.CNPLC_CNT               AS DOUBLE) AS CNPLC_CNT                /*�ؾ���Ǽ�*/
                 ,CAST(A2.APP_RJT_CNT             AS DOUBLE) AS APP_RJT_CNT              /*û��������Ǽ�*/
                 ,CAST(A2.WTDAL_PLC_CNT           AS DOUBLE) AS WTDAL_PLC_CNT            /*û��öȸ���Ǽ�*/
                 ,CAST(A2.QUALY_GRTE_CNLT_CNT     AS DOUBLE) AS QUALY_GRTE_CNLT_CNT      /*ǰ�������������Ǽ�*/
                 ,CAST(A2.APEAL_CNPLC_CNT         AS DOUBLE) AS APEAL_CNPLC_CNT          /*�ο��������Ǽ�*/
                 ,CAST(A2.OT_PLC_CNT              AS DOUBLE) AS OT_PLC_CNT               /*��Ÿ���Ǽ�*/

     FROM        PL_DRIVING_TABLE A1
     INNER JOIN  PLC_ATTR_TT_01  A2
             ON  A1.BAS_YM                            = A2.BAS_YM
            AND  A1.PLHD_INTG_CUST_NO                 = A2.INTG_CUST_NO

     WHERE       A1.BAS_YM               = '",v_BAS_YM1,"'
     ORDER BY    A1.PLHD_INTG_CUST_NO
                                        
                                        "))
  
  # --------------------------
  # Save to HDFS parquet
  WRK_table   <- "PL_PTY_TT"
  WRK_dir     <- file.path(gsub(HDFS_Path,"",MDEL_WRK_Path),WRK_table)
  
  # ���� parquet���� ���� 
  deleteExistParquetFile(WRK_dir, WRK_table, looping_ar[i])
  
  # parquet ���� ����
  print(paste0("<< NOW : ",WRK_table," - ",looping_ar[i]," >>"))
  PL_PTY_TT  <- repartition(PL_PTY_TT, numPartitions=1L)
  
  write.df(PL_PTY_TT,WRK_dir, source ='parquet', mode='append')
  
  # ����� parquet ���ϸ� �����ϱ�
  src <- grep(".snappy.parquet", hdfs.ls(WRK_dir)[hdfs.ls(WRK_dir)$modtime%in%max(hdfs.ls(WRK_dir)$modtime)]$file, value=TRUE)
  dest <- paste0(WRK_dir,'/',looping_ar[i],'_',WRK_table,'_',seq(src),'.parquet')
  for(p in seq(src)) hdfs.rename(src=src[p], dest=dest[p])
}

# chmod
system(paste0("hdfs dfs -chmod -R 777 ",MDEL_WRK_Path,"/",WRK_table))

print(paste0("<<< ",WRK_table," - DONE!! >>>"))