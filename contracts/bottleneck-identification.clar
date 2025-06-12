;; Bottleneck Identification Contract
;; Identifies and tracks process bottlenecks

(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_NOT_FOUND (err u401))
(define-constant ERR_INVALID_SEVERITY (err u402))

;; Data structures
(define-map bottlenecks uint {
    process-id: uint,
    step-index: uint,
    description: (string-ascii 200),
    severity: uint, ;; 1-5 scale
    impact-score: uint,
    identified-by: principal,
    identified-at: uint,
    status: (string-ascii 20) ;; "open", "investigating", "resolved"
})

(define-map bottleneck-solutions uint {
    bottleneck-id: uint,
    solution: (string-ascii 300),
    estimated-improvement: uint,
    implementation-cost: uint,
    proposed-by: principal,
    proposed-at: uint
})

(define-data-var next-bottleneck-id uint u1)
(define-data-var next-solution-id uint u1)

;; Identify a new bottleneck
(define-public (identify-bottleneck (process-id uint) (step-index uint) (description (string-ascii 200)) (severity uint) (impact-score uint))
    (let ((bottleneck-id (var-get next-bottleneck-id)))
        (begin
            (asserts! (and (>= severity u1) (<= severity u5)) ERR_INVALID_SEVERITY)
            (asserts! (<= impact-score u100) ERR_INVALID_SEVERITY)

            (map-set bottlenecks bottleneck-id {
                process-id: process-id,
                step-index: step-index,
                description: description,
                severity: severity,
                impact-score: impact-score,
                identified-by: tx-sender,
                identified-at: block-height,
                status: "open"
            })

            (var-set next-bottleneck-id (+ bottleneck-id u1))
            (ok bottleneck-id)
        )
    )
)

;; Propose solution for bottleneck
(define-public (propose-solution (bottleneck-id uint) (solution (string-ascii 300)) (estimated-improvement uint) (implementation-cost uint))
    (let ((solution-id (var-get next-solution-id)))
        (begin
            (asserts! (is-some (map-get? bottlenecks bottleneck-id)) ERR_NOT_FOUND)

            (map-set bottleneck-solutions solution-id {
                bottleneck-id: bottleneck-id,
                solution: solution,
                estimated-improvement: estimated-improvement,
                implementation-cost: implementation-cost,
                proposed-by: tx-sender,
                proposed-at: block-height
            })

            (var-set next-solution-id (+ solution-id u1))
            (ok solution-id)
        )
    )
)

;; Update bottleneck status
(define-public (update-status (bottleneck-id uint) (new-status (string-ascii 20)))
    (match (map-get? bottlenecks bottleneck-id)
        bottleneck-data
        (begin
            (map-set bottlenecks bottleneck-id
                (merge bottleneck-data {status: new-status}))
            (ok true)
        )
        ERR_NOT_FOUND
    )
)

;; Read-only functions
(define-read-only (get-bottleneck (bottleneck-id uint))
    (map-get? bottlenecks bottleneck-id)
)

(define-read-only (get-solution (solution-id uint))
    (map-get? bottleneck-solutions solution-id)
)

(define-read-only (calculate-priority-score (bottleneck-id uint))
    (match (map-get? bottlenecks bottleneck-id)
        bottleneck-data
        (some (* (get severity bottleneck-data) (get impact-score bottleneck-data)))
        none
    )
)
