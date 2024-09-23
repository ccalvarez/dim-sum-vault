// SPDX-License-Identifier: MIT

pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
contract DimSumVault is ERC4626, ReentrancyGuard {


     /*//////////////////////////////////////////////////////////////
                                 Variables
    //////////////////////////////////////////////////////////////*/


    address private owner;
    bool private paused;
    uint256 public rewardPool; // El pool de recompensas a distribuir
    uint256 public constant FEE_PERCENTAGE = 10; // 10% comision de retiro
    uint256 public constant EARLY_WITHDRAWAL_PENALTY = 10; // 10% penalty por retiro antes de ciclo
    uint256 public constant CYCLE_DURATION = 7 days; // Duracion del ciclo de staking
    uint256 private totalFees;
    uint256 private lastDistribution; // Ultima distribucion de ganancias
    
    struct DepositLog {
        uint256 amount;
        uint256 timestamp;
    }

    address[] private shareHoldersList;
    
    mapping(address => uint256) public shareHolder; // a mapping that checks if a user has deposited a token.
    mapping(address => DepositLog[]) public deposits; // Mapping para guardar el timestamp de los depósitos.



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
      ERC4626(asset) {
        owner = msg.sender;
        paused = false;
        lastDistribution = block.timestamp;
      }
    

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



    // Deposita los tokens ERC20 a la bóveda.
    function stake(uint256 vaultAssets, address vaultReceiver) public whenNotPaused nonReentrant returns (uint256 shares) {
        require(vaultAssets > 0, "Assets must be greater than 0");
        shares = super.deposit(vaultAssets, vaultReceiver);
        deposits[vaultReceiver].push(DepositLog(vaultAssets, block.timestamp));
        if (shareHolder[vaultReceiver] == 0) {
            shareHoldersList.push(vaultReceiver); // Add to array if not already present
        }
        shareHolder[vaultReceiver] += shares;
        return shares;
    }

    // Withdraw from the vault the ERC20 tokens deposited
    // Esta funcion permite el retiro de los fondos depositados.
    // Si el usuario retira el deposito antes de cumplir el ciclo establecido, se le cobrará una penalizacion
    // por retiro anticipado.
    function unstake(uint256 vaultAssets, address vaultReceiver, address vaultOwner) public whenNotPaused nonReentrant returns (uint256 shares) {
        require(vaultAssets > 0, "Assets must be greater than 0");
        require(vaultReceiver != address(0), "Receiver must not be address 0");
        // El monto supera los fondos en su balance, o vaultOwner no existe en el mapping de holders (shareHolder[vaultOwner] retorna 0)
        require(shareHolder[vaultOwner] > vaultAssets, "Insufficient funds/Transfer not allowed");

        uint256 fee = (vaultAssets * FEE_PERCENTAGE) / 100;
        uint256 penalty = 0;
        if (deposits[vaultReceiver].length > 0 ){
            DepositLog memory firstDeposit = deposits[vaultReceiver][0];
            if (block.timestamp < firstDeposit.timestamp + CYCLE_DURATION){ // Revisa si el retiro sucede antes del MIN_STAKING_DURATION
                penalty = (vaultAssets * EARLY_WITHDRAWAL_PENALTY) / 100;  // Si es así, se le agrega un penalty de 10% a los shares
            }
        }

        totalFees += fee + penalty;
        rewardPool += (totalFees / 2);
        shareHolder[vaultOwner] -= vaultAssets;
        shares = super.withdraw(vaultAssets - fee - penalty, vaultReceiver, vaultOwner);
        return shares; // cantidad de shares que fueron quemados

    }
    // Funcion para el reclamo de las recompensas del ciclo.
    function vaultRedeem(uint256 vaultShares, address vaultReceiver, address vaultOwner) public whenNotPaused returns (uint256 assets) {
        DepositLog memory firstDeposit = deposits[vaultReceiver][0];
        require(vaultShares > 0, "VaultShares must be greater than 0");
        require(vaultReceiver != address(0), "Receiver must not be address 0");
        require(firstDeposit.timestamp + CYCLE_DURATION <= block.timestamp, "Deposit not met the time for rewards");
        uint256 vaultAssets = convertToAssets(vaultShares); // Convierte shares a assets
        
        // Calcula el fee (10%)
            uint256 fee = (vaultAssets * FEE_PERCENTAGE) / 100;
        // Agrega el fee a totalFees y al rewardPool
            totalFees += fee;
            rewardPool += (totalFees / 2); // Add half of the total fees to the rewardPool
        // Deducción del fee de los shares del owner y el total de la transacción de los vaultShares
        shareHolder[vaultOwner] -= vaultShares; 
        // Redime los shares.
        assets = super.redeem(vaultShares, vaultReceiver, vaultOwner); 
        assets = assets - fee;  // Deduce el fee de los assets
        return assets;
    }
    

    // Funcion de distribucion de recompensas a los usuarios.
    // Las recompensas se distribuyen en el token de la bóveda.
    function distributeEarnings() public onlyOwner nonReentrant {
        require(block.timestamp >= lastDistribution + CYCLE_DURATION, "El ciclo de staking no ha terminado");
        uint256 earnings = rewardPool;
        lastDistribution = block.timestamp;
        // Lógica para distribuir las ganancias entre los holders
        // uint256 totalShares = super.totalSupply();

        for (uint256 i = 0; i < shareHoldersList.length; i++) {
            address holder = shareHoldersList[i];
            uint256 holderShares = shareHolder[holder];
            if (holderShares > 0) {
                uint256 holderEarnings = calculateRewards(holder);
                super.mint(holderEarnings, holder);
                shareHolder[holder] += holderEarnings;
            }
        }
        rewardPool = 0;
        emit EarningsDistributed(earnings);
       
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

    function getShares(address holder) public view returns (uint256){
        return shareHolder[holder];
    }

    function getTimeUntilRedeem(address holder) public view returns (uint256){
        require(deposits[holder].length > 0, "No deposits found for user");
        DepositLog memory firstDeposit = deposits[holder][0];
        uint256 redeemTime = firstDeposit.timestamp + CYCLE_DURATION;
        if (block.timestamp < redeemTime){
            return redeemTime - block.timestamp;
        } else {
            return 0;
        }
    }




}
