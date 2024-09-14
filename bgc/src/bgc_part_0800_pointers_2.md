<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Punteros II: Aritmética {#pointers2}

[i[Pointers-->arithmetic]<]
¡Es hora de entrar más en materia con una serie de nuevos temas sobre punteros! Si no
estás al día con los punteros, [echa un vistazo a la primera sección de la guía sobre
el tema](#pointers).

## Aritmética de punteros

Resulta que se pueden hacer operaciones matemáticas con punteros, sobre todo sumas y restas.

Pero, ¿qué significa hacer eso?

En resumen, si tienes un puntero a un tipo, sumando uno al puntero, te mueves al
siguiente elemento de ese tipo, el cual se encuentra, directamente después de él, en memoria.

Es **importante** recordar, que cuando movemos punteros y buscamos en diferentes lugares
de la memoria, necesitamos asegurarnos de que **siempre** estamos apuntando a un lugar válido
de la memoria, antes de hacer la desreferencia. Si nos vamos por las ramas e intentamos
ver qué hay ahí, el comportamiento es indefinido y el resultado habitual es un fallo.

Esto es un poco complicado con [La equivalencia de Array/Puntero](#arraypointerequiv) pero vamos a intentarlo de todas formas.

### Incrementando punteros

En primer lugar, tomemos una matriz de números.

``` {.c}
int a[5] = {11, 22, 33, 44, 55};
```

A continuación, vamos a obtener un puntero al primer elemento de esa matriz:

``` {.c}
int a[5] = {11, 22, 33, 44, 55};

int *p = &a[0];  // O "int *p = a;" funciona igual de bien
```

A continuación, vamos a imprimir el valor allí por desreferenciación del puntero:

``` {.c}
printf("%d\n", *p);  // Imprime 11
```

Ahora vamos a utilizar la aritmética de punteros para imprimir el siguiente elemento
de la matriz, el que está en el índice 1:

``` {.c}
printf("%d\n", *(p + 1));  // Imprime 22!!
```

¿Qué ha pasado ahí? C sabe que `p` es un puntero a un `int`. Así que sabe el tamaño
de un `int`^[Recuerda que el operador `sizeof` te dice el tamaño en bytes de un objeto
en memoria] y sabe que debe saltarse esa cantidad de bytes para llegar al
siguiente `int` después del primero.

De hecho, el ejemplo anterior podría escribirse de estas dos formas equivalentes:

``` {.c}
printf("%d\n", *p);        // Imprime 11
printf("%d\n", *(p + 0));  // Imprime 11
```

porque añadiendo `0` a un puntero se obtiene el mismo puntero.

Pensemos en el resultado. Podemos iterar sobre elementos de un array de esta forma en
lugar de usar un array:

``` {.c}
int a[5] = {11, 22, 33, 44, 55};

int *p = &a[0];  // O "int *p = a;" funciona igual de bien

for (int i = 0; i < 5; i++) {
    printf("%d\n", *(p + i));  // ¡Igual que p[i]!
}
```

¡Y eso funciona igual que si utilizáramos la notación array! ¡Oooo! Cada vez más cerca
de la equivalencia entre array y puntero. Más sobre esto en este capítulo.

Pero, ¿qué está pasando realmente aquí? ¿Cómo funciona?

¿Recuerdas que la memoria es como un gran array, donde un byte se almacena en cada
índice del array?

Y el índice del array en la memoria tiene algunos nombres:

* Índice en memoria
* Localización
* Dirección
* _Puntero!_

Así que un puntero es un índice en la memoria, en algún lugar.

Por poner un ejemplo al azar, digamos que un número 3490 se almacenó en la
dirección («índice») 23,237,489,202. Si tenemos un puntero `int` a ese 3490, el valor
de ese puntero es 23,237,489,202... porque el puntero es la dirección de memoria.
Diferentes palabras para la misma cosa.


Y ahora digamos que tenemos otro número, 4096, almacenado justo después del 3490
en la dirección 23,237,489,210 (8 más alto que el 3490 porque cada `int` en este
ejemplo tiene 8 bytes de longitud).


Si añadimos `1` a ese puntero, en realidad salta `sizeof(int)` bytes hasta el siguiente `int`.
Sabe que debe saltar tan lejos porque es un puntero `int`. Si fuera un puntero `float`,
saltaría `sizeof(float)` bytes adelante para llegar al siguiente float.

Así que puedes ver el siguiente `int`, añadiendo `1` al puntero, el siguiente
añadiendo `2` al puntero, y así sucesivamente.

### Cambio de punteros

En la sección anterior vimos cómo podíamos añadir un entero a un puntero. Esta vez,
vamos a _modificar el puntero en sí_.

Puede añadir (o restar) valores enteros directamente a (o desde) cualquier puntero.

Repitamos el ejemplo, pero con un par de cambios. En primer lugar, voy a añadir un `999`
al final de nuestros números para utilizar como un valor centinela. Esto nos permitirá
saber dónde está el final de los datos.

``` {.c}
int a[] = {11, 22, 33, 44, 55, 999};  // Añade 999 aquí como centinela

int *p = &a[0];  // p señala el 11
```

Y también tenemos `p` apuntando al elemento en el índice `0` de `a`, es decir `11`, igual
que antes.

Ahora empecemos a _incrementar_ `p` para que apunte a los siguientes elementos del array.
Haremos esto hasta que `p` apunte al `999`; es decir, lo haremos hasta que `*p == 999`:

``` {.c}
while (*p != 999) {       // Mientras que la cosa a la que p señala no es 999
    printf("%d\n", *p);   // Imprimir
    p++;                  // Mueve(Incrementa) p para apuntar al siguiente int
}
```

Bastante loco, ¿verdad?

Cuando le damos una vuelta, primero `p` apunta a `11`. Luego incrementamos `p`, y apunta
a `22`, y luego otra vez, apunta a `33`. Y así sucesivamente, hasta que apunta
a `999` y salimos.

### Restar punteros

[i[Pointers-->subtracting]<]
También puedes restar un valor de un puntero para llegar a una dirección anterior, igual
que antes.

Pero también podemos restar dos punteros para encontrar la diferencia entre ellos, por
ejemplo, podemos calcular cuántos `int`s hay entre dos `int*`s. El problema es que esto
sólo funciona dentro de un array^[O cadena, que en realidad es un array de `char`s.
Curiosamente, también puedes tener un puntero que haga referencia a _uno pasado_ el final
del array sin problema y seguir haciendo cálculos con él]. Si los punteros apuntan
a cualquier otra cosa, se obtiene un comportamiento indefinido.

¿Recuerdas que las cadenas son `char*`s en C? Veamos si podemos usar esto para escribir
otra variante de `strlen()` para calcular la longitud de una cadena que utilice la resta
de punteros.

La idea es que si tenemos un puntero al principio de la cadena, podemos encontrar un puntero
al final de la cadena buscando el carácter `NUL`.

Y si tenemos un puntero al principio de la cadena, y hemos calculado el puntero al final
de la cadena, podemos restar los dos punteros para obtener la longitud de la cadena.

``` {.c .numberLines}
#include <stdio.h>

int my_strlen(char *s)
{
    // Empezar a escanear desde el principio de la cadena
    char *p = s;

    // Escanear hasta encontrar el carácter NUL
    while (*p != '\0')
        p++;

    // Devuelve la diferencia de punteros
    return p - s;
}

int main(void)
{
    printf("%d\n", my_strlen("Hello, world!"));  // Imprime "13"
}
```

Recuerda que sólo puedes utilizar la resta de punteros entre dos punteros que apunten
a la misma matriz.
[i[Pointers-->subtracting]>]

## Equivalencia entre matrices e identificadores {#arraypointerequiv}

[i[Pointers-->array equivalence]<]
¡Por fin estamos listos para hablar de esto! Hemos visto un montón de ejemplos de
lugares donde hemos entremezclado la notación array, pero vamos a dar la _fórmula fundamental de equivalencia array/puntero_:

``` {.c}
a[b] == *(a + b)
```

¡Estudia eso! Son equivalentes y pueden utilizarse indistintamente.

He simplificado un poco, porque en mi ejemplo anterior `a` y `b` pueden ser ambas
expresiones, y podríamos querer algunos paréntesis más para forzar el orden de las
operaciones en caso de que las expresiones sean complejas.

La especificación es específica, como siempre, declarando (en C11 §6.5.2.1¶2):

> `E1[E2]` es idéntico a `(*((E1)+(E2)))`

pero eso es un poco más difícil de entender. Sólo asegúrate de incluir paréntesis
si las expresiones son complicadas para que todas tus matemáticas ocurran en el orden correcto.

Esto significa que podemos _decidir_ si vamos a usar la notación array o puntero
para cualquier array o puntero (asumiendo que apunta a un elemento de un array).

Usemos un array y un puntero con ambas notaciones, array y puntero:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int a[] = {11, 22, 33, 44, 55};

    int *p = a;  // p apunta al primer elemento de a, 11

    // Imprime todos los elementos del array de varias maneras:

    for (int i = 0; i < 5; i++)
        printf("%d\n", a[i]);      // Notación de matriz con a

    for (int i = 0; i < 5; i++)
        printf("%d\n", p[i]);      // Notación de matriz con p

    for (int i = 0; i < 5; i++)
        printf("%d\n", *(a + i));  // Notación de puntero con a

    for (int i = 0; i < 5; i++)
        printf("%d\n", *(p + i));  // Notación de puntero con p

    for (int i = 0; i < 5; i++)
        printf("%d\n", *(p++));    // Puntero móvil p
        //printf("%d\n", *(a++));    // Moviendo la variable de array a--¡ERROR!
}
```

Así que puedes ver que en general, si tienes una variable array, puedes usar puntero
o noción de array para acceder a los elementos. Lo mismo con una variable puntero.

La única gran diferencia es que puedes _modificar_ un puntero para que apunte a una
dirección diferente, pero no puedes hacer eso con una variable array. <!--
6.3.2.1p2 -->

### Equivalencia entre arrays e identificadores en las llamadas a funciones

Aquí es donde más te encontrarás con este concepto.

Si usted tiene una función que toma un argumento puntero, por ejemplo:

``` {.c}
int my_strlen(char *s)
```

esto significa que puedes pasar un array o un puntero a esta función y que funcione.

``` {.c}
char s[] = "Antelopes";
char *t = "Wombats";

printf("%d\n", my_strlen(s));  // Funciona!
printf("%d\n", my_strlen(t));  // Tambien funciona!
```

Y también es la razón por la que estas dos firmas de función son equivalentes:

``` {.c}
int my_strlen(char *s)    // Funciona!
int my_strlen(char s[])   // Tambien funciona!
```
[i[Pointers-->array equivalence]>]

## Punteros `void` 

[i[`void*` void pointer]<]
Ya has visto que la palabra clave `void` se usa con funciones, pero esto es un
animal completamente separado y no relacionado.

A veces es útil tener un puntero a una cosa _de la que no sabes el tipo_.

Lo sé. Ten paciencia conmigo un segundo.

Hay básicamente dos casos de uso para esto.

[i[`memcpy()` function]<]
1. Una función va a operar sobre algo byte a byte. Por ejemplo, `memcpy()` copia
   bytes de memoria de un puntero a otro, pero esos punteros pueden apuntar a cualquier
   tipo. `memcpy()` se aprovecha del hecho de que si iteras a través de `char*`s, estás
   iterando a través de los bytes de un objeto sin importar el tipo del objeto.  Más sobre 
   esto en la subsección [Valores Multibyte](#multibyte-values).

2. Otra función está llamando a una función que tú le pasaste (un callback), y te está
   pasando datos. Tú conoces el tipo de los datos, pero la función que te llama no.
   Así que te pasa `void*`s---porque no conoce el tipo---y tú los conviertes al tipo que
   necesitas. Las funciones incorporadas [fl[`qsort()`|https://beej.us/guide/bgclr/html/split/stdlib.html#man-qsort]] y [fl[`bsearch()`|https://beej.us/guide/bgclr/html/split/stdlib.html#man-bsearch]] utilizan esta técnica.

Veamos un ejemplo, la función incorporada `memcpy()`:

``` {.c}
void *memcpy(void *s1, void *s2, size_t n);
```

Esta función copia `n` bytes a partir de la dirección `s2` en la memoria
a partir de la dirección `s1`.

Pero, ¡mira! ¡`s1` y `s2` son `void*`s! ¿Por qué? ¿Qué significa esto? Veamos más ejemplos.

Por ejemplo, podríamos copiar una cadena con `memcpy()` (aunque `strcpy()` es más
apropiado para cadenas):

``` {.c .numberLines}
#include <stdio.h>
#include <string.h>

int main(void)
{
    char s[] = "Goats!";
    char t[100];

    memcpy(t, s, 7);  // Copia 7 bytes - ¡incluyendo el terminador NUL!

    printf("%s\n", t);  // "Goats!"
}
```

O podemos copiar algunos `int`s:

``` {.c .numberLines}
#include <stdio.h>
#include <string.h>

int main(void)
{
    int a[] = {11, 22, 33};
    int b[3];

    memcpy(b, a, 3 * sizeof(int));  // Copiar 3 ints de datos

    printf("%d\n", b[1]);  // 22
}
```

Esto es un poco salvaje... ¿has visto lo que hemos hecho con `memcpy()`? Copiamos los
datos de `a` a `b`, pero tuvimos que especificar cuántos _bytes_ copiar, y un `int` es
más de un byte.

Bien, entonces... ¿cuántos bytes ocupa un `int`? Respuesta: depende del sistema. Pero
podemos saber cuántos bytes ocupa cualquier tipo con el operador `sizeof`.

Así que.. ahí está la respuesta: un `int` ocupa `sizeof(int)` bytes de memoria para almacenarse.

Y si tenemos 3 de ellos en nuestro array, como en el ejemplo, todo el espacio usado
para los 3 `int`s debe ser `3 * sizeof(int)`.

(En el ejemplo de la cadena, habría sido técnicamente más exacto copiar
`7 * sizeof(char)` bytes. Pero los `char`s son siempre de un byte, por definición,
así que se convierte en `7 * 1`).

Incluso podríamos copiar un `float` o un `struct` con `memcpy()`. (Aunque esto
es abusivo---deberíamos usar `=` para eso):

``` {.c}
struct antelope my_antelope;
struct antelope my_clone_antelope;

// ...

memcpy(&my_clone_antelope, &my_antelope, sizeof my_antelope);
```

¡Mira qué versátil es `memcpy()`! Si tienes un puntero a un origen y un puntero a un destino,
y tienes el número de bytes que quieres copiar, puedes copiar _cualquier tipo de datos_.

Imagina que no tuviéramos `void*`. Tendríamos que escribir funciones `memcpy()` especializadas
para cada tipo:
[i[`memcpy()` function]>]

``` {.c}
memcpy_int(int *a, int *b, int count);
memcpy_float(float *a, float *b, int count);
memcpy_double(double *a, double *b, int count);
memcpy_char(char *a, char *b, int count);
memcpy_unsigned_char(unsigned char *a, unsigned char *b, int count);

// etc... blech!
```

Es mucho mejor usar `void*` y tener una función que lo haga todo.

Ese es el poder de `void*`. Puedes escribir funciones que no se preocupan
por el tipo y aún así son capaces de hacer cosas con él.

Pero un gran poder conlleva una gran responsabilidad. Tal vez no tan grande
en este caso, pero hay algunos límites.

[i[`void*` void pointer-->caveats]<]
1. No se puede hacer aritmética de punteros en un `void*`.

2. No se puede desreferenciar un `void*`.

3. No puedes usar el operador flecha en un `void*`, ya que también es una dereferencia.

4. No puedes usar la notación array en un `void*`, ya que también es una dereferencia
^[Porque recuerda que la notación de array es sólo una una desreferencia y algo
de matemática de punteros, y no puedes desreferenciar un `void*`].

Y si lo piensas, estas reglas tienen sentido. Todas esas operaciones se basan en conocer
el tamaño del tipo de dato apuntado, y con `void*` no sabemos el tamaño del dato apuntado,
¡puede ser cualquier cosa!
[i[`void*` void pointer-->caveats]>]

Pero espera... si no puedes desreferenciar un `void*` ¿de qué te puede servir?

Como con `memcpy()`, te ayuda a escribir funciones genéricas que pueden manejar múltiples
tipos de datos. ¡Pero el secreto es que, en el fondo, _conviertes el `void*` a otro tipo
antes de usarlo_!

Y la conversión es fácil: sólo tienes que asignar a una variable del tipo deseado
^[También puedes _castear_ el `void*` a otro tipo, pero aún no hemos llegado a los castts].

``` {.c}
char a = 'X';  // Un solo carácter

void *p = &a;  // p señala a "X"
char *q = p;   // q también señala a "X"

printf("%c\n", *p);  // ERROR--¡no se puede hacer referencia a void*!
printf("%c\n", *q);  // Imprime "X"
```

[i[`memcpy()` function]<]
Escribamos nuestro propio `memcpy()` para probarlo. Podemos copiar bytes (`char`s), y
sabemos el número de bytes porque se pasa.

``` {.c}
void *my_memcpy(void *dest, void *src, int byte_count)
{
    // Convertir void*s en char*s
    char *s = src, *d = dest;

    // Ahora que tenemos char*s, podemos desreferenciarlos y copiarlos
    while (byte_count--) {
        *d++ = *s++;
    }

    // La mayoría de estas funciones devuelven el destino, por si acaso
    // que sea útil para el que llama.
    return dest;
}
```

Justo al principio, copiamos los `void*`s en `char*`s para poder usarlos como `char*`s.
Así de fácil.

Luego un poco de diversión en un bucle while, donde decrementamos `byte_count` hasta
que se convierte en false (`0`). Recuerda que con el post-decremento, se calcula el valor
de la expresión (para que `while` lo use) y _entonces_ se decrementa la variable.

Y algo de diversión en la copia, donde asignamos `*d = *s` para copiar el byte, pero
lo hacemos con post-incremento para que tanto `d` como `s` se muevan al siguiente byte
después de hacer la asignación.

Por último, la mayoría de las funciones de memoria y cadena devuelven una copia
de un puntero a la cadena de destino por si el que llama quiere utilizarla.

Ahora que hemos hecho esto, sólo quiero señalar rápidamente que podemos utilizar esta técnica
para iterar sobre los bytes de _cualquier_ objeto en C, `float`s, `struct`s, ¡o cualquier cosa!
[i[`memcpy()` function]>]

[i[`qsort()` function]<]
[Vamos]{#qsort-example} a ejecutar un ejemplo más del mundo real con la rutina incorporada
`qsort()` que puede ordenar _cualquier cosa_ gracias a la magia de los `void*`s.

(En el siguiente ejemplo, puede ignorar la palabra `const`, que aún no hemos tratado).

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

// El tipo de estructura que vamos a ordenar
struct animal {
    char *name;
    int leg_count;
};

// Esta es una función de comparación llamada por qsort() para ayudarle a determinar
// qué ordenar exactamente. La usaremos para ordenar un array de struct
// animales por leg_count.
int compar(const void *elem1, const void *elem2)
{
    // Sabemos que estamos ordenando struct animals, así que hagamos ambos
    // argumentos punteros a struct animals
    const struct animal *animal1 = elem1;
    const struct animal *animal2 = elem2;

    // Devolver <0 =0 o >0 dependiendo de lo que queramos ordenar.

    // Vamos a ordenar ascendentemente por leg_count, por lo que
    //devolveremos la diferencia en los leg_counts
    if (animal1->leg_count > animal2->leg_count)
        return 1;
    
    if (animal1->leg_count < animal2->leg_count)
        return -1;

    return 0;
}

int main(void)
{
    // Construyamos un array de 4 struct animals con diferentes
    // características. Este array está desordenado por leg_count, pero
    // lo ordenaremos en un segundo.
    struct animal a[4] = {
        {.name="Dog", .leg_count=4},
        {.name="Monkey", .leg_count=2},
        {.name="Antelope", .leg_count=4},
        {.name="Snake", .leg_count=0}
    };

    // Llama a qsort() para ordenar el array. qsort() necesita saber exactamente
    // qué ordenar estos datos, y lo haremos dentro de la función compar()
    //
    // Esta llamada dice: qsort array a, que tiene 4 elementos, y
    // cada elemento es sizeof(struct animal) bytes grande, y esta es la función
    // que comparará dos elementos cualesquiera.
    qsort(a, 4, sizeof(struct animal), compar);

    // Imprímelos todos
    for (int i = 0; i < 4; i++) {
        printf("%d: %s\n", a[i].leg_count, a[i].name);
    }
}
```

Mientras le des a `qsort()` una función que pueda comparar dos elementos que tengas
en tu array a ordenar, puede ordenar cualquier cosa. Y lo hace sin necesidad de tener
los tipos de los elementos codificados en cualquier lugar. `qsort()` simplemente reordena
bloques de bytes basándose en los resultados de la función `compar()` que le pasaste.
[i[`qsort()` function]>]
[i[`void*` void pointer]>]
[i[Pointers-->arithmetic]>]
