@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Apartment'
define view entity ZWP_R_Apartment
  as select from zwp_apartment
  association to parent ZWP_R_Building as _Building on $projection.ParentUUID = _Building.BuildingUUID
{
  key apartment_uuid              as ApartmentUUID,
      parent_uuid                 as ParentUUID,
      apartment_id                as ApartmentID,
      floor                       as Floor,
      rooms                       as Rooms,
      @Semantics.quantity.unitOfMeasure: 'AreaUnit'
      living_space                as LivingSpace,
      area_unit                   as AreaUnit,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      base_rent                   as BaseRent,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      service_charges             as ServiceCharges,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      base_rent + service_charges as WarmRent,
      currency_code               as CurrencyCode,
      status                      as Status,
      @Semantics.user.createdBy: true
      created_by                  as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                  as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by       as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at       as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at             as LastChangedAt,

      _Building
}
