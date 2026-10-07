CLASS lhc_tenant DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Tenant RESULT result.

    METHODS setTenantID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Tenant~setTenantID.

    METHODS validateEmail FOR VALIDATE ON SAVE
      IMPORTING keys FOR Tenant~validateEmail.
ENDCLASS.

CLASS lhc_tenant IMPLEMENTATION.

  METHOD get_global_authorizations.
    " Sprint 6 adds real checks
        result = VALUE #( %create      = if_abap_behv=>auth-allowed
                      %update      = if_abap_behv=>auth-allowed
                      %delete      = if_abap_behv=>auth-allowed
                      %action-Edit = if_abap_behv=>auth-allowed ).
  ENDMETHOD.

  METHOD setTenantID.
    READ ENTITIES OF zwp_r_tenant IN LOCAL MODE
      ENTITY Tenant
        FIELDS ( TenantID ) WITH CORRESPONDING #( keys )
      RESULT DATA(tenants).

    DELETE tenants WHERE TenantID IS NOT INITIAL.
    CHECK tenants IS NOT INITIAL.

    SELECT SINGLE FROM zwp_tenant FIELDS MAX( tenant_id ) INTO @DATA(max_id).
    DATA(last_no) = COND i( WHEN max_id IS INITIAL THEN 0 ELSE CONV i( max_id+1(4) ) ).

    MODIFY ENTITIES OF zwp_r_tenant IN LOCAL MODE
      ENTITY Tenant
        UPDATE FIELDS ( TenantID )
        WITH VALUE #( FOR t IN tenants INDEX INTO i
                      ( %tky     = t-%tky
                        TenantID = |T{ last_no + i WIDTH = 4 ALIGN = RIGHT PAD = '0' }| ) ).
  ENDMETHOD.

  METHOD validateEmail.
    READ ENTITIES OF zwp_r_tenant IN LOCAL MODE
      ENTITY Tenant
        FIELDS ( Email ) WITH CORRESPONDING #( keys )
      RESULT DATA(tenants).

    LOOP AT tenants INTO DATA(tenant).
      APPEND VALUE #( %tky = tenant-%tky %state_area = 'VALIDATE_EMAIL' ) TO reported-tenant.

      IF NOT matches( val = tenant-Email pcre = `^[^@\s]+@[^@\s]+\.[^@\s]+$` ).
        APPEND VALUE #( %tky = tenant-%tky ) TO failed-tenant.
        APPEND VALUE #( %tky           = tenant-%tky
                        %state_area    = 'VALIDATE_EMAIL'
                        %msg           = new_message_with_text(
                                           severity = if_abap_behv_message=>severity-error
                                           text     = 'Enter a valid e-mail address' )
                        %element-Email = if_abap_behv=>mk-on ) TO reported-tenant.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
