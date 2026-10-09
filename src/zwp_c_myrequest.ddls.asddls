@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'My maintenance requests (tenant app)'
@ObjectModel.semanticKey: [ 'RequestID' ]
define root view entity ZWP_C_MyRequest
  provider contract transactional_query
  as projection on ZWP_R_MaintRequest
{
  key RequestUUID,
      RequestID,
      ApartmentUUID,
      _Apartment.ApartmentID     as ApartmentID,
      TenantUUID,
      TenantAppUser,
      @ObjectModel.text.element: [ 'CategoryText' ]
      Category,
      _CategoryText.CategoryText as CategoryText,
      Title,
      Description,
      @ObjectModel.text.element: [ 'StatusText' ]
      Status,
      _StatusText.StatusText     as StatusText,
      StatusCriticality,
      ReportedAt,
      PlannedDate,
      CompletedAt,
      ResolutionNote,
      _Technician.FullName       as TechnicianName,
      LocalLastChangedAt,

      _MyRoles,
      _StatusLog : redirected to composition child ZWP_C_MyReqStatus
}
