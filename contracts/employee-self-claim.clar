(define-constant ERR-UNAUTHORIZED u100)
(define-constant ERR-NOT-EMPLOYEE u101)
(define-constant ERR-INACTIVE u102)
(define-constant ERR-NOTHING-TO-CLAIM u103)
(define-constant ERR-INSUFFICIENT-FUNDS u104)
(define-constant ERR-INVALID-ARG u105)
(define-constant ERR-ALREADY-HIRED u106)
(define-constant ERR-OWNER-UNSET u107)

(define-data-var owner (optional principal) none)
(define-data-var pay-period uint u144)

(define-map employees
  principal
  {
    salary-per-period: uint,
    last-paid-height: uint,
    active: bool
  }
)

(define-read-only (get-owner)
  (var-get owner)
)

(define-read-only (get-pay-period)
  (var-get pay-period)
)

(define-read-only (get-employee (who principal))
  (map-get? employees who)
)

(define-read-only (get-claimable (who principal))
  (match (map-get? employees who)
    e
    (let (
      (pp (var-get pay-period))
      (bh stacks-block-height)
      (lph (get last-paid-height e))
      (blocks (if (>= bh lph) (- bh lph) u0))
      (periods (if (> pp u0) (/ blocks pp) u0))
      (amount (* periods (get salary-per-period e)))
    )
    amount)
    u0
  )
)

(define-public (init)
  (if (is-none (var-get owner))
    (begin (var-set owner (some tx-sender)) (ok true))
    (err ERR-UNAUTHORIZED)
  )
)

(define-public (set-pay-period (blocks uint))
  (match (var-get owner)
    o
    (if (is-eq o tx-sender)
      (if (> blocks u0)
        (begin (var-set pay-period blocks) (ok true))
        (err ERR-INVALID-ARG)
      )
      (err ERR-UNAUTHORIZED)
    )
    (err ERR-OWNER-UNSET)
  )
)

(define-public (hire-employee (employee principal) (salary uint))
  (match (var-get owner)
    o
    (if (is-eq o tx-sender)
      (if (> salary u0)
        (let (
          (inserted (map-insert employees employee
            {
              salary-per-period: salary,
              last-paid-height: stacks-block-height,
              active: true
            }
          ))
        )
        (if inserted (ok true) (err ERR-ALREADY-HIRED))
        )
        (err ERR-INVALID-ARG)
      )
      (err ERR-UNAUTHORIZED)
    )
    (err ERR-OWNER-UNSET)
  )
)

(define-public (update-salary (employee principal) (salary uint))
  (match (var-get owner)
    o
    (if (is-eq o tx-sender)
      (if (> salary u0)
        (match (map-get? employees employee)
          e
          (begin
            (map-set employees employee
              {
                salary-per-period: salary,
                last-paid-height: (get last-paid-height e),
                active: (get active e)
              }
            )
            (ok true)
          )
          (err ERR-NOT-EMPLOYEE)
        )
        (err ERR-INVALID-ARG)
      )
      (err ERR-UNAUTHORIZED)
    )
    (err ERR-OWNER-UNSET)
  )
)

(define-public (set-active (employee principal) (flag bool))
  (match (var-get owner)
    o
    (if (is-eq o tx-sender)
      (match (map-get? employees employee)
        e
        (begin
          (map-set employees employee
            {
              salary-per-period: (get salary-per-period e),
              last-paid-height: (get last-paid-height e),
              active: flag
            }
          )
          (ok true)
        )
        (err ERR-NOT-EMPLOYEE)
      )
      (err ERR-UNAUTHORIZED)
    )
    (err ERR-OWNER-UNSET)
  )
)

(define-public (claim)
  (let (
    (who tx-sender)
  )
  (match (map-get? employees who)
    e
    (if (get active e)
      (let (
        (pp (var-get pay-period))
        (bh stacks-block-height)
        (lph (get last-paid-height e))
        (blocks (if (>= bh lph) (- bh lph) u0))
        (periods (if (> pp u0) (/ blocks pp) u0))
        (amount (* periods (get salary-per-period e)))
      )
      (if (> amount u0)
        (let (
          (new-lph (+ lph (* periods pp)))
        )
        (match (as-contract (stx-transfer? amount tx-sender who))
          ok-tx
          (begin
            (map-set employees who
              {
                salary-per-period: (get salary-per-period e),
                last-paid-height: new-lph,
                active: (get active e)
              }
            )
            (ok amount)
          )
          err-code
          (err ERR-INSUFFICIENT-FUNDS)
        )
        )
        (err ERR-NOTHING-TO-CLAIM)
      )
      )
      (err ERR-INACTIVE)
    )
    (err ERR-NOT-EMPLOYEE)
  )
  )
)