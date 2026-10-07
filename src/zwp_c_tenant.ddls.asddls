@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Tenant - projection'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: [ 'TenantID' ]
define root view entity ZWP_C_Tenant
  provider contract transactional_query
  as projection on ZWP_R_Tenant
{
  key TenantUUID,
      @Search.defaultSearchElement: true
      TenantID,
      FirstName,
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      LastName,
      FullName,
      Email,
      Phone,
      PreferredLanguage,
      AppUser,
      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt
}
