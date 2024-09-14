<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Tipos Enumerados: `enum`

[i[`enum` enumerated types]<]

C nos ofrece otra forma de tener valores enteros constantes por nombre: `enum`.

Por ejemplo:

``` {.c}
enum {
  ONE=1,
  TWO=2
};

printf("%d %d", ONE, TWO);  // 1 2
```

En algunos aspectos, puede ser mejor --o diferente-- que usar un `#define`. Diferencias clave:

* Los `enum`s sólo pueden ser tipos enteros.
* `#define` puede definir cualquier cosa.
* Los `enum`s se muestran a menudo por su nombre de identificador simbólico en un depurador.
* Los números definidos con `#define` se muestran como números brutos que son más difíciles de conocer mientras se depura.

Ya que son tipos enteros, pueden ser usados en cualquier lugar donde se puedan usar enteros,
incluyendo en dimensiones de arreglos y sentencias `case`.

Vamos a profundizar en esto.

## Comportamiento de `enum`

### Numeración

[i[`enum` enumerated types-->numbering order]<]

Los `enum`s se numeran automáticamente a menos que los anules.

Empiezan en `0`, y se autoincrementan desde ahí, por defecto:

``` {.c}
enum {
    SHEEP,  // El Valor es 0
    WHEAT,  // El Valor es 1
    WOOD,   // El Valor es 2
    BRICK,  // El Valor es 3
    ORE     // El Valor es 4
};

printf("%d %d\n", SHEEP, BRICK);  // 0 3
```

Puede forzar determinados valores enteros, como vimos anteriormente:

``` {.c}
enum {
  X=2,
  Y=18,
  Z=-2
};
```

Los duplicados no son un problema:

``` {.c}
enum {
  X=2,
  Y=2,
  Z=2
};
```

si se omiten los valores, la numeración continúa contando en sentido positivo a partir del
último valor especificado. Por ejemplo:

``` {.c}
enum {
  A,    // 0, valor inicial por defecto
  B,    // 1
  C=4,  // 4, ajustar manualmente
  D,    // 5
  E,    // 6
  F=3   // 3, ajustar manualmente
  G,    // 4
  H     // 5
}
```

[i[`enum` enumerated types-->numbering order]>]

### Comas finales

Esto está perfectamente bien, si ese es tu estilo:

``` {.c}
enum {
  X=2,
  Y=18,
  Z=-2,   // <-- Coma final
};
```

Se ha hecho más popular en los idiomas de las últimas décadas, así que puede que te alegre verlo.

### Alcance

[i[`enum` enumerated types-->scope]<]

`enum`s scope como era de esperar. Si está en el ámbito del fichero, todo el fichero puede verlo.
Si está en un bloque, es local a ese bloque.

Es muy común que los `enum`s se definan en ficheros de cabecera para que puedan ser `#include`
en el ámbito del fichero.

[i[`enum` enumerated types-->scope]>]

### Estilo

Como habrás notado, es común declarar los símbolos `enum` en mayúsculas (con guiones bajos).

Esto no es un requisito, pero es un modismo muy, muy común.

## Su `enum` es un Tipo

Esto es algo importante que hay que saber sobre los `enum`: son un tipo, de forma análoga
a como una `struct` es un tipo.

Puedes darles un nombre de etiqueta para poder referirte al tipo más tarde y declarar
variables de ese tipo.

Ahora bien, dado que los `enum`s son tipos enteros, ¿por qué no usar simplemente `int`?

En C, la mejor razón para esto es la claridad del código--es una forma agradable y tipada
de describir tu pensamiento en el código. C (a diferencia de C++) no obliga a que ningún valor
esté dentro del rango de un `enum` en particular.

Hagamos un ejemplo donde declaramos una variable `r` de tipo `enum resource` que puede
contener esos valores:

``` {.c}
// Nombrado enum, el tipo es "enum resource"

enum resource {
    SHEEP,
    WHEAT,
    WOOD,
    BRICK,
    ORE
};

// Declarar una variable "r" de tipo "enum resource"

enum resource r = BRICK;

if (r == BRICK) {
    printf("I'll trade you a brick for two sheep.\n");
}
```

También puede `typedef` estos, por supuesto, aunque yo personalmente no me gusta hacerlo.


``` {.c}
typedef enum {
    SHEEP,
    WHEAT,
    WOOD,
    BRICK,
    ORE
} RESOURCE;

RESOURCE r = BRICK;
```

Otro atajo que es legal pero raro es declarar variables cuando declaras el `enum`:

``` {.c}
// Declara un enum y algunas variables inicializadas de ese tipo:

enum {
    SHEEP,
    WHEAT,
    WOOD,
    BRICK,
    ORE
} r = BRICK, s = WOOD;
```

También puedes dar un nombre al `enum` para poder utilizarlo más tarde, que es probablemente
lo que quieres hacer en la mayoría de los casos:


``` {.c}
// Declara un enum y algunas variables inicializadas de ese tipo:

enum resource {   // <-- es ahora "enum resource"
    SHEEP,
    WHEAT,
    WOOD,
    BRICK,
    ORE
} r = BRICK, s = WOOD;
```

En resumen, los `enum`s son una gran manera de escribir código limpio, tipado, de alcance y
agradable.

[i[`enum` enumerated types]>]
