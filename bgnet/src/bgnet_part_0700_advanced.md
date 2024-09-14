# Técnicas ligeramente avanzadas

Estas no son _realmente_ avanzadas, pero salen de los niveles más básicos que ya hemos cubierto. De hecho, si has llegado hasta aquí, ¡deberías considerarte bastante experto en los fundamentos de la programación de redes Unix!  ¡Enhorabuena!

Así que, aquí, vamos al valiente nuevo mundo de algunas de las cosas más esotéricas que podrías querer aprender sobre sockets. ¡Adelante!

## Bloqueo {#blocking}

[i[Blocking]<]

Bloqueo. Ya ha oído hablar de él, pero ¿qué es? En pocas palabras, "block" «bloquear» es la jerga técnica para "sleep" «dormir». Probablemente has notado que cuando ejecutas `listener`, arriba, se queda ahí sentado hasta que llega un paquete. Lo que ocurrió es que llamó a `recvfrom()`, no había datos, y por eso se dice que `recvfrom()` se «bloquea» (es decir, duerme ahí) hasta que llegan algunos datos.

Muchas funciones se bloquean. La función `accept()` se bloquea. Todas las funciones `recv()` se bloquean.  La razón por la que pueden hacer esto es porque se les permite. Cuando se crea por primera vez el descriptor del socket con `socket()`, el kernel lo configura como bloqueante. [i[Non-blocking sockets]] Si no quieres que un socket sea bloqueante, tienes que hacer una llamada a la función `fcntl()` :

```{.c .numberLines}
#include <unistd.h>
#include <fcntl.h>
.
.
.
sockfd = socket(PF_INET, SOCK_STREAM, 0);
fcntl(sockfd, F_SETFL, O_NONBLOCK);
.
.
. 
```

Al configurar un socket como no bloqueante, puede «sondear» el socket para obtener información. Si intentas leer de un socket no bloqueante y no hay datos allí, no está permitido bloquearlo---devolverá `-1` y `errno` será puesto a [i[`EAGAIN` macro]] `EAGAIN` o [i[`EWOULDBLOCK` macro]] `EWOULDBLOCK`.

(Espera---puede devolver [i[`EAGAIN` macro]] `EAGAIN` _o_ [i[`EWOULDBLOCK` macro]] `EWOULDBLOCK`) `EWOULDBLOCK`? ¿Cuál comprueba?  En realidad, la especificación no especifica cuál devolverá su sistema, así que, por motivos de portabilidad, compruebe ambas).

En general, sin embargo, este tipo de sondeo es una mala idea. Si pones tu programa en un busy-wait buscando datos en el socket, chuparás tiempo de CPU como si estuviera pasando de moda. Una solución más elegante para comprobar si hay datos esperando a ser leídos viene en la siguiente sección de [i[`poll()` function]] `poll()`.

[i[Blocking]>]

## `poll()`---Multiplexación síncrona de E/S {#poll}

[i[poll()]<]

Lo que realmente quieres es poder monitorizar de alguna manera un _montón_ de sockets a la vez y luego manejar los que tienen datos listos. De esta manera no tienes que estar continuamente sondeando todos esos sockets para ver cuáles están listos para leer.

> Una advertencia: `poll()` es terriblemente lento cuando se trata de grandes
> número de conexiones. En esas circunstancias, obtendrás un mejor
> rendimiento de una librería de eventos como
> [fl[libevent|https://libevent.org/]] que intenta usar el método más rápido
> disponible en su sistema.

¿Cómo evitar las encuestas? Irónicamente, puedes evitar el sondeo utilizando la llamada al sistema `poll()`. En pocas palabras, vamos a pedirle al sistema operativo que haga todo el trabajo sucio por nosotros, y sólo nos haga saber cuándo hay datos listos para leer en qué sockets. Mientras tanto, nuestro proceso puede irse a dormir, ahorrando recursos del sistema.

El plan general es mantener un array de `struct pollfd`s con información sobre qué descriptores de socket queremos monitorizar, y qué tipo de eventos queremos monitorizar. El sistema operativo bloqueará la llamada a `poll()` hasta que ocurra uno de esos eventos (por ejemplo, «socket ready for reading») o hasta que ocurra un tiempo de espera especificado por el usuario.

De forma útil, un socket `listen()` devolverá «ready to read» cuando una nueva conexión entrante esté lista para ser `accept()`.

Basta de bromas. ¿Cómo usamos esto?

``` {.c}
#include <poll.h>

int poll(struct pollfd fds[], nfds_t nfds, int timeout);
```

`fds` es nuestro array de información (qué sockets monitorizar y para qué), `nfds` es el número de elementos en el array, y `timeout` es el tiempo de espera en milisegundos. Devuelve el número de elementos del array en los que se ha producido un evento.

Echemos un vistazo a esa `struct`:

[i[`struct pollfd` type]]

``` {.c}
struct pollfd {
    int fd;         // el descriptor del socket
    short events;   // mapa de bits de los eventos que nos interesan
    short revents;  // cuando poll() retorna, bitmap de eventos ocurridos
};
```

Así que vamos a tener una matriz de estos, y vamos a establecer el campo `fd` para cada elemento a un descriptor de socket que estamos interesados en monitorear. Y luego pondremos el campo `events` para indicar el tipo de eventos que nos interesan.

El campo `events` es el bitwise-OR de lo siguiente:

| Macro     | 
Descripción                                                  |
|-----------|--------------------------------------------------------------|
| `POLLIN`  | Alertarme cuando los datos estén listos para `recv()` en este socket.      |
| `POLLOUT` | Avisame cuando pueda `enviar()` datos a este socket sin bloquear.|

Una vez que tengas tu array de `struct pollfd` en orden, entonces puedes pasarlo a `poll()`, pasando también el tamaño del array, así como un valor de tiempo de espera en milisegundos. (Puedes especificar un tiempo de espera negativo para esperar eternamente).

Después de que `poll()` retorne, puedes comprobar el campo `revents` para ver si `POLLIN` o `POLLOUT` está activado, indicando que el evento ha ocurrido.

(En realidad hay más cosas que puedes hacer con la llamada `poll()`. Vea la [página man de `poll()`, más abajo](#pollman), para más detalles).

Aquí está [flx[un ejemplo|poll.c]] donde esperaremos 2.5 segundos a que los datos estén listos para ser leídos desde la entrada estándar, es decir, cuando pulses `RETURN`:

``` {.c .numberLines}
#include <stdio.h>
#include <poll.h>

int main(void)
{
    struct pollfd pfds[1]; // Más si desea supervisar más

    pfds[0].fd = 0;          // Entrada estándar
    pfds[0].events = POLLIN; // Avísame cuando esté listo para leer

    // Si necesitaras controlar también otras cosas:
    //pfds[1].fd = some_socket; // Algún descriptor de socket
    //pfds[1].events = POLLIN; // Avisa cuando esté listo para leer

    printf("Hit RETURN or wait 2.5 seconds for timeout\n");

    int num_events = poll(pfds, 1, 2500); // 2,5 segundos de espera

    if (num_events == 0) {
        printf("Poll timed out!\n");
    } else {
        int pollin_happened = pfds[0].revents & POLLIN;

        if (pollin_happened) {
            printf("File descriptor %d is ready to read\n", pfds[0].fd);
        } else {
            printf("Unexpected event occurred: %d\n", pfds[0].revents);
        }
    }

    return 0;
}
```
Observe de nuevo que `poll()` devuelve el número de elementos de la matriz `pfds` para los que se han producido eventos. No te dice _qué_ elementos del array (aún tienes que escanearlo), pero te dice cuántas entradas tienen un campo `revents` distinto de cero (así que puedes dejar de escanear después de encontrar ese número).

Aquí pueden surgir un par de preguntas: ¿cómo añadir nuevos descriptores de fichero al conjunto que paso a `poll()`? Para esto, simplemente asegúrate de que tienes suficiente espacio en el array para todos los que necesites, o `realloc()` más espacio si es necesario.

¿Qué pasa con la eliminación de elementos del conjunto? Para esto, puedes copiar el último elemento del array encima del que estás borrando. Y luego pasar uno menos como recuento a `poll()`. Otra opción es establecer cualquier campo `fd` a un número negativo y `poll()` lo ignorará.

¿Cómo podemos juntar todo esto en un servidor de chat al que puedas conectarte por `telnet`?

Lo que haremos es iniciar un socket de escucha, y añadirlo al conjunto de descriptores de fichero de `poll()`. (Se mostrará listo para leer cuando haya una conexión entrante).

Entonces añadiremos nuevas conexiones a nuestro array `struct pollfd`. Y lo haremos crecer dinámicamente si nos quedamos sin espacio.

Cuando se cierre una conexión, la eliminaremos de la matriz.

Y cuando una conexión esté lista para ser leída, leeremos sus datos y los enviaremos a todas las demás conexiones para que puedan ver lo que han escrito los demás usuarios.

Así que pruebe [flx[este servidor de pool|pollserver.c]]. Ejecútalo en una ventana, y luego `telnet localhost 9034` desde otras ventanas de terminal. Deberías poder ver lo que escribes en una ventana en las otras (después de pulsar RETURN).

No sólo eso, sino que si pulsas `CTRL-]` y tecleas `quit` para salir de `telnet`, el servidor debería detectar la desconexión y eliminarte del conjunto de descriptores de fichero.


``` {.c .numberLines}
/*
** pollserver.c -- a cheezy multiperson chat server
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <poll.h>

#define PORT "9034"   // Puerto en el que estamos escuchando

// Get sockaddr, IPv4 or IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

// Devuelve un socket de escucha
int get_listener_socket(void)
{
    int listener;     // Descriptor de socket de escucha
    int yes=1;        // Para setsockopt() SO_REUSEADDR, abajo
    int rv;

    struct addrinfo hints, *ai, *p;

    // Obtener un socket y enlazarlo
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    if ((rv = getaddrinfo(NULL, PORT, &hints, &ai)) != 0) {
        fprintf(stderr, "pollserver: %s\n", gai_strerror(rv));
        exit(1);
    }
    
    for(p = ai; p != NULL; p = p->ai_next) {
        listener = socket(p->ai_family, p->ai_socktype, p->ai_protocol);
        if (listener < 0) { 
            continue;
        }
        
        // Elimina el molesto mensaje de error "address already in use"
        setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int));

        if (bind(listener, p->ai_addr, p->ai_addrlen) < 0) {
            close(listener);
            continue;
        }

        break;
    }

    freeaddrinfo(ai); // Todo hecho con esto

    // Si llegamos aquí, significa que no nos ataron
    if (p == NULL) {
        return -1;
    }

    // Escuchar
    if (listen(listener, 10) == -1) {
        return -1;
    }

    return listener;
}

// Añadir un nuevo descriptor de fichero al conjunto
void add_to_pfds(struct pollfd *pfds[], int newfd, int *fd_count, int *fd_size)
{
    // Si no tenemos espacio, añadir más espacio en la matriz pfds
    if (*fd_count == *fd_size) {
        *fd_size *= 2; // Double it

        *pfds = realloc(*pfds, sizeof(**pfds) * (*fd_size));
    }

    (*pfds)[*fd_count].fd = newfd;
    (*pfds)[*fd_count].events = POLLIN; // Check ready-to-read

    (*fd_count)++;
}

// Eliminar un índice del conjunto
void del_from_pfds(struct pollfd pfds[], int i, int *fd_count)
{
    // Copia el del final sobre este
    pfds[i] = pfds[*fd_count-1];

    (*fd_count)--;
}

// Main
int main(void)
{
    int listener;        // Descriptor de socket de escucha

    int newfd;        // Nuevo descriptor de socket accept()ed
    struct sockaddr_storage remoteaddr; // Dirección del cliente
    socklen_t addrlen;

    char buf[256];    // Buffer para datos del cliente

    char remoteIP[INET6_ADDRSTRLEN];

    // Empezar con espacio para 5 conexiones
    // (Reasignaremos cuando sea necesario)
    int fd_count = 0;
    int fd_size = 5;
    struct pollfd *pfds = malloc(sizeof *pfds * fd_size);

    // Configurar y obtener un socket de escucha
    listener = get_listener_socket();

    if (listener == -1) {
        fprintf(stderr, "error getting listening socket\n");
        exit(1);
    }

    // Añadir el listener a set
    pfds[0].fd = listener;
    pfds[0].events = POLLIN; // Informe listo para leer en la conexión entrante

    fd_count = 1; // Para el oyente

    // Main loop
    for(;;) {
        int poll_count = poll(pfds, fd_count, -1);

        if (poll_count == -1) {
            perror("poll");
            exit(1);
        }

        // Ejecutar a través de las conexiones existentes en busca de datos para leer
        for(int i = 0; i < fd_count; i++) {

            // Comprobar si alguien está listo para leer
            if (pfds[i].revents & POLLIN) { // We got one!!

                if (pfds[i].fd == listener) {
                    // Si el receptor está listo para leer, gestiona la nueva conexión

                    addrlen = sizeof remoteaddr;
                    newfd = accept(listener,
                        (struct sockaddr *)&remoteaddr,
                        &addrlen);

                    if (newfd == -1) {
                        perror("accept");
                    } else {
                        add_to_pfds(&pfds, newfd, &fd_count, &fd_size);

                        printf("pollserver: new connection from %s on "
                            "socket %d\n",
                            inet_ntop(remoteaddr.ss_family,
                                get_in_addr((struct sockaddr*)&remoteaddr),
                                remoteIP, INET6_ADDRSTRLEN),
                            newfd);
                    }
                } else {
                    // Si no es el oyente, somos un cliente normal
                    int nbytes = recv(pfds[i].fd, buf, sizeof buf, 0);

                    int sender_fd = pfds[i].fd;

                    if (nbytes <= 0) {
                        // Error o conexión cerrada por el cliente
                        if (nbytes == 0) {
                            // Connection closed
                            printf("pollserver: socket %d hung up\n", sender_fd);
                        } else {
                            perror("recv");
                        }

                        close(pfds[i].fd); // Bye!

                        del_from_pfds(pfds, i, &fd_count);

                    } else {
                        // Tenemos algunos buenos datos de un cliente

                        for(int j = 0; j < fd_count; j++) {
                            // ¡Enviar a todo el mundo!
                            int dest_fd = pfds[j].fd;

                            // Excepto el oyente y nosotros
                            if (dest_fd != listener && dest_fd != sender_fd) {
                                if (send(dest_fd, buf, nbytes, 0) == -1) {
                                    perror("send");
                                }
                            }
                        }
                    }
                } // END manejar datos del cliente
            } // END obtuvo datos listos para leer de poll()
        } // FINALIZAR el bucle a través de los descriptores de fichero
    } // END for(;;)--¡y pensabas que nunca acabaría!
    
    return 0;
}
```

En la siguiente sección, veremos una función similar más antigua llamada `select()`. Tanto `select()` como `poll()` ofrecen una funcionalidad y un rendimiento similares, y sólo difieren realmente en cómo se utilizan. Puede que `select()` sea ligeramente más portable, pero quizás sea un poco más torpe en su uso. Elige el que más te guste, siempre que esté soportado en tu sistema.

[i[poll()]>]


## `select()`---Multiplexación síncrona de E/S a la antigua usanza {#select}

[i[`select()` function]<]

Esta función es un tanto extraña, pero resulta muy útil. Tomemos la siguiente situación: eres un servidor y quieres escuchar conexiones entrantes así como seguir leyendo de las conexiones que ya tienes.

No hay problema, dices, sólo un `accept()` y un par de `recv()`s. No tan rápido, amigo. ¿Qué pasa si estás bloqueando una llamada a `accept()`? ¿Cómo vas a «recuperar» datos al mismo tiempo? «¡Usa sockets no bloqueantes!» ¡No puede ser! No quieres ser un devorador de CPU. ¿Entonces qué?

`select()` te da el poder de monitorizar varios sockets al mismo tiempo.  Te dirá cuáles están listos para leer, cuáles están listos para escribir, y qué sockets han lanzado excepciones, si realmente quieres saberlo.

> Una advertencia: `select()`, aunque muy portable, es terriblemente lento
> cuando se trata de un gran número de conexiones. En esas circunstancias,
> obtendrás mejor rendimiento de una librería de eventos como
> [fl[libevent|https://libevent.org/]] que intenta usar el
> método más rápido disponible en su sistema.

Sin más dilación, te ofrezco la sinopsis de `select()`:

```{.c}
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

int select(int numfds, fd_set *readfds, fd_set *writefds,
           fd_set *exceptfds, struct timeval *timeout); 
```

La función monitoriza «conjuntos» de descriptores de fichero; en particular `readfds`, `writefds`, y `exceptfds`. Si quiere ver si puede leer de la entrada estándar y de algún descriptor de socket, `sockfd`, sólo tiene que añadir los descriptores de fichero `0` y `sockfd` al conjunto `readfds`. El parámetro `numfds` debe establecerse con los valores del descriptor de fichero más alto más uno. En este ejemplo, debería ser `sockfd+1`, ya que es seguramente mayor que la entrada estándar (`0`).

Cuando `select()` retorna, `readfds` se modificará para reflejar cuál de los descriptores de fichero seleccionados está listo para ser leído. Puedes probarlos con la macro `FD_ISSET()`, más abajo.

Antes de avanzar mucho más, hablaré de cómo manipular estos conjuntos.  Cada conjunto es del tipo `fd_set`. Las siguientes macros operan sobre este tipo:

| Función                          | Descripción                          |
|----------------------------------|--------------------------------------|
| [i[`FD_SET()` macro]]`FD_SET(int fd, fd_set *set);`   | Añade `fd` al `set`.               |
| [i[`FD_CLR()` macro]]`FD_CLR(int fd, fd_set *set);`   | Eliminar `fd` del `set`.          |
| [i[`FD_ISSET()` macro]]`FD_ISSET(int fd, fd_set *set);` | Devuelve true si `fd` está en el `set`. |
| [i[`FD_ZERO()` macro]]`FD_ZERO(fd_set *set);`          | Borra todas las entradas del `set`.    |

[i[`struct timeval` type]<]

Por último, ¿qué es ese extraño `struct timeval`? Bueno, a veces no quieres esperar eternamente a que alguien te envíe algún dato. Puede que cada 96 segundos quieras imprimir «Still Going...» en el terminal aunque no haya pasado nada. Esta estructura de tiempo te permite especificar un periodo de tiempo de espera. Si se excede el tiempo y `select()` todavía no ha encontrado ningún descriptor de fichero listo, volverá para que puedas continuar procesando.

La `struct timeval` tiene los siguientes campos:

```{.c}
struct timeval {
    int tv_sec;     // seconds
    int tv_usec;    // microseconds
}; 
```
Sólo tienes que poner `tv_sec` al número de segundos que hay que esperar, y poner `tv_usec` al número de microsegundos que hay que esperar. Sí, son _micro_segundos, no milisegundos.  Hay 1.000 microsegundos en un milisegundo, y 1.000 milisegundos en un segundo. Por tanto, hay 1.000.000 de microsegundos en un segundo. ¿Por qué se dice «usec»?  Se supone que la «u» se parece a la letra griega μ (Mu) que utilizamos para «micro». Además, cuando la función regresa, `timeout` _podría_ actualizarse para mostrar el tiempo restante. Esto depende del tipo de Unix que estés usando.

¡Sí! ¡Tenemos un temporizador con resolución de microsegundos! Bueno, no cuentes con ello. Probablemente tendrás que esperar una parte del tiempo estándar de Unix, no importa lo pequeño que configures tu `struct timeval`.

Otras cosas de interés:  Si estableces los campos de tu `struct timeval` a `0`, `select()` expirará inmediatamente, sondeando efectivamente todos los descriptores de fichero de tus conjuntos. Si establece el parámetro `timeout` a NULL, nunca se agotará el tiempo de espera, y esperará hasta que el primer descriptor de fichero esté listo. Por último, si no te importa esperar a un determinado conjunto, puedes ponerlo a NULL en la llamada a `select()`.

[flx[El siguiente fragmento de código|select.c]] espera 2,5 segundos a que aparezca algo en la entrada estándar:

```{.c .numberLines}
/*
** select.c -- a select() demo
*/

#include <stdio.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>

#define STDIN 0  // descriptor de fichero para la entrada estándar

int main(void)
{
    struct timeval tv;
    fd_set readfds;

    tv.tv_sec = 2;
    tv.tv_usec = 500000;

    FD_ZERO(&readfds);
    FD_SET(STDIN, &readfds);

    // no te preocupes por writefds y exceptfds:
    select(STDIN+1, &readfds, NULL, NULL, &tv);

    if (FD_ISSET(STDIN, &readfds))
        printf("A key was pressed!\n");
    else
        printf("Timed out.\n");

    return 0;
} 
```

Si estás en un terminal con búfer de línea, la tecla que pulses debe ser RETURN o se agotará el tiempo de espera.

Ahora, algunos de ustedes podrían pensar que esta es una gran manera de esperar datos en un socket de datagramas--y tienen razón: _podría_ serlo. Algunas Unices pueden usar select de esta manera, y otras no. Debería ver lo que dice su página man local al respecto si quiere intentarlo.

Algunas Unices actualizan el tiempo en su `struct timeval` para reflejar la cantidad de tiempo restante antes de un tiempo de espera. Pero otras no lo hacen. No confíes en que eso ocurra si quieres ser portable. (Use [i[`gettimeofday()` function]] `gettimeofday()` si necesitas controlar el tiempo transcurrido. Es un fastidio, lo sé, pero así son las cosas).

[i[`struct timeval` type]>]

¿Qué ocurre si un socket del conjunto de lectura cierra la conexión? Bueno, en ese caso, `select()` vuelve con ese descriptor de socket establecido como «listo para leer».  Cuando hagas `recv()` desde él, `recv()` devolverá `0`. Así es como sabes que el cliente ha cerrado la conexión.

Una nota más de interés sobre `select()`: si tienes un socket que es
[i[`select()` function-->with `listen()`]]
[i[`listen()` function-->with `select()`]]
`listen()`, puedes comprobar si hay una nueva conexión poniendo el descriptor de fichero de ese socket en el set `readfds`.

Y esto, amigos míos, es una rápida visión general de la todopoderosa función `select()`.

Pero, por demanda popular, aquí hay un ejemplo en profundidad. Desafortunadamente, la diferencia entre el sencillo ejemplo anterior y este es significativa. Pero échale un vistazo, y luego lee la descripción que sigue.

[flx[Este programa|selectserver.c]] actúa como un simple servidor de chat multiusuario. Empieza a ejecutarlo en una ventana, luego `telnet` a él (`telnet hostname 9034`) desde otras múltiples ventanas. Cuando escribas algo en una sesión `telnet`, debería aparecer en todas las demás.

```{.c .numberLines}
/*
** selectserver.c -- un servidor de chat multipersona
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define PORT "9034"   // puerto en el que estamos escuchando

// obtener sockaddr, IPv4 o IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

int main(void)
{
    fd_set master; // lista maestra de descriptores de fichero
    fd_set read_fds; // lista temporal de descriptores de fichero para select()
    int fdmax; // número máximo de descriptores de fichero

    int listener; // descriptor de socket a la escucha
    int newfd; // descriptor de socket recién aceptado()ed
    struct sockaddr_storage remoteaddr; // dirección del cliente
    socklen_t addrlen;

    char buf[256];    // búfer para los datos del cliente
    int nbytes;

    char remoteIP[INET6_ADDRSTRLEN];

    int yes=1;        // para setsockopt() SO_REUSEADDR, abajo
    int i, j, rv;

    struct addrinfo hints, *ai, *p;

    FD_ZERO(&master);    // borrar los conjuntos maestro y temporal
    FD_ZERO(&read_fds);

    // obtener un socket y enlazarlo
    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE;
    if ((rv = getaddrinfo(NULL, PORT, &hints, &ai)) != 0) {
        fprintf(stderr, "selectserver: %s\n", gai_strerror(rv));
        exit(1);
    }
    
    for(p = ai; p != NULL; p = p->ai_next) {
        listener = socket(p->ai_family, p->ai_socktype, p->ai_protocol);
        if (listener < 0) { 
            continue;
        }
        
        // perder el molesto mensaje de error "address already in use"
        setsockopt(listener, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int));

        if (bind(listener, p->ai_addr, p->ai_addrlen) < 0) {
            close(listener);
            continue;
        }

        break;
    }

    // si llegamos aquí, significa que no nos ataron
    if (p == NULL) {
        fprintf(stderr, "selectserver: failed to bind\n");
        exit(2);
    }

    freeaddrinfo(ai); // todo hecho con esto

    // Escuchando
    if (listen(listener, 10) == -1) {
        perror("listen");
        exit(3);
    }

    // añadir el oyente al conjunto maestro
    FD_SET(listener, &master);

    // llevar la cuenta del mayor descriptor de fichero
    fdmax = listener; // so far, it's this one

    // bucle principal
    for(;;) {
        read_fds = master; // copy it
        if (select(fdmax+1, &read_fds, NULL, NULL, NULL) == -1) {
            perror("select");
            exit(4);
        }

        // recorre las conexiones existentes buscando datos para leer
        for(i = 0; i <= fdmax; i++) {
            if (FD_ISSET(i, &read_fds)) { // ¡¡tenemos uno!!
                if (i == listener) {
                    // gestionar nuevas conexiones
                    addrlen = sizeof remoteaddr;
                    newfd = accept(listener,
                        (struct sockaddr *)&remoteaddr,
                        &addrlen);

                    if (newfd == -1) {
                        perror("accept");
                    } else {
                        FD_SET(newfd, &master); // añadir al conjunto principal
                        if (newfd > fdmax) {    // llevar la cuenta del máximo
                            fdmax = newfd;
                        }
                        printf("selectserver: new connection from %s on "
                            "socket %d\n",
                            inet_ntop(remoteaddr.ss_family,
                                get_in_addr((struct sockaddr*)&remoteaddr),
                                remoteIP, INET6_ADDRSTRLEN),
                            newfd);
                    }
                } else {
                    // manejar los datos de un cliente
                    if ((nbytes = recv(i, buf, sizeof buf, 0)) <= 0) {
                        // error obtenido o conexión cerrada por el cliente
                        if (nbytes == 0) {
                            // conexión cerrada
                            printf("selectserver: socket %d hung up\n", i);
                        } else {
                            perror("recv");
                        }
                        close(i); // bye!
                        FD_CLR(i, &master); // eliminar del conjunto principal
                    } else {
                        // recibimos algunos datos de un cliente
                        for(j = 0; j <= fdmax; j++) {
                            // ¡enviar a todo el mundo!
                            if (FD_ISSET(j, &master)) {
                                // excepto el oyente y nosotros
                                if (j != listener && j != i) {
                                    if (send(j, buf, nbytes, 0) == -1) {
                                        perror("send");
                                    }
                                }
                            }
                        }
                    }
                } // END manejar datos del cliente
            } // END obtuvo nueva conexión entrante
        } // FINALIZAR bucle a través de descriptores de fichero
    } // END for(;;)--¡y pensabas que nunca terminaría!
    
    return 0;
}
```

Observe que tengo dos conjuntos de descriptores de archivo en el código: `master` y `read_fds`. El primero, `master`, contiene todos los descriptores de socket que están actualmente conectados, así como el descriptor de socket que está a la escucha de nuevas conexiones.

La razón por la que tengo el conjunto `master` es que `select()` realmente _cambia_ el conjunto que le pasas para reflejar qué sockets están listos para leer. Como tengo que mantener un registro de las conexiones de una llamada de `select()` a la siguiente, debo almacenarlas de forma segura en algún lugar. En el último momento, copio el `master` en el `read_fds`, y entonces llamo a `select()`.

¿Pero esto no significa que cada vez que obtengo una nueva conexión, tengo que añadirla al conjunto `master`? Sí. ¿Y cada vez que se cierra una conexión, tengo que eliminarla del conjunto `master`? Pues sí.

Fíjate que compruebo cuando el socket `listener` está listo para leer. Cuando lo está, significa que tengo una nueva conexión pendiente, y la `acept()` y la añado al conjunto `master`. De forma similar, cuando una conexión cliente está lista para leer, y `recv()` devuelve `0`, sé que el cliente ha cerrado la conexión, y debo eliminarla del conjunto `master`.

Sin embargo, si la función `recv()` del cliente devuelve un valor distinto de cero, sé que se han recibido algunos datos. Así que lo obtengo, y luego recorro la lista de `master` y envío esos datos al resto de los clientes conectados.

Y eso, amigos míos, es una visión menos que simple de la todopoderosa función `select()`.

Nota rápida para todos los fans de Linux: a veces, en raras circunstancias, la función `select()` de Linux puede devolver "ready-to-read" «listo para leer» ¡y no estar realmente listo para leer! Esto significa que bloqueará la función `read()` después de que `select()` diga que no lo hará. ¿Por qué pequeño...? De todas formas, la solución es poner la macro  [i[`O_NONBLOCK` macro]] `O_NONBLOCK` en el socket receptor para que se produzca un error con `EWOULDBLOCK` (que puede ignorar con seguridad si ocurre). Vea la [página de referencia `fcntl()`](#fcntlman) para más información sobre cómo configurar un socket como no-bloqueante.

Además, aquí hay una idea extra: hay otra función llamada  [i[`poll()` function]] `poll()` que se comporta de forma muy similar a `select()`, pero con un sistema diferente para gestionar los conjuntos de descriptores de fichero. [Check it out!](#pollman)

[i[`select()` function]>]

## Manejo de `send()`s parciales {#sendall}

¿Recuerdas en la [sección sobre `send()`](#sendrecv), más arriba, cuando dije que `send()` podría no enviar todos los bytes que le pidieras? Es decir, quieres que envíe 512 bytes, pero devuelve 412. ¿Qué pasó con los 100 bytes restantes?

Bueno, siguen en tu pequeño buffer esperando a ser enviados. Debido a circunstancias fuera de tu control, el kernel decidió no enviar todos los datos en un solo trozo, y ahora, amigo mío, depende de ti hacer que los datos salgan.

[i[`sendall()` function]<]
También podrías escribir una función como esta para hacerlo:

```{.c .numberLines}
#include <sys/types.h>
#include <sys/socket.h>

int sendall(int s, char *buf, int *len)
{
    int total = 0; // cuántos bytes hemos enviado
    int bytesleft = *len; // cuántos bytes nos quedan por enviar
    int n;

    while(total < *len) {
        n = send(s, buf+total, bytesleft, 0);
        if (n == -1) { break; }
        total += n;
        bytesleft -= n;
    }

    *len = total; // aquí se devuelve el número realmente enviado

    return n==-1?-1:0; // devuelve -1 en caso de fallo, 0 en caso de éxito
} 
```

En este ejemplo, `s` es el socket al que quieres enviar los datos, `buf` es el buffer que contiene los datos, y `len` es un puntero a un `int` que contiene el número de bytes en el buffer.

La función devuelve `-1` en caso de error (y `errno` se mantiene desde la llamada a `send()`). Además, el número de bytes realmente enviados se devuelve en `len`. Este será el mismo número de bytes que le pidió que enviara, a menos que hubiera un error. `sendall()` hará todo lo posible, resoplando y resoplando, para enviar los datos, pero si hay un error, se lo devolverá de inmediato.

Para completar, aquí hay un ejemplo de llamada a la función:

```{.c .numberLines}
char buf[10] = "Beej!";
int len;

len = strlen(buf);
if (sendall(s, buf, &len) == -1) {
    perror("sendall");
    printf("We only sent %d bytes because of the error!\n", len);
} 
```

[i[`sendall()` function]>]

¿Qué ocurre en el receptor cuando llega parte de un paquete? Si los paquetes son de longitud variable, ¿cómo sabe el receptor cuándo termina un paquete y empieza otro? Sí, los escenarios del mundo real son un auténtico dolor de [i[Donkeys]] burros. Probablemente tengas que [i[Data encapsulation]] _encapsular_ (¿recuerdas eso de la [sección de encapsulación de datos](#lowlevel) allá al principio?) Sigue leyendo para más detalles.


## Serialization---Cómo empaquetar datos {#serialization}

[i[Serialization]<]

Es bastante fácil enviar datos de texto a través de la red,
pero ¿qué pasa si quieres enviar datos «binarios» como `int`s o `float`s? Resulta que tienes varias opciones.

1. Convierte el número en texto con una función como `sprintf()`, luego envía el texto. El receptor volverá a convertir el texto en un número utilizando una función como `strtol()`.

2. Simplemente envíe los datos sin procesar, pasando un puntero a los datos a `send()`.

3. Codificar el número en un formato binario portable. El receptor lo decodificará.

¡Preestreno! ¡Sólo esta noche!

[_Se levanta el telón_]

Beej dice: «¡Prefiero el Método Tres, arriba!»

[_THE END_]

(Antes de empezar esta sección en serio, debo decirte que existen librerías para hacer esto, y que crear la tuya propia y mantenerla portable y sin errores es todo un reto. Así que busca y haz los deberes antes de decidirte a implementar esto tú mismo. Incluyo la información aquí para aquellos curiosos sobre cómo funcionan estas cosas).

En realidad, todos los métodos anteriores tienen sus inconvenientes y ventajas, pero, como he dicho, en general, prefiero el tercer método. Primero, sin embargo, hablemos de algunos de los inconvenientes y ventajas de los otros dos.

El primer método, codificar los números como texto antes de enviarlos, tiene la ventaja de que puedes imprimir y leer fácilmente los datos que llegan por el cable.  A veces es excelente utilizar un protocolo legible por humanos en una situación que no requiera mucho ancho de banda, como con [i[IRC]] [fl[Internet Relay Chat (IRC)|https://en.wikipedia.org/wiki/Internet_Relay_Chat]]. Sin embargo, tiene la desventaja de que es lento de convertir, ¡y los resultados casi siempre ocupan más espacio que el número original!

Segundo método: pasar los datos en bruto. Este es bastante fácil (¡pero peligroso!): simplemente toma un puntero a los datos a enviar, y llama a send con él.

```{.c}
double d = 3490.15926535;

send(s, &d, sizeof d, 0);  /* DANGER--non-portable! */
```

El receptor lo recibe así:

```{.c}
double d;

recv(s, &d, sizeof d, 0);  /* PELIGRO--¡no portable! */
```

Rápido, sencillo... ¿qué más se puede pedir? Bueno, resulta que no todas las arquitecturas representan un `doble` (o un `int`) con la misma representación de bits, ni siquiera con el mismo orden de bytes. El código es decididamente no portable. (Hey---quizás no necesites portabilidad, en cuyo caso esto es bonito y rápido).

Al empaquetar tipos enteros, ya hemos visto cómo la clase de funciones [i[`htons()` function]] `htons()` puede ayudar a mantener las cosas portables transformando los números en [i[Byte ordering]] Network Byte Order, y cómo eso es lo correcto. Desafortunadamente, no hay funciones similares para los tipos `float`. ¿Se ha perdido toda esperanza?

No tema. (¿Te has asustado por un segundo? ¿No? ¿Ni siquiera un poquito?) Hay algo que podemos hacer: podemos empaquetar (o «marshal», o «serializar», o uno de los mil millones de otros nombres) los datos en un formato binario conocido que el receptor pueda desempaquetar en el lado remoto.

¿Qué quiero decir con "formato binario conocido"? Bueno, ya hemos visto el ejemplo de `htons()`, ¿verdad? Cambia (o «codifica», si quieres verlo así) un número de cualquier formato del host a Network Byte Order. Para invertir (descodificar) el número, el receptor llama a `ntohs()`.

¿Pero no acababa de decir que no existía tal función para otros tipos no enteros? Sí. Pues sí. Y como no hay una forma estándar en C de hacer esto, es un poco complicado (un juego de palabras gratuito para los fans de Python).

Lo que hay que hacer es empaquetar los datos en un formato conocido y enviarlo por cable para su decodificación. Por ejemplo, para empaquetar `float`s, aquí está [flx[algo rápido y sucio con mucho margen de mejora|pack.c]]:

```{.c .numberLines}
#include <stdint.h>

uint32_t htonf(float f)
{
    uint32_t p;
    uint32_t sign;

    if (f < 0) { sign = 1; f = -f; }
    else { sign = 0; }
        
    p = ((((uint32_t)f)&0x7fff)<<16) | (sign<<31); // parte entera y signo
    p |= (uint32_t)(((f - (int)f) * 65536.0f))&0xffff; // fracción

    return p;
}

float ntohf(uint32_t p)
{
    float f = ((p>>16)&0x7fff); // parte entera
    f += (p&0xffff) / 65536.0f; // fracción

    if (((p>>31)&0x1) == 0x1) { f = -f; } // bit de signo activado

    return f;
}
```

El código anterior es una especie de implementación ingenua que almacena un `float` en un número de 32 bits. El bit más alto (31) se utiliza para almacenar el signo del número («1» significa negativo), y los siete bits siguientes (30-16) se utilizan para almacenar la parte entera del `float`. Por último, los bits restantes (15-0) se utilizan para almacenar la parte fraccionaria del número.

Su uso es bastante sencillo:

```{.c .numberLines}
#include <stdio.h>

int main(void)
{
    float f = 3.1415926, f2;
    uint32_t netf;

    netf = htonf(f);  // convertir a formato de "red"
    f2 = ntohf(netf); // volver a convertir en prueba

    printf("Original: %f\n", f);        // 3.141593
    printf(" Network: 0x%08X\n", netf); // 0x0003243F
    printf("Unpacked: %f\n", f2);       // 3.141586

    return 0;
}
```

Lo bueno es que es pequeño, sencillo y rápido. En el lado negativo, no es un uso eficiente del espacio y el rango está severamente restringido - ¡intenta almacenar un número mayor que 32767 y no estará muy contento!
También puedes ver en el ejemplo anterior que los últimos decimales no se conservan correctamente.

¿Qué podemos hacer en su lugar? Bueno, _El_ estándar para almacenar números en coma flotante se conoce como [i[IEEE-754]] [fl[IEEE-754|https://en.wikipedia.org/wiki/IEEE_754]].  La mayoría de los ordenadores utilizan este formato internamente para realizar operaciones matemáticas en coma flotante, por lo que en esos casos, estrictamente hablando, no sería necesario realizar la conversión. Pero si quieres que tu código fuente sea portable, esa es una suposición que no puedes hacer necesariamente. (Por otro lado, si quieres que las cosas sean rápidas, ¡deberías optimizar esto en plataformas que no necesiten hacerlo! Eso es lo que hacen `htons()` y similares).

[flx[Aquí hay algo de código que codifica flotantes y dobles en formato IEEE-754|ieee754.c]]. (Mayormente---no codifica NaN o Infinito, pero podría ser modificado para hacerlo).

```{.c .numberLines}
#define pack754_32(f) (pack754((f), 32, 8))
#define pack754_64(f) (pack754((f), 64, 11))
#define unpack754_32(i) (unpack754((i), 32, 8))
#define unpack754_64(i) (unpack754((i), 64, 11))

uint64_t pack754(long double f, unsigned bits, unsigned expbits)
{
    long double fnorm;
    int shift;
    long long sign, exp, significand;
    unsigned significandbits = bits - expbits - 1; // -1 for sign bit

    if (f == 0.0) return 0; // quita este caso especial de en medio

    // comprobar signo e iniciar normalización
    if (f < 0) { sign = 1; fnorm = -f; }
    else { sign = 0; fnorm = f; }

    // obtener la forma normalizada de f y seguir el exponente
    shift = 0;
    while(fnorm >= 2.0) { fnorm /= 2.0; shift++; }
    while(fnorm < 1.0) { fnorm *= 2.0; shift--; }
    fnorm = fnorm - 1.0;

    // calcular la forma binaria (no-float) de los datos del significando
    significand = fnorm * ((1LL<<significandbits) + 0.5f);

    // obtener el exponente sesgado
    exp = shift + ((1<<(expbits-1)) - 1); // shift + bias

    // devuelve la respuesta final
    return (sign<<(bits-1)) | (exp<<(bits-expbits-1)) | significand;
}

long double unpack754(uint64_t i, unsigned bits, unsigned expbits)
{
    long double result;
    long long shift;
    unsigned bias;
    unsigned significandbits = bits - expbits - 1; // -1 for sign bit

    if (i == 0) return 0.0;

    // extraer el significante
    result = (i&((1LL<<significandbits)-1)); // mask
    result /= (1LL<<significandbits); // volver a convertir a float
    result += 1.0f; // volver a añadir el

    // tratar el exponente
    bias = (1<<(expbits-1)) - 1;
    shift = ((i>>significandbits)&((1LL<<expbits)-1)) - bias;
    while(shift > 0) { result *= 2.0; shift--; }
    while(shift < 0) { result /= 2.0; shift++; }

    // fírmelo
    result *= (i>>(bits-1))&1? -1.0: 1.0;

    return result;
}
```

Puse algunas macros útiles en la parte superior para empaquetar y desempaquetar números de 32 bits (probablemente un `float`) y 64 bits (probablemente un `double`), pero la función `pack754()` podría ser llamada directamente y decirle que codifique `bits` de datos (`expbits` de los cuales están reservados para el exponente del número normalizado).

Aquí tienes un ejemplo de uso:

```{.c .numberLines}

#include <stdio.h>
#include <stdint.h> // define los tipos uintN_t
#include <inttypes.h> // define las macros PRIx

int main(void)
{
    float f = 3.1415926, f2;
    double d = 3.14159265358979323, d2;
    uint32_t fi;
    uint64_t di;

    fi = pack754_32(f);
    f2 = unpack754_32(fi);

    di = pack754_64(d);
    d2 = unpack754_64(di);

    printf("float before : %.7f\n", f);
    printf("float encoded: 0x%08" PRIx32 "\n", fi);
    printf("float after  : %.7f\n\n", f2);

    printf("double before : %.20lf\n", d);
    printf("double encoded: 0x%016" PRIx64 "\n", di);
    printf("double after  : %.20lf\n", d2);

    return 0;
}
```

El código anterior produce este resultado:

```
float before : 3.1415925
float encoded: 0x40490FDA
float after  : 3.1415925

double before : 3.14159265358979311600
double encoded: 0x400921FB54442D18
double after  : 3.14159265358979311600
```
Desgraciadamente para ti, el compilador es libre de poner relleno por todas partes en una `struct`, lo que significa que no puedes enviarla por cable en un solo trozo.  (¿No estás harto de oír «no se puede hacer esto», «no se puede hacer aquello»? Lo siento. Citando a un amigo: «Siempre que algo va mal, culpo a Microsoft».  Puede que ésta no sea culpa de Microsoft, hay que reconocerlo, pero la afirmación de mi amigo es completamente cierta).

Volviendo al tema: la mejor forma de enviar la `struct` por cable es empaquetar cada campo de forma independiente y luego desempaquetarlos en la `struct` cuando llegan al otro lado.

Eso es mucho trabajo, es lo que estás pensando. Pues sí. Una cosa que puedes hacer es escribir una función de ayuda que te ayude a empaquetar los datos. ¡Será divertido! ¡Realmente!

En el libro [flr[_The Practice of Programming_|tpop]] de Kernighan y Pike, implementan funciones similares a `printf()` llamadas `pack()` y `unpack()` que hacen exactamente esto. Las enlazaría, pero aparentemente esas funciones no están en línea con el resto del código fuente del libro.

(La práctica de la programación es una lectura excelente. Zeus salva un gatito cada vez que lo recomiendo).

En este punto, voy a dejar un puntero a un [fl[Protocol Buffers implementation in C|https://github.com/protobuf-c/protobuf-c]] que nunca he usado, pero que parece completamente respetable. Los programadores de Python y Perl querrán echar un vistazo a las funciones `pack()` y `unpack()` de sus lenguajes para conseguir lo mismo. Y Java tiene una gran interfaz Serializable que puede usarse de forma similar.

Pero si quieres escribir tu propia utilidad de empaquetado en C, el truco de K&P es usar listas de argumentos variables para hacer funciones tipo `printf()` para construir los paquetes.  [flx[Aquí hay una versión que he cocinado|pack2.c]] por mi cuenta basada en eso que espero que sea suficiente para darte una idea de cómo puede funcionar algo así.

(Este código hace referencia a las funciones `pack754()`, arriba. Las funciones `packi*()` operan como la familiar familia `htons()`, excepto que empaquetan en un array `char` en lugar de otro entero).

```{.c .numberLines}
#include <stdio.h>
#include <ctype.h>
#include <stdarg.h>
#include <string.h>

/*
** packi16() -- almacena un int de 16 bits en un buffer char (como htons())
*/ 
void packi16(unsigned char *buf, unsigned int i)
{
    *buf++ = i>>8; *buf++ = i;
}

/*
** packi32() -- almacenar un int de 32 bits en un búfer char (como htonl())
*/ 
void packi32(unsigned char *buf, unsigned long int i)
{
    *buf++ = i>>24; *buf++ = i>>16;
    *buf++ = i>>8;  *buf++ = i;
}

/*
** packi64() -- almacenar un int de 64 bits en un búfer char (como htonl())
*/ 
void packi64(unsigned char *buf, unsigned long long int i)
{
    *buf++ = i>>56; *buf++ = i>>48;
    *buf++ = i>>40; *buf++ = i>>32;
    *buf++ = i>>24; *buf++ = i>>16;
    *buf++ = i>>8;  *buf++ = i;
}

/*
** unpacki16() -- descomprimir un int de 16 bits de un búfer char (como ntohs())
*/ 
int unpacki16(unsigned char *buf)
{
    unsigned int i2 = ((unsigned int)buf[0]<<8) | buf[1];
    int i;

    // change unsigned numbers to signed
    if (i2 <= 0x7fffu) { i = i2; }
    else { i = -1 - (unsigned int)(0xffffu - i2); }

    return i;
}

/*
** unpacku16() -- desempaqueta un unsigned de 16 bits de un buffer char (como ntohs())
*/ 
unsigned int unpacku16(unsigned char *buf)
{
    return ((unsigned int)buf[0]<<8) | buf[1];
}

/*
** unpacki32() -- descomprimir un int de 32 bits de un búfer char (como ntohl())
*/ 
long int unpacki32(unsigned char *buf)
{
    unsigned long int i2 = ((unsigned long int)buf[0]<<24) |
                           ((unsigned long int)buf[1]<<16) |
                           ((unsigned long int)buf[2]<<8)  |
                           buf[3];
    long int i;

    // cambiar números sin signo a con signo
    if (i2 <= 0x7fffffffu) { i = i2; }
    else { i = -1 - (long int)(0xffffffffu - i2); }

    return i;
}

/*
** unpacku32() -- desempaqueta un unsigned de 32 bits de un buffer char (como ntohl())
*/ 
unsigned long int unpacku32(unsigned char *buf)
{
    return ((unsigned long int)buf[0]<<24) |
           ((unsigned long int)buf[1]<<16) |
           ((unsigned long int)buf[2]<<8)  |
           buf[3];
}

/*
** unpacki64() -- descomprime un int de 64 bits de un buffer char (como ntohl())
*/ 
long long int unpacki64(unsigned char *buf)
{
    unsigned long long int i2 = ((unsigned long long int)buf[0]<<56) |
                                ((unsigned long long int)buf[1]<<48) |
                                ((unsigned long long int)buf[2]<<40) |
                                ((unsigned long long int)buf[3]<<32) |
                                ((unsigned long long int)buf[4]<<24) |
                                ((unsigned long long int)buf[5]<<16) |
                                ((unsigned long long int)buf[6]<<8)  |
                                buf[7];
    long long int i;

    // cambiar números sin signo a con signo
    if (i2 <= 0x7fffffffffffffffu) { i = i2; }
    else { i = -1 -(long long int)(0xffffffffffffffffu - i2); }

    return i;
}

/*
** unpacku64() -- desempaqueta un unsigned de 64 bits de un buffer char (como ntohl())
*/ 
unsigned long long int unpacku64(unsigned char *buf)
{
    return ((unsigned long long int)buf[0]<<56) |
           ((unsigned long long int)buf[1]<<48) |
           ((unsigned long long int)buf[2]<<40) |
           ((unsigned long long int)buf[3]<<32) |
           ((unsigned long long int)buf[4]<<24) |
           ((unsigned long long int)buf[5]<<16) |
           ((unsigned long long int)buf[6]<<8)  |
           buf[7];
}

/*
** pack() -- almacena los datos dictados por la cadena de formato en el buffer
**
**   bits |signo   sin-signo   float   string
**   -----+----------------------------------
**      8 |   c        C         
**     16 |   h        H         f
**     32 |   l        L         d
**     64 |   q        Q         g
**      - |                               s
**
** (La longitud de 16 bits sin signo se añade automáticamente a las cadenas)
*/ 

unsigned int pack(unsigned char *buf, char *format, ...)
{
    va_list ap;

    signed char c;              // 8-bit
    unsigned char C;

    int h;                      // 16-bit
    unsigned int H;

    long int l;                 // 32-bit
    unsigned long int L;

    long long int q;            // 64-bit
    unsigned long long int Q;

    float f;                    // floats
    double d;
    long double g;
    unsigned long long int fhold;

    char *s;                    // strings
    unsigned int len;

    unsigned int size = 0;

    va_start(ap, format);

    for(; *format != '\0'; format++) {
        switch(*format) {
        case 'c': // 8-bit
            size += 1;
            c = (signed char)va_arg(ap, int); // promoted
            *buf++ = c;
            break;

        case 'C': // 8-bit unsigned
            size += 1;
            C = (unsigned char)va_arg(ap, unsigned int); // promoted
            *buf++ = C;
            break;

        case 'h': // 16-bit
            size += 2;
            h = va_arg(ap, int);
            packi16(buf, h);
            buf += 2;
            break;

        case 'H': // 16-bit unsigned
            size += 2;
            H = va_arg(ap, unsigned int);
            packi16(buf, H);
            buf += 2;
            break;

        case 'l': // 32-bit
            size += 4;
            l = va_arg(ap, long int);
            packi32(buf, l);
            buf += 4;
            break;

        case 'L': // 32-bit unsigned
            size += 4;
            L = va_arg(ap, unsigned long int);
            packi32(buf, L);
            buf += 4;
            break;

        case 'q': // 64-bit
            size += 8;
            q = va_arg(ap, long long int);
            packi64(buf, q);
            buf += 8;
            break;

        case 'Q': // 64-bit unsigned
            size += 8;
            Q = va_arg(ap, unsigned long long int);
            packi64(buf, Q);
            buf += 8;
            break;

        case 'f': // float-16
            size += 2;
            f = (float)va_arg(ap, double); // promoted
            fhold = pack754_16(f); // convert to IEEE 754
            packi16(buf, fhold);
            buf += 2;
            break;

        case 'd': // float-32
            size += 4;
            d = va_arg(ap, double);
            fhold = pack754_32(d); // convert to IEEE 754
            packi32(buf, fhold);
            buf += 4;
            break;

        case 'g': // float-64
            size += 8;
            g = va_arg(ap, long double);
            fhold = pack754_64(g); // convert to IEEE 754
            packi64(buf, fhold);
            buf += 8;
            break;

        case 's': // string
            s = va_arg(ap, char*);
            len = strlen(s);
            size += len + 2;
            packi16(buf, len);
            buf += 2;
            memcpy(buf, s, len);
            buf += len;
            break;
        }
    }

    va_end(ap);

    return size;
}

/*
** unpack() -- desempaqueta los datos dictados por la cadena de formato en el buffer
**
**   bits |signed   unsigned   float   string
**   -----+----------------------------------
**      8 |   c        C         
**     16 |   h        H         f
**     32 |   l        L         d
**     64 |   q        Q         g
**      - |                               s
**
** (la cadena se extrae en función de su longitud almacenada, pero 's' se puede
** con una longitud máxima)
*/
void unpack(unsigned char *buf, char *format, ...)
{
    va_list ap;

    signed char *c;              // 8-bit
    unsigned char *C;

    int *h;                      // 16-bit
    unsigned int *H;

    long int *l;                 // 32-bit
    unsigned long int *L;

    long long int *q;            // 64-bit
    unsigned long long int *Q;

    float *f;                    // floats
    double *d;
    long double *g;
    unsigned long long int fhold;

    char *s;
    unsigned int len, maxstrlen=0, count;

    va_start(ap, format);

    for(; *format != '\0'; format++) {
        switch(*format) {
        case 'c': // 8-bit
            c = va_arg(ap, signed char*);
            if (*buf <= 0x7f) { *c = *buf;} // re-sign
            else { *c = -1 - (unsigned char)(0xffu - *buf); }
            buf++;
            break;

        case 'C': // 8-bit unsigned
            C = va_arg(ap, unsigned char*);
            *C = *buf++;
            break;

        case 'h': // 16-bit
            h = va_arg(ap, int*);
            *h = unpacki16(buf);
            buf += 2;
            break;

        case 'H': // 16-bit unsigned
            H = va_arg(ap, unsigned int*);
            *H = unpacku16(buf);
            buf += 2;
            break;

        case 'l': // 32-bit
            l = va_arg(ap, long int*);
            *l = unpacki32(buf);
            buf += 4;
            break;

        case 'L': // 32-bit unsigned
            L = va_arg(ap, unsigned long int*);
            *L = unpacku32(buf);
            buf += 4;
            break;

        case 'q': // 64-bit
            q = va_arg(ap, long long int*);
            *q = unpacki64(buf);
            buf += 8;
            break;

        case 'Q': // 64-bit unsigned
            Q = va_arg(ap, unsigned long long int*);
            *Q = unpacku64(buf);
            buf += 8;
            break;

        case 'f': // float
            f = va_arg(ap, float*);
            fhold = unpacku16(buf);
            *f = unpack754_16(fhold);
            buf += 2;
            break;

        case 'd': // float-32
            d = va_arg(ap, double*);
            fhold = unpacku32(buf);
            *d = unpack754_32(fhold);
            buf += 4;
            break;

        case 'g': // float-64
            g = va_arg(ap, long double*);
            fhold = unpacku64(buf);
            *g = unpack754_64(fhold);
            buf += 8;
            break;

        case 's': // string
            s = va_arg(ap, char*);
            len = unpacku16(buf);
            buf += 2;
            if (maxstrlen > 0 && len >= maxstrlen) count = maxstrlen - 1;
            else count = len;
            memcpy(s, buf, count);
            s[count] = '\0';
            buf += len;
            break;

        default:
            if (isdigit(*format)) { // track max str len
                maxstrlen = maxstrlen * 10 + (*format-'0');
            }
        }

        if (!isdigit(*format)) maxstrlen = 0;
    }

    va_end(ap);
}
```

Y [flx[aquí hay un programa de demostración|pack2.c]] del código anterior que empaqueta algunos datos en `buf` y luego los desempaqueta en variables. Tenga en cuenta que cuando llame a `unpack()` con un argumento de cadena (especificador de formato `s`), es aconsejable poner un contador de longitud máxima delante de él para evitar un desbordamiento del búfer, por ejemplo, `96s`. Tenga cuidado cuando desempaquete datos que reciba a través de la red: ¡un usuario malintencionado podría enviar paquetes mal construidos con la intención de atacar su sistema!

```{.c .numberLines}
#include <stdio.h>

// varios bits para tipos de coma flotante--
// varía según la arquitectura
typedef float float32_t;
typedef double float64_t;

int main(void)
{
    unsigned char buf[1024];
    int8_t magic;
    int16_t monkeycount;
    int32_t altitude;
    float32_t absurdityfactor;
    char *s = "Great unmitigated Zot! You've found the Runestaff!";
    char s2[96];
    int16_t packetsize, ps2;

    packetsize = pack(buf, "chhlsf", (int8_t)'B', (int16_t)0, (int16_t)37, 
            (int32_t)-5, s, (float32_t)-3490.6677);
    packi16(buf+1, packetsize); // almacena el tamaño del paquete en packet for kicks

    printf("packet is %" PRId32 " bytes\n", packetsize);

    unpack(buf, "chhl96sf", &magic, &ps2, &monkeycount, &altitude, s2,
        &absurdityfactor);

    printf("'%c' %" PRId32" %" PRId16 " %" PRId32
            " \"%s\" %f\n", magic, ps2, monkeycount,
            altitude, s2, absurdityfactor);

    return 0;
}
```

Tanto si desarrollas tu propio código como si utilizas el de otro, es una buena idea tener un conjunto general de rutinas de empaquetado de datos para mantener los errores bajo control, en lugar de empaquetar cada bit a mano cada vez.

¿Cuál es el mejor formato para empaquetar los datos? Excelente pregunta. Afortunadamente, [i[XDR]] [flrfc[RFC 4506|4506]], el Estándar de Representación de Datos Externos, ya define formatos binarios para un montón de tipos diferentes, como tipos de coma flotante, tipos enteros, matrices, datos brutos, etc. Te sugiero que lo sigas si vas a enrollar los datos tú mismo. Pero no estás obligado a hacerlo. La policía de los paquetes no está delante de tu puerta. Al menos, no creo que lo estén.

En cualquier caso, codificar los datos de una forma u otra antes de enviarlos es la forma correcta de hacer las cosas.

[i[Serialization]>]

## Hijo de la encapsulación de datos {#sonofdataencap}
¿Qué significa realmente encapsular datos? En el caso más sencillo, se trata de incluir una cabecera con información identificativa o la longitud del paquete, o ambas cosas.

¿Qué aspecto debe tener la cabecera? Bueno, son sólo algunos datos binarios que representan lo que consideres necesario para completar tu proyecto.

Vaya. Eso es vago.

Bien. Por ejemplo, digamos que tienes un programa de chat multiusuario que usa `SOCK_STREAM`s. Cuando un usuario teclea (dice) algo, hay que transmitir dos informaciones al servidor: qué se ha dicho y quién lo ha dicho.

¿Hasta aquí todo bien? "¿Cuál es el problema?", te preguntarás.

El problema es que los mensajes pueden ser de distinta longitud. Una persona llamada "tom" puede decir: "Hi", y otra persona llamada "Benjamin" puede decir: "Hey guys what is up?".

Así que `send()` todas estas cosas a los clientes a medida que van llegando. Tu flujo de datos salientes se parece a esto:
```
t o m H i B e n j a m i n H e y g u y s w h a t i s u p ?
```

Y así sucesivamente. ¿Cómo sabe el cliente cuándo empieza un mensaje y termina otro?  Podrías, si quisieras, hacer que todos los mensajes tuvieran la misma longitud y simplemente llamar a la función [i[`sendall()` function]] que implementamos, [arriba](#sendall). Pero eso desperdicia ancho de banda. No queremos `send()` (enviar) 1024 bytes sólo para que «tom» pueda decir "Hi".

Así que _encapsulamos_ los datos en una pequeña estructura de cabecera y paquete. Tanto el cliente como el servidor saben cómo empaquetar y desempaquetar (a veces denominado «marshal» y «unmarshal») estos datos. No mires ahora, pero estamos empezando a definir un _protocolo_ que describe cómo se comunican un cliente y un servidor.

En este caso, vamos a suponer que el nombre de usuario tiene una longitud fija de 8 caracteres, rellenados con `'\0'`. Y supongamos que los datos son de longitud variable, hasta un máximo de 128 caracteres. Veamos un ejemplo de estructura de paquete que podríamos utilizar en esta situación:


1. `len` (1 byte, sin signo)---La longitud total del paquete, contando el nombre de usuario de 8 bytes y los datos del chat.

2. `name` (8 bytes)---El nombre del usuario, relleno NUL si es necesario.

3. (_n_-bytes)---Los datos en sí, no más de 128 bytes. La longitud del paquete debe calcularse como la longitud de estos datos más 8 (la longitud del campo de nombre, arriba).

¿Por qué elegí los límites de 8 y 128 bytes para los campos? Los saqué de la nada, suponiendo que serían suficientemente largos. Sin embargo, tal vez 8 bytes sea demasiado restrictivo para tus necesidades y puedas tener un campo de nombre de 30 bytes, o lo que sea.  La elección depende de ti.

Usando la definición de paquete anterior, el primer paquete consistiría en la siguiente información (en hexadecimal y ASCII):

```
   0A     74 6F 6D 00 00 00 00 00      48 69
(length)  T  o  m    (padding)         H  i
```

Y la segunda es similar:

```
   18     42 65 6E 6A 61 6D 69 6E      48 65 79 20 67 75 79 73 20 77 ...
(length)  B  e  n  j  a  m  i  n       H  e  y     g  u  y  s     w  ...
```

(Por supuesto, la longitud se almacena en orden de bytes de red. En este caso, es sólo un byte, así que no importa, pero en general querrás que todos tus enteros binarios se almacenen en Orden de Bytes de Red en tus paquetes)

Cuando estés enviando estos datos, deberías estar seguro y usar un comando similar a [`sendall()`](#sendall), para que sepas que todos los datos han sido enviados, incluso si se necesitan múltiples llamadas a `send()` para obtenerlos todos

Del mismo modo, cuando reciba estos datos, tendrá que hacer un poco más de trabajo.  Para estar seguro, debes asumir que podrías recibir un paquete parcial (como tal vez recibimos "`18 42 65 6E 6A`"" de Benjamin, arriba, pero eso es todo lo que obtenemos en esta llamada a `recv()`). Necesitamos llamar a `recv()` una y otra vez hasta que el paquete sea recibido completamente.

¿Cómo? Bueno, sabemos el número de bytes que necesitamos recibir en total para que el paquete esté completo, ya que ese número aparece en la parte delantera del paquete.  También sabemos que el tamaño máximo del paquete es 1+8+128, o 137 bytes (porque así es como definimos el paquete).

En realidad hay un par de cosas que puedes hacer aquí. Como sabe que cada paquete comienza con una longitud, puede llamar a `recv()` sólo para obtener la longitud del paquete.  Entonces, una vez que tenga eso, puede llamarla de nuevo especificando exactamente la longitud restante del paquete (posiblemente repetidamente para obtener todos los datos) hasta que tenga el paquete completo. La ventaja de este método es que sólo necesita un buffer lo suficientemente grande para un paquete, mientras que la desventaja es que necesita llamar a `recv()` al menos dos veces para obtener todos los datos.

Otra opción es simplemente llamar a `recv()` y decir que la cantidad que estás dispuesto a recibir es el número máximo de bytes en un paquete. Entonces, lo que obtenga, péguelo en la parte posterior de un buffer, y finalmente compruebe si el paquete está completo. Por supuesto, puede que recibas algo del siguiente paquete, así que necesitarás tener espacio para eso.

Lo que puedes hacer es declarar un array lo suficientemente grande para dos paquetes. Este es tu array de trabajo donde reconstruirás los paquetes según vayan llegando.

Cada vez que `recv()` datos, los añadirá al búfer de trabajo y comprobará si el paquete está completo. Esto es, el número de bytes en el buffer es mayor o igual que la longitud especificada en la cabecera (+1, porque la longitud en la cabecera no incluye el byte para la longitud en sí). Si el número de bytes en el búfer es inferior a 1, el paquete no está completo, obviamente. Tienes que hacer un caso especial para esto, ya que el primer byte es basura y no puedes confiar en él para la longitud correcta del paquete

Una vez que el paquete está completo, puedes hacer con él lo que quieras. Utilízalo y elimínalo de tu búfer de trabajo.

¡Uf! ¿Ya estás haciendo malabarismos en tu cabeza? Bien, aquí está el segundo de los dos golpes: puede que hayas leído más allá del final de un paquete y sobre el siguiente en una sola llamada a `recv()`. Es decir, ¡tienes un buffer de trabajo con un paquete completo, y una parte incompleta del siguiente paquete! Maldita sea. (Pero esta es la razón por la que hizo su búfer de trabajo lo suficientemente grande como para contener _dos_ paquetes--¡en caso de que esto ocurriera!)

Como conoces la longitud del primer paquete por la cabecera, y has estado llevando la cuenta del número de bytes en el búfer de trabajo, puedes restar y calcular cuántos de los bytes del búfer de trabajo pertenecen al segundo paquete (incompleto). Cuando haya manejado el primero, puede borrarlo del búfer de trabajo y mover el segundo paquete parcial al frente del búfer para que esté listo para el siguiente `recv()`.

(Algunos de los lectores notarán que mover el segundo paquete parcial al principio del buffer de trabajo toma tiempo, y el programa puede ser codificado para no requerir esto usando un buffer circular. Desafortunadamente para el resto de ustedes, una discusión sobre buffers circulares está más allá del alcance de este artículo. Si todavía tienes curiosidad, coge un libro de estructuras de datos y sigue a partir de ahí).

Nunca dije que fuera fácil. Vale, sí dije que era fácil. Y lo es; sólo necesitas práctica y muy pronto te saldrá de forma natural. Por [i[Excalibur]] Excalibur ¡lo juro!


## Paquetes de difusión... ¡Hola, mundo!

Hasta ahora, esta guía ha hablado sobre el envío de datos de un host a otro host. ¡Pero es posible, insisto, que puedas, con la autoridad apropiada, enviar datos a múltiples hosts _al mismo tiempo_!

Con [i[UDP]] UDP (sólo UDP, no TCP) e IPv4 estándar, esto se hace a través de un mecanismo llamado [i[Broadcast]] _broadcasting_. Con IPv6, la difusión no está soportada, y tienes que recurrir a la técnica a menudo superior de _multicasting_, que, por desgracia, no voy a discutir en este momento. Pero basta de futuro, estamos atrapados en el presente de 32 bits.

Pero, ¡espera! No puedes simplemente salir corriendo y empezar a emitir como si nada; Tienes que [i[`setsockopt()` function]] establecer la opción de socket [i[`SO_BROADCAST` macro]] `SO_BROADCAST` antes de poder enviar un paquete broadcast a la red. ¡Es como una de esas pequeñas tapas de plástico que ponen sobre el interruptor de lanzamiento de misiles! ¡Eso es todo el poder que tienes en tus manos!

Pero en serio, hay un peligro en el uso de paquetes de difusión, y es que cada sistema que recibe un paquete de difusión debe deshacer todas las capas de encapsulación de datos hasta que averigua a qué puerto están destinados los datos. Y entonces entrega los datos o los descarta. En cualquier caso, es mucho trabajo para cada máquina que recibe el paquete de difusión, y puesto que son todas ellas en la red local, podrían ser muchas máquinas haciendo mucho trabajo innecesario. Cuando el juego Doom salió por primera vez, esta era una queja sobre su código de red.

Ahora, hay más de una manera de despellejar a un gato... espera un minuto. ¿De verdad hay más de una forma de despellejar a un gato? ¿Qué clase de expresión es esa? Uh, y del mismo modo, hay más de una manera de enviar un paquete de difusión. Así que, para llegar a la carne y las patatas de todo el asunto: ¿cómo se especifica la dirección de destino de un mensaje de difusión? Hay dos formas comunes:

1. Enviar los datos a la dirección de difusión de una subred específica. Este es el número de red de la subred con todos los bits de la parte de host de la dirección. Por ejemplo, en casa mi red es `192.168.1.0`, mi máscara de red es `255.255.255.0`, así que el último byte de la dirección es mi número de host (porque los tres primeros bytes, según la máscara de red,  son el número de red). Así que mi dirección de difusión es `192.168.1.255`. En Unix, el comando `ifconfig` le dará todos estos datos. datos. (Si tienes curiosidad, la lógica bit a bit para obtener tu dirección de transmisión es es `número_de_red` (network_number) O (NO `máscara_de_red`). Puedes enviar este tipo de paquete de difusión a redes remotas, así como a su red local, pero corre el riesgo de que el paquete sea descartado por el enrutador de destino.  (Si no lo descartan, un pitufo al azar podría empezar a inundar su LAN con tráfico de difusión).

2. Envía los datos a la dirección de difusión «global». Esto es [i[`255.255.255.255`]] `255.255.255.255`, también conocido como [i[`INADDR_BROADCAST` macro]] `INADDR_BROADCAST`. Muchas máquinas automáticamente bitwise AND esto con su número de red para convertirlo en una dirección de difusión de red, pero algunos no. Esto varía. Irónicamente, los routers no reenvían este tipo de paquetes de difusión fuera de la red local.

Entonces, ¿qué pasa si intentas enviar datos en la dirección de difusión sin configurar primero la opción de socket `SO_BROADCAST`? Bueno, encendamos el viejo [`talker` and `listener`](#datagram) y veamos que pasa.

```
$ talker 192.168.1.2 foo
sent 3 bytes to 192.168.1.2
$ talker 192.168.1.255 foo
sendto: Permission denied
$ talker 255.255.255.255 foo
sendto: Permission denied
```

Sí, no está nada contento... porque no hemos puesto la opción de socket `SO_BROADCAST`. Hazlo, ¡y ahora puedes `sendto()` donde quieras!

De hecho, esa es la _única diferencia_ entre una aplicación UDP que puede emitir y una que no. Así que tomemos la vieja aplicación `talker` y añadamos una sección que establezca la opción de socket `SO_BROADCAST`. Llamaremos a este programa [flx[`broadcaster.c`|broadcaster.c]]:

```{.c .numberLines}
/*
** broadcaster.c -- un «cliente» de datagramas como talker.c, excepto que
** que este puede emitir
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>

#define SERVERPORT 4950 // el puerto al que se conectarán los usuarios

int main(int argc, char *argv[])
{
    int sockfd;
    struct sockaddr_in their_addr; // información de la dirección del conector
    struct hostent *he;
    int numbytes;
    int broadcast = 1;
    //char broadcast = '1'; // si eso no funciona, prueba esto

    if (argc != 3) {
        fprintf(stderr,"usage: broadcaster hostname message\n");
        exit(1);
    }

    if ((he=gethostbyname(argv[1])) == NULL) {  // get the host info
        perror("gethostbyname");
        exit(1);
    }

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) == -1) {
        perror("socket");
        exit(1);
    }

    // esta llamada es la que permite enviar paquetes de difusión:
    if (setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST, &broadcast,
        sizeof broadcast) == -1) {
        perror("setsockopt (SO_BROADCAST)");
        exit(1);
    }

    their_addr.sin_family = AF_INET;     // orden de bytes del host
    their_addr.sin_port = htons(SERVERPORT); // short, orden de bytes de red
    their_addr.sin_addr = *((struct in_addr *)he->h_addr);
    memset(their_addr.sin_zero, '\0', sizeof their_addr.sin_zero);

    if ((numbytes=sendto(sockfd, argv[2], strlen(argv[2]), 0,
             (struct sockaddr *)&their_addr, sizeof their_addr)) == -1) {
        perror("sendto");
        exit(1);
    }

    printf("sent %d bytes to %s\n", numbytes,
        inet_ntoa(their_addr.sin_addr));

    close(sockfd);

    return 0;
}
```

¿Qué diferencia hay entre esto y una situación cliente/servidor UDP «normal»?  En nada. (Con la excepción de que al cliente se le permite enviar paquetes de difusión en este caso). Como tal, siga adelante y ejecute el viejo programa UDP [`listener`](#datagram) en una ventana, y `broadcaster` en otra. Ahora debería ser capaz de hacer todos los envíos que fallaron, más arriba.

```
$ broadcaster 192.168.1.2 foo
sent 3 bytes to 192.168.1.2
$ broadcaster 192.168.1.255 foo
sent 3 bytes to 192.168.1.255
$ broadcaster 255.255.255.255 foo
sent 3 bytes to 255.255.255.255
```

Y deberías ver a `listener` respondiendo que recibió los paquetes. (Si `listener` no responde, podría ser porque está enlazado a una dirección IPv6. Prueba a cambiar `AF_INET6` en `listener.c` por `AF_INET` para forzar IPv4).

Bueno, eso es emocionante. Pero ahora enciende `listener` en otra máquina a tu lado en la misma red para tener dos copias, una en cada máquina, y ejecuta `broadcaster` de nuevo con tu dirección de emisión... ¡Ambos `listener` reciben el paquete aunque sólo hayas llamado a `sendto()` una vez! ¡Genial!

Si el `listener` recibe los datos que le envías directamente, pero no los datos en la dirección de broadcast, puede ser que tengas un [i[Firewall]] firewall en tu máquina local que esté bloqueando los paquetes. (Sí, [i[Pat]] Pat y [i[Bapper]] Bapper, gracias por daros cuenta antes que yo de que por eso no funcionaba mi código de ejemplo. Os dije que os mencionaría en la guía, y aquí estáis. Así que _nyah_).

De nuevo, ten cuidado con los paquetes broadcast. Dado que cada máquina de la LAN se verá forzada a tratar con el paquete tanto si lo `recvfrom()`s como si no, puede suponer una gran carga para toda la red informática. Definitivamente deben usarse con moderación y apropiadamente.
