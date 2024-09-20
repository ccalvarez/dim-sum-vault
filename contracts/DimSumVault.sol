// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract DimSumVault is ERC4626 {

    // Variables
    address private owner;
    bool private paused;
    mapping(address => uint256) public shareHolder; // a mapping that checks if a user has deposited a token

    // Access Restriction Pattern
    modifier onlyOwner() {
        require(msg.sender == owner, "The function is restricted to the owner only");
        _;
    }

    // Emergency Stop Pattern
    modifier whenPaused() {
        require(paused, "The contract is not paused");
        _;
    }

    // Emergency UnStop Pattern
    modifier whenNotPaused() {
        require(paused=false, "The contract is not unpaused");
        _;
    }

    // Events
    event Paused();

    event Unpaused();
    

    // Constructor
    //constructor (IERC20 _asset, string memory _name, string memory _symbol) 
    //ERC4626(_asset, _name, _symbol)
      constructor(IERC20 _asset) 
        ERC20("WoTip", "WTP")
        ERC4626(_asset)
    {
        owner = msg.sender;
        paused = paused;
    }
    
    // Pause the contract
    function pause() public onlyOwner {
        paused = true;
        emit Paused();
    }

    // Unpause the contract
    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused();
    }

    // Deposit to the vault an ERC20 token
    function vaultDeposit(uint256 vaultAssets, address vaultReceiver) public returns (uint256 shares) {
        super.deposit(vaultAssets, vaultReceiver);

        // retornar valor correcto
        return 0;
    }

    // Withdraw from the vault the ERC20 tokens deposited
    function vaultWithdraw(uint256 vaultAssets, address vaultReceiver, address vaultOwner) public returns (uint256 shares) {
        super.withdraw(vaultAssets, vaultReceiver, vaultOwner);

        // retornar valor correcto
        return 0;
    }

    // Withdraw from the vault earning winings from investing on this lending contract
    function vaultRedeem(uint256 vaultShares, address vaultReceiver, address vaultOwner) public returns (uint256 assets){
        super.redeem(vaultShares, vaultReceiver, vaultOwner);

         // retornar valor correcto
        return 0;
    }


}
