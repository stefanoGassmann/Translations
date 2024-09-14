<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# `typedef`: Creación de nuevos tipos

[i[`typedef` keyword]<]
Bueno, no tanto crear _nuevos_ tipos como obtener nuevos nombres para tipos existentes.
Suena un poco inútil en la superficie, pero realmente podemos utilizar esto para hacer
nuestro código más limpio.

## `typedef` en Teoría

Básicamente, se toma un tipo existente y se hace un alias para él con `typedef`.

Así:

``` {.c}
typedef int antelope;  // Hacer de «antelope» un alias de «int»

antelope x = 10;       // El tipo «antelope» es el mismo que el tipo «int»
```

Puede tomar cualquier tipo existente y hacerlo. Usted puede incluso hacer un número
de tipos con una lista de comas:

``` {.c}
typedef int antelope, bagel, mushroom;  // Estos son todos «int»
```

Eso es muy útil, ¿verdad? ¿Que puedas escribir «mushroom» en lugar de «bagel»? Debes de
estar muy emocionado con esta función.

De acuerdo, Profesor Sarcasmo... llegaremos a algunas aplicaciones más comunes de esto
en un momento.

### Alcance

[i[`typedef` keyword-->scoping rules]<]
`typedef` sigue las [reglas de ámbito](#scope) habituales.

Por esta razón, es bastante común encontrar `typedef` en el ámbito del archivo
(«global») para que todas las funciones puedan utilizar los nuevos tipos a voluntad.

## `typedef` en la práctica

Así que renombrar `int` a otra cosa no es tan emocionante. Veamos dónde suele
aparecer `typedef`.

### `typedef` y `struct`s {#typedef-struct}

[i[`typedef` keyword-->with `struct`s]<]
A veces, una  `struct` «estructura» se  `typedef` «tipifica» con un nuevo nombre para que no tengas que
escribir la palabra `struct` una y otra vez.

``` {.c}
struct animal {
    char *name;
    int leg_count, speed;
};

// Nombre Original  Nuevo Nombre
//            |         |
//            v         v
//      |-----------| |----|
typedef struct animal animal;

struct animal y;  // Esto funciona
animal z;         // Esto también funciona porque «animal» es un alias
```

Personalmente, no me gusta esta práctica. Me gusta la claridad que tiene el código
cuando añades la palabra `struct` al tipo; los programadores saben lo que obtienen. Pero
es muy común, así que lo incluyo aquí.

Ahora quiero ejecutar exactamente el mismo ejemplo de una manera que se puede ver
comúnmente. Vamos a poner el `struct animal` _en_ el `typedef`. Puedes mezclarlo todo así:

``` {.c}
//      Nombre Original
//            |
//            v
//      |-----------|
typedef struct animal {
    char *name;
    int leg_count, speed;
} animal;                         // <-- Nuevo nombre

struct animal y;  // Esto funciona
animal z;         // Esto también funciona porque «animal» es un alias
```

Es exactamente igual que el ejemplo anterior, pero más conciso.

[i[`typedef` keyword-->with anonymous `struct`s]<]
Pero eso no es todo. Hay otro atajo común, que puedes ver en el código, usando lo que se
llaman _estructuras anónimas_^[Hablaremos más de ellas más adelante]. Resulta que en
realidad, no necesitas nombrar la estructura en una variedad de lugares, y con `typedef` es
uno de ellos.

Hagamos el mismo ejemplo con una estructura anónima:

``` {.c}
//  ¡Estructura anónima! ¡No tiene nombre!
//         |
//         v
//      |----|
typedef struct {
    char *name;
    int leg_count, speed;
} animal;                         // <-- Nuevo nombre

//struct animal y;  // ERROR: esto ya no funciona--¡no existe tal estructura!
animal z;           // Esto funciona porque «animal» es un alias
```

Como otro ejemplo, podríamos encontrar algo como esto:

``` {.c}
typedef struct {
    int x, y;
} point;

point p = {.x=20, .y=40};

printf("%d, %d\n", p.x, p.y);  // 20, 40
```
[i[`typedef` keyword-->with anonymous `struct`s]>]
[i[`typedef` keyword-->with `struct`s]>]
[i[`typedef` keyword-->scoping rules]>]

### `typedef` y otros tipos

No es que usar `typedef` con un tipo simple como `int` sea completamente inútil... te ayuda
a abstraer los tipos para que sea más fácil cambiarlos después.

Por ejemplo, si tienes `float` por todo tu código en 100 zillones de sitios, va a ser
doloroso cambiarlos todos a `double` si descubres que tienes que hacerlo más tarde
por alguna razón.

Pero si te preparas un poco con:

``` {.c}
typedef float app_float;

// y

app_float f1, f2, f3;
```

Si más tarde quieres cambiar a otro tipo, como `long double`, sólo tienes que cambiar
el `typedef`:

``` {.c}
//        voila!
//      |---------|
typedef long double app_float;

// y no es necesario cambiar esta línea:

app_float f1, f2, f3;  // Ahora todos estos son long double
```

### `typedef` y punteros

[i[`typedef` keyword-->with pointers]<]
Puedes hacer un tipo que sea un puntero.

``` {.c}
typedef int *intptr;

int a = 10;
intptr x = &a;  // «intptr» es tipo «int*»
```

Realmente no me gusta esta práctica. Oculta el hecho de que `x` es un tipo puntero
porque no se ve un `*` en la declaración.

En mi opinión, es mejor mostrar explícitamente que estás declarando un tipo puntero para
que otros desarrolladores puedan verlo claramente y no confundan `x` con un tipo no puntero.

Pero en el último recuento, digamos, 832.007 personas tenían una opinión diferente.
[i[`typedef` keyword-->with pointers]>]

### `typedef` y mayúsculas

He visto todo tipo de mayúsculas en `typedef`.

``` {.c}
typedef struct {
    int x, y;
} my_point;          // lower snake case

typedef struct {
    int x, y;
} MyPoint;          // CamelCase

typedef struct {
    int x, y;
} Mypoint;          // Leading uppercase

typedef struct {
    int x, y;
} MY_POINT;          // UPPER SNAKE CASE
```

La especificación C11 no dicta un modo u otro, y muestra ejemplos en mayúsculas y minúsculas.

K&R2 utiliza predominantemente las mayúsculas, pero muestra algunos ejemplos en mayúsculas
y minúsculas (con `_t`).

Si utiliza una guía de estilo, cíñase a ella. Si no, hazte con una y cíñete a ella.

## Arrays y `typedef`

[i[`typedef` keyword-->with arrays]<]
La sintaxis es un poco extraña, y en mi experiencia esto se ve raramente, pero usted
puede utilizar `typedef` en una matriz, de algún número de elementos.

``` {.c}
// Hacer del tipo five_inst un array de 5 ints
typedef int five_ints[5];

five_ints x = {11, 22, 33, 44, 55};
```

No me gusta porque oculta la naturaleza de la variable array, pero se puede hacer.
[i[`typedef` keyword-->with arrays]>]
[i[`typedef` keyword]>]
