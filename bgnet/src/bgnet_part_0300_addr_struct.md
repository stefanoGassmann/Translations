# Direcciones IP, `struct`s y Data Munging

Esta es la parte del juego en la que (para variar) vamos a hablar de código.

Pero primero, ¡discutiremos más sobre no código!. Quiero hablar sobre [i[IP address]] direcciones IP y puertos para que lo tengamos claro.  Luego hablaremos de cómo la API de sockets almacena y manipula las direcciones IP y otros datos.

## Direcciones IP, versiones 4 y 6

En los viejos tiempos, cuando Ben Kenobi aún se llamaba Obi Wan Kenobi, existía un maravilloso sistema de enrutamiento de red llamado Protocolo de Internet versión 4, también llamado IPv4 [i[IPv4]]. Tenía direcciones formadas por cuatro bytes (también conocidos como cuatro "octetos"), y se escribía habitualmente en forma de "puntos y números", como por ejemplo `192.0.2.111`.

Seguro que lo has visto por ahí.

De hecho, en el momento de escribir estas líneas, prácticamente todos los sitios de Internet utilizan IPv4.

Todo el mundo, incluido Obi Wan, estaba contento. Todo iba genial, hasta que un pesimista llamado Vint Cerf advirtió a todo el mundo de que estábamos a punto de quedarnos sin direcciones IPv4.

(Además de advertir a todo el mundo de la llegada del Apocalipsis IPv4, [i[Vint Cerf]] [flw[Vint Cerf|Vint_Cerf]]también es conocido por ser el padre de Internet. Así que no estoy en posición de cuestionar su juicio).

¿Se han quedado sin direcciones? ¿Cómo es posible? Hay miles de millones de direcciones IP en una dirección IPv4 de 32 bits. ¿Realmente tenemos miles de millones de ordenadores ahí fuera?

Sí.

Además, al principio, cuando sólo había unos pocos ordenadores y todo el mundo pensaba que mil millones era un número imposiblemente grande, a algunas grandes organizaciones se les asignaron generosamente millones de direcciones IP para su propio uso. (Como Xerox, MIT, Ford, HP, IBM, GE, AT&T y una pequeña empresa llamada Apple, por nombrar algunas).

De hecho, si no fuera por varias medidas provisionales, nos habríamos quedado sin ellas hace mucho tiempo.

Pero ahora vivimos en una era en la que hablamos de que cada ser humano tiene una dirección IP, cada ordenador, cada calculadora, cada teléfono, cada parquímetro y (por qué no) también cada perrito.

Y así, [i[IPv6]] IPv6 nació. Como Vint Cerf es probablemente inmortal
(aunque su forma física falleciera, Dios no lo quiera, probablemente ya exista como una especie de programa hiperinteligente [flw[ELIZA|ELIZA]] en las profundidades de Internet2), nadie quiere tener que oírle decir otra vez "te lo dije" si no tenemos suficientes direcciones en la próxima versión del Protocolo de Internet.

¿Qué le sugiere esto?

Que necesitamos _muchas_ más direcciones. Que necesitamos no sólo el doble de direcciones, no mil millones de veces más, no mil billones de veces más, sino ¡79 MILLONES DE MILLONES DE TRILLONES de veces más direcciones posibles!_ ¡Eso les enseñará!

Dices: "B.J., ¿es cierto? Tengo motivos para no creer en los números grandes".  Bueno, la diferencia entre 32 bits y 128 bits puede no parecer mucha; son sólo 96 bits más, ¿verdad? Pero recuerde que estamos hablando de potencias: 32 bits representan unos 4.000 millones de números (2^32^), mientras que 128 bits representan unos 340 billones de billones de billones de números (de verdad, 2^128^).  Eso es como un millón de Internets IPv4 para _cada estrella del Universo_.

Olvídate también del aspecto de puntos y números de IPv4; ahora tenemos una representación hexadecimal, con cada trozo de dos bytes separado por dos puntos, así:

```
2001:0db8:c9d2:aee5:73e3:934a:a5ae:9551
```

Pero eso no es todo. Muchas veces, tendrás una dirección IP con muchos ceros, y puedes comprimirlos entre dos dos puntos. Y puedes dejar ceros a la izquierda para cada par de bytes. Por ejemplo, cada uno de estos pares de direcciones son equivalentes:

```
2001:0db8:c9d2:0012:0000:0000:0000:0051
2001:db8:c9d2:12::51

2001:0db8:ab00:0000:0000:0000:0000:0000
2001:db8:ab00::

0000:0000:0000:0000:0000:0000:0000:0001
::1
```

La dirección `::1` es la dirección _loopback_. Siempre significa "esta máquina, en la que estoy funcionando ahora". En IPv4, la dirección loopback es `127.0.0.1`.

Por último, existe un modo de compatibilidad IPv4 para las direcciones IPv6 con el que te puedes encontrar. Si quieres, por ejemplo, representar la dirección IPv4 `192.0.2.33` como una dirección IPv6, utiliza la siguiente notación: `::ffff:192.0.2.33`.

Estamos hablando de diversión en serio.

De hecho, es tan divertido que los creadores de IPv6 han recortado con bastante displicencia billones y billones de direcciones para uso reservado, pero tenemos tantas que, francamente, ¿quién lleva ya la cuenta? Sobran para todos los hombres, mujeres, niños, cachorros y parquímetros de todos los planetas de la galaxia.  Y créeme, todos los planetas de la galaxia tienen parquímetros. Sabes que es verdad.


### Subredes

Por razones organizacionales, a veces es conveniente declarar que "esta primera parte de esta dirección IP, hasta este bit es la porción de red de la dirección IP, y el resto es la porción de host".

Por ejemplo, con IPv4, podrías tener 192.0.2.12, y podríamos decir que los primeros tres bytes son la red y el último byte es el host. O, dicho de otra manera, estamos hablando del host 12 en la red 192.0.2.0 (observa cómo ponemos en cero el byte que era el host).

¡Y ahora, más información desactualizada! ¿Listo?
 En los Tiempos Antiguos, había "clases" de subredes, donde el primer byte, segundo byte o tercer byte de la dirección, era la parte de red. Si tenías la suerte de tener un byte para la red y tres para el host, podrías tener 24 bits de hosts en tu red (alrededor de 16 millones). Eso era una red de "Clase A". En el extremo opuesto estaba la "Clase C", con tres bytes para la red y un byte para el host (256 hosts, menos un par que estaban reservados).

Como puedes ver, había solo unas pocas redes Clase A, una gran cantidad de redes Clase C, y algunas redes Clase B en el medio.

La porción de red de la dirección IP se describe con algo llamado "máscara de red", con la cual haces una operación bit a bit "AND" con la dirección IP para obtener el número de red. La máscara de red usualmente se ve algo como 255.255.255.0. (Por ejemplo, con esa máscara de red, si tu IP es 192.0.2.12, entonces tu red es 192.0.2.12 Y 255.255.255.0, lo que da 192.0.2.0).

Desafortunadamente, resultó que esto no era lo suficientemente detallado para las necesidades futuras de Internet; nos estábamos quedando sin redes Clase C bastante rápido, y definitivamente nos habíamos quedado sin redes Clase A, así que ni siquiera te molestes en preguntar. Para solucionar esto, los poderes que sean permitieron que la máscara de red fuera un número arbitrario de bits, no solo 8, 16 o 24. Así que podrías tener una máscara de red de, por ejemplo, 255.255.255.252, que son 30 bits de red, y 2 bits de host, lo que permite cuatro hosts en la red. (Ten en cuenta que la máscara de red es SIEMPRE un montón de bits en 1 seguidos por un montón de bits en 0).

Pero es un poco incómodo usar una larga cadena de números como 255.192.0.0 como una máscara de red. En primer lugar, las personas no tienen una idea intuitiva de cuántos bits son, y en segundo lugar, no es realmente compacto. Así que apareció el "nuevo estilo", y es mucho más agradable. Simplemente colocas una barra diagonal después de la dirección IP, y luego sigues eso con el número de bits de red en decimal. Como esto: 192.0.2.12/30.

O, para IPv6, algo como esto: 2001:db8::/32 o 2001:db8:5413:4028::9db9/64.


### Números de puerto

Si eres tan amable de recordar, te presenté antes el [modelo de red por capas(Layered Network Model)](#lowlevel) que tenía la Capa de Internet (IP) dividida de la Capa de Transporte de Host a Host (TCP y UDP). Ponte al día antes del siguiente párrafo.

Resulta que además de una dirección IP (usada por la capa IP), hay otra dirección que es usada por TCP (stream sockets) y, coincidentemente, por UDP (datagram sockets). Se trata del _número de puerto_. Es un número de 16 bits que es como la dirección local de la conexión.

Piense en la dirección IP como la dirección de la calle de un hotel, y en el número de puerto como el número de la habitación. Es una analogía decente; quizá más adelante se me ocurra una que tenga que ver con la industria del automóvil. Digamos que quieres tener un ordenador que gestione el correo entrante y los servicios web... ¿cómo diferenciar ambos en un ordenador con una única dirección IP

Bueno, los diferentes servicios de Internet tienen diferentes números de puerto bien conocidos.  Puedes verlos todos en [fl[la gran lista de puertos de IANA|https://www.iana.org/assignments/port-numbers]] o, si estás en una máquina Unix, en tu archivo `/etc/services`. HTTP (la web) es el puerto 80, telnet es el puerto 23, SMTP es el puerto 25, el juego [fl[DOOM|https://en.wikipedia.org/wiki/Doom_(1993_video_game)]] usaba el puerto 666, etc. y así sucesivamente. Los puertos por debajo de 1024 suelen considerarse especiales, y normalmente requieren privilegios especiales del sistema operativo para su uso.

Y eso es todo.

##  Ordenación de bytes

[i[Byte ordering]] ¡Por orden del Reino! Habrá dos ordenaciones de bytes, a partir de ahora conocidas como ¡Lame y Magnificent!

Es broma, pero una es mejor que la otra. `:-)`

No hay forma fácil de decirlo, así que lo diré sin rodeos: puede que tu ordenador haya estado almacenando bytes en orden inverso a tus espaldas. ¡Ya lo sé! Nadie quería tener que decírtelo.

El caso es que todo el mundo en Internet está de acuerdo en que si quieres representar un número hexadecimal de dos bytes, digamos `b34f`, lo almacenarás en dos bytes secuenciales `b3` seguidos de `4f`. Tiene sentido y, como te diría [fl[Wilford Brimley|https://en.wikipedia.org wiki/Wilford_Brimley]], es lo correcto. Este número, almacenado con el extremo grande primero, se llama _Big-Endian_.

Desgraciadamente, unos pocos ordenadores repartidos por el mundo, es decir, los que tienen un procesador Intel o compatible con Intel, almacenan los bytes al revés, de modo que `b34f` se almacenaría en memoria como los bytes secuenciales `4f` seguidos de `b3`. Este método de almacenamiento se llama _Little-Endian_.

Pero espera, ¡aún no he terminado con la terminología! El más sensato _Big-Endian_ también se llama _Network Byte Order_ porque es el orden que nos gusta a los tipos de red.

Tu ordenador almacena los números en _Host Byte Order_. Si es un Intel 80x86, el orden de los bytes es Little-Endian. Si es un Motorola 68k, el Host Byte Order es Big-Endian. Si es un PowerPC, el orden de bytes del host es... bueno, ¡depende!

Muchas veces cuando estás construyendo paquetes o rellenando estructuras de datos necesitarás asegurarte de que tus números de dos y cuatro bytes están en Network Byte Order. Pero, ¿cómo puedes hacerlo si no conoces el orden de bytes nativo del host?

Buenas noticias. Sólo tienes que asumir que el Orden de Bytes del Host no es correcto, y siempre pasas el valor a través de una función para ajustarlo al Orden de Bytes de la Red. La función hará la conversión mágica si es necesario, y de esta manera tu código es portable a máquinas de diferente endianness.

Muy bien. Hay dos tipos de números que puedes convertir: `short` (dos bytes) y `long` (cuatro bytes). Estas funciones también funcionan para sus variaciones `unsigned`. Digamos que quieres convertir un `short` de Host Byte Order a Network Byte Order. Empieza con «h» para «host», sigue con «to», luego «n» para «network», y «s» para «short»: h-to-n-s, o `htons()` (léase: «Host to Network Short»).

Es casi demasiado fácil...

Puedes usar todas las combinaciones de «n», «h», «s» y «l» que quieras, sin contar las realmente estúpidas. Por ejemplo, NO hay una función `stolh()` («Short to long host») --no en esta fiesta, al menos. Pero la hay:

[[book-pagebreak]]

| Función   | Descripción                   |
|-----------|-------------------------------|
| [i[`htons()` function]]`htons()` | `h`ost `to` `n`etwork `s`hort|
| [i[`htonl()` function]]`htonl()` | `h`ost `to` `n`etwork `l`ong |
| [i[`ntohs()` function]]`ntohs()` | `n`etwork `to` `h`ost `s`hort|
| [i[`ntohl()` function]]`ntohl()` | `n`etwork `to` `h`ost `l`ong |

Básicamente, querrás convertir los números al orden de bytes de red antes de que salgan por el cable, y convertirlos al orden de bytes de host cuando entren por el cable.

No conozco una variante de 64 bits, lo siento. Y si quieres hacer coma flotante, echa un vistazo a la sección sobre [Serialization](#serialization), más abajo.

Asuma que los números en este documento están en el orden de bytes del host a menos que yo diga lo contrario.


## `struct`s {#structs}

Bueno, por fin estamos aquí. Es hora de hablar de programación. En esta sección, cubriré varios tipos de datos usados por la interfaz de sockets, ya que algunos de ellos son realmente difíciles de entender.

Primero el más fácil: un [i[Socket descriptor]] descriptor de socket. Un descriptor de socket es del siguiente tipo:

```{.c}
int
```
Sólo un `int` normal.

Las cosas se ponen raras a partir de aquí, así que lee y ten paciencia conmigo.

Mi primera Struct™---`struct addrinfo`. [i[`struct addrinfo` type]] Esta estructura es una invención más reciente, y se utiliza para preparar las estructuras de direcciones de socket para su uso posterior. También se usa en búsquedas de nombres de host, y búsquedas de nombres de servicio. Esto tendrá sentido más adelante, cuando lleguemos al uso real, pero por ahora sepa que es una de las primeras cosas que llamará cuando haga una conexión.

```{.c}
struct addrinfo {
    int              ai_flags;     // AI_PASSIVE, AI_CANONNAME, etc.
    int              ai_family;    // AF_INET, AF_INET6, AF_UNSPEC
    int              ai_socktype;  // SOCK_STREAM, SOCK_DGRAM
    int              ai_protocol;  // utilice 0 para "cualquiera"
    size_t           ai_addrlen;   // tamaño de ai_addr en bytes
    struct sockaddr *ai_addr;      // struct sockaddr_in o _in6
    char            *ai_canonname; // nombre de host canónico completo

    struct addrinfo *ai_next;      // lista enlazada, nodo siguiente
};
```

Cargarás un poco esta estructura y luego llamarás a la función [i[`getaddrinfo()` function]] `getaddrinfo()`. Devolverá un puntero a una nueva lista enlazada de estas estructuras, rellenada con todo lo que necesites.

Puedes forzar el uso de IPv4 o IPv6 en el campo `ai_family`, o dejarlo como `AF_UNSPEC` para usar lo que quieras. Esto es genial porque tu código puede ser agnóstico a la versión IP

Ten en cuenta que se trata de una lista enlazada: `ai_next` apunta al siguiente elemento---podría haber varios resultados entre los que elegir. Yo usaría el primer resultado que funcionara, pero puede que tengas necesidades de negocio diferentes; ¡no lo sé todo!

Verás que el campo `ai_addr` de la `struct addrinfo` es un puntero a una [i[`struct sockaddr` type]] `struct sockaddr`. Aquí es donde empezamos a entrar en los detalles de lo que hay dentro de una estructura de dirección IP.

Normalmente no necesitarás escribir en estas estructuras; a menudo, una llamada a `getaddrinfo()` para rellenar tu `struct addrinfo` es todo lo que necesitarás.  Sin embargo, tendrás que mirar dentro de estas `struct`s para obtener los valores, así que te los presento aquí.

(Además, todo el código escrito antes de que se inventara la `struct addrinfo` empaquetaba todo esto a mano, así que verás mucho código IPv4 que hace exactamente eso). Ya sabes, en versiones antiguas de esta guía y demás).

Algunas `struct`s son IPv4, algunas son IPv6, y algunas son ambas. Tomaré nota de cuales son cuales.

De todos modos, la `struct sockaddr` contiene información de direcciones de sockets para muchos tipos de sockets.

```{.c}
struct sockaddr {
    unsigned short    sa_family;    // familia de direcciones, AF_xxx
    char              sa_data[14];  // 14 bytes de dirección de protocolo
}; 
```

`sa_family` puede ser una variedad de cosas, pero será [i[`AF_INET`
macro]] `AF_INET` (IPv4) o [i[`AF_INET6` macro]] `AF_INET6` (IPv6) para todo lo que hagamos en este documento. `sa_data` contiene una dirección de destino y un número de puerto para el socket. Esto es poco manejable ya que no querrás empaquetar tediosamente la dirección en `sa_data` a mano.

Para tratar con `struct sockaddr`, los programadores crearon una estructura paralela: [i[`struct sockaddr` type]] `struct sockaddr_in` («in» por «Internet») para ser usada con IPv4.

Y _esto es lo importante_: un puntero a `struct sockaddr_in` puede convertirse en un puntero a `struct sockaddr` y viceversa. Así que aunque `connect()` quiera una `struct sockaddr*`, puedes usar una `struct sockaddr_in` y convertirla en el último momento.

```{.c}
// (Sólo IPv4 - véase struct sockaddr_in6 para IPv6)

struct sockaddr_in {
    short int          sin_family;  // Familia de direcciónes, AF_INET
    unsigned short int sin_port;    // Número de puerto.
    struct in_addr     sin_addr;    // Dirección de Internet
    unsigned char      sin_zero[8]; // Mismo tamaño que struct sockaddr
};
```

Esta estructura facilita la referencia a elementos de la dirección del socket. Tenga en cuenta que `sin_zero` (que se incluye para rellenar la estructura a la longitud de una `struct sockaddr`) debe establecer cada byte completamnete a cero con la función `memset()`.  Además, observe que `sin_family` corresponde a `sa_family` en una `struct sockaddr` y debe establecerse a `AF_INET`. Por último, `sin_port` debe estar en [i[Byte ordering]] _Network Byte Order_ (usando [i[`htons()` function]] `htons()`)

Profundicemos un poco más. Ves que el campo `sin_addr` es una `struct in_addr`. ¿Qué es eso? Bueno, no quiero ser demasiado dramático, pero es una de las uniones más aterradoras de todos los tiempos:

```{.c}
// (sólo IPv4; véase struct in6_addr para IPv6)

// Dirección de Internet (una estructura por razones históricas)
struct in_addr {
    uint32_t s_addr; // es un int de 32 bits (4 bytes)
};
```

¡Vaya! Bueno, solía ser un sindicato, pero ahora parece que esos días se han ido. Hasta nunca. Así que si has declarado que `ina` es del tipo `struct sockaddr_in`, entonces `ina.sin_addr.s_addr` hace referencia a la dirección IP de 4 bytes (en orden de bytes de red).  Tenga en cuenta que incluso si su sistema todavía utiliza la horrible unión para `struct in_addr`, todavía puede hacer referencia a la dirección IP de 4 bytes exactamente de la misma manera que lo hice anteriormente (esto debido a `#define`).

¿Qué pasa con [i[IPv6]] IPv6? También existen `struct`s similares para ello:

```{.c}
// (sólo IPv6; véase struct sockaddr_in y struct in_addr para IPv4)

struct sockaddr_in6 {
    u_int16_t       sin6_family;   // Familia de direcciónes, AF_INET6
    u_int16_t       sin6_port;     // número de puerto, orden de bytes de red
    u_int32_t       sin6_flowinfo; // Información de flujo IPv6
    struct in6_addr sin6_addr;     // Dirección IPv6
    u_int32_t       sin6_scope_id; // Alcance ID
};

struct in6_addr {
    unsigned char   s6_addr[16];   // Dirección IPv6
};
```

Ten en cuenta que IPv6 tiene una dirección IPv6 y un número de puerto, igual que IPv4 tiene una dirección IPv4 y un número de puerto.

También ten en cuenta que no voy a hablar de la información de flujo IPv6 o de los campos Scope ID por el momento... esto es sólo una guía para principiantes. `:-)`

Por último, pero no menos importante, aquí hay otra estructura simple, `struct sockaddr_storage` que está diseñada para ser lo suficientemente grande como para contener estructuras IPv4 e IPv6. Verás, para algunas llamadas, a veces no sabes de antemano si se va a rellenar tu `struct sockaddr` con una dirección IPv4 o IPv6. Así que pasas esta estructura paralela, muy similar a `struct sockaddr` excepto que es más grande, y luego la transformas al tipo que necesitas:

```{.c}
struct sockaddr_storage {
    sa_family_t  ss_family;     // familia de direcciones

    // todo esto es relleno, específico de la implementación, ignóralo:
    char      __ss_pad1[_SS_PAD1SIZE];
    int64_t   __ss_align;
    char      __ss_pad2[_SS_PAD2SIZE];
};
```

Lo importante es que puedas ver la familia de direcciones en el campo `ss_family`; comprueba si es `AF_INET` o `AF_INET6` (para IPv4 o IPv6).  Entonces puedes convertirlo en una `struct sockaddr_in` o `struct sockaddr_in6` si quieres.


## Direcciones IP, segunda parte

Afortunadamente para ti, hay un montón de funciones que te permiten manipular [i[IP address]] direcciones IP. No necesitas calcularlas a mano y meterlas en un `long` con el operador `<<`.

Primero, digamos que tienes una `struct sockaddr_in ina`, y tienes una dirección IP `10.12.110.57` o `2001:db8:63b3:1::3490` que quieres almacenar en ella. La función que quieres usar, [i[`inet_pton()` function]] `inet_pton()`, convierte una dirección IP en notación de números y puntos en una `struct in_addr` o una `struct in6_addr` dependiendo de si especifica `AF_INET` o `AF_INET6`. (`pton` significa "Presentation to Network"--puedes llamarlo "Print to Network" si te resulta más fácil de recordar). La conversión puede hacerse de la siguiente manera:

```{.c}
struct sockaddr_in sa; // IPv4
struct sockaddr_in6 sa6; // IPv6

inet_pton(AF_INET, "10.12.110.57", &(sa.sin_addr)); // IPv4
inet_pton(AF_INET6, "2001:db8:63b3:1::3490", &(sa6.sin6_addr)); // IPv6

```

(Nota rápida: la forma antigua de hacer las cosas utilizaba una función llamada [i[`inet_addr()` function]] `inet_addr()` u otra función llamada [i[`inet_aton()` function]] `inet_aton()`; ahora están obsoletas y no funcionan con IPv6).

Ahora bien, el fragmento de código anterior no es muy robusto porque no hay comprobación de errores. Verás, `inet_pton()` devuelve `-1` en caso de error, o 0 si la dirección es incorrecta. Así que comprueba que el resultado es mayor que 0 antes de usarlo.

Muy bien, ahora puedes convertir direcciones IP de cadena a sus representaciones binarias. ¿Y al revés? ¿Qué pasa si tienes una `struct in_addr` y quieres imprimirla en notación de números y puntos? (O una `struct in6_addr` que quieres en, uh, notación «hex-and-colons».) En este caso, querrás usar la función [i[`inet_ntop()` function]] `inet_ntop()` (`ntop` significa "Network to presentation"--puedes llamarlo "Network to print" si es más fácil de recordar), así:

```{.c .numberLines}
// IPv4:

char ip4[INET_ADDRSTRLEN];  // espacio para la cadena IPv4
struct sockaddr_in sa;      // pretender que esto se carga con algo

inet_ntop(AF_INET, &(sa.sin_addr), ip4, INET_ADDRSTRLEN);

printf("The IPv4 address is: %s\n", ip4);


// IPv6:

char ip6[INET6_ADDRSTRLEN]; // espacio para la cadena IPv6
struct sockaddr_in6 sa6;    // pretender que esto se carga con algo

inet_ntop(AF_INET6, &(sa6.sin6_addr), ip6, INET6_ADDRSTRLEN);

printf("The address is: %s\n", ip6);
```

Cuando la llame, le pasará el tipo de dirección (IPv4 o IPv6), la dirección, un puntero a una cadena para guardar el resultado y la longitud máxima de esa cadena.  (Dos macros contienen convenientemente el tamaño de la cadena que necesitarás para contener la dirección IPv4 o IPv6 más grande: `INET_ADDRSTRLEN` y `INET6_ADDRSTRLEN`).

(Otra nota rápida para mencionar una vez más la antigua forma de hacer las cosas: la función histórica para hacer esta conversión se llamaba [i[`inet_ntoa()` function]] `inet_ntoa()`. También está obsoleta y no funcionará con IPv6).

Por último, estas funciones sólo trabajan con direcciones IP numéricas---no harán ninguna búsqueda DNS en un nombre de host, como `www.example.com`. Para ello, como verás más adelante, deberás usar `getaddrinfo()`.

### Redes privadas (o desconectadas)

Muchos lugares tienen un [i[Firewall]] cortafuegos que oculta la red del resto del mundo para su propia protección. Y muchas veces, el cortafuegos traduce las direcciones IP «internas» a direcciones IP «externas» (que todo el mundo conoce) mediante un proceso llamado _Network Address Translation_, o [i[NAT]] NAT.

¿Ya te estás poniendo nervioso? "¿A dónde quiere llegar con todas estas cosas raras?".

Bueno, relájate y cómprate una bebida sin alcohol (o alcohólica), porque como principiante, ni siquiera tienes que preocuparte por NAT, ya que se hace por ti de forma transparente. Pero quería hablar de la red detrás del cortafuegos por si empezabas a confundirte con los números de red que veías.

Por ejemplo, tengo un cortafuegos en casa. Tengo dos direcciones IPv4 estáticas asignadas por la compañía de DSL, y aún así tengo siete ordenadores en la red. ¿Cómo es posible? Dos ordenadores no pueden compartir la misma dirección IP, de lo contrario los datos no sabrían a cuál dirigirse.

La respuesta es: no comparten las mismas direcciones IP. Están en una red privada con 24 millones de direcciones IP asignadas. Son todas para mí.  Bueno, todas para mí en lo que a los demás se refiere. Esto es lo que ocurre:

Si me conecto a un ordenador remoto, me dice que estoy conectado desde 192.0.2.33, que es la dirección IP pública que me ha proporcionado mi ISP. Pero si le pregunto a mi ordenador local cuál es su dirección IP, me dice 10.0.0.5. ¿Quién está traduciendo la dirección IP de una a otra? ¡Eso es, el cortafuegos! ¡Está haciendo NAT!

`10.x.x.x` es una de las pocas redes reservadas que sólo deben utilizarse en redes totalmente desconectadas o en redes que estén detrás de cortafuegos. Los detalles de qué números de red privada están disponibles para su uso, se describen en [flrfc[RFC 1918|1918]], pero algunos de los más comunes que verá son [i[`10.x.x.x`]] `10.x.x.x` y [i[`192.168.x.x`]] 192.168.x.x», donde “x” es de 0 a 255, generalmente. Menos común es `172.y.x.x`, donde `y` está entre 16 y 31.

Las redes detrás de un cortafuegos NAT no _necesitan_ estar en una de estas redes reservadas, pero suelen estarlo.

(¡Un dato curioso! Mi dirección IP externa no es realmente `192.0.2.33`. La red `192.0.2.x` está reservada para direcciones IP «reales» falsas que se utilizan en la documentación, ¡como en esta guía! Wowzers!)

[i[IPv6]] En cierto sentido, IPv6 también tiene redes privadas. Empezarán con `fdXX:` (o quizás en el futuro `fcXX:`), según [flrfc[RFC 4193|4193]]. NAT e IPv6 generalmente no se mezclan, sin embargo (a menos que estés haciendo lo de la pasarela IPv6 a IPv4, que está más allá del alcance de este documento)---en teoría tendrás tantas direcciones a tu disposición que no necesitarás usar NAT nunca más. Pero si quieres asignar direcciones para ti mismo en una red que no enrutará fuera, así es cómo hacerlo.
