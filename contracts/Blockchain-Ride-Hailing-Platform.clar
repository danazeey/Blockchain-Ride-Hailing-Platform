(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-status (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-invalid-rating (err u106))
(define-constant err-already-rated (err u107))
(define-constant err-trip-not-completed (err u108))
(define-constant err-milestone-claimed (err u109))
(define-constant err-milestone-not-reached (err u110))

(define-constant trip-status-requested u1)
(define-constant trip-status-accepted u2)
(define-constant trip-status-completed u3)
(define-constant trip-status-cancelled u4)

(define-data-var platform-fee-percentage uint u5)
(define-data-var trip-counter uint u0)
(define-data-var reward-pool uint u0)

(define-map drivers
    principal
    {
        registered: bool,
        total-trips: uint,
        rating-sum: uint,
        rating-count: uint,
        earnings: uint
    }
)

(define-map riders
    principal
    {
        registered: bool,
        total-trips: uint,
        rating-sum: uint,
        rating-count: uint,
        spent: uint
    }
)

(define-map trips
    uint
    {
        rider: principal,
        driver: (optional principal),
        fare: uint,
        status: uint,
        created-at: uint,
        completed-at: (optional uint),
        pickup: (string-ascii 100),
        destination: (string-ascii 100),
        rider-rated: bool,
        driver-rated: bool
    }
)

(define-map driver-milestones
    principal
    {
        milestone-10-claimed: bool,
        milestone-25-claimed: bool,
        milestone-50-claimed: bool,
        milestone-100-claimed: bool
    }
)

(define-read-only (get-driver (driver principal))
    (map-get? drivers driver)
)

(define-read-only (get-rider (rider principal))
    (map-get? riders rider)
)

(define-read-only (get-trip (trip-id uint))
    (map-get? trips trip-id)
)

(define-read-only (get-platform-fee)
    (var-get platform-fee-percentage)
)

(define-read-only (get-trip-counter)
    (var-get trip-counter)
)

(define-read-only (get-reward-pool)
    (var-get reward-pool)
)

(define-read-only (get-driver-milestones (driver principal))
    (default-to 
        {
            milestone-10-claimed: false,
            milestone-25-claimed: false,
            milestone-50-claimed: false,
            milestone-100-claimed: false
        }
        (map-get? driver-milestones driver)
    )
)

(define-read-only (calculate-milestone-reward (trip-count uint))
    (if (>= trip-count u100)
        u50000000
        (if (>= trip-count u50)
            u20000000
            (if (>= trip-count u25)
                u8000000
                (if (>= trip-count u10)
                    u3000000
                    u0
                )
            )
        )
    )
)

(define-read-only (calculate-platform-fee (fare uint))
    (/ (* fare (var-get platform-fee-percentage)) u100)
)

(define-read-only (calculate-driver-payout (fare uint))
    (- fare (calculate-platform-fee fare))
)

(define-read-only (get-driver-rating (driver principal))
    (let (
        (driver-data (unwrap! (map-get? drivers driver) (err u0)))
    )
        (if (> (get rating-count driver-data) u0)
            (ok (/ (get rating-sum driver-data) (get rating-count driver-data)))
            (ok u0)
        )
    )
)

(define-read-only (get-rider-rating (rider principal))
    (let (
        (rider-data (unwrap! (map-get? riders rider) (err u0)))
    )
        (if (> (get rating-count rider-data) u0)
            (ok (/ (get rating-sum rider-data) (get rating-count rider-data)))
            (ok u0)
        )
    )
)

(define-public (register-driver)
    (let (
        (driver tx-sender)
    )
        (asserts! (is-none (map-get? drivers driver)) err-already-exists)
        (map-set drivers driver {
            registered: true,
            total-trips: u0,
            rating-sum: u0,
            rating-count: u0,
            earnings: u0
        })
        (map-set driver-milestones driver {
            milestone-10-claimed: false,
            milestone-25-claimed: false,
            milestone-50-claimed: false,
            milestone-100-claimed: false
        })
        (ok true)
    )
)

(define-public (register-rider)
    (let (
        (rider tx-sender)
    )
        (asserts! (is-none (map-get? riders rider)) err-already-exists)
        (map-set riders rider {
            registered: true,
            total-trips: u0,
            rating-sum: u0,
            rating-count: u0,
            spent: u0
        })
        (ok true)
    )
)

(define-public (request-trip (pickup (string-ascii 100)) (destination (string-ascii 100)) (fare uint))
    (let (
        (rider tx-sender)
        (trip-id (+ (var-get trip-counter) u1))
        (rider-data (unwrap! (map-get? riders rider) err-not-found))
    )
        (asserts! (get registered rider-data) err-unauthorized)
        (try! (stx-transfer? fare rider (as-contract tx-sender)))
        (map-set trips trip-id {
            rider: rider,
            driver: none,
            fare: fare,
            status: trip-status-requested,
            created-at: stacks-block-height,
            completed-at: none,
            pickup: pickup,
            destination: destination,
            rider-rated: false,
            driver-rated: false
        })
        (var-set trip-counter trip-id)
        (ok trip-id)
    )
)

(define-public (accept-trip (trip-id uint))
    (let (
        (driver tx-sender)
        (trip (unwrap! (map-get? trips trip-id) err-not-found))
        (driver-data (unwrap! (map-get? drivers driver) err-not-found))
    )
        (asserts! (get registered driver-data) err-unauthorized)
        (asserts! (is-eq (get status trip) trip-status-requested) err-invalid-status)
        (map-set trips trip-id (merge trip {
            driver: (some driver),
            status: trip-status-accepted
        }))
        (ok true)
    )
)

(define-public (complete-trip (trip-id uint))
    (let (
        (driver tx-sender)
        (trip (unwrap! (map-get? trips trip-id) err-not-found))
        (driver-data (unwrap! (map-get? drivers driver) err-not-found))
        (rider-data (unwrap! (map-get? riders (get rider trip)) err-not-found))
        (payout (calculate-driver-payout (get fare trip)))
        (platform-fee (calculate-platform-fee (get fare trip)))
    )
        (asserts! (is-eq (some driver) (get driver trip)) err-unauthorized)
        (asserts! (is-eq (get status trip) trip-status-accepted) err-invalid-status)
        (try! (as-contract (stx-transfer? payout tx-sender driver)))
        (try! (as-contract (stx-transfer? platform-fee tx-sender contract-owner)))
        (map-set trips trip-id (merge trip {
            status: trip-status-completed,
            completed-at: (some stacks-block-height)
        }))
        (map-set drivers driver (merge driver-data {
            total-trips: (+ (get total-trips driver-data) u1),
            earnings: (+ (get earnings driver-data) payout)
        }))
        (map-set riders (get rider trip) (merge rider-data {
            total-trips: (+ (get total-trips rider-data) u1),
            spent: (+ (get spent rider-data) (get fare trip))
        }))
        (ok true)
    )
)

(define-public (cancel-trip (trip-id uint))
    (let (
        (caller tx-sender)
        (trip (unwrap! (map-get? trips trip-id) err-not-found))
    )
        (asserts! 
            (or 
                (is-eq caller (get rider trip))
                (is-eq (some caller) (get driver trip))
            )
            err-unauthorized
        )
        (asserts! 
            (or
                (is-eq (get status trip) trip-status-requested)
                (is-eq (get status trip) trip-status-accepted)
            )
            err-invalid-status
        )
        (try! (as-contract (stx-transfer? (get fare trip) tx-sender (get rider trip))))
        (map-set trips trip-id (merge trip {
            status: trip-status-cancelled
        }))
        (ok true)
    )
)

(define-public (rate-driver (trip-id uint) (rating uint))
    (let (
        (rider tx-sender)
        (trip (unwrap! (map-get? trips trip-id) err-not-found))
        (driver (unwrap! (get driver trip) err-not-found))
        (driver-data (unwrap! (map-get? drivers driver) err-not-found))
    )
        (asserts! (is-eq rider (get rider trip)) err-unauthorized)
        (asserts! (is-eq (get status trip) trip-status-completed) err-trip-not-completed)
        (asserts! (not (get rider-rated trip)) err-already-rated)
        (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
        (map-set drivers driver (merge driver-data {
            rating-sum: (+ (get rating-sum driver-data) rating),
            rating-count: (+ (get rating-count driver-data) u1)
        }))
        (map-set trips trip-id (merge trip {
            rider-rated: true
        }))
        (ok true)
    )
)

(define-public (rate-rider (trip-id uint) (rating uint))
    (let (
        (driver tx-sender)
        (trip (unwrap! (map-get? trips trip-id) err-not-found))
        (rider (get rider trip))
        (rider-data (unwrap! (map-get? riders rider) err-not-found))
    )
        (asserts! (is-eq (some driver) (get driver trip)) err-unauthorized)
        (asserts! (is-eq (get status trip) trip-status-completed) err-trip-not-completed)
        (asserts! (not (get driver-rated trip)) err-already-rated)
        (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
        (map-set riders rider (merge rider-data {
            rating-sum: (+ (get rating-sum rider-data) rating),
            rating-count: (+ (get rating-count rider-data) u1)
        }))
        (map-set trips trip-id (merge trip {
            driver-rated: true
        }))
        (ok true)
    )
)

(define-public (set-platform-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u20) err-invalid-status)
        (var-set platform-fee-percentage new-fee)
        (ok true)
    )
)

(define-public (fund-reward-pool (amount uint))
    (begin
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set reward-pool (+ (var-get reward-pool) amount))
        (ok true)
    )
)

(define-public (claim-milestone-reward (milestone-level uint))
    (let (
        (driver tx-sender)
        (driver-data (unwrap! (map-get? drivers driver) err-not-found))
        (driver-milestone-data (get-driver-milestones driver))
        (trip-count (get total-trips driver-data))
    )
        (asserts! (get registered driver-data) err-unauthorized)
        (asserts! 
            (or 
                (is-eq milestone-level u10)
                (is-eq milestone-level u25)
                (is-eq milestone-level u50)
                (is-eq milestone-level u100)
            )
            err-invalid-status
        )
        (asserts! (>= trip-count milestone-level) err-milestone-not-reached)
        (asserts!
            (if (is-eq milestone-level u10)
                (not (get milestone-10-claimed driver-milestone-data))
                (if (is-eq milestone-level u25)
                    (not (get milestone-25-claimed driver-milestone-data))
                    (if (is-eq milestone-level u50)
                        (not (get milestone-50-claimed driver-milestone-data))
                        (not (get milestone-100-claimed driver-milestone-data))
                    )
                )
            )
            err-milestone-claimed
        )
        (let (
            (reward-amount (calculate-milestone-reward milestone-level))
        )
            (asserts! (>= (var-get reward-pool) reward-amount) err-insufficient-funds)
            (try! (as-contract (stx-transfer? reward-amount tx-sender driver)))
            (var-set reward-pool (- (var-get reward-pool) reward-amount))
            (map-set driver-milestones driver
                (if (is-eq milestone-level u10)
                    (merge driver-milestone-data { milestone-10-claimed: true })
                    (if (is-eq milestone-level u25)
                        (merge driver-milestone-data { milestone-25-claimed: true })
                        (if (is-eq milestone-level u50)
                            (merge driver-milestone-data { milestone-50-claimed: true })
                            (merge driver-milestone-data { milestone-100-claimed: true })
                        )
                    )
                )
            )
            (ok reward-amount)
        )
    )
)
