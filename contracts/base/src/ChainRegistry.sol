// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ChainRegistry
 * @author winsznx
 * @notice Decentralized username/domain registry with ownership transfer and expiration
 * @dev First-come-first-serve registration with transfer capabilities, fees, and expiration
 * @custom:security-contact timjosh507@gmail.com
 */
contract ChainRegistry is Ownable, Pausable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Thrown when attempting to register an already registered name
    error NameAlreadyRegistered();
    
    /// @notice Thrown when querying or operating on a non-existent name
    error NameNotRegistered();
    
    /// @notice Thrown when caller is not the owner of the name
    error NotNameOwner();
    
    /// @notice Thrown when name doesn't meet validation requirements
    error InvalidName();
    
    /// @notice Thrown when address is zero address
    error InvalidAddress();
    
    /// @notice Thrown when insufficient payment is provided
    error InsufficientPayment();
    
    /// @notice Thrown when name has expired
    error NameExpired();
    
    /// @notice Thrown when attempting to renew a name too early
    error RenewalTooEarly();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Emitted when a new name is registered
    /// @param name The registered name
    /// @param owner The owner of the name
    /// @param expiresAt When the registration expires
    event NameRegistered(string indexed name, address indexed owner, uint256 expiresAt);
    
    /// @notice Emitted when name ownership is transferred
    /// @param name The transferred name
    /// @param from Previous owner
    /// @param to New owner
    event NameTransferred(string indexed name, address indexed from, address indexed to);
    
    /// @notice Emitted when a name is released
    /// @param name The released name
    /// @param owner The previous owner
    event NameReleased(string indexed name, address indexed owner);
    
    /// @notice Emitted when a name is renewed
    /// @param name The renewed name
    /// @param owner The owner
    /// @param newExpiresAt New expiration timestamp
    event NameRenewed(string indexed name, address indexed owner, uint256 newExpiresAt);
    
    /// @notice Emitted when registration fee is updated
    /// @param oldFee Previous fee
    /// @param newFee New fee
    event RegistrationFeeUpdated(uint256 oldFee, uint256 newFee);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Registration data structure
    /// @param owner Address that owns the name
    /// @param registeredAt Timestamp when registered
    /// @param expiresAt Timestamp when registration expires
    struct Registration {
        address owner;
        uint256 registeredAt;
        uint256 expiresAt;
    }

    /// @notice Mapping from name to registration data
    mapping(string => Registration) public registry;
    
    /// @notice Mapping from owner to their registered names
    mapping(address => string[]) public ownerNames;
    
    /// @notice Registration fee in wei
    uint256 public registrationFee;
    
    /// @notice Registration duration in seconds (default: 365 days)
    uint256 public constant REGISTRATION_DURATION = 365 days;
    
    /// @notice Minimum name length
    uint256 public constant MIN_NAME_LENGTH = 3;
    
    /// @notice Maximum name length
    uint256 public constant MAX_NAME_LENGTH = 32;
    
    /// @notice Grace period after expiration (30 days)
    uint256 public constant GRACE_PERIOD = 30 days;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Initialize the registry with initial fee
    /// @param _initialFee Initial registration fee in wei
    constructor(uint256 _initialFee) {
        _owner = msg.sender;
        _status = _NOT_ENTERED;
        registrationFee = _initialFee;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register a new name
     * @param name The name to register (3-32 characters)
     * @dev Requires payment of registrationFee, validates name format
     */
    function registerName(string calldata name) external payable whenNotPaused nonReentrant {
        _validateName(name);
        
        if (msg.value < registrationFee) revert InsufficientPayment();
        if (registry[name].owner != address(0) && !_isExpired(name)) {
            revert NameAlreadyRegistered();
        }

        uint256 expiresAt = block.timestamp + REGISTRATION_DURATION;
        
        registry[name] = Registration({
            owner: msg.sender,
            registeredAt: block.timestamp,
            expiresAt: expiresAt
        });

        ownerNames[msg.sender].push(name);

        emit NameRegistered(name, msg.sender, expiresAt);
        
        // Refund excess payment
        if (msg.value > registrationFee) {
            (bool success, ) = msg.sender.call{value: msg.value - registrationFee}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @notice Renew an existing name registration
     * @param name The name to renew
     * @dev Can only be renewed by current owner, extends expiration by REGISTRATION_DURATION
     */
    function renewName(string calldata name) external payable whenNotPaused nonReentrant {
        Registration storage reg = registry[name];
        
        if (reg.owner == address(0)) revert NameNotRegistered();
        if (reg.owner != msg.sender) revert NotNameOwner();
        if (msg.value < registrationFee) revert InsufficientPayment();
        
        uint256 newExpiresAt = reg.expiresAt + REGISTRATION_DURATION;
        reg.expiresAt = newExpiresAt;
        
        emit NameRenewed(name, msg.sender, newExpiresAt);
        
        // Refund excess payment
        if (msg.value > registrationFee) {
            (bool success, ) = msg.sender.call{value: msg.value - registrationFee}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @notice Transfer name ownership to another address
     * @param name The name to transfer
     * @param newOwner The address to transfer to
     * @dev Only callable by current owner, name must not be expired
     */
    function transferName(string calldata name, address newOwner) external whenNotPaused nonReentrant {
        if (newOwner == address(0)) revert InvalidAddress();
        
        Registration storage reg = registry[name];
        if (reg.owner == address(0)) revert NameNotRegistered();
        if (reg.owner != msg.sender) revert NotNameOwner();
        if (_isExpired(name)) revert NameExpired();

        address previousOwner = msg.sender;
        reg.owner = newOwner;

        // Remove from previous owner's list
        _removeNameFromOwner(previousOwner, name);
        
        // Add to new owner's list
        ownerNames[newOwner].push(name);

        emit NameTransferred(name, previousOwner, newOwner);
    }

    /**
     * @notice Release a name back to the registry
     * @param name The name to release
     * @dev Only callable by current owner
     */
    function releaseName(string calldata name) external whenNotPaused nonReentrant {
        Registration storage reg = registry[name];
        
        if (reg.owner == address(0)) revert NameNotRegistered();
        if (reg.owner != msg.sender) revert NotNameOwner();

        address owner = msg.sender;
        delete registry[name];
        _removeNameFromOwner(owner, name);

        emit NameReleased(name, owner);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if a name is available for registration
     * @param name The name to check
     * @return bool True if available (not registered or expired)
     */
    function isNameAvailable(string calldata name) external view returns (bool) {
        return registry[name].owner == address(0) || _isExpired(name);
    }

    /**
     * @notice Get the owner of a name
     * @param name The name to query
     * @return address The owner address (address(0) if not registered or expired)
     */
    function getNameOwner(string calldata name) external view returns (address) {
        if (_isExpired(name)) return address(0);
        return registry[name].owner;
    }

    /**
     * @notice Get full registration details
     * @param name The name to query
     * @return owner The owner address
     * @return registeredAt The registration timestamp
     * @return expiresAt The expiration timestamp
     * @return isExpired Whether the registration has expired
     */
    function getRegistration(string calldata name) 
        external 
        view 
        returns (
            address owner, 
            uint256 registeredAt, 
            uint256 expiresAt,
            bool isExpired
        ) 
    {
        Registration memory reg = registry[name];
        return (reg.owner, reg.registeredAt, reg.expiresAt, _isExpired(name));
    }

    /**
     * @notice Get all names owned by an address
     * @param owner The address to query
     * @return string[] Array of owned names (includes expired names)
     */
    function getOwnerNames(address owner) external view returns (string[] memory) {
        return ownerNames[owner];
    }
    
    /**
     * @notice Get all active (non-expired) names owned by an address
     * @param owner The address to query
     * @return activeNames Array of active owned names
     */
    function getActiveOwnerNames(address owner) external view returns (string[] memory) {
        string[] memory allNames = ownerNames[owner];
        uint256 activeCount = 0;
        
        // Count active names
        for (uint256 i = 0; i < allNames.length; i++) {
            if (!_isExpired(allNames[i])) {
                activeCount++;
            }
        }
        
        // Build active names array
        string[] memory activeNames = new string[](activeCount);
        uint256 index = 0;
        for (uint256 i = 0; i < allNames.length; i++) {
            if (!_isExpired(allNames[i])) {
                activeNames[index] = allNames[i];
                index++;
            }
        }
        
        return activeNames;
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Get the contract owner
     * @return address The owner address
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Update the registration fee
     * @param newFee New fee in wei
     * @dev Only callable by owner
     */
    function setRegistrationFee(uint256 newFee) external onlyOwner {
        uint256 oldFee = registrationFee;
        registrationFee = newFee;
        emit RegistrationFeeUpdated(oldFee, newFee);
    }

    /**
     * @notice Pause the contract
     * @dev Only callable by owner, prevents new registrations and transfers
     */
    function pause() external onlyOwner {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpause the contract
     * @dev Only callable by owner
     */
    function unpause() external onlyOwner {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @notice Withdraw accumulated fees
     * @param to Address to send fees to
     * @dev Only callable by owner
     */
    function withdrawFees(address payable to) external onlyOwner nonReentrant {
        if (to == address(0)) revert InvalidAddress();
        uint256 balance = address(this).balance;
        (bool success, ) = to.call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Validate name format and length
     * @param name The name to validate
     */
    function _validateName(string calldata name) internal pure {
        uint256 length = bytes(name).length;
        if (length < MIN_NAME_LENGTH || length > MAX_NAME_LENGTH) {
            revert InvalidName();
        }
        
        // Validate characters (alphanumeric and hyphens only)
        bytes memory nameBytes = bytes(name);
        for (uint256 i = 0; i < length; i++) {
            bytes1 char = nameBytes[i];
            bool isValid = (char >= 0x30 && char <= 0x39) || // 0-9
                          (char >= 0x61 && char <= 0x7A) || // a-z
                          (char >= 0x41 && char <= 0x5A) || // A-Z
                          (char == 0x2D);                    // hyphen
            if (!isValid) revert InvalidName();
        }
    }

    /**
     * @dev Check if a name registration has expired
     * @param name The name to check
     * @return bool True if expired (past grace period)
     */
    function _isExpired(string calldata name) internal view returns (bool) {
        Registration memory reg = registry[name];
        if (reg.owner == address(0)) return true;
        return block.timestamp > reg.expiresAt + GRACE_PERIOD;
    }

    /**
     * @dev Internal function to remove name from owner's list
     * @param owner The owner address
     * @param name The name to remove
     */
    function _removeNameFromOwner(address owner, string calldata name) internal {
        string[] storage names = ownerNames[owner];
        for (uint256 i = 0; i < names.length; i++) {
            if (keccak256(bytes(names[i])) == keccak256(bytes(name))) {
                names[i] = names[names.length - 1];
                names.pop();
                break;
            }
        }
    }
}
