CLASS zcl_wp_sla_calculator DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    "! Days until a request is due: priority 1 = 1 day, 2 = 3, 3 = 7, 4 = 14
    CLASS-METHODS days_for_priority
      IMPORTING priority      TYPE zwp_maint_req-priority
      RETURNING VALUE(result) TYPE i.

    "! Due time = reported time + SLA days for the priority
    CLASS-METHODS due_at
      IMPORTING reported_at   TYPE timestampl
                priority      TYPE zwp_maint_req-priority
      RETURNING VALUE(result) TYPE timestampl.

    "! Adds (or, with a negative number, subtracts) whole days to a UTC time stamp
    CLASS-METHODS add_days
      IMPORTING timestamp     TYPE timestampl
                days          TYPE i
      RETURNING VALUE(result) TYPE timestampl.
ENDCLASS.

CLASS zcl_wp_sla_calculator IMPLEMENTATION.

  METHOD days_for_priority.
    result = SWITCH #( priority WHEN 1 THEN 1
                                WHEN 2 THEN 3
                                WHEN 3 THEN 7
                                ELSE 14 ).
  ENDMETHOD.

  METHOD due_at.
    result = add_days( timestamp = reported_at days = days_for_priority( priority ) ).
  ENDMETHOD.

  METHOD add_days.
    DATA date TYPE d.
    DATA time TYPE t.

    CONVERT TIME STAMP timestamp TIME ZONE 'UTC' INTO DATE date TIME time.
    date = date + days.
    CONVERT DATE date TIME time INTO TIME STAMP result TIME ZONE 'UTC'.
  ENDMETHOD.

ENDCLASS.
