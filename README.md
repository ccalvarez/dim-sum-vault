# Dim Sum Vault

## Descripción del contrato


Se decidió implementar una bóveda de tipo liquid staking, siguiendo el estándar ERC-4626 de OpenZeppelin, en la cual los usuarios depositan token ERC-20 _(assets)_, y reciben a cambio tokens de la bóveda _(shares)_ que pueden ser redimidos y dependiendo del tiempo generan algún valor o ganancia al usuario.

- El usuario recibe un interés según el tiempo que invierte sus tokens, se penaliza la salida anticipada del contrado por medio de un fee.
- Si el inversionista retira toda su participación, se le aplica una penalización del 10%.
- El inversionista puede retirar las ganancias de su participación a partir del momento que se ha cumplido el primer ciclo de 7 días de inversión, y se le rebajará una comisión del 5% sobre cada retiro que realice.
- El usuario no puede realizar un retiro si su primer depópsito no ha cumplido con el equivalente a un ciclo.
- El dueño del contrato ejecutará la funcion para calcular las ganancias periodicamente en ciclos de 7 días.

El contrato Solidity creado se ubica dentro del folder [/contracts](https://github.com/ccalvarez/dim-sum-vault/tree/main/contracts) de este repositorio.

## Decisiones técnicas
- Se crea la función calculateRewards para calcular las ganancias segun el tiempo que el usuario invierte sus tokens.
- Se utiliza un struct llamado Deposit para crear una dimensión adicional y que cada inversionista pueda tener múltiples depósitos asociados a su address, con el monto del depósito y el timestamp de cada uno.
- Se utiliza un mapping llamado Deposits para asociar un address a un struct de Deposit con múltiples depósitos. Esto ayudará a poder calcular si el usuario tiene algún depósito que cumpla con un ciclo entero y que además no se le penalice si realiza un segúndo depósito que no cumpla con la fecha mínima de ciclo pero el primer depósito si lo haga.
  

## Patrones de diseño utilizados

- **Ownable:** El patron se utiliza para restringir el acceso a algunas funciones del contrato.  Solo el propietario tendra derechos elevados para ejecutar algunas funciones como por ejemplo 'Pausa', UnPause o 'distributeEarnings' para la distribucion de las ganancias a los inversores. Se implemento una variable 'owner' de tipo address, la cual se inicializa al momento de desplegar el contrato con la dirección de quien despliegó el contrato. Se agrego un modifiador 'onlyOwner' para validar quien ejecuta el llamado.

- **Pausable:** el contrato puede ser pausable si hay alguna emergencia, pero sólo el dueño puede realizar esta función de pausar y reanudar el contrato, siguiendo los patrones de Ownable y Paused.

- **Reentrancy Guard:** para prevenir ataques de reentrada que permitan a un atacante ejecutar repetidamente una función de la bóveda y drenar fondos o manipular el estado nuestro contrato de manera inesperada, hemos implementado el patrón Reentrancy Guard sobre las funciones que modifican los balances de la bóveda y que realizan transferencias de tokens, pues dichas funciones son más vulnerables a este tipo de ataques.

## Integrantes del equipo

[@ccalvarez](https://github.com/ccalvarez) - Carolina Cordero\
[@fedejim](https://github.com/fedejim) - Federico Jiménez\
[@aorue1](https://github.com/aorue1) - Andrés Orué Moraga\
[@cañas](https://github.com/Z3R0BYT3) - Alejandro Cañas
