# Salto de IPv4 a IPv6

[i[IPv6]]

Pero sólo quiero saber qué cambiar en mi código para que funcione con IPv6. ¡Dímelo ahora!

¡Vale! ¡Ok!

Casi todo lo que hay aquí es algo que ya he repasado, más arriba, pero es la versión corta para los impacientes. (Por supuesto, hay más que esto, pero esto es lo que se aplica a la guía).

1. En primer lugar, intenta usar  [i[`getaddrinfo()` function]] [`getaddrinfo()`](#structs) para obtener toda la información de `struct sockaddr`, en lugar de empaquetar las estructuras a mano. Esto mantendrá tu IP agnóstica a la versión, y eliminará muchos de los pasos posteriores.

2. En cualquier lugar donde encuentres que estás codificando algo relacionado con la versión IP, intenta envolverlo en una función de ayuda.

3. Cambia `AF_INET` por `AF_INET6`.

4. Cambia `PF_INET` por `PF_INET6`.

5. Cambie las asignaciones `INADDR_ANY` por `in6addr_any`, que son ligeramente diferentes:

   ```{.c}
   struct sockaddr_in sa;
   struct sockaddr_in6 sa6;
   
   sa.sin_addr.s_addr = INADDR_ANY;  // utilizar mi dirección IPv4
   sa6.sin6_addr = in6addr_any; // utilizar mi dirección IPv6
   ```

   Además, el valor `IN6ADDR_ANY_INIT` se puede utilizar como inicializador cuando
   se declara la `struct in6_addr`, de esta forma:

   ```{.c}
   struct in6_addr ia6 = IN6ADDR_ANY_INIT;
   ```

6. En lugar de `struct sockaddr_in` utilice `struct sockaddr_in6`, asegurándose de añadir «6» a los campos según corresponda (véase [`struct`s](#structs), más arriba). No existe el campo `sin6_zero`.

7. En lugar de `struct in_addr` utilice `struct in6_addr`, asegurándose de añadir «6» a los campos según corresponda (véase [`struct`s](#structs), más arriba).

8. En lugar de `inet_aton()` o `inet_addr()`, utilice `inet_pton()`.

9. En lugar de `inet_ntoa()`, use `inet_ntop()`.

10. En lugar de `gethostbyname()`, utilice la superior `getaddrinfo()`.

11. En lugar de `gethostbyaddr()`, utilice la función superior [i[`getnameinfo()` function]] `getnameinfo()` (aunque `gethostbyaddr()` todavía puede funcionar con IPv6).

12. La función `INADDR_BROADCAST` ya no funciona. Usa multicast IPv6 en su lugar.

_Et voila_!
