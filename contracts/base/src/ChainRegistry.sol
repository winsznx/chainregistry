// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ChainRegistry
 * @notice Decentralized username/domain registry with ownership transfer
 * @dev First-come-first-serve registration with transfer capabilities
 */
contract ChainRegistry {
    // Custom errors for gas efficiency
    error NameAlreadyRegistered();
    error NameNotRegistered();
    error NotNameOwner();
    error InvalidName();
    error InvalidAddress();

    // Events
    event NameRegistered(string indexed name, address indexed owner, uint256 timestamp);
    event NameTransferred(string indexed name, address indexed from, address indexed to);
    event NameReleased(string indexed name, address indexed owner);

    // State variables
    struct Registration {
        address owner;
        uint256 registeredAt;
    }

    mapping(string => Registration) public registry;
    mapping(address => string[]) public ownerNames;

    /**
     * @notice Register a new name
     * @param name The name to register
     */
    function registerName(string calldata name) external {
        if (bytes(name).length == 0 || bytes(name).length > 32) revert InvalidName();
        if (registry[name].owner != address(0)) revert NameAlreadyRegistered();

        registry[name] = Registration({
            owner: msg.sender,
            registeredAt: block.timestamp
        });

        ownerNames[msg.sender].push(name);

        emit NameRegistered(name, msg.sender, block.timestamp);
    }

    /**
     * @notice Transfer name ownership to another address
     * @param name The name to transfer
     * @param newOwner The address to transfer to
     */
    function transferName(string calldata name, address newOwner) external {
        if (newOwner == address(0)) revert InvalidAddress();
        if (registry[name].owner == address(0)) revert NameNotRegistered();
        if (registry[name].owner != msg.sender) revert NotNameOwner();

        address previousOwner = msg.sender;
        registry[name].owner = newOwner;

        // Remove from previous owner's list
        _removeNameFromOwner(previousOwner, name);
        
        // Add to new owner's list
        ownerNames[newOwner].push(name);

        emit NameTransferred(name, previousOwner, newOwner);
    }

    /**
     * @notice Release a name back to the registry
     * @param name The name to release
     */
    function releaseName(string calldata name) external {
        if (registry[name].owner == address(0)) revert NameNotRegistered();
        if (registry[name].owner != msg.sender) revert NotNameOwner();

        address owner = msg.sender;
        delete registry[name];
        _removeNameFromOwner(owner, name);

        emit NameReleased(name, owner);
    }

    /**
     * @notice Check if a name is available
     * @param name The name to check
     * @return bool True if available
     */
    function isNameAvailable(string calldata name) external view returns (bool) {
        return registry[name].owner == address(0);
    }

    /**
     * @notice Get the owner of a name
     * @param name The name to query
     * @return address The owner address
     */
    function getNameOwner(string calldata name) external view returns (address) {
        return registry[name].owner;
    }

    /**
     * @notice Get registration details
     * @param name The name to query
     * @return owner The owner address
     * @return registeredAt The registration timestamp
     */
    function getRegistration(string calldata name) external view returns (address owner, uint256 registeredAt) {
        Registration memory reg = registry[name];
        return (reg.owner, reg.registeredAt);
    }

    /**
     * @notice Get all names owned by an address
     * @param owner The address to query
     * @return string[] Array of owned names
     */
    function getOwnerNames(address owner) external view returns (string[] memory) {
        return ownerNames[owner];
    }

    /**
     * @dev Internal function to remove name from owner's list
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
