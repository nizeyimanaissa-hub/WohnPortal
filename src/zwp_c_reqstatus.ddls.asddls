@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Status history - projection'
@Metadata.allowExtensions: true
define view entity ZWP_C_ReqStatus
  as projection on ZWP_R_ReqStatus
{
  key LogUUID,
      RequestUUID,
      @ObjectModel.text.element: [ 'OldStatusText' ]
      OldStatus,
      _OldStatusText.StatusText as OldStatusText,
      @ObjectModel.text.element: [ 'NewStatusText' ]
      NewStatus,
      _NewStatusText.StatusText as NewStatusText,
      ChangedBy,
      ChangedAt,
      Note,
      LocalLastChangedAt,

      _Request : redirected to parent ZWP_C_MaintRequest
}
