<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Operaciones bit a bit

[i[Bitwise operations]<]

Estas operaciones numéricas permiten manipular bits individuales de las variables, lo que encaja
con el hecho de que C sea un lenguaje de bajo nivel^[No es que otros lenguajes no lo hagan...
lo hacen. Es interesante ver cómo muchos lenguajes modernos utilizan los mismos operadores
para bitwise que C].

Si no estás familiarizado con las operaciones bit a bit, [flw[Wikipedia tiene un buen artículo
sobre operaciones bit a bit|Bitwise_operation]].

## AND, OR, XOR y NOT por bits

Para cada uno de ellos, las [conversiones aritméticas habituales](#usual-arithmetic-conversions) tienen lugar en los operandos (que en este caso deben ser de tipo entero), y luego se realiza la operación bitwise apropiada.

[i[`&` bitwise AND]]
[i[`|` bitwise OR]]
[i[`^` bitwise XOR]]
[i[`~` bitwise NOT]]

|Operación|Operador|Ejemplo|
|-|:-:|-|
|AND|`&`|`a = b & c`|
|OR|`|`|`a = b | c`|
|XOR|`^`|`a = b ^ c`|
|NOT|`~`|`a = ~c`|

Observe que son similares a los operadores booleanos `&&` y `||`.

Éstos tienen variantes abreviadas de asignación similares a `+=` y `-=`:

[i[`&=` assignment]]
[i[`|=` assignment]]
[i[`^=` assignment]]

|Operador|Ejemplo|Equivalente taquigráfico|
|-|-|-|
|`&=`|`a &= c`|`a = a & c`|
|`|=`|`a |= c`|`a = a | c`|
|`^=`|`a ^= c`|`a = a ^ c`|

## Desplazamiento (Bitwise)

Para ellos, las [i[promociones de enteros]] [promociones de enteros](#integer-promotions)  se
realizan en cada operando (que debe ser de tipo entero) y luego se ejecuta un desplazamiento
a nivel de bits. El tipo del resultado es el tipo del operando izquierdo promocionado.

Los nuevos bits se rellenan con ceros, con una posible excepción indicada en el comportamiento
definido por la implementación, a continuación.

[i[`<<` shift left]]
[i[`>>` shift right]]

|Operación|Operador|Ejemplo|
|-|:-:|-|
|Desplazamiento a la izquierda|`<<`|`a = b << c`|
|Desplazamiento a la derecha|`>>`|`a = b >> c`|

También existe la misma taquigrafía similar para el desplazamiento:

[i[`>>=` assignment]]
[i[`<<=` assignment]]

|Operador|Ejemplo|Equivalente a mano larga|
|-|-|-|
|`>>=`|`a >>= c`|`a = a >> c`|
|`<<=`|`a <<= c`|`a = a << c`|

Tenga cuidado con el comportamiento indefinido: no se permiten desplazamientos negativos
ni desplazamientos mayores que el tamaño del operando izquierdo promocionado.

También hay que tener cuidado con el comportamiento definido por la implementación: si se desplaza
a la derecha un número negativo, los resultados están definidos por la implementación.
(Es perfectamente correcto desplazar a la derecha un `int` con signo, sólo asegúrese
de que es positivo).

[i[Bitwise operations]>]
