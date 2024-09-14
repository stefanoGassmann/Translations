<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Funciones de fecha y hora

> "El tiempo es una ilusión. La hora de comer doblemente". \
> ---Ford Prefect, La guía del autoestopista galáctico

[i[Date and time]<]

Esto no es demasiado complejo, pero puede ser un poco intimidante al principio, tanto con los diferentes tipos disponibles y la forma en que podemos convertir entre ellos.

Mezcla GMT (UTC) y la hora local y tenemos toda la _Usual Fun_™ que uno consigue con horas y fechas.

Y, por supuesto, nunca olvides la regla de oro de las fechas y horas: _Nunca intentes escribir tu propia funcionalidad de fecha y hora. Sólo usa lo que te da la librería._

El tiempo es demasiado complejo para que los simples programadores mortales lo manejen correctamente. En serio, todos debemos un punto a todos los que trabajaron en cualquier librería de fecha y hora, así que ponlo en tu presupuesto.

## Terminología rápida e información

Sólo un par de términos rápidos en caso de que no los tengas apuntados.
* [i[Universal Coordinated Time]] **UTC**: El Tiempo Universal Coordinado (Universal Time Coordinated) es una hora absoluta acordada universalmente^[En la Tierra, al menos. A saber qué locos sistemas usan _allá_...]. Todo el mundo en el planeta piensa que es la misma hora ahora mismo en UTC... aunque tengan diferentes horas locales.

* [i[Greenwich Mean time]] **GMT**: Hora del meridiano de Greenwich, efectivamente la misma que la UTC^[¡Vale, no me mates! GMT es técnicamente una zona horaria, mientras que UTC es un sistema horario mundial. Además, algunos países pueden ajustar GMT para el horario de verano, mientras que UTC nunca se ajusta para el horario de verano]. Probablemente quieras decir UTC, o "hora universal". Si te refieres específicamente a la zona horaria GMT, di GMT. Confusamente, muchas de las funciones UTC de C son anteriores a UTC y todavía se refieren a la hora media de Greenwich. Cuando vea eso, sepa que C quiere decir UTC.

* [i[Local time]] **Hora local**: qué hora es en el lugar donde se encuentra el ordenador que ejecuta el programa. Se describe como un desfase con respecto a UTC. Aunque hay muchas zonas horarias en el mundo, la mayoría de los ordenadores trabajan en hora local o UTC.

[i[Universal Coordinated Time]<]

Como regla general, si estás describiendo un evento que ocurre una sola vez, como una entrada de registro, o el lanzamiento de un cohete, o cuando los punteros finalmente hicieron clic para ti, utiliza UTC.

[i[Local time]<]

En cambio, si se trata de algo que ocurre a la misma hora _en todas las zonas horarias_, como Nochevieja o la hora de cenar, utiliza la hora local.

Dado que muchos lenguajes sólo son buenos en la conversión entre UTC y hora local, puedes causarte mucho dolor si eliges almacenar tus fechas en la forma incorrecta. (Pregúntame cómo lo sé).

[i[Local time]>]
[i[Universal Coordinated Time]>]


## Tipos de fecha

Hay dos^[Hay que admitir que hay más de dos.] tipos principales en C cuando se trata de fechas: `time_t` y `struct tm`.

La especificación no dice mucho sobre ellos:

* [i[`time_t` type]] `time_t`: un tipo real capaz de contener un tiempo. Según la especificación, puede ser un tipo flotante o un tipo entero. En POSIX (Unix-likes), es un entero. Esto contiene _tiempo de calendario_. Que se puede considerar como la hora UTC.

* [i[`struct tm` type]] `struct tm`: contiene los componentes de una hora de calendario. Se trata de una _hora desglosada_, es decir, los componentes de la hora, como hora, minuto, segundo, día, mes, año, etc.

[i[`time_t` type]<]

En muchos sistemas, `time_t` representa el número de segundos transcurridos desde [flw[_Época(Epoch)_|Unix_time]].. Epoch es en cierto modo el comienzo del tiempo desde la perspectiva del ordenador, que es comúnmente el 1 de enero de 1970 UTC.  `time_t` puede ser negativo para representar tiempos anteriores a Epoch. Windows se comporta de la misma manera que Unix por lo que puedo decir.

[i[`time_t` type]>]
[i[`struct tm` type]<]

¿Y qué hay en una `struct tm`? Los siguientes campos:

``` {.c}
struct tm {
    int tm_sec; // segundos después del minuto -- [0, 60]
    int tm_min; // minutos después de la hora -- [0, 59]
    int tm_hour; // horas desde medianoche -- [0, 23]
    int tm_mday; // día del mes -- [1, 31]
    int tm_mon; // meses desde enero -- [0, 11]
    int tm_year; // años desde 1900
    int tm_wday; // días desde el domingo -- [0, 6]
    int tm_yday; // días desde el 1 de enero -- [0, 365]
    int tm_isdst; // indicador del horario de verano
};
```

Tenga en cuenta que todo tiene base cero excepto el día del mes.

Es importante saber que puedes poner los valores que quieras en estos tipos. Hay funciones que ayudan a obtener la hora _ahora_, pero los tipos contienen _una_ hora, no _la_ hora.

[i[`struct tm` type]>]

Así que la pregunta es: "¿Cómo se inicializan los datos de estos tipos, y cómo se convierten entre ellos?"

## Inicialización y conversión entre tipos

[i[`time()` function]<]

En primer lugar, puedes obtener la hora actual y almacenarla en un `time_t` con la función `time()`.

``` {.c}
time_t now;  // Variable para mantener la hora actual

now = time(NULL);  // Puedes conseguirlo así...

time(&now);        // ...o esto. Igual que la línea anterior.
```

Estupendo. Ahora tienes una variable que te da la hora.

[i[`time()` function]>]
[i[`ctime()` function]<]

Curiosamente, sólo hay una forma portable de imprimir lo que hay en un `time_t`, y es la función `ctime()`, raramente utilizada, que imprime el valor en tiempo local:

``` {.c}
now = time(NULL);
printf("%s", ctime(&now));
```

Devuelve una cadena con una forma muy específica que incluye una nueva línea al final:

``` {.default}
Sun Feb 28 18:47:25 2021
```

[i[`ctime()` function]>]

Así que eso es un poco inflexible. Si quieres más control, deberías convertir ese `time_t` en un `struct tm`.

### Convertir `time_t` en `struct tm`

[i[`time_t` type-->conversion to `struct tm`]<]

Hay dos formas increíbles de hacer esta conversión:

[i[`localtime()` function]<]

* `localtime()`: esta función convierte un `time_t` en un `struct tm` en tiempo local.

[i[`gmtime()` function]<]

* `gmtime()`: esta función convierte un `time_t` en un `struct tm` en UTC. (¿Ves el antiguo GMT en el nombre de la función?)

[i[`asctime()` function]<]

Veamos qué hora es ahora imprimiendo una `struct tm` con la función `asctime()`:

``` {.c}
printf("Local: %s", asctime(localtime(&now)));
printf("  UTC: %s", asctime(gmtime(&now)));
```

[i[`asctime()` function]>]
[i[`localtime()` function]>]
[i[`gmtime()` function]>]

Salida (estoy en la zona horaria estándar del Pacífico):

``` {.default}
Local: Sun Feb 28 20:15:27 2021
  UTC: Mon Mar  1 04:15:27 2021
```

Una vez que tienes tu `time_t` en una `struct tm`, se abren todo tipo de puertas. Puede imprimir la hora de varias maneras, averiguar qué día de la semana es una fecha, y así sucesivamente. O convertirlo de nuevo en un `time_t`.

Pronto hablaremos de ello.

[i[`time_t` type-->conversion to `struct tm`]>]

### Convertir `struct tm` a `time_t`

[i[`struct tm` type-->conversion to `time_t`]<]
[i[`mktime()` function]<]

Si quieres ir por otro camino, puedes usar `mktime()` para obtener esa información.

`mktime()` establece los valores de `tm_wday` y `tm_yday` por ti, así que no te molestes en rellenarlos porque serán sobrescritos.

Además, puedes poner `tm_isdst` a `-1` para que lo determine por ti. O puede establecerlo manualmente en verdadero o falso.

``` {.c}
// No tenga la tentación de poner ceros a la izquierda en estos números
// (a menos que usted quiera que estén en octal)

struct tm algún_tiempo = {
    .tm_year=82, // años desde 1900
    .tm_mon=3, // meses desde enero -- [0, 11]
    .tm_mday=12, // día del mes -- [1, 31]
    .tm_hour=12, // horas desde medianoche -- [0, 23]
    .tm_min=0, // minutos después de la hora -- [0, 59]
    .tm_sec=4, // segundos después del minuto -- [0, 60]
    .tm_isdst=-1, // indicador del horario de verano
};

time_t some_time_epoch;

some_time_epoch = mktime(&some_time);

printf("%s", ctime(&some_time_epoch));
printf("Is DST: %d\n", some_time.tm_isdst);
```

Salida:

``` {.default}
Mon Apr 12 12:00:04 1982
Is DST: 0
```

Cuando cargas manualmente una `struct tm` como esa, debería estar en hora local.  `mktime()` convertirá esa hora local en una hora de calendario `time_t`.

[i[`mktime()` function]>]

Extrañamente, sin embargo, el estándar no nos da una manera de cargar una `struct tm` con una hora UTC y convertirla en un `time_t`. Si quieres hacer eso con Unix-likes, prueba la no-estándar [i[`timegm()` Unix function]]. `timegm()`. En Windows,[i[`_mkgmtime()` Windows function]] `_mkgmtime()`.

[i[`struct tm` type-->conversion to `time_t`]>]

## Salida de fecha formateada

Ya hemos visto un par de formas de imprimir fechas formateadas en la pantalla. Con `time_t` podemos usar `ctime()`, y con `struct tm` podemos usar `asctime()`.


``` {.c}
time_t now = time(NULL);
struct tm *local = localtime(&now);
struct tm *utc = gmtime(&now);

printf("Hora local: %s", ctime(&now)); // Hora local con time_t
printf("Hora local: %s", asctime(local)); // Hora local con struct tm
printf("UTC : %s", asctime(utc)); // UTC con struct tm
```

Pero, ¿y si te dijera, querido lector, que hay una forma de tener mucho más control sobre la impresión de la fecha?

[i[`strftime()` function]<]

Claro, podríamos pescar campos individuales de la `struct tm`, pero hay una gran función llamada `strftime()` que hará mucho del trabajo duro por ti. Es como `printf()`, ¡pero para fechas!

Veamos algunos ejemplos. En cada uno de ellos, pasamos un buffer de destino, un número máximo de caracteres a escribir, y luego una cadena de formato (al estilo de---pero no igual que---`printf()`) que le dice a `strftime()` qué componentes de una `struct tm` imprimir y cómo.

Puede añadir otros caracteres constantes para incluir en la salida de la cadena de formato, así, al igual que con `printf()`.

Obtenemos un `struct tm` en este caso de `localtime()`, pero cualquier fuente funciona bien.

``` {.c .numberLines}
#include <stdio.h>
#include <time.h>

int main(void)
{
    char s[128];
    time_t now = time(NULL);

    // %c: print date as per current locale
    strftime(s, sizeof s, "%c", localtime(&now));
    puts(s);   // Sun Feb 28 22:29:00 2021

    // %A: full weekday name
    // %B: full month name
    // %d: day of the month
    strftime(s, sizeof s, "%A, %B %d", localtime(&now));
    puts(s);   // Sunday, February 28

    // %I: hour (12 hour clock)
    // %M: minute
    // %S: second
    // %p: AM or PM
    strftime(s, sizeof s, "It's %I:%M:%S %p", localtime(&now));
    puts(s);   // Es 10:29:00 PM

    // %F: ISO 8601 yyyy-mm-dd
    // %T: ISO 8601 hh:mm:ss
    // %z: ISO 8601 time zone offset
    strftime(s, sizeof s, "ISO 8601: %FT%T%z", localtime(&now));
    puts(s);   // ISO 8601: 2021-02-28T22:29:00-0800
}
```

Hay _toneladas_ de especificadores de formato de impresión de fecha para `strftime()`, así que asegúrese de comprobarlos en la fl[ página de referencia `strftime()` |https://beej.us/guide/bgclr/html/split/time.html#man-strftime]].

[i[`strftime()` function]>]

## Más Resolución con `timespec_get()`
[i[`timespec_get()` function]<]

Puede obtener el número de segundos y nanosegundos desde Epoch con `timespec_get()`.

Quizás.

Es posible que las implementaciones no tengan una resolución de nanosegundos (que es una milmillonésima parte de un segundo), así que quién sabe cuántos lugares significativos obtendrás, pero inténtalo y verás.

[i[`struct timespec` type]<]

La función `timespec_get()` recibe dos argumentos. Uno es un puntero a una `struct timespec` que contiene la información horaria. Y el otro es la `base`, que la especificación te permite establecer a `TIME_UTC` indicando que estás interesado en segundos desde Epoch. (Otras implementaciones pueden ofrecer más opciones para la "base").

Y la propia estructura tiene dos campos:

``` {.c}
struct timespec {
    time_t tv_sec;   // Segundos
    long   tv_nsec;  // Nanosegundos (milmillonésimas de segundo)
};
```

He aquí un ejemplo en el que obtenemos la hora y la imprimimos como valor entero y también como valor flotante:

``` {.c}
struct timespec ts;

timespec_get(&ts, TIME_UTC);

printf("%ld s, %ld ns\n", ts.tv_sec, ts.tv_nsec);

double float_time = ts.tv_sec + ts.tv_nsec/1000000000.0;
printf("%f seconds since epoch\n", float_time);
```

Ejemplo de salida:

``` {.default}
1614581530 s, 806325800 ns
1614581530.806326 seconds since epoch
```

`struct timespec` también hace su aparición en un número de funciones de threading que necesitan ser capaces de especificar el tiempo con esa resolución.

[i[`struct timespec` type]>]
[i[`timespec_get()` function]>]

## Diferencias entre tiempos

[i[Date and time-->differences]<]

Una nota rápida sobre cómo obtener la diferencia entre dos `time_t`s: ya que la especificación no dicta cómo ese tipo representa un tiempo, puede que no seas capaz de simplemente restar dos `time_t`s y obtener algo sensato^[Lo harás en POSIX, donde `time_t` es definitivamente un entero. Desafortunadamente el mundo entero no es POSIX, así que ahí estamos].

[i[`difftime()` function]<]

Por suerte, puede utilizar `difftime()` para calcular la diferencia en segundos entre dos fechas.

En el siguiente ejemplo, tenemos dos eventos que ocurren con cierta diferencia de tiempo, y usamos `difftime()` para calcular la diferencia.

``` {.c .numberLines}
#include <stdio.h>
#include <time.h>

int main(void)
{
    struct tm time_a = {
        .tm_year=82, // años desde 1900
        .tm_mon=3, // meses desde enero -- [0, 11]
        .tm_mday=12, // día del mes -- [1, 31]
        .tm_hour=4, // horas desde medianoche -- [0, 23]
        .tm_min=00, // minutos después de la hora -- [0, 59]
        .tm_sec=04, // segundos después del minuto -- [0, 60]
        .tm_isdst=-1, // indicador del horario de verano
    };

    struct tm time_b = {
        .tm_year=120, // años desde 1900
        .tm_mon=10, // meses desde enero -- [0, 11]
        .tm_mday=15, // día del mes -- [1, 31]
        .tm_hour=16, // horas desde medianoche -- [0, 23]
        .tm_min=27, // minutos después de la hora -- [0, 59]
        .tm_sec=00, // segundos después del minuto -- [0, 60]
        .tm_isdst=-1, // indicador del horario de verano
    };

    time_t cal_a = mktime(&time_a);
    time_t cal_b = mktime(&time_b);

    double diff = difftime(cal_b, cal_a);

    double years = diff / 60 / 60 / 24 / 365.2425;  // bastante cerca

    printf("%f seconds (%f years) between events\n", diff, years);
}
```

Output:

``` {.default}
1217996816.000000 seconds (38.596783 years) between events
```

Y ya está. Recuerda usar `difftime()` para tomar la diferencia de tiempo. Aunque puedes simplemente restar en un sistema POSIX, es mejor ser portable.

[i[`difftime()` function]>]
[i[Date and time-->differences]>]
[i[Date and time]>]
