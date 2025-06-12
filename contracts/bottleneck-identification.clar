;; Efficiency Measurement Contract
;; Measures and tracks process efficiency metrics

(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_NOT_FOUND (err u301))
(define-constant ERR_INVALID_METRIC (err u302))

;; Data structures
(define-map efficiency-metrics uint {
    process-id: uint,
    completion-time: uint,
    resource-usage: uint,
    quality-score: uint,
    cost: uint,
    measured-by: principal,
    measured-at: uint
})

(define-map process-benchmarks uint {
    target-completion-time: uint,
    target-resource-usage: uint,
    target-quality-score: uint,
    target-cost: uint
})

(define-data-var next-metric-id uint u1)

;; Record efficiency measurement
(define-public (record-measurement (process-id uint) (completion-time uint) (resource-usage uint) (quality-score uint) (cost uint))
    (let ((metric-id (var-get next-metric-id)))
        (begin
            (asserts! (> completion-time u0) ERR_INVALID_METRIC)
            (asserts! (<= quality-score u100) ERR_INVALID_METRIC)

            (map-set efficiency-metrics metric-id {
                process-id: process-id,
                completion-time: completion-time,
                resource-usage: resource-usage,
                quality-score: quality-score,
                cost: cost,
                measured-by: tx-sender,
                measured-at: block-height
            })

            (var-set next-metric-id (+ metric-id u1))
            (ok metric-id)
        )
    )
)

;; Set process benchmarks
(define-public (set-benchmark (process-id uint) (target-time uint) (target-resources uint) (target-quality uint) (target-cost uint))
    (begin
        (map-set process-benchmarks process-id {
            target-completion-time: target-time,
            target-resource-usage: target-resources,
            target-quality-score: target-quality,
            target-cost: target-cost
        })
        (ok true)
    )
)

;; Calculate efficiency score (0-100)
(define-read-only (calculate-efficiency-score (metric-id uint))
    (match (map-get? efficiency-metrics metric-id)
        metric-data
        (match (map-get? process-benchmarks (get process-id metric-data))
            benchmark-data
            (let (
                (time-efficiency (if (> (get target-completion-time benchmark-data) u0)
                    (/ (* (get target-completion-time benchmark-data) u100) (get completion-time metric-data))
                    u0))
                (resource-efficiency (if (> (get target-resource-usage benchmark-data) u0)
                    (/ (* (get target-resource-usage benchmark-data) u100) (get resource-usage metric-data))
                    u0))
                (quality-efficiency (get quality-score metric-data))
                (cost-efficiency (if (> (get target-cost benchmark-data) u0)
                    (/ (* (get target-cost benchmark-data) u100) (get cost metric-data))
                    u0))
            )
            (some (/ (+ time-efficiency resource-efficiency quality-efficiency cost-efficiency) u4)))
            none
        )
        none
    )
)

;; Read-only functions
(define-read-only (get-metric (metric-id uint))
    (map-get? efficiency-metrics metric-id)
)

(define-read-only (get-benchmark (process-id uint))
    (map-get? process-benchmarks process-id)
)
