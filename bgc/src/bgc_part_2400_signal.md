<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Manejo de señales

[i[Signal handling]<]

Antes de empezar, voy a aconsejarte que ignores todo este capítulo y utilices las (muy probablemente) superiores funciones de manejo de señales de tu sistema operativo. Los Unix tienen la función [i[`sigaction()` function] `sigaction()`, y Windows tiene... lo que sea que haga^[Aparentemente no hace señales al estilo Unix en el fondo, y son simuladas para aplicaciones de consola].

Una vez aclarado esto, ¿qué son las señales?


## ¿Qué son las señales?

Una _señal_ es _levantada_ en una variedad de eventos externos. Su programa puede ser configurado para ser interrumpido para _manejar_ la señal, y, opcionalmente, continuar donde lo dejó una vez que la señal ha sido manejada.

Piense en ello como una función que se llama automáticamente cuando se produce uno de estos eventos externos.

¿Cuáles son estos eventos? En tu sistema, probablemente haya muchos, pero en la especificación C sólo hay unos pocos:

[i[`SIGABRT` signal]]
[i[`SIGFPE` signal]]
[i[`SIGILL` signal]]
[i[`SIGINT` signal]]
[i[`SIGSEGV` signal]]
[i[`SIGTERM` signal]]

|Signal|Descipción|
|-------|--------------------------------------------------------|
|`SIGABRT`|Terminación anormal---lo que ocurre cuando se llama a `abort()`.|
|`SIGFPE`|Excepción de coma flotante.|
|`SIGILL`|Instrucción ilegal.|
|`SIGINT`|Interrupción: normalmente el resultado de pulsar "CTRL-C".|
|`SIGSEGV`|"Violación de segmentación": acceso inválido a memoria.|
|`SIGTERM`|Terminación solicitada.|

Puede configurar su programa para ignorar, manejar o permitir la acción por defecto para cada uno de ellos utilizando la función `signal()`.

## Manejo de señales con `signal()`.

[i[`signal()` function]<]

La llamada a `signal()` toma dos parámetros: la señal en cuestión, y una acción a tomar cuando esa señal es lanzada.

La acción puede ser una de estas tres cosas:

* Un puntero a una función manejadora.
* [i[`SIG_IGN` macro]<]`SIG_IGN` para ignorar la señal.
* [i[`SIG_DFL` macro]]`SIG_DFL` para restaurar el manejador por defecto de la señal.

Escribamos un programa del que no puedas salir con `CTRL-C`. (No te preocupes--en el siguiente programa, también puedes pulsar `RETURN` y saldrá).

[i[`SIGINT` signal]<]

``` {.c .numberLines}
#include <stdio.h>
#include <signal.h>

int main(void)
{
    char s[1024];

    signal(SIGINT, SIG_IGN);    // Ignorar SIGINT, causado por ^C

    printf("Prueba a pulsar ^C... (pulsa RETURN para salir)\n");

    // Esperar una línea de entrada para que el programa no salga sin más
    fgets(s, sizeof s, stdin);
}
```

Mira la línea 8: le decimos al programa que ignore "SIGINT", la señal de interrupción que se activa cuando se pulsa "CTRL-C". No importa cuánto la pulses, la señal permanece ignorada. Si comentas la línea 8, verás que puedes pulsar `CTRL-C` impunemente y salir del programa en el acto.

[i[`SIGINT` signal]>]
[i[`SIG_IGN` macro]>]

## Escribiendo Manejadores de Señales

He mencionado que también se puede escribir una función manejadora que se llama cuando la señal se eleva.

Estos son bastante sencillos, también son muy limitados en cuanto a la capacidad de la especificación.
[i[`signal()` function]<]

Antes de empezar, veamos el prototipo de función para la llamada `signal()`:

``` {.c}
void (*signal(int sig, void (*func)(int)))(int);
```

Bastante fácil de leer, ¿verdad?

ERROR.

Vamos a desmenuzarlo un poco para practicar.

`signal()` toma dos argumentos: un entero `sig` que representa la señal, y un puntero `func` al manejador (el manejador devuelve `void` y toma un `int` como argumento), resaltado abajo:

``` {.c}
                sig          func
              |-----|  |---------------|
void (*signal(int sig, void (*func)(int)))(int);
```

[i[`signal()` function]>]

Básicamente, vamos a pasar en el número de señal que estamos interesados en la captura, y vamos a pasar un puntero a una función de la forma:

``` {.c}
void f(int x);
```

que hará la captura real.

Ahora... ¿qué pasa con el resto del prototipo? Básicamente es todo el tipo de retorno. Verás, `signal()` devolverá lo que hayas pasado como `func` en caso de éxito... así que eso significa que devuelve un puntero a una función que devuelve `void` y toma un `int` como argumento.

``` {.c}
returned
function    indicates we're              and
returns     returning a                  that function
void        pointer to function          takes an int
|--|        |                                   |---|
void       (*signal(int sig, void (*func)(int)))(int);
```

Además, puede devolver [i[macro `SIG_ERR`]] `SIG_ERR` en caso de error.

Hagamos un ejemplo donde tengamos que pulsar `CTRL-C` dos veces para salir.

Quiero dejar claro que este programa tiene un comportamiento indefinido en un par de formas. Pero probablemente te funcione, y es difícil hacer demos portables no triviales.

[i[`signal()` function]<]
[i[`SIG_INT` signal]<]

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>

int count = 0;

void sigint_handler(int signum)
{
    // El compilador puede funcionar:
    //
    // signal(signum, SIG_DFL)
    //
    // cuando el manejador es llamado. Así que aquí reiniciamos el manejador:
    signal(SIGINT, sigint_handler);

    (void)signum;   // Deshacerse del aviso de variable no utilizada
    count++;                       // Comportamiento indefinido
    printf("Count: %d\n", count);   // Comportamiento indefinido
    if (count == 2) {
        printf("Exiting!\n");       // Comportamiento indefinido
        exit(0);
    }
}

int main(void)
{
    signal(SIGINT, sigint_handler);

    printf("Try hitting ^C...\n");

    for(;;);  // Espera aquí para siempre
}
```

[i[`SIG_INT` signal]>]

Una de las cosas que notarás es que en la línea 14 reiniciamos el manejador de señales. Esto es porque C tiene la opción de resetear el manejador de señales a su [i[`SIG_DFL` macro]] `SIG_DFL` antes de ejecutar tu manejador personalizado. En otras palabras. Así que lo reseteamos a la primera para volver a manejarlo en la siguiente.

Estamos ignorando el valor de retorno de `signal()` en este caso. Si lo hubiéramos puesto antes en un manejador diferente, devolvería un puntero a ese manejador, que podríamos obtener así:

``` {.c}
// old_handler es del tipo "puntero a función que toma un único parámetro
// parámetro int y devuelve void":

void (*old_handler)(int);

old_handler = signal(SIGINT, sigint_handler);
```

[i[`signal()` function]>]

Dicho esto, no estoy seguro de que haya un caso de uso común para esto. Pero si necesitas el antiguo manejador por alguna razón, puedes conseguirlo de esa manera.

Nota rápida sobre la línea 16---es sólo para decirle al compilador que no advierta que no estamos usando esta variable. Es como decir, "Sé que no la estoy usando; no tienes que advertirme".

Y por último verás que he marcado comportamiento indefinido en un par de sitios. Más sobre esto en la siguiente sección.

## ¿Qué podemos hacer realmente?

Resulta que estamos bastante limitados en lo que podemos y no podemos hacer en nuestros manejadores de señales. Esta es una de las razones por las que digo que ni siquiera deberías molestarte con esto y en su lugar utilizar el manejo de señales de tu sistema operativo (por ejemplo, [i[`sigaction()` function]]. `sigaction()` para sistemas tipo Unix).

Wikipedia llega a decir que lo único realmente portable que puedes hacer es llamar a `signal()` con `SIG_IGN` o `SIG_DFL` y ya está.

Esto es lo que **no** podemos hacer de forma portable:

[i[Signal handling--->limitations]<]

* Llama a cualquier función de la biblioteca estándar.
  * Como `printf()`, por ejemplo.
  * Creo que es probablemente seguro llamar a funciones reiniciables/reentrantes, pero la especificación no permite esa libertad.
* Obtener o establecer valores desde una variable local `static`, file scope, o thread-local.
  * A menos que sea un objeto atómico libre de bloqueos o...
  * Estás asignando a una variable de tipo `volatile sig_atomic_t`.

[i[`sig_atomic_t` type]<]

Ese último bit--`sig_atomic_t`--es tu boleto para obtener datos de un manejador de señales. (A menos que quieras usar objetos atómicos sin bloqueo, lo cual está fuera del alcance de esta sección^[Confusamente, `sig_atomic_t` es anterior a los atómicos sin bloqueo y no es lo mismo]). Es un tipo entero que puede o no estar firmado. Y está limitado por lo que puedes poner ahí
Puede consultar los valores mínimo y máximo permitidos en las macros `SIG_ATOMIC_MIN` y `SIG_ATOMIC_MAX`^[Si `sig_action_t` es con signo, el rango será como mínimo de `-127` a `127`. Si es sin signo, al menos de `0` a `255`].

Confusamente, la especificación también dice que no puedes referirte "a ningún objeto con duración de almacenamiento estático o de hilo que no sea un objeto atómico libre de bloqueos que no sea asignando un valor a un objeto declarado como `volatile sig_atomic_t` [...]".

Mi lectura de esto es que no puedes leer o escribir nada que no sea un objeto atómico libre de bloqueo. También puedes asignar a un objeto que es `volatile sig_atomic_t`.

¿Pero puedes leer de él? Honestamente, no veo por qué no, excepto que la especificación es muy específica sobre la mención de asignar a. Pero si tienes que leerlo y tomar cualquier tipo de decisión basándote en ello, podrías estar abriendo espacio para algún tipo de race conditions.

[i[Signal handling--->limitations]>]

Con esto en mente, podemos reescribir nuestro código "pulsa `CTRL-C` dos veces para salir" para que sea un poco más portable, aunque menos verboso en la salida.

Cambiemos nuestro manejador `SIGINT` para que no haga nada excepto incrementar un valor de tipo `volatile sig_atomic_t`. Así contará el número de `CTRL-C`s que han sido pulsados.

Luego, en nuestro bucle principal, comprobaremos si el contador es mayor de `2`, y si es así, lo abandonaremos.

``` {.c .numberLines}
#include <stdio.h>
#include <signal.h>

volatile sig_atomic_t count = 0;

void sigint_handler(int signum)
{
    (void)signum;                    // Aviso de variable no utilizada

    signal(SIGINT, sigint_handler);  // Restablecer manejador de señal

    count++;                         // Comportamiento indefinido
}

int main(void)
{
    signal(SIGINT, sigint_handler);

    printf("Hit ^C twice to exit.\n");

    while(count < 2);
}
```

[i[`sig_atomic_t` type]>]

¿Otra vez comportamiento indefinido? Yo creo que sí, porque tenemos que leer el valor para incrementarlo y almacenarlo.

Si sólo queremos posponer la salida una pulsación de `CTRL-C`, podemos hacerlo sin demasiados problemas. Pero cualquier otro aplazamiento requeriría un encadenamiento de funciones ridículo.

Lo que haremos es manejarlo una vez, y el manejador restablecerá la señal a su comportamiento por defecto (es decir, a la salida):

[i[`SIG_DFL` macro]<]

``` {.c .numberLines}
#include <stdio.h>
#include <signal.h>

void sigint_handler(int signum)
{
    (void)signum;                      // Aviso de variable no utilizada
    signal(SIGINT, SIG_DFL);           // Restablecer manejador de señal
}

int main(void)
{
    signal(SIGINT, sigint_handler);

    printf("Hit ^C twice to exit.\n");

    while(1);
}
```

[i[`SIG_DFL` macro]>]

Más adelante, cuando veamos las variables atómicas sin bloqueo, veremos una forma de arreglar la versión `count` (suponiendo que las variables atómicas sin bloqueo estén disponibles en tu sistema en particular).

Esta es la razón por la que al principio, sugería comprobar el sistema de señales integrado en tu sistema operativo como una alternativa probablemente superior.

## Los amigos no dejan a los amigos `señal()`

De nuevo, usa el manejo de señales integrado en tu sistema operativo o su equivalente. No está en la especificación, no es tan portable, pero probablemente es mucho más capaz. Además, tu sistema operativo probablemente tenga definidas un número de señales que no están en la especificación de C. Y es difícil escribir señales portables. Más adelante, cuando veamos las variables atómicas sin bloqueo, veremos una forma de arreglar la versión `count` (suponiendo que las variables atómicas sin bloqueo estén disponibles en tu sistema en particular).

Esta es la razón por la que al principio, sugería comprobar el sistema de señales integrado en tu sistema operativo como una alternativa probablemente superior.

[i[`signal()` function]>]
[i[Signal handling]>]
