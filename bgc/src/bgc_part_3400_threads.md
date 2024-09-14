<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Multihilo (Multithreading)

[i[Multithreading]<]

C11 introdujo, formalmente, el multithreading en el lenguaje C. Es muy similar a  [flw[POSIX threads|POSIX_Threads]], si alguna vez los has usado.

Y si no, no te preocupes. Hablaremos de ello.

Sin embargo, ten en cuenta, que no pretendo que esto sea un tutorial completo de multihilo clásico^[Yo soy más un fan de compartir-nada, y mis habilidades con las construcciones de multihilo clásico están oxidadas, por decir algo]; tendrás que coger un libro diferente y muy grueso específicamente para eso. Lo siento.

[i[`__STDC_NO_THREADS__` macro]<]

El roscado es una característica opcional. Si un compilador C11+ define `__STDC_NO_THREADS__`, los hilos **no** estarán presentes en la librería. Por qué decidieron usar un sentido negativo en esa macro es algo que se me escapa, pero ahí estamos.

Puedes comprobarlo así:

``` {.c}
#ifdef __STDC_NO_THREADS__
#error I need threads to build this program!
#endif
```

[i[`__STDC_NO_THREADS__` macro]>]

[i[`gcc` compiler-->with threads]<]

Además, es posible que tenga que especificar ciertas opciones del enlazador durante la compilación. En el caso de los Unix, prueba añadir `-lpthreads` al final de la línea de órdenes para enlazar la librería `pthreads`^[Sí, `pthreads` con "`p`". Es la abreviatura de POSIX threads, una librería de la que C11 tomó prestado libremente para su implementación de hilos]:

``` {.zsh}
gcc -std=c11 -o foo foo.c -lpthreads
```

[i[`gcc` compiler-->with threads]>]

Si obtiene errores del enlazador en su sistema, podría deberse a que no se incluyó la biblioteca apropiada.

## Background

Los hilos son una forma de hacer que todos esos brillantes núcleos de CPU por los que has pagado trabajen para ti en el mismo programa.

Normalmente, un programa en C se ejecuta en un único núcleo de la CPU. Pero si sabes cómo dividir el trabajo, puedes dar partes de él a un número de hilos y hacer que lo hagan simultáneamente.

Aunque la especificación no lo dice, en tu sistema es muy probable que C (o el SO a sus órdenes) intente equilibrar los hilos entre todos los núcleos de la CPU.

Y si tienes más hilos que núcleos, no pasa nada. Simplemente no te darás cuenta de todas esas ganancias si todos ellos están tratando de competir por el tiempo de CPU.

## Cosas que puedes hacer

Puedes crear un hilo. Comenzará a ejecutar la función que especifiques. El hilo padre que lo generó también continuará ejecutándose.

Y puedes esperar a que el hilo se complete. Esto se llama _joining_ (_unirse_).

O si no te importa cuando se complete el hilo y no quieres esperar, puedes _detach it_ (_separarlo_).

Un hilo puede _exit_ (_salir_) explícitamente, o puede llamarlo implícitamente _quits_ (_se retira_) al volver de su función principal.

Un hilo también puede _Sleep_ (_dormir_) durante un periodo de tiempo, sin hacer nada mientras otros hilos se ejecutan.

El programa `main()` también es un hilo.

Además, tenemos almacenamiento local de hilos, mutexes y variables condicionales. Pero hablaremos de ello más adelante.  Por ahora, veamos sólo lo básico.

## Razas de datos y la biblioteca estándar

[i[Multithreading-->and the standard library]<]

Algunas de las funciones de la biblioteca estándar (por ejemplo, `asctime()` y `strtok()`) devuelven o utilizan elementos de datos `static` que no son threadsafe. Pero en general, a menos que se diga lo contrario, la biblioteca estándar hace un esfuerzo para serlo^[Según §7.1.4¶5.].

Pero tenga cuidado. Si una función de la biblioteca estándar mantiene el estado entre llamadas en una variable que no te pertenece, o si una función devuelve un puntero a algo que no has pasado, no es threadsafe.
[i[Multithreading-->and the standard library]>]

## Creando y Esperando Hilos

¡Vamos a hackear algo!

Crearemos algunos hilos (create) y esperaremos a que se completen (join).

Aunque primero tenemos que entender un poco.

Cada hilo se identifica por una variable opaca de tipo 
[i[`thrd_t` type]] `thrd_t`. Es un identificador único por hilo en tu programa. Cuando creas un hilo, se le da un nuevo ID.

También, cuando creas el hilo, tienes que darle un puntero a una función para ejecutar, y un puntero a un argumento para pasarle (o `NULL` si no tienes nada que pasar).

El hilo comenzará la ejecución de la función que especifiques.

Cuando quieras esperar a que un hilo se complete, tienes que especificar su ID de hilo para que C sepa a cuál esperar.

Así que la idea básica es

1. Escribe una función que actúe como "`main`" del hilo. No es `main()` propiamente dicha, pero es análoga a ella. El hilo comenzará a ejecutarse allí.
2. Desde el hilo principal, lanzar un nuevo hilo con  [i[`thrd_create()` function]] `thrd_create()`, y pasarle un puntero a la función a ejecutar.
3. En esa función, haz que el hilo haga lo que tenga que hacer.
4. Mientras tanto, el hilo principal puede seguir haciendo lo que tenga que hacer.
5. Cuando el hilo principal lo decida, puede esperar a que el hilo hijo termine llamando a la función [i[`thrd_join()` function]] . `thrd_join()`. Generalmente **debe** `thrd_join()` el hilo para limpiar después de él o de lo contrario perderá memoria^[A menos que `thrd_detach()`. Más sobre esto más adelante].

[i[`thrd_create()` function]<]
[i[`thrd_start_t` type]<]

`thrd_create()` toma un puntero a la función a ejecutar, y es de tipo `thrd_start_t`, que es `int (*)(void *)`. Esto significa en griego "un puntero a una función que toma un `void*` como argumento, y devuelve un `int`".

[i[`thrd_join()` function]<]

¡Vamos a crear un hilo!  Lo lanzaremos desde el hilo principal con `thrd_create()` para ejecutar una función, hacer algunas otras cosas, y luego esperar a que se complete con `thrd_join()`. He llamado a la función principal del hilo `run()`, pero puedes llamarla como quieras siempre que los tipos coincidan con `thrd_start_t`.

``` {.c .numberLines}
#include <stdio.h>
#include <threads.h>

// Esta es la función que el hilo ejecutará. Puede llamarse cualquier cosa.
//
// arg es el puntero del argumento pasado a `thrd_create()`.
//
// El hilo padre obtendrá el valor de retorno de `thrd_join()`'
// más tarde.

int run(void *arg)
{
    int *a = arg; // Pasaremos un int* desde thrd_create()

    printf("THREAD: Running thread with arg %d\n", *a);

    return 12; // Valor que recogerá thrd_join() (eligió 12 al azar)
}

int main(void)
{
    thrd_t t;  // t contendrá el ID del hilo
    int arg = 3490;

    printf("Launching a thread\n");

    // Lanza un hilo a la función run(), pasando un puntero a 3490
    // como argumento. También almacena el ID del hilo en t:

    thrd_create(&t, run, &arg);

    printf("Hacer otras cosas mientras se ejecuta el hilo\n");

    printf("Esperando a que se complete el hilo...\n");

    int res;  // Mantiene el valor de retorno de la salida del hilo

    // Espera aquí a que el hilo termine; almacena el valor de retorno
    // en res:

    thrd_join(t, &res);

    printf("Thread finalizado con valor de retorno %d\n", res);
}
```

[i[`thrd_start_t` type]>]

¿Ves cómo hicimos el `thrd_create()` allí para llamar a la función `run()`? Luego hicimos otras cosas en `main()` y luego paramos y esperamos a que el hilo se complete con `thrd_join()`.

[i[`thrd_create()` function]>]
[i[`thrd_join()` function]>]

Ejemplos de resultados (los suyos pueden variar):

``` {.default}
Launching a thread
Doing other things while the thread runs
Waiting for thread to complete...
THREAD: Running thread with arg 3490
Thread exited with return value 12
```

La `arg` que pases a la función tiene que tener un tiempo de vida lo suficientemente largo como para que el hilo pueda recogerla antes de que desaparezca. Además, no debe ser sobrescrita por el hilo principal antes de que el nuevo hilo pueda utilizarla.

Veamos un ejemplo que lanza 5 hilos. Una cosa a tener en cuenta aquí es cómo usamos un array de `thrd_t`s para mantener un registro de todos los IDs de los hilos.

[i[`thrd_create()` function]<]
[i[`thrd_join()` function]<]

``` {.c .numberLines}
#include <stdio.h>
#include <threads.h>

int run(void *arg)
{
    int i = *(int*)arg;

    printf("THREAD %d: running!\n", i);

    return i;
}

#define THREAD_COUNT 5

int main(void)
{
    thrd_t t[THREAD_COUNT];

    int i;

    printf("Launching threads...\n");
    for (i = 0; i < THREAD_COUNT; i++)

        // ¡NOTA! En la siguiente línea, pasamos un puntero a i, 
        // pero cada hilo ve el mismo puntero. Así que
        // imprimirán cosas raras cuando i cambie de valor aquí en
        // el hilo principal! (Más en el texto, abajo.)

        thrd_create(t + i, run, &i);

    printf("Doing other things while the thread runs...\n");
    printf("Waiting for thread to complete...\n");

    for (int i = 0; i < THREAD_COUNT; i++) {
        int res;
        thrd_join(t[i], &res);

        printf("Thread %d complete!\n", res);
    }

    printf("All threads complete!\n");
}
```

[i[`thrd_join()` function]>]

Cuando ejecuto los hilos, cuento `i` de 0 a 4. Y le paso un puntero a `thrd_create()`. Este puntero termina en la rutina `run()` donde hacemos una copia del mismo.

[i[`thrd_create()` function]>]

¿Es sencillo? Aquí está el resultado:

``` {.default}
Launching threads...
THREAD 2: running!
THREAD 3: running!
THREAD 4: running!
THREAD 2: running!
Doing other things while the thread runs...
Waiting for thread to complete...
Thread 2 complete!
Thread 2 complete!
THREAD 5: running!
Thread 3 complete!
Thread 4 complete!
Thread 5 complete!
All threads complete!
```

¿Qué...? ¿Dónde está el "HILO 0"? ¿Y por qué tenemos un `THREAD 5` cuando claramente `i` nunca es más de `4` cuando llamamos a `thrd_create()`? ¿Y dos "THREAD 2"? ¡Qué locura!

Esto es entrar en la divertida tierra de [i[Multithreading-->race conditions]] _condiciones de carrera_. El hilo principal está modificando `i` antes de que el hilo tenga la oportunidad de copiarlo. De hecho, `i` llega hasta `5` y termina el bucle antes de que el último hilo tenga la oportunidad de copiarlo.

Tenemos que tener una variable por hilo a la que podamos referirnos para poder pasarla como `arg`.

Podríamos tener un gran array de ellas. O podríamos `malloc()` espacio (y liberarlo en algún lugar - tal vez en el propio hilo.)

Vamos a intentarlo:

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>
#include <threads.h>

int run(void *arg)
{
    int i = *(int*)arg;  // Copia el arg

    free(arg);  // Terminado con esto

    printf("THREAD %d: running!\n", i);

    return i;
}

#define THREAD_COUNT 5

int main(void)
{
    thrd_t t[THREAD_COUNT];

    int i;

    printf("Launching threads...\n");
    for (i = 0; i < THREAD_COUNT; i++) {

        // Obtener espacio para un argumento por hilo:

        int *arg = malloc(sizeof *arg);
        *arg = i;

        thrd_create(t + i, run, arg);
    }

    // ...
```

Observa que en las líneas 27-30 hacemos `malloc()` para un `int` y copiamos el valor de `i` en él. Cada nuevo hilo obtiene su propia variable recién `malloc()` y le pasamos un puntero a la función `run()`.

Una vez que `run()` hace su propia copia de la `arg` en la línea 7, `free()`s la `malloc()` `int`. Y ahora que tiene su propia copia, puede hacer con ella lo que le plazca.

Y una ejecución muestra el resultado:

``` {.default}
Launching threads...
THREAD 0: running!
THREAD 1: running!
THREAD 2: running!
THREAD 3: running!
Doing other things while the thread runs...
Waiting for thread to complete...
Thread 0 complete!
Thread 1 complete!
Thread 2 complete!
Thread 3 complete!
THREAD 4: running!
Thread 4 complete!
All threads complete!
```

¡Allá vamos! ¡Hilos 0-4 todos en efecto!

Tu ejecución puede variar---cómo los hilos se programan para ejecutarse, está más allá de la especificación C. Vemos en el ejemplo anterior que el subproceso 4 ni siquiera comenzó hasta que los subprocesos 0-1 se completaron. De hecho, si ejecuto esto de nuevo, es probable que obtenga resultados diferentes. No podemos garantizar un orden de ejecución de hilos.

## Separación de hilos

Si desea despedir y olvidar un hilo (es decir, para no tener que `thrd_join()` más tarde), puede hacerlo con `thrd_detach()`.

Esto elimina la capacidad de la hebra padre de obtener el valor de retorno de la hebra hija, pero si no te importa eso y sólo quieres que las hebras se limpien bien por sí solas, este es el camino a seguir.

Básicamente vamos a hacer esto:

[i[`thrd_detach()` function]<]

``` {.c}
thrd_create(&t, run, NULL);
thrd_detach(t);
```

donde la llamada a `thrd_detach()` es la hebra padre diciendo, "Hey, no voy a esperar a que esta hebra hija termine con `thrd_join()`. Así que sigue adelante y límpialo por tu cuenta cuando se complete".

``` {.c .numberLines}
#include <stdio.h>
#include <threads.h>

int run(void *arg)
{
    (void)arg;

    //printf("¡Hilo en ejecución! %lu\n", thrd_current()); // ¡no portable!
    printf("Thread running!\n");

    return 0;
}

#define THREAD_COUNT 10

int main(void)
{
    thrd_t t;

    for (int i = 0; i < THREAD_COUNT; i++) {
        thrd_create(&t, run, NULL);
        thrd_detach(t);               // <-- DETACH!
    }

    // Duerme un segundo para que todos los hilos terminen
    thrd_sleep(&(struct timespec){.tv_sec=1}, NULL);
}
```

[i[`thrd_detach()` function]>]

Tenga en cuenta que en este código, ponemos el hilo principal a dormir durante 1 segundo con `thrd_sleep()`---más sobre esto más adelante.

También en la función `run()`, tengo una línea comentada que imprime el ID del hilo como un `unsigned long`. Esto es no-portable, porque la especificación no dice qué tipo es un `thrd_t` bajo el capó---podría ser una `struct` por lo que sabemos. Pero esa línea funciona en mi sistema.

Algo interesante que vi cuando ejecuté el código anterior e imprimí los IDs de los hilos fue que ¡algunos hilos tenían IDs duplicados! Esto parece que debería ser imposible, pero a C se le permite _reutilizar_ los IDs de los hilos después de que el hilo correspondiente haya salido. Así que lo que estaba viendo era que algunos hilos completaban su ejecución antes de que otros hilos fueran lanzados.

## Datos Locales del Hilo

[i[Thread local data]<]

Los hilos son interesantes porque no tienen memoria propia más allá de las variables locales. Si quieres una variable `static` o una variable de ámbito de fichero, todos los hilos verán esa misma variable.

Esto puede conducir a condiciones de carrera, donde se obtienen _Weird Things_™ (_Cosas raras_) sucediendo.

Mira este ejemplo. Tenemos una variable `static` `foo` en el ámbito de bloque en `run()`. Esta variable será visible para todos los hilos que pasen por la función `run()`. Y los distintos hilos pueden pisarse unos a otros.

Cada hilo copia `foo` en una variable local `x` (que no es compartida entre hilos--- todos los hilos tienen sus propias pilas de llamadas). Así que _deberían_ ser iguales, ¿no?

Y la primera vez que los imprimimos, lo son^[Aunque no creo que tengan que serlo. Es sólo que los hilos no parecen ser reprogramados hasta que alguna llamada al sistema como podría ocurrir con un `printf()`... que es por lo que tengo el `printf()` ahí]. Pero justo después de eso comprobamos que siguen siendo los mismos.

Y _normalmente_ lo son. Pero no siempre.

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>
#include <threads.h>

int run(void *arg)
{
    int n = *(int*)arg;  // Número de hilo para que los humanos lo diferencien

    free(arg);

    static int foo = 10;  // Valor estático compartido entre hilos

    int x = foo;  // Variable local automática--cada hilo tiene la suya propia

    // Acabamos de asignar x desde foo, así que más vale que sean iguales aquí.
    // (En todas mis pruebas, lo eran, ¡pero ni siquiera esto está garantizado!)

    printf("Thread %d: x = %d, foo = %d\n", n, x, foo);

    // Y aquí deberían ser iguales, ¡pero no siempre lo son!
    // (¡A veces sí, a veces no!)

    // Lo que pasa es que otro hilo entra e incrementa foo
    // en este momento, ¡pero la x de este thread sigue siendo la que era antes!

    if (x != foo) {
        printf("Thread %d: Craziness! x != foo! %d != %d\n", n, x, foo);
    }

    foo++;  // Incrementar el valor compartido

    return 0;
}

#define THREAD_COUNT 5

int main(void)
{
    thrd_t t[THREAD_COUNT];

    for (int i = 0; i < THREAD_COUNT; i++) {
        int *n = malloc(sizeof *n);  // Contiene un número de serie del hilo
        *n = i;
        thrd_create(t + i, run, n);
    }

    for (int i = 0; i < THREAD_COUNT; i++) {
        thrd_join(t[i], NULL);
    }
}
```

He aquí un ejemplo (aunque varía de una ejecución a otra):

``` {.default}
Thread 0: x = 10, foo = 10
Thread 1: x = 10, foo = 10
Thread 1: Craziness! x != foo! 10 != 11
Thread 2: x = 12, foo = 12
Thread 4: x = 13, foo = 13
Thread 3: x = 14, foo = 14
```

En el hilo 1, entre los dos `printf()`s, el valor de `foo` de alguna manera cambió de `10` a `11`, ¡aunque claramente no hay incremento entre los `printf()`s!

¡Fue otro hilo el que entró ahí (probablemente el hilo 0, por lo que parece) e incrementó el valor de `foo` a espaldas del hilo 1!

Resolvamos este problema de dos maneras diferentes. (Si quieres que todos los hilos compartan la variable _y_ no se pisen unos a otros, tendrás que seguir leyendo la sección [mutex](#mutex)).

###  Clase de almacenamiento `_Thread_local` {#thread-local}

[i[`_Thread_local` storage class]<]

Lo primero es lo primero, veamos la forma más sencilla de evitarlo: la clase de almacenamiento `_Thread_local`.

Básicamente, vamos a ponerla delante de nuestra variable `static` de ámbito de bloque, ¡y todo funcionará! Le dice a C que cada hilo debe tener su propia versión de esta variable, para que ninguno de ellos pise a los demás.
[i[`thread_local` storage class]<]

El [i[`threads.h` header file]] `<threads.h>` define `thread_local` como un alias de `_Thread_local` para que tu código no tenga que verse tan feo.

Tomemos el ejemplo anterior y convirtamos `foo` en una variable `thread_local` para no compartir esos datos.

``` {.c .numberLines startFrom="5"}
int run(void *arg)
{
    int n = *(int*)arg;  // Número de hilo para que los humanos lo diferencien

    free(arg);

    thread_local static int foo = 10;  // <-- ¡¡¡Ya no se comparte!!!
```

Y corriendo llegamos:

``` {.default}
Thread 0: x = 10, foo = 10
Thread 1: x = 10, foo = 10
Thread 2: x = 10, foo = 10
Thread 4: x = 10, foo = 10
Thread 3: x = 10, foo = 10
```

Se acabaron los problemas raros.

Una cosa: si una variable `thread_local` tiene ámbito de bloque, **debe** ser `static`. Esas son las reglas. (Pero esto está bien porque las variables no `static` ya son per-thread ya que cada thread tiene sus propias variables no `static`).

Un poco de mentira: las variables `thread_local` de ámbito de bloque también pueden ser `extern`.

[i[`thread_local` storage class]>]
[i[`_Thread_local` storage class]>]
[i[Thread local data]>]

### Otra opción: Almacenamiento específico de subprocesos

[i[Thread-specific storage]<]

El almacenamiento específico de subprocesos (TSS) es otra forma de obtener datos por subproceso.

Una característica adicional es que estas funciones permiten especificar un destructor que será llamado sobre los datos cuando la variable TSS sea borrada. Comúnmente este destructor es `free()` para limpiar automáticamente los datos por hilo `malloc()`d. O `NULL` si no necesitas destruir nada.

El destructor es de tipo [i[`tss_dtor_t` type]] `tss_dtor_t` que es un puntero a una función que devuelve `void` y toma un `void*` como argumento (el `void*` apunta a los datos almacenados en la variable). En otras palabras, es un `void (*)(void*)`, si eso lo aclara. Que admito que probablemente no. Mira el ejemplo de abajo.

Generalmente, `thread_local` es probablemente tu mejor opción, pero si te gusta la idea del destructor, entonces puedes hacer uso de eso.

El uso es un poco raro en el sentido de que necesitamos una variable de tipo [i[`tss_t` type]] `tss_t` para representar el valor de cada hilo. Luego la inicializamos con [i[`tss_create()` function]] `tss_create()`. Finalmente nos deshacemos de él con [i[`tss_delete()` function]<] `tss_delete()`. Nótese que llamar a `tss_delete()` no ejecuta todos los destructores--es `thrd_exit()` (o volver de la función run) la que lo hace. `tss_delete()` sólo libera la memoria asignada por `tss_create()`. [i[`tss_delete()` function]>]

En el medio, los hilos pueden llamar [i[`tss_set()` function]] `tss_set()` y [i[`tss_get()` function]] `tss_get()` para establecer y obtener el valor.

En el siguiente código, establecemos la variable TSS antes de crear los hilos, y luego limpiamos después de los hilos.

En la función `run()`, los hilos `malloc()` un poco de espacio para una cadena y almacenan ese puntero en la variable TSS.

Cuando el hilo sale, la función destructora (`free()` en este caso) es llamada para _todos_ los hilos.

[i[`tss_t` type]<]
[i[`tss_get()` function]<]
[i[`tss_set()` function]<]
[i[`tss_create()` function]<]
[i[`tss_delete()` function]<]

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>
#include <threads.h>

tss_t str;

void some_function(void)
{
    // Recuperar el valor por hilo de esta cadena
    char *tss_string = tss_get(str);

    // E imprimirlo
    printf("TSS string: %s\n", tss_string);
}

int run(void *arg)
{
    int serial = *(int*)arg;  // Obtener el número de serie de este hilo
    free(arg);

    // malloc() espacio para guardar los datos de este hilo
    char *s = malloc(64);
    sprintf(s, "thread %d! :)", serial);  // Cadena feliz

    // Establece esta variable TSS para que apunte a la cadena
    tss_set(str, s);

    // Llama a una función que obtendrá la variable
    some_function();

    return 0;   // Equivalente a thrd_exit(0)
}

#define THREAD_COUNT 15

int main(void)
{
    thrd_t t[THREAD_COUNT];

    // Crea una nueva variable TSS, la función free() es el destructor
    tss_create(&str, free);

    for (int i = 0; i < THREAD_COUNT; i++) {
        int *n = malloc(sizeof *n);  // Contiene un número de serie del hilo
        *n = i;
        thrd_create(t + i, run, n);
    }

    for (int i = 0; i < THREAD_COUNT; i++) {
        thrd_join(t[i], NULL);
    }

    // Todos los hilos están hechos, así que hemos terminado con esto
    tss_delete(str);
}
```

[i[`tss_t` type]>]
[i[`tss_get()` function]>]
[i[`tss_set()` function]>]
[i[`tss_create()` function]>]
[i[`tss_delete()` function]>]

Una vez más, esta es una forma un poco dolorosa de hacer las cosas en comparación con `thread_local`, así que a menos que realmente necesites esa funcionalidad destructor, yo usaría eso en su lugar.

[i[Thread-specific storage]>]

## Mutexes {#mutex}

[i[Mutexes]<]

Si sólo quieres permitir que un único hilo entre en una sección crítica de código a la vez, puedes proteger esa sección con un mutex^[Abreviatura de "exclusión mutua", alias un "bloqueo" en una sección de código que sólo un hilo puede ejecutar].

Por ejemplo, si tuviéramos una variable `static` y quisiéramos poder obtenerla y establecerla en dos operaciones sin que otro hilo saltara en medio y la corrompiera, podríamos usar un mutex para eso.

Puedes adquirir un mutex o liberarlo. Si intentas adquirir el mutex y tienes éxito, puedes continuar la ejecución. Si lo intentas y fallas (porque alguien más lo tiene), te _bloquearás_^[Es decir, tu proceso entrará en reposo] hasta que el mutex sea liberado.

Si varios hilos están bloqueados esperando a que se libere un mutex, uno de ellos será elegido para ejecutarse (al azar, desde nuestra perspectiva), y los demás seguirán durmiendo.

El plan de juego es que primero inicializaremos una variable mutex para que esté lista para usar con [i[`mtx_init()` function]] `mtx_init()`.

Entonces los hilos subsiguientes pueden llamar a [i[`mtx_lock()` function]] `mtx_lock()` y [i[`mtx_unlock` function]] `mtx_unlock()` para obtener y liberar el mutex.

Cuando hayamos terminado completamente con el mutex, podemos destruirlo con la función [i[`mtx_destroy()` function]] `mtx_destroy()`, el opuesto lógico de [i[`mtx_init()` function]] `mtx_init()`.

[i[Multithreading-->race conditions]<]

Primero, veamos algo de código que _no_ usa un mutex, e intenta imprimir un número de serie compartido (`static`) y luego incrementarlo. Debido a que no estamos usando un mutex sobre la obtención del valor (para imprimirlo) y el ajuste (para incrementarlo), los hilos podrían interponerse en el camino de los demás en esa sección crítica.

``` {.c .numberLines}
#include <stdio.h>
#include <threads.h>

int run(void *arg)
{
    (void)arg;

    static int serial = 0;   // ¡Variable estática compartida!

    printf("Thread running! %d\n", serial);

    serial++;

    return 0;
}

#define THREAD_COUNT 10

int main(void)
{
    thrd_t t[THREAD_COUNT];

    for (int i = 0; i < THREAD_COUNT; i++) {
        thrd_create(t + i, run, NULL);
    }

    for (int i = 0; i < THREAD_COUNT; i++) {
        thrd_join(t[i], NULL);
    }
}
```

Cuando ejecuto esto, obtengo algo parecido a esto:

``` {.default}
Thread running! 0
Thread running! 0
Thread running! 0
Thread running! 3
Thread running! 4
Thread running! 5
Thread running! 6
Thread running! 7
Thread running! 8
Thread running! 9
```

Claramente múltiples hilos están entrando y ejecutando el `printf()` antes de que nadie pueda actualizar la variable `serial`.

[i[Multithreading-->race conditions]>]

Lo que queremos hacer es envolver la obtención de la variable y su establecimiento en un único tramo de código protegido por mutex.

Añadiremos una nueva variable para representar el mutex de tipo [i[`mtx_t` type]] `mtx_t` en el ámbito del fichero, la inicializaremos, y entonces los hilos podrán bloquearla y desbloquearla en la función `run()`.

[i[`mtx_lock()` function]<]
[i[`mtx_unlock()` function]<]
[i[`mtx_init()` function]<]
[i[`mtx_destroy()` function]<]

``` {.c .numberLines}
#include <stdio.h>
#include <threads.h>

mtx_t serial_mtx;     // <-- MUTEX VARIABLE

int run(void *arg)
{
    (void)arg;

    static int serial = 0;   // ¡Variable estática compartida!

    // Adquirir el mutex--todos los hilos se bloquearán en esta llamada hasta que
    // obtengan el bloqueo:

    mtx_lock(&serial_mtx);           // <-- ACQUIRE MUTEX

    printf("Thread running! %d\n", serial);

    serial++;

    // Terminado de obtener y fijar los datos, libera el bloqueo. Esto
    // desbloqueará los hilos en la llamada a mtx_lock():

    mtx_unlock(&serial_mtx);         // <-- RELEASE MUTEX

    return 0;
}

#define THREAD_COUNT 10

int main(void)
{
    thrd_t t[THREAD_COUNT];

    // Inicializar la variable mutex, indicando que esto es un normal
    // sin florituras, mutex:

    mtx_init(&serial_mtx, mtx_plain);        // <-- CREATE MUTEX

    for (int i = 0; i < THREAD_COUNT; i++) {
        thrd_create(t + i, run, NULL);
    }

    for (int i = 0; i < THREAD_COUNT; i++) {
        thrd_join(t[i], NULL);
    }

    // Done with the mutex, destroy it:

    mtx_destroy(&serial_mtx);                // <-- DESTROY MUTEX
}
```

Mira cómo en las líneas 38 y 50 de `main()` inicializamos y destruimos el mutex.

[i[`mtx_init()` function]>]
[i[`mtx_destroy()` function]>]

Pero cada hilo individual adquiere el mutex en la línea 15 y lo libera en la línea 24.

Entre `mtx_lock()` y `mtx_unlock()` está la _sección crítica_, el área de código en la que no queremos que varios hilos se metan al mismo tiempo.

[i[`mtx_lock()` function]>]
[i[`mtx_unlock()` function]>]

Y ahora obtenemos una salida adecuada.

``` {.default}
Thread running! 0
Thread running! 1
Thread running! 2
Thread running! 3
Thread running! 4
Thread running! 5
Thread running! 6
Thread running! 7
Thread running! 8
Thread running! 9
```

Si necesitas múltiples mutexes, no hay problema: simplemente ten múltiples variables mutex.

Y recuerda siempre la Regla Número Uno de los Mutexes Múltiples: Desbloquea los mutex en el orden opuesto al que los bloqueaste.

### Diferentes Tipos de Mutex

[i[Mutexes-->types]<]

Como se ha insinuado antes, tenemos algunos tipos de mutex que puedes crear con `mtx_init()`. (Algunos de estos tipos son el resultado de una operación bitwise-OR, como se indica en la tabla).

[i[Mutexes-->timeouts]<]

[i[`mtx_plain` macro]]
[i[`mtx_timed` macro]]
[i[`mtx_plain` macro]]
[i[`mtx_timed` macro]]
[i[`mtx_recursive` macro]]

|Tipo|Descripción|
|-|-|
|`mtx_plain`|Mutex normal y corriente|
|`mtx_timed`|Mutex que admite tiempos de espera|
|`mtx_plain|mtx_recursive`|Mutex recursivo|
|`mtx_timed|mtx_recursive`|Mutex recursivo que admite tiempos de espera|

"Recursivo" significa que el poseedor de un bloqueo puede llamar a `mtx_lock()` varias veces sobre el mismo bloqueo. (Tienen que desbloquearlo un número igual de veces antes de que alguien más pueda tomar el mutex). Esto puede facilitar la codificación de vez en cuando, especialmente si llamas a una función que necesita bloquear el mutex cuando ya tienes el mutex.

Y el tiempo de espera da a un hilo la oportunidad de _intentar_ obtener el bloqueo durante un tiempo, pero luego abandonarlo si no puede conseguirlo en ese plazo.

[i[`mtx_timed` macro]<]

Para un mutex con tiempo de espera, asegúrate de crearlo con `mtx_timed`:

``` {.c}
mtx_init(&serial_mtx, mtx_timed);
```

[i[`mtx_timed` macro]>]

Y luego, cuando lo esperas, tienes que especificar una hora en UTC en la que se desbloqueará^[Puede que esperaras que fuera "hora a partir de ahora", pero te gustaría pensar eso, ¿verdad?]

[i[`timespec_get()` function]<]

La función `timespec_get()` de `<time.h>` puede ser de ayuda aquí. Te dará la hora actual en UTC en una `struct timespec` que es justo lo que necesitamos. De hecho, parece existir sólo para este propósito.

Tiene dos campos: `tv_sec` tiene el tiempo actual en segundos desde la época, y `tv_nsec` tiene los nanosegundos (milmillonésimas de segundo) como parte "fraccionaria".

Así que puedes cargarlo con el tiempo actual, y luego añadirlo para obtener un tiempo de espera específico.

[i[`mtx_timedlock()` function]<]

Entonces llame a `mtx_timedlock()` en lugar de a `mtx_lock()`. Si devuelve el valor `thrd_timedout`, se ha agotado el tiempo de espera.

``` {.c}
struct timespec timeout;

timespec_get(&timeout, TIME_UTC);  // Obtener la hora actual
timeout.tv_sec += 1;               // Tiempo de espera 1 segundo después de ahora

int result = mtx_timedlock(&serial_mtx, &timeout));

if (result == thrd_timedout) {
    printf("Mutex lock timed out!\n");
}
```

[i[`mtx_timedlock()` function]>]
[i[`timespec_get()` function]>]

Aparte de eso, los bloqueos temporizados son iguales que los bloqueos normales.

[i[Mutexes-->timeouts]>]
[i[Mutexes-->types]>]
[i[Mutexes]>]

## Variables de condición

[i[Condition variables]<]

Las variables de condición son la última pieza del rompecabezas que necesitamos para crear aplicaciones multihilo eficaces y componer estructuras multihilo más complejas.

Una variable de condición proporciona una manera para que los hilos vayan a dormir hasta que ocurra algún evento en otro hilo.

En otras palabras, podemos tener un número de hilos que están listos para empezar, pero tienen que esperar hasta que algún evento se cumpla antes de continuar. Básicamente se les está diciendo "¡esperad!" hasta que se les notifique.

Y esto trabaja mano a mano con mutexes ya que lo que vamos a esperar generalmente depende del valor de algunos datos, y esos datos generalmente necesitan ser protegidos por un mutex.

Es importante tener en cuenta que la variable de condición en sí no es el titular de ningún dato en particular desde nuestra perspectiva. Es simplemente la variable mediante la cual C realiza un seguimiento del estado de espera/no espera de un hilo o grupo de hilos en particular.

Escribamos un programa artificial que lea grupos de 5 números del hilo principal de uno en uno. Entonces, cuando se hayan introducido 5 números, el subproceso hijo se despierta, suma esos 5 números e imprime el resultado.

Los números se almacenarán en una matriz global compartida, al igual que el índice de la matriz del número que se va a introducir.

Como se trata de valores compartidos, al menos tenemos que esconderlos detrás de un mutex tanto para el hilo principal como para el secundario. (El principal escribirá datos en ellos y el hijo los leerá).

Pero eso no es suficiente. El subproceso hijo necesita bloquearse ("dormir") hasta que se hayan leído 5 números en el array. Y entonces la hebra padre tiene que despertar a la hebra hija para que pueda hacer su trabajo.

Y cuando se despierte, necesita mantener ese mutex. Y lo hará. Cuando un hilo espera en una variable de condición, también adquiere un mutex cuando se despierta.

Todo esto tiene lugar alrededor de una variable adicional de tipo [i[`cnd_t` type]] `cnd_t` que es la _variable de condición_. Creamos esta variable con la función [i[`cnd_init()` function]] `cnd_init()` y la destruimos cuando acabemos con ella con la [i[`cnd_destroy()` function]] `cnd_destroy()`.

Pero, ¿cómo funciona todo esto? Veamos el esquema de lo que hará el hilo hijo:

[i[`mtx_lock()` function]<]
[i[`mtx_unlock()` function]<]
[i[`cnd_wait()` function]<]
[i[`cnd_signal()` function]<]

1. Bloquea el mutex con `mtx_lock()`.
2. Si no hemos introducido todos los números, esperar en la variable condición con `cnd_wait()`.
3. Hacer el trabajo que haya que hacer
4. Desbloquear el mutex con `mtx_unlock()`.

Mientras tanto el hilo principal estará haciendo lo siguiente

1. Bloquear el mutex con `mtx_lock()`.
2. Almacenar el número leído recientemente en el array
3. Si el array está lleno, indica al hijo que se despierte con `cnd_signal()`.
4. Desbloquea el mutex con `mtx_unlock()`.

[i[`mtx_lock()` function]>]
[i[`mtx_unlock()` function]>]

Si no lo has ojeado demasiado (no pasa nada, no me ofendo), puede que notes algo raro: ¿cómo puede el hilo principal mantener el bloqueo mutex y enviar una señal al hijo, si el hijo tiene que mantener el bloqueo mutex para esperar la señal? No pueden mantener ambos el bloqueo.

Y de hecho no lo hacen. Hay algo de magia entre bastidores con las variables de condición: cuando `cnd_wait()`, libera el mutex que especifiques y el hilo se va a dormir. Y cuando alguien indica a ese hilo que se despierte, vuelve a adquirir el bloqueo como si nada hubiera pasado.

Es un poco diferente en el lado `cnd_signal()` de las cosas. Esto no hace nada con el mutex. La hebra señalizadora aún debe liberar manualmente el mutex antes de que las hebras en espera puedan despertarse.

[i[`cnd_signal()` function]>]

Una cosa más sobre `cnd_wait()`. Probablemente llame a `cnd_wait()` si alguna condición^[¡Y por eso se llaman _variables de condición_!] aún no se cumple (por ejemplo, en este caso, si aún no se han introducido todos los números). Este es el problema: esta condición debería estar en un bucle `while`, no en una sentencia `if`. ¿Por qué?

Por un misterioso fenómeno llamado [i[Condition variables-->spurious wakeup]]  _spurious wakeup_. A veces, en algunas implementaciones, un hilo puede ser despertado de una suspensión `cnd_wait()` aparentemente _sin razón_ _[X-Files music]_. No digo que sean aliens... pero son aliens. Vale, en realidad es más probable que otro hilo se haya despertado y haya llegado al trabajo primero]. Y así tenemos que comprobar que la condición que necesitamos todavía se cumple cuando nos despertamos. Y si no es así, ¡a dormir!
[i[`cnd_wait()` function]>]

Así que ¡manos a la obra! Empezando por el hilo principal:

* El hilo principal creará el mutex y la variable condición, y lanzará el hilo hijo.

* Luego, en un bucle infinito, obtendrá números de la consola.

* También adquirirá el mutex para almacenar los números introducidos en un array global.

* Cuando el array tenga 5 números, la hebra principal indicará a la hebra hija que es hora de despertar y hacer su trabajo.

* Entonces el hilo principal desbloqueará el mutex y volverá a leer el siguiente número de la consola.

Mientras tanto, el subproceso hijo ha estado haciendo sus propias travesuras:

* El hilo hijo toma el mutex

* Mientras no se cumpla la condición (es decir, mientras el array compartido no tenga todavía 5 números), la hebra hija duerme esperando en la variable de condición. Cuando espera, implícitamente desbloquea el mutex.

* Una vez que el hilo principal indica al hilo hijo que se despierte, éste se despierta para hacer el trabajo y recupera el bloqueo mutex.

* El subproceso hijo suma los números y restablece la variable que es el índice en la matriz.

* Entonces libera el mutex y se ejecuta de nuevo en un bucle infinito.

Y aquí está el código. Estudialo un poco para que puedas ver donde se manejan todas las piezas anteriores:

[i[`mtx_lock()` function]<]
[i[`mtx_unlock()` function]<]
[i[`mtx_init()` function]<]
[i[`mtx_destroy()` function]<]
[i[`cnd_init()` function]<]
[i[`cnd_destroy()` function]<]
[i[`cnd_wait()` function]<]
[i[`cnd_signal()` function]<]
[i[`cnd_t` type]<]

``` {.c .numberLines}
#include <stdio.h>
#include <threads.h>

#define VALUE_COUNT_MAX 5

int value[VALUE_COUNT_MAX];  // Global compartido
int value_count = 0;   // Global compartido, también

mtx_t value_mtx;   // Mutex alrededor del valor
cnd_t value_cnd;   // Condicionar la variable al valor

int run(void *arg)
{
    (void)arg;

    for (;;) {
        mtx_lock(&value_mtx);      // <-- GRAB THE MUTEX

        while (value_count < VALUE_COUNT_MAX) {
            printf("Thread: is waiting\n");
            cnd_wait(&value_cnd, &value_mtx);  // <-- CONDITION WAIT
        }

        printf("Thread: is awake!\n");

        int t = 0;

        // Add everything up
        for (int i = 0; i < VALUE_COUNT_MAX; i++)
            t += value[i];

        printf("Thread: total is %d\n", t);

        // Reset input index for main thread
        value_count = 0;

        mtx_unlock(&value_mtx);   // <-- MUTEX UNLOCK
    }

    return 0;
}

int main(void)
{
    thrd_t t;

    // Crear un nuevo tema

    thrd_create(&t, run, NULL);
    thrd_detach(t);

    // Configurar el mutex y la variable de condición

    mtx_init(&value_mtx, mtx_plain);
    cnd_init(&value_cnd);

    for (;;) {
        int n;

        scanf("%d", &n);

        mtx_lock(&value_mtx);    // <-- LOCK MUTEX

        value[value_count++] = n;

        if (value_count == VALUE_COUNT_MAX) {
            printf("Main: signaling thread\n");
            cnd_signal(&value_cnd);  // <-- SIGNAL CONDITION
        }

        mtx_unlock(&value_mtx);  // <-- UNLOCK MUTEX
    }

    // Limpiar (Sé que es un bucle infinito aquí arriba, pero yo
    // quiero al menos pretender ser correcto):

    mtx_destroy(&value_mtx);
    cnd_destroy(&value_cnd);
}
```

[i[`mtx_lock()` function]>]
[i[`mtx_unlock()` function]>]
[i[`mtx_init()` function]>]
[i[`mtx_destroy()` function]>]
[i[`cnd_init()` function]>]
[i[`cnd_destroy()` function]>]
[i[`cnd_wait()` function]>]
[i[`cnd_signal()` function]>]
[i[`cnd_t` type]>]

Y aquí hay algunos ejemplos de salida (los números individuales en las líneas son mis entradas):

``` {.default}
Thread: is waiting
1
1
1
1
1
Main: signaling thread
Thread: is awake!
Thread: total is 5
Thread: is waiting
2
8
5
9
0
Main: signaling thread
Thread: is awake!
Thread: total is 24
Thread: is waiting
```

Es un uso común de las variables de condición en situaciones productor-consumidor como ésta. Si no tuviéramos una forma de poner el hilo hijo a dormir mientras espera a que se cumpla alguna condición, se vería forzado a sondear, lo cual es un gran desperdicio de CPU.

### Timed Condition Wait

[i[Condition variables-->timeouts]<]

Hay una variante de `cnd_wait()` que permite especificar un tiempo de espera para que pueda dejar de esperar.

Dado que el subproceso hijo debe volver a bloquear el mutex, esto no significa necesariamente que vaya a volver a la vida en el instante en que se produce el tiempo de espera; todavía debe esperar a que cualquier otro subproceso libere el mutex.

Pero sí significa que no estarás esperando hasta que ocurra la `cnd_signal()`.

Para que esto funcione, llame a la función [i[`cnd_timedwait()` function]] `cnd_timedwait()` en lugar de `cnd_wait()`. Si devuelve el valor [i[`thrd_timedout` macro]] `thrd_timedout`, se ha agotado el tiempo de espera.

La marca de tiempo es un tiempo absoluto en UTC, no un tiempo-desde-ahora. Gracias a la función [i[`timespec_get()` function]] `timespec_get()` en `<time.h>` parece hecha a medida exactamente para este caso.

[i[`timespec_get()` function]<]
[i[`cnd_timedwait()` function]<]
[i[`thrd_timedout()` macro]<]

``` {.c}
struct timespec timeout;

timespec_get(&timeout, TIME_UTC);  // Obtener la hora actual
timeout.tv_sec += 1;               // Tiempo de espera 1 segundo después de ahora

int result = cnd_timedwait(&condition, &mutex, &timeout));

if (result == thrd_timedout) {
    printf("Condition variable timed out!\n");
}
```

[i[`timespec_get()` function]>]
[i[`cnd_timedwait()` function]>]
[i[`thrd_timedout()` macro]>]
[i[Condition variables-->timeouts]>]

### Broadcast: Despertar todos los hilos en espera

[i[Condition variables-->broadcasting]<]

`cnd_signal()` function]] `cnd_signal()` only wakes up one thread to
continue working. Depending on how you have your logic done, it might
make sense to wake up more than one thread to continue once the
condition is met.

Of course only one of them can grab the mutex, but if you have a
situation where:

* The newly-awoken thread is responsible for waking up the next one,
  and---

* There's a chance the spurious-wakeup loop condition will prevent it
  from doing so, then---

you'll want to broadcast the wake up so that you're sure to get at least
one of the threads out of that loop to launch the next one.

How, you ask?

[i[`cnd_broadcast()` function]<]

Simply use `cnd_broadcast()` instead of `cnd_signal()`. Exact same
usage, except `cnd_broadcast()` wakes up **all** the sleeping threads
that were waiting on that condition variable.

[i[`cnd_broadcast()` function]>]
[i[Condition variables-->broadcasting]>]
[i[Condition variables]>]

## Running a Function One Time

[i[Multithreading-->one-time functions]<]

Let's say you have a function that _could_ be run by many threads, but
you don't know when, and it's not work trying to write all that logic.

There's a way around it: use [i[`call_once()` function]] `call_once()`.
Tons of threads could try to run the function, but only the first one
counts^[Survival of the fittest! Right? I admit it's actually nothing
like that.]

To work with this, you need a special flag variable you declare to keep
track of whether or not the thing's been run. And you need a function to
run, which takes no parameters and returns no value.

[i[`once_flag` type]<]
[i[`ONCE_FLAG_INIT` macro]<]
[i[`call_once()` function]<]

``` {.c}
once_flag of = ONCE_FLAG_INIT;  // Initialize it like this

void run_once_function(void)
{
    printf("I'll only run once!\n");
}

int run(void *arg)
{
    (void)arg;

    call_once(&of, run_once_function);

    // ...
```

[i[`once_flag` type]>]
[i[`ONCE_FLAG_INIT` macro]>]
[i[`call_once()` function]>]

In this example, no matter how many threads get to the `run()`
function, the `run_once_function()` will only be called a single time.

[i[Multithreading-->one-time functions]>]
[i[Multithreading]>]
