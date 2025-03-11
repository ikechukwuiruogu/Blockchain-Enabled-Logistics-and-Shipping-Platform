;; Shipment Tracking Contract
;; Monitors the movement of goods through the supply chain

(define-map shipments
  { shipment-id: uint }
  {
    sender: principal,
    recipient: principal,
    origin: (string-ascii 50),
    destination: (string-ascii 50),
    status: (string-ascii 20),
    last-updated: uint
  }
)

(define-map shipment-updates
  { shipment-id: uint, update-id: uint }
  {
    location: (string-ascii 50),
    status: (string-ascii 20),
    timestamp: uint
  }
)

(define-data-var last-shipment-id uint u0)
(define-data-var last-update-id uint u0)

(define-read-only (get-shipment (shipment-id uint))
  (map-get? shipments { shipment-id: shipment-id })
)

(define-read-only (get-shipment-update (shipment-id uint) (update-id uint))
  (map-get? shipment-updates { shipment-id: shipment-id, update-id: update-id })
)

(define-public (create-shipment (recipient principal) (origin (string-ascii 50)) (destination (string-ascii 50)))
  (let
    (
      (new-shipment-id (+ (var-get last-shipment-id) u1))
    )
    (var-set last-shipment-id new-shipment-id)
    (ok (map-set shipments
      { shipment-id: new-shipment-id }
      {
        sender: tx-sender,
        recipient: recipient,
        origin: origin,
        destination: destination,
        status: "created",
        last-updated: block-height
      }
    ))
  )
)

(define-public (update-shipment-status (shipment-id uint) (location (string-ascii 50)) (status (string-ascii 20)))
  (let
    (
      (shipment (unwrap! (get-shipment shipment-id) (err u404)))
      (new-update-id (+ (var-get last-update-id) u1))
    )
    (asserts! (or (is-eq tx-sender (get sender shipment)) (is-eq tx-sender (get recipient shipment))) (err u403))
    (var-set last-update-id new-update-id)
    (map-set shipment-updates
      { shipment-id: shipment-id, update-id: new-update-id }
      {
        location: location,
        status: status,
        timestamp: block-height
      }
    )
    (ok (map-set shipments
      { shipment-id: shipment-id }
      (merge shipment { status: status, last-updated: block-height })
    ))
  )
)

(define-read-only (get-latest-update (shipment-id uint))
  (map-get? shipment-updates { shipment-id: shipment-id, update-id: (var-get last-update-id) })
)

