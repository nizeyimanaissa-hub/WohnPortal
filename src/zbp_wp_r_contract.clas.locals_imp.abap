CLASS lhc_contract DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF contract_status,
        draft      TYPE c LENGTH 1 VALUE 'D',
        active     TYPE c LENGTH 1 VALUE 'A',
        terminated TYPE c LENGTH 1 VALUE 'T',
      END OF contract_status.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Contract RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Contract RESULT result.

    METHODS activateContract FOR MODIFY
      IMPORTING keys FOR ACTION Contract~activateContract RESULT result.

    METHODS terminateContract FOR MODIFY
      IMPORTING keys FOR ACTION Contract~terminateContract RESULT result.

    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Contract~setDefaults.

    METHODS fillRentFromApartment FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Contract~fillRentFromApartment.

    METHODS validateReferences FOR VALIDATE ON SAVE
      IMPORTING keys FOR Contract~validateReferences.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Contract~validateDates.

    METHODS validateDeposit FOR VALIDATE ON SAVE
      IMPORTING keys FOR Contract~validateDeposit.
ENDCLASS.

CLASS lhc_contract IMPLEMENTATION.

  METHOD get_global_authorizations.
    DATA(ok) = COND #( WHEN zcl_wp_auth=>has_role( zcl_wp_auth=>roles-property_manager ) = abap_true
                       THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).

    result = VALUE #( %create                   = ok
                      %update                   = ok
                      %delete                   = ok
                      %action-Edit              = ok
                      %action-activateContract  = ok
                      %action-terminateContract = ok ).
  ENDMETHOD.

  METHOD get_instance_features.
    " Activate only saved contracts in status Draft, terminate only active ones.
    " Both are off while a contract is being edited (draft instance).
    READ ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(contracts)
      FAILED failed.

    result = VALUE #( FOR c IN contracts
      ( %tky = c-%tky
        %action-activateContract  = COND #( WHEN c-Status = contract_status-draft
                                             AND c-%is_draft = if_abap_behv=>mk-off
                                            THEN if_abap_behv=>fc-o-enabled
                                            ELSE if_abap_behv=>fc-o-disabled )
        %action-terminateContract = COND #( WHEN c-Status = contract_status-active
                                             AND c-%is_draft = if_abap_behv=>mk-off
                                            THEN if_abap_behv=>fc-o-enabled
                                            ELSE if_abap_behv=>fc-o-disabled ) ) ).
  ENDMETHOD.

  METHOD activateContract.
        DATA free_contracts TYPE TABLE FOR READ RESULT zwp_r_contract\\Contract.
    DATA to_activate    TYPE TABLE FOR UPDATE zwp_r_contract\\Contract.
    DATA conflict_id    TYPE zwp_contract-contract_id.

    READ ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        FIELDS ( ContractUUID ApartmentUUID StartDate EndDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    CHECK contracts IS NOT INITIAL.

    " 1. Overlap check: other active or terminated contracts on the same apartments (one select for all)
    SELECT FROM zwp_contract
      FIELDS contract_uuid, contract_id, apartment_uuid, start_date, end_date
      FOR ALL ENTRIES IN @contracts
      WHERE apartment_uuid = @contracts-ApartmentUUID
        AND ( status = @contract_status-active OR status = @contract_status-terminated )
      INTO TABLE @DATA(occupied).

    DATA(open_end) = CONV d( '99991231' ).   " no end date = unlimited

    LOOP AT contracts INTO DATA(contract).
      CLEAR conflict_id.
      DATA(my_end) = COND d( WHEN contract-EndDate IS INITIAL THEN open_end ELSE contract-EndDate ).

      LOOP AT occupied INTO DATA(other)
           WHERE apartment_uuid = contract-ApartmentUUID
             AND contract_uuid <> contract-ContractUUID.
        DATA(other_end) = COND d( WHEN other-end_date IS INITIAL THEN open_end ELSE other-end_date ).
        IF other-start_date <= my_end AND contract-StartDate <= other_end.
          conflict_id = other-contract_id.
          EXIT.
        ENDIF.
      ENDLOOP.

      IF conflict_id IS NOT INITIAL.
        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.
        APPEND VALUE #( %tky = contract-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Apartment already let: contract { conflict_id }| ) )
          TO reported-contract.
      ELSE.
        APPEND contract TO free_contracts.
      ENDIF.
    ENDLOOP.

    CHECK free_contracts IS NOT INITIAL.

    " 2. Ask the Building BO to set the apartments to Let (cross-BO EML, one call for all)
    MODIFY ENTITIES OF zwp_r_building
      ENTITY Apartment
        EXECUTE markAsLet
        FROM VALUE #( FOR c IN free_contracts
                      ( ApartmentUUID = c-ApartmentUUID
                        %is_draft     = if_abap_behv=>mk-off ) )
      FAILED DATA(apartment_failed).

    " 3. Activate only the contracts whose apartment could be updated
    LOOP AT free_contracts INTO contract.
      IF line_exists( apartment_failed-apartment[ ApartmentUUID = contract-ApartmentUUID ] ).
        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.
        APPEND VALUE #( %tky = contract-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Apartment locked: is its building being edited?' ) )
          TO reported-contract.
      ELSE.
        APPEND VALUE #( %tky = contract-%tky Status = contract_status-active ) TO to_activate.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        UPDATE FIELDS ( Status ) WITH to_activate.

    READ ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        ALL FIELDS WITH CORRESPONDING #( to_activate )
      RESULT DATA(activated).

    result = VALUE #( FOR a IN activated ( %tky = a-%tky %param = a ) ).
  ENDMETHOD.

  METHOD terminateContract.
        DATA valid_contracts TYPE TABLE FOR READ RESULT zwp_r_contract\\Contract.
    DATA to_terminate    TYPE TABLE FOR UPDATE zwp_r_contract\\Contract.

    DATA(today) = cl_abap_context_info=>get_system_date( ).

    READ ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        FIELDS ( ApartmentUUID StartDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    " 1. Check the end date entered in the dialog
    LOOP AT contracts INTO DATA(contract).
      DATA(end_date) = keys[ KEY id %tky = contract-%tky ]-%param-EndDate.

      IF end_date IS INITIAL OR end_date < today OR end_date <= contract-StartDate.
        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.
        APPEND VALUE #( %tky = contract-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'End date must be today or later, after start' ) )
          TO reported-contract.
      ELSE.
        APPEND contract TO valid_contracts.
      ENDIF.
    ENDLOOP.

    CHECK valid_contracts IS NOT INITIAL.

    " 2. Release the apartments for re-letting (cross-BO EML)
    MODIFY ENTITIES OF zwp_r_building
      ENTITY Apartment
        EXECUTE markAsVacant
        FROM VALUE #( FOR c IN valid_contracts
                      ( ApartmentUUID = c-ApartmentUUID
                        %is_draft     = if_abap_behv=>mk-off ) )
      FAILED DATA(apartment_failed).

    " 3. Terminate the contracts whose apartment could be updated
    LOOP AT valid_contracts INTO contract.
      IF line_exists( apartment_failed-apartment[ ApartmentUUID = contract-ApartmentUUID ] ).
        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.
        APPEND VALUE #( %tky = contract-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = 'Apartment locked: is its building being edited?' ) )
          TO reported-contract.
      ELSE.
        APPEND VALUE #( %tky       = contract-%tky
                        Status     = contract_status-terminated
                        EndDate    = keys[ KEY id %tky = contract-%tky ]-%param-EndDate
                        NoticeDate = today ) TO to_terminate.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        UPDATE FIELDS ( Status EndDate NoticeDate ) WITH to_terminate.

    READ ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        ALL FIELDS WITH CORRESPONDING #( to_terminate )
      RESULT DATA(terminated).

    result = VALUE #( FOR t IN terminated ( %tky = t-%tky %param = t ) ).
  ENDMETHOD.

  METHOD setDefaults.
    DATA year TYPE c LENGTH 4.

    READ ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        FIELDS ( ContractID StartDate CurrencyCode ) WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    DELETE contracts WHERE ContractID IS NOT INITIAL.
    CHECK contracts IS NOT INITIAL.

    DATA(today) = cl_abap_context_info=>get_system_date( ).
    year = today+0(4).
    DATA(pattern) = |MV-{ year }-%|.

    " Highest number of this year in active data and in open drafts
    SELECT SINGLE FROM zwp_contract   FIELDS MAX( contract_id ) WHERE contract_id LIKE @pattern INTO @DATA(max_active).
    SELECT SINGLE FROM zwp_contract_d FIELDS MAX( contractid )  WHERE contractid  LIKE @pattern INTO @DATA(max_draft).

    DATA(max_id)  = COND #( WHEN max_draft > max_active THEN max_draft ELSE max_active ).
    DATA(last_no) = COND i( WHEN max_id IS INITIAL THEN 0 ELSE CONV i( max_id+8(4) ) ).

    MODIFY ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        UPDATE FIELDS ( ContractID Status StartDate CurrencyCode )
        WITH VALUE #( FOR c IN contracts INDEX INTO i
                      ( %tky         = c-%tky
                        ContractID   = |MV-{ year }-{ last_no + i WIDTH = 4 ALIGN = RIGHT PAD = '0' }|
                        Status       = contract_status-draft
                        StartDate    = COND #( WHEN c-StartDate IS INITIAL THEN today ELSE c-StartDate )
                        CurrencyCode = COND #( WHEN c-CurrencyCode IS INITIAL THEN 'EUR' ELSE c-CurrencyCode ) ) ).
  ENDMETHOD.

  METHOD fillRentFromApartment.
    " When an apartment is chosen: rent = warm rent, deposit = 3 base rents
    DATA updates TYPE TABLE FOR UPDATE zwp_r_contract\\Contract.

    READ ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        FIELDS ( ApartmentUUID ) WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    DELETE contracts WHERE ApartmentUUID IS INITIAL.
    CHECK contracts IS NOT INITIAL.

    SELECT FROM zwp_r_apartment
      FIELDS ApartmentUUID, BaseRent, ServiceCharges, CurrencyCode
      FOR ALL ENTRIES IN @contracts
      WHERE ApartmentUUID = @contracts-ApartmentUUID
      INTO TABLE @DATA(apartments).

    LOOP AT contracts INTO DATA(contract).
      READ TABLE apartments INTO DATA(apartment) WITH KEY ApartmentUUID = contract-ApartmentUUID.
      IF sy-subrc = 0.
        APPEND VALUE #( %tky         = contract-%tky
                        MonthlyRent  = apartment-BaseRent + apartment-ServiceCharges
                        Deposit      = apartment-BaseRent * 3
                        CurrencyCode = apartment-CurrencyCode ) TO updates.
      ENDIF.
    ENDLOOP.

    MODIFY ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        UPDATE FIELDS ( MonthlyRent Deposit CurrencyCode ) WITH updates.
  ENDMETHOD.

  METHOD validateReferences.
    READ ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        FIELDS ( ApartmentUUID TenantUUID ) WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    LOOP AT contracts INTO DATA(contract).
      APPEND VALUE #( %tky = contract-%tky %state_area = 'VALIDATE_REFERENCES' ) TO reported-contract.

      IF contract-ApartmentUUID IS INITIAL.
        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.
        APPEND VALUE #( %tky                   = contract-%tky
                        %state_area            = 'VALIDATE_REFERENCES'
                        %msg                   = new_message_with_text(
                                                   severity = if_abap_behv_message=>severity-error
                                                   text     = 'Choose an apartment' )
                        %element-ApartmentUUID = if_abap_behv=>mk-on ) TO reported-contract.
      ENDIF.

      IF contract-TenantUUID IS INITIAL.
        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.
        APPEND VALUE #( %tky                = contract-%tky
                        %state_area         = 'VALIDATE_REFERENCES'
                        %msg                = new_message_with_text(
                                                severity = if_abap_behv_message=>severity-error
                                                text     = 'Choose a tenant' )
                        %element-TenantUUID = if_abap_behv=>mk-on ) TO reported-contract.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDates.
    READ ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        FIELDS ( StartDate EndDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    LOOP AT contracts INTO DATA(contract).
      APPEND VALUE #( %tky = contract-%tky %state_area = 'VALIDATE_DATES' ) TO reported-contract.

      IF contract-StartDate IS INITIAL.
        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.
        APPEND VALUE #( %tky               = contract-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = new_message_with_text(
                                               severity = if_abap_behv_message=>severity-error
                                               text     = 'Enter a start date' )
                        %element-StartDate = if_abap_behv=>mk-on ) TO reported-contract.
      ELSEIF contract-EndDate IS NOT INITIAL AND contract-EndDate <= contract-StartDate.
        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.
        APPEND VALUE #( %tky             = contract-%tky
                        %state_area      = 'VALIDATE_DATES'
                        %msg             = new_message_with_text(
                                             severity = if_abap_behv_message=>severity-error
                                             text     = 'The end date must be after the start date' )
                        %element-EndDate = if_abap_behv=>mk-on ) TO reported-contract.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDeposit.
    " § 551 BGB: the deposit may be at most 3 monthly base rents (Kaltmiete)
    READ ENTITIES OF zwp_r_contract IN LOCAL MODE
      ENTITY Contract
        FIELDS ( ApartmentUUID Deposit ) WITH CORRESPONDING #( keys )
      RESULT DATA(contracts).

    CHECK contracts IS NOT INITIAL.

    SELECT FROM zwp_r_apartment
      FIELDS ApartmentUUID, BaseRent
      FOR ALL ENTRIES IN @contracts
      WHERE ApartmentUUID = @contracts-ApartmentUUID
      INTO TABLE @DATA(apartments).

    LOOP AT contracts INTO DATA(contract).
      APPEND VALUE #( %tky = contract-%tky %state_area = 'VALIDATE_DEPOSIT' ) TO reported-contract.

      READ TABLE apartments INTO DATA(apartment) WITH KEY ApartmentUUID = contract-ApartmentUUID.
      IF sy-subrc = 0 AND contract-Deposit > apartment-BaseRent * 3.
        APPEND VALUE #( %tky = contract-%tky ) TO failed-contract.
        APPEND VALUE #( %tky             = contract-%tky
                        %state_area      = 'VALIDATE_DEPOSIT'
                        %msg             = new_message_with_text(
                                             severity = if_abap_behv_message=>severity-error
                                             text     = |Deposit max. 3 base rents ({ apartment-BaseRent * 3 DECIMALS = 2 } EUR)| )
                        %element-Deposit = if_abap_behv=>mk-on ) TO reported-contract.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
