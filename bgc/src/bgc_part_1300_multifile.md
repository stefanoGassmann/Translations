<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Proyectos multiarchivos

[i[Multifile projects]<]

Hasta ahora hemos visto programas de juguete que, en su mayor parte, caben
en un único archivo. Pero los programas C complejos se componen de muchos archivos
que se compilan y enlazan en un único ejecutable.

En este capítulo veremos algunos de los patrones y prácticas más comunes para crear
proyectos más grandes.

## Incluye prototipos y funciones  {#includes-func-protos}

[i[Multifile projects-->includes]<]
[i[Multifile projects-->function prototypes]<]

Una situación realmente común es que algunas de tus funciones estén definidas
en un fichero, y quieras llamarlas desde otro.

Esto en realidad funciona con una advertencia... probemos primero y luego veamos
la forma correcta de arreglar la advertencia.

Para estos ejemplos, pondremos el nombre del archivo como el primer comentario
en el código fuente.

Para compilarlos, necesitarás especificar todas las fuentes en la línea de comandos:

``` {.zsh}
# archivo de salida      archivos de origen
#     v                       |
#   |----| |---------|        | 
gcc -o foo foo.c bar.c  <-----|
```

En esos ejemplos, `foo.c` y `bar.c` se construyen en el ejecutable llamado `foo`.

Así que echemos un vistazo al archivo fuente `bar.c`:

``` {.c .numberLines}
// Archivo bar.c

int add(int x, int y)
{
    return x + y;
}
```

Y el archivo `foo.c` con main en él:

``` {.c .numberLines}
// Archivo foo.c

#include <stdio.h>

int main(void)
{
    printf("%d\n", add(2, 3));  // 5!
}
```

Mira cómo desde `main()` llamamos a `add()`--¡pero `add()` está en un fichero
fuente completamente diferente! Está en `bar.c`, ¡mientras que la llamada a él está
en `foo.c`!

Si construimos esto con:

``` {.zsh}
gcc -o foo foo.c bar.c
```

obtenemos este error:

``` {.default}
error: implicit declaration of function 'add' is invalid in C99
// error: la declaración implícita de la función 'add' no es válida en C99
```

(O puede recibir una advertencia. Que no debes ignorar. Nunca ignores
las advertencias en C; atiéndelas todas).

Si recuerdas la [sección sobre prototipos](#prototypes), las declaraciones implícitas
están prohibidas en el C moderno y no hay ninguna razón legítima para introducirlas
en código nuevo. Deberíamos arreglarlo.

Lo que significa `declaración implícita` es que estamos usando una función, en este
caso `add()`, sin que C sepa nada de ella de antemano. C quiere saber
qué devuelve, qué tipos toma como argumentos, y cosas por el estilo.

Ya vimos cómo arreglar esto antes con un _prototipo de función_. De hecho, si añadimos
uno de esos a `foo.c` antes de hacer la llamada, todo funciona bien:

``` {.c .numberLines}
// File foo.c

#include <stdio.h>

int add(int, int);  // Añadir el prototipo

int main(void)
{
    printf("%d\n", add(2, 3));  // 5!
}
```

Se acabaron los errores.

Pero eso es un coñazo---tener que teclear el prototipo cada vez que quieres usar
una función. Quiero decir, usamos `printf()` justo ahí y no necesitamos teclear
un prototipo; ¿qué pasa?

Si recuerdas lo que pasó con «hola.c» al principio del libro, ¡en realidad incluimos
el prototipo de `printf()` _! ¡Está en el fichero `stdio.h` !_ ¡Y lo incluimos con `#include`!

¿Podemos hacer lo mismo con nuestra función `add()`? ¿Hacer un prototipo
para ella y ponerlo en un fichero de cabecera?

Por supuesto.

Los ficheros de cabecera en C tienen una extensión `.h` por defecto. Y a menudo, aunque
no siempre, tienen el mismo nombre que su correspondiente archivo `.c`. Así que vamos
a crear un fichero `bar.h` para nuestro fichero `bar.c`, y vamos a meter el prototipo en él:

``` {.c .numberLines}
// Archivo bar.h

int add(int, int);
```
 
Y ahora vamos a modificar `foo.c` para incluir ese fichero. Suponiendo que está
en el mismo directorio, lo incluimos entre comillas dobles (en lugar de corchetes angulares):

``` {.c .numberLines}
// Archivo foo.c

#include <stdio.h>

#include "bar.h"  // Incluir desde el directorio actual

int main(void)
{
    printf("%d\n", add(2, 3));  // 5!
}
```

Fíjate en que ya no tenemos el prototipo en `foo.c`, lo hemos incluido en `bar.h`.
Ahora _cualquier_ fichero que quiera la funcionalidad `add()` puede simplemente
`#include «bar.h»` para obtenerla, y no necesitas preocuparte de escribir el prototipo
de la función.

Como habrás adivinado, `#include` incluye literalmente el fichero nombrado _ahí mismo_
en tu código fuente, como si lo hubieras tecleado.

Y al construir y ejecutar:

``` {.zsh}
./foo
5
```

Efectivamente, ¡obtenemos el resultado de $2+3$! ¡Bien!

Pero no abras todavía tu bebida preferida. Ya casi hemos llegado. Sólo tenemos
que añadir una pieza más de la repetición.

[i[Multifile projects-->function prototypes]>]

## Tratamiento de la repetición `#include`

No es infrecuente que un fichero de cabecera incluya a su vez otras cabeceras
necesarias para la funcionalidad de sus correspondientes ficheros C. ¿Por qué no?

Y puede ser que tengas una cabecera `#include` varias veces desde diferentes sitios.
Puede que eso no sea un problema, pero puede que cause errores de compilación. ¡Y no
podemos controlar en cuántos sitios se hace `#include`!

Peor aún, ¡podríamos llegar a una situación loca en la que la cabecera `a.h` incluya
la cabecera `b.h`, y `b.h` incluya `a.h`! ¡Es un ciclo infinito `#include`!

Intentar construir algo así da error:

``` {.default}
error: #include nested depth 200 exceeds maximum of 200
//error : #include profundidad anidada 200 supera el máximo de 200
```

Lo que tenemos que hacer es que si un archivo se incluye una vez, los subsiguientes
`#include`s para ese archivo sean ignorados.

**Lo que vamos a hacer es tan común que deberías hacerlo automáticamente
cada vez que crees un archivo de cabecera.**

Y la forma común de hacerlo es con una variable de preprocesador que establecemos
la primera vez que `#incluimos` el archivo. Y entonces para los subsiguientes
`#include`s, primero comprobamos que la variable no está definida.

Para ese nombre de variable, es supercomún tomar el nombre del fichero de cabecera, como
`bar.h`, ponerlo en mayúsculas, y sustituir el punto por un guión bajo: `BAR_H`.

Por lo tanto, compruebe en la parte superior del archivo si ya se ha incluido y, en
caso afirmativo, coméntelo todo.

(No pongas un guión bajo inicial (porque un guión bajo inicial seguido de una letra
mayúscula está reservado) o un doble guión bajo inicial (porque también está reservado.))

``` {.c .numberLines}
#ifndef BAR_H // Si BAR_H no está definido...
#define BAR_H // Definirlo (sin valor particular)

// Archivo bar.h

int add(int, int);

#endif          // Fin del #ifndef BAR_H
```

Esto hará que el fichero de cabecera se incluya sólo una vez, sin importar en cuántos
sitios se intente hacer `#include`.

[i[Multifile projects-->includes]>]

## `static` y `extern`

[i[`static` storage class]<]
[i[`extern` storage class]<]
[i[Multifile projects-->`static` storage class]<]
[i[Multifile projects-->`extern` storage class]<]

Cuando se trata de proyectos multifichero, puedes asegurarte de que las
variables y funciones de un fichero no son visibles desde otros ficheros fuente
con la palabra clave `static`.

Y puedes hacer referencia a objetos de otros ficheros con `extern`.

Para más información, echa un vistazo a las secciones en el libro sobre
el [`static`](#static) y [`extern`](#extern) especificadores de clase de almacenamiento.

[i[`static` storage class]>]
[i[`extern` storage class]>]
[i[Multifile projects-->`static` storage class]>]
[i[Multifile projects-->`extern` storage class]>]

## Compilación con archivos de objetos

[i[Object files]<]

Esto no es parte de la especificación, pero es 99,999% común en el mundo C.

Puedes compilar archivos C en una representación intermedia llamada _archivos objeto_.
Estos son código máquina compilado que aún no ha sido puesto en un ejecutable.

Los archivos objeto en Windows tienen una extensión `.OBJ`; en Unix, son `.o`.
[i[`gcc` compiler]<]


En gcc, podemos construir algo como esto, con la bandera `-c` (¡sólo compilar!):

``` {.zsh}
gcc -c foo.c # produce foo.o
gcc -c bar.c # produce bar.o
```

Y luego podemos _enlazarlos_ juntos en un único ejecutable:

``` {.zsh}
gcc -o foo foo.o bar.o
```

_Voila_, hemos producido un ejecutable `foo` a partir de los dos ficheros objeto.

Pero usted está pensando, ¿por qué molestarse? ¿No podemos simplemente:

``` {.zsh}
gcc -o foo foo.c bar.c
```

¿y matar dos [flw[boids|Boids]] de un tiro?

[i[`gcc` compiler]>]

Para programas pequeños, está bien. Yo lo hago todo el tiempo.

Pero para programas más grandes, podemos aprovechar el hecho de que compilar desde
el código fuente a los ficheros objeto es relativamente lento, y enlazar un montón
de ficheros objeto es relativamente rápido.

Esto realmente se muestra con la utilidad `make` que sólo reconstruye fuentes
que son más recientes que sus salidas.

Digamos que tienes mil archivos C. Podrías compilarlos todos a ficheros objeto
para empezar (lentamente) y luego combinar todos esos ficheros objeto
en un ejecutable (rápido).

Ahora digamos que modificas sólo uno de esos archivos fuente en C -aquí está la magia:
¡sólo tienes que reconstruir ese archivo objeto para ese archivo fuente! Y luego
reconstruir el ejecutable (rápido). Todos los demás archivos C no tienen que ser
tocados.

En otras palabras, al reconstruir sólo los archivos objeto que necesitamos, reducimos
radicalmente los tiempos de compilación. (A menos, claro, que estés haciendo
una compilación «limpia», en cuyo caso hay que crear todos los ficheros objeto).

[i[Object files]>]
[i[Multifile projects]>]
