# Introducción

¿La programación de sockets te tiene deprimido? ¿Te resulta demasiado difícil entender esto desde las páginas `man`? Quieres hacer una buena programación de Internet, pero no tienes tiempo para vadear a través de un montón de `struct`s tratando de averiguar si tienes que llamar a `bind()` antes de `connect()`, etc, etc.

Bueno, ¡adivina qué! Yo ya lo he hecho, ¡y me muero por compartir la información con todo el mundo! Has venido al lugar adecuado. Este documento debería dar al programador C competente, la ventaja que necesita para controlar este ruido de redes.

Y compruébalo: Por fin me he puesto al día con el futuro (¡justo a tiempo, además!) y he actualizado la Guía para IPv6. ¡Así que, aproveche!


## Audiencia

Este documento ha sido escrito como un tutorial, no como una referencia completa. Es probablemente mejor cuando lo leen personas que están empezando con la programación de sockets y están buscando un punto de apoyo. Ciertamente no es la guía _completa y total_ para la programación de sockets, ni mucho menos.

Con suerte, será suficiente para que esas páginas de manual empiecen a tener sentido... `:-)`


## Plataforma y compilador

El código contenido en este documento fue compilado en un PC con Linux utilizando el compilador [i[Compilers-->GCC]] de Gnu `gcc`. Sin embargo, debería compilarse en casi cualquier plataforma que utilice `gcc`. Naturalmente, esto no se aplica si estás programando para Windows---ver la [sección sobre programación para Windows](#windows), más abajo.


## Página oficial y libros a la venta

La ubicación oficial de este documento es

* [`https://beej.us/guide/bgnet/`](https://beej.us/guide/bgnet/)
Allí también encontrará ejemplos de código y traducciones de la guía a varios idiomas.

Para comprar ejemplares impresos bien encuadernados (algunos los llaman «libros»), visite:

* [`https://beej.us/guide/url/bgbuy`](https://beej.us/guide/url/bgbuy)

Agradeceré la compra porque me ayuda a mantener mi estilo de vida de escritor de documentos.

## Nota para programadores de Solaris/SunOS {#solaris}

Al compilar para [i[Solaris]] Solaris o [i[SunOS]] SunOS, necesita especificar algunos modificadores extra en la línea de comandos para enlazar las librerías apropiadas. Para ello, simplemente añada "`-lnsl -lsocket -lresolv`" al final de la orden de compilación, de la siguiente manera:

```
$ cc -o server server.c -lnsl -lsocket -lresolv
```

Si sigues obteniendo errores, puedes intentar añadir `-lxnet` al final de la línea de comandos. No sé qué hace eso exactamente, pero algunas personas parecen necesitarlo.

Otro lugar donde podrías encontrar problemas es en la llamada a `setsockopt()`. El prototipo difiere del de mi caja Linux, así que en lugar de:

```{.c}
int yes=1;
```

introduce esto:

```{.c}
char yes='1';
```

Como no tengo caja Sun, no he comprobado ninguna de las informaciones anteriores; es sólo lo que la gente me ha dicho por correo electrónico.

## Nota para programadores Windows {#windows}

En este punto de la guía, históricamente, he hecho un poco de bolsa en [i[Windows]] Windows, simplemente debido al hecho de que no me gusta mucho. Pero debería ser justo y decirles que Windows tiene una base de instalación enorme y que, obviamente, es un sistema operativo perfectamente válido.

Dicen que la ausencia hace que el corazón se encariñe, y en este caso, creo que es cierto (o tal vez sea la edad). Pero lo que puedo decir es que después de más de una década sin utilizar sistemas operativos de Microsoft para mi trabajo personal, ¡soy mucho más feliz! Como tal, puedo sentarme y decir con seguridad: «¡Claro, siéntete libre de usar Windows!».  ...Bueno, sí... me hace rechinar los dientes decir eso.

Así que te animo a que pruebes [i[Linux]] [fl[Linux|https://www.linux.com/]], [i[BSD]] [fl[BSD|https://bsd.org/]], o algún tipo de Unix.

Pero a la gente le gusta lo que le gusta, y a vosotros, los de Windows, les gustará saber que esta información es aplicable en general a vosotros, con algunos cambios menores, si los hay.

Otra cosa que deberías tener muy en cuenta es[i[WSL]] [i[Windows
Subsystem For Linux]] el [fl[Subsistema Windows para Linux|https://learn.microsoft.com/en-us/windows/wsl/]]. Esto básicamente le permite instalar una cosa Linux VM-ish en Windows 10. Eso también te situará definitivamente, y podrás construir y ejecutar estos programas tal cual.

Algo genial que puedes hacer es instalar [i[Cygwin]] [fl[Cygwin|https://cygwin.com/]], que es una colección de herramientas Unix para Windows. He oído por ahí que hacerlo permite compilar todos estos programas sin modificarlos, pero nunca lo he probado.

Pero puede que algunos de vosotros queráis hacer las cosas a la manera de Windows. Eso es muy valiente de tu parte, y esto es lo que tienes que hacer: ¡corre y consigue Unix inmediatamente! No, no... estoy bromeando. Se supone que soy Windows-friendly(er) estos días...

[i[Winsock]]

Esto es lo que tendrás que hacer: primero, ignora casi todos los ficheros de cabecera del sistema que menciono aquí. En su lugar, incluye:

```{.c}
#include <winsock2.h>
#include <ws2tcpip.h>
```

`winsock2` es la «nueva» versión (circa 1994) de la librería de sockets de Windows.

Desafortunadamente, si incluyes `windows.h`, automáticamente te trae el antiguo fichero de cabecera `winsock.h` (versión 1) que entra en conflicto con `winsock2.h`. Qué divertido.

Así que si tienes que incluir `windows.h`, necesitas definir una macro para que _no_ incluya la cabecera antigua:

```{.c}
#define WIN32_LEAN_AND_MEAN // Di esto...

#include <windows.h> // Y ahora podemos incluir esto.
#include <winsock2.h> // Y esto.
```

Espera! También tienes que hacer una llamada a [i[`WSAStartup()` function]] `WSAStartup()` antes de hacer cualquier otra cosa con la librería de sockets. A esta función le pasas la versión de Winsock que desees (por ejemplo, la versión 2.2). Y entonces puedes comprobar el resultado para asegurarte de que esa versión está disponible.

El código para hacerlo se parece a esto:

[[book-pagebreak]]

```{.c .numberLines}
#include <winsock2.h>

{
    WSADATA wsaData;

    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        fprintf(stderr, "WSAStartup failed.\n");
        exit(1);
    }

    if (LOBYTE(wsaData.wVersion) != 2 ||
        HIBYTE(wsaData.wVersion) != 2)
    {
        fprintf(stderr,"Versiion 2.2 of Winsock is not available.\n");
        WSACleanup();
        exit(2);
    }
```

Tenga en cuenta que la llamada a [i[`WSACleanup()` function]] `WSACleanup()`. Eso es lo que quieres llamar cuando hayas terminado con la librería Winsock.

También tienes que decirle a tu compilador que enlace la librería Winsock, llamada `ws2_32.lib` para Winsock 2. En VC++, esto se puede hacer a través del menú `Project`, en `Settings...`. Haz click en la pestaña `Link`, y busca la casilla titulada «Object/library modules». Añade «ws2_32.lib» (o la librería que prefieras) a la lista.

O eso he oído.

Una vez hecho esto, el resto de los ejemplos de este tutorial deberían aplicarse en general, con algunas excepciones. Por un lado, no puedes usar `close()` para cerrar un socket---necesitas usar [i[`closesocket()` function]] , en su lugar. Además, la función [i[`select()` function]] `select()` sólo funciona con descriptores de socket, no con descriptores de fichero (como `0` para `stdin`).

También hay una clase socket que puedes usar,i[`CSocket` class]]
[`CSocket`](https://learn.microsoft.com/en-us/cpp/mfc/reference/csocket-class?view=msvc-170) 
Consulta las páginas de ayuda de tu compilador para más información.

Para obtener más información sobre Winsock, [consulte la página oficial de Microsoft](https://learn.microsoft.com/en-us/windows/win32/winsock/windows-sockets-start-page-2).

Por último, he oído que Windows no tiene [i[`fork()` function]] `fork()`que, por desgracia, se utiliza en algunos de mis ejemplos. Quizás tengas que enlazar una librería POSIX o algo para que funcione, o puedes usar [i[`CreateThread()` function]] `CreateProcess()` en su lugar. `fork()` no toma argumentos, y `CreateProcess()` toma alrededor de 48 mil millones de argumentos. Si no estás preparado, la función [i[`CreateThread()` function]] `CreateThread()` es un poco más fácil de digerir... desafortunadamente una discusión sobre multithreading está más allá del alcance de este documento. No puedo hablar de mucho, ¡ya sabes!

Por último, Steven Mitchell ha [fl[portado varios de los ejemplos|https://www.tallyhawk.net/WinsockExamples/]] a Winsock. Échale un vistazo.


## Política de correo electrónico

Generalmente estoy disponible para ayudar con preguntas por correo electrónico, así que siéntete libre de escribirme, pero no puedo garantizar una respuesta. Llevo una vida muy ajetreada y a veces no puedo responder a tus preguntas. Cuando es así, suelo borrar el mensaje. No es nada personal; simplemente, nunca tendré tiempo para dar la respuesta detallada que necesitas.

Por regla general, cuanto más compleja es la pregunta, menos probable es que responda. Si puedes reducir tu pregunta antes de enviarla y te aseguras de incluir toda la información pertinente (como la plataforma, el compilador, los mensajes de error que recibes y cualquier otra cosa que creas que puede ayudarme a solucionar el problema), es mucho más probable que recibas una respuesta. Para más información, lea el documento de ESR [fl[Cómo hacer preguntas de forma inteligente|http://www.catb.org/~esr/faqs/smartquestions.html]].

Si no recibes respuesta, dale más vueltas, intenta encontrar la respuesta y, si sigue sin aparecer, vuelve a escribirme con la información que hayas encontrado y, con suerte, será suficiente para que pueda ayudarte.

Ahora que ya te he dado la lata con lo de escribirme y no escribirme, me gustaría que supieras que agradezco _completamente_ todos los elogios que ha recibido la guía a lo largo de los años. Es una auténtica inyección de moral, ¡y me alegra saber que se utiliza para el bien! Gracias.


## Mirroring

[i[Mirroring the Guide]]  Eres más que bienvenido a replicar este sitio, ya sea pública o privadamente. Si lo haces público y quieres que lo enlace desde la página principal, escríbeme a [`beej@beej.us`](beej@beej.us).


## Nota para los traductores

[i[Translating the Guide]] Si quieres traducir la guía a otro idioma, escríbeme a [`beej@beej.us`](beej@beej.us) y pondré un enlace a tu traducción desde la página principal. No dudes en añadir tu nombre e información de contacto a la traducción.

Este documento fuente markdown utiliza codificación UTF-8.

Por favor, ten en cuenta las restricciones de licencia en la sección [Copyright, Distribución y Legal](#legal), más abajo.

Si quieres que aloje la traducción, sólo tienes que pedírmelo. También pondré un enlace a ella si quieres alojarla; cualquiera de las dos opciones está bien.


## Copyright, distribución y legal {#legal}

La Guía del Beej para la programación en red es Copyright © 2019 Brian «Beej Jorgensen» Hall.

Con excepciones específicas para el código fuente y las traducciones, a continuación, este trabajo está bajo la licencia Creative Commons Attribution- Noncommercial-No Derivative Works 3.0 License. Para ver una copia de esta licencia, visite

[`https://creativecommons.org/licenses/by-nc-nd/3.0/`](https://creativecommons.org/licenses/by-nc-nd/3.0/)

o envíe una carta a Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, EE.UU.

Una excepción específica a la parte de la licencia relativa a la «Prohibición de obras derivadas» es la siguiente: esta guía puede traducirse libremente a cualquier idioma, siempre que la traducción sea exacta, y la guía se reimprima en su totalidad. Se aplicarán a la traducción las mismas restricciones de licencia que a la guía original. La traducción también puede incluir el nombre y la información de contacto del traductor.

El código fuente en C presentado en este documento es de dominio público y está totalmente libre de cualquier restricción de licencia.

Se anima libremente a los educadores a recomendar o suministrar copias de esta guía a sus alumnos.

A menos que las partes acuerden lo contrario por escrito, el autor ofrece la obra tal como está y no hace representaciones o garantías de ningún tipo con respecto a la obra, expresas, implícitas, estatutarias o de otro tipo, incluyendo, sin limitación, garantías de título, comerciabilidad, idoneidad para un propósito particular, no infracción, o la ausencia de defectos latentes o de otro tipo, exactitud, o la presencia o ausencia de errores, sean o no descubribles.

Salvo en la medida en que lo exija la legislación aplicable, en ningún caso el autor será responsable ante usted, bajo ninguna teoría legal, de ningún daño especial, incidental, consecuente, punitivo o ejemplar derivado del uso de la obra, incluso si el autor ha sido advertido de la posibilidad de tales daños.
Contact [`beej@beej.us`](mailto:beej@beej.us) for more information.

## Dedicatoria

Gracias a todos los que me han ayudado en el pasado y en el futuro a escribir esta guía. Y gracias a toda la gente que produce el software Libre y los paquetes que utilizo para hacer la Guía: GNU, Linux, Slackware, vim, Python, Inkscape, pandoc, muchos otros. Y, por último, un gran agradecimiento a los miles de personas que me han escrito con sugerencias de mejora y palabras de ánimo.

Dedico esta guía a algunos de mis mayores héroes e inspiradores en el mundo de la informática: Donald Knuth, Bruce Schneier, W. Richard Stevens y The Woz, a mis lectores y a toda la comunidad del software libre y de código abierto.


## Información de publicación

Este libro está escrito en Markdown usando el editor vim en una caja Arch Linux cargada con herramientas GNU. El «arte» de la portada y los diagramas están hechos con Inkscape.  El Markdown se convierte a HTML y LaTex/PDF con Python, Pandoc y XeLaTeX, utilizando fuentes Liberation. La cadena de herramientas está compuesta al 100% por software libre y de código abierto.
