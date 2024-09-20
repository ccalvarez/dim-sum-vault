// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {ERC20} "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract DimSumVault is ERC20, ERC4626 {

    // Variables
    address private owner;
    bool private paused;
    uint256 public constant FEE_PERCENTAGE = 5; // 5% comision de retiro
    uint256 private totalFees;
    uint256 private lastDistribution; // Ultima distribucion de ganancias
    uint256 private constant CYCLE_DURATION = 7 days; // Duracion del ciclo de staking
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
        require(!paused, "The contract is not unpaused");
        _;
    }

    // Events
    event Paused();
    event Unpaused();
    event FeesCollected(uint256 amount);
    event EarningsDistributed(uint256 amount);
    

    // Constructor
    //constructor (IERC20 _asset, string memory _name, string memory _symbol) 
    //ERC4626(_asset, _name, _symbol)
      constructor(IERC20 _asset) 
        ERC20("WoTip", "WTP")
        ERC4626(_asset)
    {
        owner = msg.sender;
        paused = false;
        lastDistribution = block.timestamp;
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
    function stake(uint256 vaultAssets, address vaultReceiver) public returns (uint256 shares) {
        require(vaultAssets > 0, "Assets must be greater than 0");
        shares = super.deposit(vaultAssets, vaultReceiver);
        shareHolder[vaultReceiver] += shares;
        return shares;


    }

    // Withdraw from the vault the ERC20 tokens deposited
    function unstake(uint256 vaultAssets, address vaultReceiver, address vaultOwner) public returns (uint256 shares) {
        require(vaultAssets > 0, "Assets must be greater than 0");
        require(vaultReceiver != address(0); "Receiver must not be address 0");
        uint256 fee = (vaultAssets * FEE_PERCENTAGE) / 100;
        totalFees += fee;
        shareHolder[vaultOwner] -= shares;
        shares = super.withdraw(vaultAssets - fee, vaultReceiver, vaultOwner);
        return shares;

        emit FeesCollected(fee);

        // shares = super.deposit(vaultAssets, vaultReceiver);
        // shareHolder[vaultReceiver] += shares;
        // // retornar valor correcto
        // return shares;
    }

    // Withdraw from the vault earning winings from investing on this lending contract
    function vaultRedeem(uint256 vaultShares, address vaultReceiver, address vaultOwner) public returns (uint256 assets){
        require(vaultShares > 0, "Assets must be greater than 0");
        require(vaultReceiver != address(0), "Receiver must not be address 0");
        
        shareHolder[vaultOwner] -= vaultShares;
        assets = super.redeem(vaultShares, vaultReceiver, vaultOwner);
        return assets;
    }


    function distributeEarnings() public onlyOwner {
        require(block.timestamp >= lastDistribution + CYCLE_DURATION, "El ciclo de staking no ha terminado");
        uint256 earnings = totalFees;
        totalFees = 0;
        lastDistribution = block.timestamp;
       

        // Lógica para distribuir las ganancias entre los holders
        uint256 totalShares = totalSupply();
        for (uint256 i = 0; i < totalShares; i++) {
            address holder = address(uint160(i));
            uint256 holderShares = shareHolder[holder];
            if (holderShares > 0) {
                uint256 holderEarnings = (earnings * holderShares) / totalShares;
                _mint(holder, holderEarnings);
            }

         emit EarningsDistributed(earnings);


}
