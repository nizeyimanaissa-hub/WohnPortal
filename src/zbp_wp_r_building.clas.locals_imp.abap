CLASS lhc_building DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Building RESULT result.

    METHODS setBuildingID FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Building~setBuildingID.

    METHODS validatePostalCode FOR VALIDATE ON SAVE
      IMPORTING keys FOR Building~validatePostalCode.
ENDCLASS.

CLASS lhc_building IMPLEMENTATION.

  METHOD get_global_authorizations.
    DATA(ok) = COND #( WHEN zcl_wp_auth=>has_role( zcl_wp_auth=>roles-property_manager ) = abap_true
                       THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ).

    result = VALUE #( %create      = ok
                      %update      = ok
                      %delete      = ok
                      %action-Edit = ok ).
  ENDMETHOD.

  METHOD setBuildingID.
    READ ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Building
        FIELDS ( BuildingID ) WITH CORRESPONDING #( keys )
      RESULT DATA(buildings).

    DELETE buildings WHERE BuildingID IS NOT INITIAL.
    CHECK buildings IS NOT INITIAL.

    " Highest ID in active data and in open drafts
    SELECT SINGLE FROM zwp_building   FIELDS MAX( building_id ) INTO @DATA(max_active).
    SELECT SINGLE FROM zwp_building_d FIELDS MAX( buildingid )  INTO @DATA(max_draft).

    DATA(max_id)  = COND #( WHEN max_draft > max_active THEN max_draft ELSE max_active ).
    DATA(last_no) = COND i( WHEN max_id IS INITIAL THEN 0 ELSE CONV i( max_id+1 ) ).

    MODIFY ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Building
        UPDATE FIELDS ( BuildingID )
        WITH VALUE #( FOR b IN buildings INDEX INTO i
                      ( %tky       = b-%tky
                        BuildingID = |B{ last_no + i WIDTH = 4 ALIGN = RIGHT PAD = '0' }| ) ).
  ENDMETHOD.

  METHOD validatePostalCode.
    READ ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Building
        FIELDS ( PostalCode ) WITH CORRESPONDING #( keys )
      RESULT DATA(buildings).

    LOOP AT buildings INTO DATA(building).
      " Clear old messages of this check first
      APPEND VALUE #( %tky = building-%tky %state_area = 'VALIDATE_POSTALCODE' ) TO reported-building.

      IF strlen( building-PostalCode ) <> 5 OR building-PostalCode CN '0123456789'.
        APPEND VALUE #( %tky = building-%tky ) TO failed-building.
        APPEND VALUE #( %tky                = building-%tky
                        %state_area         = 'VALIDATE_POSTALCODE'
                        %msg                = new_message_with_text(
                                                severity = if_abap_behv_message=>severity-error
                                                text     = 'The postal code must have exactly 5 digits' )
                        %element-PostalCode = if_abap_behv=>mk-on ) TO reported-building.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lhc_apartment DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Apartment~setDefaults.

    METHODS calculateWarmRent FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Apartment~calculateWarmRent.

    METHODS setApartmentID FOR DETERMINE ON SAVE
      IMPORTING keys FOR Apartment~setApartmentID.

    METHODS validateApartmentValues FOR VALIDATE ON SAVE
      IMPORTING keys FOR Apartment~validateApartmentValues.

    METHODS markAsLet FOR MODIFY
      IMPORTING keys FOR ACTION Apartment~markAsLet.

    METHODS markAsVacant FOR MODIFY
      IMPORTING keys FOR ACTION Apartment~markAsVacant.
ENDCLASS.

CLASS lhc_apartment IMPLEMENTATION.

  METHOD setDefaults.
    MODIFY ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Apartment
        UPDATE FIELDS ( Status CurrencyCode AreaUnit )
        WITH VALUE #( FOR key IN keys
                      ( %tky         = key-%tky
                        Status       = 'V'
                        CurrencyCode = 'EUR'
                        AreaUnit     = 'M2' ) ).
  ENDMETHOD.

  METHOD calculateWarmRent.
    READ ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Apartment
        FIELDS ( BaseRent ServiceCharges ) WITH CORRESPONDING #( keys )
      RESULT DATA(apartments).

    MODIFY ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Apartment
        UPDATE FIELDS ( WarmRent )
        WITH VALUE #( FOR apt IN apartments
                      ( %tky     = apt-%tky
                        WarmRent = apt-BaseRent + apt-ServiceCharges ) ).
  ENDMETHOD.

  METHOD setApartmentID.
    TYPES: BEGIN OF ty_counter,
             parent  TYPE sysuuid_x16,
             last_no TYPE i,
           END OF ty_counter.
    DATA counters    TYPE HASHED TABLE OF ty_counter WITH UNIQUE KEY parent.
    DATA parents     TYPE SORTED TABLE OF sysuuid_x16 WITH UNIQUE KEY table_line.
    DATA updates     TYPE TABLE FOR UPDATE zwp_r_building\\Apartment.
    DATA building_id TYPE zwp_building-building_id.
    DATA last_id     TYPE zwp_apartment-apartment_id.

    READ ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Apartment
        FIELDS ( ApartmentID ParentUUID ) WITH CORRESPONDING #( keys )
      RESULT DATA(apartments).

    DELETE apartments WHERE ApartmentID IS NOT INITIAL.
    CHECK apartments IS NOT INITIAL.

    " Building IDs of the parents (one read for all apartments)
    READ ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Apartment BY \_Building
        FIELDS ( BuildingID ) WITH CORRESPONDING #( apartments )
      RESULT DATA(buildings).

    " Highest existing apartment ID per building (one select, no loop)
    LOOP AT apartments INTO DATA(apt).
      INSERT apt-ParentUUID INTO TABLE parents.
    ENDLOOP.

    SELECT FROM zwp_apartment AS a
      INNER JOIN @parents AS p ON a~parent_uuid = p~table_line
      FIELDS a~parent_uuid, MAX( a~apartment_id ) AS max_id
      GROUP BY a~parent_uuid
      INTO TABLE @DATA(max_ids).

    LOOP AT apartments INTO apt.
      ASSIGN counters[ parent = apt-ParentUUID ] TO FIELD-SYMBOL(<counter>).
      IF sy-subrc <> 0.
        last_id = VALUE #( max_ids[ parent_uuid = apt-ParentUUID ]-max_id OPTIONAL ).
        INSERT VALUE #( parent  = apt-ParentUUID
                        last_no = COND #( WHEN last_id IS INITIAL THEN 0
                                          ELSE CONV i( substring( val = last_id off = strlen( last_id ) - 2 len = 2 ) ) ) )
          INTO TABLE counters ASSIGNING <counter>.
      ENDIF.
      <counter>-last_no += 1.

      building_id = VALUE #( buildings[ BuildingUUID = apt-ParentUUID ]-BuildingID OPTIONAL ).
      APPEND VALUE #( %tky        = apt-%tky
                      ApartmentID = |{ building_id }-{ <counter>-last_no WIDTH = 2 ALIGN = RIGHT PAD = '0' }| )
        TO updates.
    ENDLOOP.

    MODIFY ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Apartment
        UPDATE FIELDS ( ApartmentID ) WITH updates.
  ENDMETHOD.

  METHOD validateApartmentValues.
    READ ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Apartment
        FIELDS ( ParentUUID Rooms LivingSpace BaseRent ServiceCharges ) WITH CORRESPONDING #( keys )
      RESULT DATA(apartments).

    LOOP AT apartments INTO DATA(apt).
      APPEND VALUE #( %tky = apt-%tky %state_area = 'VALIDATE_VALUES' ) TO reported-apartment.

      IF apt-Rooms <= 0 OR apt-LivingSpace <= 0 OR apt-BaseRent <= 0 OR apt-ServiceCharges < 0.
        APPEND VALUE #( %tky = apt-%tky ) TO failed-apartment.
        APPEND VALUE #( %tky        = apt-%tky
                        %state_area = 'VALIDATE_VALUES'
                        %msg        = new_message_with_text(
                                        severity = if_abap_behv_message=>severity-error
                                        text = 'Rooms, space and base rent must be above 0' )
                        %path       = VALUE #( building-%is_draft    = apt-%is_draft
                                               building-BuildingUUID = apt-ParentUUID )
                        %element-Rooms       = if_abap_behv=>mk-on
                        %element-LivingSpace = if_abap_behv=>mk-on
                        %element-BaseRent    = if_abap_behv=>mk-on ) TO reported-apartment.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD markAsLet.
    MODIFY ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Apartment
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky Status = 'L' ) ).
  ENDMETHOD.

  METHOD markAsVacant.
    MODIFY ENTITIES OF zwp_r_building IN LOCAL MODE
      ENTITY Apartment
        UPDATE FIELDS ( Status )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky Status = 'V' ) ).
  ENDMETHOD.

ENDCLASS.
