@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Apartment value help'
@Search.searchable: true
define view entity ZWP_I_ApartmentVH
  as select from ZWP_R_Apartment
{
      @UI.hidden: true
  key ApartmentUUID,
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Apartment'
      ApartmentID,
      @EndUserText.label: 'City'
      _Building.City as City,
      @EndUserText.label: 'Rooms'
      Rooms,
      @ObjectModel.text.element: [ 'StatusText' ]
      @EndUserText.label: 'Status'
      Status,
      _StatusText.StatusText as StatusText
}
