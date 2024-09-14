<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# `goto`

[i[`goto` statement]<]

La afirmación `goto` es universalmente venerada y puede presentarse aquí sin impugnación.

Es broma. A lo largo de los años, ha habido muchas idas y venidas sobre si `goto` es o no (a menudo no) [flw[considerado dañino|Goto#Criticism]].

En opinión de este programador, deberías usar cualquier construcción que conduzca al _mejor_ código, teniendo en cuenta la mantenibilidad y la velocidad. ¡Y a veces esto puede ser `goto`!

En este capítulo, veremos cómo funciona `goto` en C, y luego comprobaremos algunos de los casos comunes en los que se usa^[Me gustaría señalar que usar `goto` en todos estos casos es evitable. Puedes usar variables y bucles en su lugar. Es sólo que algunas personas piensan que `goto` produce el _mejor_ código en esas circunstancias].

## Un ejemplo sencillo

[i[Labels]<]

En este ejemplo, vamos a utilizar `goto` para saltar una línea de código y saltar a una _etiqueta_. La etiqueta es el identificador que puede ser un objetivo de `goto`; termina con dos puntos (`:`).

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    printf("One\n");
    printf("Two\n");

    goto skip_3;

    printf("Three\n");

skip_3:

    printf("Five!\n");
}
```

La salida es :

``` {.default}
One
Two
Five!
```

`goto` envía la ejecución saltando a la etiqueta especificada, saltándose todo lo que hay entre medias.

Puedes saltar hacia delante o hacia atrás con `goto`.

``` {.c}
infinite_loop:
    print("Hello, world!\n");
    goto infinite_loop;
```

Las etiquetas se omiten durante la ejecución. Lo siguiente imprimirá los tres números en orden como si las etiquetas no estuvieran allí:

``` {.c}
    printf("Zero\n");
label_1:
label_2:
    printf("One\n");
label_3:
    printf("Two\n");
label_4:
    printf("Three\n");
```

Como habrá notado, es una convención común justificar las etiquetas hasta el final a la izquierda. Esto aumenta la legibilidad porque un lector puede escanear rápidamente para encontrar el destino.

Las etiquetas tienen _alcance de función_. Es decir, no importa a cuántos niveles de profundidad en los bloques aparezcan, puedes "ir a ellas" desde cualquier parte de la función.

También significa que sólo se puede "ir a" las etiquetas que están en la misma función que la propia "ir a". Las etiquetas de otras funciones están fuera del alcance de `goto`. Y significa que puedes usar el mismo nombre de etiqueta en dos funciones, pero no en la misma función.
[i[Labels]>]

## Etiqueta `continue`

[i[`goto` statement-->as labeled `continue`]<]

En algunos lenguajes, puedes especificar una etiqueta para una sentencia `continue`. C no lo permite, pero puedes usar `goto` en su lugar.

Para mostrar el problema, mira `continue` en este bucle anidado:

``` {.c}
for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
        printf("%d, %d\n", i, j);
        continue;   // Siempre pasa al siguiente j
    }
}
```

Como vemos, ese `continue`, como todos los `continues`, va a la siguiente iteración del bucle más cercano. ¿Y si queremos `continuar` en el siguiente bucle exterior, el bucle con `i`?

Bueno, podemos `break` para volver al bucle exterior, ¿no?

``` {.c}
for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
        printf("%d, %d\n", i, j);
        break;     // Nos lleva a la siguiente iteración de i
    }
}
```

Eso nos da dos niveles de bucle anidado. Pero si anidamos otro bucle, nos quedamos sin opciones. ¿Qué pasa con esto, donde no tenemos ninguna declaración que nos llevará a la siguiente iteración de `i`?

``` {.c}
for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
        for (int k = 0; k < 3; k++) {
            printf("%d, %d, %d\n", i, j, k);

            continue;  // Nos lleva a la siguiente iteración de k
            break;     // Nos lleva a la siguiente iteración de j
            ????;      // Nos lleva a la siguiente iteración de i???

        }
    }
}
```

¡La sentencia `goto` nos ofrece un camino!

``` {.c}
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            for (int k = 0; k < 3; k++) {
                printf("%d, %d, %d\n", i, j, k);

                goto continue_i;   // ¡¡¡Ahora continuando el bucle i!!!
            }
        }
continue_i: ;
    }
```

Tenemos un `;` al final---eso es porque no se puede tener una etiqueta apuntando al final plano de una sentencia compuesta (o antes de una declaración de variable).

[i[`goto` statement-->as labeled `continue`]>]

## Libertad bajo fianza

[i[`goto` statement-->for bailing out]<]

Cuando estás super anidado en medio de algún código, puedes usar `goto` para salir de él de una manera que a menudo es más limpia que anidar más `if`s y usar variables flag.

``` {.c}
    // Pseudocode

    for(...) {
        for (...) {
            while (...) {
                do {
                    if (some_error_condition)
                        goto bail;

                } while(...);
            }
        }
    }

bail:
    // Limpieza aquí
```

Sin `goto`, tendrías que comprobar una bandera de condición de error en todos los bucles para llegar hasta el final.

[i[`goto` statement-->for bailing out]>]

## Etiqueta `break`

[i[`goto` statement-->as labeled `break`]<]

Esta situación es muy similar a la de `continue`, que sólo continúa el bucle más interno. También `break` sólo sale del bucle más interno.

``` {.c}
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            printf("%d, %d\n", i, j);
            break;   // Sólo sale del bucle j
        }
    }

    printf("Done!\n");
```

Pero podemos usar `goto` para ir más lejos:

``` {.c}
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
            printf("%d, %d\n", i, j);
            goto break_i;   // ¡Ahora saliendo del bucle i!
        }
    }

break_i:

    printf("Done!\n");
```

[i[`goto` statement-->as labeled `break`]>]

## Limpieza multinivel
[i[`goto` statement-->multilevel cleanup]<]

Si estás llamando a varias funciones para inicializar varios sistemas y una de ellas falla, sólo debes desinicializar los que hayas conseguido hasta el momento.

Hagamos un ejemplo falso en el que empezamos a inicializar sistemas y comprobamos si alguno devuelve un error (usaremos `-1` para indicar un error). Si alguno lo hace, tenemos que apagar sólo los sistemas que hemos inicializado hasta ahora.

``` {.c}
    if (init_system_1() == -1)
        goto shutdown;

    if (init_system_2() == -1)
        goto shutdown_1;

    if (init_system_3() == -1)
        goto shutdown_2;

    if (init_system_4() == -1)
        goto shutdown_3;

    do_main_thing();   // Ejecutar nuestro programa

    shutdown_system4();

shutdown_3:
    shutdown_system3();

shutdown_2:
    shutdown_system2();

shutdown_1:
    shutdown_system1();

shutdown:
    print("All subsystems shut down.\n");
```

Ten en cuenta que estamos apagando en el orden inverso al que inicializamos los subsistemas. Así que si el subsistema 4 no arranca, apagará el 3, el 2 y el 1 en ese orden.

[i[`goto` statement-->multilevel cleanup]>]

## Optimización de las llamadas de cola

[i[`goto` statement-->tail call optimzation]<]
[i[Tail call optimzation-->with `goto`]<]

Algo así. Sólo para funciones recursivas.

Si no está familiarizado, [flw[Optimización de las llamadas de cola (TCO)|Tail_call]] es una forma de no desperdiciar espacio en la pila cuando se llama a otras funciones bajo circunstancias muy específicas. Por desgracia, los detalles están fuera del alcance de esta guía.

Pero si tienes una función recursiva que sabes que puede ser optimizada de esta manera, puedes hacer uso de esta técnica. (Ten en cuenta que no puedes llamar a la cola a otras funciones debido al ámbito de función de las etiquetas).

Hagamos un ejemplo sencillo, factorial.

Aquí hay una versión recursiva que no es TCO, ¡pero puede serlo!

``` {.c .numberLines}
#include <stdio.h>
#include <complex.h>

int factorial(int n, int a)
{
    if (n == 0)
        return a;

    return factorial(n - 1, a * n);
}

int main(void)
{
    for (int i = 0; i < 8; i++)
        printf("%d! == %ld\n", i, factorial(i, 1));
}
```

Para conseguirlo, puedes sustituir la llamada por dos pasos:

1. Establecer los valores de los parámetros a lo que serían en la siguiente llamada.
2. `goto` una etiqueta en la primera línea de la función.

Vamos a probarlo:

``` {.c .numberLines}
#include <stdio.h>

int factorial(int n, int a)
{
tco:  // añade esto

    if (n == 0)
        return a;

    // sustituir return por la fijación de nuevos valores de los parámetros y
    // goto-ando el principio de la función
    //return factorial(n - 1, a * n);

    int next_n = n - 1;  // ¿Ves cómo coinciden con
    int next_n = a * n; // ¿los argumentos recursivos, arriba?

    n = next_n;   // Establecer los parámetros a los nuevos valores
    a = next_a;

    goto tco;   // y repite!
}

int main(void)
{
    for (int i = 0; i < 8; i++)
        printf("%d! == %d\n", i, factorial(i, 1));
}
```

Utilicé variables temporales ahí arriba para establecer los siguientes valores de los parámetros antes de saltar al inicio de la función. ¿Ves cómo corresponden a los argumentos recursivos que estaban en la llamada recursiva?

Ahora bien, ¿por qué usar variables temporales? Podría haber hecho esto en su lugar:

``` {.c}
    a *= n;
    n -= 1;

    goto tco;
```

y eso funciona muy bien. Pero si descuidadamente invierto esas dos líneas de código:

``` {.c}
    n -= 1;  // MALAS NOTICIAS
    a *= n;
```

---ahora estamos en problemas. Modificamos `n` antes de usarlo para modificar `a`. Eso es malo porque no es así como funciona cuando llamas recursivamente.
Usar las variables temporales evita este problema incluso si no estás atento a ello. Y el compilador probablemente las optimiza, de todos modos.

[i[`goto` statement-->tail call optimzation]>]
[i[Tail call optimzation-->with `goto`]>]

## Reinicio de llamadas al sistema interrumpidas

[i[`goto` statement-->restarting system calls]<]

Esto está fuera de la especificación, pero se ve comúnmente en sistemas tipo Unix.

Ciertas llamadas al sistema de larga duración pueden devolver un error si son interrumpidas por una señal, y `errno` será puesto a `EINTR` para indicar que la llamada al sistema estaba funcionando bien; sólo fue interrumpida.

En esos casos, es muy común que el programador quiera reiniciar la llamada e intentarlo de nuevo.

``` {.c}
retry:
    byte_count = read(0, buf, sizeof(buf) - 1);  // Llamada al sistema Unix read()

    if (byte_count == -1) {            // Se ha producido un error...
        if (errno == EINTR) {          // Pero sólo fue interrumpido
            printf("Restarting...\n");
            goto retry;
        }
```

Muchos Unix-likes tienen una bandera `SA_RESTART` que puede pasar a `sigaction()` para solicitar al SO que reinicie automáticamente cualquier syscall lenta en lugar de fallar con `EINTR`.

De nuevo, esto es específico de Unix y está fuera del estándar C.

Dicho esto, es posible usar una técnica similar cada vez que cualquier función deba ser reiniciada.

[i[`goto` statement-->restarting system calls]>]

## `goto` y el Hilo conductor preferente (Thread Preemption)

[i[`goto` statement-->thread preemption]<]

Este ejemplo está extraído directamente de [_Sistemas operativos: Tres piezas fáciles_](http://www.ostep.org/), otro excelente libro de autores con ideas afines que también consideran que los libros de calidad deben poder descargarse gratuitamente. No es que sea un testarudo, ni nada por el estilo.

``` {.c}
retry:

    pthread_mutex_lock(L1);

    if (pthread_mutex_trylock(L2) != 0) {
        pthread_mutex_unlock(L1);
        goto retry;
    }

    save_the_day();

    pthread_mutex_unlock(L2);
    pthread_mutex_unlock(L1);
```

Allí el hilo adquiere felizmente el mutex `L1`, pero entonces falla potencialmente en conseguir el segundo recurso custodiado por el mutex `L2` (si algún otro hilo no cooperativo lo tiene, digamos). Si nuestro hilo no puede conseguir el bloqueo `L2`, desbloquea `L1` y usa `goto` para reintentarlo limpiamente.

Esperamos que nuestra heroica hebra consiga finalmente adquirir ambos mutexes y salvar el día, todo ello evitando el malvado punto muerto.

[i[`goto` statement-->thread preemption]>]

## `goto` y el ámbito de las variables 

[i[`goto` statement-->variable scope]<]

Ya hemos visto que las etiquetas tienen ámbito de función, pero pueden ocurrir cosas raras si saltamos más allá de la inicialización de alguna variable.

Mira este ejemplo en el que saltamos de un lugar en el que la variable `x` está fuera de ámbito a la mitad de su ámbito (en el bloque).

``` {.c}
    goto label;

    {
        int x = 12345;

label:
        printf("%d\n", x);
    }
```

Esto compilará y ejecutará, pero me da una advertencia:

``` {.default}
warning: ‘x’ is used uninitialized in this function
```

Y luego imprime `0` cuando lo ejecuto (su kilometraje puede variar).

Básicamente lo que ha pasado es que hemos saltado al ámbito de `x` (así que estaba bien referenciarlo en `printf()`) pero hemos saltado la línea que realmente lo inicializaba a `12345`. Así que el valor era indeterminado.

La solución es, por supuesto, obtener la inicialización _después_ de la etiqueta de una forma u otra.

``` {.c}
    goto label;

    {
        int x;

label:
        x = 12345;
        printf("%d\n", x);
    }
```

Veamos un ejemplo más.

``` {.c}
    {
        int x = 10;

label:

        printf("%d\n", x);
    }

    goto label;
```

¿Qué pasa aquí?

La primera vez a través del bloque, estamos bien. `x` es `10` y eso es lo que se imprime.

Pero después del `goto`, saltamos al ámbito de `x`, pero después de su inicialización. Lo que significa que aún podemos imprimirlo, pero el valor es indeterminado (ya que no ha sido reinicializado).

En mi máquina, imprime `10` de nuevo (hasta el infinito), pero eso es sólo suerte. Podría imprimir cualquier valor después del `goto` ya que `x` no está inicializado.

[i[`goto` statement-->variable scope]>]

## `goto` y matrices de longitud variable (Variable-Length Arrays)

[i[`goto` statement-->with variable-length arrays]<]

Cuando se trata de VLAs y `goto`, hay una regla: no se puede saltar desde fuera del ámbito de un VLA al ámbito de ese VLA.

Si intento hacer esto:

``` {.c}
    int x = 10;

    goto label;

    {
        int v[x];

label:

        printf("Hi!\n");
    }
```

Me aparece un error:

``` {.default}
error: jump into scope of identifier with variably modified type
```

Puede adelantarse así a la declaración del VLA:

``` {.c}
    int x = 10;

    goto label;

    {
label:  ;
        int v[x];

        printf("Hi!\n");
    }
```

Porque de ese modo el VLA se asigna correctamente antes de su inevitable desasignación una vez que queda fuera del ámbito de aplicación.

[i[`goto` statement-->with variable-length arrays]>]
[i[`goto` statement]>]
