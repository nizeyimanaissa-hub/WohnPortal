CLASS zcl_wp_role_setup DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_wp_role_setup IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    " Edit this list and run with F9 to switch the roles of your own user.
    " All three:   ( `TENANT` ) ( `AGENT` ) ( `PROPERTY_MGR` )
    " Tenant only: ( `TENANT` )
    DATA(my_roles) = VALUE string_table( ( `TENANT` ) ).

    DATA rows TYPE STANDARD TABLE OF zwp_user_role WITH EMPTY KEY.
    DATA(user) = zcl_wp_auth=>current_user( ).

    rows = VALUE #( FOR r IN my_roles ( user_id = user role = r ) ).

    DELETE FROM zwp_user_role WHERE user_id = @user.
    INSERT zwp_user_role FROM TABLE @rows.

    out->write( |Roles for { user }: { concat_lines_of( table = my_roles sep = `, ` ) }| ).
  ENDMETHOD.

ENDCLASS.
