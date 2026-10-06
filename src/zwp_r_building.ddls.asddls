@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Building'
define root view entity ZWP_R_Building
  as select from zwp_building
  composition [0..*] of ZWP_R_Apartment as _Apartment
{
  key building_uuid         as BuildingUUID,
      building_id           as BuildingID,
      name                  as Name,
      street                as Street,
      house_number          as HouseNumber,
      postal_code           as PostalCode,
      city                  as City,
      year_built            as YearBuilt,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,

      _Apartment
}
