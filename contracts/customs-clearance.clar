;; Customs Clearance Contract
;; Manages documentation for international shipments

(define-map customs-documents
  { shipment-id: uint }
  {
    document-hash: (buff 32),
    status: (string-ascii 20),
    submitted-by: principal,
    approved-by: (optional principal),
    submission-date: uint,
    approval-date: (optional uint)
  }
)

(define-constant contract-owner tx-sender)

(define-read-only (get-customs-document (shipment-id uint))
  (map-get? customs-documents { shipment-id: shipment-id })
)

(define-public (submit-customs-document (shipment-id uint) (document-hash (buff 32)))
  (let
    (
      (existing-doc (get-customs-document shipment-id))
    )
    (asserts! (is-none existing-doc) (err u400))
    (ok (map-set customs-documents
      { shipment-id: shipment-id }
      {
        document-hash: document-hash,
        status: "submitted",
        submitted-by: tx-sender,
        approved-by: none,
        submission-date: block-height,
        approval-date: none
      }
    ))
  )
)

(define-public (approve-customs-document (shipment-id uint))
  (let
    (
      (document (unwrap! (get-customs-document shipment-id) (err u404)))
    )
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (asserts! (is-eq (get status document) "submitted") (err u400))
    (ok (map-set customs-documents
      { shipment-id: shipment-id }
      (merge document {
        status: "approved",
        approved-by: (some tx-sender),
        approval-date: (some block-height)
      })
    ))
  )
)

(define-public (reject-customs-document (shipment-id uint))
  (let
    (
      (document (unwrap! (get-customs-document shipment-id) (err u404)))
    )
    (asserts! (is-eq tx-sender contract-owner) (err u403))
    (asserts! (is-eq (get status document) "submitted") (err u400))
    (ok (map-set customs-documents
      { shipment-id: shipment-id }
      (merge document {
        status: "rejected",
        approved-by: (some tx-sender),
        approval-date: (some block-height)
      })
    ))
  )
)

