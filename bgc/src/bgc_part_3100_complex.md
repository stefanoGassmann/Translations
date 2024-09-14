<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Números complejos

[i[Complex numbers]<]

Un pequeño manual sobre [flw[Números complejos|Complex_number]] robado directamente de Wikipedia:

> Un **número complejo** es un número que puede expresarse de la forma
> $a+bi$, donde $a$ y $b$ son números reales [es decir, tipos de coma flotante
> en C], y $i$ representa la unidad imaginaria, satisfaciendo la ecuación
> $i^2=-1$. Dado que ningún número real satisface esta ecuación, $i$ se denomina número imaginario.
> Para el número complejo $a+bi$, $a$ se denomina
> se llama **parte real**, y $b$ se llama **parte imaginaria**.

Pero hasta aquí voy a llegar. Asumiremos que si estás leyendo este capítulo, sabes lo que es un número complejo y lo que quieres hacer con ellos.

Y todo lo que necesitamos cubrir son las facultades de C para hacerlo.

Resulta, sin embargo, que el soporte de números complejos en un compilador es una característica _opcional_. No todos los compiladores compatibles pueden hacerlo. Y los que lo hacen, puede que lo hagan con distintos grados de completitud.

Puedes comprobar si tu sistema soporta números complejos con:

[i[`__STDC_NO_COMPLEX__` macro]<]

``` {.c}
#ifdef __STDC_NO_COMPLEX__
#error Complex numbers not supported!
#endif
```

[i[`__STDC_NO_COMPLEX__` macro]>]

[i[`__STDC_IEC_559_COMPLEX__` macro]<]

Además, hay una macro que indica la adhesión a la norma ISO 60559 (IEEE 754) para matemáticas en coma flotante con números complejos, así como la presencia del tipo `_Imaginary`.

``` {.c}
#if __STDC_IEC_559_COMPLEX__ != 1
#error Need IEC 60559 complex support!
#endif
```

[i[`__STDC_IEC_559_COMPLEX__` macro]>]

Encontrará más información al respecto en el Anexo G de la especificación C11.

## Tipos complejos

Para usar números complejos,  [i[`complex.h` header file]] `#include <complex.h>`.

Con eso, se obtienen al menos dos tipos:

[i[`_Complex` type]]
[i[`complex` type]<]

``` {.c}
_Complex
complex
```

Ambos significan lo mismo, por lo que es mejor utilizar el más bonito `complex`.
[i[`complex` type]>]

También dispone de algunos tipos para números imaginarios si su aplicación cumple la norma IEC 60559:

[i[`_Imaginary` type]]
[i[`imaginary` type]<]

``` {.c}
_Imaginary
imaginary
```

Ambos significan lo mismo, así que puedes usar el más bonito `imaginary`.

[i[`imaginary` type]>]

También se obtienen valores para el propio número imaginario $i$:

[i[`I` macro]<]
[i[`_Complex_I` macro]<]
[i[`_Imaginary_I` macro]<]

``` {.c}
I
_Complex_I
_Imaginary_I
```

La macro `I` se establece en `_Imaginario_I` (si está disponible), o `_I_Complejo`. Así que sólo tiene que utilizar `I` para el número imaginario.

[i[`I` macro]>]
[i[`_Complex_I` macro]>]

[i[`__STDC_IEC_559_COMPLEX__` macro]<]

Un inciso: he dicho que si un compilador tiene `__STDC_IEC_559_COMPLEX__` a `1`, debe soportar tipos `_Imaginary` para ser compatible. Esa es mi lectura de la especificación. Sin embargo, no conozco ningún compilador que soporte `_Imaginary` aunque tenga `__STDC_IEC_559_COMPLEX__`. Así que voy a escribir algo de código con ese tipo que no tengo forma de probar. Lo siento.

[i[`__STDC_IEC_559_COMPLEX__` macro]>]
[i[`_Imaginary_I` macro]>]

Bien, ahora que sabemos que existe un tipo `complejo`, ¿cómo podemos usarlo?

## Asignando Números Complejos
[i[Complex numbers-->declaring]<]

Dado que el número complejo tiene una parte real y otra imaginaria, pero ambas se basan en números de coma flotante para almacenar valores, también tenemos que decirle a C qué precisión utilizar para esas partes del número complejo.

[i[`complex float` type]<]
[i[`complex double` type]<]
[i[`complex long double` type]<]

Para ello, basta con fijar un `float`, un `double` o un `long double` al `complex`, antes o después de él.

[i[`complex long double` type]>]

Definamos un número complejo que utilice `float` para sus componentes:

``` {.c}
float complex c; // Spec prefiere esta forma
float complex c; // Lo mismo--el orden no importa
```

Eso está muy bien para las declaraciones, pero ¿cómo las inicializamos o asignamos?

Resulta que podemos utilizar una notación bastante natural. Ejemplo

[i[`I` macro]<]

``` {.c}
double complex x = 5 + 2*I;
double complex y = 10 + 3*I;
```

[i[`I` macro]>]

Para 5+2i$ y 10+3i$, respectivamente.

[i[`complex float` type]>]
[i[`complex double` type]>]
[i[Complex numbers-->declaring]>]

## Construir, deconstruir e imprimir

Ya estamos llegando...

Ya hemos visto una forma de escribir un número complejo:

``` {.c}
double complex x = 5 + 2*I;
```

Tampoco hay problema en utilizar otros números de coma flotante para construirlo:

``` {.c}
double a = 5;
double b = 2;
double complex x = a + b*I;
```

[i[`CMPLX()` macro]<]

También hay un conjunto de macros para ayudar a construir estos. El código anterior podría escribirse utilizando la macro `CMPLX()`, así:

``` {.c}
double complex x = CMPLX(5, 2);
```

Según mis investigaciones, son casi equivalentes:

``` {.c}
double complex x = 5 + 2*I;
double complex x = CMPLX(5, 2);
```

Pero la macro `CMPLX()` tratará siempre correctamente los ceros negativos en la parte imaginaria, mientras que la otra forma podría convertirlos en ceros positivos. Yo _pienso_^[Esto ha sido más difícil de investigar, y aceptaré cualquier información adicional que alguien pueda darme. que `I` podría definirse como `_Complex_I` o `_Imaginary_I`, si este último existe. `_Imaginary_I` manejará ceros con signo, pero `_Complex_I` _puede_ que no. Esto tiene implicaciones con los cortes de rama y otras cosas de números complejos. Tal vez. ¿Te das cuenta de que me estoy saliendo de mi elemento? En cualquier caso, las macros `CMPLX()` se comportan como si `I` estuviera definido como `_Imaginary_I`, con ceros con signo, aunque `_Imaginary_I` no exista en el sistema]. Esto parece implicar que si existe la posibilidad de que la parte imaginaria sea cero, debería usar la macro... ¡pero que alguien me corrija si me equivoco!

La macro `CMPLX()` funciona con tipos `doble`. Hay otras dos macros para `float` y `long double`:  [i[`CMPLXF()` macro]] `CMPLXF()` y [i[`CMPLXL()` macro]] `CMPLXL()`. (Estos sufijos "f" y "l" aparecen en prácticamente todas las funciones relacionadas con los números complejos).

[i[`CMPLX()` macro]>]

Ahora intentemos lo contrario: si tenemos un número complejo, ¿cómo lo descomponemos en sus partes real e imaginaria?

[i[`creal()` function]<]
[i[`cimag()` function]<]

Aquí tenemos un par de funciones que extraerán las partes real e imaginaria del número: `creal()` y `cimag()`:

``` {.c}
double complex x = 5 + 2*I;
double complex y = 10 + 3*I;

printf("x = %f + %fi\n", creal(x), cimag(x));
printf("y = %f + %fi\n", creal(y), cimag(y));
```

para la salida:

``` {.default}
x = 5.000000 + 2.000000i
y = 10.000000 + 3.000000i
```

Tenga en cuenta que la `i` que tengo en la cadena de formato `printf()` es una `i` literal que se imprime---no es parte del especificador de formato. Ambos valores devueltos por `creal()` y `cimag()` son `double`.

Y como siempre, hay variantes `float` y `long double` de estas funciones:[i[`crealf()` function]] `crealf()`, [i[`cimagf()` function]]
`cimagf()`, [i[`creall()` function]] `creall()`, and [i[`cimagl()`
function]] `cimagl()`.

[i[`creal()` function]>]
[i[`cimag()` function]>]

## Aritmética compleja y comparaciones

[i[Complex numbers-->arithmetic]<]

Es posible realizar operaciones aritméticas con números complejos, aunque su funcionamiento matemático queda fuera del alcance de esta guía.

``` {.c .numberLines}
#include <stdio.h>
#include <complex.h>

int main(void)
{
    double complex x = 1 + 2*I;
    double complex y = 3 + 4*I;
    double complex z;

    z = x + y;
    printf("x + y = %f + %fi\n", creal(z), cimag(z));

    z = x - y;
    printf("x - y = %f + %fi\n", creal(z), cimag(z));

    z = x * y;
    printf("x * y = %f + %fi\n", creal(z), cimag(z));

    z = x / y;
    printf("x / y = %f + %fi\n", creal(z), cimag(z));
}
```

por un resultado de:

``` {.default}
x + y = 4.000000 + 6.000000i
x - y = -2.000000 + -2.000000i
x * y = -5.000000 + 10.000000i
x / y = 0.440000 + 0.080000i
```

También puede comparar dos números complejos para la igualdad (o desigualdad):

``` {.c .numberLines}
#include <stdio.h>
#include <complex.h>

int main(void)
{
    double complex x = 1 + 2*I;
    double complex y = 3 + 4*I;

    printf("x == y = %d\n", x == y);  // 0
    printf("x != y = %d\n", x != y);  // 1
}
```

con la salida:

``` {.default}
x == y = 0
x != y = 1
```

Son iguales si ambos componentes prueban igual. Tenga en cuenta que, al igual que ocurre con todas las operaciones en coma flotante, podrían ser iguales si se aproximan lo suficiente debido a un error de redondeo^[La simplicidad de esta afirmación no hace justicia a la increíble cantidad de trabajo que supone simplemente entender cómo funciona realmente la coma flotante. https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/].

[i[Complex numbers-->arithmetic]>]

## Matemáticas complejas

Pero, ¡espera! Hay mucho más que simple aritmética compleja.

Aquí tienes una tabla resumen de todas las funciones matemáticas disponibles con números complejos.

Sólo voy a listar la versión `doble` de cada función, pero para todas ellas hay una versión `float` que puedes obtener añadiendo `f` al nombre de la función, y una versión `long double` que puedes obtener añadiendo `l`.

Por ejemplo, la función `cabs()` para calcular el valor absoluto de un número complejo también tiene variantes `cabsf()` y `cabsl()`. Las omito por brevedad.

### Funciones de trigonometría

[i[`ccos()` function]]
[i[`csin()` function]]
[i[`ctan()` function]]
[i[`cacos()` function]]
[i[`casin()` function]]
[i[`catan()` function]]
[i[`ccosh()` function]]
[i[`csinh()` function]]
[i[`ctanh()` function]]
[i[`cacosh()` function]]
[i[`casinh()` function]]
[i[`catanh()` function]]

|Function|Description|
|-|-|
|`ccos()`|Coseno|
|`csin()`|Seno|
|`ctan()`|Tangente|
|`cacos()`|Arco coseno|
|`casin()`|Arco seno|
|`catan()`|Jugar a _Settlers of Catan_|
|`ccosh()`|Coseno hiperbólico|
|`csinh()`|Hyperbolic sine|
|`ctanh()`|Tangente hiperbólica|
|`cacosh()`|Arco coseno hiperbólico|
|`casinh()`|Arco seno hiperbólico|
|`catanh()`|Arco hiperbólico tangente|

### Funciones exponenciales y logarítmicas

[i[`cexp()` function]]
[i[`clog()` function]]

|Función|Descripción|
|-|-|
|`cexp()`|Base-$e$ exponente|
|`clog()`|Logaritmo natural (base-$e$)|

### Funciones de potencia y valor absoluto

[i[`cabs()` function]]
[i[`cpow()` function]]
[i[`csqrt()` function]]

|Función|Descripción|
|-|-|
|`cabs()`|Valor absoluto|
|`cpow()`|Potencia|
|`csqrt()`|Raíz cuadrada|

### Funciones de manipulación

[i[`creal()` function]]
[i[`cimag()` function]]
[i[`CMPLX()` macro]]
[i[`carg()` function]]
[i[`conj()` function]]
[i[`cproj()` function]]

|Función|Descripción|
|-|-|
|`creal()`|Devolver parte real|
|`cimag()`|Devolver parte imaginaria|
|`CMPLX()`|Construir un número complejo|
|`carg()`|Argumento/ángulo de fase|
|`conj()`|Conjugar[^4a34]|
|`cproj()`|Proyección sobre la esfera de Riemann|

[^4a34]: Este es el único que no comienza con una "c" extra, extrañamente.

[i[Complex numbers]>]
