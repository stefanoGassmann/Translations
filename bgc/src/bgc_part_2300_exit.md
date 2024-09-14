<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Salir de un programa

[i[Exiting]<]

Resulta que hay un montón de maneras de hacer esto, e incluso maneras de configurar "ganchos" para que una función se ejecute cuando un programa salga.

En este capítulo nos sumergiremos en ellas y las comprobaremos.

Ya hemos cubierto el significado del código de estado de salida en la sección [Exit Status](#exit-status), así que vuelve allí y repásalo si es necesario.

Todas las funciones de esta sección están en `<stdlib.h>`.


## Salidas normales

Empezaremos con las formas normales de salir de un programa, y luego saltaremos a algunas de las más raras y esotéricas.

Cuando se sale de un programa normalmente, todos los flujos de E/S abiertos se vacían y los archivos temporales se eliminan. Básicamente es una salida agradable donde todo se limpia y se maneja. Es lo que quieres hacer casi todo el tiempo a menos que tengas razones para hacer lo contrario.

### Retorno de `main()`

[i[Exiting-->return from `main()`]<]

Si te has dado cuenta, `main()` tiene un tipo de retorno `int`... y sin embargo rara vez, o nunca, he estado `devolviendo` nada de `main()` en absoluto.

Esto se debe a que `main()` sólo (y no puedo enfatizar lo suficiente este caso especial _sólo_ se aplica a `main()` y a ninguna otra función en ninguna parte) tiene un `return 0` _implícito_ si te caes del final.

Puedes `return` explícitamente desde `main()` cuando quieras, y algunos programadores creen que es más _Correcto_ tener siempre un `return` al final de `main()`. Pero si lo dejas, C pondrá uno por ti.

Así que... aquí están las reglas de `return` para `main()`:

* Puede devolver un estado de salida desde `main()` con una sentencia `return`. `main()` es la única función con este comportamiento especial. Usar `return` en cualquier otra función sólo devuelve desde esa función a quien la llamó.
* Si no se usa `return` explícitamente y se sale al final de `main()`, es como si se hubiera devuelto `0` o `EXIT_SUCCESS`.
[i[Exiting-->return from `main()`]>]

### `exit()`

[i[Exiting-->return from `main()`]>]

Éste también ha aparecido unas cuantas veces. Si llama a `exit()` desde cualquier parte de su programa, éste saldrá en ese punto.

El argumento que pasas a `exit()` es el estado de salida.

### Configuración de los controladores de salida con `atexit()`

[i[`atexit()` function]<]

Puede registrar funciones para ser llamadas cuando un programa sale, ya sea volviendo de `main()` o llamando a la función `exit()`.

Una llamada a `atexit()` con el nombre de la función manejadora lo hará. Puede registrar múltiples manejadores de salida, y serán llamados en el orden inverso al registro.

He aquí un ejemplo:

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

void on_exit_1(void)
{
    printf("¡Controlador de salida 1 llamado!\n");
}

void on_exit_2(void)
{
    printf("¡Controlador de salida 2 llamado!\n");
}

int main(void)
{
    atexit(on_exit_1);
    atexit(on_exit_2);
    
    printf("A punto de salir...\n");
}
```

Y la salida es:

``` {.default}
A punto de salir...
¡Controlador de salida 2 llamado!
¡Controlador de salida 1 llamado!
```

[i[`atexit()` function]>]

## Salidas más rápidas con `quick_exit()`.

[i[`quick_exit()` function]<]

Esto es similar a una salida normal, excepto:

* Los archivos abiertos pueden no ser vaciados.
* Los ficheros temporales pueden no ser eliminados.
* Los manejadores `atexit()` no serán llamados.

Pero hay una forma de registrar manejadores de salida: llame a `at_quick_exit()` de forma análoga a como llamaría a `atexit()`.

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

void on_quick_exit_1(void)
{
    printf("Llamada al gestor de salida rápida 1\n");
}

void on_quick_exit_2(void)
{
    printf("Llamada al gestor de salida rápida 2\n");
}

void on_exit(void)
{
    printf("Salida normal... ¡No me llamarán!\n");
}

int main(void)
{
    at_quick_exit(on_quick_exit_1);
    at_quick_exit(on_quick_exit_2);

    atexit(on_exit);  // Esto no se llamará

    printf("A punto de salir rápidamente...\n");

    quick_exit(0);
}
```

Lo que da esta salida:

``` {.default}
A punto de salir rápidamente...
Llamada al gestor de salida rápida 2
Llamada al gestor de salida rápida 1
```

Funciona igual que `exit()`/`atexit()`, excepto por el hecho de que el vaciado y limpieza de ficheros puede no realizarse.

[i[`quick_exit()` function]>]

## Destrúyelo desde la órbita: `_Exit()`

[i[`_Exit()` function]<]

Llamando a `_Exit()` se sale inmediatamente, punto. No se ejecutan funciones de callback al salir. Los ficheros no se vaciarán. Los ficheros temporales no se eliminan.

Use esto si tiene que salir _ahora mismo_.

## Saliendo a veces: `assert()`

La sentencia `assert()` se utiliza para insistir en que algo sea cierto, o de lo contrario el programa se cerrará.

Los desarrolladores a menudo utilizan un assert para detectar errores del tipo "no debería ocurrir nunca".

``` {.c}
#define PI 3.14159

assert(PI > 3);   // Claro que sí, así que continúa.
```

versus:

``` {.c}
goats -= 100;

assert(goats >= 0);  // No puede tener cabras negativas
```

En ese caso, si intento ejecutarlo y `goats` cae bajo `0`, ocurre esto:

``` {.default}
goat_counter: goat_counter.c:8: main: Assertion `goats >= 0' failed.
Aborted
```

y vuelvo a la línea de comandos.

Esto no es muy fácil de usar, así que sólo se usa para cosas que el usuario nunca verá. Y a menudo la gente [escribe sus propias macros assert que pueden ser desactivadas más fácilmente](#my-assert).

[i[`_Exit()` function]>]

## Salida anormal: `abort()`

[i[`abort()` function]<]

Puedes utilizarlo si algo ha ido terriblemente mal y quieres indicarlo al entorno exterior. Esto tampoco limpiará necesariamente cualquier archivo abierto, etc.

Raramente he visto usar esto.

Puedes utilizarlo si algo ha ido terriblemente mal y quieres indicarlo al entorno exterior. Esto tampoco limpiará necesariamente cualquier archivo abierto, etc.

Rara vez he visto que se utilice.

Un poco de anticipación sobre las _señales_: esto en realidad funciona lanzando una [i[`SIGABRT` signal]] `SIGABRT` que terminará el proceso. 

Lo que suceda después depende del sistema, pero en los Unix, era común [flw[dump core|Core_dump]] cuando el programa terminaba.
[i[`abort()` function]>]
[i[Exiting]>]
