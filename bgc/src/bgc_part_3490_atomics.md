<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Atomics {#chapter-atomics}

> "¿Lo intentaron y fracasaron, todos ellos?">
> "Oh, no." Sacudió la cabeza. "Lo intentaron y murieron."
>
> ---Paul Atreides y la Reverenda Madre Gaius Helen Mohiam, _Dune_

[i[Atomic variables]<]

Este es uno de los aspectos más desafiantes del multithreading con C. Pero intentaremos tomárnoslo con calma.

Básicamente, hablaré de los usos más sencillos de las variables atómicas, qué son, cómo funcionan, etc.  Y mencionaré algunos de los caminos más increíblemente complejos que están a tu disposición.

Pero no voy a ir por esos caminos. No sólo apenas estoy cualificado para escribir sobre ellos, sino que me imagino que si sabes que los necesitas, ya sabes más que yo.

Pero hay algunas cosas raras incluso en lo básico. Así que abróchense los cinturones, porque Kansas se va.

## Pruebas de compatibilidad atómica

[i[`__STDC_NO_ATOMICS__` macro]<]

Los atómicos son opcionales. Hay una macro `__STDC_NO_ATOMICS__` que es `1` si _no_ tienes atómicos.

Esa macro podría no existir antes de C11, así que deberíamos comprobar la versión del lenguaje con `__STDC_VERSION__`^[La macro `__STDC_VERSION__` no existía a principios de C89, así que si estás preocupado por eso, compruébalo con `#ifdef`].

``` {.c}
#if __STDC_VERSION__ < 201112L || __STDC_NO_ATOMICS__ == 1
#define HAS_ATOMICS 0
#else
#define HAS_ATOMICS 1
#endif
```

[i[`__STDC_NO_ATOMICS__` macro]>]

[i[Atomic variables-->compiling with]<]

Si esas pruebas pasan, entonces puedes incluir con seguridad `<stdatomic.h>`, la cabecera en la que se basa el resto de este capítulo. Pero si no hay soporte atómico, puede que esa cabecera ni siquiera exista.

En algunos sistemas, puede que necesites añadir `-latomic` al final de tu línea de comandos de compilación para usar cualquier función del fichero de cabecera.

[i[Atomic variables-->compiling with]>]

## Variables atómicas

Esto es _parte_ de cómo funcionan las variables atómicas:

Si tienes una variable atómica compartida y escribes en ella desde una hebra, esa escritura será _todo o nada_ en otra hebra.

Es decir, el otro proceso verá la escritura completa de, digamos, un valor de 32 bits. No la mitad. No hay forma de que un subproceso interrumpa a otro que está en medio de una escritura atómica multibyte.

Es casi como si hubiera un pequeño bloqueo en torno a la obtención y el establecimiento de esa variable. (¡Y _podría_ haberlo! Ver [Variables atómicas libres de bloqueo](#lock-free-atomic), más abajo).

Y en esa nota, usted puede conseguir lejos con nunca usando atomics si usted utiliza mutexes para trabar sus secciones críticas. Es sólo que hay una clase de _estructuras de datos libres de bloqueo_ que siempre permiten a otros hilos progresar en lugar de ser bloqueados por un mutex... pero son difíciles de crear correctamente desde cero, y son una de las cosas que están más allá del alcance de la guía, lamentablemente.

Eso es sólo una parte de la historia. Pero es la parte con la que empezaremos.

Antes de continuar, ¿cómo se declara que una variable es atómica?

Primero, incluye [i[`stdatomic.h` header]] `<stdatomic.h>`.

[i[`atomic_int` type]<]

Esto nos da tipos como `atomic_int`.

Y entonces podemos simplemente declarar variables para que sean de ese tipo.

Pero hagamos una demostración donde tenemos dos hilos. El primero se ejecuta durante un tiempo y luego establece una variable a un valor específico, luego sale. El otro se ejecuta hasta que ve que el valor se establece, y luego se sale.

``` {.c .numberLines}
#include <stdio.h>
#include <threads.h>
#include <stdatomic.h>

atomic_int x;   // ¡EL PODER DE LA ATOMIC! ¡BWHAHAHA!

int thread1(void *arg)
{
    (void)arg;

    printf("Thread 1: Sleeping for 1.5 seconds\n");
    thrd_sleep(&(struct timespec){.tv_sec=1, .tv_nsec=500000000}, NULL);

    printf("Thread 1: Setting x to 3490\n");
    x = 3490;

    printf("Thread 1: Exiting\n");
    return 0;
}

int thread2(void *arg)
{
    (void)arg;

    printf("Thread 2: Waiting for 3490\n");
    while (x != 3490) {}  // spin here

    printf("Thread 2: Got 3490--exiting!\n");
    return 0;
}

int main(void)
{
    x = 0;

    thrd_t t1, t2;

    thrd_create(&t1, thread1, NULL);
    thrd_create(&t2, thread2, NULL);

    thrd_join(t1, NULL);
    thrd_join(t2, NULL);

    printf("Main    : Threads are done, so x better be 3490\n");
    printf("Main    : And indeed, x == %d\n", x);
}
```

[i[`atomic_int` type]>]

El segundo hilo gira en su lugar, mirando la bandera y esperando a que se establezca en el valor `3490`. Y el primero lo hace.

Y obtengo esta salida:

``` {.default}
Thread 1: Sleeping for 1.5 seconds
Thread 2: Waiting for 3490
Thread 1: Setting x to 3490
Thread 1: Exiting
Thread 2: Got 3490--exiting!
Main    : Threads are done, so x better be 3490
Main    : And indeed, x == 3490
```

¡Mira, ma! ¡Estamos accediendo a una variable desde diferentes hilos y sin usar un mutex! Y eso funcionará siempre gracias a la naturaleza atómica de las variables atómicas.

Te estarás preguntando qué pasa si en vez de eso es un `int` normal no atómico. Bueno, en mi sistema sigue funcionando... a menos que haga una compilación optimizada, en cuyo caso se cuelga en el hilo 2 esperando a que se establezca el 3490^[La razón de esto es que cuando está optimizado, mi compilador ha puesto el valor de `x` en un registro para hacer que el bucle `while` sea rápido. Pero el registro no tiene forma de saber que la variable fue actualizada en otro hilo, así que nunca ve el `3490`. Esto no está realmente relacionado con la parte _todo o nada_ de la atomicidad, sino que está más relacionado con los aspectos de sincronización de la siguiente sección].

Pero esto es sólo el principio de la historia. La siguiente parte va a requerir más poder mental y tiene que ver con algo llamado _sincronización_.

## Sincronización

[i[Atomic variables-->synchronization]<]

La siguiente parte de nuestra historia trata sobre cuándo ciertas escrituras de memoria en un hilo se hacen visibles para las de otro hilo.

Podrías pensar que es inmediatamente, ¿verdad? Pero no es así. Varias cosas pueden ir mal. Raramente mal.

El compilador puede haber reordenado los accesos a memoria de modo que cuando crees que estableces un valor relativo a otro puede no ser cierto. E incluso si el compilador no lo hizo, tu CPU podría haberlo hecho sobre la marcha. O puede que haya algo más en esta arquitectura que haga que las escrituras en una CPU se retrasen antes de ser visibles en otra.

La buena noticia es que podemos condensar todos estos problemas potenciales en uno: los accesos no sincronizados a la memoria pueden aparecer fuera de orden dependiendo del hilo que esté haciendo la observación, como si las propias líneas de código hubieran sido reordenadas.

A modo de ejemplo, ¿qué ocurre primero en el siguiente código, la escritura en `x` o la escritura en `y`?

``` {.c .numberLines}
int x, y;  // global

// ...

x = 2;
y = 3;

printf("%d %d\n", x, y);
```
Respuesta: no lo sabemos. El compilador o la CPU podrían invertir silenciosamente las líneas 5 y 6 y no nos daríamos cuenta. El código se ejecutaría con un único hilo _como si_ se ejecutara en el orden del código.

En un escenario multihilo, podríamos tener algo como este pseudocódigo:

``` {.c .numberLines}
int x = 0, y = 0;

thread1() {
    x = 2;
    y = 3;
}

thread2() {
    while (y != 3) {}  // spin
    printf("x is now %d\n", x);  // 2? ...or 0?
}
```

¿Cuál es la salida del hilo 2?

Bueno, si a `x` se le asigna `2` _antes_ de que a `y` se le asigne `3`, entonces esperaría que la salida fuera la muy sensata:

``` {.default}
x is now 2 
```

Pero algo astuto podría reordenar las líneas 4 y 5 haciendo que veamos el valor de `0` para `x` cuando lo imprimamos.

En otras palabras, todo está perdido a menos que podamos decir de alguna manera: "A partir de este punto, espero que todas las escrituras anteriores en otro hilo sean visibles en este hilo".

Dos hilos _sincronizan_ cuando coinciden en el estado de la memoria compartida. Como hemos visto, no siempre están de acuerdo con el código. Entonces, ¿cómo se ponen de acuerdo?

El uso de variables atómicas puede forzar el acuerdo^[Hasta que diga lo contrario, estoy hablando en general de operaciones _secuencialmente consistentes_. Más sobre lo que eso significa pronto]. Si un hilo escribe en una variable atómica, está diciendo "cualquiera que lea esta variable atómica en el futuro también verá todos los cambios que hice en la memoria (atómica o no) hasta la variable atómica inclusive".

O, en términos más humanos, sentémonos a la mesa de conferencias y asegurémonos de que estamos de acuerdo en qué partes de la memoria compartida contienen qué valores. Estás de acuerdo en que los cambios de memoria que has hecho hasta e incluyendo el almacenamiento atómico serán visibles para mí después de que haga una carga de la misma variable atómica.

Así que podemos arreglar fácilmente nuestro ejemplo:

``` {.c .numberLines}
int x = 0;
atomic int y = 0;  // Make y atomic

thread1() {
    x = 2;
    y = 3;             // Sincronizar al escribir
}

thread2() {
    while (y != 3) {}  // Sincronizar en lectura
    printf("x is now %d\n", x);  // 2, period.
}
```
Como los hilos se sincronizan a través de `y`, todas las escrituras en el hilo 1 que ocurrieron _antes_ de la escritura en `y` son visibles en el hilo 2 _después_ de la lectura de `y` (en el bucle `while`).

Es importante tener en cuenta un par de cosas aquí:

1. Nada duerme. La sincronización no es una operación de bloqueo. Ambos hilos están funcionando a toda máquina hasta que salen. Incluso el que está atascado en el bucle no está bloqueando la ejecución de ningún otro.

2. La sincronización ocurre cuando un hilo lee una variable atómica que otro hilo escribió. Así que cuando el hilo 2 lee `y`, todas las escrituras de memoria anteriores en el hilo 1 (es decir, la configuración de `x`) serán visibles en el hilo 2.

3. Observa que `x` no es atómica. Eso está bien porque no estamos sincronizando sobre `x`, y la sincronización sobre `y` cuando la escribimos en el hilo 1 significa que todas las escrituras previas -incluyendo `x` - en el hilo 1 serán visibles para otros hilos... si esos otros hilos leen `y` para sincronizarse.

Forzar esta sincronización es ineficiente y puede ser mucho más lento que usar una variable normal. Esta es la razón por la que no usamos atomics a menos que sea necesario para una aplicación en particular.

Esto es lo básico. Profundicemos un poco más.

[i[Atomic variables-->synchronization]<]

## Adquirir y Liberar

[i[Atomic variables-->acquire]<]
[i[Atomic variables-->release]<]

Más terminología. Vale la pena aprender esto ahora.

Cuando un hilo lee una variable atómica, se dice que es una operación de _adquisición_.

Cuando un hilo escribe una variable atómica, se dice que es una operación de _liberación_.

¿Qué es esto? Vamos a alinearlas con los términos que ya conoces cuando se trata de variables atómicas:

**Leer = Cargar = Adquirir**. Como cuando comparas una variable atómica o la lees para copiarla a otro valor.

**Escribir = Almacenar = Liberar**. Como cuando asignas un valor a una variable atómica.

Cuando se usan variables atómicas con esta semántica de adquisición/liberación, C especifica qué puede ocurrir cuándo.

La adquisición/liberación es la base de la sincronización de la que acabamos de hablar.

Cuando un hilo adquiere una variable atómica, puede ver los valores establecidos en otro hilo que liberó esa misma variable.

En otras palabras:

Cuando un hilo lee una variable atómica, puede ver los valores establecidos en otro hilo que escribió en esa misma variable.

La sincronización se produce a través del par acquire/release.

Más detalles:

Con lectura/carga/adquisición de una variable atómica particular:

* Todas las escrituras (atómicas o no atómicas) en otro hilo que ocurrieron antes de que ese otro hilo escribiera/almacenara/liberara esta variable atómica son ahora visibles en este hilo.

* El nuevo valor de la variable atómica establecida por el otro hilo también es visible en este hilo.

* Ninguna lectura o escritura de cualquier variable/memoria en el hilo actual puede ser reordenada para ocurrir antes de esta adquisición.

* La adquisición actúa como una barrera unidireccional cuando se trata de reordenar código; las lecturas y escrituras en el hilo actual pueden moverse de _antes_ de la adquisición a _después_ de ella. Pero, más importante para la sincronización, nada puede moverse hacia arriba desde _después_ de la adquisición a _antes_ de ella.

Con escritura/almacenamiento/liberación de una variable atómica particular:

* Todas las escrituras (atómicas o no atómicas) en el subproceso actual que se produjeron antes de esta liberación se vuelven visibles para otros subprocesos que han leído/cargado/adquirido la misma variable atómica.

* El valor escrito en esta variable atómica por este hilo también es visible para otros hilos.

* Ninguna lectura o escritura de cualquier variable/memoria en el hilo actual puede ser reordenada para que ocurra después de esta liberación.

* La liberación actúa como una barrera unidireccional cuando se trata de reordenar código: las lecturas y escrituras en el hilo actual pueden moverse de _después_ de la liberación a _antes_ de ella. Pero, lo que es más importante para la sincronización, nada puede moverse hacia abajo desde _antes_ de la liberación a _después_ de ella.

De nuevo, el resultado es la sincronización de la memoria de un subproceso a otro. El segundo hilo puede estar seguro de que las variables y la memoria se escriben en el orden previsto por el programador.

```
int x, y, z = 0;
atomic_int a = 0;

thread1() {
    x = 10;
    y = 20;
    a = 999;  // Liberación
    z = 30;
}

thread2()
{
    while (a != 999) { } // Adquirir

    assert(x == 10);  // nunca se afirma, x es siempre 10
    assert(y == 20);  // nunca se afirma, y es siempre 20

    assert(z == 0);  // ¡¡podría afirmarlo!!
}
```

En el ejemplo anterior, `thread2` puede estar seguro de los valores de `x` y `y` después de adquirir `a` porque fueron establecidos antes de que `thread1` liberara el atómico `a`.

Pero `thread2` no puede estar seguro del valor de `z` porque ocurrió después de la liberación. Quizás la asignación a `z` se movió antes que la asignación a `a`.

Una nota importante: liberar una variable atómica no tiene efecto sobre las adquisiciones de diferentes variables atómicas. Cada variable está aislada de las demás.

[i[Atomic variables-->acquire]>]
[i[Atomic variables-->release]>]

## Consistencia secuencial

[i[Atomic variables-->sequential consistency]<]
¿Estás aguantando? Estamos a través de la carne de la utilización más simple de atómica. Y como ni siquiera vamos a hablar aquí de los usos más complejos, puedes relajarte un poco.

La consistencia secuencial es lo que se llama un ordenamiento de memoria. Hay muchos ordenamientos de memoria, pero la consistencia secuencial es la más sana^[Más sana desde la perspectiva del programador.] que C tiene para ofrecer. También es la predeterminada. Tienes que salir de tu camino para usar otros ordenamientos de memoria.

Todo lo que hemos estado hablando hasta ahora ha sucedido dentro del ámbito de la consistencia secuencial.

Hemos hablado de cómo el compilador o la CPU pueden reordenar las lecturas y escrituras de memoria en un único hilo siempre que siga la regla _as-if_.

Y hemos visto cómo podemos frenar este comportamiento sincronizando sobre variables atómicas.

Formalicemos un poco más.

Si las operaciones son _secuencialmente consistentes_, significa que al final del día, cuando todo está dicho y hecho, todos los hilos pueden levantar sus pies, abrir su bebida de elección, y todos están de acuerdo en el orden en que los cambios de memoria se produjeron durante la ejecución. Y ese orden es el especificado por el código.

Uno no dirá: "¿Pero _B_ no sucedió antes que _A_?" si el resto dice: "_A_ definitivamente sucedió antes que _B_". Aquí todos son amigos.

En particular, dentro de un hilo, ninguna de las adquisiciones y liberaciones puede reordenarse entre sí. Esto se suma a las reglas sobre qué otros accesos a memoria pueden reordenarse a su alrededor.

Esta regla da un nivel adicional de cordura a la progresión de cargas/adquisiciones y almacenamientos/liberación atómicos.

Cualquier otro orden de memoria en C implica una relajación de las reglas de reordenación, ya sea para adquisiciones/liberaciones u otros accesos a memoria, atómicos o no. Lo harías si _realmente_ supieras lo que estás haciendo y necesitaras el aumento de velocidad. Aquí hay ejércitos de dragones...

Hablaremos de ello más adelante, pero por ahora vamos a ceñirnos a lo seguro y práctico.

[i[Atomic variables-->sequential consistency]>]

## Asignaciones y operadores atómicos

[i[Atomic variables-->assignments and operators]<]

Algunos operadores sobre variables atómicas son atómicos. Y otros no lo son.

Empecemos con un contraejemplo:

``` {.c}
atomic_int x = 0;

thread1() {
    x = x + 3;  // NOT atomic!
}
```

Dado que hay una lectura de `x` a la derecha de la asignación y una escritura efectiva a la izquierda, se trata de dos operaciones. Otro hilo podría colarse en medio y hacerte infeliz.

Pero _puedes_ usar la abreviatura `+=` para obtener una operación atómica:

``` {.c}
atomic_int x = 0;

thread1() {
    x += 3;   // ATOMIC!
}
```

En ese caso, `x` se incrementará atómicamente en `3`--ningún otro hilo puede saltar en medio.

En particular, los siguientes operadores son operaciones atómicas de lectura-modificación-escritura con consistencia secuencial, así que úsalos con alegre abandono. (En el ejemplo, `a` es atómico).

``` {.c}
a++       a--       --a       ++a
a += b    a -= b    a *= b    a /= b    a %= b
a &= b    a |= b    a ^= b    a >>= b   a <<= b
```

[i[Atomic variables-->assignments and operators]>]

## Funciones de biblioteca que se sincronizan automáticamente

[i[Atomic variables-->synchronized library functions]<]

Hasta ahora hemos hablado de cómo se puede sincronizar con variables atómicas, pero resulta que hay algunas funciones de biblioteca que hacen algunas limitadas detrás de las escenas de sincronización, ellos mismos.

``` {.c}
call_once()      thrd_create()       thrd_join()
mtx_lock()       mtx_timedlock()     mtx_trylock()
malloc()         calloc()            realloc()
aligned_alloc()
```

**`call_once()`**---Sincroniza con todas las llamadas posteriores a `call_once()` para una bandera en particular. De esta forma, las llamadas posteriores pueden estar seguras de que si otro hilo establece la bandera, la verán.

**`thrd_create()`**---Sincroniza con el inicio del nuevo hilo, que puede estar seguro de que verá todas las escrituras en memoria compartida del hilo padre desde antes de la llamada a `thrd_create()`.

**`thrd_join()`**Cuando un hilo muere, se sincroniza con esta función. La hebra que ha llamado a `thrd_join()` puede estar segura de que puede ver todas las escrituras compartidas de la hebra fallecida.

**`mtx_lock()`**---Las llamadas anteriores a `mtx_unlock()` en el mismo mutex se sincronizan en esta llamada. Este es el caso que más refleja el proceso de adquisición/liberación del que ya hemos hablado. `mtx_unlock()` realiza una liberación en la variable mutex, asegurando que cualquier hilo posterior que haga una adquisición con `mtx_lock()` pueda ver todos los cambios de memoria compartida en la sección crítica.

**`mtx_timedlock()`** y **`mtx_trylock()`**---Similar a la situación con `mtx_lock()`, si esta llamada tiene éxito, las llamadas anteriores a `mtx_unlock()` se sincronizan con ésta.

**Funciones de memoria dinámica**: si asignas memoria, se sincroniza con la anterior liberación de esa misma memoria. Y las asignaciones y desasignaciones de esa región de memoria en particular ocurren en un único orden total que todos los hilos pueden acordar. Creo que la idea aquí es que la desasignación puede limpiar la región si lo desea, y queremos estar seguros de que una asignación posterior no vea los datos no limpiados. Que alguien me diga si hay algo más.

[i[Atomic variables-->synchronized library functions]>]

## Especificador de Tipo Atómico, Calificador

Bajemos un poco el nivel y veamos qué tipos tenemos disponibles, y cómo podemos incluso crear nuevos tipos atómicos.

[i[`_Atomic` type qualifier]<]

Lo primero es lo primero, echemos un vistazo a los tipos atómicos incorporados y a lo que son `typedef`. (Spoiler: `_Atomic` es un calificador de tipo)

[i[`atomic_bool` type]]
[i[`atomic_char` type]]
[i[`atomic_schar` type]]
[i[`atomic_uchar` type]]
[i[`atomic_short` type]]
[i[`atomic_ushort` type]]
[i[`atomic_int` type]]
[i[`atomic_uint` type]]
[i[`atomic_long` type]]
[i[`atomic_ulong` type]]
[i[`atomic_llong` type]]
[i[`atomic_ullong` type]]
[i[`atomic_char16_t` type]]
[i[`atomic_char32_t` type]]
[i[`atomic_wchar_t` type]]
[i[`atomic_int_least8_t` type]]
[i[`atomic_uint_least8_t` type]]
[i[`atomic_int_least16_t` type]]
[i[`atomic_uint_least16_t` type]]
[i[`atomic_int_least32_t` type]]
[i[`atomic_uint_least32_t` type]]
[i[`atomic_int_least64_t` type]]
[i[`atomic_uint_least64_t` type]]
[i[`atomic_int_fast8_t` type]]
[i[`atomic_uint_fast8_t` type]]
[i[`atomic_int_fast16_t` type]]
[i[`atomic_uint_fast16_t` type]]
[i[`atomic_int_fast32_t` type]]
[i[`atomic_uint_fast32_t` type]]
[i[`atomic_int_fast64_t` type]]
[i[`atomic_uint_fast64_t` type]]
[i[`atomic_intptr_t` type]]
[i[`atomic_uintptr_t` type]]
[i[`atomic_size_t` type]]
[i[`atomic_ptrdiff_t` type]]
[i[`atomic_intmax_t` type]]
[i[`atomic_uintmax_t` type]]

|Atomic type|Longhand equivalent|
|-|-|
|`atomic_bool`|`_Atomic _Bool`|
|`atomic_char`|`_Atomic char`|
|`atomic_schar`|`_Atomic signed char`|
|`atomic_uchar`|`_Atomic unsigned char`|
|`atomic_short`|`_Atomic short`|
|`atomic_ushort`|`_Atomic unsigned short`|
|`atomic_int`|`_Atomic int`|
|`atomic_uint`|`_Atomic unsigned int`|
|`atomic_long`|`_Atomic long`|
|`atomic_ulong`|`_Atomic unsigned long`|
|`atomic_llong`|`_Atomic long long`|
|`atomic_ullong`|`_Atomic unsigned long long`|
|`atomic_char16_t`|`_Atomic char16_t`|
|`atomic_char32_t`|`_Atomic char32_t`|
|`atomic_wchar_t`|`_Atomic wchar_t`|
|`atomic_int_least8_t`|`_Atomic int_least8_t`|
|`atomic_uint_least8_t`|`_Atomic uint_least8_t`|
|`atomic_int_least16_t`|`_Atomic int_least16_t`|
|`atomic_uint_least16_t`|`_Atomic uint_least16_t`|
|`atomic_int_least32_t`|`_Atomic int_least32_t`|
|`atomic_uint_least32_t`|`_Atomic uint_least32_t`|
|`atomic_int_least64_t`|`_Atomic int_least64_t`|
|`atomic_uint_least64_t`|`_Atomic uint_least64_t`|
|`atomic_int_fast8_t`|`_Atomic int_fast8_t`|
|`atomic_uint_fast8_t`|`_Atomic uint_fast8_t`|
|`atomic_int_fast16_t`|`_Atomic int_fast16_t`|
|`atomic_uint_fast16_t`|`_Atomic uint_fast16_t`|
|`atomic_int_fast32_t`|`_Atomic int_fast32_t`|
|`atomic_uint_fast32_t`|`_Atomic uint_fast32_t`|
|`atomic_int_fast64_t`|`_Atomic int_fast64_t`|
|`atomic_uint_fast64_t`|`_Atomic uint_fast64_t`|
|`atomic_intptr_t`|`_Atomic intptr_t`|
|`atomic_uintptr_t`|`_Atomic uintptr_t`|
|`atomic_size_t`|`_Atomic size_t`|
|`atomic_ptrdiff_t`|`_Atomic ptrdiff_t`|
|`atomic_intmax_t`|`_Atomic intmax_t`|
|`atomic_uintmax_t`|`_Atomic uintmax_t`|

[i[`_Atomic` type qualifier]>]

Utilízalos cuando quieras. Son consistentes con los alias atómicos que se encuentran en C++, si eso ayuda.

Pero, ¿y si quieres más?

Puedes hacerlo con un calificador de tipo o un especificador de tipo.

[i[`_Atomic` type specifier]<]

En primer lugar, el especificador. Es la palabra clave `_Atomic` con un tipo en paréntesis después^[Aparentemente C++23 está añadiendo esto como una macro.]---apto para usarse con `typedef`:

``` {.c}
typedef _Atomic(double) atomic_double;

atomic_double f;
```

Restricciones en el especificador: el tipo que está haciendo atómico no puede ser de tipo array o función, ni puede ser atómico o calificado de otra manera.

[i[`_Atomic` type specifier]>]
[i[`_Atomic` type qualifier]<]

Siguiente, ¡calificador! Es la palabra clave `_Atomic` _sin_ un tipo entre paréntesis.

Así que hacen cosas similares^[La especificación señala que pueden diferir en tamaño, representación y alineación]:

``` {.c}
_Atomic(int) i;   // especificador de tipo
_Atomic int  j;   // especificador de tipo
```

Lo que ocurre es que puedes incluir otros calificadores de tipo con este último:

``` {.c}
_Atomic volatile int k;   // variable atómica cualificada
```
Restricciones en el calificador: el tipo que estás haciendo atómico no puede ser de tipo array o función.

[i[`_Atomic` type qualifier]>]

## Variables atómicas sin bloqueo {#lock-free-atomic}

[i[Atomic variables-->lock-free]<]

Las arquitecturas de hardware están limitadas en la cantidad de datos que pueden leer y escribir atómicamente. Depende de cómo esté cableado. Y varía.

Si usas un tipo atómico, puedes estar seguro de que los accesos a ese tipo serán atómicos... pero hay una trampa: si el hardware no puede hacerlo, se hace con un bloqueo, en su lugar.

Así que el acceso atómico se convierte en bloqueo-acceso-desbloqueo, lo que es bastante más lento y tiene algunas implicaciones para los manejadores de señales.

[Banderas atómicas](#atomic-flags), más abajo, es el único tipo atómico que está garantizado que esté libre de bloqueos en todas las implementaciones conformes. En el mundo típico de los ordenadores de sobremesa/portátiles, es probable que otros tipos más grandes no tengan bloqueos.

Afortunadamente, tenemos un par de maneras de determinar si un tipo en particular es atómico libre de bloqueo o no.

En primer lugar, algunas macros---puedes usarlas en tiempo de compilación con `#if`. Se aplican tanto a tipos con signo como sin signo.

[i[`ATOMIC_BOOL_LOCK_FREE` macro]]
[i[`ATOMIC_CHAR_LOCK_FREE` macro]]
[i[`ATOMIC_CHAR16_T_LOCK_FREE` macro]]
[i[`ATOMIC_CHAR32_T_LOCK_FREE` macro]]
[i[`ATOMIC_WCHAR_T_LOCK_FREE` macro]]
[i[`ATOMIC_SHORT_LOCK_FREE` macro]]
[i[`ATOMIC_INT_LOCK_FREE` macro]]
[i[`ATOMIC_LONG_LOCK_FREE` macro]]
[i[`ATOMIC_LLONG_LOCK_FREE` macro]]
[i[`ATOMIC_POINTER_LOCK_FREE` macro]]

|Atomic Type|Lock Free Macro|
|-|-|
|`atomic_bool`|`ATOMIC_BOOL_LOCK_FREE`|
|`atomic_char`|`ATOMIC_CHAR_LOCK_FREE`|
|`atomic_char16_t`|`ATOMIC_CHAR16_T_LOCK_FREE`|
|`atomic_char32_t`|`ATOMIC_CHAR32_T_LOCK_FREE`|
|`atomic_wchar_t`|`ATOMIC_WCHAR_T_LOCK_FREE`|
|`atomic_short`|`ATOMIC_SHORT_LOCK_FREE`|
|`atomic_int`|`ATOMIC_INT_LOCK_FREE`|
|`atomic_long`|`ATOMIC_LONG_LOCK_FREE`|
|`atomic_llong`|`ATOMIC_LLONG_LOCK_FREE`|
|`atomic_intptr_t`|`ATOMIC_POINTER_LOCK_FREE`|

Estas macros pueden tener _tres_ valores diferentes:

|Value|Meaning|
|-|-|
|`0`|Never lock-free.|
|`1`|_Sometimes_ lock-free.|
|`2`|Always lock-free.|

Espera... ¿cómo puede algo estar _a veces_ libre de bloqueos? Esto sólo significa que la respuesta no se conoce en tiempo de compilación, pero podría conocerse en tiempo de ejecución. Tal vez la respuesta varía dependiendo de si se está ejecutando este código en Intel o AMD Genuine, o algo así^[Acabo de sacar ese ejemplo de la nada. Quizás no importe en Intel/AMD, pero podría importar en algún sitio, ¡maldita sea!]

Pero siempre se puede probar en tiempo de ejecución con la  [i[`atomic_is_lock_free()` function]]`atomic_is_lock_free()`. Esta función devuelve verdadero o falso si el tipo en particular es atómico en este momento.

¿Por qué nos importa?

Lock-free es más rápido, así que tal vez hay un problema de velocidad que usted codificaría de otra manera. O quizás necesites usar una variable atómica en un manejador de señales.

[i[Atomic variables-->lock-free]>]

### Manejadores de señales y atómicos sin bloqueo

[i[Signal handlers-->with lock-free atomics]<]
[i[Atomic variables-->with signal handlers]<]

Si lees o escribes una variable compartida (duración de almacenamiento estático o `_Thread_Local`) en un manejador de señales, es un comportamiento indefinido [¡jajaja!]... A menos que hagas una de las siguientes cosas

1. Escribir en una variable de tipo `volatile sig_atomic_t`.

2. Leer o escribir en una variable atómica sin bloqueo.

Hasta donde yo sé, las variables atómicas sin bloqueo son una de las pocas formas de obtener información de un manejador de señales de forma portable.

La especificación es un poco vaga, en mi lectura, sobre el orden de memoria cuando se trata de adquirir o liberar variables atómicas en el manejador de señales. C++ dice, y tiene sentido, que tales accesos no tienen secuencia con respecto al resto del programa^[C++ elabora que si la señal es el resultado de una llamada a  [i[`raise()` function]] `raise()`, se secuencia _después_ de la función `raise()`]. La señal puede ser levantada, después de todo, en cualquier momento. Así que asumo que el comportamiento de C es similar.

[i[Signal handlers-->with lock-free atomics]>]
[i[Atomic variables-->with signal handlers]>]

## Banderas atómicas {#atomic-flags}

[i[Atomic variables-->atomic flags]<]
[i[`atomic_flag` type]<]

Sólo hay un tipo que el estándar garantiza que será un atómico sin bloqueo: `atomic_flag`. Es un tipo opaco para operaciones [flw[test-and-set|Test-and-set]].

Puede ser _set_ o _clear_. Puedes inicializarlo a clear con:

[i[`ATOMIC_FLAG_INIT` macro]<]

``` {.c}
atomic_flag f = ATOMIC_FLAG_INIT;
```

[i[`ATOMIC_FLAG_INIT` macro]>]

[i[`atomic_flag_test_and_set()` function]<]

Puede establecer la bandera atómicamente con `atomic_flag_test_and_set()`, que establecerá la bandera y devolverá su estado anterior como `_Bool` (true para set).

[i[`atomic_flag_clear()` function]<]

Puede borrar la bandera atómicamente con `atomic_flag_clear()`.

Este es un ejemplo en el que initamos la bandera a limpiar, la establecemos dos veces y la volvemos a limpiar.

``` {.c}
#include <stdio.h>
#include <stdbool.h>
#include <stdatomic.h>

atomic_flag f = ATOMIC_FLAG_INIT;

int main(void)
{
    bool r = atomic_flag_test_and_set(&f);
    printf("Value was: %d\n", r);           // 0

    r = atomic_flag_test_and_set(&f);
    printf("Value was: %d\n", r);           // 1

    atomic_flag_clear(&f);
    r = atomic_flag_test_and_set(&f);
    printf("Value was: %d\n", r);           // 0
}
```

[i[`atomic_flag_clear()` function]>]
[i[`atomic_flag_test_and_set()` function]>]
[i[Atomic variables-->atomic flags]>]
[i[`atomic_flag` type]>]

## Estructuras y uniones atómicas(Atomic `struct`s and `union`s)

[i[Atomic variables-->`struct` and `union`]<]

Usando el cualificador o especificador `_Atomic`, ¡puedes hacer `struct`s o `union`s atómicas! Bastante asombroso.

Si no hay muchos datos (por ejemplo, un puñado de bytes), el tipo atómico resultante puede estar libre de bloqueos. Compruébalo con `atomic_is_lock_free()`.

``` {.c .numberLines}
#include <stdio.h>
#include <stdatomic.h>

int main(void)
{
    struct point {
        float x, y;
    };

    _Atomic(struct point) p;

    printf("Is lock free: %d\n", atomic_is_lock_free(&p));
}
```

Aquí está el truco: no puedes acceder a los campos de una `struct` o `union` atómica... ¿entonces qué sentido tiene? Bueno, puedes _copiar_ atómicamente toda la `struct` en una variable no atómica y luego usarla. También puedes copiar atómicamente a la inversa.

``` {.c .numberLines}
#include <stdio.h>
#include <stdatomic.h>

int main(void)
{
    struct point {
        float x, y;
    };

    _Atomic(struct point) p;
    struct point t;

    p = (struct point){1, 2};  // Atomic copy

    //printf("%f\n", p.x);  // Error

    t = p;   // Atomic copy

    printf("%f\n", t.x);  // OK!
}
```

También puede declarar una `estructura` en la que los campos individuales sean atómicos. La implementación define si los tipos atómicos están permitidos en los campos de bits.

[i[Atomic variables-->`struct` and `union`]>]

## Punteros Atómicos

[i[Atomic variables-->pointers]<]

Sólo una nota sobre la colocación de `_Atomic` cuando se trata de punteros.

En primer lugar, los punteros a atómicos (es decir, el valor del puntero no es atómico, pero la cosa a la que apunta sí lo es):

``` {.c}
_Atomic int x;
_Atomic int *p;  // p es un puntero a un int atómico

p = &x;  // OK!
```

En segundo lugar, los punteros atómicos a valores no atómicos (es decir, el valor del puntero en sí es atómico, pero la cosa a la que apunta no lo es):

``` {.c}
int x;
int * _Atomic p;  // p es un puntero atómico a un int

p = &x;  // OK!
```

Por último, punteros atómicos a valores atómicos (es decir, el puntero y la cosa a la que apunta son ambos atómicos):

``` {.c}
_Atomic int x;
_Atomic int * _Atomic p;  // p es un puntero atómico a un int atómico

p = &x;  // OK!
```

[i[Atomic variables-->pointers]>]

## Orden de Memoria

[i[Atomic variables-->memory order]<]
[i[Memory order]<]

Ya hemos hablado de la coherencia secuencial, que es la más sensata de todas. Pero hay muchas otras:

[i[`memory_order_seq_cst` enumerated type]]
[i[`memory_order_acq_rel` enumerated type]]
[i[`memory_order_release` enumerated type]]
[i[`memory_order_acquire` enumerated type]]
[i[`memory_order_consume` enumerated type]]
[i[`memory_order_relaxed` enumerated type]]

|`memory_order`|Description|
|-|-|
|`memory_order_seq_cst`|Sequential Consistency|
|`memory_order_acq_rel`|Acquire/Release|
|`memory_order_release`|Release|
|`memory_order_acquire`|Acquire|
|`memory_order_consume`|Consume|
|`memory_order_relaxed`|Relaxed|

Puede especificar otras con determinadas funciones de biblioteca. Por ejemplo, puedes añadir un valor a una variable atómica así:

``` {.c}
atomic_int x = 0;

x += 5;  // Consistencia secuencial, por defecto
```

O puede hacer lo mismo con esta función de biblioteca:

[i[`atomic_fetch_add()` function]<]

``` {.c}
atomic_int x = 0;

atomic_fetch_add(&x, 5);  // Consistencia secuencial, por defecto
```
[i[`atomic_fetch_add()` function]>]

O puedes hacer lo mismo con una ordenación explícita de la memoria:

[i[`atomic_fetch_add_explicit()` function]<]

``` {.c}
atomic_int x = 0;

atomic_fetch_add_explicit(&x, 5, memory_order_seq_cst);
```

Pero, ¿y si no quisiéramos coherencia secuencial? Y quisieras adquirir / liberar en su lugar por cualquier razón? Sólo dilo:

``` {.c}
atomic_int x = 0;

atomic_fetch_add_explicit(&x, 5, memory_order_acq_rel);
```

[i[`atomic_fetch_add_explicit()` function]>]

A continuación haremos un desglose de los diferentes órdenes de memoria. No te metas con nada que no sea consistencia secuencial a menos que sepas lo que estás haciendo. Es realmente fácil cometer errores que causarán fallos raros y difíciles de reproducir.

### Consistencia Secuencial

[i[Atomic variables-->sequential consistency]<]
[i[Memory order-->sequential consistency]<]

* Adquisición de operaciones de carga (véase más adelante).
* Las operaciones de almacenamiento se liberan (véase más abajo).
* Las operaciones de lectura-modificación-escritura adquieren y luego liberan.

Además, para mantener el orden total de las adquisiciones y liberaciones, ninguna adquisición o liberación se reordenará entre sí. (Las reglas de adquisición/liberación no prohíben reordenar una liberación seguida de una adquisición. Pero las reglas de coherencia secuencial sí lo hacen).

[i[Memory order-->sequential consistency]>]
[i[Atomic variables-->sequential consistency]>]

### Acquire

[i[Atomic variables-->acquire]<]
[i[Memory order-->acquire]<]

Esto es lo que ocurre en una operación de carga/lectura de una variable atómica.

* Si otro hilo liberó esta variable atómica, todas las escrituras que ese hilo hizo son ahora visibles en este hilo.

* Los accesos a memoria en este thread que ocurran después de esta carga no pueden ser reordenados antes.

[i[Memory order-->acquire]>]
[i[Atomic variables-->acquire]>]

### Release

[i[Atomic variables-->release]<]
[i[Memory order-->acquire]<]

Esto es lo que ocurre al almacenar/escribir una variable atómica.

* Si otro hilo adquiere más tarde esta variable atómica, toda la memoria en este hilo antes de su escritura atómica se vuelven visibles para ese otra hebra.

* Los accesos a memoria en este hilo que ocurran antes de la liberación no pueden reordenarse después.

[i[Atomic variables-->release]>]
[i[Memory order-->release]>]

### Consume

[i[Atomic variables-->consume]<]
[i[Memory order-->consume]<]

Esta es una extraña, similar a una versión menos estricta de adquirir. Afecta a los accesos a memoria que son _data dependent_ de la variable atómica.

Ser "dependiente de datos" significa vagamente que la variable atómica se utiliza en un cálculo.

Es decir, si un hilo consume una variable atómica entonces todas las operaciones en ese hilo que utilicen esa variable atómica podrán ver las escrituras de memoria en el hilo que la libera.

Compárese con adquirir donde las escrituras en memoria en el subproceso que libera serán visibles para _todas_ las operaciones en el subproceso actual, no sólo las que dependen de los datos.
las dependientes de datos.

También como en acquire, hay una restricción sobre qué operaciones pueden ser reordenadas _antes_ de consumir. Con acquire, no se podía reordenar nada antes. Con consume, no puedes reordenar nada que dependa del valor atómico cargado antes de él.

[i[Atomic variables-->consume]>]
[i[Memory order-->consume]>]

### Acquire/Release

[i[Atomic variables-->acquire/release]<]
[i[Memory order-->acquire/release]<]

Esto sólo se aplica a las operaciones de lectura-modificación-escritura. Es una adquisición y liberación en uno.

* Una adquisición ocurre para la lectura.
* Una liberación ocurre para la escritura.

[i[Atomic variables-->acquire/release]>]
[i[Memory order-->acquire/release]>]

### Relaxed

[i[Atomic variables-->relaxed]<]
[i[Memory order-->relaxed]<]

Sin reglas; ¡es la anarquía! Perros y gatos viviendo juntos... ¡histeria colectiva!

En realidad, hay una regla. Las lecturas y escrituras atómicas siguen siendo "todo o nada". Pero las operaciones pueden reordenarse caprichosamente y hay cero sincronización entre hilos.

Hay algunos casos de uso para este orden de memoria, que puedes encontrar con un poco de búsqueda, por ejemplo, contadores simples.

Y puedes usar una valla para forzar la sincronización después de un montón de escrituras relajadas.

[i[Atomic variables-->relaxed]>]
[i[Memory order-->relaxed]>]
[i[Memory order]>]
[i[Atomic variables-->memory order]>]

## Fences

[i[Atomic variables-->fences]<]

¿Sabes que las liberaciones y adquisiciones de variables atómicas se producen al leerlas y escribirlas?

Bueno, es posible hacer una liberación o adquisición _sin_ una variable atómica, también.

Esto se llama un _fence_. Así que si quieres que todas las escrituras en un hilo sean visibles en otro lugar, puedes poner una valla de liberación en un hilo y una valla de adquisición en otro, igual que con el funcionamiento de las variables atómicas.

Como una operación consume no tiene sentido en un vallado^[Porque consume se refiere a las operaciones que dependen del valor de la variable atómica adquirida, y no hay variable atómica en un vallado], `memory_order_consume` se trata como una adquisición.

Usted puede poner una cerca con cualquier orden especificado:

[i[`atomic_thread_fence()` function]<]

``` {.c}
atomic_thread_fence(memory_order_release);
```

[i[`atomic_thread_fence()` function]>]
[i[`atomic_signal_fence()` function]<]

También hay una versión ligera de una valla para usar con manejadores de señales, llamada `atomic_signal_fence()`.

Funciona de la misma manera que `atomic_thread_fence()`, excepto que:

* Sólo se ocupa de la visibilidad de valores dentro del mismo hilo; no hay sincronización con otros hilos.

* No se emiten instrucciones hardware fence.

Si quieres estar seguro de que los efectos secundarios de las operaciones no atómicas (y de las operaciones atómicas relajadas) son visibles en el manejador de señales, puedes usar esta valla.

La idea es que el manejador de señales se está ejecutando en _este_ hilo, no en otro, por lo que esta es una forma más ligera de asegurarse de que los cambios fuera del manejador de señales son visibles dentro de él (es decir, que no han sido reordenados).

[i[`atomic_signal_fence()` function]>]
[i[Atomic variables-->fences]>]

## References

Si quieres aprender más sobre este tema, aquí tienes algunas de las cosas que me ayudaron a superarlo:

* Herb Sutter's _`atomic<>` Weapons_ talk:
  * [fl[Part 1|https://www.youtube.com/watch?v=A8eCGOqgvH4]]
  * [fl[part 2|https://www.youtube.com/watch?v=KeLBd2EJLOU]]

* [fl[Jeff Preshing's materials|https://preshing.com/archives/]], in particular:
  * [fl[An Introduction to Lock-Free Programming|https://preshing.com/20120612/an-introduction-to-lock-free-programming/]]
  * [fl[Acquire and Release Semantics|https://preshing.com/20120913/acquire-and-release-semantics/]]
  * [fl[The _Happens-Before_ Relation|https://preshing.com/20130702/the-happens-before-relation/]]
  * [fl[The _Synchronizes-With_ Relation|https://preshing.com/20130823/the-synchronizes-with-relation/]]
  * [fl[The Purpose of `memory_order_consume` in C++11|https://preshing.com/20140709/the-purpose-of-memory_order_consume-in-cpp11/]]
  * [fl[You Can Do Any Kind of Atomic Read-Modify-Write Operation|https://preshing.com/20150402/you-can-do-any-kind-of-atomic-read-modify-write-operation/]]

* CPPReference:
  * [fl[Memory Order|https://en.cppreference.com/w/c/atomic/memory_order]]
  * [fl[Atomic Types|https://en.cppreference.com/w/c/language/atomic]]

* Bruce Dawson's [fl[Lockless Programming Considerations|https://docs.microsoft.com/en-us/windows/win32/dxtecharts/lockless-programming]]

* The helpful and knowledgeable folks on [fl[r/C_Programming|https://www.reddit.com/r/C_Programming/]]

[i[Atomic variables]>]
