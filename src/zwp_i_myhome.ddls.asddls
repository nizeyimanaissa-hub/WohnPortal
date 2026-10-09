@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'My home (tenant app)'
define view entity ZWP_I_MyHome
  as select from ZWP_R_Contract
{
  key ContractUUID,
      ContractID,
      TenantUUID,
      _Tenant.FullName                 as TenantName,
      _Tenant.AppUser                  as TenantAppUser,
      ApartmentUUID,
      _Apartment.ApartmentID           as ApartmentID,
      _Apartment.Floor                 as Floor,
      _Apartment.Rooms                 as Rooms,
      @Semantics.quantity.unitOfMeasure: 'AreaUnit'
      _Apartment.LivingSpace           as LivingSpace,
      _Apartment.AreaUnit              as AreaUnit,
      _Apartment._Building.Name        as BuildingName,
      _Apartment._Building.Street      as Street,
      _Apartment._Building.HouseNumber as HouseNumber,
      _Apartment._Building.PostalCode  as PostalCode,
      _Apartment._Building.City        as City,
      StartDate,
      EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      MonthlyRent,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      Deposit,
      CurrencyCode
}
where ( Status = 'A' or Status = 'T' )
  and ( EndDate = '00000000' or EndDate >= $session.system_date )
