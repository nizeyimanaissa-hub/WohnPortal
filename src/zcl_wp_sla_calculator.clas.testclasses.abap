"! Unit tests for the SLA rule: days per priority and calendar arithmetic
CLASS ltc_sla DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS priority_1_is_one_day       FOR TESTING.
    METHODS priorities_2_to_4           FOR TESTING.
    METHODS unknown_priority_is_14_days FOR TESTING.
    METHODS due_at_adds_sla_days        FOR TESTING.
    METHODS add_days_over_year_end      FOR TESTING.
    METHODS add_days_in_leap_year       FOR TESTING.
    METHODS add_negative_days           FOR TESTING.
ENDCLASS.

CLASS ltc_sla IMPLEMENTATION.

  METHOD priority_1_is_one_day.
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = zcl_wp_sla_calculator=>days_for_priority( CONV #( 1 ) ) ).
  ENDMETHOD.

  METHOD priorities_2_to_4.
    cl_abap_unit_assert=>assert_equals( exp = 3  act = zcl_wp_sla_calculator=>days_for_priority( CONV #( 2 ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 7  act = zcl_wp_sla_calculator=>days_for_priority( CONV #( 3 ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 14 act = zcl_wp_sla_calculator=>days_for_priority( CONV #( 4 ) ) ).
  ENDMETHOD.

  METHOD unknown_priority_is_14_days.
    " Anything outside 1-3 gets the longest SLA rather than none
    cl_abap_unit_assert=>assert_equals( exp = 14
                                        act = zcl_wp_sla_calculator=>days_for_priority( CONV #( 0 ) ) ).
  ENDMETHOD.

  METHOD due_at_adds_sla_days.
    " Priority 3 = 7 days, the time of day stays the same
    cl_abap_unit_assert=>assert_equals(
      exp = CONV timestampl( '20261017100000' )
      act = zcl_wp_sla_calculator=>due_at( reported_at = CONV #( '20261010100000' )
                                           priority    = CONV #( 3 ) ) ).
  ENDMETHOD.

  METHOD add_days_over_year_end.
    cl_abap_unit_assert=>assert_equals(
      exp = CONV timestampl( '20270102083000' )
      act = zcl_wp_sla_calculator=>add_days( timestamp = CONV #( '20261231083000' ) days = 2 ) ).
  ENDMETHOD.

  METHOD add_days_in_leap_year.
    " 2028 is a leap year: 28 Feb + 1 day = 29 Feb
    cl_abap_unit_assert=>assert_equals(
      exp = CONV timestampl( '20280229120000' )
      act = zcl_wp_sla_calculator=>add_days( timestamp = CONV #( '20280228120000' ) days = 1 ) ).
  ENDMETHOD.

  METHOD add_negative_days.
    " The demo data uses negative days to date requests back
    cl_abap_unit_assert=>assert_equals(
      exp = CONV timestampl( '20260930090000' )
      act = zcl_wp_sla_calculator=>add_days( timestamp = CONV #( '20261010090000' ) days = -10 ) ).
  ENDMETHOD.

ENDCLASS.
