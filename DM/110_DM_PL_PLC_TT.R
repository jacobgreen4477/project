# ---
# title   : 110_DM_PL_PLC_TT
# version : 1.0
# author  : 2e consulting
# desc.   : [�������̺�] DM_PL_PLC ������ ���� ������ ���̺�
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
castToTimestamp(S_EDW_Path,"CO_DATE","STDATE")
castToTimestamp(S_EDW_Path,"CO_OCPN_CD","EFTV_END_DATE")     
castToTimestamp(S_EDW_Path,"DM_PLC","FST_PLC_DATE")
castToTimestamp(S_EDW_Path,"DW_AUTO_TRSF_CNLT_DES","CHG_PRC_DTTM")     
castToTimestamp(S_EDW_Path,"DW_CUST_ACNT_RL","HSTY_EFTV_END_DTTM")
castToTimestamp(S_EDW_Path,"DW_PERPLC_DPS_TRNS_CLG","DPS_DATE") 
castToTimestamp(S_EDW_Path,"DW_PL_MM_CLG",c("LST_LOAN_DATE","PYM_DATE")) 
castToTimestamp(S_EDW_Path,"DW_PYM_TRNS","PYM_DATE") 
castToTimestamp(S_EDW_Path,"DW_PRINSU_PYM","REG_DTTM") 
castToTimestamp(S_EDW_Path,"DW_EXRT_MGMT","STDATE") 


for(i in 1:length(looping_ar)){
  
  # --------------------------
  # set the time variables
  v_BAS_YM1    <- looping_ar[i]                    # ���س��  (M����)
  v_BAS_YM12   <- TRNS_MONTH.fn(V_BAS_YM1, -11)    # ���س��12(M-11����)
  v_FRCST_YM1  <- TRNS_MONTH.fn(V_BAS_YM1, +1)     # �������12(M+1����)
  v_FRCST_YM2  <- TRNS_MONTH.fn(V_BAS_YM1, +2)     # �������12(M+2����)
  
  # --------------------------
  # create DRIVING_TABLE
  PL_DRIVING_TABLE <- SparkR::sql(paste0("
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

  # --------------------------
  # Create Temp Table(1)
  PLC_ATTR_TT_01 <- SparkR::sql(paste0("
     SELECT     A1.BAS_YM                                                                   /*���س��*/
               ,A1.PONO                                                                     /*���ǹ�ȣ*/
               ,A1.CMIP                                                                     /*CMIP*/
               ,A1.MNCV_FCANT_WAMT                                                          /*�ְ�డ�Աݾ׿�ȭȯ��ݾ�*/
               ,A1.RID_FCAMT_WAMT                                                           /*Ư�డ�Աݾ׿�ȭȯ��ݾ�*/
               ,A1.PMFQY_CD                                                                 /*�����ֱ��ڵ�*/
               ,CASE WHEN A1.PYMT_STAT_CD = '00'
                     THEN 'Y'
                ELSE      'N' END                               AS PRM_PYG_FLG              /*����ᳳ���߿���*/
               ,CASE WHEN A1.PYMT_STAT_CD = '02'
                     THEN 'Y'
                ELSE      'N' END                               AS MMPD_FLG                 /*����ü����*/
               ,A1.PLC_STAT_CD                                                              /*�������ڵ�*/
               ,A1.RTNN_NTHMM                                                               *��������*/
               ,CASE WHEN A1.RBNPLC_TYP_CD = '01'
                     THEN 'N'
                ELSE      'Y' END                               AS RBNPLC_FLG               /*���ư�࿩��*/
               ,CASE WHEN A1.PLHD_PLC_AGE = 999
                     THEN NULL
                ELSE      A1.PLHD_PLC_AGE END                   AS PLHD_PLC_AGE             /*����ڰ�࿬��*/
               ,CASE WHEN A1.PLHD_CUR_AGE = 999
                     THEN NULL
                ELSE      A1.PLHD_CUR_AGE END                   AS PLHD_CUR_AGE             /*��������翬��*/
               ,A1.PLHD_GEN_CD                                                              /*����ڼ����ڵ�*/
               ,A1.PLHD_OCPN_CD                                                             /*����������ڵ�*/
               ,A1.PLHD_OCPN_RSKLVL_CD                                                      /*����������������ڵ�*/
               ,A1.MINSD_PLC_AGE                                                            /*���Ǻ����ڰ�࿬��*/
               ,A1.MINSD_GEN_CD                                                             /*���Ǻ����ڼ����ڵ�*/
               ,A1.MINSD_OCPN_CD                                                            /*���Ǻ����������ڵ�*/
               ,A1.MINSD_OCPN_RSKLVL_CD                                                     /*���Ǻ����������������ڵ�*/
               ,A1.PMPMD_CD                                                                 /*���ݹ���ڵ�*/
               ,A1.PLHD_SAME_FLG                                AS PLHD_MINSD_SAME_FLG      /*��������Ǻ����ڵ��Ͽ���*/
               ,A1.HFAMDS_APLC_FLG                                                          /*�����������뿩��*/
               ,A1.MDEXM_FLG                                                                /*�ǰ����ܿ���*/
               ,CASE WHEN A1.PLHD_CUR_AGE  = 999
                       OR A1.MINSD_CUR_AGE = 999
                       OR A4.UPP_CD_EFTV_VLU NOT IN ('TA','GA')
                     THEN NULL
                ELSE      A1.PLHD_CUR_AGE-A1.MINSD_CUR_AGE END  AS PLHD_MINSD_CUR_AGE_DIFF  /*��������Ǻ��������翬������*/
               ,A2.MNCV_PYMT_PRD_TYP_CD                                                     /*�ְ�ೳ�ԱⰣ�����ڵ�*/
               ,A2.MNCV_INS_PRD_TYP_CD                                                      /*�ְ�ຸ��Ⱓ�����ڵ�*/
               ,A2.MNCV_CMIP                                                                /*�ְ��CMIP*/
               ,A3.RID_CMIP                                                                 /*Ư��CMIP*/
               ,A3.RID_CNT                                                                  /*Ư��Ǽ�*/
               ,A4.UPP_CD_EFTV_VLU                              AS SALE_CHNL_L2_CD          /*�Ǹ�ä�η���2�ڵ�*/
               ,A5.UPP_CD_EFTV_VLU                              AS PLC_RL_L1_CD             /*�����跹��1�ڵ�*/
               ,A6.KLIA_INS_KND_CD                                                          /*����������ȸ���������ڵ�*/
               ,A6.PROD_REPT_TYP_CD                                                         /*��ǰ�����������ڵ�*/
               ,CASE WHEN A7.PROD_GRP_L3_CD IN ('P10107','P10110')
                     THEN 'Y'
                ELSE      'N' END                               AS ITSTV_PROD_FLG           /*�ݸ���������ǰ����*/
               ,A7.PROD_GRP_L2_CD                               AS MKTG_PROD_GRP_L2_CD      /*�����û�ǰ�׷췹��2�ڵ�*/
               ,A7.PROD_GRP_L3_CD                               AS MKTG_PROD_GRP_L3_CD      /*�����û�ǰ�׷췹��3�ڵ�*/
               ,A7.PROD_GRP_L4_CD                               AS MKTG_PROD_GRP_L4_CD      /*�����û�ǰ�׷췹��4�ڵ�*/
               ,A8.TRSF_HOPE_DAY                                                            /*��ü�����*/
               ,CASE WHEN A9.PONO IS NOT NULL
                     THEN 'Y'
                ELSE      'N' END                               AS FC_FAM_PLC_FLG           /*FC������࿩��*/
               ,NVL(A10.PL_BLC,0)                                                           /*�����ܾ�*/

     FROM DM_PLC A1                                                                         /*DM_���*/
     INNER JOIN(
         SELECT    B1.PONO
                  ,B1.CMIP                                      AS MNCV_CMIP                /*�ְ��CMIP*/
                  ,B1.PYMT_PRD_TYP_CD                           AS MNCV_PYMT_PRD_TYP_CD     /*�ְ�ೳ�ԱⰣ�����ڵ�*/
                  ,B1.INS_PRD_TYP_CD                            AS MNCV_INS_PRD_TYP_CD      /*�ְ�ຸ��Ⱓ�����ڵ�*/
         FROM      DW_INS B1
         WHERE     B1.BAS_YM              = '",v_BAS_YM1,"'
           AND     B1.INS_SRLNO           = 0
     ) A2
             ON A1.PONO                  = A2.PONO
     LEFT OUTER JOIN(
         SELECT    B1.PONO
                  ,SUM(B1.CMIP)                                 AS RID_CMIP                 /*Ư��CMIP*/ 
                  ,COUNT(B1.INS_SRLNO)                          AS RID_CNT                  /*Ư���*/ 
         FROM      DW_INS B1
         WHERE     B1.BAS_YM             = '",v_BAS_YM1,"'
           AND     B1.INS_SRLNO          != 0
         GROUP BY  B1.PONO
     ) A3
             ON A1.PONO                  = A3.PONO
     INNER JOIN CD_SALE_CHNL A4                                                             /*CD_�Ǹ�ä���ڵ�*/
             ON A1.SALE_CHNL_CD          = A4.CD_EFTV_VLU
     INNER JOIN CD_RL A5                                                                    /*CD_�����ڵ�*/
             ON A1.PLHD_RL_CD            = A5.CD_EFTV_VLU
     INNER JOIN DW_INS_PROD A6                                                              /*DW_�����ǰ*/
             ON A1.PROD_CD               = A6.PROD_CD
            AND A1.PROD_VER_CD           = A6.PROD_VER_CD
     INNER JOIN DM_MKTG_PROD_GRP A7                                                         /*DM_�����û�ǰ�׷�*/
             ON A6.PROD_GRP_CD           = A7.PROD_GRP_CD
     INNER JOIN FT_PLC_PYMT A8                                                              /*FT_��ೳ��*/
             ON A1.BAS_YM                = A8.BAS_YM
            AND A1.PONO                  = A8.PONO
     LEFT OUTER JOIN (
         SELECT    DISTINCT B1.PONO
         FROM      DW_OWN_PLC B1
         WHERE     B1.CLG_YM             = '",v_BAS_YM1,"'
     ) A9
             ON A1.PONO                  = A9.PONO
     LEFT OUTER JOIN (
         SELECT    B1.PONO
                  ,SUM(B1.PL_BLC)                               AS PL_BLC                   /*�����ܾ�*/
         FROM      DW_PL_BALC_MM_CLG B1
         WHERE     B1.CLG_YM             = '",v_BAS_YM1,"'
           AND     B1.PL_TYP_CD          = '01'
           AND     B1.PL_BLC             > 0
         GROUP BY  B1.PONO
     ) A10
             ON A1.PONO                  = A10.PONO
     
     WHERE     A1.BAS_YM                 = '",v_BAS_YM1,"'                                  /*���س��*/

  "))

  # --------------------------  
  # ���Ӽ�_TT - Roll_up_SUM
  # ��ȰȽ��
  PLC_ATTR_TT_SUM_query  <- mkSpreadTermQuery('DM_PLC', 'RINST_TIMES','PONO','SUM','BAS_YM',v_BAS_YM1,-12)
  PLC_ATTR_TT_SUM_01     <- SparkR::sql(PLC_ATTR_TT_SUM_query)
  # ������߰����Աݾ�
  PLC_ATTR_TT_SUM_query  <- mkSpreadTermQuery('DW_PERPLC_DPS_TRNS_CLG', 'PYMT_PRM','PONO','SUM','CLG_YM',v_BAS_YM1,-12,"DPS_PRC_CD IN ('02','03')", output_col_name="PRM_TUPMT_AMT")
  PLC_ATTR_TT_SUM_02     <- SparkR::sql(PLC_ATTR_TT_SUM_query)

  # ������ ������ �� 
  SUM_query_cnt <- 2
  
  # --------------------------
  # ���Ӽ�_TT - Roll_up_COUNT
  # ��ȿȽ��
  PLC_ATTR_TT_COUNT_query  <- mkSpreadTermQuery('DM_PLC', '1','PONO','COUNT','BAS_YM',v_BAS_YM1,-12,"PLC_STAT_CD='40'",output_col_name="LPS_TIMES")
  PLC_ATTR_TT_COUNT_01     <- SparkR::sql(PLC_ATTR_TT_COUNT_query)
  # ����ῬüȽ��
  PLC_ATTR_TT_COUNT_query  <- mkSpreadTermQuery('DM_PLC', '1','PONO','COUNT','BAS_YM',v_BAS_YM1,-12,"DPS_PRC_CD IN ('02','03')", output_col_name="PRM_OVDU_TIMES")
  PLC_ATTR_TT_COUNT_02     <- SparkR::sql(PLC_ATTR_TT_COUNT_query)
  
  # ������ ������ �� 
  COUNT_query_cnt <- 2
  
  # --------------------------
  # ���Ӽ�TT - ����
  createOrRplaceTempView(PL_DRIVING_TABLE,"PL_DRIVING_TABLE")
  createOrRplaceTempView(PLC_ATTR_TT_01,"PLC_ATTR_TT_01")
  
  # Roll_up_����(MM00~MM11) �������� ���� 
  sum_column_names    <- data.frame()
  for(j in 1:SUM_query_cnt){
    n <- ifelse(nchar(j)==1, paste0("0",j),j)
    eval(parse(text=paste0("createOrReplaceTempView(PLC_ATTR_TT_SUM_",n,", 'PLC_ATTR_TT_SUM_",n,"')")))
    eval(parse(text=paste0("sum_column_names <- rbind(sum_column_names,data.frame(table='PLC_ATTR_TT_SUM_"
                           ,n,"',column=columns(PLC_ATTR_TT_SUM_",n,")))")))
  }
  count_column_names  <- data.frame()
  for(k in 1:COUNT_query_cnt){
    m <- ifelse(nchar(k)==1, paste0("0",k),k)
    eval(parse(text=paste0("createOrReplaceTempView(PLC_ATTR_TT_COUNT_",m,", 'PLC_ATTR_TT_COUNT_",m,"')")))
    eval(parse(text=paste0("sum_column_names <- rbind(sum_column_names,data.frame(table='PLC_ATTR_TT_COUNT_"
                           ,m,"',column=columns(PLC_ATTR_TT_COUNT_",m,")))")))
  }
  sum_column_names    <- sum_column_names[which(sum_column_names$column!='PONO'),]
  count_column_names  <- count_column_names[which(count_column_names$column!='PONO'),]
  cal_column_names    <- rbind(sum_column_names,count_column_names)
  cal_table_names     <- unique(cal_column_names$table)
  
  cal_column_query      <-  ""
  cal_column_join_query <-  ""
  for(l in seq(length(cal_column_names$column)))
    cal_column_query  <- paste0(cal_column_query, sprintf(",%s.%s", cal_column_names$table[l], cal_column_names$column[l]))
  for(t in seq(length(cal_table_names)))
    cal_column_join_query  <- paste0(cal_column_join_query, sprintf(" LEFT OUTER JOIN %s ON A1.PONO=%s.PONO", cal_table_names[t], cal_table_names[t]))
  
  # ������_TT
  PL_PLC_TT <- SparkR::sql(paste0("
      SELECT       A1.BAS_YM                           
                  ,A1.PONO
                  ,A1.PL_FLG
                  ,A1.PLHD_INTG_CUST_NO
                  ,A1.MINSD_INTG_CUST_NO
                  ,A1.SLFC_NO
                  ,A1.SVFC_NO
                  ,CAST(A2.CMIP                            AS DOUBLE) AS CMIP
                  ,CAST(A2.MNCV_FCANT_WAMT                 AS DOUBLE) AS MNCV_FCANT_WAMT          /*�ְ�డ�Աݾ׿�ȭȯ��ݾ�*/
                  ,CAST(A2.RID_FCAMT_WAMT                  AS DOUBLE) AS A2.RID_FCAMT_WAMT        /*Ư�డ�Աݾ׿�ȭȯ��ݾ�*/
                  ,CAST(A2.PMFQY_CD                        AS STRING) AS PMFQY_CD                 /*�����ֱ��ڵ�*/
                  ,CAST(A2.PRM_PYG_FLG                     AS STRING) AS PRM_PYG_FLG              /*����ᳳ���߿���*/
                  ,CAST(A2.MMPD_FLG                        AS STRING) AS MMPD_FLG                 /*����ü����*/
                  ,CAST(A2.PLC_STAT_CD                     AS STRING) AS PLC_STAT_CD              /*�������ڵ�*/
                  ,CAST(A2.RTNN_NTHMM                      AS INT)    AS RTNN_NTHMM               /*��������*/
                  ,CAST(A2.RBNPLC_FLG                      AS STRING) AS RBNPLC_FLG               /*���ư�࿩��*/
                  ,CAST(A2.PLHD_PLC_AGE                    AS INT)    AS PLHD_PLC_AGE             /*����ڰ�࿬��*/
                  ,CAST(A2.PLHD_CUR_AGE                    AS INT)    AS PLHD_CUR_AGE             /*��������翬��*/
                  ,CAST(A2.PLHD_GEN_CD                     AS STRING) AS PLHD_GEN_CD              /*����ڼ����ڵ�*/
                  ,CAST(A2.PLHD_OCPN_CD                    AS STRING) AS PLHD_OCPN_CD             /*����������ڵ�*/
                  ,CAST(A2.PLHD_OCPN_RSKLVL_CD             AS STRING) AS PLHD_OCPN_RSKLVL_CD      /*����������������ڵ�*/
                  ,CAST(A2.MINSD_PLC_AGE                   AS INT)    AS MINSD_PLC_AGE            /*���Ǻ����ڰ�࿬��*/
                  ,CAST(A2.MINSD_GEN_CD                    AS STRING) AS MINSD_GEN_CD             /*���Ǻ����ڼ����ڵ�*/
                  ,CAST(A2.MINSD_OCPN_CD                   AS STRING) AS MINSD_OCPN_CD            /*���Ǻ����������ڵ�*/
                  ,CAST(A2.MINSD_OCPN_RSKLVL_CD            AS STRING) AS MINSD_OCPN_RSKLVL_CD     /*���Ǻ����������������ڵ�*/
                  ,CAST(A2.PMPMD_CD                        AS STRING) AS PMPMD_CD                 /*���ݹ���ڵ�*/
                  ,CAST(A2.PLHD_MINSD_SAME_FLG             AS STRING) AS PLHD_MINSD_SAME_FLG      /*��������Ǻ����ڵ��Ͽ���*/
                  ,CAST(A2.HFAMDS_APLC_FLG                 AS STRING) AS HFAMDS_APLC_FLG          /*�����������뿩��*/
                  ,CAST(A2.MDEXM_FLG                       AS STRING) AS MDEXM_FLG                /*�ǰ����ܿ���*/
                  ,CAST(A2.PLHD_MINSD_CUR_AGE_DIFF         AS INT)    AS PLHD_MINSD_CUR_AGE_DIFF  /*��������Ǻ��������翬������*/
                  ,CAST(A2.MNCV_PYMT_PRD_TYP_CD            AS STRING) AS MNCV_PYMT_PRD_TYP_CD     /*�ְ�ೳ�ԱⰣ�����ڵ�*/
                  ,CAST(A2.MNCV_INS_PRD_TYP_CD             AS STRING) AS MNCV_INS_PRD_TYP_CD      /*�ְ�ຸ��Ⱓ�����ڵ�*/
                  ,CAST(A2.MNCV_CMIP                       AS DOUBLE) AS MNCV_CMIP                /*�ְ��CMIP*/
                  ,CAST(A2.RID_CMIP                        AS DOUBLE) AS RID_CMIP                 /*Ư��CMIP*/
                  ,CAST(A2.RID_CNT                         AS INT)    AS RID_CNT                  /*Ư��Ǽ�*/
                  ,CAST(A2.SALE_CHNL_L2_CD                 AS STRING) AS SALE_CHNL_L2_CD          /*�Ǹ�ä�η���2�ڵ�*/
                  ,CAST(A2.PLC_RL_L1_CD                    AS STRING) AS PLC_RL_L1_CD             /*�����跹��1�ڵ�*/
                  ,CAST(A2.KLIA_INS_KND_CD                 AS STRING) AS KLIA_INS_KND_CD          /*����������ȸ���������ڵ�*/
                  ,CAST(A2.PROD_REPT_TYP_CD                AS STRING) AS PROD_REPT_TYP_CD         /*��ǰ�����������ڵ�*/
                  ,CAST(A2.ITSTV_PROD_FLG                  AS STRING) AS ITSTV_PROD_FLG           /*�ݸ���������ǰ����*/
                  ,CAST(A2.MKTG_PROD_GRP_L2_CD             AS STRING) AS MKTG_PROD_GRP_L2_CD      /*�����û�ǰ�׷췹��2�ڵ�*/
                  ,CAST(A2.MKTG_PROD_GRP_L3_CD             AS STRING) AS MKTG_PROD_GRP_L3_CD      /*�����û�ǰ�׷췹��3�ڵ�*/
                  ,CAST(A2.MKTG_PROD_GRP_L4_CD             AS STRING) AS MKTG_PROD_GRP_L4_CD      /*�����û�ǰ�׷췹��4�ڵ�*/
                  ,CAST(A2.TRSF_HOPE_DAY                   AS INT)    AS TRSF_HOPE_DAY            /*��ü�����*/
                  ,CAST(A2.FC_FAM_PLC_FLG                  AS STRING) AS FC_FAM_PLC_FLG           /*FC������࿩��*/
                  ,CAST(A2.PL_BLC                          AS DOUBLE) AS PL_BLC                   /*�����ܾ�*/

      FROM        PL_DRIVING_TABLE A1
      INNER JOIN  PLC_ATTR_TT_01  A2
              ON  A1.BAS_YM               = A2.BAS_YM
             AND  A1.PONO                 = A2.PONO
                  ",cal_column_join_query,"
      WHERE       A1.BAS_YM               = '",v_BAS_YM1,"'
      ORDER BY    A1.PONO
                                        
  "))
  
  # --------------------------
  # Save to HDFS parquet
  WRK_table   <- "PL_PLC_TT"
  WRK_dir     <- file.path(gsub(HDFS_Path,"",MDEL_WRK_Path),WRK_table)
    
  # ���� parquet���� ���� 
  deleteExistParquetFile(WRK_dir, WRK_table, looping_ar[i])
  
  # parquet ���� ����
  print(paste0("<< NOW : ",WRK_table," - ",looping_ar[i]," >>"))
  PL_PLC_TT  <- repartition(PL_PLC_TT, numPartitions=1L)
  
  write.df(PL_PLC_TT,WRK_dir, source ='parquet', mode='append')
  
  # ����� parquet ���ϸ� �����ϱ�
  src <- grep(".snappy.parquet", hdfs.ls(WRK_dir)[hdfs.ls(WRK_dir)$modtime%in%max(hdfs.ls(WRK_dir)$modtime)]$file, value=TRUE)
  dest <- paste0(WRK_dir,'/',looping_ar[i],'_',WRK_table,'_',seq(src),'.parquet')
  for(p in seq(src)) hdfs.rename(src=src[p], dest=dest[p])
}

# chmod
system(paste0("hdfs dfs -chmod -R 777 ",MDEL_WRK_Path,"/",WRK_table))

print(paste0("<<< ",WRK_table," - DONE!! >>>"))