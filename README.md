
 HullChain  Immutable Vessel Inspection Smart Contract

A Clarity smart contract for Stacks blockchain that provides immutable, tamperproof vessel structural integrity certification and inspection records for the marine industry.

 Overview

HullChain enables marine authorities, port operators, and insurance providers to securely record and verify vessel inspections onchain. All inspection records are immutable, timestamped, and automatically enforce compliance rules based on structural assessments.


 Features

 Inspector Credential Management: Register maritime inspectors with license numbers and activate/deactivate status
 Vessel Registry: Track vessels by unique ID, IMO number, vessel name, and registered owner
 Immutable Inspections: Submit detailed inspection records with hull condition, structural status, and compliance scoring
 Automatic Compliance Determination: Vessels with compliance score >= 70 are marked COMPLIANT< 70 marked NONCOMPLIANT
 Expiry Tracking: Inspections have configurable expiry dates (specified in days from submission)
 Full Audit Trail: All inspection records permanently stored with block height timestamps
 Access Control: Contract owner (deployer) manages inspector and vessel registrationonly active inspectors can submit inspections
 ReadOnly Queries: Public functions to lookup inspector, vessel, and inspection details

 Contract Architecture

 Data Maps

inspectors
 Key: inspector principal address
 Value: name, licensenumber, active status, joinedat block height

vessels
 Key: vesselid (string ASCII 100 chars max)
 Value: vessel name, IMO number, registered owner, createdat block height

inspections
 Key: inspectionid (autoincrementing uint)
 Value: vesselid, inspector principal, hullcondition, structuralstatus, compliancescore (0100), inspectiondate, expirydate, notes, verified flag

vesselcompliance
 Key: vesselid
 Value: lastinspectionid, compliancestatus (COMPLIANT or NONCOMPLIANT), lastupdated block height

 Public Functions

 registerinspector(inspectorprincipal, name, license)
Registers a new maritime inspector. Only callable by contract owner.
 Parameters: Inspector principal address, name (256 char limit), license number (50 char limit)
 Returns: ok if successful, err if already registered or unauthorized

 deactivateinspector(inspectorprincipal)
Deactivates an inspector, preventing future inspections from that inspector. Only callable by contract owner.
 Parameters: Inspector principal address
 Returns: ok if successful, err if unauthorized or inspector not found

 registervessel(vesselid, name, imo, owner)
Registers a new vessel in the system. Only callable by contract owner.
 Parameters: Vessel ID (100 char limit), vessel name (256 char limit), IMO number (50 char limit), owner principal
 Returns: ok if successful, err if unauthorized

 submitinspection(vesselid, hullcondition, structuralstatus, compliancescore, expirydays, notes)
Submits a new inspection record for a vessel. Only active registered inspectors can call this.
 Parameters: 
   vesselid: vessel identifier (100 char limit)
   hullcondition: condition assessment (50 char limit, e.g., "EXCELLENT", "GOOD", "FAIR", "POOR")
   structuralstatus: structural assessment (50 char limit, e.g., "SOUND", "MINOR_ISSUES", "MAJOR_ISSUES")
   compliancescore: numeric score 0100 (>= 70 = COMPLIANT)
   expirydays: number of days until inspection expires
   notes: inspection notes/observations (512 char limit)
 Returns: ok with new inspectionid, err if unauthorized, vessel not found, invalid score, or inspector not active

 ReadOnly Functions

 getinspector(inspectorprincipal) → (optional inspectordata)
Retrieves inspector details by principal address.

 getvessel(vesselid) → (optional vesseldata)
Retrieves vessel details by ID.

 getinspection(inspectionid) → (optional inspectiondata)
Retrieves inspection record details by inspection ID.

 getvesselcompliance(vesselid) → (optional compliancerecord)
Retrieves the latest compliance status for a vessel.

 isvesselcompliant(vesselid) → (ok bool | err)
Checks if a vessel is currently COMPLIANT based on its latest inspection.

 getinspectioncount() → (ok inspectioncounter)
Returns total number of inspections submitted.

 Error Codes

 100: Unauthorized  caller is not contract owner (for owneronly functions)
 101: Invalid inspector  inspector principal not registered
 102: Inspector not active  inspector has been deactivated
 103: Vessel not found  vesselid not in registry
 104: Inspection not found  inspectionid does not exist
 105: Invalid score  compliance score exceeds 100
 106: Already registered  inspector or vessel already exists

 Usage Example

clarity
;Register an inspector (contract owner only)
(contractcall? .hullchain registerinspector 'SPxxxx "John Smith" "USCG12345")

;Register a vessel (contract owner only)
(contractcall? .hullchain registervessel "VESSEL001" "MV Integrity" "1234567" 'SPyyyy)

;Submit an inspection (as registered inspector)
(contractcall? .hullchain submitinspection
  "VESSEL001"
  "EXCELLENT"
  "SOUND"
  u85
  u90
  "All structural systems nominal. No issues found."
)

;Check vessel compliance
(contractcall? .hullchain isvesselcompliant "VESSEL001")

;Get vessel compliance status
(contractcall? .hullchain getvesselcompliance "VESSEL001")


 Deployment

1. Ensure you have Clarinet installed
2. Create a new Clarinet project: clarinet new hullchain
3. Place hullchain.clar in the contracts/ directory
4. Run clarinet check to verify no syntax errors
5. Deploy to testnet or mainnet as needed


 Design Decisions

 Compliance Score Threshold: Set at 70/100 to align with typical maritime regulatory standards (70% represents acceptable operational status)
 Expiry Dates: Configurable per inspection to accommodate different inspection types and vessel risk profiles
 Immutability: All inspection records are permanent and cannot be modified, ensuring audit trail integrity
 Active Inspector Flag: Allows temporary disabling of inspectors without deleting their history
 ASCII Strings: Used for vessel IDs, hull/structural assessments to minimize onchain storage cost while maintaining readability


 Security Considerations

 Only contract owner (deployer) can register inspectors and vessels
 Only active registered inspectors can submit inspections
 All inspection records are immutable once recorded
 Compliance logic is deterministic (score >= 70 = COMPLIANT)
 Principalbased access control prevents unauthorized submissions


 Future Enhancements

 Multisignature approval for critical operations
 Inspector reputation scoring based on inspection accuracy
 Integration with oracle services for realtime vessel status feeds
 Tokenized inspection certificates for easier transfer between stakeholders
 Advanced compliance rules (weighted scoring, conditional logic)


 License

MIT

