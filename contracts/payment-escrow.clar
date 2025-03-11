;; Payment Escrow Contract
;; Holds and releases payments based on delivery confirmation

(define-map escrows
  { escrow-id: uint }
  {
    payer: principal,
    payee: principal,
    amount: uint,
    shipment-id: uint,
    status: (string-ascii 20),
    created-at: uint,
    released-at: (optional uint)
  }
)

(define-data-var last-escrow-id uint u0)

(define-read-only (get-escrow (escrow-id uint))
  (map-get? escrows { escrow-id: escrow-id })
)

(define-public (create-escrow (payee principal) (amount uint) (shipment-id uint))
  (let
    (
      (new-escrow-id (+ (var-get last-escrow-id) u1))
    )
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (var-set last-escrow-id new-escrow-id)
    (ok (map-set escrows
      { escrow-id: new-escrow-id }
      {
        payer: tx-sender,
        payee: payee,
        amount: amount,
        shipment-id: shipment-id,
        status: "active",
        created-at: block-height,
        released-at: none
      }
    ))
  )
)

(define-public (release-escrow (escrow-id uint))
  (let
    (
      (escrow (unwrap! (get-escrow escrow-id) (err u404)))
    )
    (asserts! (is-eq (get status escrow) "active") (err u400))
    (asserts! (or (is-eq tx-sender (get payer escrow)) (is-eq tx-sender (get payee escrow))) (err u403))
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get payee escrow))))
    (ok (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow {
        status: "released",
        released-at: (some block-height)
      })
    ))
  )
)

(define-public (refund-escrow (escrow-id uint))
  (let
    (
      (escrow (unwrap! (get-escrow escrow-id) (err u404)))
    )
    (asserts! (is-eq (get status escrow) "active") (err u400))
    (asserts! (is-eq tx-sender (get payer escrow)) (err u403))
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get payer escrow))))
    (ok (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow {
        status: "refunded",
        released-at: (some block-height)
      })
    ))
  )
)

