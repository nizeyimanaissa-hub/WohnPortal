@EndUserText.label: 'Parameter: assign technician'
define abstract entity ZWP_A_AssignParam
{
  @EndUserText.label: 'Technician'
  @Consumption.valueHelpDefinition: [{ entity: { name: 'ZWP_I_TechnicianVH', element: 'TechnicianID' } }]
  TechnicianID : abap.char(8);
  @EndUserText.label: 'Planned date'
  PlannedDate  : abap.dats;
}
