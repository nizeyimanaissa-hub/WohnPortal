@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Rental contract - projection'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: [ 'ContractID' ]
define root view entity ZWP_C_Contract
  provider contract transactional_query
  as projection on ZWP_R_Contract
{
  key ContractUUID,
      @Search.defaultSearchElement: true
      ContractID,
      @ObjectModel.text.element: [ 'ApartmentID' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZWP_I_ApartmentVH', element: 'ApartmentUUID' } }]
      ApartmentUUID,
      _Apartment.ApartmentID as ApartmentID,
      @ObjectModel.text.element: [ 'TenantName' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZWP_I_TenantVH', element: 'TenantUUID' } }]
      TenantUUID,
      _Tenant.FullName as TenantName,
      StartDate,
      EndDate,
      MonthlyRent,
      Deposit,
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_CurrencyStdVH', element: 'Currency' } }]
      CurrencyCode,
      @ObjectModel.text.element: [ 'StatusText' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZWP_I_ContrStatusVH', element: 'Status' } }]
      Status,
      _StatusText.StatusText as StatusText,
      StatusCriticality,
      NoticeDate,
      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt
}
