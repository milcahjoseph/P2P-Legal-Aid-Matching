(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_INVALID_PARAMS (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u104))
(define-constant ERR_CASE_NOT_ACTIVE (err u105))
(define-constant ERR_ALREADY_MATCHED (err u106))

(define-constant CONTRACT_OWNER tx-sender)
(define-constant CASE_REWARD u1000)
(define-constant REVIEW_REWARD u100)
(define-constant MIN_INCOME_THRESHOLD u50000)

(define-data-var total-cases uint u0)
(define-data-var total-users uint u0)
(define-data-var platform-balance uint u0)

(define-map users principal {
    user-type: (string-ascii 10),
    reputation: uint,
    cases-completed: uint,
    total-earned: uint,
    is-verified: bool
})

(define-map lawyers principal {
    specialty: (string-ascii 50),
    hourly-rate: uint,
    available: bool,
    license-number: (string-ascii 20)
})

(define-map cases uint {
    client: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 30),
    status: (string-ascii 20),
    lawyer: (optional principal),
    reward-amount: uint,
    created-at: uint,
    income-verified: bool
})

(define-map case-applications uint (list 20 principal))

(define-map reviews {case-id: uint, reviewer: principal} {
    rating: uint,
    comment: (string-ascii 200),
    created-at: uint
})

(define-map user-tokens principal uint)

(define-public (register-user (user-type (string-ascii 10)))
    (let ((sender tx-sender))
        (asserts! (or (is-eq user-type "client") (is-eq user-type "lawyer")) ERR_INVALID_PARAMS)
        (asserts! (is-none (map-get? users sender)) ERR_ALREADY_EXISTS)
        (map-set users sender {
            user-type: user-type,
            reputation: u0,
            cases-completed: u0,
            total-earned: u0,
            is-verified: false
        })
        (map-set user-tokens sender u1000)
        (var-set total-users (+ (var-get total-users) u1))
        (ok true)))

(define-public (register-lawyer (specialty (string-ascii 50)) (hourly-rate uint) (license-number (string-ascii 20)))
    (let ((sender tx-sender))
        (try! (register-user "lawyer"))
        (map-set lawyers sender {
            specialty: specialty,
            hourly-rate: hourly-rate,
            available: true,
            license-number: license-number
        })
        (ok true)))

(define-public (verify-income (user principal) (annual-income uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (let ((user-data (unwrap! (map-get? users user) ERR_NOT_FOUND)))
            (asserts! (is-eq (get user-type user-data) "client") ERR_INVALID_PARAMS)
            (map-set users user (merge user-data {is-verified: true}))
            (ok (<= annual-income MIN_INCOME_THRESHOLD)))))

(define-public (create-case (title (string-ascii 100)) (description (string-ascii 500)) (category (string-ascii 30)))
    (let 
        ((sender tx-sender)
         (case-id (+ (var-get total-cases) u1))
         (user-data (unwrap! (map-get? users sender) ERR_NOT_FOUND))
         (current-balance (default-to u0 (map-get? user-tokens sender))))
        (asserts! (is-eq (get user-type user-data) "client") ERR_NOT_AUTHORIZED)
        (asserts! (get is-verified user-data) ERR_NOT_AUTHORIZED)
        (asserts! (>= current-balance CASE_REWARD) ERR_INSUFFICIENT_FUNDS)
        (map-set user-tokens sender (- current-balance CASE_REWARD))
        (var-set platform-balance (+ (var-get platform-balance) CASE_REWARD))
        (map-set cases case-id {
            client: sender,
            title: title,
            description: description,
            category: category,
            status: "open",
            lawyer: none,
            reward-amount: CASE_REWARD,
            created-at: stacks-block-height,
            income-verified: true
        })
        (var-set total-cases case-id)
        (ok case-id)))

(define-public (apply-to-case (case-id uint))
    (let 
        ((sender tx-sender)
         (case-data (unwrap! (map-get? cases case-id) ERR_NOT_FOUND))
         (user-data (unwrap! (map-get? users sender) ERR_NOT_FOUND))
         (current-applications (default-to (list) (map-get? case-applications case-id))))
        (asserts! (is-eq (get user-type user-data) "lawyer") ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status case-data) "open") ERR_CASE_NOT_ACTIVE)
        (asserts! (is-none (index-of current-applications sender)) ERR_ALREADY_EXISTS)
        (map-set case-applications case-id (unwrap! (as-max-len? (append current-applications sender) u20) ERR_INVALID_PARAMS))
        (ok true)))

(define-public (accept-lawyer (case-id uint) (lawyer principal))
    (let 
        ((sender tx-sender)
         (case-data (unwrap! (map-get? cases case-id) ERR_NOT_FOUND))
         (applications (unwrap! (map-get? case-applications case-id) ERR_NOT_FOUND)))
        (asserts! (is-eq sender (get client case-data)) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status case-data) "open") ERR_CASE_NOT_ACTIVE)
        (asserts! (is-some (index-of applications lawyer)) ERR_NOT_FOUND)
        (map-set cases case-id (merge case-data {
            status: "in-progress",
            lawyer: (some lawyer)
        }))
        (ok true)))

(define-public (complete-case (case-id uint))
    (let 
        ((sender tx-sender)
         (case-data (unwrap! (map-get? cases case-id) ERR_NOT_FOUND))
         (lawyer (unwrap! (get lawyer case-data) ERR_NOT_FOUND)))
        (asserts! (is-eq sender (get client case-data)) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status case-data) "in-progress") ERR_CASE_NOT_ACTIVE)
        (map-set cases case-id (merge case-data {status: "completed"}))
        (try! (release-case-reward lawyer (get reward-amount case-data)))
        (try! (update-user-stats lawyer))
        (try! (update-user-stats sender))
        (ok true)))

(define-public (submit-review (case-id uint) (rating uint) (comment (string-ascii 200)))
    (let 
        ((sender tx-sender)
         (case-data (unwrap! (map-get? cases case-id) ERR_NOT_FOUND))
         (review-key {case-id: case-id, reviewer: sender}))
        (asserts! (or 
            (is-eq sender (get client case-data))
            (is-eq (some sender) (get lawyer case-data))) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get status case-data) "completed") ERR_CASE_NOT_ACTIVE)
        (asserts! (<= rating u5) ERR_INVALID_PARAMS)
        (asserts! (is-none (map-get? reviews review-key)) ERR_ALREADY_EXISTS)
        (map-set reviews review-key {
            rating: rating,
            comment: comment,
            created-at: stacks-block-height
        })
        (reward-user sender REVIEW_REWARD)
        (ok true)))

(define-public (withdraw-tokens (amount uint))
    (let 
        ((sender tx-sender)
         (current-balance (default-to u0 (map-get? user-tokens sender))))
        (asserts! (>= current-balance amount) ERR_INSUFFICIENT_FUNDS)
        (map-set user-tokens sender (- current-balance amount))
        (ok true)))

(define-private (reward-user (user principal) (amount uint))
    (let ((current-balance (default-to u0 (map-get? user-tokens user))))
        (map-set user-tokens user (+ current-balance amount))
        true))

(define-private (release-case-reward (user principal) (amount uint))
    (let 
        ((current-platform-balance (var-get platform-balance))
         (current-user-balance (default-to u0 (map-get? user-tokens user))))
        (asserts! (>= current-platform-balance amount) ERR_INSUFFICIENT_FUNDS)
        (var-set platform-balance (- current-platform-balance amount))
        (map-set user-tokens user (+ current-user-balance amount))
        (ok true)))

(define-private (update-user-stats (user principal))
    (let ((user-data (unwrap! (map-get? users user) ERR_NOT_FOUND)))
        (map-set users user (merge user-data {
            cases-completed: (+ (get cases-completed user-data) u1),
            reputation: (+ (get reputation user-data) u10)
        }))
        (ok true)))

(define-read-only (get-user (user principal))
    (map-get? users user))

(define-read-only (get-lawyer (lawyer principal))
    (map-get? lawyers lawyer))

(define-read-only (get-case (case-id uint))
    (map-get? cases case-id))

(define-read-only (get-case-applications (case-id uint))
    (map-get? case-applications case-id))

(define-read-only (get-review (case-id uint) (reviewer principal))
    (map-get? reviews {case-id: case-id, reviewer: reviewer}))

(define-read-only (get-user-balance (user principal))
    (default-to u0 (map-get? user-tokens user)))

(define-read-only (get-total-cases)
    (var-get total-cases))

(define-read-only (get-total-users)
    (var-get total-users))

(define-read-only (get-platform-stats)
    {
        total-cases: (var-get total-cases),
        total-users: (var-get total-users),
        platform-balance: (var-get platform-balance)
    })
