@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Maintenance request - projection'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: [ 'RequestID' ]
define root view entity ZWP_C_MaintRequest
  provider contract transactional_query
  as projection on ZWP_R_MaintRequest
{
  key RequestUUID,
      @Search.defaultSearchElement: true
      RequestID,
      @ObjectModel.text.element: [ 'ApartmentID' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZWP_I_ApartmentVH', element: 'ApartmentUUID' } }]
      ApartmentUUID,
      _Apartment.ApartmentID          as ApartmentID,
      _Apartment._Building.City       as City,
      @ObjectModel.text.element: [ 'TenantName' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZWP_I_TenantVH', element: 'TenantUUID' } }]
      TenantUUID,
      _Tenant.FullName                as TenantName,
      @ObjectModel.text.element: [ 'TechnicianName' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZWP_I_TechnicianVH', element: 'TechnicianUUID' } }]
      TechnicianUUID,
      _Technician.FullName            as TechnicianName,
      @ObjectModel.text.element: [ 'CategoryText' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZWP_I_CategoryVH', element: 'Category' } }]
      Category,
      _CategoryText.CategoryText      as CategoryText,
      Priority,
      PriorityCriticality,
      @Search.defaultSearchElement: true
      Title,
      Description,
      @ObjectModel.text.element: [ 'StatusText' ]
      @Consumption.valueHelpDefinition: [{ entity: { name: 'ZWP_I_ReqStatusVH', element: 'Status' } }]
      Status,
      _StatusText.StatusText          as StatusText,
      StatusCriticality,
      ReportedAt,
      DueAt,
      PlannedDate,
      CompletedAt,
      ResolutionNote,
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_WP_VE_OVERDUE'
      virtual IsOverdue          : abap_boolean,
      @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_WP_VE_OVERDUE'
      virtual OverdueCriticality : abap.int1,
      CreatedBy,
      CreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,

      _StatusLog : redirected to composition child ZWP_C_ReqStatus
}
