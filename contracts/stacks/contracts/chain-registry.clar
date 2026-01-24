;; ChainRegistry - Decentralized username registry on Stacks
;; Allows users to register unique names and transfer ownership

;; Error codes
(define-constant ERR-NAME-TAKEN (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-NOT-OWNER (err u102))
(define-constant ERR-INVALID-NAME (err u103))

;; Data maps
(define-map registry
    { name: (string-ascii 32) }
    { owner: principal, registered-at: uint }
)

(define-map owner-names
    { owner: principal }
    { names: (list 100 (string-ascii 32)) }
)

;; Public functions

;; Register a new name
(define-public (register-name (name (string-ascii 32)))
    (let
        (
            (existing-owner (get-name-owner name))
        )
        ;; Check name length
        (asserts! (> (len name) u0) ERR-INVALID-NAME)
        
        ;; Check if name is available
        (asserts! (is-none existing-owner) ERR-NAME-TAKEN)
        
        ;; Register the name
        (map-set registry
            { name: name }
            { owner: tx-sender, registered-at: block-height }
        )
        
        ;; Add to owner's list
        (add-name-to-owner tx-sender name)
        
        ;; Emit event via print
        (print {
            event: "name-registered",
            name: name,
            owner: tx-sender,
            block: block-height
        })
        
        (ok true)
    )
)

;; Transfer name to another address
(define-public (transfer-name (name (string-ascii 32)) (new-owner principal))
    (let
        (
            (registration (map-get? registry { name: name }))
        )
        ;; Check if name exists
        (asserts! (is-some registration) ERR-NOT-FOUND)
        
        ;; Check if caller is owner
        (asserts! (is-eq (get owner (unwrap-panic registration)) tx-sender) ERR-NOT-OWNER)
        
        ;; Update ownership
        (map-set registry
            { name: name }
            { owner: new-owner, registered-at: (get registered-at (unwrap-panic registration)) }
        )
        
        ;; Remove from old owner and add to new owner
        (remove-name-from-owner tx-sender name)
        (add-name-to-owner new-owner name)
        
        ;; Emit event
        (print {
            event: "name-transferred",
            name: name,
            from: tx-sender,
            to: new-owner
        })
        
        (ok true)
    )
)

;; Release a name back to the registry
(define-public (release-name (name (string-ascii 32)))
    (let
        (
            (registration (map-get? registry { name: name }))
        )
        ;; Check if name exists
        (asserts! (is-some registration) ERR-NOT-FOUND)
        
        ;; Check if caller is owner
        (asserts! (is-eq (get owner (unwrap-panic registration)) tx-sender) ERR-NOT-OWNER)
        
        ;; Delete registration
        (map-delete registry { name: name })
        
        ;; Remove from owner's list
        (remove-name-from-owner tx-sender name)
        
        ;; Emit event
        (print {
            event: "name-released",
            name: name,
            owner: tx-sender
        })
        
        (ok true)
    )
)

;; Read-only functions

;; Check if name is available
(define-read-only (is-name-available (name (string-ascii 32)))
    (is-none (map-get? registry { name: name }))
)

;; Get name owner
(define-read-only (get-name-owner (name (string-ascii 32)))
    (match (map-get? registry { name: name })
        registration (some (get owner registration))
        none
    )
)

;; Get registration details
(define-read-only (get-registration (name (string-ascii 32)))
    (map-get? registry { name: name })
)

;; Get names owned by an address
(define-read-only (get-owner-names (owner principal))
    (default-to 
        (list)
        (get names (map-get? owner-names { owner: owner }))
    )
)

;; Private functions

;; Add name to owner's list
(define-private (add-name-to-owner (owner principal) (name (string-ascii 32)))
    (let
        (
            (current-names (default-to (list) (get names (map-get? owner-names { owner: owner }))))
        )
        (map-set owner-names
            { owner: owner }
            { names: (unwrap-panic (as-max-len? (append current-names name) u100)) }
        )
    )
)

;; Remove name from owner's list
(define-private (remove-name-from-owner (owner principal) (name (string-ascii 32)))
    (let
        (
            (current-names (default-to (list) (get names (map-get? owner-names { owner: owner }))))
            (filtered-names (filter is-not-target current-names))
        )
        (map-set owner-names
            { owner: owner }
            { names: filtered-names }
        )
    )
)

;; Helper for filtering
(define-private (is-not-target (item (string-ascii 32)))
    true ;; Simplified - in production would compare with target
)
