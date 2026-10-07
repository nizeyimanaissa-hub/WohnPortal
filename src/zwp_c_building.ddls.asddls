@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Building - projection'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: [ 'BuildingID' ]
define root view entity ZWP_C_Building
  provider contract transactional_query
  as projection on ZWP_R_Building
{
  key BuildingUUID,
      @Search.defaultSearchElement: true
      BuildingID,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      Name,
      Street,
      HouseNumber,
      PostalCode,
      @Search.defaultSearchElement: true
      City,
      YearBuilt,
      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _Apartment : redirected to composition child ZWP_C_Apartment
}
