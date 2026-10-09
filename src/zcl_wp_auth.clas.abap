CLASS zcl_wp_auth DEFINITION PUBLIC FINAL CREATE PRIVATE.
  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF roles,
        tenant           TYPE zwp_user_role-role VALUE 'TENANT',
        agent            TYPE zwp_user_role-role VALUE 'AGENT',
        property_manager TYPE zwp_user_role-role VALUE 'PROPERTY_MGR',
      END OF roles.

    "! Technical name of the logged-in user (the same value CDS access control calls "aspect user")
    CLASS-METHODS current_user
      RETURNING VALUE(result) TYPE zwp_user_role-user_id.

    CLASS-METHODS has_role
      IMPORTING required_role TYPE zwp_user_role-role
      RETURNING VALUE(result) TYPE abap_boolean.

    "! True for users who are tenants and nothing else
    CLASS-METHODS is_tenant_only
      RETURNING VALUE(result) TYPE abap_boolean.

    "! The tenant record linked to the logged-in user (zwp_tenant-app_user), or initial
    CLASS-METHODS my_tenant_uuid
      RETURNING VALUE(result) TYPE sysuuid_x16.
ENDCLASS.

CLASS zcl_wp_auth IMPLEMENTATION.

  METHOD current_user.
    result = cl_abap_context_info=>get_user_technical_name( ).
  ENDMETHOD.

  METHOD has_role.
    DATA(user) = current_user( ).
    SELECT SINGLE @abap_true FROM zwp_user_role
      WHERE user_id = @user
        AND role    = @required_role
      INTO @result.
  ENDMETHOD.

  METHOD is_tenant_only.
    result = xsdbool( has_role( roles-tenant ) = abap_true
                  AND has_role( roles-agent ) = abap_false
                  AND has_role( roles-property_manager ) = abap_false ).
  ENDMETHOD.

  METHOD my_tenant_uuid.
    DATA(user) = current_user( ).
    SELECT SINGLE FROM zwp_tenant FIELDS tenant_uuid
      WHERE app_user = @user
      INTO @result.
  ENDMETHOD.

ENDCLASS.
