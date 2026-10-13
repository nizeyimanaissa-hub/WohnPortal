"! Message class ZWP_MSG and its message numbers, so the code never uses bare numbers
INTERFACE zif_wp_msg PUBLIC.

  CONSTANTS id TYPE symsgid VALUE 'ZWP_MSG'.

  CONSTANTS:
    BEGIN OF no,
      postal_code         TYPE symsgno VALUE '001',
      apartment_values    TYPE symsgno VALUE '002',
      email               TYPE symsgno VALUE '003',
      apartment_let       TYPE symsgno VALUE '004',
      apartment_locked    TYPE symsgno VALUE '005',
      end_date_terminate  TYPE symsgno VALUE '006',
      choose_apartment    TYPE symsgno VALUE '007',
      choose_tenant       TYPE symsgno VALUE '008',
      start_date          TYPE symsgno VALUE '009',
      end_after_start     TYPE symsgno VALUE '010',
      deposit_max         TYPE symsgno VALUE '011',
      active_technician   TYPE symsgno VALUE '012',
      trade_mismatch      TYPE symsgno VALUE '013',
      planned_date_past   TYPE symsgno VALUE '014',
      resolution_note     TYPE symsgno VALUE '015',
      reject_reason       TYPE symsgno VALUE '016',
      choose_category     TYPE symsgno VALUE '017',
      title               TYPE symsgno VALUE '018',
      priority_range      TYPE symsgno VALUE '019',
      description         TYPE symsgno VALUE '020',
      no_active_contract  TYPE symsgno VALUE '021',
      only_yourself       TYPE symsgno VALUE '022',
    END OF no.

ENDINTERFACE.
