# Dim Sum Vault

## Descripción del contrato

> Explicación del contrato desarrollado, incluyendo la funcionalidad principal.\
> \
> [al final removemos este enunciado]

Se decidio implementar una bóveda siguiendo el estándar ERC4626 de OpenZeppelin, en la cual los usuarios depositan token ERC20 y reciben a cambio otros tokens que pueden ser redimidos y dependiendo del tiempo generan algún valor o ganancia al usuario.

El usuario recibe un interés según el tiempo que invierte sus tokens, se penaliza la salida anticipada del contrado por medio de un fee.

Se crea una estructura para calcular las ganancias segun el tiempo que el usuario invierte sus tokens. **[<== esto me parece que puede ir en la sección de Decisiones técnicas]**

## Razonamiento detrás del diseño

> Breve explicación de las decisiones técnicas y de diseño tomadas durante el desarrollo, haciendo énfasis en el uso de patrones de diseño en Solidity donde sea necesario.\
> \
> [al final removemos este enunciado]

### Decisiones técnicas

[Reemplazar esto con breve explicación de las decisiones técnicas y de diseño tomadas durante el desarrollo]

### Patrones de diseño utilizados

#### Ownable

[Explicación, en qué consiste y por qué lo usamos]

#### Pausable

El contrato puede ser pausable si hay alguna emergencia, pero sólo el dueño puede realizar esta función de pausar y reanudar el contrato, siguiendo los patrones de Ownable y Paused.

#### Reentrancy Guard

[Explicación, en qué consiste y por qué lo usamos]

## Integrantes del equipo

[@ccalvarez](https://github.com/ccalvarez) - Carolina Cordero\
[@fedejim](https://github.com/fedejim) - Federico Jiménez\
[@aorue1](https://github.com/aorue1) - Andrés Orué Moraga\
[@cañas](https://github.com/Z3R0BYT3) - Alejandro Cañas
