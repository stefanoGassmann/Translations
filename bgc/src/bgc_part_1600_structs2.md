<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# `struct`s II: Más diversión con `struct`s

[i[`struct` keyword]<]

Resulta que hay mucho más que puedes hacer con `struct`s de lo que hemos hablado,
pero es sólo un gran montón de cosas varias. Así que las incluiremos en este capítulo.

Si eres bueno con lo básico de `struct`s, puedes completar tus conocimientos aquí.

## Inicializadores de `struct`s anidadas y matrices

[i[`struct` keyword-->initializers]<]

¿Recuerdas cómo podías [inicializar los miembros de la estructura siguiendo
estas líneas](#struct-initializers)?

``` {.c}
struct foo x = {.a=12, .b=3.14};
```

Resulta que tenemos más potencia en estos inicializadores de la que habíamos
compartido en un principio. ¡Interesante!

Por un lado, si tienes una subestructura anidada como la siguiente, puedes
inicializar miembros de esa subestructura siguiendo los nombres de las variables
línea abajo:

``` {.c}
struct foo x = {.a.b.c=12};
```

Veamos un ejemplo:

``` {.c .numberLines}
#include <stdio.h>

struct cabin_information {
    int window_count;
    int o2level;
};

struct spaceship {
    char *manufacturer;
    struct cabin_information ci;
};

int main(void)
{
    struct spaceship s = {
        .manufacturer="General Products",
        .ci.window_count = 8,   // <-- ¡INICIALIZADOR ANIDADO!
        .ci.o2level = 21
    };

    printf("%s: %d seats, %d%% oxygen\n",
        s.manufacturer, s.ci.window_count, s.ci.o2level);
}
```

Fíjate en las líneas 16-17. Ahí es donde estamos inicializando los miembros
de la `struct cabin_information` en la definición de `s`, nuestra `struct spaceship`.

Y aquí hay otra opción para ese mismo inicializador - esta vez vamos a hacer algo
más estándar, pero cualquiera de los enfoques funciona:

``` {.c .numberLines startFrom="15"}
    struct spaceship s = {
        .manufacturer="General Products",
        .ci={
            .window_count = 8,
            .o2level = 21
        }
    };
```

Como si la información anterior no fuera lo suficientemente espectacular,
también podemos mezclar inicializadores de matrices.

Vamos a cambiar esto para obtener una matriz de información de pasajeros allí, y
podemos comprobar cómo los inicializadores trabajan allí, también.

``` {.c .numberLines}
#include <stdio.h>

struct passenger {
    char *name;
    int covid_vaccinated; // Booleano
};

#define MAX_PASSENGERS 8

struct spaceship {
    char *manufacturer;
    struct passenger passenger[MAX_PASSENGERS];
};

int main(void)
{
    struct spaceship s = {
        .manufacturer="General Products",
        .passenger = {
            // Inicializar un campo cada vez
            [0].name = "Gridley, Lewis",
            [0].covid_vaccinated = 0,

            // O todos a la vez
            [7] = {.name="Brown, Teela", .covid_vaccinated=1},
        }
    };

    printf("Passengers for %s ship:\n", s.manufacturer);

    for (int i = 0; i < MAX_PASSENGERS; i++)
        if (s.passenger[i].name != NULL)
            printf("    %s (%svaccinated)\n",
                s.passenger[i].name,
                s.passenger[i].covid_vaccinated? "": "not ");
}
```

[i[`struct` keyword-->initializers]>]

## `struct`s anonimas

[i[`struct` keyword-->anonymous]<]

Son las "estructuras sin nombre". También las mencionamos en la sección
[`typedef`](#typedef-struct), pero las refrescaremos aquí.

Aquí tenemos una `struct` normal:

``` {.c}
struct animal {
    char *name;
    int leg_count, speed;
};
```

Y aquí está el equivalente anónimo:

``` {.c}
struct {              // <-- Sin nombre
    char *name;
    int leg_count, speed;
};
```

Okaaaaay. ¿Así que tenemos una "estructura", pero no tiene nombre, por lo que
no tenemos manera de utilizarla más tarde? Parece bastante inútil.

Es cierto que en ese ejemplo lo es. Pero todavía podemos hacer uso de ella
de un par de maneras.

Una es rara, pero como la `struct` anónima representa un tipo, podemos simplemente
poner algunos nombres de variables después de ella y usarlos.

``` {.c}
struct {                   // <-- ¡Sin nombre!
    char *name;
    int leg_count, speed;
} a, b, c;                 // 3 variables de este tipo struct

a.name = "antelope";
c.leg_count = 4;           // Por ejemplo
```

Pero sigue sin ser muy útil.

Mucho más común es el uso de `struct`s anónimas con un `typedef` para que podamos
usarlo más tarde (por ejemplo, para pasar variables a funciones).

``` {.c}
typedef struct {                   // <-- ¡Sin nombre!
    char *name;
    int leg_count, speed;
} animal;                          // Nuevo tipo: animal

animal a, b, c;

a.name = "antelope";
c.leg_count = 4;           // Por ejemplo
```

Personalmente, no utilizo muchas `struct`s anónimas. Creo que es más agradable
ver el `struct animal` completo antes del nombre de la variable en una declaración.

Pero eso es sólo mi opinión.

[i[`struct` keyword-->anonymous]>]

## `struct`s (Estructuras autorreferenciales)

[i[`struct` keyword-->self-referential]<]

Para cualquier estructura de datos tipo grafo, es útil poder tener punteros
a los nodos/vértices conectados. Pero esto significa que en la definición
de un nodo, es necesario tener un puntero a un nodo. Es un rollo.

Pero resulta que se puede hacer esto en C sin ningún problema.

Por ejemplo, aquí hay un nodo de lista enlazada:

``` {.c}
struct node {
    int data;
    struct node *next;
};
```

Es importante tener en cuenta que `next` es un puntero. Esto es lo que permite 
todo el asunto incluso construir. A pesar de que el compilador no sabe cómo es
el nodo `struct` completo, todos los punteros tienen el mismo tamaño.

Aquí hay un programa de lista enlazada para probarlo:

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

struct node {
    int data;
    struct node *next;
};

int main(void)
{
    struct node *head;

    // Hackishly configurar una lista enlazada (11)->(22)->(33)
    head = malloc(sizeof(struct node));
    head->data = 11;
    head->next = malloc(sizeof(struct node));
    head->next->data = 22;
    head->next->next = malloc(sizeof(struct node));
    head->next->next->data = 33;
    head->next->next->next = NULL;

    // Atraviésalo
    for (struct node *cur = head; cur != NULL; cur = cur->next) {
        printf("%d\n", cur->data);
    }
}
```

Corriendo que imprime:

``` {.default}
11
22
33
```

[i[`struct` keyword-->self-referential]>]

## Miembros flexibles de la matriz

[i[`struct` keyword-->flexible array members]<]

En los viejos tiempos, cuando la gente tallaba el código C en madera, algunos
pensaban que estaría bien poder asignar `struct`s que tuvieran arrays de longitud
variable al final.

Quiero dejar claro que la primera parte de la sección es la forma antigua de hacer
las cosas, y que después vamos a hacer las cosas de la forma nueva.

Por ejemplo, podrías definir una `struct` para contener cadenas y la longitud de esa
cadena. Tendría una longitud y una matriz para contener los datos. Tal vez algo
como esto:

``` {.c}
struct len_string {
    int length;
    char data[8];
};
```

Pero eso tiene "8" codificados como la longitud máxima de una cadena, y eso no es
mucho. ¿Qué pasa si hacemos algo _limpio_ y simplemente `malloc()` algún espacio
extra al final después de la estructura, y luego dejar que los datos se desborden
en ese espacio?

Hagamos eso, y luego asignemos otros 40 bytes encima:

``` {.c}
struct len_string *s = malloc(sizeof *s + 40);
```

Como `data` es el último campo de la `struct`, si desbordamos ese campo, ¡se acaba
el espacio que ya habíamos asignado! Por esta razón, este truco sólo funciona
si el array corto es el _último_ campo de la `struct`.

``` {.c}
// Copie más de 8 bytes

strcpy(s->data, "Hello, world!");  // No se estrellará. Probablemente.
```

[i[Arrays-->zero length]<]

De hecho, existía una solución común en el compilador para hacer esto, en la que
se asignaba un array de longitud cero al final:

``` {.c}
struct len_string {
    int length;
    char data[0];
};
```

Y entonces cada byte extra que asignaste estaba listo para ser usado en esa cadena.

Como `data` es el último campo de la `struct`, si desbordamos ese campo, ¡se acaba
el espacio que ya habíamos asignado!

``` {.c}
// Copie más de 8 bytes

strcpy(s->data, "Hello, world!");  // No se estrellará. Probablemente.
```

Pero, por supuesto, acceder a los datos más allá del final de la matriz es un
comportamiento indefinido. En estos tiempos modernos, ya no nos dignamos a recurrir
a semejante salvajada.

[i[Arrays-->zero length]>]

Por suerte para nosotros, todavía podemos conseguir el mismo efecto con C99 y
posteriores, pero ahora es legal.

Cambiemos nuestra definición anterior para que el array no tenga tamaño^[Técnicamente
decimos que tiene un _tipo incompleto_]:

``` {.c}
struct len_string {
    int length;
    char data[];
};
```

De nuevo, esto sólo funciona si el miembro del array flexible es el _último_ campo
de la `struct`.

Y entonces podemos asignar todo el espacio que queramos para esas cadenas haciendo
`malloc()`mayor que la `struct len_string` de `construcción`, como hacemos en este
ejemplo que hace una nueva `struct len_string` a partir de una
cadena C:


``` {.c}
struct len_string *len_string_from_c_string(char *s)
{
    int len = strlen(s);

    // Asignar "len" más bytes de los que normalmente necesitaríamos
    struct len_string *ls = malloc(sizeof *ls + len);

    ls->length = len;

    // Copia la cadena en esos bytes extra
    memcpy(ls->data, s, len);

    return ls;
}
```

[i[`struct` keyword-->flexible array members]>]

## Bytes de relleno {#struct-padding-bytes}

[i[`struct` keyword-->padding bytes]<]

Tenga en cuenta que C puede añadir bytes de relleno dentro o después de una `struct`
según le convenga. No puedes confiar en que estarán directamente adyacentes
en memoria^[Aunque algunos compiladores tienen opciones para forzar que esto
ocurra---busca `__attribute__((packed))` para ver cómo hacer esto con GCC].

Echemos un vistazo a este programa. Obtenemos dos números. Uno es la suma del
`tamaño de` los tipos de campo individuales. El otro es el tamaño de toda
la estructura.

Es de esperar que sean iguales. El tamaño del total es el tamaño de la suma
de sus partes, ¿verdad?

``` {.c .numberLines}
#include <stdio.h>

struct foo {
    int a;
    char b;
    int c;
    char d;
};

int main(void)
{
    printf("%zu\n", sizeof(int) + sizeof(char) + sizeof(int) + sizeof(char));
    printf("%zu\n", sizeof(struct foo));
}
```

Pero en mi sistema, esto sale:

``` {.default}
10
16
```

No son iguales. El compilador ha añadido 6 bytes de relleno para mejorar
el rendimiento. Puede que tu compilador te dé un resultado diferente, pero a menos
que lo fuerces, no puedes estar seguro de que no haya relleno.

[i[`struct` keyword-->padding bytes]>]

## `offsetof`

[i[`offsetof()` macro]<]

En la sección anterior, vimos que el compilador podía inyectar bytes de relleno
a voluntad dentro de una estructura.

¿Y si necesitáramos saber dónde están? Podemos medirlo con `offsetof`, definido
en `<stddef.h>`.

Modifiquemos el código anterior para imprimir los desplazamientos de los campos
individuales en la `struct`:

``` {.c .numberLines}
#include <stdio.h>
#include <stddef.h>

struct foo {
    int a;
    char b;
    int c;
    char d;
};

int main(void)
{
    printf("%zu\n", offsetof(struct foo, a));
    printf("%zu\n", offsetof(struct foo, b));
    printf("%zu\n", offsetof(struct foo, c));
    printf("%zu\n", offsetof(struct foo, d));
}
```

Para mí, estas salidas:

``` {.default}
0
4
8
12
```

indicando que estamos utilizando 4 bytes para cada uno de los campos. Es un poco
raro, porque `char` es sólo 1 byte, ¿verdad? El compilador está poniendo 3 bytes
de relleno después de cada `char` para que todos los campos tengan 4 bytes.
Presumiblemente esto se ejecutará más rápido en mi CPU.

[i[`offsetof()` macro]>]

<!--

6.7.2.1

15 Within a structure object, the non-bit-field members and the units in which bit-fields reside have addresses that increase in the order in which they are declared. A pointer to a structure object, suitably converted, points to its initial member (or if that member is a bit-field, then to the unit in which it resides), and vice versa. There may be unnamed padding within a structure object, but not at its beginning.

6.2.7 Compatible type and composite type

1 Two types have compatible type if their types are the same.

6.5

7 An object shall have its stored value accessed only by an lvalue expression that has one of the following types:

- a type compatible with the effective type of the object

-->

## Falsa OOP {#fake-oop}

Hay una cosa un poco abusiva que es una especie de OOP-como que se puede hacer
con `struct`s.

Dado que el puntero a la `struct` es el mismo que un puntero al primer elemento
de la `struct`, puedes lanzar libremente un puntero a la `struct` a un puntero
al primer elemento.

Esto significa que podemos crear una situación como la siguiente:

``` {.c}
struct parent {
    int a, b;
};

struct child {
    struct parent super;  // DEBE ser el primero
    int c, d;
};
```

Entonces podemos pasar un puntero a una `struct hija` a una función que espera
o bien eso _o_ ¡un puntero a una `struct padre`!

Como `struct padre super` es el primer elemento de `struct hijo`, un puntero a
cualquier `struct hijo` es lo mismo que un puntero a ese campo `super`^[`super` no
es una palabra clave, por cierto. Sólo estoy robando terminología de programación
orientada a objetos].

Pongamos un ejemplo. Haremos `struct`s como arriba, pero luego pasaremos un puntero
a una `struct hija` a una función que necesita un puntero a una `struct padre`... y
seguirá funcionando.

``` {.c .numberLines}
#include <stdio.h>

struct parent {
    int a, b;
};

struct child {
    struct parent super;  // DEBE ser el primero
    int c, d;
};

// Haciendo el argumento `void*` para que podamos pasarle cualquier tipo
// (es decir, un struct padre o struct hijo)
void print_parent(void *p)
{
    // Espera una estructura padre--pero una estructura hijo también funcionará
    // porque el puntero apunta al struct padre en el primer
    // campo:
    struct parent *self = p;

    printf("Parent: %d, %d\n", self->a, self->b);
}

void print_child(struct child *self)
{
    printf("Child: %d, %d\n", self->c, self->d);
}

int main(void)
{
    struct child c = {.super.a=1, .super.b=2, .c=3, .d=4};

    print_child(&c);
    print_parent(&c);  // ¡También funciona aunque sea un struct hijo!
}
```

¿Ves lo que hemos hecho en la última línea de `main()`? Llamamos a `print_parent()`
pero pasamos una `struct child*` como argumento. Aunque `print_parent()` necesita que
el argumento apunte a una `struct padre`, nos estamos _saliendo con la nuestra_
porque el primer campo de la `struct hija` es una `struct padre`.

De nuevo, esto funciona porque un puntero a una `struct` tiene el mismo valor que
un puntero al primer campo de esa `struct`.

Todo depende de esta parte de la especificación:

> **§6.7.2.1¶15** [...] Un puntero a un objeto estructura, convenientemente
> convertido, apunta a su miembro inicial [...], y viceversa.

y

§§6.5¶7** Sólo se puede acceder al valor almacenado de un objeto mediante una expresión
> expresión lvalue que tenga uno de los siguientes tipos:
>
> * un tipo compatible con el tipo efectivo del objeto
> * [...]

y mi suposición de que "convenientemente convertido" significa "moldeado al tipo 
efectivo del miembro inicial".

## Campos de bits

[i[`struct` keyword-->bit fields]<]

En mi experiencia, rara vez se utilizan, pero puede que los veas por ahí de vez
en cuando, especialmente en aplicaciones de bajo nivel que empaquetan bits
en espacios más grandes.

Echemos un vistazo a algo de código para demostrar un caso de uso:

``` {.c .numberLines}
#include <stdio.h>

struct foo {
    unsigned int a;
    unsigned int b;
    unsigned int c;
    unsigned int d;
};

int main(void)
{
    printf("%zu\n", sizeof(struct foo));
}
```

Para mí, esto imprime `16`. Lo cual tiene sentido, ya que `unsigned`s son 4 bytes
en mi sistema.

Pero, ¿y si supiéramos que todos los valores que se van a almacenar en `a` y `b` se
pueden almacenar en 5 bits, y los valores en `c`, y `d` se pueden almacenar en 3
bits?  Eso es sólo un total de 16 bits. ¿Por qué tener 128 bits reservados para
ellos si sólo vamos a usar 16?

Bueno, podemos decirle a C que por favor intente empaquetar estos valores. Podemos
especificar el número máximo de bits que pueden tener los valores (desde 1 hasta el
tamaño del tipo que los contiene).

Esto se hace poniendo dos puntos después del nombre del campo, seguido del ancho del
campo en bits.

``` {.c .numberLines startFrom="3"}
struct foo {
    unsigned int a:5;
    unsigned int b:5;
    unsigned int c:3;
    unsigned int d:3;
};
```

Ahora, cuando le pregunto a C cuánto mide mi `estructura foo`, ¡me dice 4! Eran 16
bytes, pero ahora son sólo 4. Ha "empaquetado" esos 4 valores en 4 bytes, lo que
supone un ahorro de memoria cuatro veces mayor.

La contrapartida es, por supuesto, que los campos de 5 bits sólo pueden contener
valores del 0 al 31 y los de 3 bits sólo pueden contener valores del 0 al 7. Pero
la vida es así. Pero, al fin y al cabo, la vida es un compromiso.

### Campos de bits no adyacentes

Un inconveniente: C sólo combinará campos de bits **adyacentes**. Si están
interrumpidos por campos que no son de bits, no se ahorra nada:

``` {.c}
struct foo { // sizeof(struct foo) == 16 (para mí)
    unsigned int a:1; // ya que a no es adyacente a c.
    unsigned int b;
    unsigned int c:1;
    unsigned int d;
};
```

En ese ejemplo, como "a" no es adyacente a "c", ambas están "empaquetadas" en sus
propios "int".

Así que tenemos un `int` para `a`, `b`, `c` y `d`. Como mis `int`s son de 4 bytes,
hay un total de 16 bytes.

Una rápida reorganización nos permite ahorrar espacio, de 16 a 12 bytes (en mi
sistema):

``` {.c}
struct foo {            // sizeof(struct foo) == 12 (para mí)
    unsigned int a:1;
    unsigned int c:1;
    unsigned int b;
    unsigned int d;
};
```

Y ahora, como `a` está junto a `c`, el compilador los junta en un único `int`.

Así que tenemos un `int` para `a` y `c` combinados, y un `int` para `b` y `d`. Para
un total de 3 `int`s, o 12 bytes.

Pon todos tus campos de bits juntos para que el compilador los combine.

### `int`s con signo o sin signo

Si simplemente declaras un campo de bits como `int`, los diferentes compiladores
lo tratarán como `signed` o `unsigned`. Igual que ocurre con `char`.

Sea específico sobre el signo cuando utilice campos de bits.

### Campos de bits sin nombre

En algunas circunstancias concretas, puede que necesites reservar algunos bits
por razones de hardware, pero no necesites utilizarlos en código.

Por ejemplo, supongamos que tenemos un byte en el que los 2 bits superiores tienen
un significado, el bit inferior tiene un significado, pero los 5 bits centrales
no los usamos^[Suponiendo `charts` de 8 bits, es decir `CHAR_BIT == 8`.].

Podríamos hacer algo así:

``` {.c}
struct foo {
    unsigned char a:2;
    unsigned char dummy:5;
    unsigned char b:1;
};
```

Y eso funciona--en nuestro código usamos `a` y `b`, pero nunca `dummy`. Sólo está
ahí para consumir 5 bits y asegurarse de que "a" y "b" están en las posiciones
"requeridas" (por este ejemplo artificial) dentro del byte.

C nos permite una forma de limpiar esto: campos de bits sin nombre. Puedes omitir
el nombre (`dummy`) en este caso, y C está perfectamente satisfecho con el mismo
efecto:

``` {.c}
struct foo {
    unsigned char a:2;
    unsigned char :5;   // <--  campo de bits sin nombre
    unsigned char b:1;
};
```

### Campos de bits sin nombre de ancho cero

Algo más de esoterismo por aquí... Digamos que estás empaquetando bits en un
`unsigned int`, y necesitas algunos campos de bits adyacentes para empaquetarlos
en el _siguiente_ `unsigned int`.

Es decir, si haces esto:

``` {.c}
struct foo {
    unsigned int a:1;
    unsigned int b:2;
    unsigned int c:3;
    unsigned int d:4;
};
```

el compilador los empaqueta todos en un único `unsigned int`. ¿Pero qué pasa si
necesitas `a` y `b` en un `int`, y `c` y `d` en otro diferente?

Hay una solución para eso: poner un campo de bits sin nombre de ancho `0` donde
quieras que el compilador empiece de nuevo a empaquetar bits en un `int` diferente:

``` {.c}
struct foo {
    unsigned int a:1;
    unsigned int b:2;
    unsigned int :0;   // <--Campo de bits sin nombre de ancho cero
    unsigned int c:3;
    unsigned int d:4;
};
```

Es análogo a un salto de página explícito en un procesador de textos. Le estás
diciendo al compilador: "Deja de empaquetar bits en este `unsigned`, y empieza
a empaquetarlos en el siguiente".

Añadiendo el campo de bits sin nombre de ancho cero en ese lugar, el compilador
pone `a` y `b` en un `unsigned int`, y `c` y `d` en otro `unsigned int`. Dos en
total, para un tamaño de 8 bytes en mi sistema (`unsigned int`s son 4 bytes cada uno).

[i[`struct` keyword-->bit fields]>]

## Uniones (Unions)

[i[`union` keyword]<]

Son básicamente como `struct`s, excepto que los campos se solapan en memoria.
La `union` sólo será lo suficientemente grande para el campo más grande, y sólo
se puede utilizar un campo a la vez.

Es una forma de reutilizar el mismo espacio de memoria para distintos tipos de datos.

Los declaras como `struct`s, excepto que es `union`. Echa un vistazo a esto:

``` {.c}
union foo {
    int a, b, c, d, e, f;
    float g, h;
    char i, j, k, l;
};
```

Eso son muchos campos. Si esto fuera una `estructura`, mi sistema me diría que se
necesitan 36 bytes para contenerlo todo.

Pero es una `union`, así que todos esos campos se solapan en el mismo espacio
de memoria. El más grande es `int` (o `float`), que ocupa 4 bytes en mi sistema.
Y, de hecho, si pregunto por el `sizeof` de la `unión foo`, ¡me dice 4!

El inconveniente es que sólo se puede utilizar uno de esos campos a la vez. Pero...

### Unions y Tipo Punning {#union-type-punning}

[i[`union` keyword-->type punning]<]

Se puede escribir de forma no portátil en un campo `union` y leer de otro.

Esto se llama [flw[type punning|Type_punning]], y lo usarías si realmente supieras
lo que estás haciendo, normalmente con algún tipo de programación de bajo nivel.

Dado que los miembros de una unión comparten la misma memoria, escribir en un miembro
afecta necesariamente a los demás. Y si se lee de uno lo que se ha escrito en otro,
se obtienen efectos extraños.

``` {.c .numberLines}
#include <stdio.h>

union foo {
    float b;
    short a;
};

int main(void)
{
    union foo x;

    x.b = 3.14159;

    printf("%f\n", x.b);  // 3.14159, bastante justo

    printf("%d\n", x.a);  // Pero, ¿y esto?
}
```

En mi sistema, esto se imprime:

```
3.141590
4048
```

porque bajo el capó, la representación del objeto para el float `3.14159` era la
misma que la representación del objeto para el short `4048`. En mi sistema. Tus
resultados pueden variar.

[i[`union` keyword-->type punning]>]

### Punteros a `union`s

[i[`union` keyword-->pointers to]<]

Si tienes un puntero a una `union`, puedes convertir ese puntero a cualquiera de
los tipos de los campos de esa `union` y obtener los valores de esa forma.

En este ejemplo, vemos que la `union` tiene `int`s y `float`s en ella. Y obtenemos
punteros a la `union`, pero los convertimos a los tipos `int*` y `float*` (la
conversión silencia las advertencias del compilador). Y si los desreferenciamos,
vemos que tienen los valores que almacenamos directamente en la "unión".

``` {.c .numberLines}
#include <stdio.h>

union foo {
    int a, b, c, d, e, f;
    float g, h;
    char i, j, k, l;
};

int main(void)
{
    union foo x;

    int *foo_int_p = (int *)&x;
    float *foo_float_p = (float *)&x;

    x.a = 12;
    printf("%d\n", x.a);           // 12
    printf("%d\n", *foo_int_p);    // 12, nuevamente

    x.g = 3.141592;
    printf("%f\n", x.g);           // 3.141592
    printf("%f\n", *foo_float_p);  // 3.141592, nuevamente
}
```

Lo contrario también es cierto. Si tenemos un puntero a un tipo dentro de `union`,
podemos convertirlo en un puntero a `union` y acceder a sus miembros.

``` {.c}
union foo x;
int *foo_int_p = (int *)&x;             // Puntero a campo int
union foo *p = (union foo *)foo_int_p;  // Volver al puntero de la unión

p->a = 12;  // Esta línea es la misma que...
x.a = 12;   // este.
```

Todo esto sólo te permite saber que, bajo el capó, todos estos valores en un `union`
comienzan en el mismo lugar en la memoria, y eso es lo mismo que donde todo el `union
es.

[i[`union` keyword-->pointers to]>]

### Secuencias iniciales comunes en las uniones

[i[`union` keyword-->common initial sequences]<]

Si tienes una `union` de `struct`s, y todas esas `struct`s empiezan con una
_secuencia inicial común_, es válido acceder a miembros de esa secuencia desde
cualquiera de los miembros de la `union`.

¿Cómo?

Aquí hay dos `struct`s con una secuencia inicial común:

``` {.c}
struct a {
	int x;     //
	float y;   // Secuencia inicial común

	char *p;
};

struct b {
	int x;     //
	float y;   // Secuencia inicial común

	double *p;
	short z;
};
```

¿Lo ves? Es que empiezan con `int` seguido de `float`---esa es la secuencia inicial
común. Los miembros en la secuencia de las `struct`s tienen que ser tipos
compatibles. Y lo vemos con `x` y `y`, que son `int` y `float` respectivamente.

Ahora vamos a construir una unión de estos:

``` {.c}
union foo {
	struct a sa;
	struct b sb;
};
```

Lo que nos dice esta regla es que tenemos garantizado que los miembros de las secuencias iniciales comunes son intercambiables en código. Es decir:

* `f.sa.x` es lo mismo que `f.sb.x`.

y

* `f.sa.y` es lo mismo que `f.sb.y`.

Porque los campos `x` e `y` están ambos en la secuencia inicial común.

Además, los nombres de los miembros de la secuencia inicial común no importan.
todo lo que importa es que los tipos son los mismos.

En conjunto, esto nos permite añadir de forma segura alguna información compartida
entre `struct`s en la `union`. El mejor ejemplo de esto es probablemente el uso de un
campo para determinar el tipo de `struct` de todas las `struct`s en la `union` que
está actualmente "en uso".

Es decir, si no se nos permitiera esto y pasáramos la `union` a alguna función, ¿cómo
sabría esa función qué miembro de la `union` es el que debería mirar?

Echa un vistazo a estas `struct`s. Observa la secuencia inicial común:

``` {.c .numberLines}
#include <stdio.h>

struct common {
	int type;   // secuencia inicial común
};

struct antelope {
	int type;   // secuencia inicial común

	int loudness;
};

struct octopus {
	int type;   // secuencia inicial común

	int sea_creature;
	float intelligence;
};

```

Ahora vamos a meterlos en un `union`:

``` {.c .numberLines startFrom="20"}
union animal {
	struct common common;
	struct antelope antelope;
	struct octopus octopus;
};

```

También, permítanme estos dos `#define`s para la demo:

``` {.c .numberLines startFrom="26"}
#define ANTELOPE 1
#define OCTOPUS  2

```

Hasta ahora, aquí no ha pasado nada especial. Parece que el campo `type` es
completamente inútil.

Pero ahora hagamos una función genérica que imprima un `union animal`. De alguna
manera tiene que ser capaz de decir si está mirando un `struct antílope` o un
`struct pulpo`.

Gracias a la magia de las secuencias iniciales comunes, puede buscar el tipo de
animal en cualquiera de estos lugares para un `animal de unión x` en particular:

``` {.c}
int type = x.common.type;    \\ or...
int type = x.antelope.type;  \\ or...
int type = x.octopus.type;
```

Todos ellos se refieren al mismo valor en memoria.

Y, como habrás adivinado, el `struct common` está ahí para que el código pueda mirar
agnósticamente el tipo sin mencionar un animal en particular.

Veamos el código para imprimir un `union animal`:

``` {.c .numberLines startFrom="29"}
void print_animal(union animal *x)
{
	switch (x->common.type) {
		case ANTELOPE:
			printf("Antelope: loudness=%d\n", x->antelope.loudness);
			break;

		case OCTOPUS:
			printf("Octopus : sea_creature=%d\n", x->octopus.sea_creature);
			printf("          intelligence=%f\n", x->octopus.intelligence);
			break;
		
		default:
			printf("Unknown animal type\n");
	}

}

int main(void)
{
	union animal a = {.antelope.type=ANTELOPE, .antelope.loudness=12};
	union animal b = {.octopus.type=OCTOPUS, .octopus.sea_creature=1,
	                                   .octopus.intelligence=12.8};

	print_animal(&a);
	print_animal(&b);
}
```

Mira cómo en la línea 29 sólo estamos pasando la `union` --no tenemos ni idea de qué
tipo de animal `struct` está en uso dentro de ella.

Pero no pasa nada. Porque en la línea 31 comprobamos el tipo para ver si es un
antílope o un pulpo. Y entonces podemos mirar en la `struct` apropiada para obtener
los miembros.

Definitivamente es posible conseguir este mismo efecto usando sólo `struct`s, pero
puedes hacerlo de esta manera si quieres los efectos de ahorro de memoria de una
`union`.
[i[`union` keyword-->common initial sequences]>]

## Uniones y estructuras sin nombre

[i[`union` keyword-->and unnamed `struct`s]<]

Usted sabe cómo puede tener un `struct` sin nombre, así:

``` {.c}
struct {
    int x, y;
} s;
```

Eso define una variable `s` que es de tipo `struct` anónimo (porque la `struct` no
tiene etiqueta de nombre), con los miembros `x` e `y`.

Así que cosas como esta son válidas:

``` {.c}
s.x = 34;
s.y = 90;

printf("%d %d\n", s.x, s.y);
```

Resulta que puedes soltar esas `struct`s sin nombre en `union`s tal y como cabría
esperar:

``` {.c}
union foo {
    struct {       // sin nombre!
        int x, y;
    } a;

    struct {       // sin nombre!
        int z, w;
    } b;
};
```

Y luego acceder a ellos con normalidad:

``` {.c}
union foo f;

f.a.x = 1;
f.a.y = 2;
f.b.z = 3;
f.b.w = 4;
```

No hay problema.

[i[`union` keyword-->and unnamed `struct`s]>]

## Pasar y devolver `struct`s y `union`s

[i[`union` keyword-->passing and returning]<]
[i[`struct` keyword-->passing and returning]<]

Puede pasar una `struct` o `union` a una función por valor (en lugar de un puntero
a la misma)---se hará una copia de ese objeto al parámetro como si fuera por
asignación como de costumbre.

También puedes devolver una `struct` o `union` de una función y también se devuelve
por valor.

``` {.c .numberLines}
#include <stdio.h>

struct foo {
    int x, y;
};

struct foo f(void)
{
    return (struct foo){.x=34, .y=90};
}

int main(void)
{
    struct foo a = f();  // Se realiza la copia

    printf("%d %d\n", a.x, a.y);
}
```

Dato curioso: si haces esto, puedes utilizar el operador `.` justo después de la
llamada a la función:

``` {.c .numberLines startFrom="16"}
    printf("%d %d\n", f().x, f().y);
```

(Por supuesto, ese ejemplo llama a la función dos veces, de forma ineficiente).

Y lo mismo vale para devolver punteros a `struct`s y `union`s---sólo asegúrate
de usar el operador de flecha `->` en ese caso.

[i[`union` keyword-->passing and returning]>]
[i[`struct` keyword-->passing and returning]>]
[i[`union` keyword]>]
[i[`struct` keyword]>]
