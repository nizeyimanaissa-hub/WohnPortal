"! <p class="shorttext synchronized" lang="en">Hello World</p>
CLASS zcl_hello_rap_w DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_hello_rap_w IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    DATA(message) = `Hello from ABAP Cloud!`.
    out->write( message ).
  ENDMETHOD.

ENDCLASS.

