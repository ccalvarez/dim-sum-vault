# Dim Sum Vault

### Descripción del contrato

Explicación del contrato desarrollado, incluyendo la funcionalidad principal.

Se decidio implementar una boveda siguiendo el estandar ERC4626 de OpenZepelin de tipo 'lending' en la cual los usuarios depositan token ERC20 y reciben a cambio otros tokens que pueden ser redimidos y dependiendo del tiempo generan algun valor o ganancia al usuario.

### Razonamiento detrás del diseño

Breve explicación de las decisiones técnicas y de diseño tomadas durante el desarrollo, haciendo énfasis en el uso de patrones de diseño en Solidity donde sea necesario.

El contrato puede ser pausable si hay alguna emergencia, pero solo el dueno puede realizar esta funcion de pausa y continuar siguiendo los patrones de onlyOwner y whenPaused
El usuario recibe un interes segun el tiempo que invierte sus tokens, se penaliza la salida anticipada del contrado por medio de un fee
Se crea una estructura para calcular las ganancias segun el tiempo que el usuario invierte sus tokens.


### Integrantes del equipo

[@ccalvarez](https://github.com/ccalvarez) - Carolina Cordero\
[@fedejim](https://github.com/fedejim) - Federico Jiménez\
[@aorue1](https://github.com/aorue1) - Andrés Orué Moraga \
[@cañas](https://github.com/Z3R0BYT3) - Alejandro Cañas
