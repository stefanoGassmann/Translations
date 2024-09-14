<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Funciones variádicas

[i[Variadic functions]<]

Variadic_ es una palabra elegante para referirse a las funciones que toman un número
arbitrario de argumentos.

Por ejemplo, una función normal toma un número determinado de argumentos:

``` {.c}
int add(int x, int y)
{
    return x + y;
}
```

Sólo se puede llamar con exactamente dos argumentos que corresponden a los parámetros `x` e `y`.

``` {.c}
add(2, 3);
add(5, 12);
```

Pero si lo intentas con más, el compilador no te dejará:

``` {.c}
add(2, 3, 4);  // ERROR
add(5);        // ERROR
```

Las funciones variádicas sortean esta limitación hasta cierto punto.

Ya hemos visto un ejemplo famoso en `printf()`. Puedes pasarle todo tipo de cosas.

``` {.c}
printf("Hello, world!\n");
printf("The number is %d\n", 2);
printf("The number is %d and pi is %f\n", 2, 3.14159);
```

Parece no importarle cuántos argumentos le des.

Bueno, eso no es del todo cierto. Cero argumentos le dará un error:

``` {.c}
printf();  // ERROR
```

Esto nos lleva a una de las limitaciones de las funciones variádicas en C: deben tener al menos
un argumento.

Pero aparte de eso, son bastante flexibles, incluso permiten que los argumentos tengan
diferentes tipos como hace `printf()`.

¡Veamos cómo funcionan!

## Elipses en firmas de funciones

¿Cómo funciona, sintácticamente?

[i[`...` variadic arguments]<]

Lo que haces es poner todos los argumentos que _deben_ pasarse primero (y recuerda que tiene
que haber al menos uno) y después de eso, pones `...` .Así:

``` {.c}
void func(int a, ...)   // Literalmente 3 puntos aquí
```

Aquí hay algo de código para demostrarlo:

``` {.c}
#include <stdio.h>

void func(int a, ...)
{
    printf("a is %d\n", a);  // Imprime "a es 2"
}

int main(void)
{
    func(2, 3, 4, 5, 6);
}
```

[i[`...` variadic arguments]>]

Así que, genial, podemos obtener ese primer argumento que está en la variable `a`, pero
¿qué pasa con el resto de argumentos? ¿Cómo se llega a ellos?

Aquí empieza la diversión.

## Obtener los argumentos adicionales

Tendrás que incluir [i[`stdarg.h` header file]] `<stdarg.h>` para que todo esto funcione.

[i[`va_list` type]<]

Lo primero es lo primero, vamos a utilizar una variable especial de tipo `va_list` (lista
de argumentos de variables) para llevar la cuenta de a qué variable estamos accediendo
en cada momento.

[i[`va_start()` macro]<]
[i[`va_arg()` macro]<]
[i[`va_end()` macro]<]

La idea es que primero comencemos a procesar los argumentos con una llamada a `va_start()`,
procesemos cada argumento a su vez con `va_arg()`, y luego, cuando hayamos terminado, lo cerremos
con `va_end()`.

Cuando llame a `va_start()`, necesita pasar el _último parámetro con nombre_ (el que está
justo antes de `...`) para que sepa dónde empezar a buscar los argumentos adicionales.

Y cuando llame a `va_arg()` para obtener el siguiente argumento, tiene que decirle
el tipo de argumento que debe obtener a continuación.

Aquí tienes una demo que suma un número arbitrario de enteros. El primer argumento es el número
de enteros a sumar. Lo usaremos para calcular cuántas veces tenemos que llamar a `va_arg()`.

``` {.c .numberLines}
#include <stdio.h>
#include <stdarg.h>

int add(int count, ...)
{
    int total = 0;
    va_list va;

    va_start(va, count);   // Empezar con argumentos después de "count"

    for (int i = 0; i < count; i++) {
        int n = va_arg(va, int);   // Obtener el siguiente int

        total += n;
    }

    va_end(va);  // Todo hecho

    return total;
}

int main(void)
{
    printf("%d\n", add(4, 6, 2, -4, 17));  // 6 + 2 - 4 + 17 = 21
    printf("%d\n", add(2, 22, 44));        // 22 + 44 = 66
}
```

[i[`va_start()` macro]>]
[i[`va_end()` macro]>]

(Tenga en cuenta que cuando se llama a `printf()`, utiliza el número de `%d`s (o lo que sea)
en la cadena de formato para saber cuántos argumentos más hay).

Si la sintaxis de `va_arg()` te parece extraña (debido a ese nombre de tipo suelto flotando
por ahí), no eres el único. Esto se implementa con macros de preprocesador para conseguir
toda la magia apropiada.

## Funcionalidad de `va_list`

¿Qué es esa variable `va_list` que estamos usando ahí arriba? Es una variable opaca
^[Es decir, se supone que nosotros, los desarrolladores de pacotilla, no sabemos lo que hay ahí
ni lo que significa. La especificación no dicta qué es en detalle] que contiene información
sobre qué argumento vamos a obtener a continuación con `va_arg()`. ¿Ves cómo llamamos a `va_arg()`
una y otra vez? La variable `va_list` es un marcador de posición que mantiene un registro
del progreso hasta el momento.

[i[`va_start()` macro]<]

Pero tenemos que inicializar esa variable con algún valor razonable. Ahí es donde `va_start()`
entra en juego.

Cuando llamamos a `va_start(va, count)`, arriba, estábamos diciendo: "Inicializa
la variable `va` para que apunte al argumento variable _inmediatamente después_ de `count`".

[i[`va_end()` macro]<]

Y esa es _la razón_ por la que necesitamos tener al menos una variable con nombre en nuestra
lista de argumentos^[Sinceramente, sería posible eliminar esa limitación del lenguaje, pero
la idea es que las macros `va_start()`, `va_arg()`, y `va_end()` se puedan escribir en C. Y para
que eso ocurra, necesitamos alguna forma de inicializar un puntero a la ubicación del primer
parámetro. Y para ello, necesitamos el _nombre_ del primer parámetro. Se necesitaría una extensión
del lenguaje para hacer esto posible, y hasta ahora el comité no ha encontrado una razón
para hacerlo].

Una vez que tengas ese puntero al parámetro inicial, puedes obtener fácilmente los valores
de los argumentos posteriores llamando repetidamente a `va_arg()`. Cuando lo hagas, tienes
que pasarle tu variable `va_list` (para que pueda seguirte la pista), así como el tipo
de argumento que vas a copiar.

Depende de ti como programador averiguar qué tipo vas a pasar a `va_arg()`. En el ejemplo
anterior, acabamos de hacer `int`s. Pero en el caso de `printf()`, utiliza el especificador
de formato para determinar qué tipo sacar a continuación.

Y cuando hayas terminado, llama a `va_end()` para terminar. **Debes** (según la especificación)
llamar a esto en una variable `va_list` en particular antes de decidir
llamar a `va_start()` o `va_copy()` de nuevo. Sé que aún no hemos hablado de `va_copy()`.

* `va_start()` para inicializar tu variable `va_list`
* Repetidamente `va_arg()` para obtener los valores
* `va_end()` para desinicializar la variable `va_list`

[i[`va_start()` macro]>]
[i[`va_end()` macro]>]
[i[`va_arg()` macro]>]

[i[`va_copy()` macro]<]

También mencioné `va_copy()` ahí arriba; hace una copia de tu variable `va_list` exactamente
en el mismo estado. Es decir, si no has empezado con `va_arg()` con la variable fuente, la nueva
tampoco se iniciará. Si has consumido 5 variables con `va_arg()` hasta ahora, la copia también
lo reflejará.

va_copy()` puede ser útil si necesita recorrer los argumentos pero también necesita
recordar su posición actual.

[i[`va_copy()` macro]>]

## Funciones de biblioteca que utilizan `va_list`s

[i[`va_list` type-->passing to functions]<]

Uno de los otros usos de estos es bastante bueno: escribir tu propia variante personalizada
de `printf()`. Sería un fastidio tener que manejar todos esos especificadores de formato,
¿verdad? ¿Los millones de ellos?

Por suerte, hay variantes de `printf()` que aceptan una `va_list` como argumento. Puedes
usarlas para crear tus propios `printf()` personalizados.

[i[`vprintf()` function]<]

Estas funciones empiezan por la letra `v`, como `vprintf()`, `vfprintf()`, `vsprintf()` y
`vsnprintf()`. Básicamente, todas las funciones `printf()` de toda la vida, pero con
una `v` delante.

Hagamos una función `my_printf()` que funcione igual que `printf()` excepto que
toma un argumento extra delante.

``` {.c .numberLines}
#include <stdio.h>
#include <stdarg.h>

int my_printf(int serial, const char *format, ...)
{
    va_list va;

    // Haz mi trabajo a medida
    printf("The serial number is: %d\n", serial);

    // Luego pasa el resto a vprintf()
    va_start(va, format);
    int rv = vprintf(format, va);
    va_end(va);

    return rv;
}

int main(void)
{
    int x = 10;
    float y = 3.2;

    my_printf(3490, "x is %d, y is %f\n", x, y);
}
```

¿Ves lo que hemos hecho?  En las líneas 12-14 iniciamos una nueva variable `va_list`, y luego
la pasamos directamente a `vprintf()`. Y sabe lo que tiene que hacer con ella, porque tiene
toda la inteligencia de `printf()` incorporada.

[i[`vprintf()` function]>]

Sin embargo, aún tenemos que llamar a `va_end()` cuando hayamos terminado, ¡así que no lo olvides!

[i[`va_list` type-->passing to functions]>]
[i[`va_list` type]>]
[i[Variadic functions]>]
