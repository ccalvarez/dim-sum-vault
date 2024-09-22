// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DimSumVault is ERC4626, ReentrancyGuard {


     /*//////////////////////////////////////////////////////////////
                                 Variables
    //////////////////////////////////////////////////////////////*/


    address private owner;
    bool private paused;
    uint256 public rewardPool; // El pool de recompensas a distribuir
    uint256 public constant FEE_PERCENTAGE = 10; // 10% comision de retiro
    uint256 public constant EARLY_WITHDRAWAL_PENALTY = 10; // 10% penalty por retiro antes de ciclo
    uint256 public constant MIN_STAKING_DURATION = CYCLE_DURATION; // Minimum staking duration to avoid penalty
    uint256 private totalFees;
    uint256 private lastDistribution; // Ultima distribucion de ganancias
    uint256 private constant CYCLE_DURATION = 7 days; // Duracion del ciclo de staking
    mapping(address => uint256) public shareHolder; // a mapping that checks if a user has deposited a token.
    mapping(address => uint256) public depositTimestamps; // Mapping para guardar el timestamp de los depósitos.



     /*//////////////////////////////////////////////////////////////
                                 Modifiers
    //////////////////////////////////////////////////////////////*/


    // Access Restriction Pattern
    modifier onlyOwner() {
        require(msg.sender == owner, "The function is restricted to the owner only");
        _;
    }

    // Emergency Stop Pattern
    /*
    modifier whenPaused() {
        require(paused, "The contract is not paused");
        revert();
    }
    */
    
    // Emergency UnStop Pattern
    modifier whenNotPaused() {
        require(!paused, "The contract is paused");
        _;
    }

   

     /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/


    event Paused();
    event Unpaused();
    event FeesCollected(uint256 amount);
    event EarningsDistributed(uint256 amount);
    

     /*//////////////////////////////////////////////////////////////
                                 IMMUTABLES
    //////////////////////////////////////////////////////////////*/

      constructor(ERC20 asset)
      ERC20("Wo Tip,", "WTP") 
      ERC4626(asset) {}
    

    /*//////////////////////////////////////////////////////////////
                        Pause/Unpause Logic
    //////////////////////////////////////////////////////////////*/


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


     /*//////////////////////////////////////////////////////////////
                        Deposit/Withdraw Logic
    //////////////////////////////////////////////////////////////*/



    // Deposit to the vault an ERC20 token
    function stake(uint256 vaultAssets, address vaultReceiver) public whenNotPaused nonReentrant returns (uint256 shares) {
        require(vaultAssets > 0, "Assets must be greater than 0");
        shares = super.deposit(vaultAssets, vaultReceiver);
        shareHolder[vaultReceiver] += shares;
        depositTimestamps[vaultReceiver] = block.timestamp; // Almacena el timestamp del depósito.
        return shares;
    }

    // Withdraw from the vault the ERC20 tokens deposited
    function unstake(uint256 vaultAssets, address vaultReceiver, address vaultOwner) public whenNotPaused nonReentrant returns (uint256 shares) {
        require(vaultAssets > 0, "Assets must be greater than 0");
        require(vaultReceiver != address(0), "Receiver must not be address 0");
        uint256 fee = (vaultAssets * FEE_PERCENTAGE) / 100;
        unit256 penalty = 0;
        //Revisa si el retiro sucede antes del MIN_STAKING_DURATION
        if (block.timestamp < depositTimestamps[vaultReceiver] + MIN_STAKING_DURATION){ // Revisa si el retiro sucede antes del MIN_STAKING_DURATION
            penalty = (vaultAssets * EARLY_WITHDRAWAL_PENALTY)/100;  // Si es así, se le agrega un penalty de 10% a los shares
        }
        totalFees += fee + penalty;
        rewardPool += (totalFees / 2);
        shareHolder[vaultOwner] -= shares;
        shares = super.withdraw(vaultAssets - fee - penalty, vaultReceiver, vaultOwner);
        return shares;

    }

    function vaultRedeem(uint256 vaultShares, address vaultReceiver, address vaultOwner) public whenNotPaused returns (uint256 assets) {
        require(vaultShares > 0, "VaultShares must be greater than 0");
        require(vaultReceiver != address(0), "Receiver must not be address 0");
        uint256 vaultAssets = convertToAssets(vaultShares); // Convierte shares a assets
        
        // Calcula el fee (10%)
            uint256 fee = (vaultAssets * FEE_PERCENTAGE) / 100;
        // Inicializa el penalty a un default de 0.
            uint256 penalty = 0;
        //Revisa si el retiro sucede antes del MIN_STAKING_DURATION
        if (block.timestamp < depositTimestamps[vaultReceiver] + MIN_STAKING_DURATION) {// Revisa si el retiro sucede antes del MIN_STAKING_DURATION
            penalty = (vaultAssets * EARLY_WITHDRAWAL_PENALTY)/100;  // Si es así, se le agrega un penalty de 10% a los shares
        }
        // Agrega el fee a totalFees y al rewardPool
            totalFees += fee + penalty;
            rewardPool += (totalFees / 2); // Add half of the total fees to the rewardPool
        // Deducción del fee de los shares del owner y el total de la transacción de los vaultShares
        shareHolder[vaultOwner] -= vaultShares; 
        // Redime los shares.
        assets = super.redeem(vaultShares, vaultReceiver, vaultOwner); 
        assets = assets - fee - penalty;  // Deduce el fee de los assets
        return assets;
    }
    


    function distributeEarnings() public onlyOwner nonReentrant {
        require(block.timestamp >= lastDistribution + CYCLE_DURATION, "El ciclo de staking no ha terminado");
        uint256 earnings = rewardPool;
        rewardPool = 0;
        lastDistribution = block.timestamp;
        // Lógica para distribuir las ganancias entre los holders
        uint256 totalShares = totalSupply();
        for (uint256 i = 0; i < totalShares; i++) {
            address holder = address(uint160(i));
            uint256 holderShares = shareHolder[holder];
            if (holderShares > 0) {
                uint256 holderEarnings = calculateRewards(holder);
                _mint(holder, holderEarnings);
            }

         emit EarningsDistributed(earnings);
        }
    }


      /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/


    //Esta funcion se puede llamar internamente o externamente por cualquier usuario
    //@dev Esta funcion es publica para que los usuarios puedan previsualizar sus recompensas.
    function calculateRewards(address holder) public view returns(uint256){
        uint256 holderShares = shareHolder[holder];
        uint256 totalShares = totalSupply();
        uint256 userRewards = (rewardPool * holderShares) / totalShares;
        return userRewards;
    } 

    // Función para revisar el total de fees recoletados.
    function getTotalFees() public view returns (uint256) {
        return totalFees;
    }

    // Función para revisar el monto actual del reward pool.
    function getRewardPool() public view returns (uint256) {
        return rewardPool;
    }


}
