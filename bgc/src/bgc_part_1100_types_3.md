<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Tipos III: Conversiones

[i[Type conversions]<]

En este capítulo, queremos hablar de la conversión de un tipo a otro. C tiene una variedad
de formas de hacer esto, y algunas pueden ser un poco diferentes a las que estás acostumbrado
en otros lenguajes.

Antes de hablar de cómo hacer que las conversiones ocurran, hablemos de cómo funcionan
cuando _ocurren_.

## Conversiones de cadenas

[i[Type conversions-->strings]<]

A diferencia de muchos lenguajes, C no realiza las conversiones de cadena
a número (y viceversa) de una forma tan ágil como lo hace con las conversiones numéricas.

Para ello, tendremos que llamar a funciones que hagan el trabajo sucio.

### Valor numérico a cadena

Cuando queremos convertir un número en una cadena, podemos utilizar `sprintf()`
(se pronuncia _SPRINT-f_) o `snprintf()` (_s-n-print-f_)^[Son lo mismo, salvo que
`snprintf()` permite especificar un número máximo de bytes de salida, evitando
que se sobrepase el final de la cadena. Así que es más seguro].

Básicamente funcionan como `printf()`, excepto que dan salida a una cadena
en su lugar, y puedes imprimir esa cadena más tarde, o lo que sea.

Por ejemplo, convirtiendo parte del valor π en una cadena:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    char s[10];
    float f = 3.14159;

    // Convertir «f» en cadena, almacenando en «s», escribiendo como máximo 10 caracteres
    // incluido el terminador NUL

    snprintf(s, 10, "%f", f);

    printf("String value: %s\n", s);  // Valor de la cadena: 3.141590
}
```

Así que puedes usar `%d` o `%u` como estás acostumbrado para los enteros.

### Cadena a valor numérico

Hay un par de familias de funciones para hacer esto en C. Las llamaremos la familia
`atoi` (pronunciado _a-to-i_) y la familia `strtol` (_string-to-long_).

Para la conversión básica de una cadena a un número, pruebe las funciones `atoi` de
`<stdlib.h>`. Éstas tienen malas características de gestión de errores (incluyendo
un comportamiento indefinido si pasas una cadena incorrecta), así que úsalas con cuidado.

|Función|Descripción|
|:-|:-|
|`atoi`|Cadena a `int`|
|`atof`|Cadena a `float`|
|`atol`|Cadena a `long int`|
|`atoll`|Cadena a `long long int`|

Aunque la especificación no lo menciona, la `a` al principio de la función significa
[flw[ASCII|ASCII]], así que en realidad `atoi()` es «ASCII a entero» (Ascii To Integer, pero decirlo hoy en día es un poco ASCII-céntrico.

He aquí un ejemplo de conversión de una cadena a un `float`:

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    char *pi = "3.14159";
    float f;

    f = atof(pi);

    printf("%f\n", f);
}
```

Pero, como he dicho, obtenemos un comportamiento indefinido de cosas raras como esta:

``` {.c}
int x = atoi("what");  // «Qué» no es un número que haya oído nunca
```

(Cuando ejecuto eso, obtengo `0` de vuelta, pero realmente no deberías contar
con eso de ninguna manera. Podrías obtener algo completamente diferente).

Para obtener mejores características de manejo de errores, echemos un vistazo
a todas esas funciones `strtol`, también en `<stdlib.h>`. No sólo eso, ¡también
convierten a más tipos y más bases!

|Función|Descripción|
|:-|:-|
|`strtol`|Cadena a `long int`|
|`strtoll`|Cadena a `long long int`|
|`strtoul`|Cadena a `unsigned long int`|
|`strtoull`|Cadena a `unsigned long long int`|
|`strtof`|Cadena a `float`|
|`strtod`|Cadena a `double`|
|`strtold`|Cadena a `long double`|

Todas estas funciones siguen un patrón de uso similar y constituyen la primera experiencia
de mucha gente con punteros a punteros. Pero no te preocupes, es más fácil de lo que parece.

Hagamos un ejemplo en el que convertimos una cadena a un `unsigned long`, descartando
la información de error (es decir, la información sobre caracteres erróneos en la cadena
de entrada):

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    char *s = "3490";

    // Convierte la cadena s, a un número en base 10, a un unsigned long int.
    // NULL significa que no nos interesa conocer ninguna información de error.

    unsigned long int x = strtoul(s, NULL, 10);

    printf("%lu\n", x);  // 3490
}
```

Fíjate en un par de cosas. Aunque no nos dignamos a capturar ninguna información
sobre caracteres de error en la cadena, `strtoul()` no nos dará un comportamiento
indefinido; simplemente devolverá `0`.

Además, especificamos que se trataba de un número decimal (base 10).

¿Significa esto que podemos convertir números de bases diferentes? Por supuesto.
¡Hagámoslo en binario!

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    char *s = "101010";  // ¿Qué significa este número?

    // Convierte la cadena s, un número en base 2, a un unsigned long int.

    unsigned long int x = strtoul(s, NULL, 2);

    printf("%lu\n", x);  // 42
}
```

Vale, eso es muy divertido, pero ¿qué es eso de «NULL»? ¿Para qué sirve?

Nos ayuda a averiguar si se ha producido un error al procesar la cadena. Es un puntero
a un puntero a un `char`, que suena espeluznante, pero no lo es una vez que te haces a la idea.

Hagamos un ejemplo en el que introducimos un número deliberadamente malo, y veremos
cómo `strtol()` nos permite saber dónde está el primer dígito inválido.

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    char *s = "34x90";  // ¡«x» no es un dígito válido en base 10!
    char *badchar;

    // Convierte la cadena s, un número en base 10, a un unsigned long int.

    unsigned long int x = strtoul(s, &badchar, 10);

    // Intenta convertir tanto como sea posible, así que llega hasta aquí:

    printf("%lu\n", x);  // 34

    // Pero podemos ver el carácter malo porque badchar
    // lo señala.

    printf("Carácter no válido: %c\n", *badchar);  // "x"
}
```

Así que tenemos a `strtoul()` modificando lo que `badchar` señala para mostrarnos dónde
han ido mal las cosas^[Tenemos que pasar un puntero a `badchar` a `strtoul()` o no será
capaz de modificarlo de ninguna manera que podamos ver, de forma análoga a por qué tienes
que pasar un puntero a un `int` a una función si quieres que esa función sea capaz
de cambiar el valor de ese `int`].

Pero, ¿y si no pasa nada? En ese caso, `badchar` apuntará al terminador `NUL` al final
de la cadena. Así que podemos comprobarlo:

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    char *s = "3490";  // ¡«x» no es un dígito válido en base 10!
    char *badchar;

    // Convierte la cadena s, un número en base 10, a un unsigned long int.

    unsigned long int x = strtoul(s, &badchar, 10);

    // Comprueba si todo ha ido bien

    if (*badchar == '\0') {
        printf("Éxito! %lu\n", x);
    } else  {
        printf("Conversión parcial: %lu\n", x);
        printf("Carácter no válido: %c\n", *badchar);
    }
}
```

Ahí lo tienes. Las funciones estilo `atoi()` son buenas en un apuro controlado, pero
las funciones estilo `strtol()` le dan mucho más control sobre el manejo de errores y la
base de la entrada.

[i[Type conversions-->strings]>]

## Conversiones `char`

[i[Type conversions-->`char`]<]

¿Qué pasa si tienes un solo carácter con un dígito, como `'5'`? ¿Es lo mismo que el valor «5»?

Probemos a ver.

``` {.c}
printf("%d %d\n", 5, '5');
```

En mi sistema UTF-8, esto se imprime:

``` {.default}
5 53
```

Así que... no. ¿Y 53? ¿Qué es eso? Es el punto de código UTF-8 (y ASCII) para el símbolo
de carácter `'5'`^[Cada carácter tiene un valor asociado para cualquier esquema
de codificación de caracteres].

Entonces, ¿cómo convertimos el carácter `'5'` (que aparentemente tiene valor 53) en el valor
`5`?

Con un ingenioso truco, ¡así es cómo!

El estándar C garantiza que estos caracteres tendrán puntos de código que están
en secuencia y en este orden:

``` {.default}
0  1  2  3  4  5  6  7  8  9
```

Reflexiona un segundo... ¿cómo podemos utilizar eso? Spoilers por delante...

Echemos un vistazo a los caracteres y sus puntos de código en UTF-8:

``` {.default}
0  1  2  3  4  5  6  7  8  9
48 49 50 51 52 53 54 55 56 57
```

Ahí ves que `'5'` es `53`, tal como nos salía. Y «0» es «48».

Así que podemos restar «0» de cualquier dígito para obtener su valor numérico:

``` {.c}
char c = '6';

int x = c;  // x tiene el valor 54, el punto de código para '6'

int y = c - '0'; // y tiene valor 6, tal como queremos
```

Y también podemos convertir en el otro sentido, simplemente añadiendo el valor.

``` {.c}
int x = 6;

char c = x + '0';  // c tiene valor 54

printf("%d\n", c);  // Imprime 54
printf("%c\n", c);  // imprime 6 con %c
```

Puede que pienses que es una forma rara de hacer esta conversión, y para los estándares
de hoy en día, ciertamente lo es. Pero en los viejos tiempos, cuando los ordenadores
se hacían literalmente de madera, éste era el método para hacer esta conversión.
Y no estaba roto, así que C nunca lo arregló.

[i[Type conversions-->`char`]>]

## Conversiones numéricas

[i[Type conversions-->numeric]<]

### Booleano

[i[Type conversions-->Boolean]]

Si convierte un cero en `bool`, el resultado es `0`. En caso contrario es `1`.

### Conversión de números enteros en números enteros

[i[Type conversions-->integer]<]

Si un tipo entero se convierte a sin signo y no cabe en él, el resultado sin signo
se envuelve al estilo cuentakilómetros hasta que quepa en el sin signo^[En la práctica, lo
que probablemente está ocurriendo en tu implementación es que los bits de orden alto
simplemente se eliminan del resultado, de modo que un número de 16 bits `0x1234` que
se convierte a un número de 8 bits termina como `0x0034`, o simplemente `0x34`].

Si un tipo entero se convierte a un número con signo y no cabe, ¡el resultado está definido
por la implementación! Ocurrirá algo documentado, pero tendrás que buscarlo^[De nuevo, en
la práctica, lo que probablemente ocurrirá en tu sistema es que el patrón de bits para
el original se truncará y luego sólo se usará para representar el número con signo,
complemento a dos. Por ejemplo, mi sistema toma un `unsigned char` de `192` y lo convierte
a `signed char` `-64`. En complemento a dos, el patrón de bits para ambos números
es binario `11000000`.]

### Conversiones de enteros y coma flotante

[i[Type conversions-->floating point]<]

Si un tipo de coma flotante se convierte a un tipo entero, la parte fraccionaria
se descarta con prejuicio^[En realidad no---simplemente se descarta con regularidad].

Pero--y aquí está el truco---si el número es demasiado grande para caber en el entero,
se obtiene un comportamiento indefinido. Así que no lo hagas.

Pasando de entero o punto flotante a punto flotante, C hace el mejor esfuerzo
para encontrar el número de punto flotante más cercano al entero que pueda.

De nuevo, sin embargo, si el valor original no puede ser representado, es un
comportamiento indefinido.

[i[Type conversions-->floating point]>]
[i[Type conversions-->integer]>]

## Conversiones implícitas

[i[Type conversions-->implicit]<]

Se trata de conversiones que el compilador realiza automáticamente cuando
se mezclan y combinan tipos.

### Promociones de enteros {#integer-promotions}

En varios sitios, si un `int` puede usarse para representar un valor de `chart` o `short`
(con o sin signo), ese valor es _promovido_ a `int`. Si no cabe en un `int`, se promociona
a `unsigned int`.

Así es como podemos hacer algo como esto:

``` {.c}
char x = 10, y = 20;
int i = x + y;
```

En ese caso, `x` e `y` son promovidos a `int` por C antes de que se realice
la operación matemática.

Las promociones a enteros tienen lugar durante las conversiones aritméticas habituales,
con funciones variádicas^[Funciones con un número variable de argumentos.], operadores
unarios `+` y `-`, o al pasar valores a funciones sin prototipos^[Esto se hace raramente
porque el compilador se quejará y tener un prototipo es lo _Correcto_ de hacer. Creo que
esto todavía funciona por razones históricas, antes de que los prototipos fueran una cosa].

### Las conversiones aritméticas habituales {#usual-arithmetic-conversions}

Se trata de conversiones automáticas que C realiza en torno a las operaciones numéricas
que se le solicitan. (por cierto, así es como se llaman, en C11 §6.3.1.8.) Tenga en cuenta
que en esta sección sólo hablaremos de tipos numéricos; las cadenas vendrán más adelante.

Estas conversiones responden a preguntas sobre lo que ocurre cuando se mezclan
tipos, como en este caso:

``` {.c}
int x = 3 + 1.2; // Mezcla int y double
                   // 4.2 se convierte en int
                   // 4 se almacena en x

float y = 12 * 2; // Mezcla de float e int
                   // 24 se convierte a float
                   // 24.0 se almacena en y
```

¿Se convierten en `int`s? ¿Se convierten en `float`s? ¿Cómo funciona?

He aquí los pasos, parafraseados para facilitar su comprensión.

1. Si una cosa en la expresión es de tipo flotante, convierte las otras cosas
a ese tipo flotante.

2. De lo contrario, si ambos tipos son enteros, realice las promociones de enteros
en cada uno, luego haga los tipos de operandos tan grandes como sea necesario para
mantener el valor más grande común. A veces esto implica cambiar con signo a sin signo.

Si quiere conocer los detalles, consulte C11 §6.3.1.8. Pero probablemente no lo necesites.

En general, recuerde que los tipos int se convierten en tipos float si hay un tipo
de coma flotante en cualquier lugar, y el compilador hace un esfuerzo para asegurarse
de que los tipos enteros mixtos no se desborden.

Finalmente, si conviertes de un tipo de coma flotante a otro, el compilador intentará
hacer una conversión exacta. Si no puede, hará la mejor aproximación posible. Si el número
es demasiado grande para caber en el tipo al que se está convirtiendo, _boom_:
¡comportamiento indefinido!

### `void*`

El tipo `void*` es interesante porque puede convertirse desde o hacia cualquier
tipo de puntero.

``` {.c}
int x = 10;

void *p = &x; // &x es de tipo int*, pero lo almacenamos en un void*

int *q = p; // p es void*, pero lo almacenamos en un int*
```

[i[Type conversions-->implicit]>]

## Conversiones explícitas

[i[Type conversions-->explicit]<]

Se trata de conversiones de tipo a tipo que debes solicitar; el compilador no lo hará por ti.

Puedes convertir de un tipo a otro asignando un tipo a otro con un `=`.

También puedes convertir explícitamente con un _cast_.

[i[Type conversions-->numeric]>]

### Casting

[i[Type conversions-->casting]<]

Puedes cambiar explícitamente el tipo de una expresión poniendo un nuevo tipo entre
paréntesis delante de ella. Algunos desarrolladores de C fruncen el ceño ante esta práctica
a menos que sea absolutamente necesario, pero es probable que te encuentres con algún
código C que contenga estos paréntesis.

Hagamos un ejemplo en el que queremos convertir un `int` en un `long` para poder
almacenarlo en un `long`.

Nota: este ejemplo es artificial y la conversión en este caso es completamente
innecesaria porque la expresión `x + 12` se cambiaría automáticamente a `long int` para
coincidir con el tipo más amplio de `y`.

``` {.c}
int x = 10;
long int y = (long int)x + 12;
```

En ese ejemplo, aunque `x` era antes de tipo `int`, la expresión `(long int)x` es
de tipo `long int`. Decimos: «Castamos `x` a `long int`».

Más comúnmente, se puede ver una conversión para convertir un `void*` a un tipo
de puntero específico para que pueda ser dereferenciado.

Una llamada de retorno de la función incorporada `qsort()` puede mostrar
este comportamiento ya que tiene `void*`s pasados a ella:

``` {.c}
int compar(const void *elem1, const void *elem2)
{
    if (*((const int*)elem2) > *((const int*)elem1)) return 1;
    if (*((const int*)elem2) < *((const int*)elem1)) return -1;
    return 0;
}
```

Pero también podría escribirlo claramente con un encargo:

``` {.c}
int compar(const void *elem1, const void *elem2)
{
    const int *e1 = elem1;
    const int *e2 = elem2;

    return *e2 - *e1;
}
```

Uno de los lugares en los que verás más comúnmente las conversiones es para evitar
una advertencia al imprimir valores de puntero con el raramente usado `%p` que se
pone quisquilloso con cualquier cosa que no sea un `void*`:

``` {.c}
int x = 3490;
int *p = &x;

printf("%p\n", p);
```

genera esta advertencia:

``` {.default}
warning: format ‘%p’ expects argument of type ‘void *’, but argument
         2 has type ‘int *’
```

Puedes arreglarlo con una escayola:

``` {.c}
printf("%p\n", (void *)p);
```

Otro lugar es con cambios explícitos de puntero, si no quieres usar un `void*`
intermedio, pero estos también son bastante infrecuentes:

``` {.c}
long x = 3490;
long *p = &x;
unsigned char *c = (unsigned char *)p;
```

Un tercer lugar donde suele ser necesario es con las funciones de conversión de caracteres en
[fl[`<ctype.h>`|https://beej.us/guide/bgclr/html/split/ctype.html]]
donde debe convertir los valores con signo dudoso a `unsigned char` para
evitar comportamientos indefinidos.

Una vez más, en la práctica rara vez se _necesita_ el reparto. Si te encuentras
casteando, puede que haya otra forma de hacer lo mismo, o puede que estés
casteando innecesariamente.

O puede que sea necesario. Personalmente, intento evitarlo, pero no tengo miedo
de utilizarlo si es necesario.
[i[Type conversions-->explicit]>]
[i[Type conversions-->casting]>]
[i[Type conversions]>]
