CLASS zcl_wp_tenant_api_test DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_wp_tenant_api_test IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    out->write( |User { zcl_wp_auth=>current_user( ) }, tenant only: { zcl_wp_auth=>is_tenant_only( ) }| ).

    " 1. Report damage the way the app will: no tenant, no apartment
    MODIFY ENTITIES OF zwp_c_myrequest
      ENTITY MyRequest
        CREATE FIELDS ( Category Title Description )
        WITH VALUE #( ( %cid        = 'OWN'
                        Category    = 'HEAT'
                        Title       = 'Heizung kalt'
                        Description = 'Seit gestern bleibt die Heizung im Wohnzimmer kalt.' ) )
      FAILED DATA(failed1)
      REPORTED DATA(reported1).

    COMMIT ENTITIES RESPONSE OF zwp_c_myrequest
      FAILED DATA(commit_failed1)
      REPORTED DATA(commit_reported1).

    out->write( |1. Own request: { COND #( WHEN failed1 IS INITIAL AND commit_failed1 IS INITIAL THEN `saved` ELSE `refused` ) }| ).
    LOOP AT commit_reported1-myrequest INTO DATA(message1).
      out->write( |   { message1-%msg->if_message~get_text( ) }| ).
    ENDLOOP.

    " 2. Try to report in another tenant's name (T0002)
    SELECT SINGLE FROM zwp_tenant FIELDS tenant_uuid WHERE tenant_id = 'T0002' INTO @DATA(other_tenant).

    MODIFY ENTITIES OF zwp_c_myrequest
      ENTITY MyRequest
        CREATE FIELDS ( TenantUUID Category Title Description )
        WITH VALUE #( ( %cid        = 'OTHER'
                        TenantUUID  = other_tenant
                        Category    = 'DOOR'
                        Title       = 'Tür klemmt'
                        Description = 'Die Wohnungstür lässt sich kaum noch schließen.' ) )
      FAILED DATA(failed2)
      REPORTED DATA(reported2).

    COMMIT ENTITIES RESPONSE OF zwp_c_myrequest
      FAILED DATA(commit_failed2)
      REPORTED DATA(commit_reported2).

    out->write( |2. Request for T0002: { COND #( WHEN failed2 IS INITIAL AND commit_failed2 IS INITIAL THEN `saved` ELSE `refused` ) }| ).
    LOOP AT commit_reported2-myrequest INTO DATA(message2).
      out->write( |   { message2-%msg->if_message~get_text( ) }| ).
    ENDLOOP.

    " 3. What can I see? Access control filters this select.
    SELECT FROM zwp_c_myrequest
      FIELDS RequestID, Title, StatusText, ApartmentID
      ORDER BY RequestID DESCENDING
      INTO TABLE @DATA(mine)
      UP TO 5 ROWS.

    out->write( |3. My latest requests:| ).
    out->write( mine ).
  ENDMETHOD.

ENDCLASS.
