<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Tipos enteros de anchura fija

[i[Fixed width integers]<]

C tiene todos esos tipos de enteros pequeños, grandes y más grandes como `int` y `long` y todo eso. Y puedes mirar en [la sección sobre límites](#limits-macros) para ver cuál es el int más grande con `INT_MAX` y así sucesivamente.

¿Qué tamaño tienen esos tipos? Es decir, ¿cuántos bytes ocupan? Podríamos usar `sizeof` para obtener esa respuesta.

Pero, ¿y si quisiera ir por otro camino? ¿Y si necesitara un tipo que tuviera exactamente 32 bits (4 bytes) o al menos 16 bits o algo así?

¿Cómo podemos declarar un tipo que tenga un tamaño determinado?
La cabecera [i[`stdint.h` header file]] `<stdint.h>` nos da una manera.

## Tipos con tamaño de bit

Tanto para los enteros con signo como para los enteros sin signo, podemos especificar un tipo que tenga un cierto número de bits, con algunas salvedades, por supuesto.

Y hay tres clases principales de estos tipos (en estos ejemplos, el `N` sería reemplazado por un cierto número de bits):

* Enteros de exactamente un cierto tamaño (`intN_t`)
* Enteros que tienen al menos un cierto tamaño (`int_leastN_t`)
* Enteros que tienen al menos un cierto tamaño y son lo más rápidos posible (`int_fastN_t`)[^4582]

[^4582]: Algunas arquitecturas tienen datos de distinto tamaño con los que la CPU y la RAM pueden operar a mayor velocidad que con otros. En esos casos, si necesitas el número de 8 bits más rápido, puede que te de un tipo de 16 o 32 bits en su lugar porque simplemente es más rápido. Así que con esto, no sabrás lo grande que es el tipo, pero será al menos tan grande como tú digas.

¿Cuánto más rápido es `fast`? Definitivamente, quizás algo más rápido. Probablemente. La especificación no dice cuánto más rápido, sólo que será el más rápido en esta arquitectura. Sin embargo, la mayoría de los compiladores de C son bastante buenos, por lo que probablemente sólo lo veas usado en lugares donde se necesita garantizar la mayor velocidad posible (en lugar de simplemente esperar que el compilador produzca un código bastante rápido, como es el caso).

Finalmente, estos tipos de números sin signo tienen una "u" inicial para diferenciarlos.

Por ejemplo, estos tipos tienen el significado listado correspondiente:

[i[`int_leastN_t` types]<]
[i[`uint_leastN_t` types]<]
[i[`int_fastN_t` types]<]
[i[`uint_fastN_t` types]<]
[i[`intN_t` types]<]
[i[`uintN_t` types]<]

``` {.c}
int32_t w; // x es exactamente 32 bits, con signo
uint16_t x; // y es exactamente 16 bits, sin signo

int_least8_t y; // y es de al menos 8 bits, con signo

uint_fast64_t z; //z es la representación más rápida
                 // sin signo de al menos 64 bits.
```

Se garantiza la definición de los siguientes tipos:

``` {.c}
int_least8_t      uint_least8_t
int_least16_t     uint_least16_t
int_least32_t     uint_least32_t
int_least64_t     uint_least64_t

int_fast8_t       uint_fast8_t
int_fast16_t      uint_fast16_t
int_fast32_t      uint_fast32_t
int_fast64_t      uint_fast64_t
```

También puede haber otros de diferentes anchos, pero son opcionales.

¿Dónde están los tipos fijos como `int16_t`? Resulta que son completamente opcionales... a menos que se cumplan ciertas condiciones^[Es decir, que el sistema tenga enteros de 8, 16, 32 o 64 bits sin relleno que utilicen la representación del complemento a dos, en cuyo caso la variante `intN_t` para ese número concreto de bits _debe_ estar definida]. Y si tienes un sistema informático moderno normal y corriente, probablemente se cumplan esas condiciones. Y si lo son, tendrás estos tipos:

``` {.c}
int8_t      uint8_t
int16_t     uint16_t
int32_t     uint32_t
int64_t     uint64_t
```

Pueden definirse otras variantes con anchuras diferentes, pero son opcionales.

[i[`int_leastN_t` types]>]
[i[`uint_leastN_t` types]>]
[i[`int_fastN_t` types]>]
[i[`uint_fastN_t` types]>]
[i[`intN_t` types]>]
[i[`uintN_t` types]>]

## Tipo de tamaño entero máximo

Hay un tipo que puedes usar que contiene los enteros representables más grandes disponibles en el sistema, tanto con signo como sin signo:

[i[`intmax_t` type]<]
[i[`uintmax_t` type]<]

``` {.c}
intmax_t
uintmax_t
```

[i[`intmax_t` type]>]
[i[`uintmax_t` type]>]

Utilice estos tipos cuando quiera ir lo más grande posible.

Obviamente los valores de cualquier otro tipo entero del mismo signo cabrán en este tipo, necesariamente.

## Uso de Constantes de Tamaño Fijo

Si tienes una constante que quieres que quepa en un cierto número de bits, puedes usar estas macros para añadir automáticamente el sufijo apropiado al número (por ejemplo `22L` o `3490ULL`).

[i[`INTn_C()` macros]<]
[i[`UINTn_C()` macros]<]
[i[`INTMAX_C()` macro]<]
[i[`UINTMAX_C()` macro]<]

``` {.c}
INT8_C(x)     UINT8_C(x)
INT16_C(x)    UINT16_C(x)
INT32_C(x)    UINT32_C(x)
INT64_C(x)    UINT64_C(x)
INTMAX_C(x)   UINTMAX_C(x)
```

[i[`INTn_C()` macros]>]
[i[`UINTMAX_C()` macro]>]

De nuevo, sólo funcionan con valores enteros constantes.

Por ejemplo, podemos utilizar uno de estos para asignar valores constantes así:

``` {.c}
uint16_t x = UINT16_C(12);
intmax_t y = INTMAX_C(3490);
```

[i[`UINTn_C()` macros]>]
[i[`INTMAX_C()` macro]>]

## Límites de enteros de tamaño fijo

También tenemos definidos algunos límites para que puedas obtener los valores máximos y mínimos de estos tipos:

[i[`INTn_MAX` macros]<]
[i[`INTn_MIN` macros]<]
[i[`UINTn_MAX` macros]<]
[i[`INT_LEASTn_MAX` macros]<]
[i[`INT_LEASTn_MIN` macros]<]
[i[`UINT_LEASTn_MAX` macros]<]
[i[`INT_FASTn_MAX` macros]<]
[i[`INT_FASTn_MIN` macros]<]
[i[`UINT_FASTn_MAX` macros]<]
[i[`INTMAX_MAX` macro]<]
[i[`INTMAX_MIN` macro]<]
[i[`UINTMAX_MAX` macro]<]

``` {.c}
INT8_MAX           INT8_MIN           UINT8_MAX
INT16_MAX          INT16_MIN          UINT16_MAX
INT32_MAX          INT32_MIN          UINT32_MAX
INT64_MAX          INT64_MIN          UINT64_MAX

INT_LEAST8_MAX     INT_LEAST8_MIN     UINT_LEAST8_MAX
INT_LEAST16_MAX    INT_LEAST16_MIN    UINT_LEAST16_MAX
INT_LEAST32_MAX    INT_LEAST32_MIN    UINT_LEAST32_MAX
INT_LEAST64_MAX    INT_LEAST64_MIN    UINT_LEAST64_MAX

INT_FAST8_MAX      INT_FAST8_MIN      UINT_FAST8_MAX
INT_FAST16_MAX     INT_FAST16_MIN     UINT_FAST16_MAX
INT_FAST32_MAX     INT_FAST32_MIN     UINT_FAST32_MAX
INT_FAST64_MAX     INT_FAST64_MIN     UINT_FAST64_MAX

INTMAX_MAX         INTMAX_MIN         UINTMAX_MAX
```

[i[`INTn_MAX` macros]>]
[i[`UINTn_MAX` macros]>]
[i[`INT_LEASTn_MAX` macros]>]
[i[`UINT_LEASTn_MAX` macros]>]
[i[`INT_FASTn_MAX` macros]>]
[i[`UINT_FASTn_MAX` macros]>]
[i[`INTMAX_MAX` macro]>]
[i[`UINTMAX_MAX` macro]>]

Tenga en cuenta que `MIN` para todos los tipos sin signo es `0`, por lo que, como tal, no hay macro para ello.

[i[`INTn_MIN` macros]>]
[i[`INT_LEASTn_MIN` macros]>]
[i[`INT_FASTn_MIN` macros]>]
[i[`INTMAX_MIN` macro]>]

## Especificadores de formato

Para imprimir estos tipos, necesita enviar el especificador de formato correcto a [i[`printf()` function]] `printf()`. (Y lo mismo para obtener la entrada con la función [i[`scanf()` function]] `scanf()`). `scanf()`.)

Pero, ¿cómo vas a saber qué tamaño tienen los tipos bajo el capó? Por suerte, una vez más, C proporciona algunas macros para ayudar con esto.

Todo esto se puede encontrar en `<inttypes.h>`.

Ahora, tenemos un montón de macros. Como una explosión de complejidad de macros. Así que voy a dejar de enumerar cada una y sólo voy a poner la letra minúscula `n` en el lugar donde deberías poner `8`, `16`, `32`, o `64` dependiendo de tus necesidades.

Veamos las macros para imprimir enteros con signo:

[i[`PRIdn` macros]<]
[i[`PRIin` macros]<]
[i[`PRIdLEASTn` macros]<]
[i[`PRIiLEASTn` macros]<]
[i[`PRIdFASTn` macros]<]
[i[`PRIiFASTn` macros]<]
[i[`PRIdMAX` macro]<]
[i[`PRIiMAX` macro]<]

``` {.c}
PRIdn    PRIdLEASTn    PRIdFASTn    PRIdMAX
PRIin    PRIiLEASTn    PRIiFASTn    PRIiMAX
```

Busque allí los patrones. Puedes ver que hay variantes para los tipos fijo, mínimo, rápido y máximo.

Y también tienes una "d" minúscula y una "i" minúscula. Corresponden a los especificadores de formato `printf()` `%d` y `%i`.

Así que si tengo algo de tipo

``` {.c}
int_least16_t x = 3490;
```

Puedo imprimirlo con el especificador de formato equivalente para `%d` utilizando `PRIdLEAST16`.

¿Pero cómo? ¿Cómo usamos esa macro?

En primer lugar, esa macro especifica una cadena que contiene la letra o letras que `printf()` necesita usar para imprimir ese tipo. Como, por ejemplo, podría ser `"d"` o `"ld"`.

Así que todo lo que tenemos que hacer es incrustar eso en nuestra cadena de formato para la llamada a `printf()`.

Para ello, podemos aprovechar un hecho sobre C que puede que hayas olvidado: las cadenas literales adyacentes se concatenan automáticamente en una sola cadena. Por ejemplo

``` {.c}
printf("Hello, " "world!\n");   // Imprime "Hello, world!"
```

Y como estas macros son literales de cadena, podemos usarlas así:

``` {.c .numberLines}
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

int main(void)
{
    int_least16_t x = 3490;

    printf("The value is %" PRIdLEAST16 "!\n", x);
}
```

[i[`PRIdn` macros]>]
[i[`PRIin` macros]>]
[i[`PRIdLEASTn` macros]>]
[i[`PRIiLEASTn` macros]>]
[i[`PRIdFASTn` macros]>]
[i[`PRIiFASTn` macros]>]
[i[`PRIdMAX` macro]>]
[i[`PRIiMAX` macro]>]

También tenemos un montón de macros para imprimir tipos sin signo:

[i[`PRIon` macros]<]
[i[`PRIun` macros]<]
[i[`PRIxn` macros]<]
[i[`PRIXn` macros]<]
[i[`PRIoLEASTn` macros]<]
[i[`PRIuLEASTn` macros]<]
[i[`PRIxLEASTn` macros]<]
[i[`PRIXLEASTn` macros]<]
[i[`PRIoFASTn` macros]<]
[i[`PRIuFASTn` macros]<]
[i[`PRIxFASTn` macros]<]
[i[`PRIXFASTn` macros]<]
[i[`PRIoMAX` macros]<]
[i[`PRIuMAX` macros]<]
[i[`PRIxMAX` macros]<]
[i[`PRIXMAX` macros]<]

``` {.c}
PRIon    PRIoLEASTn    PRIoFASTn    PRIoMAX
PRIun    PRIuLEASTn    PRIuFASTn    PRIuMAX
PRIxn    PRIxLEASTn    PRIxFASTn    PRIxMAX
PRIXn    PRIXLEASTn    PRIXFASTn    PRIXMAX
```

En este caso, `o`, `u`, `x`, y `X` corresponden a los especificadores de formato documentados en `printf()`.

Y, como antes, la minúscula `n` debe sustituirse por `8`, `16`, `32`, o `64`.

[i[`PRIon` macros]>]
[i[`PRIun` macros]>]
[i[`PRIxn` macros]>]
[i[`PRIXn` macros]>]
[i[`PRIoLEASTn` macros]>]
[i[`PRIuLEASTn` macros]>]
[i[`PRIxLEASTn` macros]>]
[i[`PRIXLEASTn` macros]>]
[i[`PRIoFASTn` macros]>]
[i[`PRIuFASTn` macros]>]
[i[`PRIxFASTn` macros]>]
[i[`PRIXFASTn` macros]>]
[i[`PRIoMAX` macros]>]
[i[`PRIuMAX` macros]>]
[i[`PRIxMAX` macros]>]
[i[`PRIXMAX` macros]>]

Pero justo cuando crees que ya has tenido suficiente con las macros, resulta que tenemos un completo conjunto complementario de ellas para [i[`scanf()` function]] ¡`scanf()`!

[i[`SCNdn` macros]<]
[i[`SCNin` macros]<]
[i[`SCNon` macros]<]
[i[`SCNun` macros]<]
[i[`SCNxn` macros]<]
[i[`SCNdLEASTn` macros]<]
[i[`SCNiLEASTn` macros]<]
[i[`SCNoLEASTn` macros]<]
[i[`SCNuLEASTn` macros]<]
[i[`SCNxLEASTn` macros]<]
[i[`SCNdFASTn` macros]<]
[i[`SCNiFASTn` macros]<]
[i[`SCNoFASTn` macros]<]
[i[`SCNuFASTn` macros]<]
[i[`SCNxFASTn` macros]<]
[i[`SCNdMAX` macros]<]
[i[`SCNiMAX` macros]<]
[i[`SCNoMAX` macros]<]
[i[`SCNuMAX` macros]<]
[i[`SCNxMAX` macros]<]

``` {.c}
SCNdn    SCNdLEASTn    SCNdFASTn    SCNdMAX
SCNin    SCNiLEASTn    SCNiFASTn    SCNiMAX
SCNon    SCNoLEASTn    SCNoFASTn    SCNoMAX
SCNun    SCNuLEASTn    SCNuFASTn    SCNuMAX
SCNxn    SCNxLEASTn    SCNxFASTn    SCNxMAX
```

[i[`SCNdn` macros]>]
[i[`SCNin` macros]>]
[i[`SCNon` macros]>]
[i[`SCNun` macros]>]
[i[`SCNxn` macros]>]
[i[`SCNdLEASTn` macros]>]
[i[`SCNiLEASTn` macros]>]
[i[`SCNoLEASTn` macros]>]
[i[`SCNuLEASTn` macros]>]
[i[`SCNxLEASTn` macros]>]
[i[`SCNdFASTn` macros]>]
[i[`SCNiFASTn` macros]>]
[i[`SCNoFASTn` macros]>]
[i[`SCNuFASTn` macros]>]
[i[`SCNxFASTn` macros]>]
[i[`SCNdMAX` macros]>]
[i[`SCNiMAX` macros]>]
[i[`SCNoMAX` macros]>]
[i[`SCNuMAX` macros]>]
[i[`SCNxMAX` macros]>]

Recuerde: cuando quiera imprimir un tipo entero de tamaño fijo con `printf()` o `scanf()`, tome la especificación de formato correspondiente de `<inttypes.h>`.

[i[Fixed width integers]>]
