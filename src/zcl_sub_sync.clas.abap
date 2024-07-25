CLASS zcl_sub_sync DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES: tt_read_keys   TYPE TABLE FOR READ IMPORT   zi_sub_sync,
           tt_read_result TYPE TABLE FOR READ RESULT   zi_sub_sync,
           tt_post_keys   TYPE TABLE FOR ACTION IMPORT zi_sub_sync~post,
           tt_post_result TYPE TABLE FOR ACTION RESULT zi_sub_sync~post.

    TYPES: tt_fail_early TYPE RESPONSE FOR FAILED EARLY   zi_sub_sync,
           tt_resp_early TYPE RESPONSE FOR REPORTED EARLY zi_sub_sync,
           tt_mapp_early TYPE RESPONSE FOR MAPPED EARLY   zi_sub_sync.

    TYPES : BEGIN OF ty_jdat,
              mblnr TYPE string,
              mjahr TYPE string,
              zeile TYPE string,
              bwart TYPE string,
              matnr TYPE string,
              sgtxt TYPE string,
              werks TYPE string,
              lgort TYPE string,
              charg TYPE string,
              insmk TYPE string,
              sobkz TYPE string,
              lifnr TYPE string,
              kunnr TYPE string,
              waers TYPE string,
              bnbtr TYPE string,
              menge TYPE string,
              meins TYPE string,
              lsmng TYPE string,
              lsmeh TYPE string,
              ebeln TYPE string,
              ebelp TYPE string,
              etenr TYPE string,
              lfbja TYPE string,
              lfbnr TYPE string,
              sjahr TYPE string,
              smbln TYPE string,
              bukrs TYPE string,
              belnr TYPE string,
              buzei TYPE string,
              buzum TYPE string,
              rspos TYPE string,
              vgart TYPE string,
              blart TYPE string,
              budat TYPE string,
              cpudt TYPE string,
              cputm TYPE string,
              xblnr TYPE string,
              bktxt TYPE string,
              xabln TYPE string,
              gstat TYPE string,
              shkzg TYPE string,
              txz01 type string,
            END OF ty_jdat,
            gt_jdat TYPE STANDARD TABLE OF ty_jdat WITH NON-UNIQUE DEFAULT KEY.

    TYPES : BEGIN OF ty_data,
              token TYPE string,
              data  TYPE gt_jdat,
            END OF ty_data.

    TYPES : ty_ent_data TYPE zi_sub_sync,
            gt_ent_data TYPE STANDARD TABLE OF ty_ent_data WITH NON-UNIQUE DEFAULT KEY.

    TYPES : BEGIN OF ty_add,
              mblnr TYPE string,
              mjahr TYPE string,
            END OF ty_add,
            gt_add TYPE STANDARD TABLE OF ty_add WITH DEFAULT KEY.

    TYPES : BEGIN OF ty_resp,
              status            TYPE string,
              ADD_SUBCON_ITEMS    TYPE gt_add,
              UPDATE_SUBCON_ITEMS TYPE gt_add,
            END OF ty_resp.

    DATA : lv_resp TYPE string.

    CLASS-DATA : wa_jdat TYPE ty_jdat,
                 it_jdat TYPE gt_jdat,
                 wa_edat TYPE ty_ent_data,
                 it_edat TYPE gt_ent_data,
                 wa_resp TYPE ty_resp.

    CLASS-DATA : wa_data TYPE ty_data.

    CLASS-DATA : wa_json TYPE string.

    CLASS-METHODS:
      get_instance RETURNING VALUE(ro_instance) TYPE REF TO zcl_sub_sync.

    METHODS: read_data   IMPORTING keys     TYPE tt_read_keys
                         CHANGING  result   TYPE tt_read_result
                                   failed   TYPE tt_fail_early
                                   reported TYPE tt_resp_early,

      post_data   IMPORTING keys     TYPE tt_post_keys
                  EXPORTING mstxt    TYPE string
                  CHANGING  result   TYPE tt_post_result
                            mapped   TYPE tt_mapp_early
                            failed   TYPE tt_fail_early
                            reported TYPE tt_resp_early.
  PROTECTED SECTION.
  PRIVATE SECTION.
     CLASS-DATA: mo_instance TYPE REF TO zcl_sub_sync.

    METHODS :   data_json   IMPORTING ip_data        TYPE ty_data
                            RETURNING VALUE(rt_json) TYPE string,
                json_data   IMPORTING ip_json        TYPE string
                            CHANGING  ep_data        TYPE ty_resp,
                conv_data   IMPORTING ip_data        TYPE gt_ent_data
                            RETURNING VALUE(rt_data) TYPE ty_data,
                call_apip   IMPORTING ip_data        TYPE string
                            RETURNING VALUE(rt_resp) TYPE string
                            RAISING   cx_web_http_client_error,
                get_slin    importing ip_po type ty_ent_data-PurchaseOrder
                                      ip_it type ty_ent_data-PurchaseOrderItem
                            returning VALUE(rt_schl) type ty_ent_data-MaterialDocumentItem.
ENDCLASS.



CLASS zcl_sub_sync IMPLEMENTATION.
  METHOD read_data.
    SELECT *
     FROM zi_sub_sync
     FOR ALL ENTRIES IN @keys
     WHERE materialdocument = @keys-materialdocument
       AND materialdocumentyear = @keys-materialdocumentyear
     INTO TABLE @DATA(it_temp).

    result = CORRESPONDING #( it_temp ).
  ENDMETHOD.

  METHOD post_data.

    DATA : wa_param TYPE STRUCTURE FOR READ RESULT zi_sub_sync.
     SELECT *
     FROM zi_sub_sync
     FOR ALL ENTRIES IN @keys
     WHERE materialdocument     = @keys-materialdocument
       AND materialdocumentyear = @keys-materialdocumentyear
     INTO TABLE @DATA(it_temp).

    IF it_temp IS NOT INITIAL.
      it_edat = CORRESPONDING #( it_temp ).
      IF it_edat IS NOT INITIAL.
        wa_data = zcl_sub_sync=>get_instance( )->conv_data( ip_data = it_edat ).

        IF wa_data IS NOT INITIAL.
          wa_json = zcl_sub_sync=>get_instance( )->data_json( ip_data = wa_data ).
        ENDIF.

        IF wa_json IS NOT INITIAL.
          TRY.
              REPLACE ALL OCCURRENCES OF 'null' IN wa_json WITH space.
              lv_resp = zcl_sub_sync=>get_instance( )->call_apip( ip_data = wa_json ).
              mstxt = lv_resp.
              CALL METHOD zcl_sub_sync=>get_instance( )->json_data(
                EXPORTING
                  ip_json = lv_resp
                CHANGING
                  ep_data = wa_resp
              ).


            READ ENTITIES OF zi_sub_sync
            ENTITY zi_sub_sync
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(lt_result)
            FAILED DATA(lt_fail)
            REPORTED DATA(lt_report).

            IF lt_result IS NOT INITIAL.

              result = VALUE #( FOR ls_result IN lt_result ( %tky   = ls_result-%tky
                                                             %param = ls_result
                                                ) ).

            ELSE.

            ENDIF.
            CATCH cx_web_http_client_error.
              "handle exception
          ENDTRY.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD get_instance.
    mo_instance = ro_instance = COND #( WHEN mo_instance IS BOUND
                                        THEN mo_instance
                                        ELSE NEW #(  ) ).
  ENDMETHOD.

  METHOD call_apip.
         DATA : lv_json TYPE string,
           lv_stat TYPE string.
    FREE : lv_json, lv_stat.

    lv_json = ip_data.

    DATA : lo_clnt      TYPE REF TO if_web_http_client,
           lo_clnt_prxy TYPE REF TO /iwbep/if_cp_client_proxy,
           lo_rqst      TYPE REF TO /iwbep/if_cp_request_read_list,
           lo_resp      TYPE REF TO /iwbep/if_cp_response_read_lst,
           head_fields  TYPE if_web_http_request=>name_value_pairs.

    TRY.
        cl_http_destination_provider=>create_by_url(    EXPORTING i_url              = 'http://13.202.19.212'
                                                        RECEIVING r_http_destination = DATA(lo_dest)    ).

        cl_web_http_client_manager=>create_by_http_destination( EXPORTING i_destination = lo_dest
                                                                RECEIVING  r_client     = lo_clnt ).

        lo_clnt->get_http_request( RECEIVING r_http_request = DATA(lo_http_rqst) ).

        lo_http_rqst->set_uri_path( EXPORTING i_uri_path = '/ausubcon/'
                                    RECEIVING r_value    = DATA(lo_http_url) ).

        lo_http_rqst->set_content_type( content_type = 'application/json' ).

        lo_http_rqst->set_header_field( EXPORTING i_name  = 'accept' i_value = 'application/json' ).

        lo_http_rqst->set_text( EXPORTING i_text   = lv_json ).

        lo_clnt->execute(   EXPORTING i_method   = lo_clnt->post i_timeout  = 100
                            RECEIVING r_response = DATA(lo_http_resp) ).

        lo_http_resp->get_status( RECEIVING r_value = DATA(lo_resp_stat) ).

        lo_http_resp->get_text( RECEIVING r_value = DATA(lo_resp_text) ).

        rt_resp = lo_resp_text.

      CATCH cx_http_dest_provider_error.
      CATCH cx_web_message_error.
      CATCH cx_web_http_client_error.
    ENDTRY.
  ENDMETHOD.

  METHOD conv_data.

    DATA: wa_idat TYPE ty_ent_data,
          it_idat TYPE gt_ent_data,
          wa_odat TYPE ty_data.

    FREE : it_idat, wa_idat, wa_odat, wa_jdat, it_jdat.

    it_idat[] = ip_data.

    LOOP AT it_idat INTO wa_idat.
        wa_jdat-mblnr = wa_idat-MaterialDocument.
        wa_jdat-mjahr = wa_idat-MaterialDocumentYear.
        wa_jdat-zeile = wa_idat-MaterialDocumentItem.
        wa_jdat-bwart = wa_idat-GoodsMovementType.
        wa_jdat-matnr = wa_idat-Material.
        wa_jdat-sgtxt = wa_idat-MaterialDocumentHeaderText.
        wa_jdat-werks = wa_idat-Plant.
        wa_jdat-lgort = wa_idat-StorageLocation.
        wa_jdat-charg = wa_idat-Batch.
        wa_jdat-insmk = wa_idat-InventoryStockType.
        wa_jdat-sobkz = wa_idat-InventorySpecialStockType.
        wa_jdat-lifnr = wa_idat-Supplier.
        wa_jdat-kunnr = wa_idat-Customer.
        wa_jdat-waers = wa_idat-CompanyCodeCurrency.
        wa_jdat-bnbtr = wa_idat-TotalGoodsMvtAmtInCCCrcy.
        wa_jdat-menge = wa_idat-QuantityInBaseUnit.
        wa_jdat-meins = wa_idat-MaterialBaseUnit.
        wa_jdat-lsmng = wa_idat-QuantityInEntryUnit.
        wa_jdat-lsmeh = wa_idat-EntryUnit.
        wa_jdat-ebeln = wa_idat-PurchaseOrder.
        wa_jdat-ebelp = wa_idat-PurchaseOrderItem.
        wa_jdat-etenr = zcl_sub_sync=>get_instance( )->get_slin(
                                                    ip_po = wa_idat-PurchaseOrder
                                                    ip_it = wa_idat-PurchaseOrderItem
                                                  ).
        wa_jdat-lfbja = '2023'.
        wa_jdat-lfbnr = wa_idat-ReferenceDocument.
        wa_jdat-sjahr = wa_idat-ReversedMaterialDocumentYear.
        wa_jdat-smbln = wa_idat-ReversedMaterialDocument.
        wa_jdat-bukrs = wa_idat-CompanyCode.
        wa_jdat-belnr = wa_idat-DeliveryDocument.
        wa_jdat-buzei = wa_idat-DeliveryDocumentItem.
        wa_jdat-buzum = ''.
        wa_jdat-rspos = ''.
        wa_jdat-vgart = wa_idat-InventoryTransactionType.
        wa_jdat-blart = wa_idat-AccountingDocumentType.
        CONCATENATE wa_idat-PostingDate+0(4) '-'
                    wa_idat-PostingDate+4(2) '-'
                    wa_idat-PostingDate+6(2)
                    into wa_jdat-budat.
        CONCATENATE wa_idat-DocumentDate+0(4) '-'
                    wa_idat-DocumentDate+4(2) '-'
                    wa_idat-DocumentDate+6(2)
                    into wa_jdat-cpudt.
        wa_jdat-cputm = wa_idat-CreationTime.
        wa_jdat-xblnr = wa_idat-ReferenceDocument.
        wa_jdat-bktxt = ''.
        wa_jdat-xabln = ''.
        wa_jdat-gstat = ''.
        wa_jdat-shkzg = wa_idat-DebitCreditCode.

      APPEND : wa_jdat TO it_jdat.
      CLEAR : wa_jdat.
    ENDLOOP.

    IF it_jdat IS NOT INITIAL.
      wa_odat-token = 'fb3_pryjdgpm6iz9p4ilk^9l+1&dx7i#obq-v!hca&1%qz-&)%'.
      wa_odat-data = it_jdat.
    ENDIF.

    IF wa_odat IS NOT INITIAL.
      rt_data = wa_odat.
    ENDIF.
  ENDMETHOD.

  METHOD data_json.
       rt_json = /ui2/cl_json=>serialize(  data = wa_data
                                        compress = abap_false
                                        pretty_name = /ui2/cl_json=>pretty_mode-user_low_case ).
  ENDMETHOD.

  METHOD json_data.
    /ui2/cl_json=>deserialize(  EXPORTING   json = ip_json
                                            pretty_name = /ui2/cl_json=>pretty_mode-user_low_case
                                CHANGING    data = ep_data ).
  ENDMETHOD.

  METHOD get_slin.
    DATA: lv_po TYPE ty_ent_data-MaterialDocument,
          lv_it TYPE ty_ent_data-MaterialDocumentItem,
          lv_pocat type I_PURCHASEORDERITEMAPI01-PurchaseOrderCategory,
          lv_schln type I_SCHEDGLINEAPI01-ScheduleLine .

     lv_po = ip_po.
     lv_it = ip_it.
     select SINGLE PURCHASEORDERCATEGORY
           from I_PURCHASEORDERITEMAPI01
      where PurchaseOrder     = @lv_po
        and PurchaseOrderItem = @lv_it
      into @lv_pocat   .

      if lv_pocat eq 'F'.
        select single PURCHASEORDERSCHEDULELINE
          from I_PURORDSCHEDULELINEAPI01
            where PURCHASEORDER     = @lv_po
              and PURCHASEORDERITEM = @lv_it
            into @lv_schln .

      elseif lv_pocat eq 'L'.
        select single SCHEDULELINE
          from I_SCHEDGLINEAPI01
            where SCHEDULINGAGREEMENT     = @lv_po
              and SCHEDULINGAGREEMENTITEM = @lv_it
            into @lv_schln.

      endif.
     rt_schl = lv_schln.
  ENDMETHOD.

ENDCLASS.
