<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Tipos incompletos

[i[Incomplete types]<]

Puede que le sorprenda saber que esto se construye sin errores:

``` {.c}
extern int a[];

int main(void)
{
    struct foo *x;
    union bar *y;
    enum baz *z;
}
```

Nunca hemos dado un tamaño para "a". Y tenemos punteros a `struct`s `foo`, `bar`, y `baz` que nunca parecen estar declarados en ninguna parte.

Y las únicas advertencias que recibo son que `x`, `y`, y `z` no se usan.

Estos son ejemplos de _tipos incompletos_.

Un tipo incompleto es un tipo cuyo tamaño (es decir, el tamaño que obtendrías de `sizeof`) no se conoce. Otra forma de verlo es un tipo que no has terminado de declarar.

Puedes tener un puntero a un tipo incompleto, pero no puedes desreferenciarlo o usar aritmética de punteros en él. Y no se puede `sizeof`.

¿Qué puedes hacer con él?

## Caso práctico: estructuras autorreferenciales

[i[Incomplete types-->self-referential `struct`s]<]

Sólo conozco un caso de uso real: referencias hacia adelante a `struct`s o `union`s con estructuras autorreferenciales o codependientes. (Voy a utilizar `struct` para el resto de estos ejemplos, pero todos se aplican igualmente a `union`s, también).

Hagamos primero el ejemplo clásico.

Pero antes, ¡ten esto en cuenta! Cuando declaras una `struct`, ¡la `struct` está incompleta hasta que se alcanza la llave de cierre!

``` {.c}
struct antelope {              // struct antelope está incompleto aquí
    int leg_count;             // Aún incompleto
    float stomach_fullness;    // Aún incompleto
    float top_speed;           // Aún incompleto
    char *nickname;            // Aún incompleto
};                             // AHORA está completo.
```

¿Y qué? Parece bastante sensato.

¿Pero qué pasa si estamos haciendo una lista enlazada? Cada nodo de la lista enlazada necesita tener una referencia a otro nodo. ¿Pero cómo podemos crear una referencia a otro nodo si ni siquiera hemos terminado de declarar el nodo?

C permite tipos incompletos. No podemos declarar un nodo, pero _podemos_ declarar un puntero a uno, ¡incluso si está incompleto!

``` {.c}
struct node {
    int val;
    struct node *next;  // El nodo struct está incompleto, ¡pero no pasa nada!
};
```

Aunque el nodo `struct` está incompleto en la línea 3, aún podemos declarar un puntero a uno^[Esto funciona porque en C, los punteros tienen el mismo tamaño independientemente del tipo de datos al que apunten. Así que el compilador no necesita saber el tamaño del nodo `struct` en este punto; sólo necesita saber el tamaño de un puntero].

Podemos hacer lo mismo si tenemos dos `struct`s diferentes que se refieren la una a la otra:

``` {.c}
struct a {
    struct b *x;  // Se refiere a una `estructura b`
};

struct b {
    struct a *x;  // Se refiere a una `estructura a`.
};
```

Nunca seríamos capaces de hacer ese par de estructuras sin las reglas relajadas para tipos incompletos.

[i[Incomplete types-->self-referential `struct`s]>]

## Mensajes de error de tipo incompleto

¿Recibe errores como éstos?

``` {.default}
invalid application of ‘sizeof’ to incomplete type

invalid use of undefined type

dereferencing pointer to incomplete type
```

Culpable más probable: probablemente olvidó `#incluir` el fichero de cabecera que declara el tipo.

## Otros tipos incompletos

Declarar una `struct` o `union` sin cuerpo hace un tipo incompleto, por ejemplo `struct foo;`.

Los `enums` son incompletos hasta la llave de cierre.

Los `void` son tipos incompletos.

Los arrays declarados `extern` sin tamaño son incompletos, p.e.:

``` {.c}
extern int a[];
```

Si es un array no `externo` sin tamaño seguido de un inicializador, está incompleto hasta la llave de cierre del inicializador.

## Caso de Uso: Arrays en ficheros de cabecera

Puede ser útil declarar tipos de array incompletos en ficheros de cabecera. En esos casos, el almacenamiento real (donde se declara el array completo) debería estar en un único fichero `.c`. Si lo pones en el fichero `.h`, se duplicará cada vez que se incluya el fichero de cabecera.

Así que lo que puedes hacer es crear un fichero de cabecera con un tipo incompleto que haga referencia al array, así:

``` {.c .numberLines}
// File: bar.h

#ifndef BAR_H
#define BAR_H

extern int my_array[];  // Tipo incompleto

#endif
```

Y el en el archivo `.c`, en realidad definir la matriz:

``` {.c .numberLines}
// File: bar.c

int my_array[1024];     // ¡Tipo completo!
```

A continuación, puede incluir el encabezado de tantos lugares como desee, y cada uno de esos lugares se refieren a la misma subyacente `my_array`.

``` {.c .numberLines}
// File: foo.c

#include <stdio.h>
#include "bar.h"    // incluye el tipo incompleto para mi_array

int main(void)
{
    my_array[0] = 10;

    printf("%d\n", my_array[0]);
}
```

Cuando compile varios archivos, recuerde especificar todos los archivos `.c` al compilador, pero no los archivos `.h`, p. ej:

``` {.zsh}
gcc -o foo foo.c bar.c
```

## Completar tipos incompletos

Si tienes un tipo incompleto, puedes completarlo definiendo el `struct`, `union`, `enum`, o array completo en el mismo ámbito.

``` {.c}
struct foo;        // tipo incompleto

struct foo *p;     // puntero, no hay problema

// struct foo f;   // Error: ¡tipo incompleto!

struct foo {
    int x, y, z;
}; // ¡Ahora la estructura foo está completa!

struct foo f;      // ¡Éxito!
```

Ten en cuenta que aunque `void` es un tipo incompleto, no hay forma de completarlo. No es que a nadie se le ocurra hacer esa cosa rara. Pero explica por qué se puede hacer esto:

``` {.c}
void *p;             // OK: puntero a tipo incompleto
```

y no ninguno de estos:

``` {.c}
void v;              // Error: declarar variable de tipo incompleto

printf("%d\n", *p);  // Error: referencia a un tipo incompleto
```

Cuanto más sepas...

[i[Incomplete types]<]
