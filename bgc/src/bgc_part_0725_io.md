<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Archivo de Entrada/Salida (Input/Output)

[i[File I/O]<]
Ya hemos visto algunos ejemplos de E/S con `printf()` para hacer E/S en la consola.

Pero llevaremos estos conceptos un poco más lejos en este capítulo.

## El tipo de dato `FILE*`.

[i[`FILE*` type]<]
Cuando hacemos cualquier tipo de E/S en C, lo hacemos a través de un dato que se obtiene en
forma de un tipo `FILE*`. Este `FILE*` contiene toda la información necesaria, para comunicarse
con el subsistema de E/S acerca de qué fichero tienes abierto, en qué parte del fichero te
encuentras, etc.

La especificación se refiere a estos como _streams_, es decir, un flujo de datos de un
archivo o de cualquier fuente. Voy a utilizar «archivos (File)» y «flujos (streams)» indistintamente, pero
en realidad deberías pensar en un «archivo (File)» como un caso especial de un «flujo (Stream)». Hay otras
formas de introducir datos en un programa además de leerlos de un fichero.

Veremos en un momento, cómo pasar de tener un nombre de fichero, a obtener un `FILE*` abierto 
para él, pero primero quiero mencionar tres flujos que ya están abiertos para ti y listos para 
usar.

[i[`stdin` standard input]<]
[i[`stdout` standard output]<]
[i[`stderr` standard error]<]

|`FILE*` nombre|Descripción|
|-|-|
|`stdin`|Entrada estándar, generalmente por defecto es el teclado|
|`stdout`|Salida estándar, generalmente por defecto es la pantalla|
|`stderr`|Error estándar, generalmente por defecto es la pantalla|


Resulta que ya los hemos estado utilizando implícitamente. Por ejemplo, estas dos llamadas
son iguales:

``` {.c}
printf("Hello, world!\n");
fprintf(stdout, "Hello, world!\n");  // printf a un fichero
```

Pero hablaremos de ello más adelante.

También notarás que tanto `stdout` como `stderr` van a la pantalla. Aunque al principio
esto parece un descuido o una redundancia, en realidad no lo es. Los sistemas operativos típicos,
te permiten _redirigir_ la salida de cualquiera de ellos a archivos diferentes, y puede ser 
conveniente poder separar los mensajes de error, de la salida normal que no es de error.

Por ejemplo, en un shell POSIX (como sh, ksh, bash, zsh, etc.) en un sistema tipo Unix, 
podríamos ejecutar un programa y enviar sólo la salida no error (`stdout`) a un fichero, y 
toda la salida error (`stderr`) a otro fichero.

``` {.zsh}
./foo > output.txt 2> errors.txt   # Este comando es específico de Unix
```

Por este motivo, debe enviar los mensajes de error graves a `stderr` en lugar de a `stdout`.
[i[`stdin` standard input]>]
[i[`stdout` standard output]>]
[i[`stderr` standard error]>]

Más adelante se explica cómo hacerlo.
[i[`FILE*` type]<]

## Lectura de archivos de texto

[i[File I/O-->text files, reading]<]

Los flujos se clasifican en dos categorías diferentes: _texto_ y _binario_.

A los flujos de texto, se les permite hacer traducciones significativas de los datos,
sobre todo, traducciones de nuevas líneas a sus diferentes representaciones^[Solíamos tener
tres nuevas líneas diferentes en amplio efecto: Retorno de carro (CR, usado en los viejos
Macs), Salto de línea (LF, usado en sistemas Unix), y Retorno de carro/Salto de línea (CRLF,
usado en sistemas Windows). Afortunadamente, la introducción de OS X, al estar basado en Unix,
redujo este número a dos]. Los archivos de texto son lógicamente una secuencia de _líneas_
separadas por nuevas líneas. Para que sean portables, los datos de entrada deben terminar
siempre con una nueva línea.

Pero la regla general, es que si puedes editar el archivo en un editor de texto normal, es
un archivo de texto. En caso contrario, es binario. Hablaremos más sobre binario en un momento.

Así que manos a la obra: ¿cómo abrimos un archivo para leerlo y extraer datos de él?

Creemos un archivo llamado `hello.txt` que contenga esto:

``` {.default}
Hello, world!
```

Y vamos a escribir un programa para abrir el archivo, leer un carácter fuera de él, y luego
cerrar el archivo cuando hayamos terminado. ¡Ese es el plan!

[i[`fopen()` function]<]
[i[`fgetc()` function]<]
[i[`fclose()` function]<]
``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    FILE *fp;                      // Variable para representar el archivo abierto

    fp = fopen("hello.txt", "r");  // Abrir archivo para lectura

    int c = fgetc(fp);             // Leer un solo carácter
    printf("%c\n", c);             // Imprimir char en stdout

    fclose(fp);                    // Cierre el archivo cuando haya terminado
```

Mira como, cuando abrimos el fichero con `fopen()`, nos devolvió el `FILE*` para que
pudiéramos usarlo más tarde.

(Lo estoy omitiendo por brevedad, pero `fopen()` devolverá `NULL` si algo va mal, como
file-not-found (archivo no encontrado), ¡así que deberías comprobar el error!)

Fíjate también en la `«r»` que pasamos---esto significa «abrir un flujo de texto para
lectura». (Hay varias cadenas que podemos pasar a `fopen()` con significado adicional,
como escribir, o añadir, etc.).
[i[`fopen()` function]>]

Después, usamos la función `fgetc()` para obtener un carácter del flujo. Te estarás
preguntando, por qué he hecho que `c` sea un `int` en lugar de un `char`...
¡espera un momento!
[i[`fgetc()` function]>]

Por último, cerramos el flujo cuando hemos terminado con él. Todos los flujos se
cierran automáticamente cuando el programa se cierra, pero es de buena educación y
buena limpieza cerrar explícitamente cualquier archivo cuando se termina con ellos.
[i[`fclose()` function]>]

El [i[`FILE*` type]]`FILE*` mantiene un registro de nuestra posición en el fichero. Así, las
siguientes llamadas a `fgetc()` obtendrían el siguiente carácter del fichero, y luego el
siguiente, hasta el final.

Pero eso parece complicado. Veamos si podemos hacerlo más fácil.
[i[File I/O-->text files, reading]>]

## Fin de fichero: `EOF`

[i[`EOF` end of file]<]
Existe un carácter especial definido como macro: `EOF`. Esto es lo que `fgetc()` devolverá
cuando se haya alcanzado el final del fichero y haya intentado leer otro carácter.

Qué tal si comparto ese Fun Fact™(Hecho divertido / Hecho curioso), ahora. Resulta que `EOF`
es la razón por la que `fgetc()` y funciones similares devuelven un `int` en lugar
de un `char`. `EOF` no es un carácter propiamente dicho, y su valor probablemente cae
fuera del rango de `char`. Dado que `fgetc()` necesita ser capaz de devolver cualquier
byte **y** `EOF`, necesita ser un tipo más amplio que pueda contener más valores, así que
será `int`. Pero a menos que estés comparando el valor devuelto con `EOF`, puedes saber, en
el fondo, que es un `char`.

¡Muy bien! ¡Volvemos a la realidad! Podemos usar esto para leer todo el archivo en un bucle.
[i[`fopen()` function]<]
[i[`fgetc()` function]<]
[i[`fclose()` function]<]
``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    FILE *fp;
    int c;

    fp = fopen("hello.txt", "r");

    while ((c = fgetc(fp)) != EOF)
        printf("%c", c);

    fclose(fp);
}
```
[i[`fopen()` function]>]
[i[`fclose()` function]>]

(Si la línea 10 es demasiado rara, basta con descomponerla empezando por los paréntesis
más internos. Lo primero que hacemos es asignar el resultado de `fgetc()` a `c`, y
_luego_ comparamos _eso_ con `EOF`. Lo hemos metido todo en una sola línea. Esto puede
parecer difícil de leer, pero estúdialo---es C idiomático).
[i[`fgetc()` function]>]

Y ejecutando esto, vemos:

``` {.default}
Hello, world!
```
Pero aún así, estamos operando carácter por carácter, y muchos archivos de texto tienen
más sentido a nivel de línea. Vamos a cambiar a eso.
[i[`EOF` end of file]>]

### Leer línea a línea

[i[File I/O-->line by line]<]
Entonces, ¿cómo podemos obtener una línea entera de una vez?  [i[`fgets()`
function]<]  `fgets()` ¡al rescate! Como argumentos, toma un puntero a un buffer `char`
para almacenar bytes, un número máximo de bytes a leer, y un `FILE*` del que leer.
Devuelve `NULL` al final del archivo o en caso de error. `fgets()` es incluso lo
suficientemente amable como para terminar con NUL la cadena cuando ha
terminado^[Si el buffer no es lo suficientemente grande como para leer una línea entera, se
detendrá la lectura a mitad de línea, y la siguiente llamada a `fgets()` continuará 
leyendo el resto de la línea].
[i[`fgets()` function]>]

Vamos a hacer un bucle similar al anterior, excepto que vamos a tener un fichero multilínea
y lo vamos a leer línea a línea.

Aquí hay un archivo `quote.txt`:

``` {.default}
Un hombre sabio puede aprender más de
una pregunta tonta que un tonto
puede aprender de una respuesta sabia.
                  --Bruce Lee
```

Y aquí hay algo de código que lee ese archivo línea por línea e imprime un número de
línea antes de cada una:

[i[`fgets()` function]<]
``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    FILE *fp;
    char s[1024];  // Suficientemente grande para cualquier línea
                   // que encuentre este programa.

    int linecount = 0;

    fp = fopen("quote.txt", "r");

    while (fgets(s, sizeof s, fp) != NULL) 
        printf("%d: %s", ++linecount, s);

    fclose(fp);
}
```
[i[`fgets()` function]>]

Lo que da la salida:

``` {.default}
1: Un hombre sabio puede aprender más de
2: una pregunta tonta que un tonto
3: puede aprender de una respuesta sabia.
4:                   --Bruce Lee
```


[i[File I/O-->line by line]>]

## Entrada con formato

[i[File I/O-->formatted input]<]
¿Sabes cómo puedes obtener una salida formateada con `printf()` (y, por tanto, `fprintf()`
como veremos, más adelante)?
[i[`fscanf()` function]<]
Puede hacer lo mismo con `fscanf()`.

> Antes de empezar, deberías saber que usar funciones del estilo de `scanf()` 
> puede ser peligroso con entradas no confiables. Si no especifica anchos de campo
> con tu `%s`, podrías desbordar el buffer. Peor aún,
> una conversión numérica inválida puede resultar en un comportamiento indefinido. Lo
> más seguro es usar `%s` con un ancho de campo, luego usar funciones como
> [i[`strtol` function]] `strtol()` o  [i[`strtod` function]] `strtod()` para hacer las 
> conversiones.

Dispongamos de un fichero con una serie de registros de datos. En este caso, ballenas,
con nombre, longitud en metros y peso en toneladas. `ballenas.txt`:

``` {.default}
blue 29.9 173
right 20.7 135
gray 14.9 41
humpback 16.0 30
```

Sí, podríamos leerlos con [i[`fgets()` function]]`fgets()` y luego analizar la cadena con `sscanf()` (y en eso es más resistente contra archivos corruptos), pero en este caso, vamos a usar `fscanf()` y sacarlo directamente.

La función `fscanf()` se salta los espacios en blanco al leer, y devuelve `EOF` al final
del fichero o en caso de error.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    FILE *fp;
    char name[1024];  // Suficientemente grande para cualquier
                      //línea que encuentre este programa.
    float length;
    int mass;

    fp = fopen("whales.txt", "r");

    while (fscanf(fp, "%s %f %d", name, &length, &mass) != EOF)
        printf("%s whale, %d tonnes, %.1f meters\n", name, mass, length);

    fclose(fp);
}
```
[i[`fscanf()` function]>]

Lo que da el resultado:

``` {.default}
blue whale, 173 tonnes, 29.9 meters
right whale, 135 tonnes, 20.7 meters
gray whale, 41 tonnes, 14.9 meters
humpback whale, 30 tonnes, 16.0 meters
```
[i[File I/O-->formatted input]>]

## Escribir archivos de texto

[i[File I/O-->text files, writing]<]
[i[`fputc()` function]<]
[i[`fputs()` function]<]
[i[`fprintf()` function]<]
Del mismo modo que podemos usar `fgetc()`, `fgets()` y `fscanf()` para leer flujos de
texto, podemos usar `fputc()`, `fputs()` y `fprintf()` para escribir flujos de texto.

Para ello, tenemos que `fopen()` el archivo, en modo de escritura pasando `«w»` como
segundo argumento. Abrir un fichero existente en modo `«w»` truncará instantáneamente
ese fichero a 0 bytes para una sobreescritura completa.

Vamos a montar un programa sencillo que da salida a un archivo `output.txt` usando una
variedad de funciones de salida.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    FILE *fp;
    int x = 32;

    fp = fopen("output.txt", "w");

    fputc('B', fp);
    fputc('\n', fp);   // Salto de linea
    fprintf(fp, "x = %d\n", x);
    fputs("Hello, world!\n", fp);

    fclose(fp);
}
```
[i[`fputc()` function]>]
[i[`fputs()` function]>]
[i[`fprintf()` function]>]

Y esto produce un archivo, `output.txt`, con el siguiente contenido:

``` {.default}
B
x = 32
Hello, world!
```

Dato curioso: como `stdout` es un archivo, podrías sustituir la línea 8 por:

``` {.c}
fp = stdout;
```

y el programa habría dado salida a la consola en lugar de a un archivo. Pruébalo.

[i[File I/O-->text files, writing]>]

## E/S de archivos binarios

[i[File I/O-->binary files]<]
Hasta ahora sólo hemos hablado de archivos de texto. Pero existe esa otra bestia
que mencionamos al principio llamada archivos _binarios_, o flujos binarios.

Funcionan de forma muy similar a los archivos de texto, excepto que el subsistema de E/S
no realiza ninguna traducción de los datos como haría con un archivo de texto. Con los
archivos binarios, se obtiene un flujo de bytes sin procesar, y eso es todo.

La gran diferencia al abrir el fichero es que tienes que añadir una `«b»` al modo. Es decir,
para leer un fichero binario, ábralo en modo «rb». Para escribir un fichero, ábrelo en
modo «wb».

Como son flujos de bytes, y los flujos de bytes pueden contener caracteres NUL, y el
carácter NUL es el marcador de fin de cadena en C, es raro que la gente use las
funciones `fprintf()` y amigas para operar con ficheros binarios. [i[`fwrite()` function]<]
En cambio, las funciones más comunes son [i[función `fread()`]]`fread()` y `fwrite()`. Las
funciones leen y escriben un número especificado de bytes en el flujo.

Para la demostración, escribiremos un par de programas. Uno escribirá una secuencia de valores
de bytes en el disco de una sola vez. Y el segundo programa leerá un byte a la vez y los
imprimirá^[Normalmente el segundo programa leería todos los bytes a la vez, y _entonces_
los imprimiría en un bucle. Eso sería más eficiente. Pero vamos para el valor de
demostración, aquí].

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    FILE *fp;
    unsigned char bytes[6] = {5, 37, 0, 88, 255, 12};

    fp = fopen("output.bin", "wb");  // ¡modo wb para "escribir binario"!

    // En la llamada a fwrite, los argumentos son:
    //
    // * Puntero a los datos a escribir
    // * Tamaño de cada «pieza» de datos
    // * Recuento de cada «pieza» de datos
    // * ARCHIVO

    fwrite(bytes, sizeof(char), 6, fp);

    fclose(fp);
}
```
[i[`fwrite()` function]>]

Esos dos argumentos centrales de `fwrite()` son bastante extraños. Pero básicamente lo
que queremos decirle a la función es: «Tenemos elementos que son _así_ de grandes, y
queremos escribir _así_ muchos de ellos». Esto hace que sea conveniente si usted tiene
un registro de una longitud fija, y usted tiene un montón de ellos en una matriz. Sólo
tienes que decirle el tamaño de un registro y cuántos escribir. 

En el ejemplo anterior, le decimos que cada registro es del tamaño de un `char`, y
tenemos 6 de ellos.

Ejecutando el programa obtenemos un fichero `output.bin`, pero al abrirlo en un editor
de texto no aparece nada amigable. Son datos binarios, no texto. Y datos binarios
aleatorios que me acabo de inventar.

Si lo paso por un programa [flw[hex dump|Hex_dump]], podemos ver la salida como bytes:

``` {.default}
05 25 00 58 ff 0c
```

Y esos valores en hexadecimal coinciden con los valores (en decimal) que escribimos.

Pero ahora vamos a intentar leerlos de nuevo con un programa diferente. Este abrirá el
fichero para lectura binaria (modo `«rb»`) y leerá los bytes de uno en uno en un bucle.

[i[función `fread()`]<] La función `fread()` devuelve el número de bytes leídos, o `0` en
caso de EOF. Así que podemos hacer un bucle hasta que veamos eso, imprimiendo números
a medida que avanzamos.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    FILE *fp;
    unsigned char c;

    fp = fopen("output.bin", "rb"); // ¡rb para «leer binario»!

    while (fread(&c, sizeof(char), 1, fp) > 0)
        printf("%d\n", c);

    fclose(fp);
}
```
[i[`fread()` function]>]

Y, al ejecutarlo, ¡vemos nuestros números originales!

``` {.default}
5
37
0
88
255
12
```

Woo hoo!
[i[File I/O-->binary files]>]

### `struct` y advertencias sobre números

[i[File I/O-->with `struct`s]<]
Como vimos en la sección `struct`s, el compilador es libre de añadir relleno
a una `struct` como considere oportuno. Y diferentes compiladores pueden hacer esto
de manera diferente. Y el mismo compilador en diferentes arquitecturas podría hacerlo
de forma diferente. Y el mismo compilador en las mismas arquitecturas podría hacerlo
de manera diferente.

A lo que quiero llegar es a esto: no es portable simplemente `fwrite()` una
`struct` entera a un fichero cuando no sabes dónde acabará el relleno.
[i[File I/O-->with `struct`s]>]

¿Cómo solucionarlo? Espera un momento... veremos algunas formas de hacerlo después
de analizar otro problema relacionado.

[i[File I/O-->with numeric values]<]
Números.

Resulta que no todas las arquitecturas representan los números en memoria de la misma manera.

Veamos una simple `fwrite()` de un número de 2 bytes. Lo escribiremos en hexadecimal
para que cada byte sea claro. El byte más significativo tendrá el valor `0x12` y el
menos significativo tendrá el valor `0x34`.

``` {.c}
unsigned short v = 0x1234;  // Dos bytes, 0x12 y 0x34

fwrite(&v, sizeof v, 1, fp);
```

¿Qué termina en el flujo?

Bueno, parece que debería ser `0x12` seguido de `0x34`, ¿no?

Pero si ejecuto esto en mi máquina y volcado hexadecimal el resultado, me sale:

``` {.default}
34 12
```

¡Están al revés! ¿Por qué?

Esto tiene algo que ver con lo que se llama el
[i[Endianess]][flw[_endianess_|Endianess]] de la arquitectura. Algunas escriben primero
los bytes más significativos y otras los menos significativos.

Esto significa que si escribes un número multibyte directamente desde la memoria, no
puedes hacerlo de forma portable^[Y esta es la razón por la que usé bytes individuales
en mis ejemplos `fwrite()` y `fread()`, arriba, astutamente].

Un problema similar existe con el punto flotante. La mayoría de los sistemas usan
el mismo formato para sus números en coma flotante, pero algunos no. No hay garantías.
[i[File I/O-->with `struct`s]<]

Entonces... ¿cómo podemos solucionar todos estos problemas con números y `struct`s para
que nuestros datos se escriban de forma portable?

El resumen es [i[Data serialization]] _serializar_ los datos, que es
un término general que significa tomar todos los datos y escribirlos en un
formato que controlas, que es bien conocido, y programable, para funcionar
de la misma manera en todas las plataformas.

Como puede imaginar, se trata de un problema resuelto. Hay un montón de librerías
de serialización que puedes aprovechar, como [flw[_búferes de protocolo_|Protocol_buffers]]
de Google, ahí fuera y listas para usar. Se encargarán de todos los detalles por ti, e
incluso permitirán que los datos de tus programas en C interoperen con otros lenguajes
que soporten los mismos métodos de serialización.

Hágase un favor a sí mismo y a todo el mundo. Serializa tus datos binarios cuando los
escribas en un flujo. Esto mantendrá las cosas bien y portátiles, incluso si
transfiere archivos de datos de una arquitectura a otra.
[i[File I/O-->with `struct`s]>]
[i[File I/O-->with numeric values]>]
[i[File I/O]>]
