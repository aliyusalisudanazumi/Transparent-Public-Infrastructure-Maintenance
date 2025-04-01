;; Asset Registration Contract
;; Records details of public infrastructure

;; Error codes
(define-constant ERR_UNAUTHORIZED u1)
(define-constant ERR_ASSET_EXISTS u2)
(define-constant ERR_ASSET_NOT_FOUND u3)
(define-constant ERR_INVALID_STATUS u4)

;; Asset types
(define-constant ASSET_TYPE_BRIDGE u1)
(define-constant ASSET_TYPE_ROAD u2)
(define-constant ASSET_TYPE_BUILDING u3)
(define-constant ASSET_TYPE_UTILITY u4)

;; Asset status
(define-constant STATUS_ACTIVE u1)
(define-constant STATUS_MAINTENANCE u2)
(define-constant STATUS_INACTIVE u3)
(define-constant STATUS_DECOMMISSIONED u4)

;; Data structures
(define-map assets
  { asset-id: (string-ascii 24) }
  {
    asset-type: uint,
    name: (string-ascii 100),
    location: (string-ascii 100),
    construction-date: uint,
    status: uint,
    last-updated: uint,
    owner: principal
  }
)

(define-map asset-type-count
  { asset-type: uint }
  { count: uint }
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

;; Asset registration functions
(define-public (register-asset
    (asset-id (string-ascii 24))
    (asset-type uint)
    (name (string-ascii 100))
    (location (string-ascii 100))
    (construction-date uint)
  )
  (begin
    (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
    (asserts! (is-none (map-get? assets {asset-id: asset-id})) (err ERR_ASSET_EXISTS))
    (asserts! (is-valid-asset-type asset-type) (err u5))

    ;; Update asset type count
    (match (map-get? asset-type-count {asset-type: asset-type})
      count-data (map-set asset-type-count
                  {asset-type: asset-type}
                  {count: (+ u1 (get count count-data))})
      (map-set asset-type-count {asset-type: asset-type} {count: u1})
    )

    ;; Add the asset
    (ok (map-set assets
      {asset-id: asset-id}
      {
        asset-type: asset-type,
        name: name,
        location: location,
        construction-date: construction-date,
        status: STATUS_ACTIVE,
        last-updated: block-height,
        owner: tx-sender
      }
    ))
  )
)

(define-public (update-asset-status
    (asset-id (string-ascii 24))
    (new-status uint)
  )
  (begin
    (asserts! (is-authorized) (err ERR_UNAUTHORIZED))
    (asserts! (is-valid-status new-status) (err ERR_INVALID_STATUS))

    (match (map-get? assets {asset-id: asset-id})
      asset-data (ok (map-set assets
                      {asset-id: asset-id}
                      (merge asset-data {
                        status: new-status,
                        last-updated: block-height
                      })
                    ))
      (err ERR_ASSET_NOT_FOUND)
    )
  )
)

(define-public (update-asset-details
    (asset-id (string-ascii 24))
    (name (string-ascii 100))
    (location (string-ascii 100))
  )
  (begin
    (asserts! (is-authorized) (err ERR_UNAUTHORIZED))

    (match (map-get? assets {asset-id: asset-id})
      asset-data (ok (map-set assets
                      {asset-id: asset-id}
                      (merge asset-data {
                        name: name,
                        location: location,
                        last-updated: block-height
                      })
                    ))
      (err ERR_ASSET_NOT_FOUND)
    )
  )
)

;; Read-only functions
(define-read-only (get-asset (asset-id (string-ascii 24)))
  (map-get? assets {asset-id: asset-id})
)

(define-read-only (get-asset-count-by-type (asset-type uint))
  (default-to {count: u0} (map-get? asset-type-count {asset-type: asset-type}))
)

;; Helper functions
(define-private (is-authorized)
  (is-eq tx-sender (var-get contract-owner))
)

(define-private (is-valid-asset-type (asset-type uint))
  (or
    (is-eq asset-type ASSET_TYPE_BRIDGE)
    (is-eq asset-type ASSET_TYPE_ROAD)
    (is-eq asset-type ASSET_TYPE_BUILDING)
    (is-eq asset-type ASSET_TYPE_UTILITY)
  )
)

(define-private (is-valid-status (status uint))
  (or
    (is-eq status STATUS_ACTIVE)
    (is-eq status STATUS_MAINTENANCE)
    (is-eq status STATUS_INACTIVE)
    (is-eq status STATUS_DECOMMISSIONED)
  )
)

