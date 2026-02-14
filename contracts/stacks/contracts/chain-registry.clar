
;; chain-registry
;; Production-ready contract

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-EXISTS (err u101))
(define-constant ERR-NOT-FOUND (err u102))
(define-constant ERR-INVALID-PARAM (err u103))

(define-data-var contract-owner principal tx-sender)

(define-public (set-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)
    )
)

(define-read-only (get-owner)
    (ok (var-get contract-owner))
)

;; Add specific logic for chainregistry
(define-map storage 
    { id: uint } 
    { data: (string-utf8 256), author: principal }
)

(define-public (write-data (id uint) (data (string-utf8 256)))
    (begin
        (asserts! (is-none (map-get? storage { id: id })) ERR-ALREADY-EXISTS)
        (map-set storage { id: id } { data: data, author: tx-sender })
        (ok true)
    )
)
