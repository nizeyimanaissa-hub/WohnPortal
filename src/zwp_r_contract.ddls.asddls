@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Rental contract'
define root view entity ZWP_R_Contract
  as select from zwp_contract
  association [1..1] to ZWP_R_Apartment as _Apartment on $projection.ApartmentUUID = _Apartment.ApartmentUUID
  association [1..1] to ZWP_R_Tenant    as _Tenant    on $projection.TenantUUID = _Tenant.TenantUUID
  association [0..1] to ZWP_I_ContrStatusVH as _StatusText on $projection.Status        = _StatusText.Status
{
  key contract_uuid         as ContractUUID,
      contract_id           as ContractID,
      apartment_uuid        as ApartmentUUID,
      tenant_uuid           as TenantUUID,
      start_date            as StartDate,
      end_date              as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      monthly_rent          as MonthlyRent,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      deposit               as Deposit,
      currency_code         as CurrencyCode,
      status                as Status,
      case status
        when 'A' then 3
        when 'T' then 1
        else 0
      end                   as StatusCriticality,
      notice_date           as NoticeDate,
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

      _Apartment,
      _Tenant,
      _StatusText
}
