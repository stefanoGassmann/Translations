<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Tipos Parte V: Literales compuestos y selecciones genéricas

Este es el capítulo final de los tipos. Hablaremos de dos cosas:

* Cómo tener objetos "anónimos" sin nombre y cómo eso es útil.
* Cómo generar código dependiente del tipo.

No están particularmente relacionados, pero realmente no merecen cada uno su propio capítulo. Así que los he metido aquí como un rebelde.

## Literales compuestos

[i[Compound literals]<]

Esta es una característica del lenguaje que te permite crear un objeto de algún tipo sobre la marcha sin tener que asignarlo a una variable. Puedes crear tipos simples, arrays, `struct`s, lo que quieras.

Uno de los principales usos de esto es pasar argumentos complejos a funciones cuando no quieres crear una variable temporal para mantener el valor.

La forma de crear un literal compuesto es poner el nombre del tipo entre paréntesis, y después poner una lista inicializadora. Por ejemplo, un array sin nombre de `int`s, podría tener este aspecto:

``` {.c}
(int []){1,2,3,4}
```

Ahora, esa línea de código no hace nada por sí misma. Crea un array sin nombre de 4 `int`s, y luego los tira sin usarlos.

Podríamos usar un puntero para almacenar una referencia al array...

``` {.c}
int *p = (int []){1 ,2 ,3 ,4};

printf("%d\n", p[1]);  // 2
```

Pero eso parece una forma un poco prolija de tener una matriz. Quiero decir, podríamos haber hecho esto^[Que no es exactamente lo mismo, ya que es una matriz, no un puntero a un `int`]:

``` {.c}
int p[] = {1, 2, 3, 4};

printf("%d\n", p[1]);  // 2
```

Así que veamos un ejemplo más útil.

### Pasando Objetos sin Nombre a Funciones

[i[Compound literals-->passing to functions]<]

Digamos que tenemos una función para sumar un array de `int`s:

``` {.c}
int sum(int p[], int count)
{
    int total = 0;

    for (int i = 0; i < count; i++)
        total += p[i];

    return total;
}
```

Si quisiéramos llamarla, normalmente tendríamos que hacer algo como esto, declarando un array y almacenando valores en él para pasárselos a la función:

``` {.c}
int a[] = {1, 2, 3, 4};

int s = sum(a, 4);
```

Pero los objetos sin nombre nos dan una forma de saltarnos la variable pasándola directamente (nombres de parámetros listados arriba). Compruébalo: vamos a sustituir la variable "a" por una matriz sin nombre que pasaremos como primer argumento:

``` {.c}
//                   p[]         count
//           |-----------------|  |
int s = sum((int []){1, 2, 3, 4}, 4);
```

¡Muy hábil!

[i[Compound literals-->passing to functions]>]

###  `struct`s sin nombre

[i[Compound literals-->with `struct`]<]
[i[`struct` keyword-->compound literals]<]

Podemos hacer algo parecido con `struct`s.

Primero, hagamos las cosas sin objetos sin nombre. Definiremos una `struct` para contener algunas coordenadas `x`/`y`. Luego definiremos una, pasando valores a su inicializador. Finalmente, lo pasaremos a una función para imprimir los valores:

``` {.c .numberLines}
#include <stdio.h>

struct coord {
    int x, y;
};

void print_coord(struct coord c)
{
    printf("%d, %d\n", c.x, c.y);
}

int main(void)
{
    struct coord t = {.x=10, .y=20};

    print_coord(t);   // prints "10, 20"
}
```

¿Suficientemente sencillo?

Vamos a modificarlo para utilizar un objeto sin nombre en lugar de la variable `t` que estamos pasando a `print_coord()`.

Quitaremos `t` y la sustituiremos por una `struct` sin nombre:

``` {.c .numberLines startFrom="7"}
    /estructurar coord t = {.x=10, .y=20};

    print_coord((struct coord){.x=10, .y=20});   // Imprime "10, 20"
```

¡Todavía funciona!

[i[`struct` keyword-->compound literals]>]
[i[Compound literals-->with `struct`]>]

### Punteros a objetos sin nombre

[i[Compound literals-->pointers to]<]

Puede que hayas notado en el último ejemplo que, aunque estábamos usando una `struct`, estábamos pasando una copia de la `struct` a `print_coord()` en lugar de pasar un puntero a la `struct`.

Resulta que podemos tomar la dirección de un objeto sin nombre con `&` como siempre.

Esto es porque, en general, si un operador hubiera funcionado en una variable de ese tipo, puedes usar ese operador en un objeto sin nombre de ese tipo.

Modifiquemos el código anterior para que pasemos un puntero a un objeto sin nombre 

``` {.c .numberLines}
#include <stdio.h>

struct coord {
    int x, y;
};

void print_coord(struct coord *c)
{
    printf("%d, %d\n", c->x, c->y);
}

int main(void)
{
    // Nota el &
    //          |
    print_coord(&(struct coord){.x=10, .y=20});   // Imprime "10, 20"
}
```

Además, esto puede ser una buena manera de pasar incluso punteros a objetos simples:

``` {.c}
// Pasa un puntero a un int con valor 3490
foo(&(int){3490});
```

Así de fácil.

[i[Compound literals-->pointers to]>]

### Objetos sin nombre y alcance

[i[Compound literals-->scope]<]

El tiempo de vida de un objeto sin nombre termina al final de su ámbito. La forma más grave de que esto ocurra es si creas un nuevo objeto sin nombre, obtienes un puntero a él y luego abandonas el ámbito del objeto. En ese caso, el puntero se referirá a un objeto muerto.

Esto es un comportamiento indefinido:

``` {.c}
int *p;

{
    p = &(int){10};
}

printf("%d\n", *p);  // INVÁLIDO: El (int){10} se ha salido de ámbito
```

Del mismo modo, no se puede devolver un puntero a un objeto sin nombre desde una función. El objeto se desasigna cuando sale del ámbito:

``` {.c .numberLines}
#include <stdio.h>

int *get3490(void)
{
    // No hagas esto
    return &(int){3490};
}

int main(void)
{
    printf("%d\n", *get3490());  // INVALID: (int){3490} cayó fuera de ámbito
}
```

Piense en su alcance como en el de una variable local normal. Tampoco puedes devolver un puntero a una variable local.

[i[Compound literals-->scope]>]

### Ejemplo tonto de objeto sin nombre

Puedes poner cualquier tipo y hacer un objeto sin nombre.

Por ejemplo, estos son efectivamente equivalentes:

``` {.c}
int x = 3490;

printf("%d\n", x);               // 3490 (variable)
printf("%d\n", 3490);            // 3490 (constant)
printf("%d\n", (int){3490});     // 3490 (unnamed object)
```

Esto último no tiene nombre, pero es una tontería. También podría hacer el simple en la línea anterior.

Pero espero que proporciona un poco más de claridad en la sintaxis.

[i[Compound literals]>]

## Selecciones genéricas {#type-generics}

[i[Generic selections]<]

Se trata de una expresión que permite seleccionar diferentes fragmentos de código en función del _tipo_ del primer argumento de la expresión.

Veremos un ejemplo en un segundo, pero es importante saber que esto se procesa en tiempo de compilación, _no en tiempo de ejecución_. No hay ningún análisis en tiempo de ejecución.
[i[`_Generic` keyword]<]

La expresión empieza por `_Generic`, funciona como un `switch`, y toma al menos dos argumentos

El primer argumento es una expresión (o variable^[Una variable utilizada aquí _es_ una expresión.]) que tiene un _tipo_. Todas las expresiones tienen un tipo. El resto de argumentos de `_Generic` son los casos, de qué sustituir en el resultado de la expresión, si el primer argumento es de ese tipo.

¿Qué?

Probemos a ver.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int i;
    float f;
    char c;

    char *s = _Generic(i,
                    int: "that variable is an int",
                    float: "that variable is a float",
                    default: "that variable is some type"
                );

    printf("%s\n", s);
}
```

Fíjate en la expresión `_Generic` que empieza en la línea 9.

Cuando el compilador la ve, mira el tipo del primer argumento. (En este ejemplo, el tipo de la variable `i`.) Luego busca en los casos algo de ese tipo. Y entonces sustituye el argumento en lugar de toda la expresión `_Generic`. 

En este caso, `i` es un `int`, por lo que coincide con ese caso. Entonces la cadena es sustituida por la expresión. Así que la línea se convierte en esto cuando el compilador lo ve:

``` {.c}
    char *s = "that variable is an int";
```

Si el compilador no puede encontrar una coincidencia de tipo en `_Generic`, busca el caso opcional `default` y lo utiliza.

Si no puede encontrar una coincidencia de tipo y no hay "default", obtendrá un error de compilación.
error de compilación. La primera expresión **debe** coincidir con uno de los tipos o con `default`.

Como es inconveniente escribir `_Generic` una y otra vez, se usa a menudo para hacer el cuerpo de una macro que pueda ser fácilmente reutilizada repetidamente.

Hagamos una macro `TYPESTR(x)` que toma un argumento y devuelve una cadena con el tipo del argumento.

Así, `TYPESTR(1)` devolverá la cadena `"int"`, por ejemplo.

Allá vamos:

``` {.c}
#include <stdio.h>

#define TYPESTR(x) _Generic((x), \
                        int: "int", \
                        long: "long", \
                        float: "float", \
                        double: "double", \
                        default: "something else")

int main(void)
{
    int i;
    long l;
    float f;
    double d;
    char c;

    printf("i is type %s\n", TYPESTR(i));
    printf("l is type %s\n", TYPESTR(l));
    printf("f is type %s\n", TYPESTR(f));
    printf("d is type %s\n", TYPESTR(d));
    printf("c is type %s\n", TYPESTR(c));
}
```

Estas salidas:

``` {.default}
i is type int
l is type long
f is type float
d is type double
c is type something else
```

Lo cual no debería sorprender, porque, como dijimos, ese código en `main()` es reemplazado por lo siguiente cuando se compila:

``` {.c}
    printf("i is type %s\n", "int");
    printf("l is type %s\n", "long");
    printf("f is type %s\n", "float");
    printf("d is type %s\n", "double");
    printf("c is type %s\n", "something else");
```

Y esa es exactamente la salida que vemos.

Vamos a hacer una más. He incluido algunas macros aquí para que cuando se ejecuta:

``` {.c}
int i = 10;
char *s = "Foo!";

PRINT_VAL(i);
PRINT_VAL(s);
```

se obtiene la salida:

``` {.default}
i = 10
s = Foo!
```

Para ello tendremos que recurrir a la magia de las macros.

``` {.c .numberLines}
#include <stdio.h>
#include <string.h>

// Macro que devuelve un especificador de formato para un tipo
#define FMTSPEC(x) _Generic((x), \
                        int: "%d", \
                        long: "%ld", \
                        float: "%f", \
                        double: "%f", \
                        char *: "%s")
                        // TODO: add more types
                        
// Macro que imprime una variable de la forma "nombre = valor"
#define PRINT_VAL(x) do { \
    char fmt[512]; \
    snprintf(fmt, sizeof fmt, #x " = %s\n", FMTSPEC(x)); \
    printf(fmt, (x)); \
} while(0)

int main(void)
{
    int i = 10;
    float f = 3.14159;
    char *s = "Hello, world!";

    PRINT_VAL(i);
    PRINT_VAL(f);
    PRINT_VAL(s);
}
```

[i[`_Generic` keyword]>]

para la salida:

``` {.default}
i = 10
f = 3.141590
s = Hello, world!
```

Podríamos haberlo metido todo en una gran macro, pero lo dividí en dos para evitar el sangrado de los ojos.

[i[Generic selections]>]
