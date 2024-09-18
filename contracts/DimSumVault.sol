// SPDX-License-Identifier: MIT



pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract DimSumVault is ERC4626 {

    constructor(IERC20 _asset) 
        ERC20("WoTip", "WTP")
        ERC4626(_asset)
    {}


    // 
    function vaultDeposit(uint256 vaultAssets, address vaultReceiver) public returns (uint256 shares) {
        super.deposit(vaultAssets, vaultReceiver);

        // retornar valor correcto
        return 0;
    }
    function vaultWithdraw(uint256 vaultAssets, address vaultReceiver, address vaultOwner) public returns (uint256 shares) {
        super.withdraw(vaultAssets, vaultReceiver, vaultOwner);

        // retornar valor correcto
        return 0;
    }
    function vaultRedeem(uint256 vaultShares, address vaultReceiver, address vaultOwner) public returns (uint256 assets){
        super.redeem(vaultShares, vaultReceiver, vaultOwner);

         // retornar valor correcto
        return 0;
    }

}