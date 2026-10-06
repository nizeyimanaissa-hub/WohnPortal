@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Technician value help'
define view entity ZWP_I_TechnicianVH
  as select from ZWP_R_Technician
{
      @ObjectModel.text.element: [ 'FullName' ]
  key TechnicianUUID,
      TechnicianID,
      @Semantics.text: true
      FullName,
      Trade,
      City
}
where IsActive = 'X'
