<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# El preprocesador C

[i[Preprocessor]<]

Antes de que el programa se compile, pasa por una fase llamada _preprocesamiento_.
Es casi como si hubiera un lenguaje _sobre_ el lenguaje C que se ejecuta primero.
Y genera el código C, que luego se compila.

¡Ya hemos visto esto hasta cierto punto con `#include`! Ese es el preprocesador C.
Cuando ve esa directiva, incluye el fichero nombrado allí mismo, como
si lo hubieras escrito allí. Y _entonces_ el compilador lo construye todo.

Pero resulta que es mucho más potente que simplemente poder incluir cosas.
Puedes definir _macros_ que son sustituidas... ¡e incluso macros que toman argumentos!


## `#include`

[i[`#include` directive]<]

Empecemos por la que ya hemos visto muchas veces. Se trata, por supuesto, de
una forma de incluir otras fuentes en tu fuente. Muy comúnmente usado con archivos
de cabecera.

Mientras que la especificación permite todo tipo de comportamientos con `#include`,
vamos a tomar un enfoque más pragmático y hablar de la forma en que funciona
en todos los sistemas que he visto.

Podemos dividir los ficheros de cabecera en dos categorías: sistema y local.
Las cosas que están integradas, como `stdio.h`, `stdlib.h`, `math.h`, etc.,
se pueden incluir con corchetes angulares:


``` {.c}
#include <stdio.h>
#include <stdlib.h>
```

Los corchetes angulares le dicen a C: «Oye, no busques este archivo de cabecera
en el directorio actual, sino en el directorio de inclusión de todo el sistema».

[i[`#include` directive-->local files]<]

Lo que, por supuesto, implica que debe haber una forma de incluir archivos
locales del directorio actual. Y la hay: con comillas dobles:

``` {.c}
#include "myheader.h"
```

O muy probablemente puede buscar en directorios relativos usando barras
inclinadas y puntos, así:

``` {.c}
#include "mydir/myheader.h"
#include "../someheader.py"
```

¡No use una barra invertida (`\`) para sus separadores de ruta en su `#include`!
Es un comportamiento indefinido. Utilice sólo la barra oblicua (`/`),
incluso en Windows.

En resumen, usa corchetes angulares (`<` y `>`) para los includes del sistema,
y usa comillas dobles (`"`) para tus includes personales.

[i[`#include` directive-->local files]>]
[i[`#include` directive]>]

## Macros sencillas

[i[Preprocessor-->macros]<]

Un _macro_ es un identificador que se _expande_ a otro trozo de código antes
de que el compilador lo vea. Piense en ello como un marcador de posición - cuando
el preprocesador ve uno de esos identificadores, lo sustituye por otro valor
que ha definido.

[i[`#define` directive]<]

Lo hacemos con `#define` (a menudo se lee «pound define»). He aquí un ejemplo:

``` {.c .numberLines}
#include <stdio.h>

#define HELLO "Hello, world"
#define PI 3.14159

int main(void)
{
    printf("%s, %f\n", HELLO, PI);
}
```

En las líneas 3 y 4 definimos un par de macros. Dondequiera que aparezcan
en el código (línea 8), serán sustituidas por los valores definidos.

Desde la perspectiva del compilador de C, es exactamente como si hubiéramos
escrito esto, en su lugar:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    printf("%s, %f\n", "Hello, world", 3.14159);
}
```

¿Ve cómo `HELLO` ha sido sustituido por `«Hola, mundo»` y `PI` por `3,14159`?
Desde la perspectiva del compilador, es como si esos valores hubieran "aparecido"
en el código.

Tenga en cuenta que las macros no tienen un tipo específico, _per se_.
Realmente todo lo que ocurre es que son reemplazadas al por mayor por lo que sea
que estén `#definidas`. Si el código C resultante no es válido, el compilador
vomitará.

También puedes definir una macro sin valor:

``` {.c}
#define EXTRA_HAPPY
```

en ese caso, la macro existe y está definida, pero está definida para no ser nada.
Así que en cualquier lugar que aparezca en el texto será reemplazada por nada.
Veremos un uso para esto más adelante.

Es convencional escribir los nombres de las macros en `ALL_CAPS` aunque
técnicamente no sea necesario.

[i[`#define` directive-->versus `const`]<]

En general, esto le da una manera de definir valores constantes que son efectivamente
globales y se pueden utilizar en cualquier lugar. Incluso en aquellos lugares
donde una variable `const` no funcionaría, por ejemplo en `switch` `case`s y
longitudes de array fijas.

Dicho esto, se debate en la red si una variable `const` tipada es mejor
que la macro `#define` en el caso general.

También puede usarse para reemplazar o modificar palabras clave, un concepto
completamente ajeno a `const`, aunque esta práctica debería usarse con moderación.

[i[`#define` directive-->versus `const`]>]
[i[`#define` directive]>]
[i[Preprocessor-->macros]>]

## Compilación condicional

[i[Conditional compilation]<]

Es posible hacer que el preprocesador decida si presentar o no ciertos bloques
de código al compilador, o simplemente eliminarlos por completo antes
de la compilación.

Para ello, básicamente envolvemos el código en bloques condicionales, similares
a las sentencias `if`-`else`.

### Si está definido, `#ifdef` y `#endif`.

En primer lugar, vamos a intentar compilar código específico dependiendo
de si una macro está o no definida.

[i[`#ifdef` directive]<]
[i[`#endif` directive]<]

``` {.c .numberLines}
#include <stdio.h>

#define EXTRA_HAPPY

int main(void)
{

#ifdef EXTRA_HAPPY
    printf("I'm extra happy!\n");
#endif

    printf("OK!\n");
}
```

En ese ejemplo, definimos `EXTRA_HAPPY` (para que no sea nada, pero _está_ definido),
luego en la línea 8 comprobamos si está definido con una directiva `#ifdef`.
Si está definida, el código subsiguiente se incluirá hasta el `#endif`.

[i[`#ifdef` directive]>]
[i[`#endif` directive]>]

Por lo tanto, al estar definido, el código se incluirá para la compilación
y la salida será:

``` {.default}
I'm extra happy!
OK!
```

Si comentáramos el `#define`, así:

``` {.c}
//#define EXTRA_HAPPY
```

entonces no se definiría, y el código no se incluiría en la compilación.
Y la salida sería simplemente:

``` {.default}
OK!
```

Es importante recordar que estas decisiones se toman en tiempo de compilación.
El código se compila o elimina dependiendo de la condición. Esto contrasta
con una sentencia `if` estándar que se evalúa mientras el programa se está ejecutando.

### Si no está definido, `#ifndef`.

También existe el sentido negativo de «si se define»: «si no está definido»,
o `#ifndef`. Podríamos cambiar el ejemplo anterior para que salieran
cosas diferentes en función de si algo estaba definido o no:

[i[`#ifndef` directive]<]
[i[`#endif` directive]<]

``` {.c .numberLines startFrom="8"}
#ifdef EXTRA_HAPPY
    printf("I'm extra happy!\n");
#endif

#ifndef EXTRA_HAPPY
    printf("I'm just regular\n");
#endif
```

Veremos una forma más limpia de hacerlo en la siguiente sección.

Volviendo a los archivos de cabecera, hemos visto cómo podemos hacer
que los archivos de cabecera sólo se incluyan una vez envolviéndolos
en directivas de preprocesador como esta:

``` {.c}
#ifndef MYHEADER_H  // Primera línea de myheader.h
#define MYHEADER_H

int x = 12;

#endif  // Última línea de myheader.h
```

[i[`#ifndef` directive]>]
[i[`#endif` directive]>]

Esto demuestra cómo una macro persiste a través de archivos y múltiples
`#include`s. Si aún no está definida, definámosla y compilemos todo
el fichero de cabecera.

Pero la próxima vez que se incluya, vemos que `MYHEADER_H` _está_ definida,
así que no enviamos el fichero de cabecera al compilador--- se elimina efectivamente.

### `#else`

[i[`#else` directive]<]

Pero eso no es todo lo que podemos hacer. También podemos añadir un `#else.

[i[`#ifdef` directive]<]
[i[`#endif` directive]<]

Modifiquemos el ejemplo anterior:

``` {.c .numberLines startFrom="8"}
#ifdef EXTRA_HAPPY
    printf("I'm extra happy!\n");
#else
    printf("I'm just regular\n");
#endif
```

[i[`#ifdef` directive]>]
[i[`#else` directive]>]
[i[`#endif` directive]>]

Ahora, si `EXTRA_HAPPY` no está definido, entrará en la cláusula `#else` e imprimirá:

``` {.default}
I'm just regular
```

### Else-If: `#elifdef`, `#elifndef`

[i[`#elifdef` directive]<]
[i[`#elifndef` directive]<]

Esta función es nueva en C23.

¿Y si quiere algo más complejo? ¿Quizás necesitas una estructura
en cascada if-else para que tu código se construya correctamente?

Por suerte tenemos estas directivas a nuestra disposición. Podemos usar
`#elifdef` para «definir else if»:

``` {.c}
#ifdef MODE_1
    printf("This is mode 1\n");
#elifdef MODE_2
    printf("This is mode 2\n");
#elifdef MODE_3
    printf("This is mode 3\n");
#else
    printf("This is some other mode\n");
#endif
```

[i[`#elifdef` directive]>]

Por otro lado, puede utilizar `#elifndef` para «else if not defined».

[i[`#elifndef` directive]>]

### Condicional general: `#if`, `#elif`

[i[`#if` directive]<]
[i[`#elif` directive]<]

Funciona de forma muy parecida a las directivas `#ifdef` y `#ifndef` en el sentido
de que también puede tener un `#else` y todo termina con `#endif`.

La única diferencia es que la expresión constante después de `#if` debe
evaluarse a verdadero (distinto de cero) para que el código en `#if` sea
compilado. Así que en lugar de si algo está definido o no, queremos
una expresión que se evalúe como verdadera.

``` {.c .numberLines}
#include <stdio.h>

#define HAPPY_FACTOR 1

int main(void)
{

#if HAPPY_FACTOR == 0
    printf("I'm not happy!\n");
#elif HAPPY_FACTOR == 1
    printf("I'm just regular\n");
#else
    printf("I'm extra happy!\n");
#endif

    printf("OK!\n");
}
```

[i[`#elif` directive]>]

De nuevo, para las cláusulas `#if` no emparejadas, el compilador ni siquiera
verá esas líneas. Para el código anterior, después de que el preprocesador
haya terminado con él, todo lo que el compilador ve es:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{

    printf("I'm just regular\n");

    printf("OK!\n");
}
```

Un truco que se utiliza es comentar un gran número de líneas rápidamente
^[No siempre se puede envolver el código con comentarios `/*` `*/` porque no se anidan].

[i[`#if 0` directive]<]

Si pones un `#if 0` («si false») al principio del bloque a comentar
y un `#endif` al final, puedes conseguir este efecto:

``` {.c}
#if 0
    printf(«Todo este código»); /* está efectivamente */
    printf(«comentado»); // por el #if 0
#endif
```

[i[`#if 0` directive]>]

¿Qué pasa si estás en un compilador pre-C23 y no tienes soporte para las
directivas `#elifdef` o `#elifndef`? ¿Cómo podemos conseguir el mismo
efecto con `#if`? Es decir, qué pasaría si quisiera esto

``` {.c}
#ifdef FOO
    x = 2;
#elifdef BAR  // ERROR POTENCIAL: No soportado antes de C23
    x = 3;
#endif
```

¿Cómo podría hacerlo?

Resulta que hay un operador de preprocesador llamado `defined` que podemos
usar con una sentencia `#if`.

Son equivalentes:

[i[`#if defined` directive]<]
``` {.c}
#ifdef FOO
#if defined FOO
#if defined(FOO)   // Paréntesis opcional
```

Como estos:

``` {.c}
#ifndef FOO
#if !defined FOO
#if !defined(FOO)   // Paréntesis opcional
```

Observe que podemos utilizar el operador lógico estándar NOT (`!`) para «no definido».

¡Así que ahora estamos de vuelta en la tierra de `#if` y podemos
usar `#elif` impunemente!

Este código roto:

``` {.c}
#ifdef FOO
    x = 2;
#elifdef BAR  // ERROR POTENCIAL: No soportado antes de C23
    x = 3;
#endif
```

puede sustituirse por:

``` {.c}
#if defined FOO
    x = 2;
#elif defined BAR
    x = 3;
#endif
```

[i[`#if defined` directive]>]
[i[`#if` directive]>]
[i[Conditional compilation]>]

### Perder una macro: `#undef`

[i[`#undef` directive]<]

Si has definido algo pero ya no lo necesitas, puedes redefinirlo con `#undef`.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
#define GOATS

#ifdef GOATS
    printf("Goats detected!\n");  // Imprime
#endif

#undef GOATS  // Hacer que GOATS ya no esté definido

#ifdef GOATS
    printf("Goats detected, again!\n"); // no imprime
#endif
}
```

[i[`#undef` directive]>]

## Macros integradas

[i[Preprocessor-->predefined macros]<]

El estándar define un montón de macros incorporadas que puedes probar y utilizar
para la compilación condicional. Veámoslas aquí.


### Macros obligatorias

Todos ellos están definidos:

[i[`__DATE__` macro]<]
[i[`__TIME__` macro]<]
[i[`__FILE__` macro]<]
[i[`__LINE__` macro]<]
[i[`__func__` identifier]<]
[i[`__STDC_VERSION__` macro]<]

[i[`__STDC__` macro]]
[i[`__STDC_HOSTED__` macro]]

|Macro|Descripción|
|-----------|----------------------------------------------------|
|`__DATE__`|La fecha de compilación --como cuando está compilando este archivo-- en formato `Mmm dd yyyy`|
|`__TIME__`|La hora de compilación en formato `hh:mm:ss`.|
|`__FILE__`|Una cadena que contiene el nombre de este archivo|
|`__LINE__`|El número de línea del archivo en el que aparece esta macro|
|`__func__`|El nombre de la función en la que aparece, como una cadena^[Esto no es realmente una macro---es técnicamente un identificador. Pero es el único identificador predefinido y se parece mucho a una macro, así que lo incluyo aquí. Como un rebelde].|
|`__STDC__`|Definido con `1` si se trata de un compilador C estándar|
|`__STDC_HOSTED__`|Será `1` si el compilador es una _implementación hospedada_^[Una implementación hospedada significa básicamente que estás ejecutando el estándar C completo, probablemente en un sistema operativo de algún tipo. Lo cual es probable. Si se está ejecutando en un sistema embebido, probablemente se trate de una implementación _standalone_], en caso contrario `0`.|
|`__STDC_VERSION__`|Esta versión de C, una constante `long int` de la forma `yyyymmL`, por ejemplo `201710L`.|

Pongámoslos juntos.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    printf("Esta función: %s\n", __func__);
    printf("Este archivo %s\n", __FILE__);
    printf("Esta linea: %d\n", __LINE__);
    printf("Compilado en: %s %s\n", __DATE__, __TIME__);
    printf("Versión de C: %ld\n", __STDC_VERSION__);
}
```

[i[`__DATE__` macro]>]
[i[`__TIME__` macro]>]

La salida en mi sistema es:

``` {.default}
Esta función: main
Este archivo: foo.c
Esta linea: 7
Compilado en: Nov 23 2020 17:16:27
Versión de C : 201710
```

`__FILE__`, `__func__` y `__LINE__` son particularmente útiles para informar
de condiciones de error en mensajes a los desarrolladores. La macro `assert()` de
`<assert.h>` las utiliza para indicar en qué parte del código ha fallado la aserción.

[i[`__FILE__` macro]>]
[i[`__LINE__` macro]>]
[i[`__func__` identifier]>]

#### `__STDC_VERSION__`s

[i[Language versions]<]

Por si te lo estás preguntando, aquí tienes los números de versión
de las distintas versiones principales de la especificación del lenguaje C:

|Release|ISO/IEC version|`__STDC_VERSION__`|
|-|-|-|
|C89|ISO/IEC 9899:1990|undefined|
|**C89**|ISO/IEC 9899:1990/Amd.1:1995|`199409L`|
|**C99**|ISO/IEC 9899:1999|`199901L`|
|**C11**|ISO/IEC 9899:2011/Amd.1:2012|`201112L`|

Tenga en cuenta que la macro no existía originalmente en C89.

También ten en cuenta que la idea es que los números de versión aumenten de manera estricta, así que siempre podrías verificar, por ejemplo, 'al menos C99' con:

``` {.c}
#if __STDC_VERSION__ >= 1999901L
```

[i[Language versions]>]
[i[`__STDC_VERSION__` macro]>]

### Macros opcionales

Es posible que su aplicación también los defina. O puede que no.

[i[`__STDC_ISO_10646__` macro]]
[i[`__STDC_MB_MIGHT_NEQ_WC__` macro]]
[i[`__STDC_UTF_16__` macro]]
[i[`__STDC_UTF_32__` macro]]
[i[`__STDC_ANALYZABLE__` macro]]
[i[`__STDC_IEC_559__` macro]]
[i[`__STDC_IEC_559_COMPLEX__` macro]]
[i[`__STDC_LIB_EXT1__` macro]]
[i[`__STDC_NO_ATOMICS__` macro]]
[i[`__STDC_NO_COMPLEX__` macro]]
[i[`__STDC_NO_THREADS__` macro]]
[i[`__STDC_NO_VLA__` macro]]

|Macro|Descripción|
|----------------|--------------------------------------------------|
|`__STDC_ISO_10646__`|Si está definido, `wchar_t` contiene valores Unicode, si no, otra cosa|
|`__STDC_MB_MIGHT_NEQ_WC__`|Un "1" indica que los valores en caracteres multibyte pueden no corresponderse con los valores en caracteres anchos.|
|`__STDC_UTF_16__`|Un `1` indica que el sistema utiliza la codificación UTF-16 en el tipo `char16_t`.|
|`__STDC_UTF_32__`|A `1` indicates that the system uses UTF-32 encoding in type `char32_t`|
|`__STDC_ANALYZABLE__`|Un `1` indica que el código es analizable^[OK, sé que era una respuesta evasiva. Básicamente hay una extensión opcional que los compiladores pueden implementar en la que se comprometen a limitar ciertos tipos de comportamiento indefinido para que el código C sea más susceptible de análisis estático. Es poco probable que necesites usar esto].|
|`__STDC_IEC_559__`|`1` if IEEE-754 (aka IEC 60559) floating point is supported|
|`__STDC_IEC_559_COMPLEX__`|`1` si se admite la coma flotante compleja IEC 60559|
|`__STDC_LIB_EXT1__`|`1` si esta implementación admite una serie de funciones de
biblioteca estándar alternativas "seguras" (tienen sufijos `_s` en el nombre)|
|`__STDC_NO_ATOMICS__`|`1` si esta implementación **no** soporta `_Atomic ` o `<stdatomic.h>`.|
|`__STDC_NO_COMPLEX__`|`1` si esta implementación **no** soporta tipos complejos o `<complex.h>`.|
|`__STDC_NO_THREADS__`|`1` si esta implementación **no** es compatible con `<threads.h>`.|
|`__STDC_NO_VLA__`|`1` si esta implementación **no** admite matrices de longitud variable|

[i[Preprocessor-->predefined macros]>]

## Macros con argumentos

[i[Preprocessor-->macros with arguments]<]

Sin embargo, las macros son más potentes que una simple sustitución. También
puede configurarlas para que acepten argumentos que sean sustituidos.

A menudo surge la pregunta de cuándo utilizar macros parametrizadas frente
a funciones. Respuesta corta: usa funciones. Pero verás muchas macros en
la naturaleza y en la biblioteca estándar. La gente tiende a usarlas para
cosas cortas y matemáticas, y también para características que pueden cambiar
de plataforma a plataforma. Puedes definir diferentes palabras clave para
una plataforma u otra.

### Macros con un argumento

Empecemos con uno sencillo que eleva un número al cuadrado:

[i[`#define` directive]<]

``` {.c .numberLines}
#include <stdio.h>

#define SQR(x) x * x  // No es del todo correcto, pero ten paciencia conmigo

int main(void)
{
    printf("%d\n", SQR(12));  // 144
}
```

Lo que está diciendo es "dondequiera que veas `SQR` con algún valor,
reemplázalo con ese valor multiplicado por sí mismo".

Así que la línea 7 se cambiará a:

``` {.c .numberLines startFrom="7"}
    printf("%d\n", 12 * 12);  // 144
```

que C convierte cómodamente en 144.

Pero en esa macro hemos cometido un error elemental que debemos evitar.

Vamos a comprobarlo. ¿Y si quisiéramos calcular `SQR(3 + 4)`? Bueno, $3+4=7$,
así que debemos querer calcular $7^2=49$. Eso es; `49`---respuesta final.

Pongámoslo en nuestro código y veremos que obtenemos... 19?

``` {.c .numberLines startFrom="7"}
    printf("%d\n", SQR(3 + 4));  // 19!!??
```

¿Qué ha pasado?

Si seguimos la macro expansión, obtenemos 

``` {.c .numberLines startFrom="7"}
    printf("%d\n", 3 + 4 * 3 + 4);  // 19!
```

¡Uy! Como la multiplicación tiene prioridad, hacemos primero $4+3=12$ y
obtenemos $3+12+4=19$. No es lo que buscábamos.

Así que tenemos que arreglar esto para hacerlo bien.

**Esto es tan común que deberías hacerlo automáticamente cada vez que hagas
una macro matemática parametrizada.**

La solución es fácil: ¡sólo tienes que añadir algunos paréntesis!

``` {.c .numberLines startFrom="3"}
#define SQR(x) (x) * (x)   // Mejor... ¡pero aún no lo suficiente!
```

Y ahora nuestra macro se expande a:

``` {.c .numberLines startFrom="7"}
    printf("%d\n", (3 + 4) * (3 + 4));  // 49! Woo hoo!
```

Pero en realidad seguimos teniendo el mismo problema que podría manifestarse
si tenemos cerca un operador de mayor precedencia que multiplicar (`*`).

Así que la forma segura y adecuada de armar la macro es envolver todo
entre paréntesis adicionales, así:

``` {.c .numberLines startFrom="3"}
#define SQR(x) ((x) * (x))   // Perfecto!
```

Acostúmbrate a hacerlo cuando hagas una macro matemática y no te equivocarás.

### Macros con más de un argumento

Puedes apilar estas cosas tanto como quieras:

``` {.c}
#define TRIANGLE_AREA(w, h) (0.5 * (w) * (h))
```

Vamos a hacer unas macros que resuelven para $x$ usando la fórmula cuadrática.
Por si acaso no la tienes en la cabeza, dice que para ecuaciones de la forma:

$ax^2+bx+c=0$

puedes resolver $x$ con la fórmula cuadrática:

$x=\displaystyle\frac{-b\pm\sqrt{b^2-4ac}}{2a}$

Lo cual es una locura. También observe el más-o-menos ($\pm$) allí, lo que indica que en realidad hay dos soluciones.

Así que vamos a hacer macros para ambos:

``` {.c}
#define QUADP(a, b, c) ((-(b) + sqrt((b) * (b) - 4 * (a) * (c))) / (2 * (a)))
#define QUADM(a, b, c) ((-(b) - sqrt((b) * (b) - 4 * (a) * (c))) / (2 * (a)))
```

Así que eso nos da algunas matemáticas. Pero vamos a definir una más que podemos
utilizar como argumentos a `printf()` para imprimir ambas respuestas.

``` {.c}
//          macro           se reemplaza por
//      |-----------| |----------------------------|
#define QUAD(a, b, c) QUADP(a, b, c), QUADM(a, b, c)
```

Eso es sólo un par de valores separados por una coma - y podemos usar
eso como un argumento "combinado" de clases a `printf()` como esto:

``` {.c}
printf("x = %f or x = %f\n", QUAD(2, 10, 5));
```

Pongámoslo junto en algún código:

``` {.c .numberLines}
#include <stdio.h>
#include <math.h>  // Para sqrt()

#define QUADP(a, b, c) ((-(b) + sqrt((b) * (b) - 4 * (a) * (c))) / (2 * (a)))
#define QUADM(a, b, c) ((-(b) - sqrt((b) * (b) - 4 * (a) * (c))) / (2 * (a)))
#define QUAD(a, b, c) QUADP(a, b, c), QUADM(a, b, c)

int main(void)
{
    printf("2*x^2 + 10*x + 5 = 0\n");
    printf("x = %f or x = %f\n", QUAD(2, 10, 5));
}
```

Y esto nos da la salida:

``` {.default}
2*x^2 + 10*x + 5 = 0
x = -0.563508 or x = -4.436492
```

Si introducimos cualquiera de estos valores, obtendremos aproximadamente
cero (un poco desviado porque los números no son exactos):

$2\times-0.563508^2+10\times-0.563508+5\approx0.000003$

### Macros con argumentos variables

[i[Preprocessor-->macros with variable arguments]<]

También hay una forma de pasar un número variable de argumentos a una macro,
utilizando elipses (`...`) después de los argumentos conocidos con nombre.
Cuando se expande la macro, todos los argumentos extra estarán en una lista
separada por comas en la macro `__VA_ARGS__`, y pueden ser reemplazados desde allí:

``` {.c .numberLines}
#include <stdio.h>

// Combinar los dos primeros argumentos a un solo número,
// luego tener un commalist del resto de ellos:
#define X(a, b, ...) (10*(a) + 20*(b)), __VA_ARGS__

int main(void)
{
    printf("%d %f %s %d\n", X(5, 4, 3.14, "Hi!", 12));
}
```

La sustitución que tiene lugar en la línea 10 sería:

``` {.c .numberLines startFrom="10"}
    printf("%d %f %s %d\n", (10*(5) + 20*(4)), 3.14, "Hi!", 12);
```

para la salida:

``` {.default}
130 3.140000 Hi! 12
```

También se puede "stringificar" `__VA_ARGS__` anteponiéndole un `#`:

``` {.c}
#define X(...) #__VA_ARGS__

printf("%s\n", X(1,2,3));  // Imprime "1, 2, 3"
```

[i[`#define` directive]>]
[i[Preprocessor-->macros with variable arguments]>]
[i[Preprocessor-->macros with arguments]>]

### Stringificación

[i[`#` stringification]<]

Ya se ha mencionado, justo arriba, que puede convertir cualquier argumento
en una cadena precediéndolo de un `#` en el texto de sustitución.

Por ejemplo, podríamos imprimir cualquier cosa como una cadena con esta macro y `printf()`:

``` {.c}
#define STR(x) #x

printf("%s\n", STR(3.14159));
```

En ese caso, la sustitución conduce a:

``` {.c}
printf("%s\n", "3.14159");
```

Veamos si podemos usar esto con mayor efecto para que podamos pasar cualquier
nombre de variable `int` a una macro, y hacer que imprima su nombre y valor.

``` {.c .numberLines}
#include <stdio.h>

#define PRINT_INT_VAL(x) printf("%s = %d\n", #x, x)

int main(void)
{
    int a = 5;

    PRINT_INT_VAL(a);  // Imprime "a = 5"
}
```

En la línea 9, obtenemos la siguiente macro de sustitución:

``` {.c .numberLines startFrom="9"}
    printf("%s = %d\n", "a", 5);
```

[i[`#` stringification]>]

### Concatenación

[i[`##` concatenation]<]

También podemos concatenar dos argumentos con `##`. ¡Qué divertido!

``` {.c}
#define CAT(a, b) a ## b

printf("%f\n", CAT(3.14, 1592));   // 3.141592
```

[i[`##` concatenation]>]

## Macros multilínea

[i[Preprocessor-->multiline macros]<]

Es posible continuar una macro en varias líneas si se escapa la nueva línea
con una barra invertida (`\`).

Escribamos una macro multilínea que imprima números desde `0` hasta el producto
de los dos argumentos pasados.

[i[`do`-`while` statement-->in multiline macros]<]

``` {.c .numberLines}
#include <stdio.h>

#define PRINT_NUMS_TO_PRODUCT(a, b) do { \
    int product = (a) * (b); \
    for (int i = 0; i < product; i++) { \
        printf("%d\n", i); \
    } \
} while(0)

int main(void)
{
    PRINT_NUMS_TO_PRODUCT(2, 4);  // Salida de números del 0 al 7
}
```

Un par de cosas a tener en cuenta:

* Escapes al final de cada línea excepto la última para indicar que la macro continúa.
* Todo está envuelto en un bucle `do`-`while(0)` con llaves de ardilla.

El último punto puede ser un poco raro, pero se trata de absorber el `;` final
que el programador deja caer después de la macro.

Al principio pensé que bastaría con usar llaves de ardilla, pero hay un caso
en el que falla si el programador pone un punto y coma después de la macro. Este
es el caso:

``` {.c .numberLines}
#include <stdio.h>

#define FOO(x) { (x)++; }

int main(void)
{
    int i = 0;

    if (i == 0)
        FOO(i);
    else
        printf(":-(\n");

    printf("%d\n", i);
}
```

Parece bastante simple, pero no se construye sin un error de sintaxis:

``` {.default}
foo.c:11:5: error: ‘else’ without a previous ‘if’  
```

¿Lo ve?

Veamos la expansión:

``` {.c}

    if (i == 0) {
        (i)++;
    };             // <-- ¡Problema con MAYÚSCULAS!

    else
        printf(":-(\n");
```

El `;` pone fin a la sentencia `if`, así que el `else` queda flotando
por ahí ilegalmente^[_Quebrantando la ley... quebrantando la ley..._].

Así que envuelve esa macro multilínea con un `do`-`while(0)`.

[i[`do`-`while` statement-->in multiline macros]>]
[i[Preprocessor-->multiline macros]>]

## Ejemplo: Una macro Assert {#my-assert}

Añadir asserts a tu código es una buena forma de detectar condiciones que crees
que no deberían ocurrir. C proporciona la funcionalidad `assert()`. Comprueba
una condición, y si es falsa, el programa explota diciéndote el fichero y el número
de línea en el que falló la aserción.

Pero esto es insuficiente.

1. En primer lugar, no puedes especificar un mensaje adicional con la aserción.

2. En segundo lugar, no hay un interruptor fácil de encendido y apagado para todas
las aserciones.

Podemos abordar el primero con macros.

Básicamente, cuando tengo este código:

``` {.c}
ASSERT(x < 20, "x debe tener menos de 20 años");
```

Quiero que ocurra algo como esto (asumiendo que `ASSERT()` está en la línea 220
de `foo.c`):

``` {.c}
if (!(x < 20)) {
    fprintf(stderr, "foo.c:220: assertion x < 20 failed: ");
    fprintf(stderr, "x debe tener menos de 20 años\n");
    exit(1);
}
```

Podemos obtener el nombre del fichero de la macro `__FILE__`, y el número de línea
de `__LINE__`. El mensaje ya es una cadena, pero `x < 20` no lo es, así que tendremos
que encadenarla con `#`. Podemos hacer una macro multilínea utilizando barras
invertidas al final de la línea.

``` {.c}
#define ASSERT(c, m) \
do { \
    if (!(c)) { \
        fprintf(stderr, __FILE__ ":%d: assertion %s failed: %s\n", \
                        __LINE__, #c, m); \
        exit(1); \
    } \
} while(0)
```

(Parece un poco raro con `__FILE__` así delante, pero recuerda que es una cadena
literal, y las cadenas literales una al lado de la otra se concatenan
automáticamente. En cambio, `__LINE__` es sólo un `int`).

¡Y funciona! Si ejecuto esto

``` {.c}
int x = 30;

ASSERT(x < 20, "x debe tener menos de 20 años");
```

Obtengo este resultado:

```
foo.c:23: assertion x < 20 failed: x must be under 20
```

¡Muy bonito!

Lo único que falta es una forma de activarlo y desactivarlo, y podríamos hacerlo
con compilación condicional.

Aquí está el ejemplo completo:

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

#define ASSERT_ENABLED 1

#if ASSERT_ENABLED
#define ASSERT(c, m) \
do { \
    if (!(c)) { \
        fprintf(stderr, __FILE__ ":%d: assertion %s failed: %s\n", \
                        __LINE__, #c, m); \
        exit(1); \
    } \
} while(0)
#else
#define ASSERT(c, m)  // Macro vacía si no está activada
#endif

int main(void)
{
    int x = 30;

    ASSERT(x < 20, "x debe tener menos de 20 años");
}
```

Esto tiene la salida:

``` {.default}
foo.c:23: assertion x < 20 failed: x must be under 20
```

## Directiva `#error` 

[i[`#error` directive]<]

Esta directiva hace que el compilador se equivoque en cuanto la vea.

Normalmente, se utiliza dentro de una condicional para evitar la compilación
a menos que se cumplan algunos requisitos previos:

``` {.c}
#ifndef __STDC_IEC_559__
    #error I really need IEEE-754 floating point to compile. Sorry!
#endif
```

[i[`#error` directive]>]
[i[`#warning` directive]<]

Algunos compiladores tienen una directiva complementaria no estándar `#warning`
que mostrará una advertencia pero no detendrá la compilación, pero esto no está
en la especificación C11.

[i[`#warning` directive]>]

## Directiva `#embed`

[i[`#embed` directive]<]

<!-- Godbolt demo: https://godbolt.org/z/Kb3ejE7q5 -->

¡Nuevo en C23!

Y actualmente todavía no funciona con ninguno de mis compiladores, ¡así que tómate
esta sección con un grano de sal!

La esencia de esto es que puedes incluir bytes de un fichero como constantes
enteras como si los hubieras tecleado.

Por ejemplo, si tienes un archivo binario llamado `foo.bin` que contiene cuatro
bytes con valores decimales 11, 22, 33, y 44, y haces esto:

``` {.c}
int a[] = {
#embed "foo.bin"
};
```

Será como si lo hubieras escrito tú:

``` {.c}
int a[] = {11,22,33,44};
```

Se trata de una forma muy eficaz de inicializar una matriz con datos binarios
sin necesidad de convertirlos primero en código: ¡el preprocesador lo hace por ti!

Un caso de uso más típico podría ser un archivo que contenga una pequeña imagen
para mostrar y que no quieras cargar en tiempo de ejecución.

He aquí otro ejemplo:

``` {.c}
int a[] = {
#embed <foo.bin>
};
```

Si utiliza corchetes angulares, el preprocesador busca en una serie de lugares
definidos por la implementación para localizar el archivo, igual que haría
`#include`. Si utiliza comillas dobles y el recurso no se encuentra, el compilador
lo intentará como si hubiera utilizado paréntesis angulares en un último intento
desesperado por encontrar el archivo.

`#embed` funciona como `#include` en el sentido de que pega los valores antes
de que el compilador los vea. Esto significa que puedes usarlo en todo tipo
de lugares:

```
return
#embed "somevalue.dat"
;
```

o

```
int x =
#embed "xvalue.dat"
;
```

¿Son siempre bytes? ¿Significa que tendrán valores de 0 a 255, ambos inclusive?
La respuesta es definitivamente por defecto "sí", excepto cuando es "no".

Técnicamente, los elementos serán `CHAR_BIT` bits de ancho. Y es muy probable que
sean 8 en tu sistema, por lo que obtendrías ese rango de 0 a 255 en tus valores.
(Siempre serán no negativos).

Además, es posible que una implementación permita que esto se anule de alguna
manera, por ejemplo, en la línea de comandos o con parámetros.

El tamaño del fichero en bits debe ser múltiplo del tamaño del elemento. Es decir,
si cada elemento tiene 8 bits, el tamaño del fichero (en bits) debe ser múltiplo
de 8. En el uso cotidiano, esta es una forma confusa de decir que cada fichero debe
tener un número entero de bytes... que por supuesto lo es. Honestamente, ni siquiera
estoy seguro de por qué me molesté con este párrafo. Lee la especificación si
realmente tienes curiosidad.

### Parámetro `#embed` 

Hay todo tipo de parámetros que puedes especificar a la directiva `#embed`. He aquí
un ejemplo con el parámetro aún no introducido `limit()`:

``` {.c}
int a[] = {
#embed "/dev/random" limit(5)
};
```

Pero, ¿y si ya tienes definido `limit` en otro lugar? Afortunadamente puedes
poner `__` alrededor de la palabra clave y funcionará de la misma manera:

``` {.c}
int a[] = {
#embed "/dev/random" __limit__(5)
};
```

Ahora... ¿qué es eso de "límite"?

### Parámetro `limit()` 

Puede especificar un límite en el número de elementos a incrustar con este parámetro.

Se trata de un valor máximo, no de un valor absoluto. Si el fichero que se incrusta
es más corto que el límite especificado, sólo se importarán esa cantidad de bytes.

El ejemplo `/dev/random` de arriba es un ejemplo de la motivación para esto---en
Unix, eso es un _archivo de dispositivo de caracteres_ que devolverá un flujo
infinito de números bastante aleatorios.

Incrustar un número infinito de bytes es duro para tu RAM, así que el parámetro
`limit` te da una forma de parar después de un cierto número.

Finalmente, puedes usar macros `#define` en tu `limit`, por si tienes curiosidad.

### Parámetro `if_empty`

[i[`if_empty()` embed parameter]<]

Este parámetro define cuál debe ser el resultado de la incrustación si el fichero
existe pero no contiene datos. Supongamos que el fichero `foo.dat` contiene
un único byte con el valor 123. Si hacemos esto

``` {.c}
int x = 
#embed "foo.dat" if_empty(999)
;
```

lo conseguiremos:

``` {.c}
int x = 123;   // Cuando foo.dat contiene un byte 123
```

Pero, ¿y si el archivo `foo.dat` tiene cero bytes (es decir, no contiene datos
y está vacío)? En ese caso, se expandiría a:

``` {.c}
int x = 999;   // Cuando foo.dat está vacío
```

En particular, si el `limit` se establece en `0`, entonces el `if_empty` siempre
será sustituido. Es decir, un límite cero significa que el fichero está vacío.

Esto siempre emitirá `x = 999` sin importar lo que haya en `foo.dat`:

``` {.c}
int x = 
#embed "foo.dat" limit(0) if_empty(999)
;
```

[i[`if_empty()` embed parameter]>]

### Parámetros `prefix()` y `suffix()`.

[i[`prefix()` embed parameter]<]
[i[`suffix()` embed parameter]<]

Esta es una manera de anteponer algunos datos en el embed.

Tenga en cuenta que esto sólo afecta a los datos que no están vacíos. Si el fichero
está vacío, ni `prefix` ni `suffix` tienen efecto.

Aquí hay un ejemplo en el que incrustamos tres números aleatorios, pero les
ponemos como prefijo `11,` y como sufijo `,99`:

``` {.c}
int x[] = {
#embed "/dev/urandom" limit(3) prefix(11,) suffix(,99)
};
```

Ejemplo de resultado:

``` {.c}
int x[] = {11,135,116,220,99};
```

No es obligatorio utilizar tanto `prefix` como `suffix`. Puedes usar ambos, uno,
el otro, o ninguno.

Podemos hacer uso de la característica de que estos sólo se aplican a los archivos
no vacíos para un efecto limpio, como se muestra en el siguiente ejemplo
descaradamente robado de la especificación.

Supongamos que tenemos un archivo `foo.dat` que contiene algunos datos. Y queremos
usar esto para inicializar un array, y entonces queremos un sufijo en el array
que sea un elemento cero.

No hay problema, ¿verdad?

``` {.c}
int x[] = {
#embed "foo.dat" suffix(,0)
};
```

Si `foo.dat` tiene 11, 22 y 33, obtendríamos:

``` {.c}
int x[] = {11,22,33,0};
```

Pero, ¡espera! ¿Y si `foo.dat` está vacío? Entonces obtenemos:

``` {.c}
int x[] = {};
```

y eso no es bueno.

Pero podemos arreglarlo así:

``` {.c}
int x[] = {
#embed "foo.dat" suffix(,)
    0
};
```

Dado que el parámetro `suffix` se omite si el archivo está vacío, esto se convertiría
simplemente en:

``` {.c}
int x[] = {0};
```

lo cual está bien.

[i[`prefix()` embed parameter]>]
[i[`suffix()` embed parameter]>]

### El identificador `__has_embed()`.

[i[`__has_embed()` identifier]<]

Esta es una gran manera de comprobar si un archivo en particular está disponible
para ser incrustado, y también si está vacío o no.

Se usa con la directiva `#if`.

Aquí hay un trozo de código que obtendrá 5 números aleatorios del dispositivo
de caracteres generador de números aleatorios. Si no existen, intenta obtenerlos
de un fichero `myrandoms.dat`. Si no existe, utiliza algunos valores codificados:

``` {.c}
    int random_nums[] = {
#if __has_embed("/dev/urandom")
    #embed "/dev/urandom" limit(5)
#elif __has_embed("myrandoms.dat")
    #embed "myrandoms.dat" limit(5)
#else
    140,178,92,167,120
#endif
    };
```

Técnicamente, el identificador `__has_embed()` resuelve a uno de tres valores:

|`__has_embed()` Result|Descripción|
|-|-|
|`__STDC_EMBED_NOT_FOUND__`|Si no se encuentra el archivo.|
|`__STDC_EMBED_FOUND__`|Si se encuentra el archivo y no está vacío.|
|`__STDC_EMBED_EMPTY`|Si se encuentra el archivo y está vacío.|

Tengo buenas razones para creer que `__STDC_EMBED_NOT_FOUND__` es `0` y los otros
no son cero (porque está implícito en la propuesta y tiene sentido lógico), pero
tengo problemas para encontrarlo en esta versión del borrador de la especificación.

[i[`__has_embed()` identifier]>]

TODO

### Otros parámetros

La implementación de un compilador puede definir otros parámetros incrustados todo
lo que quiera---busque estos parámetros no estándar en la documentación de su
compilador.

Por ejemplo:

``` {.c}
#embed "foo.bin" limit(12) frotz(lamp)
```

Normalmente llevan un prefijo para facilitar el espaciado entre nombres:

``` {.c}
#embed "foo.bin" limit(12) fmc::frotz(lamp)
```

Puede ser sensato intentar detectar si están disponibles antes de usarlos, y por
suerte podemos usar `__has_embed` para ayudarnos aquí.

Normalmente, `__has_embed()` nos dirá si el fichero está ahí o no. Pero, y aquí
viene lo divertido, ¡también devolverá false si algún parámetro adicional
no está soportado!

Así que si le damos un fichero que _sabemos_ que existe y un parámetro cuya
existencia queremos comprobar, nos dirá efectivamente si ese parámetro está soportado.

Pero, ¿qué fichero existe _siempre_? Resulta que podemos usar la macro `__FILE__`,
que se expande al nombre del fichero fuente que lo referencia. Ese fichero _debe_
existir, o algo va muy mal en el departamento del huevo y la gallina.

Probemos el parámetro `frotz` para ver si podemos usarlo:

``` {.c}
#if __has_embed(__FILE__ fmc::frotz(lamp))
    puts("fmc::frotz(lamp) is supported!");
#else
    puts("fmc::frotz(lamp) is NOT supported!");
#endif
```

### Incrustación de valores multibyte

¿Qué tal si en lugar de bytes individuales se introducen `int`s? ¿Qué pasa con
los valores multibyte en el archivo incrustado?

El estándar C23 no lo admite, pero en el futuro podrían definirse extensiones
de implementación para ello.

[i[`#embed` directive]>]

## La directiva `#pragma`{#pragma}

[i[`#pragma` directive]<]

Se trata de una directiva peculiar, abreviatura de "pragmática". Puedes usarla
para hacer... bueno, cualquier cosa que tu compilador te permita hacer con ella.

Básicamente la única vez que vas a añadir esto a tu código es si alguna
documentación te dice que lo hagas.

### Pragmas no estándar

[i[`#pragma` directive-->nonstandard pragmas]<]

He aquí un ejemplo no estándar de uso de `#pragma` para hacer que el compilador
ejecute un bucle `for` en paralelo con múltiples hilos (si el compilador soporta
la extensión [fl[OpenMP|https://www.openmp.org/]]):

``` {.c}
#pragma omp parallel for
for (int i = 0; i < 10; i++) { ... }
```

Hay todo tipo de directivas `#pragma` documentadas en las cuatro esquinas del globo.

Todos los `#pragma`s no reconocidos son ignorados por el compilador.

[i[`#pragma` directive-->nonstandard pragmas]>]

### Pragmas estándar

También hay algunas estándar, que empiezan por `STDC` y siguen la misma forma:

``` {.c}
#pragma STDC pragma_name on-off
```

La parte `on-off` puede ser `ON`, `OFF`, o `DEFAULT`.

Y el `pragma_name` puede ser uno de estos:

[i[`FP_CONTRACT` pragma]<]
[i[`CX_LIMITED_RANGE` pragma]<]

[i[`FENV_ACCESS` pragma]]

|Nombre del pragma|Descripción|
|-------------|--------------------------------------------------|
|`FP_CONTRACT`|Permitir que las expresiones en coma flotante se contraigan en una sola operación para evitar los errores de redondeo que podrían producirse por múltiples operaciones.|
|`FENV_ACCESS`|Póngalo a `ON` si planea acceder a las banderas de estado de coma flotante. Si está `OFF`, el compilador puede realizar optimizaciones que causen que los valores de las banderas sean inconsistentes o inválidos.|
|`CX_LIMITED_RANGE`|Establezca a `ON` para permitir que el compilador omita las comprobaciones de desbordamiento al realizar aritmética compleja. Por defecto es `OFF`.|

Por ejemplo:

``` {.c}
#pragma STDC FP_CONTRACT OFF
#pragma STDC CX_LIMITED_RANGE ON
```

[i[`FP_CONTRACT` pragma]>]

En cuanto a `CX_LIMITED_RANGE`, la especificación señala:

> El propósito del pragma es permitir a la implementación utilizar las
> fórmulas:
>
> $(x+iy)\times(u+iv) = (xu-yv)+i(yu+xv)$
>
> $(x+iy)/(u+iv) = [(xu+yv)+i(yu-xv)]/(u^2+v^2)$
>
> $|x+iy|=\sqrt{x^2+y^2}$
>
> donde el programador puede determinar que son seguros.

[i[`CX_LIMITED_RANGE` pragma]>]

### Operador `_Pragma` 

[i[`_Pragma` operator]<]

Esta es otra forma de declarar un pragma que podría utilizar en una macro.

Son equivalentes:

``` {.c}
#pragma "Unnecessary" quotes
_Pragma("\"Unnecessary\" quotes")
```

[i[`_Pragma` operator-->in a macro]<]

Esto se puede utilizar en una macro, si es necesario:

``` {.c}
#define PRAGMA(x) _Pragma(#x)
```

[i[`_Pragma` operator-->in a macro]>]
[i[`_Pragma` operator]>]
[i[`#pragma` directive]>]

## La directiva `#line`

[i[`#line` directive]<]
[i[`__LINE__` macro]<]

Esto le permite anular los valores de `__LINE__` y `__FILE__`. Si lo desea.

Nunca he querido hacer esto, pero en K&R2, escriben:

> Para el beneficio de otros preprocesadores que generan programas C [...]

Así que tal vez haya eso.

Para anular el número de línea a, digamos 300:

``` {.c}
#line 300
```

y `__LINE__` seguirá contando a partir de ahí.

[i[macro `__LINE__`]>]

Para anular el número de línea y el nombre de fichero:

``` {.c}
#line 300 "newfilename"
```

[i[`#line` directive]>]

## La Directiva Nula (`#`)

[i[`#` null directive]<]

Un `#` en una línea por sí mismo es ignorado por el preprocesador. Ahora, para
ser totalmente honesto, no sé cuál es el caso de uso para esto.

He visto ejemplos como este:

``` {.c}
#ifdef FOO
    #
#else
    printf("Something");
#endif
```

que es sólo cosmético; la línea con el solitario `#` puede ser eliminado sin
ningún efecto nocivo.

O tal vez por coherencia cosmética, así:

``` {.c}
#
#ifdef FOO
    x = 2;
#endif
#
#if BAR == 17
    x = 12;
#endif
#
```

Pero, con respecto a la cosmética, eso es simplemente feo.

Otro post menciona la eliminación de comentarios---que en GCC, un comentario después
de un `#` no será visto por el compilador. No lo dudo, pero la especificación
no parece decir que este sea el comportamiento estándar.

Mis búsquedas de fundamentos no están dando muchos frutos. Así que voy a decir
que esto es algo de esoterismo de C.

[i[`#` null directive]>]
[i[Preprocessor]>]
