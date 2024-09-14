<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Asignación manual de memoria

[i[Manual memory management]<]
Esta es una de las grandes áreas en las que C probablemente diverge de los lenguajes
que ya conoces: _gestión manual de memoria_.

Otros lenguajes usan el conteo de referencias, la recolección de basura u otros medios
para determinar cuándo asignar nueva memoria para algunos datos--y desasignarla
cuando ninguna variable hace referencia a ella.

Y eso está bien. Está bien poder despreocuparse de ello, simplemente, eliminar todas
las referencias a un elemento y confiar en que en algún momento se liberará la memoria
asociada a él.

Pero C no es así, del todo.

[i[Automatic variables]<]
Por supuesto, en C, algunas variables se asignan y se liberan automáticamente, cuando entran
y salen del ámbito. Llamamos a estas variables automáticas. Son las típicas variables
«locales» de ámbito de bloque. No hay problema.
[i[Automatic variables]>]

Pero, ¿y si quieres que algo persista más tiempo que un bloque concreto? Aquí es donde
entra en juego la gestión manual de la memoria.

Puedes decirle explícitamente a C que te asigne un número determinado de bytes que podrás
utilizar a tu antojo. Y estos bytes permanecerán asignados hasta que liberes *explícitamente*
esa memoria^[O hasta que el programa salga, en cuyo caso se liberará toda la memoria asignada
por él. Asterisco: algunos sistemas te permiten asignar memoria que persiste después
de que un programa salga, pero esto depende del sistema, está fuera del alcance
de esta guía, y seguramente nunca lo harás por accidente].

Es importante que liberes la memoria que hayas utilizado. Si no lo haces, lo llamamos
una _fuga de memoria_ y tu proceso continuará reservando esa memoria hasta que termine.

Si la asignaste manualmente, tienes que liberarla manualmente cuando termines de usarla.

¿Cómo lo hacemos? Vamos a aprender un par de nuevas funciones, y hacer uso
del operador `sizeof` para ayudarnos a saber cuántos bytes asignar.

[i[The stack]<]
[i[The heap]<]
En el lenguaje común de C, los desarrolladores dicen que las variables locales automáticas
se asignan «en la pila» y que la memoria asignada manualmente está «en el montón (heap)».
La especificación no habla de ninguna de estas cosas, pero todos los desarrolladores
de C, sabrán de qué estás hablando si las mencionas.
[i[The heap]>]
[i[The stack]>]

Todas las funciones que vamos a aprender en este capítulo se encuentran en
`<stdlib.h>`.

## Asignación y desasignación, `malloc()` y `free()`.

[i[`malloc()` function]<]
La función `malloc()` acepta un número de bytes para asignar, y devuelve un puntero
void a ese bloque de memoria recién asignado.

Como es un `void*`, puedes asignarlo al tipo de puntero que quieras... normalmente
se corresponderá de alguna manera con el número de bytes que estás asignando.

[i[`sizeof` operator-->with `malloc()`]<]
Entonces... ¿cuántos bytes debo asignar? Podemos usar `sizeof` para ayudarnos con eso.
Si queremos asignar espacio suficiente para un único `int`, podemos usar `sizeof(int)` y
pasárselo a `malloc()`.
[i[`sizeof` operator-->with `malloc()`]>]

[i[`free()` function]<]
Después de que hayamos terminado con alguna memoria asignada, podemos llamar a `free()` para
indicar que hemos terminado con esa memoria y que puede ser utilizada para otra cosa.
Como argumento, pasas el mismo puntero que obtuviste de `malloc()` (o una copia del mismo).
Es un comportamiento indefinido usar una región de memoria después de haberla liberado (`free()`).

Intentémoslo. Asignaremos suficiente memoria para un `int`, luego almacenaremos
algo allí, y lo imprimiremos.

``` {.c}
// Asignar espacio para un único int (sizeof(int) bytes-worth):

int *p = malloc(sizeof(int));

*p = 12;  // Almacenar algo allí

printf("%d\n", *p);  // Imprímelo: 12

free(p);  // Todo hecho con esa memoria

//*p = 3490;  // ERROR: ¡comportamiento indefinido! ¡Usar después de free()!
```
[i[`free()` function]>]

En ese ejemplo artificioso, realmente no hay ningún beneficio. Nosotros podríamos
haber usado un `int` automático y habría funcionado. Pero veremos cómo la capacidad de asignar
memoria de esta manera tiene sus ventajas, especialmente con estructuras de datos
más complejas.

[i[`sizeof` operator-->with `malloc()`]<]
Otra cosa que verás comúnmente aprovecha el hecho de que `sizeof` puede darte el tamaño
del tipo de resultado de cualquier expresión constante. Así que podrías poner un nombre
de variable ahí también, y usar eso. Aquí hay un ejemplo de eso, igual que el anterior:

``` {.c}
int *p = malloc(sizeof *p);  // *p es un int, igual que sizeof(int)
```
[i[`sizeof` operator-->with `malloc()`]>]
[i[`malloc()` function]>]

## Comprobación de errores

[i[`malloc()` function-->error checking]<]
Todas las funciones de asignación devuelven un puntero al nuevo tramo de memoria asignado,
o `NULL` si la memoria no puede ser asignada por alguna razón.

Algunos sistemas operativos como Linux pueden configurarse de forma que `malloc()` nunca
devuelva `NULL`, incluso si se ha quedado sin memoria. Pero a pesar de esto, siempre
debes codificarlo con protecciones en mente.

``` {.c}
int *x;

x = malloc(sizeof(int) * 10);

if (x == NULL) {
    printf("Error al asignar 10 ints\n");
    // Haga algo aquí para manejarlo
}
```

Este es un patrón común que verás, donde hacemos la asignación  y la condición
en la misma línea:

``` {.c}
int *x;

if ((x = malloc(sizeof(int) * 10)) == NULL)
    printf("Error al asignar 10 ints\n");
    // haga algo aquí para manejarlo
}
```
[i[`malloc()` function-->error checking]>]

## Asignación de espacio para una matriz

[i[`malloc()` function-->and arrays]<]
Ya hemos visto cómo asignar espacio a una sola cosa; ¿qué pasa ahora con un montón
de ellas en una matriz?

En C, un array es un montón de la misma cosa, en un tramo contiguo de memoria(espalda con espalda).

Podemos asignar un tramo contiguo de memoria, ya hemos visto cómo hacerlo. Si quisiéramos
3490 bytes de memoria, podríamos simplemente pedirlos:

``` {.c}
char *p = malloc(3490);  // Voila
```

Y, de hecho, es una matriz de 3490 `char`s (también conocida como cadena), ya que
cada `char` es 1 byte. En otras palabras, `sizeof(char)` es `1`.

Nota: no se ha hecho ninguna inicialización en la memoria recién asignada---está llena
de basura. Límpiela con `memset()` si quiere, o vea `calloc()`, más abajo.

Pero podemos simplemente multiplicar el tamaño de la cosa que queremos por el número
de elementos que queremos, y luego acceder a ellos usando la notación de puntero o de array.

Ejemplo

[i[`sizeof` operator-->with `malloc()`]<]
``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    // Asignar espacio para 10 ints
    int *p = malloc(sizeof(int) * 10);

    // Asígneles los valores 0-45:
    for (int i = 0; i < 10; i++)
        p[i] = i * 5;

    // Imprimir todos los valores 0, 5, 10, 15, ..., 40, 45
    for (int i = 0; i < 10; i++)
        printf("%d\n", p[i]);

    // Liberar el espacio
    free(p);
}
```

La clave está en la línea `malloc()`. Si sabemos que cada `int` necesita `sizeof(int)` bytes
para contenerlo, y sabemos que queremos 10 de ellos, podemos simplemente asignar exactamente
esa cantidad de bytes con:

``` {.c}
sizeof(int) * 10
```

Y este truco funciona para todos los tipos. Basta con pasarlo a `sizeof` y multiplicarlo
por el tamaño del array.
[i[`sizeof` operator-->with `malloc()`]>]
[i[`malloc()` function-->and arrays]>]

## Una alternativa: `calloc()`.

[i[`calloc()` function]<]
Esta es otra función de asignación que funciona de forma similar a `malloc()`, con dos
diferencias clave:

* En lugar de un único argumento, pasas el tamaño de un elemento, y el número de elementos que deseas asignar. Es como si estuviera hecho para asignar arrays.
* Borra la memoria a cero.

Todavía se usa `free()` para liberar la memoria obtenida mediante `calloc()`.

Aquí tienes una comparación entre `calloc()` y `malloc()`.

``` {.c}
// Asigna espacio para 10 ints con calloc(), inicializado a 0:
int *p = calloc(10, sizeof(int));

// Asigna espacio para 10 ints con malloc(), inicializado a 0:
int *q = malloc(10 * sizeof(int));
memset(q, 0, 10 * sizeof(int));   // Pone en 0
```

De nuevo, el resultado es el mismo para ambos excepto que `malloc()` no pone a cero
la memoria por defecto.
[i[`calloc()` function]>]

## Cambio del tamaño asignado con `realloc()`.

[i[`realloc()` function]<]
Si ya has asignado 10 `int`s, pero más tarde decides que necesitas 20, ¿qué puedes hacer?

Una opción es asignar nuevo espacio y luego `memcpy()` en la memoria... pero resulta que a
veces no necesitas mover nada. Y hay una función que es lo suficientemente inteligente
como para hacer lo correcto en todas las circunstancias: `realloc()`.

Toma un puntero a memoria previamente ocupada (por `malloc()` o `calloc()`) y un nuevo
tamaño para la región de memoria.

Entonces crece o decrece esa memoria, y devuelve un puntero a ella. A veces puede devolver
el mismo puntero (si los datos no han tenido que ser copiados en otro lugar), o puede devolver
uno diferente (si los datos han tenido que ser copiados).

Asegúrese de que cuando llama a `realloc()`, especifica el número de _bytes_ a asignar, ¡y no
sólo el número de elementos del array! Esto es:

``` {.c}
num_floats *= 2;

np = realloc(p, num_floats);  // INCORRECTO: ¡se necesitan bytes, no número de elementos!

np = realloc(p, num_floats * sizeof(float));  // ¡Mejor!
```

Vamos a asignar un array de 20 `float`s, y luego cambiamos de idea y lo convertimos
en un array de 40.

Vamos a asignar el valor de retorno de `realloc()` a otro puntero para asegurarnos
de que no es `NULL`. Si no lo es, podemos reasignarlo a nuestro puntero original.
(Si simplemente asignáramos el valor de retorno directamente al puntero original, perderíamos
ese puntero si la función devolviera `NULL` y no tendríamos forma de recuperarlo).

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    // Asignar espacio para 20 floats
    float *p = malloc(sizeof *p * 20);  // sizeof *p igual que sizeof(float)

    // Asígneles valores fraccionarios 0-1:
    for (int i = 0; i < 20; i++)
        p[i] = i / 20.0;

    // Pero, ¡espera! Hagamos de esto un array de 40 elementos
    float *new_p = realloc(p, sizeof *p * 40);

    // Comprueba si hemos reasignado correctamente
    if (new_p == NULL) {
        printf("Error reallocing\n");
        return 1;
    }

    // Si lo hiciéramos, podemos simplemente reasignar p
    p = new_p;

    // Y asigna a los nuevos elementos valores en el rango 1.0-2.0
    for (int i = 20; i < 40; i++)
        p[i] = 1.0 + (i - 20) / 20.0;

    // Imprime todos los valores 0-2 en los 40 elementos:
    for (int i = 0; i < 40; i++)
        printf("%f\n", p[i]);

    // Liberar el espacio
    free(p);
}
```

Fíjate en cómo tomamos el valor de retorno de `realloc()` y lo reasignamos a la misma
variable puntero `p` que pasamos. Esto es bastante común.

Además, si la línea 7 te parece rara, con ese `sizeof *p` ahí, recuerda que `sizeof` funciona
con el tamaño del tipo de la expresión. Y el tipo de `*p` es `float`, así que esa línea
es equivalente a `sizeof(float)`.
[i[`realloc()` function]>]


### Lectura de líneas de longitud arbitraria

Quiero demostrar dos cosas con este ejemplo completo.

1. El uso de `realloc()` para hacer crecer un buffer a medida que leemos más datos.
2. El Uso de `realloc()` para reducir el buffer al tamaño perfecto después de completar
la lectura.

Lo que vemos aquí es un bucle que llama a `fgetc()` una y otra vez para añadir a un buffer,
hasta que vemos que el último carácter es una nueva línea.

Una vez que encuentra la nueva línea, encoge el buffer al tamaño adecuado y lo devuelve.

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

// Leer una línea de tamaño arbitrario de un fichero
//
// Devuelve un puntero a la línea.
// Devuelve NULL en EOF o error.
//
// Es responsabilidad del que llama liberar() este puntero cuando termine de usarlo.
//
// Tenga en cuenta que esto elimina la nueva línea del resultado. Si necesita
// de él, probablemente sea mejor cambiar esto, a un do-while.

char *readline(FILE *fp)
{
    int offset = 0; // Indice del siguiente char en el buffer
    int bufsize = 4; // Preferiblemente con un tamaño inicial que sea potencia de 2 
    char *buf; // El buffer
    int c; // El carácter que hemos leído

    buf = malloc(bufsize);  // Asignar búfer inicial

    if (buf == NULL)   // Comprobación de errores
        return NULL;

    // Bucle principal--leer hasta nueva línea o EOF
    while (c = fgetc(fp), c != '\n' && c != EOF) {

        // Comprueba si nos hemos quedado sin espacio en el buffer contabilidad
        // por el byte extra para el terminador NUL
        if (offset == bufsize - 1) {  // -1 para el terminador NUL
            bufsize *= 2;  // 2x el espacio

            char *new_buf = realloc(buf, bufsize);

            if (new_buf == NULL) {
                free(buf);   // En caso de error, libera y paga su fianza.
                return NULL;
            }

            buf = new_buf;  // Reasignación correcta
        }

        buf[offset++] = c;  // Añade el byte al buffer
    }

    // Llegamos a la nueva línea o a EOF...

    // Si es EOF y no leemos bytes, liberamos el buffer y
    // devuelve NULL para indicar que estamos en EOF:
    if (c == EOF && offset == 0) {
        free(buf);
        return NULL;
    }

    // Ajustar
    if (offset < bufsize - 1) {  // Si nos falta para el final
        char *new_buf = realloc(buf, offset + 1); // +1 por terminación NUL

        // Si tiene éxito, apunta buf a new_buf;
        // de lo contrario dejaremos buf donde está
        if (new_buf != NULL)
            buf = new_buf;
    }

    // Añadir el terminador NUL
    buf[offset] = '\0';

    return buf;
}

int main(void)
{
    FILE *fp = fopen("foo.txt", "r");

    char *line;

    while ((line = readline(fp)) != NULL) {
        printf("%s\n", line);
        free(line);
    }

    fclose(fp);
}
```

Cuando la memoria crece de esta manera, es común (aunque no es una ley) doblar el espacio
necesario en cada paso para minimizar el número de `realloc()`s que ocurren.

Por último, tenga en cuenta que `readline()` devuelve un puntero a un buffer `malloc()`. Como
tal, es responsabilidad de quien lo llama liberar explícitamente esa memoria cuando termine
de usarla.

### `realloc()` con `NULL`.

[i[`realloc()` function-->with `NULL` argument]<]
¡Hora del Trivial! Estas dos líneas son equivalentes:

``` {.c}
char *p = malloc(3490);
char *p = realloc(NULL, 3490);
```

Esto podría ser conveniente si se tiene algún tipo de bucle de asignación y no se quiere
poner en un caso especial el primer `malloc()`.

``` {.c}
int *p = NULL;
int length = 0;

while (!done) {
    // Asigna 10 ints más:
    length += 10;
    p = realloc(p, sizeof *p * length);

    // Hacer cosas increíbles
    // ...
}
```

En ese ejemplo, no necesitábamos un `malloc()` inicial ya que `p` era `NULL` para empezar.
[i[`realloc()` function-->with `NULL` argument]>]

## Asignaciones alineadas

[i[Memory alignment]<]
Probablemente no vas a necesitar usar esto.

Y no quiero meterme demasiado en la maleza hablando de ello ahora mismo, pero hay una
cosa llamada _alineación de memoria_, que tiene que ver con que la dirección de memoria
(valor del puntero) sea múltiplo de un cierto número.

Por ejemplo, un sistema puede requerir que los valores de 16 bits comiencen en direcciones
de memoria que sean múltiplos de 2. O que los valores de 64 bits comiencen en direcciones
de memoria que sean múltiplos de 2, 4 u 8, por ejemplo. Depende de la CPU.

Algunos sistemas requieren este tipo de alineación para un acceso rápido a la memoria, o
algunos incluso para el acceso a la memoria en absoluto.

Ahora, si usas `malloc()`, `calloc()`, o `realloc()`, C te dará un trozo de memoria
bien alineado para cualquier valor, incluso `struct`s. Funciona en todos los casos.

Pero puede haber ocasiones en las que sepas que algunos datos pueden ser alineados
en un límite más pequeño, o deben ser alineados en uno más grande por alguna razón.
Imagino que esto es más común en la programación de sistemas embebidos.

[i[`aligned_alloc()` function]<]
En esos casos, puede especificar una alineación con `aligned_alloc()`.

La alineación es una potencia entera de dos mayor que cero, así que `2`, `4`, `8`, `16`, etc.
y se la das a `aligned_alloc()` antes del número de bytes que te interesan.

La otra restricción es que el número de bytes que asignes tiene que ser múltiplo
de la alineación. Pero esto puede estar cambiando. Véase [fl[C Informe de defectos 460|http://www.open-std.org/jtc1/sc22/wg14/www/docs/summary.htm#dr_460]]

Hagamos un ejemplo, asignando en un límite de 64 bytes:

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void)
{
    // Asignar 256 bytes alineados en un límite de 64 bytes
    char *p = aligned_alloc(64, 256);  // 256 == 64 * 4

    // Copia una cadena e imprímela
    strcpy(p, "Hello, world!");
    printf("%s\n", p);

    // Liberar el espacio
    free(p);
}
```

Quiero hacer un comentario sobre `realloc()` y `aligned_alloc()`. `realloc()` no tiene ninguna
garantía de alineación, así que si necesitas obtener espacio reasignado alineado, tendrás
que hacerlo por las malas con `memcpy()`.
[i[`aligned_alloc()` function]>]

Aquí tienes una función no estándar `aligned_realloc()`, por si la necesitas:

``` {.c}
void *aligned_realloc(void *ptr, size_t old_size, size_t alignment, size_t size)
{
    char *new_ptr = aligned_alloc(alignment, size);

    if (new_ptr == NULL)
        return NULL;

    size_t copy_size = old_size < size? old_size: size;  // obtener min

    if (ptr != NULL)
        memcpy(new_ptr, ptr, copy_size);

    free(ptr);

    return new_ptr;
}
```

Tenga en cuenta que _siempre_ copia datos, lo que lleva tiempo, mientras que `realloc()` real
lo evitará si puede. Así que esto es poco eficiente. Evita tener que reasignar datos
alineados a medida.
[i[Memory alignment]>]
[i[Manual memory management]>]
