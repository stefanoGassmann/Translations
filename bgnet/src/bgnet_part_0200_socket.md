# ¿Qué es un socket?

Oyes hablar de «sockets» todo el tiempo, y quizá te preguntes qué son exactamente. Bueno, son esto: una forma de hablar con otros programas usando descriptores de fichero estándar de Unix [i[File descriptor]].

¿Qué?

Vale... puede que hayas oído a algún hacker de Unix decir: «¡Jesús, _todo_ en Unix es un archivo!». A lo que esa persona puede haberse referido, es al hecho de que cuando los programas Unix hacen cualquier tipo de E/S, lo hacen leyendo o escribiendo en un descriptor de fichero. Un descriptor de fichero es simplemente un número entero asociado a un fichero abierto. Pero (y aquí está el truco), ese fichero puede ser una conexión de red, un FIFO, una tubería, un terminal, un fichero real en el disco, o cualquier otra cosa.  ¡Todo en Unix _es_ un fichero! Así que cuando quieras comunicarte con otro programa a través de Internet vas a hacerlo a través de un descriptor de fichero, mejor que lo creas.

"¿De dónde saco este descriptor de fichero para la comunicación en red, Sr. Sabelotodo?" es probablemente la última pregunta que ronda por tu cabeza ahora mismo, pero voy a responderla de todos modos: Haces una llamada a la función del sistema[i[`socket()`
function]] `socket()`. Devuelve el descriptor de socket [i[Socket
descriptor]], y te comunicas a través de él usando las funciones especializadas [i[`send()` function]] `send()` y [i[`recv()` function]] `recv()` ([`man send`](#sendman), [`man recv`](#recvman)).

"Pero, ¡eh!", puedes estar exclamando en este momento. "Si es un descriptor de fichero, ¿por qué en el nombre de Neptuno no puedo usar la función normal [i[`read()` function]] `read()` y [i[`write()` function]] `write()` para comunicarme a través del socket?".  La respuesta corta es: ¡Puedes!.  La respuesta más larga es: Puedes, pero [i[`send()` function]] `send()` y [i[`recv()` function]] `recv()` ofrecen un control mucho mayor sobre tu transmisión de datos.

¿Y ahora qué? Qué tal esto: hay todo tipo de sockets. Existen
Direcciones DARPA de Internet (Internet Sockets), nombres de ruta en un nodo local (Unix Sockets), direcciones CCITT X.25 (X.25 Sockets que puedes ignorar sin problemas), y probablemente muchos otros dependiendo del tipo de Unix que utilices.  Este documento sólo trata del primero: Internet Sockets.


## Dos Tipos de Sockets de Internet

¿Qué es esto? ¿Hay dos tipos de sockets de Internet? Sí. Bueno, no. Estoy mintiendo. Hay más, pero no quería asustarte.  Aquí sólo voy a hablar de dos tipos. Excepto en esta frase, donde te voy a decir que [i[Raw sockets]] `Raw Sockets` también son muy potentes y deberías buscarlos.

Muy bien, ya. ¿Cuáles son los dos tipos? Uno es [i[Stream sockets]] "Stream Sockets"; el otro es [i[Datagram sockets]] "Datagram Sockets", que a partir de ahora se llamarán [i[`SOCK_STREAM` macro]]
`SOCK_STREAM` y [i[`SOCK_DGRAM` macro]] `SOCK_DGRAM`, respectivamente. Los sockets de datagramas se denominan a veces "sockets sin conexión".  (Aunque pueden ser [i[`connect()` function]] `connect()` si realmente quieres. Ver [`connect()`](#connect), más abajo).

Los stream sockets son flujos de comunicación bidireccionales conectados de forma fiable. Si introduce dos elementos en la toma en el orden «1, 2», llegarán en el orden «1, 2» al extremo opuesto. También estarán libres de errores. De hecho, estoy tan seguro de que no habrá errores que me pondré los dedos en las orejas y cantaré _la la la la_ si alguien intenta decir lo contrario.

¿Para qué sirven los stream sockets? Bueno, puede que hayas oído hablar de[i[telnet]] `telnet` o `ssh`, ¿verdad? Usan stream sockets. Todos los caracteres que escribes tienen que llegar en el mismo orden en que los escribes, ¿verdad? Además, los navegadores web utilizan el Protocolo de Transferencia de Hipertexto [i[HTTP protocol]] (HTTP) que utiliza sockets de flujo para obtener páginas. De hecho, si te conectas por telnet a un sitio web en el puerto 80, escribes `GET / HTTP/1.0` y pulsas RETURN dos veces, ¡te devolverá el HTML!

> Si no tienes `telnet` instalado y no quieres instalarlo, o
> tu `telnet` está siendo quisquilloso con la conexión a los clientes, la guía
> viene con un programa similar a `telnet` llamado [flx[`telnot`|telnot.c]].
> Esto debería funcionar bien para todas las necesidades de la guía. (Nótese que
> telnet es en realidad un [flrfc[protocolo de red especificado|854]], y
> `telnot` no implementa este protocolo en absoluto).

¿Cómo consiguen los stream sockets este alto nivel de calidad en la transmisión de datos?  Utilizan un protocolo llamado "Protocolo de Control de Transmisión", también conocido como [i[TCP]] `TCP` (vea [flrfc[RFC 793|793]] para información extremadamente detallada sobre TCP). TCP se encarga de que tus datos lleguen secuencialmente y sin errores. Es posible que haya oído antes TCP como la mejor mitad de TCP/IP donde [i[IP]] `IP` significa “Protocolo de Internet” (véase [flrfc[RFC 791|791]]).  IP se ocupa principalmente del enrutamiento en Internet y, por lo general, no es responsable de la integridad de los datos.

[i[Datagram sockets]<]

Genial. ¿Qué pasa con los sockets Datagram? ¿Por qué se llaman sin conexión? ¿De qué se trata? ¿Por qué no son fiables?  Bueno, aquí hay algunos hechos: si envías un datagrama, puede llegar. Puede llegar desordenado. Si llega, los datos dentro del paquete no tendrán errores.

Los sockets de datagramas también usan IP para el enrutamiento, pero no usan TCP; usan el "Protocolo de Datagramas de Usuario", o [i[UDP]] UDP (véase [flrfc[RFC 768|768]]).

¿Por qué son sin conexión? Bueno, básicamente porque no tienes que mantener una conexión abierta como haces con los stream sockets. Simplemente construyes un paquete, le pegas una cabecera IP con información de destino y lo envías.  No se necesita conexión. Generalmente se usan cuando una pila TCP no está disponible o cuando unos pocos paquetes perdidos aquí y allá no significan el fin del Universo. Ejemplos de aplicaciones: `tftp` (protocolo trivial de transferencia de archivos, un hermano pequeño del FTP), `dhcpcd` (un cliente DHCP), juegos multijugador, streaming de audio, videoconferencia, etc.

[i[Datagram sockets]>]

"¡Un momento! ¡`tftp` y `dhcpcd` se utilizan para transferir aplicaciones binarias de un host a otro! ¡Los datos no pueden perderse si esperas que la aplicación funcione cuando llegue! ¿Qué clase de magia oscura es esta?"

Bueno, amigo humano, `tftp` y programas similares tienen su propio protocolo sobre UDP. Por ejemplo, el protocolo tftp dice que por cada paquete que se envía, el destinatario tiene que enviar de vuelta un paquete que diga, "¡Lo tengo!"" (un paquete `ACK`). Si el remitente del paquete original no recibe respuesta en, digamos, cinco segundos, retransmitirá el paquete hasta que finalmente obtenga un ACK. Este procedimiento de acuse de recibo es muy importante cuando se implementan aplicaciones `SOCK_DGRAM` fiables.

Para aplicaciones no fiables como juegos, audio o vídeo, simplemente ignora los paquetes perdidos, o quizás intenta compensarlos inteligentemente. (Los jugadores de Quake conocerán la manifestación de este efecto por el término técnico: _accursed lag (retraso maldito)_.  La palabra "maldito", en este caso, representa cualquier expresión extremadamente profana).

¿Por qué utilizar un protocolo subyacente poco fiable? Por dos razones: velocidad y rapidez. Es mucho más rápido disparar y olvidar, que hacer un seguimiento de lo que ha llegado sin problemas y asegurarse de que está en orden y todo eso. Si estás enviando mensajes de chat, TCP es genial; si estás enviando 40 actualizaciones de posición por segundo de los jugadores del mundo, quizá no importe tanto si una o dos se caen, y UDP es una buena opción.


## Tonterías de bajo nivel y teoría de redes {#lowlevel}

Ya que acabo de mencionar la estratificación de protocolos, es hora de hablar de cómo funcionan realmente las redes, y de mostrar algunos ejemplos de cómo [i[`SOCK_DGRAM` macro]]  se construyen los paquetes `SOCK_DGRAM`.  En la práctica, probablemente puedas saltarte esta sección. Sin embargo, es una buena base.

![Data Encapsulation.](dataencap.pdf "[Encapsulated Protocols Diagram]")

Hola chicos, es hora de aprender sobre [i[Data encapsulation]] _¡Capsulación de datos_! Esto es muy muy importante. Es tan importante que puede que lo aprendas si tomas el curso de redes aquí en Chico State `;-)`.  Básicamente, dice esto: nace un paquete, el paquete es envuelto (encapsulado) en una cabecera [i[Data enacapsulation-->header]] (y raramente un pie [i[Data encapsulation-->footer]]) por el primer protocolo (digamos, el protocolo [i[TFTP]] TFTP protocol), luego todo (cabecera TFTP incluida) es encapsulado de nuevo por el siguiente protocolo (digamos, [i[UDP]] UDP), por el siguiente [i[IP]] (IP), y por el protocolo final en la capa (física) de hardware (digamos, [i[Ethernet]] Ethernet).

Cuando otro ordenador recibe el paquete, el hardware despoja la cabecera Ethernet, el núcleo, despoja las cabeceras IP y UDP, el programa TFTP despoja la cabecera TFTP, y finalmente tiene los datos.

Ahora por fin puedo hablar del infame [i[Layered network model]][i[ISO/OSI]]_Modelo de red por capas_ (también conocido como «ISO/OSI»). Este Modelo de Red describe un sistema de funcionalidad de red que tiene muchas ventajas sobre otros modelos. Por ejemplo, puedes escribir programas de sockets que sean exactamente iguales sin preocuparte de cómo se transmiten físicamente los datos (serie, Ethernet delgada, AUI, lo que sea) porque los programas de niveles inferiores se ocupan de ello por ti. El hardware de red real y la topología son transparentes para el programador de sockets.

Sin más preámbulos, presentaré las capas del modelo completo.  Recuerda esto para los exámenes de la clase de redes:

* Aplicación
* Presentación
* Sesión
* Transporte
* Red
* Enlace de datos
* Físico

La capa física es el hardware (serie, Ethernet, etc.). La capa de aplicación está tan lejos de la capa física como puedas imaginar: es el lugar donde los usuarios interactúan con la red.

Ahora bien, este modelo es tan general que probablemente podrías utilizarlo como guía de reparación de automóviles si realmente quisieras. Un modelo de capas más consistente con Unix podría ser:

* Capa de aplicación (_telnet, ftp, etc._)
* Capa de transporte de host a host (_TCP, UDP_)
* Capa de Internet (_IP y enrutamiento_)
* Capa de acceso a la red (_Ethernet, wi-fi, o lo que sea_)

En este momento, probablemente puedas ver cómo estas capas corresponden a la encapsulación de los datos originales.

¿Ves cuánto trabajo hay en construir un simple paquete? ¡Caramba! ¡Y tienes que escribir tú mismo las cabeceras del paquete usando `cat`! Es broma. Todo lo que tienes que hacer para los sockets de flujo es [i[`send()` function]] `send()` (eviar) los datos. Todo lo que tienes que hacer para los sockets de datagramas es encapsular el paquete en el método de tu elección y [i[`sendto()` function]] `sendto()`. El núcleo, construye la Capa de Transporte y la Capa de Internet por ti y el hardware hace la Capa de Acceso a la Red. ¡Ah, la tecnología moderna!.

Así termina nuestra breve incursión en la teoría de redes. Ah, sí, se me ha olvidado decirles todo lo que quería decirles sobre el encaminamiento: ¡nada! Así es, no voy a hablar de ello en absoluto. El router desnuda el paquete hasta la cabecera IP, consulta su tabla de enrutamiento, [i[Bla bla bla]] bla bla bla_. Echa un vistazo al [flrfc[IP RFC|791]] si realmente te importa. Si nunca te enteras, bueno, vivirás.
