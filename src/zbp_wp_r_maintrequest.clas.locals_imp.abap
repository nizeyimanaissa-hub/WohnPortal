CLASS lhc_maintrequest DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF req_status,
        new         TYPE c LENGTH 1 VALUE 'N',
        assigned    TYPE c LENGTH 1 VALUE 'A',
        in_progress TYPE c LENGTH 1 VALUE 'P',
        completed   TYPE c LENGTH 1 VALUE 'C',
        rejected    TYPE c LENGTH 1 VALUE 'R',
      END OF req_status.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR MaintRequest RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR MaintRequest RESULT result.

    METHODS assignTechnician FOR MODIFY
      IMPORTING keys FOR ACTION MaintRequest~assignTechnician RESULT result.

    METHODS startWork FOR MODIFY
      IMPORTING keys FOR ACTION MaintRequest~startWork RESULT result.

    METHODS complete FOR MODIFY
      IMPORTING keys FOR ACTION MaintRequest~complete RESULT result.

    METHODS reject FOR MODIFY
      IMPORTING keys FOR ACTION MaintRequest~reject RESULT result.

    METHODS setInitialValues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MaintRequest~setInitialValues.

    METHODS setDefaultPriority FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MaintRequest~setDefaultPriority.

    METHODS setTenantAndApartment FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MaintRequest~setTenantAndApartment.

    METHODS calculateDueDate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR MaintRequest~calculateDueDate.

    METHODS validateRequiredFields FOR VALIDATE ON SAVE
      IMPORTING keys FOR MaintRequest~validateRequiredFields.

    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR MaintRequest~validateDescription.

    METHODS validateTenantContract FOR VALIDATE ON SAVE
      IMPORTING keys FOR MaintRequest~validateTenantContract.

    TYPES ty_request  TYPE STRUCTURE FOR READ RESULT zwp_r_maintrequest\\MaintRequest.
    TYPES ty_log_line TYPE STRUCTURE FOR CREATE zwp_r_maintrequest\_StatusLog.

    "! One line for the status history of a request
    METHODS log_line
      IMPORTING request     TYPE ty_request
                new_status  TYPE zwp_maint_req-status
                note        TYPE zwp_requ_status-note OPTIONAL
      RETURNING VALUE(line) TYPE ty_log_line.
ENDCLASS.

CLASS lhc_maintrequest IMPLEMENTATION.

  METHOD get_global_authorizations.
    DATA(is_agent)   = zcl_wp_auth=>has_role( zcl_wp_auth=>roles-agent ).
    DATA(is_tenant)  = zcl_wp_auth=>has_role( zcl_wp_auth=>roles-tenant ).
    DATA(is_manager) = zcl_wp_auth=>has_role( zcl_wp_auth=>roles-property_manager ).

    DATA(can_create) = COND #( WHEN is_agent = abap_true OR is_tenant = abap_true
                               THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    DATA(can_dispatch) = COND #( WHEN is_agent = abap_true
                                 THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).
    DATA(can_delete) = COND #( WHEN is_manager = abap_true
                               THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).

    result = VALUE #( %create                  = can_create
                      %update                  = can_dispatch
                      %delete                  = can_delete
                      %action-Edit             = can_dispatch
                      %action-assignTechnician = can_dispatch
                      %action-startWork        = can_dispatch
                      %action-complete         = can_dispatch
                      %action-reject           = can_dispatch ).
  ENDMETHOD.

  METHOD get_instance_features.
    " Which buttons are on depends on the status; none of the four actions while editing a draft
    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(requests)
      FAILED failed.

    result = VALUE #( FOR r IN requests
      LET active = xsdbool( r-%is_draft = if_abap_behv=>mk-off )
          open   = xsdbool( r-Status = req_status-new OR r-Status = req_status-assigned )
          closed = xsdbool( r-Status = req_status-completed OR r-Status = req_status-rejected )
      IN
      ( %tky = r-%tky
        %action-assignTechnician = COND #( WHEN active = abap_true AND open = abap_true
                                           THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-reject           = COND #( WHEN active = abap_true AND open = abap_true
                                           THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-startWork        = COND #( WHEN active = abap_true AND r-Status = req_status-assigned
                                           THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-complete         = COND #( WHEN active = abap_true AND r-Status = req_status-in_progress
                                           THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled )
        %action-Edit             = COND #( WHEN closed = abap_true
                                           THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled ) ) ).
  ENDMETHOD.

  METHOD log_line.
    DATA now TYPE timestampl.
    GET TIME STAMP FIELD now.

    line = VALUE #( %tky    = request-%tky
                    %target = VALUE #( ( %cid      = |{ request-RequestUUID }{ new_status }|
                                         %is_draft = request-%is_draft
                                         OldStatus = request-Status
                                         NewStatus = new_status
                                         ChangedBy = cl_abap_context_info=>get_user_technical_name( )
                                         ChangedAt = now
                                         Note      = note ) ) ).
  ENDMETHOD.

  METHOD assignTechnician.
    TYPES ty_ids TYPE STANDARD TABLE OF zwp_technician-technician_id WITH EMPTY KEY.
    DATA updates  TYPE TABLE FOR UPDATE zwp_r_maintrequest\\MaintRequest.
    DATA log      TYPE TABLE FOR CREATE zwp_r_maintrequest\_StatusLog.

    DATA(today) = cl_abap_context_info=>get_system_date( ).

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    " All chosen technicians in one select
    DATA(ids) = VALUE ty_ids( FOR k IN keys ( k-%param-TechnicianID ) ).
    SELECT FROM zwp_technician
      FIELDS technician_uuid, technician_id, trade, is_active
      FOR ALL ENTRIES IN @ids
      WHERE technician_id = @ids-table_line
      INTO TABLE @DATA(technicians).

    LOOP AT requests INTO DATA(request).
      DATA(param) = keys[ KEY id %tky = request-%tky ]-%param.
      READ TABLE technicians INTO DATA(technician) WITH KEY technician_id = param-TechnicianID.

      IF sy-subrc <> 0 OR technician-is_active = abap_false.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Choose an active technician' ) ) TO reported-maintrequest.
        CONTINUE.
      ENDIF.

      IF technician-trade <> request-Category AND request-Category <> 'OTHER'.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Technician trade { technician-trade } does not fit { request-Category }| ) )
          TO reported-maintrequest.
        CONTINUE.
      ENDIF.

      IF param-PlannedDate IS NOT INITIAL AND param-PlannedDate < today.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'The planned date cannot be in the past' ) ) TO reported-maintrequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky           = request-%tky
                      TechnicianUUID = technician-technician_uuid
                      PlannedDate    = param-PlannedDate
                      Status         = req_status-assigned ) TO updates.
      APPEND log_line( request    = request
                       new_status = req_status-assigned
                       note       = |Assigned to { technician-technician_id }| ) TO log.
    ENDLOOP.

    MODIFY ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        UPDATE FIELDS ( TechnicianUUID PlannedDate Status ) WITH updates
      ENTITY MaintRequest
        CREATE BY \_StatusLog
        FIELDS ( OldStatus NewStatus ChangedBy ChangedAt Note ) WITH log.

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        ALL FIELDS WITH CORRESPONDING #( updates )
      RESULT DATA(changed).

    result = VALUE #( FOR c IN changed ( %tky = c-%tky %param = c ) ).
  ENDMETHOD.

  METHOD startWork.
    DATA updates TYPE TABLE FOR UPDATE zwp_r_maintrequest\\MaintRequest.
    DATA log     TYPE TABLE FOR CREATE zwp_r_maintrequest\_StatusLog.

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests INTO DATA(request).
      APPEND VALUE #( %tky = request-%tky Status = req_status-in_progress ) TO updates.
      APPEND log_line( request = request new_status = req_status-in_progress ) TO log.
    ENDLOOP.

    MODIFY ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        UPDATE FIELDS ( Status ) WITH updates
      ENTITY MaintRequest
        CREATE BY \_StatusLog
        FIELDS ( OldStatus NewStatus ChangedBy ChangedAt Note ) WITH log.

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        ALL FIELDS WITH CORRESPONDING #( updates )
      RESULT DATA(changed).

    result = VALUE #( FOR c IN changed ( %tky = c-%tky %param = c ) ).
  ENDMETHOD.

  METHOD complete.
    DATA updates TYPE TABLE FOR UPDATE zwp_r_maintrequest\\MaintRequest.
    DATA log     TYPE TABLE FOR CREATE zwp_r_maintrequest\_StatusLog.
    DATA now     TYPE timestampl.

    GET TIME STAMP FIELD now.

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests INTO DATA(request).
      DATA(note) = keys[ KEY id %tky = request-%tky ]-%param-ResolutionNote.

      IF note IS INITIAL.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Enter what was done to fix it' ) ) TO reported-maintrequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky           = request-%tky
                      Status         = req_status-completed
                      CompletedAt    = now
                      ResolutionNote = note ) TO updates.
      APPEND log_line( request = request new_status = req_status-completed note = note ) TO log.
    ENDLOOP.

    MODIFY ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        UPDATE FIELDS ( Status CompletedAt ResolutionNote ) WITH updates
      ENTITY MaintRequest
        CREATE BY \_StatusLog
        FIELDS ( OldStatus NewStatus ChangedBy ChangedAt Note ) WITH log.

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        ALL FIELDS WITH CORRESPONDING #( updates )
      RESULT DATA(changed).

    result = VALUE #( FOR c IN changed ( %tky = c-%tky %param = c ) ).
  ENDMETHOD.

  METHOD reject.
    DATA updates TYPE TABLE FOR UPDATE zwp_r_maintrequest\\MaintRequest.
    DATA log     TYPE TABLE FOR CREATE zwp_r_maintrequest\_StatusLog.

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests INTO DATA(request).
      DATA(reason) = keys[ KEY id %tky = request-%tky ]-%param-Reason.

      IF reason IS INITIAL.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Enter a reason for rejecting' ) ) TO reported-maintrequest.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( %tky           = request-%tky
                      Status         = req_status-rejected
                      ResolutionNote = reason ) TO updates.
      APPEND log_line( request = request new_status = req_status-rejected note = reason ) TO log.
    ENDLOOP.

    MODIFY ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        UPDATE FIELDS ( Status ResolutionNote ) WITH updates
      ENTITY MaintRequest
        CREATE BY \_StatusLog
        FIELDS ( OldStatus NewStatus ChangedBy ChangedAt Note ) WITH log.

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        ALL FIELDS WITH CORRESPONDING #( updates )
      RESULT DATA(changed).

    result = VALUE #( FOR c IN changed ( %tky = c-%tky %param = c ) ).
  ENDMETHOD.

  METHOD setInitialValues.
    " New request: next ID, status New, reported now, first history line
    DATA now TYPE timestampl.

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    DELETE requests WHERE RequestID IS NOT INITIAL.
    CHECK requests IS NOT INITIAL.

    GET TIME STAMP FIELD now.

    SELECT SINGLE FROM zwp_maint_req   FIELDS MAX( request_id ) INTO @DATA(max_active).
    SELECT SINGLE FROM zwp_maint_req_d FIELDS MAX( requestid )  INTO @DATA(max_draft).

    DATA(max_id)  = COND #( WHEN max_draft > max_active THEN max_draft ELSE max_active ).
    DATA(last_no) = COND i( WHEN max_id IS INITIAL THEN 0 ELSE CONV i( max_id+3(6) ) ).

    MODIFY ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        UPDATE FIELDS ( RequestID Status ReportedAt )
        WITH VALUE #( FOR r IN requests INDEX INTO i
                      ( %tky       = r-%tky
                        RequestID  = |SM-{ last_no + i WIDTH = 6 ALIGN = RIGHT PAD = '0' }|
                        Status     = req_status-new
                        ReportedAt = now ) )
      ENTITY MaintRequest
        CREATE BY \_StatusLog
        FIELDS ( OldStatus NewStatus ChangedBy ChangedAt Note )
        WITH VALUE #( FOR r IN requests
                      ( log_line( request = r new_status = req_status-new note = 'Request created' ) ) ).
  ENDMETHOD.

  METHOD setDefaultPriority.
    " Lifts and heating are urgent, doors and other things less so. Only if no priority was chosen yet.
    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        FIELDS ( Category Priority ) WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    DELETE requests WHERE Priority IS NOT INITIAL OR Category IS INITIAL.
    CHECK requests IS NOT INITIAL.

    MODIFY ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        UPDATE FIELDS ( Priority )
        WITH VALUE #( FOR r IN requests
                      ( %tky     = r-%tky
                        Priority = SWITCH #( r-Category WHEN 'ELEV'                   THEN 1
                                                        WHEN 'HEAT' OR 'PLUMB' OR 'ELEC' THEN 2
                                                        WHEN 'DOOR'                   THEN 3
                                                        ELSE 4 ) ) ).
  ENDMETHOD.

  METHOD calculateDueDate.
    DATA now TYPE timestampl.
    GET TIME STAMP FIELD now.

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        FIELDS ( Priority ReportedAt ) WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    DELETE requests WHERE Priority IS INITIAL.
    CHECK requests IS NOT INITIAL.

    MODIFY ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        UPDATE FIELDS ( DueAt )
        WITH VALUE #( FOR r IN requests
                      ( %tky  = r-%tky
                        DueAt = zcl_wp_sla_calculator=>due_at(
                                  reported_at = COND #( WHEN r-ReportedAt IS INITIAL THEN now ELSE r-ReportedAt )
                                  priority    = r-Priority ) ) ).
  ENDMETHOD.

  METHOD validateRequiredFields.
    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        FIELDS ( ApartmentUUID TenantUUID Category Title Priority ) WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests INTO DATA(request).
      APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_REQUIRED' ) TO reported-maintrequest.

      IF request-ApartmentUUID IS INITIAL.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_REQUIRED'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Choose an apartment' )
                        %element-ApartmentUUID = if_abap_behv=>mk-on ) TO reported-maintrequest.
      ENDIF.

      IF request-TenantUUID IS INITIAL.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_REQUIRED'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Choose a tenant' )
                        %element-TenantUUID = if_abap_behv=>mk-on ) TO reported-maintrequest.
      ENDIF.

      IF request-Category IS INITIAL.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_REQUIRED'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Choose a category' )
                        %element-Category = if_abap_behv=>mk-on ) TO reported-maintrequest.
      ENDIF.

      IF request-Title IS INITIAL.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_REQUIRED'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Enter a short title' )
                        %element-Title = if_abap_behv=>mk-on ) TO reported-maintrequest.
      ENDIF.

      IF request-Priority < 1 OR request-Priority > 4.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_REQUIRED'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Priority must be between 1 and 4' )
                        %element-Priority = if_abap_behv=>mk-on ) TO reported-maintrequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDescription.
    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        FIELDS ( Description ) WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests INTO DATA(request).
      APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_DESCRIPTION' ) TO reported-maintrequest.

      IF strlen( request-Description ) < 20.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_DESCRIPTION'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Describe the problem in 20 characters or more' )
                        %element-Description = if_abap_behv=>mk-on ) TO reported-maintrequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

    METHOD validateTenantContract.
    " The tenant must have an active contract for exactly this apartment,
    " and a tenant-only user may only report for themselves
    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        FIELDS ( ApartmentUUID TenantUUID ) WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    CHECK requests IS NOT INITIAL.

    DATA(tenant_only) = zcl_wp_auth=>is_tenant_only( ).
    DATA(my_tenant)   = COND #( WHEN tenant_only = abap_true THEN zcl_wp_auth=>my_tenant_uuid( ) ).

    SELECT FROM zwp_contract
      FIELDS apartment_uuid, tenant_uuid
      FOR ALL ENTRIES IN @requests
      WHERE apartment_uuid = @requests-ApartmentUUID
        AND tenant_uuid    = @requests-TenantUUID
        AND status         = 'A'
      INTO TABLE @DATA(contracts).

    LOOP AT requests INTO DATA(request).
      APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_CONTRACT' ) TO reported-maintrequest.

      CHECK request-ApartmentUUID IS NOT INITIAL AND request-TenantUUID IS NOT INITIAL.

      IF tenant_only = abap_true AND request-TenantUUID <> my_tenant.
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_CONTRACT'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'You can only report damage for yourself' )
                        %element-TenantUUID = if_abap_behv=>mk-on ) TO reported-maintrequest.
        CONTINUE.
      ENDIF.

      IF NOT line_exists( contracts[ apartment_uuid = request-ApartmentUUID tenant_uuid = request-TenantUUID ] ).
        APPEND VALUE #( %tky = request-%tky ) TO failed-maintrequest.
        APPEND VALUE #( %tky = request-%tky %state_area = 'VALIDATE_CONTRACT'
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Tenant has no active contract here' )
                        %element-TenantUUID = if_abap_behv=>mk-on ) TO reported-maintrequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD setTenantAndApartment.
    " Only for tenants: fill in their own tenant record and the apartment of their active contract
    CHECK zcl_wp_auth=>is_tenant_only( ) = abap_true.

    DATA(my_tenant) = zcl_wp_auth=>my_tenant_uuid( ).
    CHECK my_tenant IS NOT INITIAL.

    SELECT SINGLE FROM zwp_contract FIELDS apartment_uuid
      WHERE tenant_uuid = @my_tenant
        AND status      = 'A'
      INTO @DATA(my_apartment).

    READ ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        FIELDS ( TenantUUID ApartmentUUID ) WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    MODIFY ENTITIES OF zwp_r_maintrequest IN LOCAL MODE
      ENTITY MaintRequest
        UPDATE FIELDS ( TenantUUID ApartmentUUID )
        WITH VALUE #( FOR r IN requests
                      ( %tky          = r-%tky
                        TenantUUID    = COND #( WHEN r-TenantUUID    IS INITIAL THEN my_tenant    ELSE r-TenantUUID )
                        ApartmentUUID = COND #( WHEN r-ApartmentUUID IS INITIAL THEN my_apartment ELSE r-ApartmentUUID ) ) ).
  ENDMETHOD.

ENDCLASS.
