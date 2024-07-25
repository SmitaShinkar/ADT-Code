CLASS lhc_zi_sub_sync DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    TYPES : BEGIN OF ty_add,
              mblnr TYPE string,
              mjahr type string,
            END OF ty_add,
            gt_add TYPE STANDARD TABLE OF ty_add WITH DEFAULT KEY.

     TYPES : BEGIN OF ty_resp,
              status           TYPE string,
              ADD_SUBCON_ITEMS    TYPE gt_add,
              UPDATE_SUBCON_ITEMS TYPE gt_add,
            END OF ty_resp.

    types : begin of ty_out,
             status type c length 3,
             message type string,
             adduser type c length 1,
             updtuser type c length 1,
             mblnr   type string,
             mjahr   type string,
           end of ty_out.

    DATA : lv_resp TYPE string,
           wa_resp TYPE ty_resp,
           lt_outp TYPE TABLE of zi_sub_sync,
           wa_outp type ty_out,
           it_outp type table of ty_out with default key.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_sub_sync RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_sub_sync RESULT result.

    METHODS read FOR READ
      IMPORTING keys FOR READ zi_sub_sync RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK zi_sub_sync.

    METHODS post FOR MODIFY
      IMPORTING keys FOR ACTION zi_sub_sync~post RESULT result.

    METHODS : json_data IMPORTING ip_json TYPE string
                        CHANGING  ep_data TYPE ty_resp.


ENDCLASS.

CLASS lhc_zi_sub_sync IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD read.
   zcl_sub_sync=>get_instance( )->read_data(
     EXPORTING
       keys     = keys
     CHANGING
       result   = result
       failed   = failed
       reported = reported
   ).
  ENDMETHOD.


  METHOD lock.
  ENDMETHOD.

  METHOD post.

    DATA : lv_status  TYPE string,
           lv_message TYPE string,
           lt_data    TYPE TABLE OF zi_gr_sync.

    FREE : lv_resp, wa_resp, lv_status, lv_message.

     zcl_sub_sync=>get_instance( )->post_data(
       EXPORTING
         keys     = keys
       IMPORTING
         mstxt    = lv_resp
       CHANGING
         result   = result
         mapped   = mapped
         failed   = failed
         reported = reported
     ).

     IF lv_resp IS NOT INITIAL.
        CALL METHOD json_data(
          EXPORTING
            ip_json = lv_resp
          CHANGING
            ep_data = wa_resp ).

        SELECT *
          FROM zi_sub_sync
           FOR ALL ENTRIES IN @keys
            WHERE MaterialDocument EQ @keys-MaterialDocument
          INTO TABLE @DATA(it_temp).


         loop at it_temp into data(wa_temp).
            wa_outp-mblnr = wa_temp-MaterialDocument.
            wa_outp-mjahr = wa_temp-MaterialDocumentYear.
            append : wa_outp to it_outp.
             clear : wa_outp.
         endloop.

        loop at it_outp into wa_outp.
            IF wa_resp IS NOT INITIAL.
              IF wa_resp-status EQ '200'.
                IF wa_resp-ADD_SUBCON_ITEMS IS NOT INITIAL.
*                  if lv_resp eq wa_outp-mblnr.
                      wa_outp-status = '200'.
                      wa_outp-message = 'Challan Synced'.
                      modify : it_outp from wa_outp.
*                  endif.
                ELSE.
                  IF wa_resp-UPDATE_SUBCON_ITEMS IS NOT INITIAL.
                      wa_outp-status = '200'.
                      wa_outp-message = 'Challan Updated'.
                      modify : it_outp from wa_outp.
                  ENDIF.
                ENDIF.
              ELSE.
                wa_outp-status = wa_resp-status.
                wa_outp-message = 'Challan Not Synced'.
                modify : it_outp from wa_outp.
              ENDIF.
            ELSE.
              wa_outp-status = ''.
              wa_outp-message = 'No Portal Response'.
              modify : it_outp from wa_outp.
            ENDIF.
            clear : wa_outp.
        endloop.

        LOOP AT keys ASSIGNING FIELD-SYMBOL(<lfs_keys>).
          loop at it_outp into wa_outp where mblnr = <lfs_keys>-MaterialDocument.
              CONCATENATE wa_outp-mblnr ':' wa_outp-status wa_outp-message INTO DATA(lv_msg) SEPARATED BY space.
              APPEND VALUE #(
                 %tky = <lfs_keys>-%tky
                 %msg = new_message_with_text(
                          severity = if_abap_behv_message=>severity-none
                          text     = lv_msg
                        )

              ) TO reported-zi_sub_sync.
              CLEAR : lv_msg, wa_outp.
          endloop.
        ENDLOOP.
*      ENDIF.
    ELSE.
      APPEND VALUE #(
            %msg = new_message_with_text(
                     severity = if_abap_behv_message=>severity-none
                     text     = 'Please select Atleast 1 Challan'
                   )
         ) TO reported-zi_sub_sync.
    ENDIF.
  ENDMETHOD.

  METHOD json_data.
    /ui2/cl_json=>deserialize(  EXPORTING   json = ip_json
                                            pretty_name = /ui2/cl_json=>pretty_mode-user_low_case
                                CHANGING    data = ep_data ).
  ENDMETHOD.

ENDCLASS.

CLASS lsc_zi_sub_sync DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_zi_sub_sync IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
