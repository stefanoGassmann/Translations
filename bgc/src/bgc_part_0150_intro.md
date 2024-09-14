<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Hello, World!

## Qué esperar de C

> _"¿A dónde llevan estas escaleras?"_ \
> _"Llevan hacia arriba."_
>
> ---Ray Stantz y Peter Venkman, Cazafantasmas

C es un lenguaje de bajo nivel.

No solía ser así. En aquellos días, cuando las personas tallaban tarjetas perforadas de granito, C era una manera increíble de liberarse de la tediosa tarea de usar lenguajes de bajo nivel como [flw[ensamblador|Assembly_language]].

Pero, en estos tiempos modernos, los lenguajes de la generación actual, ofrecen todo tipo de características que no existían cuando se inventó C (1972). Esto significa que C es un lenguaje bastante básico, con pocas características. Puede hacer _cualquier cosa_, pero puede hacerte trabajar por ello.

Entonces, ¿por qué lo usaríamos hoy en día?

* Como herramienta de aprendizage: C no es solo una pieza venerable de la
  historia de la informática, está conectado a [flw[nivel de hardware|Bare_machine]] de una 
  manera en la que los lenguajes actuales no lo están. Cuando aprendes C, entiendes
  cómo el software interactúa con la memoria de la computadora a bajo nivel.
  No hay medidas de seguridad. Te garantizo, que escribirás software que fallará.
  ¡Y eso es parte de la diversión!

* Como herramienta útil: C todavía se utiliza para ciertas aplicaciones, como
  la construcción de [flw[sistemas operativos|Operating_system]] o en [flw[sistemas embebidos|Embedded_system]]. (¡Aunque el lenguaje de programación [flw[Rust|Rust_(programming_language)]] está observando ambos campos!)

Si estás familiarizado con otro lenguaje, muchas cosas en C
te resultarán fáciles. C ha inspirado muchos otros lenguajes, y
verás fragmentos de él en Go, Rust, Swift, Python, JavaScript,
Java y todo tipo de otros lenguajes. Esos aspectos te resultarán familiares.

Lo único que confunde a la gente en C son los _punteros_. Prácticamente todo
lo demás es conocido, pero los punteros son lo peculiar. Es probable que ya
conozcas el concepto detrás de los punteros, pero C te obliga a ser explícito
al respecto, utilizando operadores que probablemente nunca hayas visto antes.

Es especialmente insidioso porque una vez que _comprendes_ los punteros,
de repente se vuelven fáciles. Pero hasta ese momento, son como anguilas resbaladizas.

Todo lo demás en C es simplemente memorizar otra forma (¡o a veces la misma forma!)
de hacer algo que ya has hecho antes. Los punteros son la parte extraña. Y, se podría
argumentar, que incluso los punteros, son variaciones de un tema con el que probablemente
estás familiarizado.

Así que.. prepárate! para una emocionante aventura, tan cerca del núcleo de la computadora como
puedas estar, sin llegar al lenguaje ensamblador, en el lenguaje de computadora más influyente
de todos los tiempos^[Sé que alguien me discutirá esto, pero debe estar al menos entre los
tres primeros, ¿verdad?]. ¡Agárrate fuerte!


## Hello, World!

[i[Hello, world]()]Este es el ejemplo canónico de un programa en C.
Todo el mundo lo utiliza. (Nota: los números a la izquierda son solo para referencia del lector y no forman parte del código fuente.)

``` {.c .numberLines}
/* Programa Hola Mundo */

#include <stdio.h>

int main(void)
{
    printf("Hello, World!\n");  // En realidad se hace el trabajo aquí
}
```

Vamos a ponernos nuestros guantes de goma resistentes y de manga larga,
agarrar un bisturí y abrir esto para ver cómo funciona. Así que lávate bien,
porque allá vamos. Cortando muuuy suavemente...

[i[Comments]<]Vamos a quitar lo fácil del camino: cualquier cosa entre
los dígrafos `/*` y `*/` es un comentario y será completamente ignorado
por el compilador. Lo mismo ocurre con cualquier cosa en una línea después
de un `//`. Esto te permite dejar mensajes para ti y para otros, de modo que
cuando vuelvas y leas tu código en el futuro lejano, sabrás qué demonios estabas
tratando de hacer. Créeme, lo olvidarás; Sucede.[i[Comments]>]

[i[C Preprocessor]<][i[`#include` directive]<]Ahora, ¿Que es ese?
`#include`? ¡QUÉ ASCO! Bueno, le dice al preprocesador de C que extraiga
el contenido de otro archivo y lo inserte en el código justo _ahí_.

Espera!... ¿qué es el Preprocesador de C?  Buena pregunta. Hay dos etapas^[Bueno,
técnicamente hay más de dos, pero bueno, finjamos que hay dos, ¿verdad?] en la
compilación: el preprocesador y el compilador.[i[Octothorpe]<] Cualquier cosa que comiense con
el signo, almohadilla o "numeral" (`#`) es algo para que el preprocesador[i[Preprocessor]] 
opere, antes de que la compilación siquiera comiece. Comunmente las _directivas del
preprocesador_, son llamadas por `#include` y `#define`.[i[`#define` directive]] Pero
hablaremos de ello más adelante.[i[`#include` directive]>][i[C Preprocessor]>]

Antes de continuar, ¿por qué me molestaría en señalar que el signo de numeral se llama
almohadilla? La respuesta es simple: creo que la palabra almohadilla es tan extremadamente
divertida[Traductor: me recurda a las patitas de un gato] que tengo que difundir su nombre
gratuitamente siempre que tenga la oportunidad. Almohadilla. Almohadilla, Almohadilla, Almohadilla. [i[Octothorpe]>]

Entonces, _de todas formas_. Después de que el preprocesador de C haya terminado de
preprocesar todo, los resultados están listos para que el compilador los tome y produzca
[flw[código ensamblador|Assembly_language]], [flw[código máquina|Machine_code]], o lo que sea
que esté a punto de hacer. El código máquina es el "lenguaje" que entiende la CPU, y lo puede
entender _muy rápidamente_. Esta es una de las razones por las que los programas en C tienden a
ser rápidos.


Por ahora, no te preocupes por los detalles técnicos de la compilación; solo debes saber
que tu código fuente pasa por el preprocesador, la salida de eso pasa por el compilador, y luego eso produce un ejecutable para que lo ejecutes.

¿Qué hay del resto de la línea? [i[stdio.h header file]<] ¿Qué es `<stdio.h>`?
Eso es lo que se conoce como un _archivo de encabezado_. Es el ".h" al final
lo que lo delata. De hecho, es el archivo de encabezado de "Entrada/Salida Estándar" (`stdio` : **ST**an**D**ar **I**nput/**O**utput)
que llegarás a conocer y amar. Nos da acceso a un montón de funcionalidades de E/S
^[Técnicamente, contiene directivas de preprocesador y prototipos de funciones (más sobre eso
adelante) para necesidades comunes de entrada y salida.]. Para nuestro programa de
demostración, estamos mostrando la cadena "¡Hola, Mundo!", por lo que en particular
necesitamos acceso a la [i[`printf()`function]<] función `printf()` para hacer esto.
El archivo `<stdio.h>` nos proporciona este acceso. Básicamente, si intentáramos usar
`printf()` sin `#include <stdio.h>`, el compilador se nos habría quejado.

¿Cómo supe que necesitaba `#include <stdio.h> `para `printf()`?[i[`printf()` function]>]
Respuesta: está en la documentación.
Si estás en un sistema Unix, `man 3 printf` te dirá justo al principio de la
página del manual qué archivos de encabezado se requieren o consulta la sección
de referencia en este libro. `:-)` [i[`stdio.h` header file]>]

¡Santo cielo! Todo eso fue para cubrir la primera línea. Pero, seamos sinceros, ha sido
completamente diseccionada. ¡No quedará ningún misterio!

Así que toma un respiro... repasa el código de muestra. Solo quedan un par de líneas fáciles.

¡Bienvenido de nuevo de tu descanso! Sé que realmente no tomaste un descanso;
solo te estaba haciendo una broma.

[i[`main()` function]<]La siguiente linea es `main()`. Esta es la definición
de la función `main()`;  todo lo que está entre las llaves (`{`
y `}`) es parte de la definición de la función.


(¿Cómo se _llama_ a una función? La respuesta está en la línea `printf()`, pero llegaremos a ella en un minuto).

La función main, es muy especial, se destaca sobre las demás ya que es la función que se llamará automáticamente cuando tu programa comienza a ejecutarse. Nada de tu
código se llama antes de `main()`. En el caso de nuestro ejemplo, esto funciona bien, ya que
todo lo que queremos hacer es imprimir una línea y salir.

Otra cosa: una vez que el programa se ejecute, más allá del final de `main()`
y por debajo de la llave de cierre, el programa terminará y volverás a tu símbolo del sistema /
Terminal / Consola.

Así que, sabemos que ese programa ha traído un fichero de cabecera, `stdio.h`[i[stdio.h]T], y ha declarado una función `main()` que se ejecutará cuando se inicie el programa. ¿Cuáles son las bondades de `main()`?[i[`main()` function]>]

Me alegra mucho que lo hayas preguntado. ¡De verdad! Solo tenemos una ventaja: una llamada a
la función [i[`printf()` function]<]`printf()`. Puedes darte cuenta de que esto es una llamada
a una función y no una definición de función de varias maneras, pero un indicador es la falta
de llaves después de ella. Y terminas la llamada a la función con un punto y coma para que el
compilador sepa que es el final de la expresión. Verás que estarás poniendo puntos y comas 
después de casi todo.

Estás pasando un argumento a la función `printf()`[i[`printf()`function]>]:
una cadena que se imprimirá cuando la llames. Oh, sí, ¡estamos llamando a una función!
¡Somos geniales! Espera, espera, no te pongas arrogante.[i[`\n`newline]<]
¿Qué es ese loco `\n` al final de la cadena? Bueno, la mayoría de los caracteres en la
cadena se imprimirán tal como están almacenados. Pero hay ciertos caracteres que no se pueden
imprimir bien en pantalla y que están incrustados como códigos de barra invertida de dos
caracteres. Uno de los más populares es `\n` (se lee "barra invertida-N" o simplemente "nueva
línea") que corresponde al carácter _nueva línea_. Este es el carácter que hace que la
impresión continúe al principio de la siguiente línea, en lugar de la actual. Es como presionar
enter al final de la línea.[i[`\n` newline]>]

Así que copia ese código en un archivo llamado `hello.c` y compílalo. En una
plataforma similar a Unix (por ejemplo, Linux, BSD, Mac o WSL), desde la línea de
comandos lo compilarás con un comando como este:

[i[`gcc` compiler]]
``` {.zsh}
gcc -o hello hello.c
```
(Esto significa "compilar `hello.c` y generar un ejecutable llamado `hello`".)

Después de eso, deberías tener un archivo llamado `hello` que puedes ejecutar con este comando:

``` {.default}
./hello
```
(El `./` inicial le indica al shell que "ejecute desde el directorio actual".)

Y esto es lo que pasa:

``` {.default}
Hello, World! 
```
¡Está hecho y probado! ¡Envíalo! [i[Hello, world]>]

## Detalles de la Compilación

[i[Compilation]<] Hablemos un poco más sobre cómo compilar programas en C y qué sucede detrás
de escena en ese proceso.

Como otros lenguajes, C tiene un _código fuente_. Sin embargo, dependiendo del lenguaje
del que provengas, es posible que nunca hayas tenido que _compilar_ tu código fuente en un
_ejecutable_.

La compilación es el proceso de tomar código fuente en C
y lo convertirlo en un programa que tu sistema operativo puede ejecutar.

Los desarrolladores de JavaScript y Python no están acostumbrados a un paso de compilación
separado en absoluto, ¡aunque detrás de escena eso está sucediendo! Python compila tu código
fuente en algo llamado _bytecode_, que la máquina virtual de Python puede ejecutar. Los
desarrolladores de Java están acostumbrados a la compilación, pero eso produce bytecode para
la Máquina Virtual de Java.

Cuando se compila en C, se genera _código máquina_. Estos son los unos y ceros
que pueden ser ejecutados directa y rápidamente por la CPU.

> Los lenguajes que típicamente no se compilan se llaman lenguajes _interpretados_.
> Pero como mencionamos con Java y Python, también tienen un paso de compilación. Y
> no hay ninguna regla que diga que C no puede ser interpretado. 
> (¡Existen intérpretes de C por ahí!) En resumen, hay muchas áreas grises. La compilación
> en general simplemente toma código fuente y lo convierte en otra forma más fácil de ejecutar.

El compilador de C es el programa que realiza la compilación.

Como ya mencionamos, `gcc` es un compilador que está instalado en muchos
[flw[Sistemas operativos similares a Unix|Unix]]. Y comúnmente se ejecuta desde
la línea de comandos en una terminal, pero no siempre. También puedes
ejecutarlo desde tu entorno de desarrollo integrado (IDE).

Entonces, ¿cómo realizamos compilaciones desde la línea de comandos?

## Construyendo con `gcc`

[i[`gcc` compiler]<] Si tienes un archivo fuente llamado `hello.c` en el directorio
actual, puedes compilarlo en un programa llamado `hello` con este comando que se escribe en una terminal:

``` {.zsh}
gcc -o hello hello.c
```
El `-o` significa "salida a este archivo" (Output)^[Si no le proporcionas un nombre de archivo de 
salida, por defecto se exportará a un archivo llamado `a.out`---este nombre de archivo tiene 
sus raíces en la historia profunda de Unix.]. Y al final está `hello.c`, que es el nombre del 
archivo que queremos compilar.

Si tu código fuente está dividido en varios archivos, puedes compilarlos
todos juntos (casi como si fueran un solo archivo, aunque las reglas son
más complejas que eso) colocando todos los archivos `.c` en la línea de comandos:

``` {.zsh}
gcc -o awesomegame ui.c characters.c npc.c items.c
```
[i[`gcc` compiler]>]

y todos serán compilados juntos en un único ejecutable grande.

Eso es suficiente para empezar. Más adelante hablaremos sobre detalles como múltiples
archivos fuente, archivos objeto y muchas otras cosas divertidas.[i[Compilation]>]

## Construyendo con `clang`

En Macs, el compilador estándar no es `gcc`, es `clang`[i[`clang`compiler]].
Sin embargo, también se instala un envoltorio para que puedas ejecutar `gcc` y que
funcione de todos modos.

También puedes instalar el compilador `gcc`[i[`gcc` compiler]] de forma adecuada
a través de [fl[Homebrew|https://formulae.brew.sh/formula/gcc]] u otros medios.

## Construyendo con IDEs

[i[Integrated Development Environment]<]Si estás utilizando un _Entorno de Desarrollo
Integrado_ (IDE), probablemente no necesites compilar desde la línea de comandos.

Con Visual Studio, con `CTRL-F7` puedes compilar, y con `CTRL-F5` puedes ejecutar.

Con VS Code, puedes presionar `F5` para ejecutar a través del depurador.
(Tendrás que instalar la extensión C/C++ para esto).

Con Xcode, puedes compilar con `COMMAND-B` y ejecutar con `COMMAND-R`. Para obtener las
herramientas de línea de comandos, busca en Google "Xcode command line tools" y
encontrarás instrucciones para instalarlas.

Para comenzar, te animo también a intentar compilar desde la
línea de comandos, ¡es historia! [i[Integrated Development Environment]>]

## Versiones de C

[i[Language versions]<]C ha recorrido un largo camino a lo largo de los años,
y ha tenido muchas versiones numeradas para describir el dialecto del
lenguaje estás utilizando.

Estos generalmente se refieren al año de la especificación.

Los más famosos son C89, C99, C11 y C2x. Nos centraremos en este último en el libro.

Pero aquí tienes una tabla más completa:

|Version|Descripción|
|-----|--------------|
|K&R C|En 1978, la versión original. Nombrada en honor a Brian Kernighan y Dennis Ritchie. Ritchie diseñó y codificó el lenguaje, y Kernighan coescribió el libro sobre él. Hoy en día rara vez se ve código original de K&R. Si lo ves, se verá extraño, como el inglés medio, luce extraño para los lectores de inglés moderno.|
|**C89**, ANSI C, C90|En 1989, el American National Standards Institute (ANSI) produjo una  especificación del lenguaje C que marcó el tono para C que persiste hasta hoy. Un año después, la responsabilidad pasó a la Organización Internacional de Normalización (ISO), que produjo el estándar C90, idéntico al de ANSI.|
|C95|Una adición mencionada raramente a C89 que incluía soporte para caracteres.|
|**C99**|La primera gran revisión con muchas adiciones al lenguaje. Lo que la mayoría de la gente recuerda es la adición de los comentarios de estilo `//`. Esta es la versión más popular de C en uso hasta la fecha de esta escritura.|
|**C11**|Esta actualización mayor incluye soporte para Unicode y multi-threading. Ten en cuenta que si comienzas a usar estas características del lenguaje, podrías estar sacrificando la portabilidad en lugares que aún están usando C99. Sin embargo, honestamente, 1999 ya fue hace un tiempo.|
|C17, C18|Actualización de corrección de errores para C11. C17 parece ser el nombre oficial, pero la publicación se retrasó hasta 2018. Según tengo entendido, ambos términos son intercambiables, prefiriéndose C17.|
|C2x|Lo que viene a continuación se espera que eventualmente se convierta en C23.|

[i[`gcc` compiler]<]Puedes forzar a GCC a usar uno de estos estándares con el argumento de 
línea de comandos `-std=`. Si quieres que sea estricto con el estándar, añade `-pedantic`

Por ejemplo:

``` {.zsh}
gcc -std=c11 -pedantic programa.c
```
Para este libro, compilo programas para C2x con todas las advertencias activadas:

``` {.zsh}
gcc -Wall -Wextra -std=c2x -pedantic programa.c
```
[i[`gcc` compiler]>]
