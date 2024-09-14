# Cliente-Servidor 

[i[Client/Server]<]

El mundo es cliente-servidor. Casi todo en la red tiene que ver con procesos cliente que hablan con procesos servidor y viceversa. Tomemos `telnet`, por ejemplo. Cuando te conectas a un host remoto en el puerto 23 con telnet (el cliente), un programa en ese host (llamado `telnetd`, el servidor) cobra vida. Maneja la conexión telnet entrante, te prepara un prompt de login, etc.

![Client-Server Interaction.](cs.pdf "[Client-Server Interaction Diagram]")

El intercambio de información entre cliente y servidor se resume en el diagrama anterior.

Nótese que la pareja cliente-servidor puede hablar `SOCK_STREAM`, `SOCK_DGRAM`, o cualquier otra cosa (siempre que hablen lo mismo). Algunos buenos ejemplos de pares cliente-servidor son `telnet`/`telnetd`, `ftp`/`ftpd`, o `Firefox`/`Apache`. Cada vez que usas `ftp`, hay un programa remoto, `ftpd`, que te sirve.

A menudo, sólo habrá un servidor en una máquina, y ese servidor manejará múltiples clientes usando la función [i[`fork()` function]] `fork()`. La rutina básica es: el servidor esperará una conexión, la aceptará y creará un proceso hijo para manejarla. Esto es lo que hace nuestro servidor de ejemplo en la siguiente sección.

## Un simple servidor de streaming

[i[Server-->stream]<]

Todo lo que hace este servidor es enviar la cadena `¡Hola, mundo!` a través de una conexión stream. Todo lo que necesitas hacer para probar este servidor es ejecutarlo en una ventana, y utilizar telnet desde otro lugar con:

```
$ telnet remotehostname 3490
```

donde `remotehostname` es el nombre de la máquina en la que lo estás ejecutando.

[flx[El código del servidor|server.c]]:

```{.c .numberLines}
/*
** server.c -- demostración de un servidor de streaming socket
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <sys/wait.h>
#include <signal.h>

#define PORT "3490"  // el puerto al que se conectarán los usuarios

#define BACKLOG 10   // cuántas conexiones pendientes tendrá la cola

void sigchld_handler(int s)
{
    // waitpid() podría sobreescribir errno, así que lo guardamos y restauramos:
    int saved_errno = errno;

    while(waitpid(-1, NULL, WNOHANG) > 0);

    errno = saved_errno;
}


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
    int sockfd, new_fd;  // escucha en sock_fd, nueva conexión en new_fd
    struct addrinfo hints, *servinfo, *p;
    struct sockaddr_storage their_addr; // información sobre la dirección del conector
    socklen_t sin_size;
    struct sigaction sa;
    int yes=1;
    char s[INET6_ADDRSTRLEN];
    int rv;

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE; // utilizar mi IP

    if ((rv = getaddrinfo(NULL, PORT, &hints, &servinfo)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return 1;
    }

    // bucle a través de todos los resultados y se unen a la primera que podemos
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol)) == -1) {
            perror("server: socket");
            continue;
        }

        if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &yes,
                sizeof(int)) == -1) {
            perror("setsockopt");
            exit(1);
        }

        if (bind(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
            close(sockfd);
            perror("server: bind");
            continue;
        }

        break;
    }

    freeaddrinfo(servinfo); // todo hecho con esta estructura

    if (p == NULL)  {
        fprintf(stderr, "server: failed to bind\n");
        exit(1);
    }

    if (listen(sockfd, BACKLOG) == -1) {
        perror("listen");
        exit(1);
    }

    sa.sa_handler = sigchld_handler; // cosechar todos los procesos muertos
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;
    if (sigaction(SIGCHLD, &sa, NULL) == -1) {
        perror("sigaction");
        exit(1);
    }

    printf("server: waiting for connections...\n");

    while(1) {  // main accept() loop
        sin_size = sizeof their_addr;
        new_fd = accept(sockfd, (struct sockaddr *)&their_addr, &sin_size);
        if (new_fd == -1) {
            perror("accept");
            continue;
        }

        inet_ntop(their_addr.ss_family,
            get_in_addr((struct sockaddr *)&their_addr),
            s, sizeof s);
        printf("server: got connection from %s\n", s);

        if (!fork()) { // este es el proceso hijo
            close(sockfd); // el niño no necesita la escucha
            if (send(new_fd, "Hello, world!", 13, 0) == -1)
                perror("send");
            close(new_fd);
            exit(0);
        }
        close(new_fd);  // padre no necesita esto
    }

    return 0;
}
```

En caso de que tengas curiosidad, tengo el código en una gran función `main()` para (creo) claridad sintáctica. Siéntete libre de dividirlo en funciones más pequeñas si te hace sentir mejor.

(Además, todo esto de [i[`sigaction()` function]] `sigaction()` puede ser nueva para ti---eso está bien. El código que está ahí es responsable de cosechar [i[Zombie process]] procesos zombies que aparecen cuando los procesos hijo `fork()` salen. Si haces muchos zombies y no los cosechas, el administrador de tu sistema se agitará).

Puede obtener los datos de este servidor utilizando el cliente que se indica en la siguiente sección.

[i[Server-->stream]>]

## Un cliente de streaming sencillo

[i[Client-->stream]<]

Este tipo es aún más fácil que el servidor. Todo lo que hace este cliente es conectarse al host que especifiques en la línea de comandos, puerto 3490. Obtiene la cadena que envía el servidor.

[flx[The client source|client.c]]:

```{.c .numberLines}
/*
** client.c -- a stream socket client demo
*/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <netdb.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>

#include <arpa/inet.h>

#define PORT "3490" // el puerto al que se conectará el cliente 

#define MAXDATASIZE 100 // número máximo de bytes que podemos obtener a la vez 

// obtener sockaddr, IPv4 o IPv6:
void *get_in_addr(struct sockaddr *sa)
{
    if (sa->sa_family == AF_INET) {
        return &(((struct sockaddr_in*)sa)->sin_addr);
    }

    return &(((struct sockaddr_in6*)sa)->sin6_addr);
}

int main(int argc, char *argv[])
{
    int sockfd, numbytes;  
    char buf[MAXDATASIZE];
    struct addrinfo hints, *servinfo, *p;
    int rv;
    char s[INET6_ADDRSTRLEN];

    if (argc != 2) {
        fprintf(stderr,"usage: client hostname\n");
        exit(1);
    }

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    if ((rv = getaddrinfo(argv[1], PORT, &hints, &servinfo)) != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
        return 1;
    }

    // bucle a través de todos los resultados y conectarse a la primera que podemos
    for(p = servinfo; p != NULL; p = p->ai_next) {
        if ((sockfd = socket(p->ai_family, p->ai_socktype,
                p->ai_protocol)) == -1) {
            perror("client: socket");
            continue;
        }

        if (connect(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
            close(sockfd);
            perror("client: connect");
            continue;
        }

        break;
    }

    if (p == NULL) {
        fprintf(stderr, "client: failed to connect\n");
        return 2;
    }

    inet_ntop(p->ai_family, get_in_addr((struct sockaddr *)p->ai_addr),
            s, sizeof s);
    printf("client: connecting to %s\n", s);

    freeaddrinfo(servinfo); // all done with this structure

    if ((numbytes = recv(sockfd, buf, MAXDATASIZE-1, 0)) == -1) {
        perror("recv");
        exit(1);
    }

    buf[numbytes] = '\0';

    printf("client: received '%s'\n",buf);

    close(sockfd);

    return 0;
}
```

Observe que si no ejecuta el servidor antes de ejecutar el cliente, `connect()` devuelve [i[Connection refused]] "Connection refused". Muy útil.

[i[Client-->stream]>]

## Datagram Sockets (Sockets de datagramas) {#datagram}

[i[Server-->datagram]<]

Ya hemos cubierto los fundamentos de los sockets de datagramas UDP con nuestra discusión de `sendto()` y `recvfrom()`, más arriba, así que sólo presentaré un par de programas de ejemplo: `talker.c` y `listener.c`.

`listener` se sienta en una máquina esperando un paquete entrante en el puerto 4950. El `talker` envía un paquete a ese puerto, en la máquina especificada, que contiene lo que el usuario introduzca en la línea de comandos.

Dado que los sockets de datagramas no tienen conexión y lanzan paquetes al éter sin tener en cuenta el éxito, vamos a decirle al cliente y al servidor que utilicen específicamente IPv6. De esta manera evitamos la situación en la que el servidor está escuchando en IPv6 y el cliente envía en IPv4; los datos simplemente no se recibirían. (En nuestro mundo de sockets de flujo TCP conectados, aún podríamos tener el desajuste, pero el error en `connect()` para una familia de direcciones nos haría reintentar para la otra).

Aquí está el [flx[fuente para `listener.c`|listener.c]]:

```{.c .numberLines}
/*
** listener.c -- a datagram sockets "server" demo
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

#define MYPORT "4950"	// el puerto al que se conectarán los usuarios

#define MAXBUFLEN 100

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
	int sockfd;
	struct addrinfo hints, *servinfo, *p;
	int rv;
	int numbytes;
	struct sockaddr_storage their_addr;
	char buf[MAXBUFLEN];
	socklen_t addr_len;
	char s[INET6_ADDRSTRLEN];

	memset(&hints, 0, sizeof hints);
	hints.ai_family = AF_INET6; // establecer a AF_INET para usar IPv4
	hints.ai_socktype = SOCK_DGRAM;
	hints.ai_flags = AI_PASSIVE; // utilizar mi IP

	if ((rv = getaddrinfo(NULL, MYPORT, &hints, &servinfo)) != 0) {
		fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
		return 1;
	}

	// bucle a través de todos los resultados y se unen a la primera que podemos
	for(p = servinfo; p != NULL; p = p->ai_next) {
		if ((sockfd = socket(p->ai_family, p->ai_socktype,
				p->ai_protocol)) == -1) {
			perror("listener: socket");
			continue;
		}

		if (bind(sockfd, p->ai_addr, p->ai_addrlen) == -1) {
			close(sockfd);
			perror("listener: bind");
			continue;
		}

		break;
	}

	if (p == NULL) {
		fprintf(stderr, "listener: failed to bind socket\n");
		return 2;
	}

	freeaddrinfo(servinfo);

	printf("listener: waiting to recvfrom...\n");

	addr_len = sizeof their_addr;
	if ((numbytes = recvfrom(sockfd, buf, MAXBUFLEN-1 , 0,
		(struct sockaddr *)&their_addr, &addr_len)) == -1) {
		perror("recvfrom");
		exit(1);
	}

	printf("listener: got packet from %s\n",
		inet_ntop(their_addr.ss_family,
			get_in_addr((struct sockaddr *)&their_addr),
			s, sizeof s));
	printf("listener: packet is %d bytes long\n", numbytes);
	buf[numbytes] = '\0';
	printf("listener: packet contains \"%s\"\n", buf);

	close(sockfd);

	return 0;
}
```

Observa que en nuestra llamada a `getaddrinfo()` finalmente estamos usando `SOCK_DGRAM`.  Observe también que no hay necesidad de `listen()` o `accept()`. Esta es una de las ventajas de usar sockets de datagramas desconectados.

[i[Server-->datagram]>]

[i[Client-->datagram]<]

A continuación viene el [flx[fuente para `talker.c`|talker.c]]:

```{.c .numberLines}
/*
** talker.c -- a datagram "client" demo
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

#define SERVERPORT "4950"	// el puerto al que se conectarán los usuarios

int main(int argc, char *argv[])
{
	int sockfd;
	struct addrinfo hints, *servinfo, *p;
	int rv;
	int numbytes;

	if (argc != 3) {
		fprintf(stderr,"usage: talker hostname message\n");
		exit(1);
	}

	memset(&hints, 0, sizeof hints);
	hints.ai_family = AF_INET6; // establecer a AF_INET para usar IPv4
	hints.ai_socktype = SOCK_DGRAM;

	if ((rv = getaddrinfo(argv[1], SERVERPORT, &hints, &servinfo)) != 0) {
		fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(rv));
		return 1;
	}

	// bucle a través de todos los resultados y hacer un socket
	for(p = servinfo; p != NULL; p = p->ai_next) {
		if ((sockfd = socket(p->ai_family, p->ai_socktype,
				p->ai_protocol)) == -1) {
			perror("talker: socket");
			continue;
		}

		break;
	}

	if (p == NULL) {
		fprintf(stderr, "talker: failed to create socket\n");
		return 2;
	}

	if ((numbytes = sendto(sockfd, argv[2], strlen(argv[2]), 0,
			 p->ai_addr, p->ai_addrlen)) == -1) {
		perror("talker: sendto");
		exit(1);
	}

	freeaddrinfo(servinfo);

	printf("talker: sent %d bytes to %s\n", numbytes, argv[1]);
	close(sockfd);

	return 0;
}
```

Y eso es todo. Ejecuta `listener` en una máquina, luego ejecuta `talker` en otra. ¡Mira cómo se comunican! Diversión para toda la familia.

Esta vez ni siquiera tienes que ejecutar el servidor. Puedes ejecutar `talker` por sí mismo, y simplemente lanzará paquetes al éter donde desaparecerán si nadie está preparado con un `recvfrom()` en el otro lado. Recuerde: ¡no se garantiza que los datos enviados usando sockets de datagramas UDP lleguen!

[i[Client-->datagram]>]

Excepto por un pequeño detalle más que he mencionado muchas veces en el pasado: [i[`connect()` function-->on datagram sockets]] sockets de datagramas conectados. Necesito hablar de esto aquí, ya que estamos en la sección de datagramas del documento. Digamos que `talker` llama a `connect()` y especifica la dirección del `listener`. A partir de ese momento, `talker` sólo puede enviar y recibir de la dirección especificada por `connect()`. Por esta razón, no tienes que usar `sendto()` y `recvfrom()`; puedes simplemente usar `send()` y `recv()`.

[i[Client/Server]>]
