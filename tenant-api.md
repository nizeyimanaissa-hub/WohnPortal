# Tenant API – WohnPortal Mini

OData V4 service behind the **Mein Zuhause** tenant app. It lets a logged-in tenant read their home and their maintenance requests, and report new damage.

| | |
|---|---|
| Service | `ZWP_UI_TENANTAPP` |
| Binding | `ZWP_UI_TENANTAPP_O4` (OData V4 - UI) |
| Base path | `/sap/opu/odata4/sap/zwp_ui_tenantapp_o4/srvd/sap/zwp_ui_tenantapp/0001/` |
| Metadata | `<base path>$metadata` |
| Authentication | SAP BTP user login. The backend links the user to a tenant through `zwp_tenant.app_user`. |

## Security

- **Rows:** every entity is filtered by CDS access control to the logged-in tenant. Requests for other tenants' data return no rows, not an error.
- **Identity:** the client never sends who the tenant is. On create, the backend fills in the tenant and the apartment of their active contract.
- **Changes:** tenants can only create requests. Updates, deletes and status changes happen in the back office.

## Entity sets

### MyHome (read)

One row per current rental contract of the tenant.

| Field | Type | Meaning |
|---|---|---|
| ContractID | string(10) | Contract number, e.g. MV-2026-0001 |
| TenantName | string | Tenant's full name |
| ApartmentID | string(12) | e.g. B0001-01 |
| Floor, Rooms | number | |
| LivingSpace, AreaUnit | decimal, string | e.g. 44.00 M2 |
| BuildingName, Street, HouseNumber, PostalCode, City | string | Address |
| StartDate, EndDate | date | EndDate empty = unlimited |
| MonthlyRent, Deposit, CurrencyCode | decimal, string | Warm rent and deposit, EUR |

### MyRequest (read, create)

| Field | Type | Create | Meaning |
|---|---|---|---|
| RequestID | string(10) | – | e.g. SM-000061, set by the backend |
| Category | string(5) | **required** | PLUMB, ELEC, HEAT, ELEV, DOOR, OTHER (see CategoryVH) |
| CategoryText | string | – | Readable category |
| Title | string(60) | **required** | Short title |
| Description | string | **required** | At least 20 characters |
| Status, StatusText, StatusCriticality | string, string, number | – | N New, A Assigned, P In progress, C Completed, R Rejected |
| ReportedAt | timestamp | – | |
| PlannedDate | date | – | Set when a technician is assigned |
| TechnicianName | string | – | |
| CompletedAt, ResolutionNote | timestamp, string | – | Set when the request is completed or rejected |
| ApartmentID | string | – | Filled in from the tenant's contract |

Navigation: `_StatusLog` → MyRequestStatus.

### MyRequestStatus (read)

Status history of a request: `NewStatus`, `NewStatusText`, `ChangedAt`, `Note`.

### CategoryVH (read)

Category codes with texts in the user's logon language, for the category picker.

## Examples

List my requests, newest first, with history:

```http
GET <base path>MyRequest?$select=RequestID,Title,StatusText,ReportedAt&$expand=_StatusLog($select=NewStatusText,ChangedAt,Note;$orderby=ChangedAt desc)&$orderby=ReportedAt desc
```

My home:

```http
GET <base path>MyHome
```

Report damage:

```http
POST <base path>MyRequest
Content-Type: application/json

{
  "Category": "HEAT",
  "Title": "Heizung kalt",
  "Description": "Seit gestern bleibt die Heizung im Wohnzimmer kalt."
}
```

Response: `201 Created` with the new request, including `RequestID` and `Status` = `N`.

## Errors

Validation errors return `400` with an OData error body. `target` names the field when the error belongs to one.

```json
{
  "error": {
    "code": "...",
    "message": "Describe the problem in 20 characters or more",
    "target": "Description"
  }
}
```

| Message | Cause |
|---|---|
| Choose a category | Category missing |
| Enter a short title | Title missing |
| Describe the problem in 20 characters or more | Description too short |
| Tenant has no active contract here | The user has no active contract |
| You can only report damage for yourself | A `TenantUUID` for another tenant was sent |
