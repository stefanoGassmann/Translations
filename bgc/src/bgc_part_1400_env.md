<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Entorno exterior

Cuando ejecutas un programa, en realidad eres tú quien le habla al shell, diciéndole:
«Oye, por favor, ejecuta esto». Y el intérprete de comandos dice: «Claro», y luego
le dice al sistema operativo: «Oye, ¿podrías crear un nuevo proceso y ejecutar esta cosa?».
Y si todo va bien, el sistema operativo cumple y tu programa se ejecuta.

Pero hay todo un mundo fuera de tu programa en el shell con el que se puede interactuar
desde C. Veremos algunos de ellos en este capítulo.

## Argumentos de la línea de comandos

[i[Command line arguments]<]

Muchas utilidades de línea de comandos aceptan _argumentos de línea de comandos_.
Por ejemplo, si queremos ver todos los archivos que terminan en `.txt`, podemos
escribir algo como esto en un sistema tipo Unix:

``` {.zsh}
ls *.txt
```

(o `dir` en lugar de `ls` en un sistema Windows).

En este caso, el comando es `ls`, pero sus argumentos son todos los ficheros
que terminan en `.txt`^[Históricamente, los programas de MS-DOS y Windows
hacían esto de forma diferente a Unix. En Unix, el intérprete de comandos
_expandía_ el comodín en todos los archivos coincidentes antes de que el programa
lo viera, mientras que las variantes de Microsoft pasaban la expresión del comodín
al programa para que éste se ocupara de ella. En cualquier caso, hay argumentos
que se pasan al programa].

Entonces, ¿cómo podemos ver lo que se pasa al programa desde la línea de comandos?

Digamos que tenemos un programa llamado `add` que suma todos los números pasados
en la línea de comandos e imprime el resultado:

``` {.zsh}
./add 10 30 5
45
```

¡Seguro que eso pagará las facturas!

Pero en serio, esta es una gran herramienta para ver cómo obtener esos argumentos
de la línea de comandos y desglosarlos.

Primero, veamos cómo obtenerlos. ¡Para ello, vamos a necesitar un nuevo `main()`!

Aquí hay un programa que imprime todos los argumentos de la línea de comandos.
Por ejemplo, si nombramos al ejecutable `foo`, podemos ejecutarlo así:

``` {.zsh}
./foo i like turtles
```

y veremos esta salida:

``` {.default}
arg 0: ./foo
arg 1: i
arg 2: like
arg 3: turtles
```

Es un poco raro, porque el argumento zero es el nombre del ejecutable, en sí mismo. Pero es
algo a lo que hay que acostumbrarse. Los argumentos en sí siguen directamente.

Fuente:

[i[`argc` parameter]<]
[i[`argv` parameter]<]
[i[`main()` function-->command line options]<]

``` {.c .numberLines}
#include <stdio.h>

int main(int argc, char *argv[])
{
    for (int i = 0; i < argc; i++) {
        printf("arg %d: %s\n", i, argv[i]);
    }
}
```

¡Vaya! ¿Qué pasa con la firma de la función `main()`? ¿Qué son `argc` y `argv`
^[Como son nombres de parámetros normales, no tienes que llamarlos `argc` y `argv`.
Pero es tan idiomático usar esos nombres, que si te pones creativo, otros programadores
de C te mirarán con ojos sospechosos]. (pronunciados _arg-cee_ y _arg-vee_)?

Empecemos por lo más fácil: `argc`. Es el _número de argumentos_, incluido el propio nombre
del programa. Si piensas en todos los argumentos como un array de cadenas, que es exactamente
lo que son, entonces puedes pensar en `argc` como la longitud de ese array, que
es exactamente lo que es.

Y así lo que estamos haciendo en ese bucle es ir a través de todos los `argv`s
e imprimirlos uno a la vez, por lo que para una entrada dada:

``` {.zsh}
./foo i like turtles
```

obtenemos la salida correspondiente:

``` {.default}
arg 0: ./foo
arg 1: i
arg 2: like
arg 3: turtles
```

Con esto en mente, deberíamos estar listos para empezar con nuestro programa de sumadores.

Nuestro plan:

* Mirar todos los argumentos de la línea de comandos (pasado `argv[0]`, el nombre del programa)
* Convertirlos en enteros
* Sumarlos a un total
* Imprimir el resultado

Manos a la obra.

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    int total = 0;

    for (int i = 1; i < argc; i++) { // Empieza en 1, el primer argumento
        int value = atoi(argv[i]); // Usa strtol() para un mejor manejo de errores

        total += value;
    }

    printf("%d\n", total);
}
```

[i[`main()` function-->command line options]>]
[i[`argc` parameter]>]

Recorridos de muestra:

``` {.zsh}
$ ./add
0
$ ./add 1
1
$ ./add 1 2
3
$ ./add 1 2 3
6
$ ./add 1 2 3 4
10
```

Por supuesto, podría vomitar si le pasas un no entero, pero endurecer contra
eso se deja como un ejercicio para el lector.

### El último `argv` es `NULL`.

Una curiosidad sobre `argv` es que después de la última cadena hay un puntero a `NULL`.

Eso es:

``` {.c}
argv[argc] == NULL
```

¡siempre es cierto!

Esto puede parecer inútil, pero resulta ser útil en un par de lugares;
vamos a echar un vistazo a uno de ellos ahora mismo.

### El suplente: `char **argv`

Recuerda que cuando llamas a una función, C no diferencia entre notación
de array y notación de puntero en la firma de la función.

Es decir, son lo mismo:

``` {.c}
void foo(char a[])
void foo(char *a)
```

Ahora, ha sido conveniente pensar en `argv` como una matriz de cadenas, es decir,
una matriz de `char*`s, así que esto tenía sentido:

``` {.c}
int main(int argc, char *argv[])
```

pero debido a la equivalencia, también se podría escribir:

``` {.c}
int main(int argc, char **argv)
```

¡Sí, es un puntero a un puntero, de acuerdo! Si te resulta más fácil, piensa que es
un puntero a una cadena. Pero en realidad, es un puntero a un valor que apunta a un `char`.

Recuerda también que son equivalentes:

``` {.c}
argv[i]
*(argv + i)
```

Lo que significa que puedes hacer aritmética de punteros en `argv`.

Así que una forma alternativa de consumir los argumentos de la línea de comandos
podría ser simplemente caminar a lo largo de la matriz `argv` subiendo un puntero
hasta que lleguemos a ese `NULL` al final.

Vamos a modificar nuestro sumador para hacer eso:

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    int total = 0;
    
    // Bonito truco para que el compilador deje de advertir sobre la
    // variable no utilizada argc:
    (void)argc;

    for (char **p = argv + 1; *p != NULL; p++) {
        int value = atoi(*p);  // Use strtol() para un mejor manejo de errores

        total += value;
    }

    printf("%d\n", total);
}
```

Personalmente, utilizo la notación array para acceder a `argv`, pero he
visto este estilo flotando por ahí, también.

### Datos curiosos

[i[`argc` parameter]<]

Algunas cosas más sobre `argc` y `argv`.

* Algunos entornos pueden no establecer `argv[0]` al nombre del programa. Si no está disponible, `argv[0]` será una cadena vacía. Nunca he visto que esto ocurra.

* La especificación es bastante liberal con lo que una implementación puede hacer con `argv` y de dónde vienen esos valores. Pero en todos los sistemas (en los que he estado) funciona de la misma manera, como hemos discutido en esta sección.

* Puedes modificar `argc`, `argv`, o cualquiera de las cadenas a las que apunta `argv`. (¡Sólo no hagas esas cadenas más largas de lo que ya son!)

* En algunos sistemas tipo Unix, modificar la cadena `argv[0]` hace que la salida de `ps` cambie^[`ps`, Process Status, es un comando de Unix para ver qué procesos se están ejecutando en ese momento].

Normalmente, si tienes un programa llamado `foo` que has ejecutado con
`./foo`,podrías ver esto en la salida de `ps`:

  ``` {.default}
   4078 tty1     S      0:00 ./foo
  ```

  Pero si modificas `argv[0]` así, teniendo cuidado de que la nueva cadena
`«Hi!»` tenga la misma longitud que la anterior `«. foo»`:

  ``` {.c}
  strcpy(argv[0], "Hi!  ");
  ```

  y luego ejecutamos `ps` mientras el programa `./foo` aún se está
ejecutando, veremos esto en su lugar:

  ``` {.default}
   4079 tty1     S      0:00 Hi!  
  ```

  Este comportamiento no está en la especificación y depende en gran
medida del sistema.
[i[`argc` parameter]>]
[i[`argv` parameter]>]
[i[Command line arguments]>]

## Estado de salida {#exit-status}

[i[Exit status]<]

¿Te has dado cuenta de que la firma de la función `main()` devuelve el tipo `int`?
¿A qué se debe? Tiene que ver con una cosa llamada _exit status_, que es un entero
que puede ser devuelto al programa que lanzó el suyo para hacerle saber cómo
fueron las cosas.

Ahora, hay un número de maneras en que un programa puede salir en C, incluyendo
`return` desde `main()`, o llamando a una de las variantes de `exit()`.

Todos estos métodos aceptan un `int` como argumento.
[i[`main()` function-->returning from]<]

Nota al margen: ¿has visto que básicamente en todos mis ejemplos, aunque
se supone que `main()` debe devolver un `int`, en realidad no `devuelvo` nada?
En cualquier otra función, esto sería ilegal, pero hay un caso especial en C:
si la ejecución llega al final de `main()` sin encontrar un `return`,
automáticamente hace un `return 0`.[i[`main()` function-->returning from]>]

Pero, ¿qué significa el «0»? ¿Qué otros números podemos poner ahí? ¿Y cómo se utilizan?

La especificación es a la vez clara e imprecisa al respecto, como suele
ser habitual. Clara porque detalla lo que se puede hacer, pero vaga porque
tampoco lo limita especialmente.

No queda más remedio que _seguir adelante_ e ingeniárselas.

Pongámonos [flw[Inicio|Inception]] por un segundo: resulta que cuando ejecutas
tu programa, _lo estás ejecutando desde otro programa_.

Normalmente este otro programa es algún tipo de [flw[shell|Shell_(computing)]]
que no hace mucho por sí mismo, excepto lanzar otros programas.

Pero se trata de un proceso de varias fases, especialmente visible
en los shells de línea de comandos:

1. El intérprete de comandos inicia el programa
2. El shell normalmente entra en reposo (para los shells de línea de comandos)
3. Su programa se ejecuta
4. Tu programa termina
5. El shell se despierta y espera otro comando

Ahora, hay una pequeña pieza de comunicación que tiene lugar entre los pasos
4 y 5: el programa puede devolver un _valor de estado_ que el shell puede interrogar.
Típicamente, este valor se usa para indicar el éxito o fracaso de su programa,
y, si es un fracaso, qué tipo de fracaso.

Este valor es el que hemos estado `devolviendo` desde `main()`. Ese es el estado.

Ahora, la especificación C permite dos valores de estado diferentes, que
tienen nombres de macros definidos en `<stdlib.h>`:
[i[`EXIT_SUCCESS` macro]<]
[i[`EXIT_FAILURE` macro]<]

|Estado|Descripción|
|-|-|
|`EXIT_SUCCESS` o `0`|El programa ha finalizado correctamente.|
|`EXIT_FAILURE`|El programa ha finalizado con un error.|

Vamos a escribir un programa corto que multiplique dos números desde la línea
de comandos. Requeriremos que especifiques exactamente dos valores. Si no lo
hace, vamos a imprimir un mensaje de error, y salir con un estado de error.

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv)
{
    if (argc != 3) {
        printf("usage: mult x y\n");
        return EXIT_FAILURE;   // Indicar al shell que no funcionó
    }

    printf("%d\n", atoi(argv[1]) * atoi(argv[2]));

    return 0;  // igual que EXIT_SUCCESS, todo iba bien.
}
```

[i[`EXIT_SUCCESS` macro]>]
[i[`EXIT_FAILURE` macro]>]

Ahora, si intentamos ejecutarlo, obtendremos el efecto esperado hasta
que especifiquemos exactamente el número correcto de argumentos de la línea
de comandos:

``` {.zsh}
$ ./mult
usage: mult x y

$ ./mult 3 4 5
usage: mult x y

$ ./mult 3 4
12
```

[i[Exit status-->obtaining from shell]<]

Pero eso no muestra realmente el estado de salida que hemos devuelto, ¿verdad?
Sin embargo, podemos hacer que el shell lo imprima. Asumiendo que estás ejecutando
Bash u otro shell POSIX, puedes usar `echo $?` para verlo^[En Windows `cmd.exe`,
escribe `echo %errorlevel%`. En PowerShell, escribe `$LastExitCode`].

Intentémoslo:

``` {.zsh}
$ ./mult
usage: mult x y
$ echo $?
1

$ ./mult 3 4 5
usage: mult x y
$ echo $?
1

$ ./mult 3 4
12
$ echo $?
0
```

[i[Exit status-->obtaining from shell]>]

¡Interesante! Vemos que en mi sistema [i[macro `EXIT_FAILURE`]]
`EXIT_FAILURE` es `1`. La especificación no lo especifica, así que podría
ser cualquier número. Pero pruébalo; probablemente sea `1` en tu sistema también.

### Otros valores de estado de salida

El estado `0` definitivamente significa éxito, pero ¿qué pasa con el resto
de enteros, incluso los negativos?

Aquí nos salimos de la especificación C y nos adentramos en la tierra de Unix.
En general, mientras que `0` significa éxito, un número positivo distinto
de cero significa fracaso. Así que sólo puedes tener un tipo de éxito, y
múltiples tipos de fallo. Bash dice que el código de salida debe estar
entre 0 y 255, aunque hay una serie de códigos reservados. 

En resumen, si quieres indicar diferentes estados de salida de error
en un entorno Unix, puedes empezar con `1` e ir subiendo.

En Linux, si intentas cualquier código fuera del rango 0-255, el código será
bitwise AND con `0xff`, sujetándolo efectivamente a ese rango.

Puedes programar el shell para que más tarde use estos códigos de estado
para tomar decisiones sobre qué hacer a continuación.
[i[Exit status]>]

## Variables de entorno {#env-var}

[i[Environment variables]<]

Antes de entrar en materia, debo advertirte que C no especifica qué es una variable
de entorno. Así que voy a describir el sistema de variables de entorno que funciona
en todas las plataformas importantes que conozco.

Básicamente, el entorno es el programa que va a ejecutar tu programa, por ejemplo,
el shell bash. Y puede tener definidas algunas variables bash. En caso de que
no lo sepas, el shell puede crear sus propias variables. Cada shell es diferente,
pero en bash puedes simplemente escribir `set` y te las mostrará todas.

Aquí hay un extracto de las 61 variables que están definidas en mi shell bash:

``` {.default}
HISTFILE=/home/beej/.bash_history
HISTFILESIZE=500
HISTSIZE=500
HOME=/home/beej
HOSTNAME=FBILAPTOP
HOSTTYPE=x86_64
IFS=$' \t\n'
```

Fíjese en que están en forma de pares clave/valor. Por ejemplo, una clave
es `HOSTTYPE` y su valor es `x86_64`. Desde una perspectiva C, todos los valores
son cadenas, incluso si son números^[Si necesitas un valor numérico, convierte
la cadena con algo como `atoi()` o `strtol()`].

Así que, ¡como quieras! Resumiendo, es posible obtener estos valores desde dentro
de tu programa C.

[i[`getenv()` function]<]

Escribamos un programa que utilice la función estándar `getenv()` para buscar
un valor que hayas establecido en el shell.

La función `getenv()` devolverá un puntero a la cadena de valores, o bien `NULL`
si la variable de entorno no existe.

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    char *val = getenv("FROTZ");  // Intenta obtener el valor

    // Comprueba que existe
    if (val == NULL) {
        printf("No se encuentra la variable de entorno FROTZ\n");
        return EXIT_FAILURE;
    }

    printf("Value: %s\n", val);
}
```

[i[`getenv()` function]>]

Si ejecuto esto directamente, obtengo lo siguiente:

``` {.zsh}
$ ./foo
No se encuentra la variable de entorno FROTZ
```

que tiene sentido, ya que no lo he establecido todavía.

En bash, puedo ponerlo a algo con^[En Windows CMD.EXE, usa `set FROTZ=value`.
En PowerShell, utilice `$Env:FROTZ=value`]:

``` {.zsh}
$ export FROTZ="C is awesome!"
```

Entonces si lo ejecuto, obtengo:

``` {.zsh}
$ ./foo
Value: C is awesome!
```

De este modo, puede establecer datos en variables de entorno, y puede obtenerlos
en su código C y modificar su comportamiento en consecuencia.

### Configuración de variables de entorno

Esto no es estándar, pero muchos sistemas proporcionan formas de establecer
variables de entorno.

Si está en un sistema tipo Unix, busque la documentación de [i[`putenv()`
function]]`putenv()`, [i[`setenv()`]]`setenv()`, y [i[`unsetenv()`
function]]`unsetenv()`. En Windows, consulte [i[`_putenv()`
function]]`_putenv()`.

### Variables de entorno alternativas a Unix

Si estás en un sistema tipo Unix, lo más probable es que tengas otro par de formas
de acceder a las variables de entorno. Tenga en cuenta que aunque la especificación
señala esto como una extensión común, no es realmente parte del estándar de C.
Es, sin embargo, parte del estándar POSIX.
[i[`environ` variable]<]

Una de ellas es una variable llamada `environ` que debe declararse así:

``` {.c}
extern char **environ;
```

Es un array de cadenas terminado con un puntero `NULL`.

Deberías declararlo tú mismo antes de usarlo, o podrías encontrarlo en el fichero
de cabecera no estándar `<unistd.h>`.

Cada cadena tiene la forma `«clave=valor»`, por lo que tendrás que dividirla
y analizarla tú mismo si quieres obtener las claves y los valores.

Aquí hay un ejemplo de un bucle e impresión de las variables de entorno
de un par de maneras diferentes:

``` {.c .numberLines}
#include <stdio.h>

extern char **environ;  // DEBE ser externo Y llamarse «environ».

int main(void)
{
    for (char **p = environ; *p != NULL; p++) {
        printf("%s\n", *p);
    }

    // O podrías hacer esto:
    for (int i = 0; environ[i] != NULL; i++) {
        printf("%s\n", environ[i]);
    }
}
```

Para un montón de salida que se parece a esto:

``` {.default}
SHELL=/bin/bash
COLORTERM=truecolor
TERM_PROGRAM_VERSION=1.53.2
LOGNAME=beej
HOME=/home/beej
... etc ...
```

Utilice `getenv()` si es posible porque es más portable. Pero si tienes
que iterar sobre variables de entorno, usar `environ` puede ser la mejor opción.

[i[`environ` variable]>]
[i[`env` parameter]<]

Otra forma no estándar de obtener las variables de entorno es como parámetro
de `main()`. Funciona de forma muy parecida, pero se evita tener que añadir
la variable `environ` `extern`. [fl[Ni siquiera la especificación POSIX soporta esto.|https://pubs.opengroup.org/onlinepubs/9699919799/functions/exec.html]]
que yo sepa, pero es común en la tierra de Unix.


``` {.c .numberLines}
#include <stdio.h>

int main(int argc, char **argv, char **env)  // <-- env!
{
    (void)argc; (void)argv;  // Suprimir las advertencias no utilizadas

    for (char **p = env; *p != NULL; p++) {
        printf("%s\n", *p);
    }

    // O podrías hacer esto:
    for (int i = 0; env[i] != NULL; i++) {
        printf("%s\n", env[i]);
    }
}
```

Es como usar `environ` pero _incluso menos portable_. Es bueno tener objetivos.

[i[`env` parameter]>]
[i[Environment variables]>]
