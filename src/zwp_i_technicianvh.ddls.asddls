@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Technician value help'
@Search.searchable: true
define view entity ZWP_I_TechnicianVH
  as select from ZWP_R_Technician
{
      @UI.hidden: true
      @ObjectModel.text.element: [ 'FullName' ]
  key TechnicianUUID,
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Technician ID'
      TechnicianID,
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Name'
      FullName,
      @EndUserText.label: 'Trade'
      Trade,
      @EndUserText.label: 'City'
      City
}
where IsActive = 'X'
