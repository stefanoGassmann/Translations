<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Tipos IV: Calificadores y especificadores

Ahora que tenemos algunos tipos más en nuestro haber, resulta que podemos dar a estos
tipos algunos atributos adicionales que controlan su comportamiento. Estos son los
_calificadores de tipo_ y los _especificadores de clase de almacenamiento_.

## Calificadores de tipo

[i[Type qualifiers]<]

Esto le permitirá declarar valores constantes, y también dar al compilador
pistas de optimización que puede utilizar.

### `const`

[i[`const` type qualifier]<]

Es el calificador de tipo más común. Significa que la variable es constante y que
cualquier intento de modificarla, provocará el enfado del compilador.

``` {.c}
const int x = 2;

x = 4;  // COMPILADOR EMITE SONIDOS DE BOCINAZOS
        // no se puede asignar a una constante
```

No se puede modificar un valor `const`.

A menudo se ve `const` en las listas de parámetros de las funciones:

``` {.c}
void foo(const int x)
{
    printf("%d\n", x + 30);  // OK, no modifica «x»
}
```

#### `const` y punteros

[i[`const` type qualifier-->and pointers]<]

Esto se pone un poco raro, porque hay dos usos que tienen dos significados cuando
se trata de punteros.

Por un lado, podemos hacer que no se pueda cambiar la cosa a la que apunta el puntero. Esto
se hace poniendo `const` delante del nombre del tipo (antes del asterisco) en la
declaración del tipo.

``` {.c}
int x[] = {10, 20};
const int *p = x; 

p++;  // Podemos modificar p, no hay problema

*p = 30; // ¡Error del compilador! No se puede cambiar a qué apunta
```

De forma un tanto confusa, estas dos cosas son equivalentes:

``` {.c}
const int *p; // No se puede modificar a qué apunta p
int const *p; // No se puede modificar a qué apunta p,
              // igual que en la línea anterior
```

Genial, así que no podemos cambiar la cosa a la que apunta el puntero, pero podemos
cambiar el propio puntero. ¿Qué pasa si queremos lo contrario? ¿Queremos poder cambiar
aquello a lo que apunta el puntero, pero _no_ el puntero en sí?

Basta con mover el `const` después del asterisco en la declaración:

``` {.c}
int *const p; // No podemos modificar «p» con aritmética de punteros

p++; // ¡Error del compilador!
```

Pero podemos modificar lo que señalan:

``` {.c}
int x = 10;
int *const p = &x;

*p = 20;   // Pon «x» a 20, no hay problema
```

También puedes hacer que ambas cosas sean `const`:

``` {.c}
const int *const p;  // ¡No se puede modificar p o *p!
```

Por último, si tienes varios niveles de indirección, debes `const` los niveles apropiados.
Sólo porque un puntero sea `const`, no significa que el puntero al que apunta también
deba serlo. Puedes establecerlos explícitamente como en los siguientes ejemplos:

``` {.c}
char **p;
p++;     // OK!
(*p)++;  // OK!

char **const p;
p++;     // Error!
(*p)++;  // OK!

char *const *p;
p++;     // OK!
(*p)++;  // Error!

char *const *const p;
p++;     // Error!
(*p)++;  // Error!
```

[i[`const` type qualifier-->and pointers]>]

#### `const` Corrección

[i[`const` type qualifier-->correctness]<]

Una cosa más que tengo que mencionar es que el compilador advertirá en algo como esto:

``` {.c}
const int x = 20;
int *p = &x;
```

diciendo algo así como:

``` {.default}
initialization discards 'const' qualifier from pointer type target
// la inicialización descarta el calificador 'const' del objetivo de tipo puntero
```

¿Qué ocurre ahí?

Bueno, tenemos que mirar los tipos a cada lado de la asignación:

``` {.c}
    const int x = 20;
    int *p = &x;
//    ^       ^
//    |       |
//  int*    const int*
```

El compilador nos está avisando de que el valor de la derecha de la asignación
es `const`, pero el de la izquierda no. Y el compilador nos está avisando
de que está descartando la «const-idad» de la expresión de la derecha.

Es decir, _podemos_ seguir intentando hacer lo siguiente, pero es incorrecto. El
compilador avisará, y es un comportamiento indefinido:

``` {.c}
const int x = 20;
int *p = &x;

*p = 40;  // Comportamiento indefinido--¡quizás modifica «x», quizás no!

printf("%d\n", x);  // 40, si tienes suerte
```

[i[`const` type qualifier-->correctness]>]
[i[`const` type qualifier]>]

### `restrict`

[i[`restrict` type qualifier]<]

TLDR: nunca tienes que usar esto y puedes ignorarlo cada vez que lo veas. Si lo
usas correctamente, es probable que obtengas alguna ganancia de rendimiento. Si lo
usas incorrectamente, obtendrás un comportamiento indefinido.

`restrict` es una sugerencia al compilador de que una determinada parte de la memoria
sólo será accedida por un puntero y nunca por otro. (Es decir, no habrá aliasing
del objeto concreto al que apunta el puntero `restrict`). Si un desarrollador
declara que un puntero es `restrict` y luego accede al objeto al que apunta
de otra manera (por ejemplo, a través de otro puntero), el comportamiento es indefinido.

Básicamente le estás diciendo a C, «Hey---te garantizo que este único puntero
es la única forma en la que accedo a esta memoria, y si miento, puedes sacarme
un comportamiento indefinido».

Y C usa esa información para realizar ciertas optimizaciones. Por ejemplo, si estás
desreferenciando el puntero `restrict` repetidamente en un bucle, C podría decidir
almacenar en caché el resultado en un registro y sólo almacenar el resultado final una vez
que el bucle haya terminado. Si cualquier otro puntero hiciera referencia a esa misma
memoria y accediera a ella en el bucle, los resultados no serían exactos.

(Nótese que `restrict` no tiene efecto si nunca se escribe en el objeto apuntado. Se trata
de optimizaciones en torno a las escrituras en memoria).

Escribamos una función para intercambiar dos variables, y usaremos la palabra
clave `restrict` para asegurar a C que nunca pasaremos punteros a la misma cosa. Y luego
intentemos pasar punteros a la misma cosa.

``` {.c .numberLines}
void swap(int *restrict a, int *restrict b)
{
    int t;

    t = *a;
    *a = *b;
    *b = t;
}

int main(void)
{
    int x = 10, y = 20;

    swap(&x, &y); // ¡Bien! «a» y “b”, arriba, apuntan a cosas diferentes

    swap(&x, &x); // ¡Comportamiento indefinido! «a» y “b” apuntan a lo mismo
}
```

Si elimináramos las palabras clave `restrict`, ambas llamadas funcionarían de forma
segura. Pero entonces el compilador podría no ser capaz de optimizar.

`restrict` tiene ámbito de bloque, es decir, la restricción sólo dura el ámbito
en el que se usa. Si está en una lista de parámetros de una función, está en el ámbito
de bloque de esa función.

Si el puntero restringido apunta a un array, sólo se aplica a los objetos individuales
del array. Otros punteros pueden leer y escribir desde el array siempre que no lean
o escriban ninguno de los mismos elementos que el restringido.

Si está fuera de cualquier función en el ámbito del fichero, la restricción cubre
todo el programa.

Es probable que veas esto en funciones de biblioteca como `printf()`:

``` {.c}
int printf(const char * restrict format, ...);
```

De nuevo, esto sólo indica al compilador que dentro de la función `printf()` sólo
habrá un puntero que haga referencia a cualquier parte de la cadena `format`.

Una última nota: si por alguna razón estás usando la notación de array en el parámetro
de tu función en lugar de la notación de puntero, puedes usar `restrict` así:

``` {.c}
void foo(int p[restrict]) // Sin tamaño

void foo(int p[restrict 10]) // O con un tamaño
```

Pero la notación de puntero sería más común.

[i[`restrict` type qualifier]>]

### `volatile`

[i[`volatile` type qualifier]<]

Es poco probable que veas o necesites esto a menos que estés tratando con
hardware directamente.

`volatile` indica al compilador que un valor puede cambiar a sus espaldas y que
debe buscarlo cada vez.

Un ejemplo podría ser cuando el compilador está buscando en la memoria una dirección
que se actualiza continuamente entre bastidores, por ejemplo, algún tipo de temporizador
de hardware.

Si el compilador decide optimizar eso y almacenar el valor en un registro durante
un tiempo prolongado, el valor en memoria se actualizará y no se reflejará en el registro.

Al declarar algo `volátil`, le estás diciendo al compilador: «Oye, la cosa a la que
esto apunta puede cambiar en cualquier momento por razones ajenas a este código de programa».

``` {.c}
volatile int *p;
```

### `_Atomic`

Esta es una característica opcional de C de la que hablaremos en [el capítulo Atómica](#chapter-atomics).

[i[`volatile` type qualifier]>]
[i[Type qualifiers]>]

## Especificadores de clase de almacenamiento

[i[Storage-Class Specifiers]<]

Los especificadores de clase de almacenamiento son similares a los cuantificadores de tipo.
Proporcionan al compilador más información sobre el tipo de una variable.

### `auto`

[i[`auto` storage class]<]

Apenas se ve esta palabra clave, ya que `auto` es el valor por defecto para las variables
de ámbito de bloque. Está implícita.

Son los mismos:

``` {.c}
{
    int a; // auto es el valor por defecto...
    auto int a; // Esto es redundante
}
```

La palabra clave `auto` indica que este objeto tiene _duración de almacenamiento
automática_. Es decir, existe en el ámbito en el que se define, y se desasigna
automáticamente cuando se sale del ámbito.

Un inconveniente de las variables automáticas es que su valor es indeterminado hasta
que se inicializan explícitamente. Decimos que están llenas de datos «aleatorios»
o «basura», aunque ninguna de las dos cosas me hace feliz. En cualquier caso, no sabrás
lo que contiene a menos que la inicialices.

[i[`auto` storage class]>]

Inicialice siempre todas las variables automáticas antes de utilizarlas.

### `static` {#static}

[i[`static` storage class]<]

Esta palabra clave tiene dos significados, dependiendo de si la variable
es de ámbito de fichero o de ámbito de bloque.

Empecemos con el ámbito de bloque.

#### `static` en Alcance del bloque

[i[`static` storage class-->in block scope]<]

En este caso, básicamente estamos diciendo: «Sólo quiero que exista una única
instancia de esta variable, compartida entre llamadas».

Es decir, su valor persistirá entre llamadas.

Una variable `static` en ámbito de bloque con un inicializador sólo se inicializará
una vez al iniciar el programa, no cada vez que se llame a la función.

Hagamos un ejemplo:

``` {.c .numberLines}
#include <stdio.h>

void counter(void)
{
    static int count = 1;  // Se inicializa una vez

    printf("Se ha llamado %d vez(es)\n", count);

    count++;
}

int main(void)
{
    counter(); // «Se ha llamado 1 vez(es)»
    counter(); // «Se ha llamado 2 vez(es)»
    counter(); // «Se ha llamado 3 vez(es)»
    counter(); // «Se ha llamado 4 vez(es)»
}
```

¿Ves cómo el valor de `count` persiste entre llamadas?

Una cosa a tener en cuenta es que las variables de ámbito de bloque `static` se
inicializan a `0` por defecto.

``` {.c}
static int foo; // El valor inicial por defecto es `0`...
static int foo = 0; // Así que la asignación `0` es redundante
```

Por último, ten en cuenta que si escribes programas multihilo, tienes que asegurarte
de no dejar que varios hilos pisoteen la misma variable.

[i[`static` storage class-->in block scope]>]

#### `static` en Alcance del archivo

[i[`static` storage class-->in file scope]<]

Cuando se sale del ámbito del fichero, fuera de cualquier bloque, el significado
cambia bastante.

Las variables en el ámbito del fichero ya persisten entre llamadas a funciones, así que
ese comportamiento ya existe.

En cambio, lo que `static` significa en este contexto es que esta variable no es visible
fuera de este archivo fuente en particular. Algo así como «global», pero sólo en este archivo.

Más sobre esto en la sección sobre construir con múltiples ficheros fuente.
[i[`static` storage class-->in file scope]>]
[i[`static` storage class]>]

### `extern` {#extern}

[i[`extern` storage class]<]

El especificador de clase de almacenamiento `extern` nos da una forma de referirnos
a objetos en otros ficheros fuente.

Digamos, por ejemplo, que el fichero `bar.c` tiene lo siguiente en su totalidad:

``` {.c .numberLines}
// bar.c

int a = 37;
```

Sólo eso. Declarando un nuevo `int a` en el ámbito del fichero.

¿Pero qué pasaría si tuviéramos otro fichero fuente, `foo.c`, y quisiéramos
referirnos a `a` que está en `bar.c`?

Es fácil con la palabra clave `extern`:

``` {.c .numberLines}
// foo.c

extern int a;

int main(void)
{
    printf("%d\n", a);  // 37, ¡desde bar.c!

    a = 99;

    printf("%d\n", a);  // La misma «a» de bar.c, pero ahora es 99
}
```

También podríamos haber hecho el `extern int a` en el ámbito del bloque, y aún así
se habría referido al `a` en `bar.c`:

``` {.c .numberLines}
// foo.c

int main(void)
{
    extern int a;

    printf("%d\n", a);  // 37, ¡desde bar.c!

    a = 99;

    printf("%d\n", a);  // La misma «a» de bar.c, pero ahora es 99
}
```

Ahora bien, si `a` en `bar.c` se hubiera marcado como `static`, esto no habría funcionado.
Las variables `static` en el ámbito de un fichero no son visibles fuera de ese fichero.

Una nota final sobre `extern` en funciones. Para las funciones, `extern` es el valor
por defecto, por lo que es redundante. Puedes declarar una función `static` si sólo
quieres que sea visible en un único fichero fuente.

[i[`extern` storage class]>]

### `register`

[i[`register` storage class]<]

Se trata de una palabra clave que indica al compilador que esta variable se utiliza
con frecuencia, y que debe ser lo más rápida posible. El compilador no está
obligado a aceptarla.

Ahora bien, los modernos optimizadores del compilador de C son bastante eficaces
a la hora de averiguar esto por sí mismos, por lo que es raro verlo hoy en día.

Pero si es necesario:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    register int a;   // Haz que «a» sea tan rápido de usar como sea posible.

    for (a = 0; a < 10; a++)
        printf("%d\n", a);
}
```
Sin embargo, tiene un precio. No se puede tomar la dirección de un registro:

``` {.c}
register int a;
int *p = &a;    // ¡ERROR DEL COMPILADOR!
                // No se puede tomar la dirección de un registro!
```

Lo mismo se aplica a cualquier parte de una matriz:

``` {.c}
register int a[] = {11, 22, 33, 44, 55};
int *p = a;  // ¡ERROR DEL COMPILADOR! No se puede tomar la dirección de a[0]
```

O desreferenciar parte de un array:

``` {.c}
register int a[] = {11, 22, 33, 44, 55};

int a = *(a + 2);  // ¡ERROR DEL COMPILADOR! Dirección de a[0] tomada
```

Curiosamente, para el equivalente con notación array, gcc sólo avisa:

``` {.c}
register int a[] = {11, 22, 33, 44, 55};

int a = a[2];  // ¡ADVERTENCIA DEL COMPILADOR!
```

con:

``` {.default}
warning: ISO C forbids subscripting ‘register’ array
//Advertencia: ISO C prohíbe los subíndices en las matrices 'register'
```

El hecho de que no se pueda tomar la dirección de una variable de registro libera
al compilador para realizar optimizaciones en torno a esa suposición, si es que aún
no las ha deducido. Además, añadir `register` a una variable `const` evita
que accidentalmente se pase su puntero a otra función que ignore su constancia ^[https://gustedt.wordpress.com/2010/08/17/a-common-misconsception-the-register-keyword/].

Un poco de historia: en el interior de la CPU hay pequeñas «variables» dedicadas llamadas
[flw[_registers / registros_|Processor_register]]. Su acceso es superrápido comparado
con la RAM, por lo que usarlas aumenta la velocidad. Pero no están en la RAM, así que
no tienen una dirección de memoria asociada (por eso no puedes tomar la dirección-de
u obtener un puntero a ellas).

Pero, como ya he dicho, los compiladores modernos son realmente buenos a la hora
de producir código óptimo, utilizando registros siempre que sea posible independientemente
de si se ha especificado o no la palabra clave `register`. No sólo eso, sino que
la especificación les permite tratarlo como si hubieras escrito «auto», si quieren.
Así que no hay garantías.

[i[`register` storage class]>]

### `_Thread_local`

[i[`_Thread_local` storage class]<]

Cuando utilizas varios subprocesos y tienes algunas variables en el ámbito
global o `static` del bloque, esta es una forma de asegurarte de que cada subproceso
obtiene su propia copia de la variable. Esto te ayudará a evitar condiciones de carrera
y que los hilos se pisen unos a otros.

Si estás en ámbito de bloque, tienes que usar esto junto con `extern` o `static`.

Además, si incluyes `<threads.h>`, puedes usar el más agradable `thread_local` como
alias del más feo `_Thread_local`.

Puedes encontrar más información en la sección [Threads](#thread-local).

[i[`_Thread_local` storage class]>]
[i[Storage-Class Specifiers]>]
