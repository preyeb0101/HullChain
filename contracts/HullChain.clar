;; HullChain: Immutable Vessel Structural Integrity Certification Smart Contract
;; A Clarity contract for managing vessel inspection records on Stacks blockchain

;; Contract owner (set on deployment)
(define-data-var contract-owner principal tx-sender)

;; Counter for inspection IDs
(define-data-var inspection-counter uint u0)

;; Error codes
(define-constant ERR-UNAUTHORIZED u100)
(define-constant ERR-INVALID-INSPECTOR u101)
(define-constant ERR-INSPECTOR-NOT-ACTIVE u102)
(define-constant ERR-VESSEL-NOT-FOUND u103)
(define-constant ERR-INSPECTION-NOT-FOUND u104)
(define-constant ERR-INVALID-SCORE u105)
(define-constant ERR-ALREADY-REGISTERED u106)
;; Added validation error codes
(define-constant ERR-INVALID-INPUT u107)
(define-constant ERR-EMPTY-STRING u108)

;; Added map definitions before functions
;; Inspector data structure
(define-map inspectors
  { inspector-id: principal }
  {
    name: (string-ascii 256),
    license-number: (string-ascii 50),
    active: bool,
    joined-at: uint
  }
)

;; Vessel registry
(define-map vessels
  { vessel-id: (string-ascii 100) }
  {
    name: (string-ascii 256),
    imo-number: (string-ascii 50),
    owner: principal,
    created-at: uint
  }
)

;; Inspection records
(define-map inspections
  { inspection-id: uint }
  {
    vessel-id: (string-ascii 100),
    inspector: principal,
    hull-condition: (string-ascii 50),
    structural-status: (string-ascii 50),
    compliance-score: uint,
    inspection-date: uint,
    expiry-date: uint,
    notes: (string-ascii 512),
    verified: bool
  }
)

;; Vessel compliance tracking
(define-map vessel-compliance
  { vessel-id: (string-ascii 100) }
  {
    last-inspection-id: uint,
    compliance-status: (string-ascii 20),
    last-updated: uint
  }
)

;; Added input validation helpers
(define-private (is-valid-string (s (string-ascii 256)))
  (> (len s) u0)
)

(define-private (is-valid-string-50 (s (string-ascii 50)))
  (> (len s) u0)
)

(define-private (is-valid-string-100 (s (string-ascii 100)))
  (> (len s) u0)
)

(define-private (is-valid-string-512 (s (string-ascii 512)))
  (> (len s) u0)
)

;; Register a new inspector (owner only)
(define-public (register-inspector (inspector-principal principal) (name (string-ascii 256)) (license (string-ascii 50)))
  (begin
    ;; Added validation checks for inputs before storage
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-UNAUTHORIZED))
    (asserts! (is-valid-string name) (err ERR-EMPTY-STRING))
    (asserts! (is-valid-string-50 license) (err ERR-EMPTY-STRING))
    (asserts! (is-none (map-get? inspectors { inspector-id: inspector-principal })) (err ERR-ALREADY-REGISTERED))
    (map-set inspectors
      { inspector-id: inspector-principal }
      {
        name: name,
        license-number: license,
        active: true,
        joined-at: block-height
      }
    )
    (ok true)
  )
)

;; Deactivate an inspector (owner only)
(define-public (deactivate-inspector (inspector-principal principal))
  (let
    ((inspector-data (map-get? inspectors { inspector-id: inspector-principal })))
    (begin
      (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-UNAUTHORIZED))
      (asserts! (is-some inspector-data) (err ERR-INVALID-INSPECTOR))
      (map-set inspectors
        { inspector-id: inspector-principal }
        (merge (unwrap-panic inspector-data) { active: false })
      )
      (ok true)
    )
  )
)

;; Register a new vessel (owner only)
(define-public (register-vessel (vessel-id (string-ascii 100)) (name (string-ascii 256)) (imo (string-ascii 50)) (owner principal))
  (begin
    ;; Added validation checks for string inputs before storage
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-UNAUTHORIZED))
    (asserts! (is-valid-string-100 vessel-id) (err ERR-EMPTY-STRING))
    (asserts! (is-valid-string name) (err ERR-EMPTY-STRING))
    (asserts! (is-valid-string-50 imo) (err ERR-EMPTY-STRING))
    (asserts! (is-none (map-get? vessels { vessel-id: vessel-id })) (err ERR-ALREADY-REGISTERED))
    (map-set vessels
      { vessel-id: vessel-id }
      {
        name: name,
        imo-number: imo,
        owner: owner,
        created-at: block-height
      }
    )
    (ok true)
  )
)

;; Submit an inspection record (active inspectors only)
(define-public (submit-inspection (vessel-id (string-ascii 100)) (hull-condition (string-ascii 50)) (structural-status (string-ascii 50)) (compliance-score uint) (expiry-days uint) (notes (string-ascii 512)))
  (let
    (
      (inspector-data (map-get? inspectors { inspector-id: tx-sender }))
      (vessel-data (map-get? vessels { vessel-id: vessel-id }))
      (new-inspection-id (+ (var-get inspection-counter) u1))
      (expiry-date (+ block-height (* expiry-days u86400)))
    )
    (begin
      ;; Added validation checks for string inputs before storage
      (asserts! (is-valid-string-100 vessel-id) (err ERR-EMPTY-STRING))
      (asserts! (is-valid-string-50 hull-condition) (err ERR-EMPTY-STRING))
      (asserts! (is-valid-string-50 structural-status) (err ERR-EMPTY-STRING))
      (asserts! (is-valid-string-512 notes) (err ERR-EMPTY-STRING))
      (asserts! (is-some inspector-data) (err ERR-INVALID-INSPECTOR))
      (asserts! (get active (unwrap-panic inspector-data)) (err ERR-INSPECTOR-NOT-ACTIVE))
      (asserts! (is-some vessel-data) (err ERR-VESSEL-NOT-FOUND))
      (asserts! (<= compliance-score u100) (err ERR-INVALID-SCORE))

      (var-set inspection-counter new-inspection-id)

      (map-set inspections
        { inspection-id: new-inspection-id }
        {
          vessel-id: vessel-id,
          inspector: tx-sender,
          hull-condition: hull-condition,
          structural-status: structural-status,
          compliance-score: compliance-score,
          inspection-date: block-height,
          expiry-date: expiry-date,
          notes: notes,
          verified: true
        }
      )

      (map-set vessel-compliance
        { vessel-id: vessel-id }
        {
          last-inspection-id: new-inspection-id,
          compliance-status: (if (>= compliance-score u70) "COMPLIANT" "NON-COMPLIANT"),
          last-updated: block-height
        }
      )

      (ok new-inspection-id)
    )
  )
)

;; Get inspector details (read-only)
(define-read-only (get-inspector (inspector-principal principal))
  (map-get? inspectors { inspector-id: inspector-principal })
)

;; Get vessel details (read-only)
(define-read-only (get-vessel (vessel-id (string-ascii 100)))
  (map-get? vessels { vessel-id: vessel-id })
)

;; Get inspection record (read-only)
(define-read-only (get-inspection (inspection-id uint))
  (map-get? inspections { inspection-id: inspection-id })
)

;; Get vessel compliance status (read-only)
(define-read-only (get-vessel-compliance (vessel-id (string-ascii 100)))
  (map-get? vessel-compliance { vessel-id: vessel-id })
)

;; Check if vessel is compliant (read-only)
(define-read-only (is-vessel-compliant (vessel-id (string-ascii 100)))
  (let
    ((compliance-data (map-get? vessel-compliance { vessel-id: vessel-id })))
    (if (is-some compliance-data)
      (ok (is-eq (get compliance-status (unwrap-panic compliance-data)) "COMPLIANT"))
      (err ERR-VESSEL-NOT-FOUND)
    )
  )
)

;; Get total inspection count (read-only)
(define-read-only (get-inspection-count)
  (ok (var-get inspection-counter))
)
