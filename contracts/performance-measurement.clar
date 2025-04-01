;; Performance Measurement Contract
;; Evaluates infrastructure reliability

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ASSET_NOT_FOUND u2)
(define-constant ERR_INVALID_SCORE u3)

;; Data structures
(define-map performance-metrics
  { asset-id: (string-ascii 24) }
  {
    reliability-score: uint,
    condition-trend: int,
    maintenance-efficiency: uint,
    cost-effectiveness: uint,
    last-updated: uint
  }
)

(define-map performance-history
  { asset-id: (string-ascii 24), year: uint }
  {
    avg-reliability-score: uint,
    total-maintenance-cost: uint,
    downtime-days: uint
  }
)

;; Authorization
(define-data-var contract-owner principal tx-sender)

(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR_UNAUTHORIZED))
    (ok (var-set contract-owner new-owner))
  )
)

;; Performance measurement functions
(define-public (update-performance-metrics
    (asset-id (string-ascii 24))
    (reliability-score uint)
    (condition-trend int)
    (maintenance-efficiency uint)
    (cost-effectiveness uint)
  )
  (begin
    (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
    (asserts! (is-valid-score reliability-score) (err ERR_INVALID_SCORE))
    (asserts! (is-valid-score maintenance-efficiency) (err ERR_INVALID_SCORE))
    (asserts! (is-valid-score cost-effectiveness) (err ERR_INVALID_SCORE))

    (ok (map-set performance-metrics
      {asset-id: asset-id}
      {
        reliability-score: reliability-score,
        condition-trend: condition-trend,
        maintenance-efficiency: maintenance-efficiency,
        cost-effectiveness: cost-effectiveness,
        last-updated: block-height
      }
    ))
  )
)

(define-public (record-annual-performance
    (asset-id (string-ascii 24))
    (year uint)
    (avg-reliability-score uint)
    (total-maintenance-cost uint)
    (downtime-days uint)
  )
  (begin
    (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
    (asserts! (is-valid-score avg-reliability-score) (err ERR_INVALID_SCORE))

    (ok (map-set performance-history
      {asset-id: asset-id, year: year}
      {
        avg-reliability-score: avg-reliability-score,
        total-maintenance-cost: total-maintenance-cost,
        downtime-days: downtime-days
      }
    ))
  )
)

;; Read-only functions
(define-read-only (get-performance-metrics (asset-id (string-ascii 24)))
  (map-get? performance-metrics {asset-id: asset-id})
)

(define-read-only (get-annual-performance (asset-id (string-ascii 24)) (year uint))
  (map-get? performance-history {asset-id: asset-id, year: year})
)

(define-read-only (calculate-overall-score (asset-id (string-ascii 24)))
  (match (map-get? performance-metrics {asset-id: asset-id})
    metrics (some (/ (+ (get reliability-score metrics)
                        (get maintenance-efficiency metrics)
                        (get cost-effectiveness metrics))
                     u3))
    none
  )
)

;; Helper functions
(define-private (is-authorized)
  (is-eq tx-sender (var-get contract-owner))
)

(define-private (is-valid-score (score uint))
  (<= score u100)
)

