(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-payment-not-due (err u105))
(define-constant err-already-paid (err u106))
(define-constant err-unauthorized (err u107))
(define-constant err-invalid-date (err u108))

(define-data-var next-employee-id uint u1)
(define-data-var next-payroll-id uint u1)
(define-data-var payroll-frequency uint u30)
(define-data-var organization-name (string-ascii 50) "NGO Payroll System")
(define-data-var total-employees uint u0)
(define-data-var total-payroll-amount uint u0)

(define-map employees
    { employee-id: uint }
    {
        wallet: principal,
        name: (string-ascii 50),
        position: (string-ascii 50),
        salary: uint,
        active: bool,
        hire-date: uint,
        last-payment: uint,
    }
)

(define-map employee-by-wallet
    { wallet: principal }
    { employee-id: uint }
)

(define-map payroll-records
    { payroll-id: uint }
    {
        employee-id: uint,
        amount: uint,
        payment-date: uint,
        period-start: uint,
        period-end: uint,
        status: (string-ascii 20),
    }
)

(define-map monthly-budgets
    {
        month: uint,
        year: uint,
    }
    {
        allocated: uint,
        spent: uint,
        remaining: uint,
    }
)

(define-read-only (get-employee (employee-id uint))
    (map-get? employees { employee-id: employee-id })
)

(define-read-only (get-employee-by-wallet (wallet principal))
    (match (map-get? employee-by-wallet { wallet: wallet })
        employee-data (get-employee (get employee-id employee-data))
        none
    )
)

(define-read-only (get-payroll-record (payroll-id uint))
    (map-get? payroll-records { payroll-id: payroll-id })
)

(define-read-only (get-monthly-budget
        (month uint)
        (year uint)
    )
    (map-get? monthly-budgets {
        month: month,
        year: year,
    })
)

(define-read-only (get-organization-info)
    {
        name: (var-get organization-name),
        total-employees: (var-get total-employees),
        total-payroll-amount: (var-get total-payroll-amount),
        payroll-frequency: (var-get payroll-frequency),
    }
)

(define-read-only (get-contract-balance)
    (stx-get-balance (as-contract tx-sender))
)

(define-read-only (is-payment-due (employee-id uint))
    (match (get-employee employee-id)
        employee-data (let (
                (last-payment (get last-payment employee-data))
                (current-block stacks-block-height)
                (frequency (var-get payroll-frequency))
            )
            (>= (- current-block last-payment) frequency)
        )
        false
    )
)

(define-public (set-organization-name (name (string-ascii 50)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set organization-name name))
    )
)

(define-public (set-payroll-frequency (frequency uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> frequency u0) err-invalid-amount)
        (ok (var-set payroll-frequency frequency))
    )
)

(define-public (add-employee
        (wallet principal)
        (name (string-ascii 50))
        (position (string-ascii 50))
        (salary uint)
    )
    (let ((employee-id (var-get next-employee-id)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> salary u0) err-invalid-amount)
        (asserts! (is-none (map-get? employee-by-wallet { wallet: wallet }))
            err-already-exists
        )
        (map-set employees { employee-id: employee-id } {
            wallet: wallet,
            name: name,
            position: position,
            salary: salary,
            active: true,
            hire-date: stacks-block-height,
            last-payment: u0,
        })
        (map-set employee-by-wallet { wallet: wallet } { employee-id: employee-id })
        (var-set next-employee-id (+ employee-id u1))
        (var-set total-employees (+ (var-get total-employees) u1))
        (ok employee-id)
    )
)

(define-public (update-employee-salary
        (employee-id uint)
        (new-salary uint)
    )
    (match (get-employee employee-id)
        employee-data (begin
            (asserts! (is-eq tx-sender contract-owner) err-owner-only)
            (asserts! (> new-salary u0) err-invalid-amount)
            (map-set employees { employee-id: employee-id }
                (merge employee-data { salary: new-salary })
            )
            (ok true)
        )
        err-not-found
    )
)

(define-public (deactivate-employee (employee-id uint))
    (match (get-employee employee-id)
        employee-data (begin
            (asserts! (is-eq tx-sender contract-owner) err-owner-only)
            (map-set employees { employee-id: employee-id }
                (merge employee-data { active: false })
            )
            (var-set total-employees (- (var-get total-employees) u1))
            (ok true)
        )
        err-not-found
    )
)

(define-public (fund-payroll (amount uint))
    (begin
        (asserts! (> amount u0) err-invalid-amount)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (ok true)
    )
)

(define-public (set-monthly-budget
        (month uint)
        (year uint)
        (amount uint)
    )
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (and (>= month u1) (<= month u12)) err-invalid-date)
        (asserts! (> year u2020) err-invalid-date)
        (asserts! (> amount u0) err-invalid-amount)
        (map-set monthly-budgets {
            month: month,
            year: year,
        } {
            allocated: amount,
            spent: u0,
            remaining: amount,
        })
        (ok true)
    )
)

(define-public (process-payroll (employee-id uint))
    (let ((payroll-id (var-get next-payroll-id)))
        (match (get-employee employee-id)
            employee-data (let (
                    (salary (get salary employee-data))
                    (wallet (get wallet employee-data))
                    (active (get active employee-data))
                )
                (asserts! (is-eq tx-sender contract-owner) err-owner-only)
                (asserts! active err-not-found)
                (asserts! (is-payment-due employee-id) err-payment-not-due)
                (asserts! (>= (get-contract-balance) salary)
                    err-insufficient-balance
                )
                (try! (as-contract (stx-transfer? salary tx-sender wallet)))
                (map-set employees { employee-id: employee-id }
                    (merge employee-data { last-payment: stacks-block-height })
                )
                (map-set payroll-records { payroll-id: payroll-id } {
                    employee-id: employee-id,
                    amount: salary,
                    payment-date: stacks-block-height,
                    period-start: (get last-payment employee-data),
                    period-end: stacks-block-height,
                    status: "completed",
                })
                (var-set next-payroll-id (+ payroll-id u1))
                (var-set total-payroll-amount
                    (+ (var-get total-payroll-amount) salary)
                )
                (ok payroll-id)
            )
            err-not-found
        )
    )
)

(define-public (emergency-withdraw)
    (let ((balance (get-contract-balance)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (try! (as-contract (stx-transfer? balance tx-sender contract-owner)))
        (ok balance)
    )
)
