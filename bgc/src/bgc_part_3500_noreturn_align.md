<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Especificadores de Función, Especificadores/Operadores de Alineación

En mi experiencia, estos no se utilizan mucho, pero los cubriremos aquí en aras de la exhaustividad.

## Especificadores de función

[i[Function specifiers]<]

Cuando declaras una función, puedes dar al compilador un par de consejos sobre cómo podrían o serán utilizadas las funciones. Esto permite o anima al compilador a realizar ciertas optimizaciones.

### `inline` para la Velocidad---tal vez

[i[`inline` function specifier]<]

Puede declarar una función para que sea inline de la siguiente manera:

``` {.c}
static inline int add(int x, int y) {
    return x + y;
}
```
Esto pretende animar al compilador a hacer esta llamada a la función lo más rápido posible. Y, históricamente, una forma de hacerlo era _inlining_, lo que significa que el cuerpo de la función se incrustaba en su totalidad donde se realizaba la llamada. Esto evitaría toda la sobrecarga de establecer la llamada a la función y desmontarla a expensas de un mayor tamaño del código, ya que la función se copiaba por todas partes en lugar de reutilizarse.


Las cosas rápidas y sucias que hay que recordar son:


1. Probablemente no necesites usar `inline` por velocidad. Los compiladores modernos saben qué es lo mejor.

2. Si lo usas por velocidad, úsalo con ámbito de archivo, es decir, `static inline`. Esto evita las desordenadas reglas de vinculación externa y funciones inline.

Deja de leer esta sección ahora.

Glotón para el castigo, ¿eh?

Vamos a tratar de dejar el `static` off.

``` {.c .numberLines}
#include <stdio.h>

inline int add(int x, int y)
{
    return x + y;
}

int main(void)
{
    printf("%d\n", add(1, 2));
}
```
`gcc` da un error de enlazador en `add()`^[¡A menos que compiles con las optimizaciones activadas (probablemente)! Pero creo que cuando hace esto, no se está comportando según la especificación]. La especificación requiere que si tienes una función en línea no `externa` también debes proporcionar una versión con enlace externo.

Así que tendrías que tener una versión `externa` en algún otro lugar para que esto funcione. Si el compilador tiene tanto una función `inline` en el fichero actual como una versión externa de la misma función en otro lugar, puede elegir a cuál llamar. Así que recomiendo encarecidamente que sean la misma.

Otra cosa que puedes hacer es declarar la función como `extern inline`. Esto intentará inline en el mismo archivo (por velocidad), pero también creará una versión con enlace externo.

[i[`inline` function specifier]>]

### `noreturn` y `_Noreturn` {#noreturn}

[i[`noreturn` function specifier]<]
[i[`_Noreturn` function specifier]<]

Esto indica al compilador que una función concreta no volverá nunca a su invocador, es decir, que el programa saldrá por algún mecanismo antes de que la función retorne.

Esto permite al compilador realizar algunas optimizaciones en torno a la llamada a la función.

También le permite indicar a otros desarrolladores que cierta lógica del programa depende de que una función _no_ regrese.

Es probable que nunca necesite usar esto, pero lo verá en algunas llamadas a bibliotecas como
[fl[`exit()`|https://beej.us/guide/bgclr/html/split/stdlib.html#man-exit]]
y
[fl[`abort()`|https://beej.us/guide/bgclr/html/split/stdlib.html#man-abort]].

La palabra clave incorporada es `_Noreturn`, pero si no rompe su código existente, todo el mundo recomendaría incluir `<stdnoreturn.h>` y usar la más fácil de leer `noreturn` en su lugar.

Es un comportamiento indefinido si una función especificada como `noreturn` realmente retorna. Es computacionalmente deshonesto.

Aquí hay un ejemplo de uso correcto de `noreturn`:

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>

noreturn void foo(void) // ¡Esta función nunca debe retornar!
{
    printf("Happy days\n");

    exit(1);            // Y no vuelve... ¡Sale por aquí!
}

int main(void)
{
    foo();
}
```

Si el compilador detecta que una función `noreturn` podría retornar, podría advertirte, de forma útil.

Sustituyendo la función `foo()` por esto:

``` {.c}
noreturn void foo(void)
{
    printf("Breakin' the law\n");
}
```

me da una advertencia:

``` {.default}
foo.c:7:1: warning: function declared 'noreturn' should not return
```

[i[`noreturn` function specifier]>]
[i[`_Noreturn` function specifier]>]
[i[Function specifiers]>]

## Especificadores y operadores de alineación

[i[Alignment]<]

[flw[_Alignment_|Data_structure_alignment]] se refiere a los múltiplos de direcciones en los que se pueden almacenar objetos. ¿Se puede almacenar en cualquier dirección? ¿O debe ser una dirección inicial divisible por 2? ¿O por 8? ¿O 16?

Si estás programando algo de bajo nivel, como un asignador de memoria que interactúa con tu sistema operativo, puede que tengas que tener esto en cuenta. La mayoría de los desarrolladores pasan sus carreras sin utilizar esta funcionalidad en C.

### `alignas` y `_Alignas`

[i[`alignas` alignment specifier]<]
[i[`_Alignas` alignment specifier]<]

No es una función. Más bien, es un _especificador de alineación_ que puedes usar con una declaración de variable.

El especificador incorporado es `_Alignas`, pero la cabecera `<stdalign.h>` lo define como `alignas` para que se vea mejor.

Si necesitas que tu `char` esté alineado como un `int`, puedes forzarlo así cuando lo declares:

``` {.c}
char alignas(int) c;
```

También puede pasar un valor constante o una expresión para la alineación. Esto tiene que ser algo soportado por el sistema, pero la especificación no llega a dictar qué valores se pueden poner ahí. Las potencias pequeñas de 2 (1, 2, 4, 8 y 16) suelen ser apuestas seguras.

``` {.c}
char alignas(8) c;   // alinear en límites de 8 bytes
```

Si quiere alinear al máximo alineamiento usado por su sistema, incluya `<stddef.h>` y use el tipo `max_align_t`, así:

``` {.c}
char alignas(max_align_t) c;
```

Usted podría potencialmente _sobre-alinear_ especificando una alineación mayor que la de `max_align_t`, pero si tales cosas están o no permitidas depende del sistema.

[i[`alignas` alignment specifier]>]
[i[`_Alignas` alignment specifier]>]

### `alignof` y `_Alignof`

[i[`alignof` operator]<]
[i[`_Alignof` operator]<]

Este operador devolverá el múltiplo de dirección que un tipo particular utiliza para la alineación en este sistema. Por ejemplo, puede que `char`s se alinee cada 1 dirección, y `int`s se alinee cada 4 direcciones.

El operador incorporado es `_Alignof`, pero la cabecera `<stdalign.h>` lo define como `alignof` si quieres parecer más guay.

Aquí hay un programa que imprimirá las alineaciones de una variedad de tipos diferentes. De nuevo, estos variarán de un sistema a otro. Tenga en cuenta que el tipo `max_align_t` le dará la alineación máxima utilizada por el sistema.

``` {.c .numberLines}
#include <stdalign.h>
#include <stdio.h>     // for printf()
#include <stddef.h>    // for max_align_t

struct t {
    int a;
    char b;
    float c;
};

int main(void)
{
    printf("char       : %zu\n", alignof(char));
    printf("short      : %zu\n", alignof(short));
    printf("int        : %zu\n", alignof(int));
    printf("long       : %zu\n", alignof(long));
    printf("long long  : %zu\n", alignof(long long));
    printf("double     : %zu\n", alignof(double));
    printf("long double: %zu\n", alignof(long double));
    printf("struct t   : %zu\n", alignof(struct t));
    printf("max_align_t: %zu\n", alignof(max_align_t));
}
```

Salida en mi sistema:

``` {.default}
char       : 1
short      : 2
int        : 4
long       : 8
long long  : 8
double     : 8
long double: 16
struct t   : 16
max_align_t: 16
```

[i[`alignof` operator]>]
[i[`_Alignof` operator]>]

## Función `memalignment()` 

[i[`memalignment()` function]<]

¡Nuevo en C23!

(Advertencia: ninguno de mis compiladores soporta esta función todavía, así que el código está en gran parte sin probar).

`alignof` es genial si conoces el tipo de tus datos. ¿Pero qué pasa si _desconoce_ el tipo y sólo tiene un puntero a los datos?

¿Cómo podría ocurrir eso?

Bueno, con nuestro buen amigo el `void*`, por supuesto. No podemos pasarlo a `alignof`, pero ¿y si necesitamos saber la alineación de lo que apunta?

Podríamos querer saber esto si estamos a punto de usar la memoria para algo que tiene necesidades significativas de alineación. Por ejemplo, los tipos atómicos y flotantes a menudo se comportan mal si están mal alineados.

Así que con esta función podemos comprobar la alineación de algunos datos siempre que tengamos un puntero a esos datos, incluso si es un `void*`.

Hagamos una prueba rápida para ver si un puntero void está bien alineado para usarlo como tipo atómico, y, si es así, hagamos que una variable lo use como ese tipo:

``` {.c}
void foo(void *p)
{
    if (memalignment(p) >= alignof(atomic int)) {
        atomic int *i = p;
        do_things(i);
    } else
        puts("This pointer is no good as an atomic int\n");

...
```

Sospecho que rara vez (hasta el punto de nunca, probablemente) necesitará utilizar esta función a menos que esté haciendo algunas cosas de bajo nivel.

[i[`memalignment()` function]>]

Y ahí lo tienen. ¡Alineación!

[i[Alignment]>]
