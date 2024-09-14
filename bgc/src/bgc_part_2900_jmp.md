<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Saltos largos con `setjmp`, `longjmp` {#setjmp-longjmp}

[i[Long jumps]<]

Ya hemos visto `goto`, que salta en el ámbito de la función. Pero `longjmp()` te permite saltar a un punto anterior en la ejecución, a una función que llamó a ésta.

Hay muchas limitaciones y advertencias, pero puede ser una función útil para saltar desde lo profundo de la pila de llamadas a un estado anterior.

En mi experiencia, esta funcionalidad se utiliza muy raramente.

## Usando `setjmp` y `longjmp`

[i[`setjmp()` function]<]
[i[`longjmp()` function]<]

El baile que vamos a hacer aquí es básicamente poner un marcador en ejecución con `setjmp()`. Más tarde, llamaremos a `longjmp()` y volverá al punto anterior de la ejecución donde pusimos el marcador con `setjmp()`.

Y puede hacer esto incluso si has llamado a subfunciones.

Aquí hay una demostración rápida donde llamamos a funciones de un par de niveles de profundidad y luego salimos de ellas.

Vamos a usar una variable de ámbito de fichero `env` para mantener el _estado_ de las cosas cuando llamemos a `setjmp()` de forma que podamos restaurarlas cuando llamemos a `longjmp()` más tarde. Esta es la variable en la que recordamos nuestro "lugar".

La variable `env` es de tipo `jmp_buf`, un tipo opaco declarado en `<setjmp.h>`.

``` {.c .numberLines}
#include <stdio.h>
#include <setjmp.h>

jmp_buf env;

void depth2(void)
{
    printf("Entering depth 2\n");
    longjmp(env, 3490);           // Libertad bajo fianza
    printf("Leaving depth 2\n");  // Esto no sucederá
}

void depth1(void)
{
    printf("Entering depth 1\n");
    depth2();
    printf("Leaving depth 1\n");  // Esto no sucederá
}

int main(void)
{
    switch (setjmp(env)) {
      case 0:
          printf("Calling into functions, setjmp() returned 0\n");
          depth1();
          printf("Returned from functions\n"); // Esto no sucederá
          break;

      case 3490:
          printf("Bailed back to main, setjmp() returned 3490\n");
          break;
    }
}
```

Cuando se ejecuta, esta salida:

``` {.default}
Calling into functions, setjmp() returned 0
Entering depth 1
Entering depth 2
Bailed back to main, setjmp() returned 3490
```

Si intentas cotejar esa salida con el código, está claro que están pasando cosas realmente _funky_.

Una de las cosas más notables es que `setjmp()` devuelve _twice_. ¿Qué demonios? ¡¿Qué es esta brujería?!

Así que esto es lo que pasa: si `setjmp()` devuelve `0`, significa que has establecido con éxito el "marcador" en ese punto.

Si devuelve un valor distinto de cero, significa que has vuelto al "marcador" establecido anteriormente. (Y el valor devuelto es el que pasas a `longjmp()`.)

De esta forma puedes diferenciar entre establecer el marcador y volver a él más tarde.

Así que cuando el código de arriba llama a `setjmp()` la primera vez, `setjmp()` _almacena_ el estado en la variable `env` y devuelve `0`.  Más tarde, cuando llamamos a `longjmp()` con ese mismo `env`, se restaura el estado y `setjmp()` devuelve el valor que se le pasó a `longjmp()`.

[i[`setjmp()` function]>]
[i[`longjmp()` function]>]

## Errores (Pitfalls)

Bajo el capó, esto es bastante sencillo. Normalmente, el _puntero de pila_ mantiene un registro de las ubicaciones en memoria en las que se almacenan las variables locales, y el _contador de programa_ mantiene un registro de la dirección de la instrucción que se está ejecutando en ese momento^[Tanto el "puntero de pila" como el "contador de programa" están relacionados con la arquitectura subyacente y la implementación de C, y no forman parte de la especificación].

Así que si queremos saltar de nuevo a una función anterior, es básicamente sólo una cuestión de restaurar el puntero de la pila y el contador de programa a los valores guardados en la variable [i[`jmp_buf` type]]. `jmp_buf`, y asegurarse de que el valor de retorno se establece correctamente. Y entonces la ejecución se reanudará allí.

Pero una variedad de factores confunden esto, haciendo un número significativo de trampas de comportamiento indefinido.

### Los valores de las variables locales

[i[`setjmp()` function]<]


Si quieres que los valores de las variables locales automáticas (no `static` y no `extern`) persistan en la función que llamó a `setjmp()` después de que ocurra un [i[`longjmp()`]] `longjmp()`, debe declarar que esas variables son [i[`volatile` type qualifier-->with `setjmp()`]<] `volatile`.

Técnicamente, sólo tienen que ser `volátiles` si cambian entre el momento en que se llama a `setjmp()` y se llama a `longjmp()`^[La razón aquí es que el programa puede almacenar un valor temporalmente en un _registro de la CPU_ mientras está trabajando en él. En ese intervalo de tiempo, el registro contiene el valor correcto, y el valor en la pila podría estar desfasado. Entonces más tarde los valores del registro se sobrescribirían y los cambios en la variable se perderían].

Por ejemplo, si ejecutamos este código

``` {.c}
int x = 20;

if (setjmp(env) == 0) {
    x = 30;
}
```

y luego `longjmp()` de vuelta, el valor de `x` será indeterminado.

Si queremos solucionar esto, `x` debe ser `volátil`:

``` {.c}
volatile int x = 20;

if (setjmp(env) == 0) {
    x = 30;
}
```

[i[`setjmp()` function]>]

[i[`volatile` type qualifier-->with `setjmp()`]>]

Ahora el valor será el correcto `30` después de que un [i[`longjmp()`]] `longjmp()` nos devuelve a este punto.

### ¿Cuánto Estado se ahorra?

[i[`setjmp()` function]<]
[i[`longjmp()` function]<]

Cuando usted `longjmp()`, la ejecución se reanuda en el punto del `setjmp()` correspondiente. Y eso es todo.

[i[`setjmp()` function]>]

La especificación señala que es como si hubieras vuelto a la función en ese punto con las variables locales establecidas a los valores que tenían cuando se hizo la llamada a `longjmp()`.
[i[`longjmp()` function]>]

Las cosas que no se restauran incluyen, parafraseando la especificación:

* Banderas de estado de punto flotante
* Archivos abiertos
* Cualquier otro componente de la máquina abstracta

### No Puedes Nombrar Nada `setjmp`

No puedes tener ningún identificador `extern` con el nombre `setjmp`. O, si `setjmp` es una macro, no puedes redefinirla.

Ambos son comportamientos indefinidos.

### No Puede `setjmp()` en una Expresión Mayor

[i[`setjmp()`-->in an expression]<]

Es decir, no puedes hacer algo así:

``` {.c}
if (x == 12 && setjmp(env) == 0) { ... }
```

Eso es demasiado complejo para que lo permita la especificación debido a las maquinaciones que deben ocurrir al desenrollar la pila y todo eso. No podemos `longjmp()` volver a una expresión compleja que sólo se ha ejecutado parcialmente.

Así que hay límites en la complejidad de esa expresión. 

* Puede ser toda la expresión controladora de la condicional.

  ``` {.c}
  if (setjmp(env)) {...}
  ```

  ``` {.c}
  switch (setjmp(env)) {...}
  ```

* Puede formar parte de una expresión relacional o de igualdad, siempre que el otro operando sea una constante entera. Y el entero es la expresión controladora del condicional.

  ``` {.c}
  if (setjmp(env) == 0) {...}
  ```

* El operando de una operación lógica NOT (`!`), siendo toda la expresión controladora.

  ``` {.c}
  if (!setjmp(env)) {...}
  ```

* Una expresión independiente, posiblemente convertida en `void`.

  ``` {.c}
  setjmp(env);
  ```
  ``` {.c}
  (void)setjmp(env);
  ```

[i[`setjmp()`-->in an expression]>]

### ¿Cuándo no se puede `longjmp()`?

[i[`lonjmp()`]<]

Es un comportamiento indefinido si:

* No has llamado antes a `setjmp()`.
* Llamó a `setjmp()` desde otro thread
* Llamó a `setjmp()` en el ámbito de un array de longitud variable (VLA), y la ejecución dejó el ámbito de ese VLA antes de que `longjmp()` fuera llamado.
* La función que contiene `setjmp()` salió antes de que `longjmp()` fuera llamada.

En este último caso, "salió" incluye los retornos normales de la función, así como el caso de que otro `longjmp()` saltara "antes" en la pila de llamadas que la función en cuestión.

### No se puede pasar `0` a `longjmp()`.

Si intenta pasar el valor `0` a `longjmp()`, cambiará silenciosamente ese valor a `1`.

Dado que `setjmp()` devuelve este valor, y que `setjmp()` devuelve `0` tiene un significado especial, devolver `0` está prohibido.

### `longjmp()` y los Arrays de Longitud Variable

Si estás en el ámbito de un VLA y haces `longjmp()` fuera de él, la memoria asignada al VLA podría tener fugas^[Es decir, permanecer asignada hasta que el programa termine sin que haya forma de liberarla].

Lo mismo ocurre si haces `longjmp()` hacia atrás sobre cualquier función anterior que tuviera VLAs todavía en scope.

Esto es algo que realmente me molestaba de los VLAs---que podías escribir código C perfectamente legítimo que derrochaba memoria. Pero, oye... yo no estoy a cargo de la especificación.

[i[`lonjmp()`]>]
[i[Long jumps]>]
