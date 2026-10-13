"! Validations, called directly on the handler class.
"! The request is a draft created through EML; it only exists in memory and is rolled back after each test.
CLASS ltc_validations DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES ty_roles    TYPE STANDARD TABLE OF zwp_user_role WITH EMPTY KEY.
    TYPES ty_msgnos   TYPE STANDARD TABLE OF symsgno WITH EMPTY KEY.
    TYPES ty_failed   TYPE RESPONSE FOR FAILED LATE zwp_r_maintrequest.
    TYPES ty_reported TYPE RESPONSE FOR REPORTED LATE zwp_r_maintrequest.

    CLASS-DATA cut            TYPE REF TO lhc_maintrequest.
    CLASS-DATA sql_env        TYPE REF TO if_osql_test_environment.
    CLASS-DATA tenant_uuid    TYPE zwp_contract-tenant_uuid.
    CLASS-DATA apartment_uuid TYPE zwp_contract-apartment_uuid.

    DATA request_uuid TYPE zwp_r_maintrequest-RequestUUID.
    DATA failed       TYPE ty_failed.
    DATA reported     TYPE ty_reported.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

    METHODS valid_request_passes         FOR TESTING.
    METHODS short_description_refused    FOR TESTING.
    METHODS missing_title_refused        FOR TESTING.
    METHODS tenant_reports_only_for_self FOR TESTING.

    METHODS given_roles
      IMPORTING roles TYPE string_table.

    "! Creates a draft request and remembers its key in request_uuid
    METHODS given_request
      IMPORTING tenant      TYPE zwp_r_maintrequest-TenantUUID  OPTIONAL
                title       TYPE zwp_r_maintrequest-Title       DEFAULT 'Heizung kalt'
                description TYPE zwp_r_maintrequest-Description DEFAULT 'Die Heizung im Wohnzimmer bleibt seit gestern kalt.'.

    METHODS message_numbers
      RETURNING VALUE(result) TYPE ty_msgnos.
ENDCLASS.

CLASS ltc_validations IMPLEMENTATION.

  METHOD class_setup.
    " The handler class under test; FOR TESTING is the only way to instantiate it
    CREATE OBJECT cut FOR TESTING.

    " Role table doubled: each test decides the current user's roles
    sql_env = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZWP_USER_ROLE' ) ) ).

    " Any active contract from the demo data gives a valid tenant and apartment
    SELECT SINGLE FROM zwp_contract
      FIELDS tenant_uuid, apartment_uuid
      WHERE status = 'A'
      INTO ( @tenant_uuid, @apartment_uuid ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_env->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_env->clear_doubles( ).
    CLEAR: request_uuid, failed, reported.

    IF tenant_uuid IS INITIAL.
      cl_abap_unit_assert=>skip( msg = 'No active contract: run ZCL_WP_DEMO_DATA first' ).
    ENDIF.
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
  ENDMETHOD.

  METHOD given_roles.
    DATA(user) = CONV zwp_user_role-user_id( cl_abap_context_info=>get_user_technical_name( ) ).
    DATA(rows) = VALUE ty_roles( FOR r IN roles ( user_id = user role = r ) ).
    sql_env->insert_test_data( rows ).
  ENDMETHOD.

  METHOD given_request.
    MODIFY ENTITIES OF zwp_r_maintrequest
      ENTITY MaintRequest
        CREATE FIELDS ( ApartmentUUID TenantUUID Category Title Description )
        WITH VALUE #( ( %cid          = 'R1'
                        %is_draft     = if_abap_behv=>mk-on
                        ApartmentUUID = apartment_uuid
                        TenantUUID    = COND #( WHEN tenant IS INITIAL THEN tenant_uuid ELSE tenant )
                        Category      = 'HEAT'
                        Title         = title
                        Description   = description ) )
      MAPPED DATA(mapped)
      FAILED DATA(create_failed).

    cl_abap_unit_assert=>assert_initial( act = create_failed-maintrequest
                                         msg = 'Draft not created: check the roles the test gives the user' ).
    request_uuid = mapped-maintrequest[ 1 ]-RequestUUID.
  ENDMETHOD.

  METHOD message_numbers.
    " Lines without %msg only clear old messages of a state area; skip them
    LOOP AT reported-maintrequest INTO DATA(msg_line).
      IF msg_line-%msg IS BOUND.
        APPEND msg_line-%msg->if_t100_message~t100key-msgno TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD valid_request_passes.
    given_roles( VALUE #( ( `AGENT` ) ) ).
    given_request( ).

    cut->validaterequiredfields(
      EXPORTING keys     = VALUE #( ( %is_draft = if_abap_behv=>mk-on RequestUUID = request_uuid ) )
      CHANGING  failed   = failed
                reported = reported ).
    cut->validatedescription(
      EXPORTING keys     = VALUE #( ( %is_draft = if_abap_behv=>mk-on RequestUUID = request_uuid ) )
      CHANGING  failed   = failed
                reported = reported ).
    cut->validatetenantcontract(
      EXPORTING keys     = VALUE #( ( %is_draft = if_abap_behv=>mk-on RequestUUID = request_uuid ) )
      CHANGING  failed   = failed
                reported = reported ).

    cl_abap_unit_assert=>assert_initial( act = failed-maintrequest
                                         msg = 'A complete request must pass all three validations' ).
    cl_abap_unit_assert=>assert_initial( message_numbers( ) ).
  ENDMETHOD.

  METHOD short_description_refused.
    given_roles( VALUE #( ( `AGENT` ) ) ).
    given_request( description = 'kalt' ).

    cut->validatedescription(
      EXPORTING keys     = VALUE #( ( %is_draft = if_abap_behv=>mk-on RequestUUID = request_uuid ) )
      CHANGING  failed   = failed
                reported = reported ).

    cl_abap_unit_assert=>assert_not_initial( failed-maintrequest ).
    cl_abap_unit_assert=>assert_table_contains( line  = zif_wp_msg=>no-description
                                                table = message_numbers( ) ).
  ENDMETHOD.

  METHOD missing_title_refused.
    given_roles( VALUE #( ( `AGENT` ) ) ).
    given_request( title = '' ).

    cut->validaterequiredfields(
      EXPORTING keys     = VALUE #( ( %is_draft = if_abap_behv=>mk-on RequestUUID = request_uuid ) )
      CHANGING  failed   = failed
                reported = reported ).

    cl_abap_unit_assert=>assert_not_initial( failed-maintrequest ).
    cl_abap_unit_assert=>assert_table_contains( line  = zif_wp_msg=>no-title
                                                table = message_numbers( ) ).
  ENDMETHOD.

  METHOD tenant_reports_only_for_self.
    given_roles( VALUE #( ( `TENANT` ) ) ).

    DATA(my_tenant) = zcl_wp_auth=>my_tenant_uuid( ).
    SELECT SINGLE FROM zwp_tenant
      FIELDS tenant_uuid
      WHERE tenant_uuid <> @my_tenant
      INTO @DATA(someone_else).

    given_request( tenant = someone_else ).

    cut->validatetenantcontract(
      EXPORTING keys     = VALUE #( ( %is_draft = if_abap_behv=>mk-on RequestUUID = request_uuid ) )
      CHANGING  failed   = failed
                reported = reported ).

    cl_abap_unit_assert=>assert_not_initial( failed-maintrequest ).
    cl_abap_unit_assert=>assert_table_contains( line  = zif_wp_msg=>no-only_yourself
                                                table = message_numbers( ) ).
  ENDMETHOD.

ENDCLASS.


"! Determinations, through the real business object: a draft created with EML, rolled back afterwards
CLASS ltc_determinations DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES ty_roles TYPE STANDARD TABLE OF zwp_user_role WITH EMPTY KEY.

    CLASS-DATA sql_env        TYPE REF TO if_osql_test_environment.
    CLASS-DATA tenant_uuid    TYPE zwp_contract-tenant_uuid.
    CLASS-DATA apartment_uuid TYPE zwp_contract-apartment_uuid.

    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS teardown.

    METHODS new_request_gets_due_date FOR TESTING.
ENDCLASS.

CLASS ltc_determinations IMPLEMENTATION.

  METHOD class_setup.
    sql_env = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( 'ZWP_USER_ROLE' ) ) ).

    SELECT SINGLE FROM zwp_contract
      FIELDS tenant_uuid, apartment_uuid
      WHERE status = 'A'
      INTO ( @tenant_uuid, @apartment_uuid ).
  ENDMETHOD.

  METHOD class_teardown.
    sql_env->destroy( ).
  ENDMETHOD.

  METHOD setup.
    sql_env->clear_doubles( ).
    IF tenant_uuid IS INITIAL.
      cl_abap_unit_assert=>skip( msg = 'No active contract: run ZCL_WP_DEMO_DATA first' ).
    ENDIF.

    DATA(user) = CONV zwp_user_role-user_id( cl_abap_context_info=>get_user_technical_name( ) ).
    sql_env->insert_test_data( VALUE ty_roles( ( user_id = user role = 'AGENT' ) ) ).
  ENDMETHOD.

  METHOD teardown.
    ROLLBACK ENTITIES.
  ENDMETHOD.

  METHOD new_request_gets_due_date.
    MODIFY ENTITIES OF zwp_r_maintrequest
      ENTITY MaintRequest
        CREATE FIELDS ( ApartmentUUID TenantUUID Category Title Description )
        WITH VALUE #( ( %cid          = 'NEW'
                        %is_draft     = if_abap_behv=>mk-on
                        ApartmentUUID = apartment_uuid
                        TenantUUID    = tenant_uuid
                        Category      = 'HEAT'
                        Title         = 'Heizung kalt'
                        Description   = 'Die Heizung im Wohnzimmer bleibt seit gestern kalt.' ) )
      MAPPED DATA(mapped)
      FAILED DATA(create_failed).

    cl_abap_unit_assert=>assert_initial( act = create_failed-maintrequest
                                         msg = 'Draft not created: check the roles the test gives the user' ).

    READ ENTITIES OF zwp_r_maintrequest
      ENTITY MaintRequest
        FIELDS ( Status Priority ReportedAt DueAt )
        WITH VALUE #( FOR m IN mapped-maintrequest
                      ( %is_draft   = if_abap_behv=>mk-on
                        RequestUUID = m-RequestUUID ) )
      RESULT DATA(requests).

    cl_abap_unit_assert=>assert_not_initial( act = requests
                                             msg = 'Draft not readable: run ZCL_WP_ROLE_SETUP with all roles' ).
    DATA(request) = requests[ 1 ].

    " The determinations set status New, a default priority and the due time from the SLA rule
    cl_abap_unit_assert=>assert_equals( exp = 'N' act = request-Status ).
    cl_abap_unit_assert=>assert_not_initial( request-Priority ).
    cl_abap_unit_assert=>assert_equals(
      exp = zcl_wp_sla_calculator=>due_at( reported_at = request-ReportedAt priority = request-Priority )
      act = request-DueAt ).
  ENDMETHOD.

ENDCLASS.
