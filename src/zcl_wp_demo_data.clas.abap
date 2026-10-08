CLASS zcl_wp_demo_data DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_wp_demo_data IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA buildings   TYPE STANDARD TABLE OF zwp_building   WITH EMPTY KEY.
    DATA apartments  TYPE STANDARD TABLE OF zwp_apartment  WITH EMPTY KEY.
    DATA tenants     TYPE STANDARD TABLE OF zwp_tenant     WITH EMPTY KEY.
    DATA contracts   TYPE STANDARD TABLE OF zwp_contract   WITH EMPTY KEY.
    DATA technicians TYPE STANDARD TABLE OF zwp_technician WITH EMPTY KEY.
    DATA requests    TYPE STANDARD TABLE OF zwp_maint_req  WITH EMPTY KEY.
    DATA status_log  TYPE STANDARD TABLE OF zwp_requ_status WITH EMPTY KEY.
    DATA now         TYPE timestampl.

    DATA(cities)  = VALUE string_table( ( `Hannover` ) ( `Bochum` ) ( `Berlin` ) ( `Dresden` ) ( `Hamburg` ) ).
    DATA(postal)  = VALUE string_table( ( `30159` ) ( `44787` ) ( `10115` ) ( `01067` ) ( `20095` ) ).
    DATA(streets) = VALUE string_table( ( `Lindenstraße` ) ( `Am Stadtpark` ) ( `Gartenweg` ) ( `Elbufer` ) ( `Hafenstraße` ) ).
    DATA(first)   = VALUE string_table( ( `Anna` ) ( `Jonas` ) ( `Leyla` ) ( `Marek` ) ( `Sofia` ) ( `Tim` ) ).
    DATA(last)    = VALUE string_table( ( `Becker` ) ( `Schmidt` ) ( `Yilmaz` ) ( `Nowak` ) ( `Wagner` ) ).
    DATA(cats)    = VALUE string_table( ( `PLUMB` ) ( `ELEC` ) ( `HEAT` ) ( `ELEV` ) ( `DOOR` ) ( `OTHER` ) ).
    DATA(stats)   = VALUE string_table( ( `N` ) ( `A` ) ( `P` ) ( `C` ) ).

    DELETE FROM zwp_requ_status.
    DELETE FROM zwp_maint_req.
    DELETE FROM zwp_contract.
    DELETE FROM zwp_tenant.
    DELETE FROM zwp_technician.
    DELETE FROM zwp_apartment.
    DELETE FROM zwp_building.

    DELETE FROM zwp_reqstatus_d.
    DELETE FROM zwp_maint_req_d.
    DELETE FROM zwp_contract_d.
    DELETE FROM zwp_tenant_d.
    DELETE FROM zwp_apartment_d.
    DELETE FROM zwp_building_d.

    GET TIME STAMP FIELD now.

    TRY.
        " Buildings and apartments
        DO 5 TIMES.
          DATA(b) = sy-index.
          DATA(building_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
          APPEND VALUE #( building_uuid = building_uuid
                          building_id   = |B{ b WIDTH = 4 ALIGN = RIGHT PAD = '0' }|
                          name          = |Wohnanlage { streets[ b ] }|
                          street        = streets[ b ]
                          house_number  = |{ b * 3 }|
                          postal_code   = postal[ b ]
                          city          = cities[ b ]
                          year_built    = 1950 + b * 12
                          created_by = sy-uname  created_at = now
                          local_last_changed_by = sy-uname  local_last_changed_at = now
                          last_changed_at = now ) TO buildings.
          DO 8 TIMES.
            DATA(a) = sy-index.
            DATA(area) = 35 + a * 9.
            APPEND VALUE #( apartment_uuid  = cl_system_uuid=>create_uuid_x16_static( )
                            parent_uuid     = building_uuid
                            apartment_id    = |B{ b WIDTH = 4 ALIGN = RIGHT PAD = '0' }-{ a WIDTH = 2 ALIGN = RIGHT PAD = '0' }|
                            floor           = ( a - 1 ) DIV 2
                            rooms           = 1 + a MOD 4
                            living_space    = area
                            area_unit       = 'M2'
                            base_rent       = area * '9.50'
                            service_charges = area * '2.80'
                            currency_code   = 'EUR'
                            status          = 'V'
                            created_by = sy-uname  created_at = now
                            local_last_changed_by = sy-uname  local_last_changed_at = now
                            last_changed_at = now ) TO apartments.
          ENDDO.
        ENDDO.

        " Tenants, each with an active contract on one apartment
        DO 30 TIMES.
          DATA(t) = sy-index.
          DATA(fn) = first[ ( t - 1 ) MOD 6 + 1 ].
          DATA(ln) = last[ ( ( t - 1 ) DIV 6 ) MOD 5 + 1 ].
          DATA(tenant_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
          APPEND VALUE #( tenant_uuid        = tenant_uuid
                          tenant_id          = |T{ t WIDTH = 4 ALIGN = RIGHT PAD = '0' }|
                          first_name         = fn
                          last_name          = ln
                          email              = |{ to_lower( fn ) }.{ to_lower( ln ) }{ t }@example.com|
                          phone              = |+49 511 000{ t WIDTH = 3 ALIGN = RIGHT PAD = '0' }|
                          preferred_language = 'D'
                          app_user           = COND #( WHEN t = 1 THEN sy-uname )
                          created_by = sy-uname  created_at = now
                          local_last_changed_by = sy-uname  local_last_changed_at = now
                          last_changed_at = now ) TO tenants.

          ASSIGN apartments[ t ] TO FIELD-SYMBOL(<apt>).
          <apt>-status = 'L'.
          APPEND VALUE #( contract_uuid  = cl_system_uuid=>create_uuid_x16_static( )
                          contract_id    = |MV-2026-{ t WIDTH = 4 ALIGN = RIGHT PAD = '0' }|
                          apartment_uuid = <apt>-apartment_uuid
                          tenant_uuid    = tenant_uuid
                          start_date     = '20240101'
                          monthly_rent   = <apt>-base_rent + <apt>-service_charges
                          deposit        = <apt>-base_rent * 3
                          currency_code  = 'EUR'
                          status         = 'A'
                          created_by = sy-uname  created_at = now
                          local_last_changed_by = sy-uname  local_last_changed_at = now
                          last_changed_at = now ) TO contracts.
        ENDDO.

        " Technicians, trades cycle through the categories
        DO 8 TIMES.
          DATA(h) = sy-index.
          APPEND VALUE #( technician_uuid = cl_system_uuid=>create_uuid_x16_static( )
                          technician_id   = |H{ h WIDTH = 4 ALIGN = RIGHT PAD = '0' }|
                          full_name       = |{ first[ ( h + 2 ) MOD 6 + 1 ] } { last[ h MOD 5 + 1 ] }|
                          phone           = |+49 30 000{ h WIDTH = 3 ALIGN = RIGHT PAD = '0' }|
                          trade           = cats[ ( h - 1 ) MOD 6 + 1 ]
                          city            = cities[ ( h - 1 ) MOD 5 + 1 ]
                          is_active       = abap_true
                          created_by = sy-uname  created_at = now
                          local_last_changed_by = sy-uname  local_last_changed_at = now
                          last_changed_at = now ) TO technicians.
        ENDDO.

        " Maintenance requests with one status log entry each
        DO 60 TIMES.
          DATA(r) = sy-index.
          DATA(idx) = ( r - 1 ) MOD 30 + 1.
          DATA(cat) = cats[ ( r - 1 ) MOD 6 + 1 ].
          DATA(st)  = stats[ ( r - 1 ) MOD 4 + 1 ].
          DATA(request_uuid) = cl_system_uuid=>create_uuid_x16_static( ).
          DATA(reported) = zcl_wp_sla_calculator=>add_days( timestamp = now days = 0 - ( r MOD 20 ) ).
          DATA(prio)     = CONV zwp_maint_req-priority( ( r - 1 ) MOD 4 + 1 ).
          APPEND VALUE #( request_uuid    = request_uuid
                          request_id      = |SM-{ r WIDTH = 6 ALIGN = RIGHT PAD = '0' }|
                          apartment_uuid  = apartments[ idx ]-apartment_uuid
                          tenant_uuid     = tenants[ idx ]-tenant_uuid
                          technician_uuid = COND #( WHEN st <> `N`
                                                    THEN VALUE #( technicians[ trade = cat ]-technician_uuid OPTIONAL ) )
                          category        = cat
                          priority        = prio
                          title           = |Meldung { r }: { cat }|
                          description     = |Demo-Schadensmeldung Nummer { r }, Kategorie { cat }, bitte prüfen.|
                          status          = st
                          reported_at     = reported
                          due_at          = zcl_wp_sla_calculator=>due_at( reported_at = reported priority = prio )
                          completed_at    = COND #( WHEN st = `C` THEN now )
                          resolution_note = COND #( WHEN st = `C` THEN `Repariert, Funktion geprüft.` )
                          created_by = sy-uname  created_at = now
                          local_last_changed_by = sy-uname  local_last_changed_at = now
                          last_changed_at = now ) TO requests.
          APPEND VALUE #( log_uuid     = cl_system_uuid=>create_uuid_x16_static( )
                          request_uuid = request_uuid
                          new_status   = st
                          changed_by   = sy-uname
                          changed_at   = now
                          local_last_changed_at = now ) TO status_log.
        ENDDO.

      CATCH cx_uuid_error INTO DATA(uuid_error).
        out->write( uuid_error->get_text( ) ).
        RETURN.
    ENDTRY.

    INSERT zwp_building   FROM TABLE @buildings.
    INSERT zwp_apartment  FROM TABLE @apartments.
    INSERT zwp_tenant     FROM TABLE @tenants.
    INSERT zwp_contract   FROM TABLE @contracts.
    INSERT zwp_technician FROM TABLE @technicians.
    INSERT zwp_maint_req  FROM TABLE @requests.
    INSERT zwp_requ_status FROM TABLE @status_log.

    out->write( |{ lines( buildings ) } buildings, { lines( apartments ) } apartments, { lines( tenants ) } tenants, | &&
                |{ lines( contracts ) } contracts, { lines( technicians ) } technicians, { lines( requests ) } requests created.| ).
  ENDMETHOD.

ENDCLASS.
