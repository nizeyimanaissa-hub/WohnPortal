@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'My request history (tenant app)'
define view entity ZWP_C_MyReqStatus
  as projection on ZWP_R_ReqStatus
{
  key LogUUID,
      RequestUUID,
      TenantAppUser,
      @ObjectModel.text.element: [ 'NewStatusText' ]
      NewStatus,
      _NewStatusText.StatusText as NewStatusText,
      ChangedAt,
      Note,
      LocalLastChangedAt,

      _MyRoles,
      _Request : redirected to parent ZWP_C_MyRequest
}
