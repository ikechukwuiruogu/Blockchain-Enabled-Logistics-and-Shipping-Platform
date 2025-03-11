;; Condition Monitoring Contract
;; Tracks environmental conditions during transport

(define-map condition-logs
  { shipment-id: uint, log-id: uint }
  {
    temperature: int,
    humidity: uint,
    timestamp: uint
  }
)

(define-map shipment-condition-summary
  { shipment-id: uint }
  {
    min-temperature: int,
    max-temperature: int,
    avg-humidity: uint,
    last-updated: uint
  }
)

(define-data-var last-log-id uint u0)

(define-read-only (get-condition-log (shipment-id uint) (log-id uint))
  (map-get? condition-logs { shipment-id: shipment-id, log-id: log-id })
)

(define-read-only (get-condition-summary (shipment-id uint))
  (map-get? shipment-condition-summary { shipment-id: shipment-id })
)

(define-public (log-condition (shipment-id uint) (temperature int) (humidity uint))
  (let
    (
      (new-log-id (+ (var-get last-log-id) u1))
      (current-summary (default-to
        { min-temperature: temperature, max-temperature: temperature, avg-humidity: humidity, last-updated: u0 }
        (get-condition-summary shipment-id)))
    )
    (var-set last-log-id new-log-id)
    (map-set condition-logs
      { shipment-id: shipment-id, log-id: new-log-id }
      {
        temperature: temperature,
        humidity: humidity,
        timestamp: block-height
      }
    )
    (ok (map-set shipment-condition-summary
      { shipment-id: shipment-id }
      {
        min-temperature: (min temperature (get min-temperature current-summary)),
        max-temperature: (max temperature (get max-temperature current-summary)),
        avg-humidity: (/ (+ humidity (get avg-humidity current-summary)) u2),
        last-updated: block-height
      }
    ))
  )
)

(define-private (min (a int) (b int))
  (if (<= a b) a b)
)

(define-private (max (a int) (b int))
  (if (>= a b) a b)
)

