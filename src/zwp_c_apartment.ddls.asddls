@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Apartment - projection'
@Metadata.allowExtensions: true
@ObjectModel.semanticKey: [ 'ApartmentID' ]
define view entity ZWP_C_Apartment
  as projection on ZWP_R_Apartment
{
  key ApartmentUUID,
      ParentUUID,
      ApartmentID,
      Floor,
      Rooms,
      LivingSpace,
      AreaUnit,
      BaseRent,
      ServiceCharges,
      WarmRent,
      CurrencyCode,
      @ObjectModel.text.element: [ 'StatusText' ]
      Status,
      _StatusText.StatusText as StatusText,
      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _Building : redirected to parent ZWP_C_Building
}
