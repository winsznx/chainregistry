// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ChainRegistry.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        ChainRegistry registry = new ChainRegistry();
        
        console.log("ChainRegistry deployed to:", address(registry));
        
        vm.stopBroadcast();
    }
}
