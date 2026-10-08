CLASS zcl_wp_ve_overdue DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.
ENDCLASS.

CLASS zcl_wp_ve_overdue IMPLEMENTATION.

  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    " Fields the calculation needs, even if the app didn't ask for them
    et_requested_orig_elements = VALUE #( ( `STATUS` ) ( `DUEAT` ) ).
  ENDMETHOD.

  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA requests TYPE STANDARD TABLE OF zwp_c_maintrequest WITH DEFAULT KEY.
    DATA now      TYPE timestampl.

    GET TIME STAMP FIELD now.
    requests = CORRESPONDING #( it_original_data ).

    LOOP AT requests ASSIGNING FIELD-SYMBOL(<request>).
      <request>-IsOverdue = xsdbool( <request>-Status <> 'C'
                                 AND <request>-Status <> 'R'
                                 AND <request>-DueAt IS NOT INITIAL
                                 AND <request>-DueAt < now ).
      <request>-OverdueCriticality = COND #( WHEN <request>-IsOverdue = abap_true THEN 1 ELSE 0 ).
    ENDLOOP.

    ct_calculated_data = CORRESPONDING #( requests ).
  ENDMETHOD.

ENDCLASS.
