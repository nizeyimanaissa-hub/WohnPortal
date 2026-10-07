@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Tenant value help'
@Search.searchable: true
define view entity ZWP_I_TenantVH
  as select from ZWP_R_Tenant
{
      @UI.hidden: true
  key TenantUUID,
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Tenant ID'
      TenantID,
      @EndUserText.label: 'Name'
      FullName,
      @Search.defaultSearchElement: true
      @EndUserText.label: 'Last name'
      LastName,
      @EndUserText.label: 'E-mail'
      Email
}
