;; title: Royalty-Distribution-Engine
;; version: 1.0.0
;; summary: Automated royalty distribution system for musicians, producers, and songwriters
;; description: Transparent smart contract that automatically splits and disburses payments based on pre-defined rules

;; constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-SONG-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-PERCENTAGE (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-NO-COLLABORATORS (err u105))
(define-constant ERR-INVALID-AMOUNT (err u106))
(define-constant MAX-PERCENTAGE u10000)

;; data vars
(define-data-var contract-paused bool false)
(define-data-var total-songs-registered uint u0)
(define-data-var total-royalties-distributed uint u0)

;; data maps
(define-map songs 
  { song-id: uint }
  { 
    title: (string-ascii 100),
    artist: principal,
    total-earned: uint,
    is-active: bool,
    created-at: uint
  }
)

(define-map collaborators
  { song-id: uint, collaborator: principal }
  { 
    role: (string-ascii 20),
    percentage: uint,
    total-earned: uint
  }
)

(define-map song-collaborator-count
  { song-id: uint }
  { count: uint }
)

(define-map user-songs
  { user: principal }
  { song-ids: (list 50 uint) }
)

(define-map platform-earnings
  { platform: (string-ascii 50) }
  { total-earned: uint }
)

(define-map song-earnings-history
  { song-id: uint, block-height: uint }
  { amount: uint, platform: (string-ascii 50) }
)

;; public functions

(define-public (register-song (song-id uint) (title (string-ascii 100)) (collaborator-list (list 10 { collaborator: principal, role: (string-ascii 20), percentage: uint })))
  (let 
    (
      (existing-song (map-get? songs { song-id: song-id }))
      (total-percentage (fold calculate-total-percentage collaborator-list u0))
    )
    (asserts! (is-none existing-song) ERR-ALREADY-EXISTS)
    (asserts! (is-eq total-percentage MAX-PERCENTAGE) ERR-INVALID-PERCENTAGE)
    (asserts! (> (len collaborator-list) u0) ERR-NO-COLLABORATORS)
    (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
    
    (map-set songs 
      { song-id: song-id }
      { 
        title: title,
        artist: tx-sender,
        total-earned: u0,
        is-active: true,
        created-at: stacks-block-height
      }
    )
    
    (map-set song-collaborator-count
      { song-id: song-id }
      { count: (len collaborator-list) }
    )
    
    (fold register-collaborator collaborator-list song-id)
    (var-set total-songs-registered (+ (var-get total-songs-registered) u1))
    (update-user-songs-list song-id)
    (ok song-id)
  )
)

(define-public (distribute-royalty (song-id uint) (amount uint) (platform (string-ascii 50)))
  (let 
    (
      (song (unwrap! (map-get? songs { song-id: song-id }) ERR-SONG-NOT-FOUND))
    )
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (get is-active song) ERR-SONG-NOT-FOUND)
    (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
    
    (process-royalty-distribution song-id amount platform)
    (ok amount)
  )
)

(define-public (deactivate-song (song-id uint))
  (let 
    (
      (song (unwrap! (map-get? songs { song-id: song-id }) ERR-SONG-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get artist song)) ERR-UNAUTHORIZED)
    (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
    
    (map-set songs
      { song-id: song-id }
      (merge song { is-active: false })
    )
    (ok true)
  )
)

(define-public (reactivate-song (song-id uint))
  (let 
    (
      (song (unwrap! (map-get? songs { song-id: song-id }) ERR-SONG-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get artist song)) ERR-UNAUTHORIZED)
    (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
    
    (map-set songs
      { song-id: song-id }
      (merge song { is-active: true })
    )
    (ok true)
  )
)

(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set contract-paused false)
    (ok true)
  )
)

(define-public (update-collaborator-percentage (song-id uint) (collaborator principal) (new-percentage uint))
  (let 
    (
      (song (unwrap! (map-get? songs { song-id: song-id }) ERR-SONG-NOT-FOUND))
      (existing-collab (unwrap! (map-get? collaborators { song-id: song-id, collaborator: collaborator }) ERR-SONG-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get artist song)) ERR-UNAUTHORIZED)
    (asserts! (<= new-percentage MAX-PERCENTAGE) ERR-INVALID-PERCENTAGE)
    (asserts! (not (var-get contract-paused)) ERR-UNAUTHORIZED)
    
    (map-set collaborators
      { song-id: song-id, collaborator: collaborator }
      (merge existing-collab { percentage: new-percentage })
    )
    (ok true)
  )
)

;; read-only functions

(define-read-only (get-song-info (song-id uint))
  (map-get? songs { song-id: song-id })
)

(define-read-only (get-collaborator-info (song-id uint) (collaborator principal))
  (map-get? collaborators { song-id: song-id, collaborator: collaborator })
)

(define-read-only (get-contract-stats)
  {
    total-songs: (var-get total-songs-registered),
    total-royalties: (var-get total-royalties-distributed),
    is-paused: (var-get contract-paused),
    owner: CONTRACT-OWNER
  }
)

(define-read-only (get-platform-earnings (platform (string-ascii 50)))
  (default-to { total-earned: u0 } (map-get? platform-earnings { platform: platform }))
)

(define-read-only (get-user-songs (user principal))
  (default-to { song-ids: (list) } (map-get? user-songs { user: user }))
)

(define-read-only (get-song-earning-history (song-id uint) (height uint))
  (map-get? song-earnings-history { song-id: song-id, block-height: height })
)

(define-read-only (calculate-collaborator-share (song-id uint) (collaborator principal) (total-amount uint))
  (match (map-get? collaborators { song-id: song-id, collaborator: collaborator })
    collab-data (ok (/ (* total-amount (get percentage collab-data)) MAX-PERCENTAGE))
    ERR-SONG-NOT-FOUND
  )
)

(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

(define-read-only (get-song-collaborator-count (song-id uint))
  (default-to { count: u0 } (map-get? song-collaborator-count { song-id: song-id }))
)

;; private functions

(define-private (calculate-total-percentage (collaborator-data { collaborator: principal, role: (string-ascii 20), percentage: uint }) (acc uint))
  (+ acc (get percentage collaborator-data))
)

(define-private (register-collaborator (collaborator-data { collaborator: principal, role: (string-ascii 20), percentage: uint }) (song-id uint))
  (begin
    (map-set collaborators
      { song-id: song-id, collaborator: (get collaborator collaborator-data) }
      { 
        role: (get role collaborator-data),
        percentage: (get percentage collaborator-data),
        total-earned: u0
      }
    )
    song-id
  )
)

(define-private (process-royalty-distribution (song-id uint) (amount uint) (platform (string-ascii 50)))
  (begin
    (update-song-total-earned song-id amount)
    (update-platform-earnings platform amount)
    (record-earning-history song-id amount platform)
    (var-set total-royalties-distributed (+ (var-get total-royalties-distributed) amount))
    true
  )
)

(define-private (distribute-collaborator-share (song-id uint) (collaborator principal) (total-amount uint))
  (match (map-get? collaborators { song-id: song-id, collaborator: collaborator })
    existing-collab
    (let 
      (
        (share (/ (* total-amount (get percentage existing-collab)) MAX-PERCENTAGE))
      )
      (map-set collaborators
        { song-id: song-id, collaborator: collaborator }
        (merge existing-collab { total-earned: (+ (get total-earned existing-collab) share) })
      )
      share
    )
    u0
  )
)

(define-private (update-collaborator-earnings (song-id uint) (collaborator principal) (total-amount uint))
  (match (map-get? collaborators { song-id: song-id, collaborator: collaborator })
    existing-collab
    (let 
      (
        (share (/ (* total-amount (get percentage existing-collab)) MAX-PERCENTAGE))
      )
      (map-set collaborators
        { song-id: song-id, collaborator: collaborator }
        (merge existing-collab { total-earned: (+ (get total-earned existing-collab) share) })
      )
    )
    false
  )
)

(define-private (update-song-total-earned (song-id uint) (amount uint))
  (match (map-get? songs { song-id: song-id })
    existing-song
    (map-set songs
      { song-id: song-id }
      (merge existing-song { total-earned: (+ (get total-earned existing-song) amount) })
    )
    false
  )
)

(define-private (update-platform-earnings (platform (string-ascii 50)) (amount uint))
  (let 
    (
      (current-earnings (default-to { total-earned: u0 } (map-get? platform-earnings { platform: platform })))
    )
    (map-set platform-earnings
      { platform: platform }
      { total-earned: (+ (get total-earned current-earnings) amount) }
    )
  )
)

(define-private (record-earning-history (song-id uint) (amount uint) (platform (string-ascii 50)))
  (map-set song-earnings-history
    { song-id: song-id, block-height: stacks-block-height }
    { amount: amount, platform: platform }
  )
)

(define-private (update-user-songs-list (song-id uint))
  (let 
    (
      (current-songs (default-to { song-ids: (list) } (map-get? user-songs { user: tx-sender })))
    )
    (map-set user-songs
      { user: tx-sender }
      { song-ids: (unwrap-panic (as-max-len? (append (get song-ids current-songs) song-id) u50)) }
    )
  )
)
