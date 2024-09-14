# Llamadas al sistema

Esta es la sección donde entramos en las llamadas al sistema (y otras llamadas a librerías) que te permiten acceder a la funcionalidad de red de una máquina Unix, o de cualquier máquina que soporte la API de sockets (BSD, Windows, Linux, Mac, etc.) Cuando llamas a una de estas funciones, el kernel toma el control y hace todo el trabajo por ti automáticamente.

Donde la mayoría de la gente se queda atascada es en qué orden llamar a estas cosas. En eso, las páginas `man` (como probablemente hayas descubierto) no sirven de nada. Bien, para ayudar con esa terrible situación, he intentado presentar las llamadas al sistema en las siguientes secciones en _exactamente_ (aproximadamente) el mismo orden en que necesitarás llamarlas en tus programas.

Eso, junto con unas pocas piezas de código de ejemplo aquí y allá, un poco de leche y galletas (que me temo, tendrás que suministrar tú mismo), y algunas agallas y coraje, ¡y estarás transmitiendo datos por Internet como el Hijo de Jon Postel!

_(Ten en cuenta que, por razones de brevedad, muchos de los fragmentos de código que aparecen a continuación no incluyen la necesaria comprobación de errores. Y muy comúnmente asumen que el resultado de las llamadas a `getaddrinfo()` tienen éxito y devuelven una entrada válida en la lista enlazada. Ambas situaciones se abordan adecuadamente en los programas independientes, así que utilícelos como modelo._


## `getaddrinfo()`-- ¡Prepárate para lanzar!

[i[`getaddrinfo()` function]] Se trata de una función con muchas opciones, pero su uso es bastante sencillo. Ayuda a configurar las `struct`s que necesitarás más adelante.

Un poco de historia: antes se usaba una función llamada `gethostbyname()` para hacer búsquedas DNS. Luego cargabas esa información a mano en una `struct sockaddr_in`, y la usabas en tus llamadas.

Afortunadamente, esto ya no es necesario. (Tampoco es deseable, si quieres escribir código que funcione tanto para IPv4 como para IPv6).  En estos tiempos modernos, ahora tienes la función `getaddrinfo()` que hace todo tipo de cosas buenas por ti, incluyendo búsquedas de DNS y nombres de servicio, ¡y además rellena las `struct`s que necesitas!

Echémosle un vistazo.

```{.c}
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

int getaddrinfo(const char *node,     // e.g. "www.example.com" o IP
                const char *service,  // e.g. "http" o número de puerto
                const struct addrinfo *hints,
                struct addrinfo **res);
```

Si le das a esta función tres parámetros de entrada, te dará un puntero a una lista enlazada, `res`, de resultados.

El parámetro `node` es el nombre del host al que conectarse, o una dirección IP.

A continuación está el parámetro `service`, que puede ser un número de puerto, como «80», o el nombre de un servicio concreto (que se encuentra en [fl[La lista de puertos de IANA|https://www.iana.org/assignments/port-numbers]] o en el fichero `/etc/services` de su máquina Unix) como «http» o «ftp» o «telnet» o «smtp» o lo que sea.

Finalmente, el parámetro `hints` apunta a una `struct addrinfo` que ya has rellenado con información relevante.

Aquí tienes un ejemplo de llamada si eres un servidor que quiere escuchar en la dirección IP de tu host, puerto 3490. Ten en cuenta que esto en realidad no hace ninguna escucha o configuración de red; simplemente configura estructuras que usaremos más tarde:

```{.c .numberLines}
int status;
struct addrinfo hints;
struct addrinfo *servinfo;  // apuntará a los resultados

memset(&hints, 0, sizeof hints); // asegúrese de que la estructura está vacía
hints.ai_family = AF_UNSPEC;     // no importa IPv4 o IPv6
hints.ai_socktype = SOCK_STREAM; // Sockets de flujo TCP
hints.ai_flags = AI_PASSIVE;     // rellena mi IP por mí

if ((status = getaddrinfo(NULL, "3490", &hints, &servinfo)) != 0) {
    fprintf(stderr, "getaddrinfo error: %s\n", gai_strerror(status));
    exit(1);
}

// servinfo ahora apunta a una lista enlazada de 1 o más struct addrinfo

// ... hazlo todo hasta que ya no necesites servinfo ....

freeaddrinfo(servinfo); // liberar la lista enlazada
```

Fíjate en que he puesto `ai_family` a `AF_UNSPEC`, diciendo así que no me importa si usamos IPv4 o IPv6. Puedes ponerlo a `AF_INET` o `AF_INET6` si quieres uno u otro específicamente.

Además, verás la bandera `AI_PASSIVE` ahí; esto le dice a `getaddrinfo()` que asigne la dirección de mi host local a las estructuras del socket. Esto es bueno porque así no tienes que codificarlo (O puedes poner una dirección específica como primer parámetro de `getaddrinfo()` donde actualmente tengo `NULL`, ahí arriba).

Entonces hacemos la llamada. Si hay un error (`getaddrinfo()` devuelve distinto de cero), podemos imprimirlo usando la función `gai_strerror()`. Si todo funciona correctamente, `servinfo` apuntará a una lista enlazada de `struct addrinfo`s, ¡cada una de las cuales contiene una `struct sockaddr` de algún tipo que podremos usar más tarde! ¡Genial!

Finalmente, cuando hayamos terminado con la lista enlazada que `getaddrinfo()` tan amablemente nos ha asignado, podemos (y debemos) liberarla con una llamada a `freeaddrinfo()`.

Aquí hay un ejemplo de llamada si eres un cliente que quiere conectarse a un servidor en particular, digamos "www.example.net" puerto 3490. De nuevo, esto no conecta realmente, pero establece las estructuras que usaremos más tarde:

```{.c .numberLines}
int status;
struct addrinfo hints;
struct addrinfo *servinfo;  // apuntará a los resultados

memset(&hints, 0, sizeof hints); // asegúrese de que la estructura está vacía
hints.ai_family = AF_UNSPEC;     // no importa IPv4 o IPv6
hints.ai_socktype = SOCK_STREAM; // Sockets de flujo TCP

// prepárese para conectarse
status = getaddrinfo("www.example.net", "3490", &hints, &servinfo);

// servinfo ahora apunta a una lista enlazada de 1 o más struct addrinfos

// etc.
```

Sigo diciendo que `servinfo` es una lista enlazada con todo tipo de información de direcciones. Escribamos un rápido programa de demostración para mostrar esta información. [flx[Este pequeño programa|showip.c]] imprimirá las direcciones IP para cualquier host que especifiques en la línea de comandos:

```{.c .numberLines}
/*
** showip.c -- muestra las direcciones IP de una máquina dada
** en la línea de comandos
*/

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <netinet/in.h>

int main(int argc, char *argv[])
{
    struct addrinfo hints, *res, *p;
    int status;
    char ipstr[INET6_ADDRSTRLEN];

    if (argc != 2) {
        fprintf(stderr,"usage: showip hostname\n");
        return 1;
    }

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC; // AF_INET o AF_INET6 para forzar la versión
    hints.ai_socktype = SOCK_STREAM;

    if ((status = getaddrinfo(argv[1], NULL, &hints, &res)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(status));
        return 2;
    }

    printf("IP addresses for %s:\n\n", argv[1]);

    for(p = res;p != NULL; p = p->ai_next) {
        void *addr;
        char *ipver;

        // obtener el puntero a la propia dirección,
        // campos diferentes en IPv4 e IPv6:
        if (p->ai_family == AF_INET) { // IPv4
            struct sockaddr_in *ipv4 = (struct sockaddr_in *)p->ai_addr;
            addr = &(ipv4->sin_addr);
            ipver = "IPv4";
        } else { // IPv6
            struct sockaddr_in6 *ipv6 = (struct sockaddr_in6 *)p->ai_addr;
            addr = &(ipv6->sin6_addr);
            ipver = "IPv6";
        }

        // convierte la IP en una cadena e imprímela:
        inet_ntop(p->ai_family, addr, ipstr, sizeof ipstr);
        printf("  %s: %s\n", ipver, ipstr);
    }

    freeaddrinfo(res); // liberar la lista enlazada

    return 0;
}
```

Como ves, el código llama a `getaddrinfo()` sobre lo que sea que pases en la línea de comandos, que rellena la lista enlazada apuntada por `res`, y entonces podemos iterar sobre la lista e imprimir cosas o hacer lo que sea.

(Hay un poco de fealdad ahí donde tenemos que indagar en los diferentes tipos de `struct sockaddr`s dependiendo de la versión IP. Lo siento. No estoy seguro de una mejor manera de evitarlo).

¡Ejecución de muestra! A todo el mundo le encantan las capturas de pantalla:

```
$ showip www.example.net
IP addresses for www.example.net:

  IPv4: 192.0.2.88

$ showip ipv6.example.com
IP addresses for ipv6.example.com:

  IPv4: 192.0.2.101
  IPv6: 2001:db8:8c00:22::171
```

Ahora que tenemos esto bajo control, usaremos los resultados que obtengamos de `getaddrinfo()` para pasarlos a otras funciones de socket y, por fin, ¡conseguiremos establecer nuestra conexión de red! ¡Sigue leyendo!


## `socket()`--¡Consigue el Descriptor de Archivo! {#socket}

Supongo que no puedo posponerlo más... tengo que hablar de la [i[`socket()` function]] llamada al sistema `socket()` . Aquí está el desglose:

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int socket(int domain, int type, int protocol); 
```

Pero, ¿qué son estos argumentos? Permiten determinar qué tipo de socket se desea (IPv4 o IPv6, stream o datagrama, y TCP o UDP).

Antes la gente codificaba estos valores, y todavía se puede hacer. (`domain` es `PF_INET` o `PF_INET6`, `type` es `SOCK_STREAM` o `SOCK_DGRAM`, y `protocol` puede establecerse a `0` para elegir el protocolo apropiado para el `type` dado. O puede llamar a `getprotobyname()` para buscar el protocolo que desee, «tcp» o «udp»).

(Este `PF_INET` es un pariente cercano de la [i[`AF_INET` macro]] `AF_INET` que puedes usar al inicializar el campo `sin_family` en tu `struct sockaddr_in`. De hecho, están tan relacionadas que tienen el mismo valor, y muchos programadores llaman a `socket()` y pasan `AF_INET` como primer argumento en lugar de `PF_INET`. Ahora, coge leche y galletas, porque es hora de un cuento. Érase una vez, hace mucho tiempo, se pensó que tal vez una familia de direcciones (lo que significa «AF» en `AF_INET`) podría soportar varios protocolos que se referían a su familia de protocolos (lo que significa «PF» en `PF_INET`). Eso no ocurrió. Y todos vivieron felices para siempre, The End. Así que lo más correcto es usar `AF_INET` en tu `struct sockaddr_in` y `PF_INET` en tu llamada a `socket()`).

En fin, basta ya. Lo que realmente quieres hacer es usar los valores de los resultados de la llamada a `getaddrinfo()`, e introducirlos en `socket()` directamente así:

```{.c .numberLines}
int s;
struct addrinfo hints, *res;

// hacer la búsqueda
// [fingir que ya hemos rellenado la estructura «hints»]
getaddrinfo("www.example.com", "http", &hints, &res);

// de nuevo, deberías hacer una comprobación de errores en getaddrinfo(), y
// recorrer la lista enlazada «res» buscando entradas válidas en lugar
// de simplemente asumir que la primera es buena (como hacen muchos
// de estos ejemplos).
// Ver la sección cliente/servidor para ejemplos reales.

s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
```

`socket()` simplemente le devuelve un _descriptor de socket_ que puede usar en posteriores llamadas al sistema, o `-1` en caso de error. La variable global `errno` se establece al valor del error (vea la página de manual [`errno`](#errnoman) para más detalles, y una nota rápida sobre el uso de `errno` en programas multihilo).

Bien, bien, bien, pero ¿para qué sirve este socket? La respuesta es que realmente no sirve para nada por sí mismo, y necesitas seguir leyendo y hacer más llamadas al sistema para que tenga algún sentido.


## `bind()`---¿En qué puerto estoy? {#bind}

[i[`bind()` function]] Una vez que tengas un socket, puede que tengas que asociar ese socket con un puerto [i[Port]] en tu máquina local. (Esto se hace comúnmente si vas a [i[`listen()` function]] `listen()` para conexiones entrantes en un puerto específico---los juegos multijugador en red hacen esto cuando te dicen "conéctate a 192.168.5.10 puerto 3490"). El número de puerto es utilizado por el núcleo para hacer coincidir un paquete entrante con el descriptor de socket de un determinado proceso. Si sólo vas a hacer una función [i[`connect()`] function] `connect()` (porque eres el cliente, no el servidor), esto es probablemente innecesario. Léelo de todos modos, sólo por diversión.

Aquí está la sinopsis de la llamada al sistema `bind()`:

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int bind(int sockfd, struct sockaddr *my_addr, int addrlen);
```

`sockfd` es el descriptor de fichero de socket devuelto por `socket()`. `my_addr` es un puntero a una `struct sockaddr` que contiene información sobre su dirección, puerto y [i[IP address]]dirección IP. `addrlen` es la longitud en bytes de esa dirección.

Uf. Eso es un poco mucho para absorber en un trozo de código. Veamos un ejemplo que vincula el socket al host en el que se ejecuta el programa, el puerto 3490:

```{.c .numberLines}
struct addrinfo hints, *res;
int sockfd;

// primero, carga los structs de direcciones con getaddrinfo():

memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC;  // utilice IPv4 o IPv6, lo que corresponda
hints.ai_socktype = SOCK_STREAM;
hints.ai_flags = AI_PASSIVE;     // rellena mi IP por mí

getaddrinfo(NULL, "3490", &hints, &res);

// crea un socket:

sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);

// bind (vincularlo) al puerto que pasamos a getaddrinfo():

bind(sockfd, res->ai_addr, res->ai_addrlen);
```

Al usar la bandera `AI_PASSIVE`, le estoy diciendo al programa que se enlace a la IP del host en el que se está ejecutando. Si quiere enlazarse a una dirección IP local específica, elimine la opción `AI_PASSIVE` y ponga una dirección IP como primer argumento de `getaddrinfo()`.

`bind()` también devuelve `-1` en caso de error y establece `errno` al valor del error.

Mucho código antiguo empaqueta manualmente la `struct sockaddr_in` antes de llamar a `bind()`. Obviamente esto es específico de IPv4, pero no hay nada que te impida hacer lo mismo con IPv6, excepto que generalmente usar `getaddrinfo()` va a ser más fácil. De todos modos, el código antiguo se parece a esto:

```{.c .numberLines}
//¡¡¡ESTE ES EL VIEJO CAMINO !!!

int sockfd;
struct sockaddr_in my_addr;

sockfd = socket(PF_INET, SOCK_STREAM, 0);

my_addr.sin_family = AF_INET;
my_addr.sin_port = htons(MYPORT);     // short, orden de bytes de red
my_addr.sin_addr.s_addr = inet_addr("10.12.110.57");
memset(my_addr.sin_zero, '\0', sizeof my_addr.sin_zero);

bind(sockfd, (struct sockaddr *)&my_addr, sizeof my_addr);
```

En el código anterior, también podrías asignar `INADDR_ANY` al campo `s_addr` si quisieras enlazar con tu dirección IP local (como la bandera `AI_PASSIVE`, arriba).  La versión IPv6 de `INADDR_ANY` es una variable global `in6addr_any` que se asigna al campo `sin6_addr` de tu `struct sockaddr_in6`. (También existe una macro `IN6ADDR_ANY_INIT` que puedes usar en un inicializador de variables).

Otra cosa a tener en cuenta al llamar a `bind()`: no te pases con los números de puerto. [i[Port]] Todos los puertos por debajo de 1024 están RESERVADOS (a menos que seas el superusuario). Puedes tener cualquier número de puerto por encima de ese, hasta 65535 (siempre que no estén siendo usados por otro programa).

A veces, puede que te des cuenta, intentas volver a ejecutar un servidor y `bind()` falla, alegando [i[Address already in use]] Address already in use (Dirección ya en uso).
¿Qué significa esto? Bueno, un pedacito de un socket que estaba conectado todavía está dando vueltas en el kernel, y está acaparando el puerto. Puedes esperar a que se borre (un minuto más o menos), o añadir código a tu programa permitiéndole reutilizar el puerto, como esto:

[i[`setsockopt()` function]]
 [i[`SO_REUSEADDR` macro]]

```{.c .numberLines}
int yes=1;
//char yes='1'; // La gente de Solaris usa esto

// desaparece el molesto mensaje de error "Address already in use"
if (setsockopt(listener,SOL_SOCKET,SO_REUSEADDR,&yes,sizeof yes) == -1) {
    perror("setsockopt");
    exit(1);
} 
```

[i[`bind()` function]] Una pequeña nota final sobre `bind()`: hay veces en las que no es absolutamente necesario llamarla. Si estás [i[`connect()` function]] `connect()` a una máquina remota y no te importa cuál es tu puerto local (como es el caso de `telnet` donde sólo te importa el puerto remoto), puedes simplemente llamar a `connect()`, que comprobará si el socket está desatado y hace `bind()` a un puerto local no utilizado si es necesario.


## `connect()`--¡Hey, tú! {#connect}

[i[`connect()` function]] Imaginemos por unos minutos que eres una aplicación telnet. Tu usuario te ordena (como en la película [i[TRON]] _TRON_) que obtengas un descriptor de fichero socket. Tu cumples y llamas a `socket()`. A continuación, el usuario te dice que te conectes a `10.12.110.57` en el puerto `23` (el puerto telnet estándar). ¡Vaya! ¿Qué haces ahora?

Por suerte para ti, ahora estás leyendo la sección sobre `connect()`---cómo conectarse a un host remoto. Así que sigue leyendo furiosamente. ¡No hay tiempo que perder!

La llamada a `connect()` es la siguiente:

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int connect(int sockfd, struct sockaddr *serv_addr, int addrlen); 
```

`sockfd` es nuestro descriptor de fichero de socket, devuelto por la llamada a `socket()`, `serv_addr` es una `struct sockaddr` que contiene el puerto de destino y la dirección IP, y `addrlen` es la longitud en bytes de la estructura de la dirección del servidor.

Toda esta información se puede deducir de los resultados de la llamada `getaddrinfo()`, que es lo mejor.

¿Esto empieza a tener más sentido? No te oigo desde aquí, así que espero que sí. Veamos un ejemplo en el que hacemos una conexión de socket a `www.example.com`, puerto `3490`:

```{.c .numberLines}
struct addrinfo hints, *res;
int sockfd;

// primero, carga los structs de direcciones con getaddrinfo():

memset(&hints, 0, sizeof hints);
hints.ai_family = AF_UNSPEC;
hints.ai_socktype = SOCK_STREAM;

getaddrinfo("www.example.com", "3490", &hints, &res);

// crea un socket:

sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);

// connect!

connect(sockfd, res->ai_addr, res->ai_addrlen);
```

De nuevo, los programas de la vieja escuela rellenaban su propia `struct sockaddr_in` para pasarla a `connect()`. Puedes hacerlo si quieres. Vea la nota similar en la sección [sección `bind()`](#bind), arriba.

Asegúrese de comprobar el valor de retorno de `connect()`---devolverá `-1` en caso de error y establecerá la variable `errno`.

[i[`bind()` function-->implicit]]

Además, observa que no hemos llamado a `bind()`. Básicamente, no nos importa nuestro número de puerto local; sólo nos importa a dónde vamos (el puerto remoto). El kernel elegirá un puerto local por nosotros, y el sitio al que nos conectemos obtendrá automáticamente esta información de nosotros. No te preocupes.


## `listen()`---¿Puede alguien llamarme, por favor? {#listen}

[i[`listen()` function]]
Bien, es hora de cambiar de ritmo. ¿Qué pasa si usted no desea conectarse a un host remoto. Digamos, sólo por diversión, que quieres esperar las conexiones entrantes y manejarlas de alguna manera. El proceso tiene dos pasos: primero `listen()`, luego [i[`accept()` function]] `accept()` (ver más abajo).

La llamada a `listen()` es bastante simple, pero requiere un poco de explicación:

```{.c}
int listen(int sockfd, int backlog); 
```

`sockfd` es el descriptor de fichero de socket habitual de la llamada al sistema `socket()`. [i[`listen()` function-->backlog]] `backlog` es el número de conexiones permitidas en la cola de entrada. ¿Qué significa esto? Bueno, las conexiones entrantes van a esperar en esta cola hasta que las `acept()` (ver más abajo) y este es el límite de cuántas pueden esperar en la cola. La mayoría de los sistemas limitan silenciosamente este número a unas 20; probablemente puedas dejarlo en `5` o `10`.

De nuevo, como de costumbre, `listen()` devuelve `-1` y establece `errno` en caso de error.

Bien, como puedes imaginar, necesitamos llamar a `bind()` antes de llamar a `listen()` para que el servidor se ejecute en un puerto específico. (¡Tienes que ser capaz de decirle a tus amigos a qué puerto conectarse!) Así que si vas a estar escuchando conexiones entrantes, la secuencia de llamadas al sistema que harás es:

```{.c .numberLines}
getaddrinfo();
socket();
bind();
listen();
/* accept() va aquí */ 
```
Dejaré esto en lugar del código de ejemplo, ya que se explica por sí mismo. (El código de la sección `accept()`, más abajo, es más completo). La parte realmente complicada de todo esto es la llamada a `accept()`.


## `accept()`---"Gracias por llamar al puerto 3490."

[i[`accept()` function]]Prepárate... ¡la llamada a `accept()` es un poco rara! Lo que va a ocurrir es lo siguiente: alguien muy muy lejano intentará `conect()` a tu máquina en un puerto en el que estás `listen()`. Su conexión estará en cola esperando a ser aceptada. Llamas a `accept()` y le dices que obtenga la conexión pendiente. Te devolverá un _nuevo descriptor de fichero de socket_ para usar en esta única conexión. Así es, ¡de repente tienes _dos descriptores de socket_ por el precio de uno! El original sigue esperando nuevas conexiones, y el recién creado está finalmente listo para `send()` y `recv()`. ¡Ya está! 

La llamada es la siguiente:

```{.c}
#include <sys/types.h>
#include <sys/socket.h>

int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen); 
```

`sockfd` es el descriptor de socket `listen()`. Bastante fácil. `addr` será normalmente un puntero a una `struct sockaddr_storage` local. Aquí es donde irá la información sobre la conexión entrante (y con ella puedes determinar qué host te está llamando desde qué puerto). `addrlen` es una variable entera local que debe ser ajustada a `sizeof(struct sockaddr_storage)` antes de que su dirección sea pasada a `accept()`. `accept()` no pondrá más que esa cantidad de bytes en `addr`. Si pone menos, cambiará el valor de `addrlen` para reflejarlo.

¿Adivina qué? `accept()` devuelve `-1` y pone `errno` si se produce un error. Apuesto a que no te lo imaginabas.

Como antes, esto es mucho para absorber en un trozo, así que aquí tienes un fragmento de código de ejemplo para que lo veas:

```{.c .numberLines}
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

#define MYPORT "3490"  // el puerto al que se conectarán los usuarios
#define BACKLOG 10     // cuántas conexiones pendientes tendrá la cola

int main(void)
{
    struct sockaddr_storage their_addr;
    socklen_t addr_size;
    struct addrinfo hints, *res;
    int sockfd, new_fd;

    // ¡¡¡no olvides tu comprobación de errores para estas llamadas!!!

    // primero, carga los structs de direcciones con getaddrinfo():

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;  // utilice IPv4 o IPv6, lo que corresponda
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;     // rellena mi IP por mí

    getaddrinfo(NULL, MYPORT, &hints, &res);

    // crear un socket, enlazarlo y escuchar en él:

    sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    bind(sockfd, res->ai_addr, res->ai_addrlen);
    listen(sockfd, BACKLOG);

    // ahora acepta una conexión entrante:

    addr_size = sizeof their_addr;
    new_fd = accept(sockfd, (struct sockaddr *)&their_addr, &addr_size);

    // ¡listo para comunicar en el descriptor de socket new_fd!
    .
    .
    .
```

De nuevo, ten en cuenta que usaremos el descriptor de socket `new_fd` para todas las llamadas `send()` y `recv()`. Si sólo estás recibiendo una única conexión, puedes `close()` el `sockfd` de escucha para evitar más conexiones entrantes en el mismo puerto, si así lo deseas.

## `send()` y `recv()`---¡Háblame, nena! {#sendrecv}

Estas dos funciones sirven para comunicarse a través de sockets de flujo o sockets de datagramas conectados. Si desea utilizar sockets de datagramas normales no conectados, tendrá que ver la sección sobre [`sendto()` and `recvfrom()`](#sendtorecv), más abajo.

[i[`send()` function]] La llamada `send()`:

```{.c}
int send(int sockfd, const void *msg, int len, int flags); 
```

`sockfd` es el descriptor de socket al que quieres enviar datos (ya sea el devuelto por `socket()` o el que obtuviste con `accept()`). `msg` es un puntero a los datos que quieres enviar, y `len` es la longitud de esos datos en bytes.  Sólo tienes que poner `flags` a `0`. (Vea la página man `send()` para más información sobre flags).

Un ejemplo de código podría ser:

```{.c .numberLines}
char *msg = "Beej was here!";
int len, bytes_sent;
.
.
.
len = strlen(msg);
bytes_sent = send(sockfd, msg, len, 0);
.
.
. 
```

`send()` devuelve el número de bytes realmente enviados---¡esto podría ser menor que el número que le dijiste que enviara!_ Verás, a veces le dices que envíe un montón de datos y simplemente no puede manejarlo. Enviará tantos datos como pueda, y confiará en que le envíes el resto más tarde. Recuerda, si el valor devuelto por `send()` no coincide con el valor en `len`, depende de ti enviar el resto de la cadena. La buena noticia es esta: si el paquete es pequeño (menos de 1K o así) _probablemente_ se las arreglará para enviarlo todo de una vez.  De nuevo, `-1` se devuelve en caso de error, y `errno` se establece al número de error.


[i[`recv()` function]] La llamada `recv()` es similar en muchos aspectos:

```{.c}
int recv(int sockfd, void *buf, int len, int flags);
```

`sockfd` es el descriptor de socket del que leer, `buf` es el buffer en el que leer la información, `len` es la longitud máxima del buffer, y `flags` puede ser de nuevo `0`. (Ver la página man de `recv()` para información sobre banderas).

`Recv()` devuelve el número de bytes realmente leídos en el buffer, o `-1` en caso de error (con `errno` configurado).

Espere, `recv()` puede devolver `0`. Esto sólo puede significar una cosa: ¡el lado remoto ha cerrado la conexión! Un valor de retorno `0` es la forma que tiene `recv()` de hacerte saber que esto ha ocurrido.

Ya está, ha sido fácil, ¿verdad? ¡Ahora puedes pasar datos de un lado a otro en sockets de flujo! ¡Vaya! ¡Eres un programador de redes Unix!

## `sendto()` y `recvfrom()`---Háblame, al estilo DGRAM {#sendtorecv}

[i[`SOCK_DGRAM` macro]] "Todo esto está muy bien", te oigo decir, "¿pero dónde me deja esto con los sockets de datagramas desconectados?”. No hay problema, amigo. Tenemos justo lo que necesitas.

Como los sockets de datagramas no están conectados a un host remoto, ¿adivina qué información necesitamos dar antes de enviar un paquete? Exacto. La dirección de destino. Aquí está la primicia:

```{.c}
int sendto(int sockfd, const void *msg, int len, unsigned int flags,
           const struct sockaddr *to, socklen_t tolen); 
```

Como puede ver, esta llamada es básicamente la misma que la llamada a `send()` con la adición de otras dos piezas de información. `to` es un puntero a una `struct sockaddr` (que probablemente será otra `struct sockaddr_in` o `struct sockaddr_in6` o `struct sockaddr_storage` que has lanzado en el último momento) que contiene el destino.[i[IP address]]Dirección IP y [i[Port]] puerto. `tolen`, un `int` en el fondo, puede ser simplemente puesto a `sizeof *to` o `sizeof(struct sockaddr_stora)`.

Para obtener la estructura de direcciones de destino, probablemente la obtendrá de `getaddrinfo()`, o de `recvfrom()`, más abajo, o la rellenará a mano.

Al igual que con `send()`, `sendto()` devuelve el número de bytes realmente enviados (que, de nuevo, puede ser menor que el número de bytes que le dijo que enviara), o `-1` en caso de error.

Igualmente similares son `recv()` y [i[`recvfrom()` function]] `recvfrom()`. La sinopsis de `recvfrom()` es:

```{.c}
int recvfrom(int sockfd, void *buf, int len, unsigned int flags,
             struct sockaddr *from, int *fromlen); 
```

De nuevo, esto es como `recv()` con la adición de un par de campos.`from` es un puntero a un local [i[`struct sockaddr` type]] `struct sockaddr_storage` que se rellenará con la dirección IP y el puerto de la máquina de origen.`fromlen` es un puntero a un `int` local que debe ser inicializado a `sizeof *from` o `sizeof(struct sockaddr_storage)`. Cuando la función retorna, `fromlen` contendrá la longitud de la dirección almacenada en `from`.

La función `recvfrom()` devuelve el número de bytes recibidos, o `-1` en caso de error (con el valor `errno` correspondiente).

Así que, aquí va una pregunta: ¿por qué usamos `struct sockaddr_storage` como tipo de socket? ¿Por qué no `struct sockaddr_in`? Porque, verás, no queremos atarnos a IPv4 o IPv6. Así que usamos el genérico `struct sockaddr_storage` que sabemos que será lo suficientemente grande para cualquiera de los dos.

(Así que... aquí hay otra pregunta: ¿por qué la propia `struct sockaddr` no es lo suficientemente grande para cualquier dirección? Incluso convertimos la `struct sockaddr_storage` de propósito general en la `struct sockaddr` de propósito general. Parece superfluo y redundante. La respuesta es, simplemente no es lo suficientemente grande, y supongo que cambiarlo en este punto sería problemático. Así que hicieron uno nuevo).

Recuerde, si usted [i[`connect()` function-->on datagram sockets]] `connect()` un socket de datagramas, puedes simplemente usar `send()` y `recv()` para todas tus transacciones. El socket en sí sigue siendo un socket de datagrama y los paquetes siguen usando UDP, pero la interfaz de socket añadirá automáticamente la información de destino y origen por ti.


## `close()` y `shutdown()`---¡Fuera de mi vista!

¡Uf! Llevas todo el día enviando y recibiendo datos y ya no puedes más. Estás listo para cerrar la conexión en tu descriptor de socket. Esto es fácil. Puedes usar el archivo Unix normal descriptor [i[`close()` function]] `close()`:

```{.c}
close(sockfd); 
```

Esto evitará más lecturas y escrituras en el socket. Cualquiera que intente leer o escribir en el socket en el extremo remoto recibirá un error.

En caso de que quieras un poco más de control sobre cómo se cierra el socket, puedes usar la función [i[`shutdown()` function]] `shutdown()`. Te permite cortar la comunicación en una determinada dirección, o en ambas (igual que hace `close()`). Sinopsis:

```{.c}
int shutdown(int sockfd, int how); 
```

`sockfd` es el descriptor de fichero de socket que quieres apagar, y `how` es uno de los siguientes:

| `how` | Efecto                                                     |
|:-----:|------------------------------------------------------------|
|  `0`  |  No se admiten más recepciones                             |
|  `1`  |  No se admiten más envíos
|
|  `2`  | Otros envíos y recepciones no están permitidos (como `close()`) |

`shutdown()` devuelve `0` en caso de éxito, y `-1` en caso de error (con el valor `errno` correspondiente).

Si se digna a usar `shutdown()` en sockets de datagramas desconectados, simplemente hará que el socket no esté disponible para futuras llamadas a `send()` y `recv()` (recuerde que puede usarlas si `connect()` su socket de datagramas).

Es importante notar que `shutdown()` no cierra realmente el descriptor de fichero---solo cambia su usabilidad. Para liberar un descriptor de socket, necesitas usar `close()`.

No hay nada que hacer.

(Excepto para recordar que si está utilizando  [i[Windows]] Windows y [i[Winsock]] Winsock deberías llamar a [i[`closesocket()` function]] `closesocket()` en lugar de `close()`.)


## `getpeername()`---¿Quién es usted?

[i[`getpeername()` function]] Esta función es tan fácil.

Es tan fácil que casi no le doy su propia sección. Pero aquí está.

La función `getpeername()` le dirá quién está en el otro extremo de un socket stream conectado. La sinopsis:

```{.c}
#include <sys/socket.h>

int getpeername(int sockfd, struct sockaddr *addr, int *addrlen); 
```

`sockfd` es el descriptor del socket conectado, `addr` es un puntero a `struct sockaddr` (o `struct sockaddr_in`) que contendrá la información sobre el otro lado de la conexión, y `addrlen` es un puntero a `int`, que debería inicializarse a `sizeof *addr` o `sizeof(struct sockaddr)`.

La función devuelve `-1` en caso de error y establece `errno` en consecuencia.

Una vez que tengas su dirección, puedes usar [i[`inet_ntop()` function]] `inet_ntop()`, [i[`getnameinfo()` function]] `getnameinfo()`, o [i[`gethostbyaddr()` function]] para imprimir u obtener más información. No, no puedes obtener su nombre de usuario. (Vale, de acuerdo. Si el otro ordenador está ejecutando un demonio ident, esto es posible. Esto, sin embargo, está fuera del alcance de este documento. Consulta [flrfc[RFC 1413|1413]] para más información).


## `gethostname()`---¿Quién soy yo?

[i[`gethostname()` function]] Aún más fácil que `getpeername()` es la función `gethostname()`. Devuelve el nombre del ordenador en el que se ejecuta el programa. El nombre puede ser utilizado por [i[`getaddrinfo()` function]] `getaddrinfo()`, arriba, para determinar la [i[IP address]] dirección IP de su máquina local.

¿Qué podría ser más divertido? Podría pensar en algunas cosas, pero no pertenecen a la programación de sockets. De todos modos, aquí está el desglose:

```{.c}
#include <unistd.h>

int gethostname(char *hostname, size_t size); 
```

Los argumentos son sencillos: `hostname` es un puntero a una matriz de caracteres que contendrá el nombre del host cuando la función regrese, y `size` es la longitud en bytes de la matriz `hostname`.

La función devuelve `0` en caso de éxito, y `-1` en caso de error, estableciendo `errno` como de costumbre.