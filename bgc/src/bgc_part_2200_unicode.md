<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Unicode, caracteres anchos y todo eso

[i[Unicode]<]

Antes de empezar, ten en cuenta que esta es un área activa del desarrollo del lenguaje C, ya que
trabaja para superar algunos, erm, _dolores de crecimiento_. Cuando salga C2x, es probable
que haya actualizaciones.

La mayoría de la gente está básicamente interesada en la engañosamente simple pregunta: "¿Cómo
uso tal y tal juego de caracteres en C?". Ya llegaremos a eso. Pero como veremos, puede que ya
funcione en tu sistema. O puede que tengas que recurrir a una biblioteca de terceros.

Vamos a hablar de muchas cosas en este capítulo---algunas son agnósticas a la plataforma, y otras
son específicas de C.

Hagamos primero un resumen de lo que vamos a ver:

* Antecedentes de Unicode
* Antecedentes de codificación de caracteres
* Conjuntos de caracteres de origen y ejecución
* Uso de Unicode y UTF-8
* Usando otros tipos de caracteres como `wchar_t`, `char16_t`, y `char32_t`

¡Vamos a sumergirnos!

## ¿Qué es Unicode?

Antiguamente, en EE.UU. y en gran parte del mundo se solía utilizar una codificación de 7 u 8
bits para los caracteres de la memoria. Esto significaba que podíamos tener 128 o 256 caracteres
(incluidos los caracteres no imprimibles) en total. Eso estaba bien para un mundo centrado
en EE.UU, pero resulta que en realidad hay otros alfabetos ahí fuera... ¿quién lo iba a decir?
El chino tiene más de 50.000 caracteres, y eso no cabe en un byte.

Así que la gente inventó todo tipo de formas alternativas para representar sus propios
conjuntos de caracteres personalizados. Y eso estaba bien, pero se convirtió en una pesadilla
de compatibilidad.

Para evitarlo, se inventó Unicode. Un conjunto de caracteres para gobernarlos a todos.
Se extiende hasta el infinito (efectivamente) para que nunca nos quedemos sin espacio
para nuevos caracteres. Incluye caracteres chinos, latinos, griegos, cuneiformes, símbolos
de ajedrez, emojis... ¡casi todo! Y cada vez se añaden más.

## Puntos de código

[i[Unicode-->code points]<]

Quiero hablar de dos conceptos. Es confuso porque ambos son números... números diferentes
para la misma cosa. Pero tengan paciencia.

Definamos vagamente _punto de código_ como un valor numérico que representa un carácter.
(Los puntos de código también pueden representar caracteres de control no imprimibles, pero
suponga que me refiero a algo como la letra "B" o el carácter "π").

Cada punto de código representa un carácter único. Y cada carácter tiene asociado
un punto de código numérico único.

Por ejemplo, en Unicode, el valor numérico 66 representa "B", y 960 representa "π". Otros
mapeados de caracteres que no son Unicode utilizan valores diferentes, pero
olvidémonos de ellos y concentrémonos en Unicode, ¡el futuro!

Así que eso es una cosa: hay un número que representa a cada carácter. En Unicode, estos
números van de 0 a más de 1 millón.

[i[Unicode-->code points]>]

¿Entendido?

Porque estamos a punto de voltear la mesa un poco.

## Codificación

[i[Unicode-->encoding]<]

Si recuerdas, un byte de 8 bits puede contener valores de 0 a 255, ambos inclusive. Eso está
muy bien para "B" que es 66---que cabe en un byte. Pero "π" es 960, ¡y eso no cabe en un byte!
Necesitamos otro byte. ¿Cómo almacenamos todo eso en la memoria? ¿O qué pasa con los números más
grandes, como 195.024? Necesitaremos varios bytes.

La gran pregunta: ¿cómo se representan estos números en la memoria? Esto es lo que llamamos
la _codificación_ de los caracteres.

Así que tenemos dos cosas: una es el punto de código, que nos indica efectivamente el número
de serie de un carácter concreto. Y tenemos la codificación, que nos dice cómo
vamos a representar ese número en la memoria.

Hay muchas codificaciones. ^[Por ejemplo, podríamos almacenar el punto de código en un entero
big-endian de 32 bits. ¡Sencillo! Acabamos de inventar una codificación. En realidad no; eso
es lo que es la codificación UTF-32BE. Oh, bueno... ¡volvamos a la rutina!]. Pero vamos a ver
algunas codificaciones realmente comunes que se usan con Unicode.


[i[Unicode-->UTF-8]<]
[i[Unicode-->UTF-16]<]
[i[Unicode-->UTF-32]<]

|Codificación|Descripción
|:-----------------:|:--------------------------------------------------------------|
|UTF-8|Codificación orientada a bytes que utiliza un número variable de bytes por carácter. Esta es la que se debe utilizar.|
|UTF-16|Una codificación de 16 bits por carácter[^091d].|
|UTF-32|Una codificación de 32 bits por carácter.|

[^091d]: Ish. Técnicamente, es de anchura variable---hay una manera de representar
puntos de código superiores a $2^{16}$ juntando dos caracteres UTF 16.

Con UTF-16 y UTF-32, el orden de bytes importa, por lo que puede ver UTF-16BE para big-endian
y UTF-16LE para little-endian. Lo mismo ocurre con UTF-32. Técnicamente, si no se especifica,
se debe asumir big-endian. Pero como Windows usa UTF-16 extensivamente y es little-endian,
a veces se asume^[Hay un carácter especial llamado _Byte Order Mark_ (BOM), punto de código
0xFEFF, que puede preceder opcionalmente al flujo de datos e indicar el endianess. Sin
embargo, no es obligatorio].

Veamos algunos ejemplos. Voy a escribir los valores en hexadecimal porque son exactamente
dos dígitos por byte de 8 bits, y así es más fácil ver cómo se ordenan las cosas
en la memoria.

|Caracter|Punto de Código|UTF-16BE|UTF-32BE|UTF-16LE|UTF-32LE|UTF-8|
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
|`A`|41|0041|00000041|4100|41000000|41|
|`B`|42|0042|00000042|4200|42000000|42|
|`~`|7E|007E|0000007E|7E00|7E000000|7E|
|`π`|3C0|03C0|000003C0|C003|C0030000|CF80|
|`€`|20AC|20AC|000020AC|AC20|AC200000|E282AC|

[i[Unicode-->endianess]<]

Busca ahí los patrones. Tenga en cuenta que UTF-16BE y UTF-32BE son simplemente el punto
de código representado directamente como valores de 16 y 32 bits^[De nuevo, esto sólo
es cierto en UTF-16 para caracteres que caben en dos bytes].

[i[Unicode-->UTF-16]>]
[i[Unicode-->UTF-32]>]

Little-endian es lo mismo, excepto que los bytes están en orden little-endian.

[i[Unicode-->endianess]>]

Luego tenemos UTF-8 al final. En primer lugar, te darás cuenta de que los puntos de código
de un solo byte se representan como un solo byte. Eso está bien. También puedes observar
que los distintos puntos de código ocupan un número diferente de bytes. Se trata de una
codificación de ancho variable.

Así que tan pronto como superamos un cierto valor, UTF-8 empieza a utilizar bytes adicionales
para almacenar los valores. Y tampoco parecen estar correlacionados con el valor del punto
de código.

[flw[Los detalles de la codificación UTF-8|UTF-8]] quedan fuera del alcance de esta guía,
pero basta con saber que tiene un número variable de bytes por punto de código, y que esos
valores de bytes no coinciden con el punto de código _excepto los 128 primeros puntos de
código_. Si realmente quieres aprender más, [fl[Computerphile tiene un gran video de UTF-8
con Tom Scott|https://www.youtube.com/watchv=MijmeoH9LT4]].

Esto último es lo bueno de Unicode y UTF-8 desde una perspectiva norteamericana: ¡es
compatible con la codificación ASCII de 7 bits! Así que si estás acostumbrado a ASCII, UTF-8
es lo mismo. Todos los documentos codificados en ASCII también están codificados en UTF-8.
(Pero no al revés, obviamente).

Probablemente sea este último punto más que ningún otro el que está impulsando a UTF-8
a conquistar el mundo.

[i[Unicode-->UTF-8]>]
[i[Unicode-->encoding]>]

## Juegos de caracteres de origen y ejecución {#src-exec-charset}

[i[Character sets]<]

Al programar en C, hay (al menos) tres conjuntos de caracteres en juego:

* El que su código existe en el disco como.
* [i[Character sets-->source]]El que el compilador traduce justo cuando comienza la compilación (el _source character set_). Este puede ser el mismo que el del disco, o puede que no.
* [i[Character sets-->execution]]Aquel al que el compilador traduce el juego de caracteres fuente para su ejecución (el _juego de caracteres de ejecución_). Este puede ser el mismo que el juego de caracteres fuente, o puede que no.

Su compilador probablemente disponga de opciones para seleccionar estos conjuntos de caracteres en el momento de la compilación.
[i[Character sets-->basic]<]

El juego de caracteres básico tanto para el origen como para la ejecución contendrá los siguientes caracteres:

``` {.default}
A B C D E F G H I J K L M
N O P Q R S T U V W X Y Z
a b c d e f g h i j k l m
n o p q r s t u v w x y z
0 1 2 3 4 5 6 7 8 9
! " # % & ' ( ) * + , - . / :
; < = > ? [ \ ] ^ _ { | } ~
space tab vertical-tab
form-feed end-of-line
```

Esos son los caracteres que puedes utilizar en tu código fuente y seguir siendo 100% portable.

El conjunto de caracteres de ejecución tendrá además caracteres para alerta (campana/flash), retroceso, retorno de carro y nueva línea.

Pero la mayoría de la gente no llega a ese extremo y utiliza libremente sus conjuntos de caracteres extendidos en el código fuente y el ejecutable, especialmente ahora que Unicode y UTF-8 son cada vez más comunes. Quiero decir, ¡el juego de caracteres básico ni siquiera permite `@`, `$`, o `` ``!

En particular, es un engorro (aunque posible con secuencias de escape) introducir caracteres Unicode utilizando sólo el juego de caracteres básico.

[i[Character sets-->basic]>]
[i[Character sets]>]

## Unicode en C {#unicode-in-c}

Antes de entrar en la codificación en C, hablemos de Unicode desde el punto de vista de los puntos de código. Hay una manera en C para especificar caracteres Unicode y estos serán traducidos por el compilador en el conjunto de caracteres de ejecución^[Presumiblemente el compilador hace el mejor esfuerzo para traducir el punto de código a cualquiera que sea la codificación de salida, pero no puedo encontrar ninguna garantía en la especificación].

Entonces, ¿cómo lo hacemos?

¿Qué tal el símbolo del euro, punto de código 0x20AC? (Lo he escrito en hexadecimal porque ambas formas de representarlo en C requieren hexadecimal). ¿Cómo podemos ponerlo en nuestro código C?

[i[`\u` Unicode escape]<]
Utiliza el escape `\u` para ponerlo en una cadena, por ejemplo `"\u20AC"` (las mayúsculas y minúsculas del hexadecimal no importan). Debe poner **exactamente cuatro** dígitos hexadecimales después de la "u", rellenando con ceros a la izquierda si es necesario.

He aquí un ejemplo:

``` {.c}
char *s = "\u20AC1.23";

printf("%s\n", s);  // €1.23
```

[i[`\U` Unicode escape]<]

Así pues, `\u` funciona para los puntos de código Unicode de 16 bits, pero ¿qué pasa con los que tienen más de 16 bits? Para eso, necesitamos mayúsculas: `\U`.

Por ejemplo:

``` {.c}
char *s = "\U0001D4D1";

printf("%s\n", s);  // Imprime una matemática letter "B"
```

Es lo mismo que `\u`, sólo que con 32 bits en lugar de 16. Son equivalentes:

``` {.c}
\u03C0
\U000003C0
```

[i[`\u` Unicode escape]>]
[i[`\U` Unicode escape]>]

De nuevo, se traducen al juego de caracteres de [i[Character sets-->execution]]ejecución durante la compilación. Representan puntos de código Unicode, no una codificación específica. Además, si un punto de código Unicode no es representable en el conjunto de caracteres de ejecución, el compilador puede hacer lo que quiera con él.

Ahora bien, puede que se pregunte por qué no puede hacer esto sin más:

``` {.c}
char *s = "€1.23";

printf("%s\n", s);  // €1.23
```

Y probablemente pueda, dado un compilador moderno. El [i[Character sets-->source]]juego de caracteres fuente será traducido por el compilador al [i[Character sets-->execution]]juego de caracteres de ejecución. Pero los compiladores son libres de vomitar si encuentran cualquier carácter que no esté incluido en su juego de caracteres extendido, y el símbolo € ciertamente no está en el [i[Character sets-->basic]]juego de caracteres básico.

[i[`\u` Unicode escape]<]
[i[`\U` Unicode escape]<]

Advertencia de la especificación: no se puede utilizar `\u` o `\U` para codificar ningún punto de código por debajo de 0xA0 excepto 0x24 (`$`), 0x40 (`@`), y 0x60 (`` ```)---sí, esos son precisamente el trío de signos de puntuación comunes que faltan en el juego de caracteres básico. Al parecer, esta restricción se relajará en la próxima versión de la especificación.

[i[`\u` Unicode escape]>]
[i[`\U` Unicode escape]>]

Por último, también puede utilizar estos en identificadores en su código, con algunas restricciones. Pero no quiero entrar en eso aquí. En este capítulo nos centramos en el manejo de cadenas.

Y eso es todo sobre Unicode en C (excepto la codificación).

## Una nota rápida sobre UTF-8 antes de adentrarnos en la maleza {#utf8-quick}

[i[Unicode-->UTF-8]<]

Podría ser que tu archivo fuente en disco, los caracteres fuente extendidos y los caracteres de ejecución extendidos estén todos en formato UTF-8. Y las bibliotecas que utilizas esperan UTF-8. Este es el glorioso futuro de UTF-8 en todas partes.

Si ese es el caso, y no te importa ser no-portable a sistemas que no son así, entonces simplemente corre con ello. Mete caracteres Unicode en tus fuentes y datos a voluntad. Usa cadenas C normales y sé feliz.

Muchas cosas funcionarán (aunque de forma no portable) porque las cadenas UTF-8 pueden terminar en NUL de forma segura como cualquier otra cadena C. Pero tal vez perder portabilidad a cambio de un manejo más sencillo de los caracteres sea una compensación que merezca la pena.

Sin embargo, hay algunas advertencias:

* Cosas como `strlen()` informan del número de bytes de una cadena, no necesariamente del número de caracteres. (La función [i[`mbstowcs()`-->con UTF-8]]`mbstowcs()` devuelve el número de caracteres de una cadena cuando la convierte a caracteres anchos. POSIX extiende esto para que pueda pasar `NULL` para el primer argumento si sólo quiere el recuento de caracteres).

* Lo siguiente no funcionará correctamente con caracteres de más de un byte: [i[`strtok()` function-->with UTF-8]]`strtok()`, [i[`strchr()` function-->with UTF-8]]`strchr()` (use [i[`strstr()` function-->with UTF-8]]`str()` en su lugar), funciones del tipo `strspn()`, [i[`toupper()` function-->with UTF-8]]`toupper()`, [i[`tolower()` function-->with UTF-8]]`tolower()`, [i[`isalpha()` function-->with UTF-8]]`isalpha()`-type functions, y probablemente más. Cuidado con todo lo que opere sobre bytes.

 * [i[`printf()` function-->with UTF-8]]`printf()` variants allow for a way to only print so many bytes of a string^[Con un especificador de formato como `"%.12s"`, por ejemplo.]. Quieres asegurarte de que imprimes el número correcto de bytes para terminar en un límite de carácter.

* [i[función `malloc()`-->con UTF-8]]Si quieres `malloc()` espacio para una cadena, o declarar un array de `char`s para una, ten en cuenta que el tamaño máximo podría ser más de lo que esperabas. Cada caracter puede ocupar hasta [i[macro `MB_LEN_MAX`]]`MB_LEN_MAX` bytes (de `<limits.h>`)---excepto los caracteres del juego de caracteres básico que se garantiza que son de un byte



Y probablemente otros que no he descubierto. Háganme saber qué trampas
hay por ahí...

[i[Unicode-->UTF-8]>]

## Diferentes tipos de personajes

Quiero introducir más tipos de caracteres. Estamos acostumbrados a `char`, ¿verdad?

Pero eso es demasiado fácil. ¡Hagamos las cosas mucho más difíciles! ¡Sí!

### Caracteres multibyte

[i[Multibyte characters]<]

En primer lugar, quiero cambiar potencialmente tu idea de lo que es una cadena (array de `char`s). Son _cadenas multibyte_ formadas por _caracteres multibyte_.

Así es, una cadena de caracteres común y corriente es multibyte. Cuando alguien dice "cadena C", quiere decir "cadena multibyte C".

Incluso si un carácter en particular en la cadena es sólo un byte, o si una cadena se compone sólo de caracteres simples, se conoce como una cadena multibyte.

Por ejemplo:

``` {.c}
char c[128] = "Hello, world!";  // Multibyte string
```

Lo que queremos decir con esto es que un carácter concreto que no esté en el juego de caracteres básico podría estar compuesto por varios bytes. Hasta [i[macro `MB_LEN_MAX`]]`MB_LEN_MAX` de ellos (de `<limits.h>`). Claro, sólo parece un carácter en la pantalla, pero podrían ser múltiples bytes.

También puedes meter valores Unicode, como vimos antes:

``` {.c}
char *s = "\u20AC1.23";

printf("%s\n", s);  // €1.23
```

Pero aquí entramos en algo raro, porque mira esto:

[i[`strlen()` function-->with UTF-8]<]

``` {.c}
char *s = "\u20AC1.23";  // €1.23

printf("%zu\n", strlen(s));  // 7!
```

¡¿La longitud de la cadena de `"€1.23"` es `7`?! ¡Sí! Bueno, en mi sistema, ¡sí! Recuerde que `strlen()` devuelve el número de bytes de la cadena, no el número de caracteres. (Cuando lleguemos a "caracteres anchos", más adelante, veremos una forma de obtener el número de caracteres de la cadena).

[i[`strlen()` function-->with UTF-8]>]

Tenga en cuenta que aunque C permite constantes individuales multibyte `char` (en oposición a `char*`), el comportamiento de éstas varía según la implementación y su compilador podría advertirle de ello.

GCC, por ejemplo, advierte de constantes de caracteres multibyte para las dos líneas siguientes (y, en mi sistema, imprime la codificación UTF-8):

``` {.c}
printf("%x\n", '€');
printf("%x\n", '\u20ac');
```

[i[Multibyte characters]>]

### Caracteres anchos {#wide-characters}

[i[Wide characters]<]

Si no es un carácter multibyte, entonces es un _carácter ancho_.

Un carácter ancho es un valor único que puede representar cualquier carácter en la configuración regional actual. Es análogo a los puntos de código Unicode. Pero podría no serlo. O podría serlo.

Básicamente, mientras que las cadenas de caracteres multibyte son matrices de bytes, las cadenas de caracteres anchos son matrices de _caracteres_. Así que puedes empezar a pensar carácter por carácter en lugar de byte por byte (esto último se complica cuando los caracteres empiezan a ocupar un número variable de bytes).

[i[`wchar_t` type]<]

Los caracteres anchos pueden representarse mediante varios tipos, pero el más destacado es `wchar_t`. Es el principal. Es como `char`, pero ancho.

Te estarás preguntando si no puedes saber si es Unicode o no, ¿cómo te permite eso mucha flexibilidad a la hora de escribir código? `wchar_t` abre algunas de esas puertas, ya que hay un rico conjunto de funciones que puedes usar para tratar con cadenas `wchar_t` (como obtener la longitud, etc.) sin preocuparte de la codificación.

## Uso de caracteres anchos y `wchar_t`

Es hora de un nuevo tipo: `wchar_t`. Este es el principal tipo de carácter ancho. ¿Recuerdas que un `char` es sólo un byte? ¿Y un byte no es suficiente para representar todos los caracteres, potencialmente? Pues este es suficiente.

Para usar `wchar_t`, incluye `<wchar.h>`.

¿De cuántos bytes es? Bueno, no está del todo claro. Podrían ser 16
bits. Podrían ser 32 bits.

Pero espera, estás diciendo---si son sólo 16 bits, no es lo suficientemente grande como para contener todos los puntos de código Unicode, ¿verdad? Tienes razón, no lo es. La especificación no requiere que lo sea. Sólo tiene que ser capaz de representar todos los caracteres de la configuración regional actual.

Esto puede causar problemas con Unicode en plataformas con `wchar_t`s de 16 bits (ejem---Windows). Pero eso está fuera del alcance de esta guía.

[i[`L` wide character prefix]<]

Puede declarar una cadena o carácter de este tipo con el prefijo `L`, y puede imprimirlos con el especificador de formato `%ls` ("ell ess"). O imprimir un `wchar_t` individual con `%lc`.

``` {.c}
wchar_t *s = L"Hello, world!";
wchar_t c = L'B';

printf("%ls %lc\n", s, c);
```

[i[`L` wide character prefix]>]

Ahora bien, ¿estos caracteres se almacenan como puntos de código Unicode o no? Depende de la implementación. Pero puedes comprobar si lo están con la macro [i[`__STDC_ISO_10646__` macro]]. `__STDC_ISO_10646__`. Si está definida, la respuesta es: "¡Es Unicode!".

Más detalladamente, el valor de esa macro es un número entero de la forma `yyyymm` que le permite saber en qué estándar Unicode puede confiar---el que estuviera en vigor en esa fecha.

Pero, ¿cómo se utilizan?

### Conversiones de Multibyte a `wchar_t`

Entonces, ¿cómo pasamos de las cadenas estándar orientadas a bytes a las cadenas anchas orientadas a caracteres y viceversa?

Podemos utilizar un par de funciones de conversión de cadenas para hacerlo.

Primero, algunas convenciones de nomenclatura que verás en estas funciones:

* `mb`: multibyte
* `wc`: carácter ancho
* `mbs`: cadena multibyte
* `wcs`: cadena de caracteres anchos

Así que si queremos convertir una cadena multibyte en una cadena de caracteres anchos, podemos llamar a `mbstowcs()`. Y al revés: `wcstombs()`.

[i[`mbtowc()` function]]
[i[`wctomb()` function]]
[i[`mbstowcs()` function]]
[i[`wcstombs()` function]]

|Función de conversión|Descripción
|------------|---------------------------------------------------|
|`mbtowc()`|Convierte un carácter multibyte en un carácter ancho.|
|`wctomb()`|Convierte un carácter ancho en un carácter multibyte.|
|`mbstowcs()`|Convierte una cadena multibyte en una cadena ancha.|
|`wcstombs()`|Convierte una cadena ancha en una cadena multibyte.|

Hagamos una demostración rápida en la que convertiremos una cadena multibyte en una cadena de caracteres anchos, y compararemos las longitudes de cadena de ambas utilizando sus respectivas funciones.

[i[`mbstowcs()` function]<]

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include <string.h>
#include <locale.h>

int main(void)
{
    // Salir de la configuración regional C a una que probablemente tenga el símbolo del euro
    setlocale(LC_ALL, "");

    // Cadena multibyte original con el símbolo del euro (punto 20ac de Unicode)
    char *mb_string = "The cost is \u20ac1.23";  // €1.23
    size_t mb_len = strlen(mb_string);

    // Matriz de caracteres anchos que contendrá la cadena convertida
    wchar_t wc_string[128];  // Contiene hasta 128 caracteres de ancho

    // Convierte la cadena MB a WC; esto devuelve el número de caracteres anchos
    size_t wc_len = mbstowcs(wc_string, mb_string, 128);

    // Imprime el resultado - nota las %ls para cadenas de caracteres anchos
    printf("multibyte: \"%s\" (%zu bytes)\n", mb_string, mb_len);
    printf("wide char: \"%ls\" (%zu characters)\n", wc_string, wc_len);
}
```

[i[`wchar_t` type]>]

En mi sistema, esta salida:

``` {.default}
multibyte: "The cost is €1.23" (19 bytes)
wide char: "The cost is €1.23" (17 characters)
```

(Su sistema puede variar en el número de bytes dependiendo de su localización).

Una cosa interesante a tener en cuenta es que `mbstowcs()`, además de convertir la cadena multibyte a ancha, devuelve la longitud (en caracteres) de la cadena de caracteres anchos. En sistemas compatibles con POSIX, puede aprovechar un modo especial en el que _sólo_ devuelve la longitud en caracteres de una cadena multibyte dada: sólo tiene que pasar `NULL` al destino, y `0` al número máximo de caracteres a convertir (este valor se ignora).

(En el código de abajo, estoy usando mi juego de caracteres fuente extendido---puede que tengas que reemplazarlos con escapes `\u`).

``` {.c}
setlocale(LC_ALL, "");

// La siguiente cadena tiene 7 caracteres
size_t len_in_chars = mbstowcs(NULL, "§¶°±π€•", 0);

printf("%zu", len_in_chars);  // 7
```

[i[`mbstowcs()` function]>]

De nuevo, es una extensión POSIX no portable.

Y, por supuesto, si quieres convertir de la otra manera, es [i[`wcstombs()` function]]
`wcstombs()`.

## Funcionalidad de los caracteres anchos

Una vez en la tierra de los caracteres anchos, tenemos todo tipo de funciones a nuestra disposición. Sólo voy a resumir un montón de funciones, pero básicamente lo que tenemos aquí son las versiones de caracteres anchos de las funciones de cadena multibyte a las que estamos acostumbrados. (Por ejemplo, conocemos `strlen()` para cadenas multibyte; hay una [i[función `wcslen()`] `wcslen()` para cadenas de caracteres anchos).

### `wint_t`

[i[`wint_t` type]<]

Muchas de estas funciones utilizan un `wint_t` para contener caracteres individuales, ya sean pasados o devueltos.

Está relacionado con `wchar_t` por naturaleza. Un `wint_t` es un entero que puede representar todos los valores del juego de caracteres extendido, y también un carácter especial de fin de fichero, `WEOF`.

[i[`wint_t` type]>]

Lo utilizan varias funciones de caracteres anchos orientadas a un solo carácter.

### Orientación del flujo de E/S {#io-stream-orientation}

[i[I/O stream orientation]<]

Lo importante es no mezclar funciones orientadas a bytes (como `fprintf()`) con funciones orientadas a ancho (como `fwprintf()`). Decide si un flujo será orientado a bytes o a ancho y quédate con esos tipos de funciones de E/S.

En más detalle: los flujos pueden estar orientados a bytes u orientados a ancho. Cuando un flujo se crea por primera vez, no tiene orientación, pero la primera lectura o escritura establecerá la orientación.

Si utiliza por primera vez una operación amplia (como `fwprintf()`) orientará el flujo de forma amplia.

Si utiliza por primera vez una operación byte (como `fprintf()`) orientará el flujo por bytes.

Puede orientar manualmente un flujo desorientado de una forma u otra con una llamada a [i[`fwide()` function]]. `fwide()`. Puede utilizar esa misma función para obtener la orientación de un flujo.

Si necesitas cambiar la orientación en mitad del vuelo, puedes hacerlo con `freopen()`.

[i[I/O stream orientation]>]

### Funciones de E/S

Típicamente incluye `<stdio.h>` y `<wchar.h>` para estas.

[i[`wprintf()` function]]
[i[`wscanf()` function]]
[i[`getwchar()` function]]
[i[`putwchar()` function]]
[i[`fwprintf()` function]]
[i[`fwscanf()` function]]
[i[`fgetwc()` function]]
[i[`fputwc()` function]]
[i[`fgetws()` function]]
[i[`fputws()` function]]
[i[`swprintf()` function]]
[i[`swscanf()` function]]
[i[`vfwprintf()` function]]
[i[`vfwscanf()` function]]
[i[`vswprintf()` function]]
[i[`vswscanf()` function]]
[i[`vwprintf()` function]]
[i[`vwscanf()` function]]
[i[`ungetwc()` function]]
[i[`fwide()` function]]

|I/O Función|Descripción|
|------------|---------------------------------------------------|
|`wprintf()`|Salida de consola formateada.|
|`wscanf()`|Entrada de consola formateada.|
|`getwchar()`|Entrada de consola basada en caracteres.|
|`putwchar()`|Salida de consola basada en caracteres.|
|`fwprintf()`|Salida de archivos formateados.|
|`fwscanf()`|Entrada de archivos formateados.|
|`fgetwc()`|Entrada de archivos basada en caracteres.|
|`fputwc()`|Salida de archivos basada en caracteres.|
|`fgetws()`|Entrada de archivos basada en cadenas.|
|`fputws()`|Salida de archivos basada en cadenas.|
|`swprintf()`|Cadena formateada output.|
|`swscanf()`|Cadena formateada input.|
|`vfwprintf()`|Salida de archivo con formato variable.|
|`vfwscanf()`|Archivo con formato variadic entrada.|
|`vswprintf()`|Salida de cadena con formato variable.|
|`vswscanf()`|Entrada de cadena con formato variable.|
|`vwprintf()`|Salida de consola con formato variable.|
|`vwscanf()`|Entrada de consola con formato variable.|
|`ungetwc()`|Empuja un carácter ancho hacia atrás en un flujo de salida.|
|`fwide()`|Obtener o establecer la orientación multibyte/ancha del flujo.|

### Funciones de conversión de tipos

Típicamente incluye `<wchar.h>` para esto.

[i[`wcstod()` function]]
[i[`wcstof()` function]]
[i[`wcstold()` function]]
[i[`wcstol()` function]]
[i[`wcstoll()` function]]
[i[`wcstoul()` function]]
[i[`wcstoull()` function]]



|Función de conversión|Descripción
|------------|---------------------------------------------------|
|`wcstod()`|Convierte cadena(String) a `doble`.|
|`wcstof()`|Convierte cadena a `float`.|
|`wcstold()`|Convierte cadena a `long double`.|
|`wcstol()`|Convierte cadena a `long`.|
|`wcstoll()`|Convierte cadena a `long long`.|
|`wcstoul()`|Convierte cadena a `unsigned long`.|
|`wcstoull()`|Convierte cadena a `unsigned long long`.|

### Funciones de copia de cadenas y memoria

Típicamente incluye `<wchar.h>` para estas.

[i[`wcscpy()` function]]
[i[`wcsncpy()` function]]
[i[`wmemcpy()` function]]
[i[`wmemmove()` function]]
[i[`wcscat()` function]]
[i[`wcsncat()` function]]

|Función de copia|Descripción|
|----|----------------------------------------------|
|`wcscpy()`|Copiar cadena.|
|`wcsncpy()`|Cadena de copia, de longitud limitada.|
|`wmemcpy()`|Copiar memoria.|
|`wmemmove()`|Copia la memoria potencialmente solapada.|
|`wcscat()`|Concatenar cadenas.|
|`wcsncat()`|Concatenar cadenas, longitud limitada.|

### Funciones de comparación de cadenas y memoria

Típicamente incluye `<wchar.h>` para estas.

[i[`wcscmp()` function]]
[i[`wcsncmp()` function]]
[i[`wcscoll()` function]]
[i[`wmemcmp()` function]]
[i[`wcsxfrm()` function]]

|Función de comparación|Descripción|
|-------------------|---------------------------------------------------------------|
|`wcscmp()`|Compara cadenas lexicográficamente.|
|`wcsncmp()`|Compara cadenas lexicográficamente, con límite de longitud.|
|`wcscoll()`|Compara cadenas en orden de diccionario por configuración regional.|
|`wmemcmp()`|Compara la memoria lexicográficamente.|
|`wcsxfrm()`|Transforma cadenas en versiones tales que `wcscmp()` se comporta como `wcscoll()`[^97d0].|

[^97d0]: `wcscoll()` es lo mismo que `wcsxfrm()` seguido de `wcscmp()`.

### Funciones de búsqueda de cadenas

Típicamente incluye `<wchar.h>` para estas.

[i[`wcschr()` function]]
[i[`wcsrchr()` function]]
[i[`wmemchr()` function]]
[i[`wcsstr()` function]]
[i[`wcspbrk()` function]]
[i[`wcsspn()` function]]
[i[`wcscspn()` function]]
[i[`wcstok()` function]]

|Función de búsqueda|Descripción|
|-|-|
|`wcschr()`|Find a character in a string.|
|`wcsrchr()`|Find a character in a string from the back.|
|`wmemchr()`|Find a character in memory.|
|`wcsstr()`|Find a substring in a string.|
|`wcspbrk()`|Find any of a set of characters in a string.|
|`wcsspn()`|Find length of substring including any of a set of characters.|
|`wcscspn()`|Find length of substring before any of a set of characters.|
|`wcstok()`|Find tokens in a string.|

### Longitud/Funciones varias

Typically include `<wchar.h>` for these.

[i[`wcslen()` function]]
[i[`wmemset()` function]]
[i[`wcsftime()` function]]

|Length/Misc Function|Description|
|-|-|
|`wcslen()`|Return the length of the string.|
|`wmemset()`|Set characters in memory.|
|`wcsftime()`|Formatted date and time output.|

### Funciones de clasificación de caracteres

Include `<wctype.h>` for these.

[i[`iswalnum()` function]]
[i[`iswalpha()` function]]
[i[`iswblank()` function]]
[i[`iswcntrl()` function]]
[i[`iswdigit()` function]]
[i[`iswgraph()` function]]
[i[`iswlower()` function]]
[i[`iswprint()` function]]
[i[`iswpunct()` function]]
[i[`iswspace()` function]]
[i[`iswupper()` function]]
[i[`iswxdigit()` function]]
[i[`towlower()` function]]
[i[`towupper()` function]]

|Length/Misc Function|Description|
|------------|---------------------------------------------------|
|`iswalnum()`|True if the character is alphanumeric.|
|`iswalpha()`|True if the character is alphabetic.|
|`iswblank()`|True if the character is blank (space-ish, but not a newline).|
|`iswcntrl()`|True if the character is a control character.|
|`iswdigit()`|True if the character is a digit.|
|`iswgraph()`|True if the character is printable (except space).|
|`iswlower()`|True if the character is lowercase.|
|`iswprint()`|True if the character is printable (including space).|
|`iswpunct()`|True if the character is punctuation.|
|`iswspace()`|True if the character is whitespace.|
|`iswupper()`|True if the character is uppercase.|
|`iswxdigit()`|True if the character is a hex digit.|
|`towlower()`|Convert character to lowercase.|
|`towupper()`|Convert character to uppercase.|

## Estado de análisis, funciones reiniciables

[i[Multibyte characters-->parse state]<]

Vamos a entrar un poco en las tripas de la conversión multibyte, pero esto es algo bueno de entender, conceptualmente.

Imagina cómo tu programa toma una secuencia de caracteres multibyte y los convierte en caracteres anchos, o viceversa. Puede que, en algún momento, esté a medio camino de analizar un carácter, o puede que tenga que esperar más bytes antes de determinar el valor final.

Este estado de análisis se almacena en una variable opaca de tipo `mbstate_t` y se utiliza cada vez que se realiza la conversión. Así es como las funciones de conversión llevan la cuenta de dónde se encuentran a mitad de trabajo.
Y si cambias a una secuencia de caracteres diferente a mitad del proceso, o intentas buscar un lugar diferente en tu secuencia de entrada, podría confundirse.

Puede que quieras llamarme la atención sobre esto: acabamos de hacer algunas conversiones, arriba, y nunca mencioné ningún `mbstate_t` en ningún sitio.

Eso es porque las funciones de conversión como `mbstowcs()`, `wctomb()`, etc. tienen cada una su propia variable `mbstate_t` que usan. Sólo hay una por función, así que si estás escribiendo código multihilo, no es seguro usarlas.

Afortunadamente, C define versiones _restartable_ de estas funciones donde puedes pasar tu propio `mbstate_t` por hilo si lo necesitas. Si estás haciendo cosas multihilo, ¡úsalas!

Nota rápida sobre la inicialización de una variable `mbstate_t`: simplemente `memset()` a cero. No hay ninguna función integrada para forzar su inicialización.

``` {.c}
mbstate_t mbs;

// Establecer el estado inicial
memset(&mbs, 0, sizeof mbs);
```

Esta es una lista de las funciones de conversión reiniciables: tenga en cuenta la convención de nomenclatura de poner una "`r`" después del tipo "from":

* mbrtowc()`---carácter multibyte a carácter ancho
* `wcrtomb()`--carácter ancho a multibyte
* `mbsrtowcs()`---cadena multibyte a cadena de caracteres anchos
* `wcsrtombs()`---cadena de caracteres anchos a cadena multibyte

Son muy similares a sus equivalentes no reiniciables, salvo que requieren que pases un puntero a tu propia variable `mbstate_t`. Y también modifican el puntero de la cadena fuente (para ayudarte si se encuentran bytes inválidos), por lo que puede ser útil guardar una copia del original.

Aquí está el ejemplo de antes en el capítulo reelaborado para pasar nuestro propio `mbstate_t`.

``` {.c .numberLines}
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <wchar.h>
#include <string.h>
#include <locale.h>

int main(void)
{
    // Salir de la configuración regional C a una que probablemente tenga el símbolo del euro
    setlocale(LC_ALL, "");

    // Cadena multibyte original con el símbolo del euro (punto 20ac de Unicode)
    char *mb_string = "The cost is \u20ac1.23";  // €1.23
    size_t mb_len = strlen(mb_string);

    // Matriz de caracteres anchos que contendrá la cadena convertida
    wchar_t wc_string[128];  // Contiene hasta 128 caracteres de ancho

    // Configurar el estado de conversión
    mbstate_t mbs;
    memset(&mbs, 0, sizeof mbs);  // Estado inicial

    // mbsrtowcs() modifica el puntero de entrada para que apunte al primer
    // carácter inválido, o NULL si tiene éxito. Hagamos una copia de
    // del puntero para que mbsrtowcs() se meta con él, así nuestro original queda
    // sin cambios.
    //
    // Este ejemplo probablemente sea exitoso, pero chequeamos mas adelante
    // abajo para ver.
    const char *invalid = mb_string;

    // Convierte la cadena MB a WC; esto devuelve el número de caracteres anchos
    size_t wc_len = mbsrtowcs(wc_string, &invalid, 128, &mbs);

    if (invalid == NULL) {
        printf("No invalid characters found\n");

        // Imprime el resultado - nota las %ls para cadenas de caracteres anchos
        printf("multibyte: \"%s\" (%zu bytes)\n", mb_string, mb_len);
        printf("wide char: \"%ls\" (%zu characters)\n", wc_string, wc_len);
    } else {
        ptrdiff_t offset = invalid - mb_string;
        printf("Invalid character at offset %td\n", offset);
    }
}
```

Para las funciones de conversión que gestionan su propio estado, puedes restablecer su estado interno al inicial pasando `NULL` para sus argumentos `char*`, por ejemplo:

``` {.c}
mbstowcs(NULL, NULL, 0); // Restablecer el estado de análisis para mbstowcs()
mbstowcs(dest, src, 100); // Analiza algunas cosas
```

Para la E/S, cada flujo ancho gestiona su propio `mbstate_t` y lo utiliza para las conversiones de entrada y salida sobre la marcha.

Y algunas de las funciones de E/S orientadas a bytes como `printf()` y `scanf()` mantienen su propio estado interno mientras hacen su trabajo.

Finalmente, estas funciones de conversión reiniciables tienen su propio estado interno si pasas `NULL` por el parámetro `mbstate_t`. Esto hace que se comporten más como sus homólogas no reiniciables.

[i[Multibyte characters-->parse state]>]
[i[Wide characters]>]

## Codificaciones Unicode y C

In this section, we'll see what C can (and can't) do when it comes to
three specific Unicode encodings: UTF-8, UTF-16, and UTF-32.

### UTF-8

[i[Unicode-->UTF-8]<]

To refresh before this section, read the [UTF-8 quick note,
above](#utf8-quick).

Aside from that, what are C's UTF-8 capabilities?

Well, not much, unfortunately.

[i[`u8` UTF-8 prefix]<]

You can tell C that you specifically want a string literal to be UTF-8
encoded, and it'll do it for you. You can prefix a string with `u8`:

``` {.c}
char *s = u8"Hello, world!";

printf("%s\n", s);   // Hello, world!--if you can output UTF-8
```

Now, can you put Unicode characters in there?

``` {.c}
char *s = u8"€123";
```

[i[`u8` UTF-8 prefix]>]

Sure! If the extended source character set supports it. (gcc does.)

What if it doesn't? You can specify a Unicode code point with your
friendly neighborhood `\u` and `\U`, [as noted above](#unicode-in-c).

But that's about it. There's no portable way in the standard library to
take arbirary input and turn it into UTF-8 unless your locale is UTF-8.
Or to parse UTF-8 unless your locale is UTF-8.

So if you want to do it, either be in a UTF-8 locale and:

[i[`setlocale()` function]<]

``` {.c}
setlocale(LC_ALL, "");
```

or figure out a UTF-8 locale name on your local machine and set it
explicitly like so:

``` {.c}
setlocale(LC_ALL, "en_US.UTF-8");  // Non-portable name
```

[i[`setlocale()` function]>]

Or use a [third-party library](#utf-3rd-party).

[i[Unicode-->UTF-8]>]

### UTF-16, UTF-32, `char16_t`, y `char32_t`

[i[Unicode-->UTF-16]<]
[i[Unicode-->UTF-32]<]
[i[`char16_t` type]<]
[i[`char32_t` type]<]

`char16_t` and `char32_t` are a couple other potentially wide character
types with sizes of 16 bits and 32 bits, respectively. Not necessarily
wide, because if they can't represent every character in the current
locale, they lose their wide character nature. But the spec refers them
as "wide character" types all over the place, so there we are.

These are here to make things a little more Unicode-friendly,
potentially.

To use, include `<uchar.h>`. (That's "u", not "w".)

This header file doesn't exist on OS X---bummer. If you just want the
types, you can:

``` {.c}
#include <stdint.h>

typedef int_least16_t char16_t;
typedef int_least32_t char32_t;
```

But if you also want the functions, that's all on you.

[i[`u` Unicode prefix]<]
[i[`U` Unicode prefix]<]

Assuming you're still good to go, you can declare a string or character
of these types with the `u` and `U` prefixes:

``` {.c}
char16_t *s = u"Hello, world!";
char16_t c = u'B';

char32_t *t = U"Hello, world!";
char32_t d = U'B';
```

[i[`char32_t` type]>]
[i[`u` Unicode prefix]>]
[i[`U` Unicode prefix]>]

Now---are values in these stored in UTF-16 or UTF-32? Depends on the
implementation.

But you can test to see if they are. If the macros [i[`__STDC_UTF_16__`
macro]] `__STDC_UTF_16__` or [i[`__STDC_UTF_32__ macro`]]
`__STDC_UTF_32__` are defined (to `1`) it means the types hold UTF-16 or
UTF-32, respectively.

If you're curious, and I know you are, the values, if UTF-16 or UTF-32,
are stored in the native endianess. That is, you should be able to
compare them straight up to Unicode code point values:

``` {.c}
char16_t pi = u"\u03C0";  // pi symbol

#if __STDC_UTF_16__
pi == 0x3C0;  // Always true
#else
pi == 0x3C0;  // Probably not true
#endif
```

[i[`char16_t` type]>]
[i[Unicode-->UTF-16]>]
[i[Unicode-->UTF-32]>]

###  Conversiones multibyte

You can convert from your multibyte encoding to `char16_t` or `char32_t`
with a number of helper functions.

(Like I said, though, the result might not be UTF-16 or UTF-32 unless the
corresponding macro is set to `1`.)

All of these functions are restartable (i.e. you pass in your own
`mbstate_t`), and all of them operate character by
character^[Ish---things get funky with multi-`char16_t` UTF-16
encodings.].

[i[`mbrtoc16()` function]]
[i[`mbrtoc32()` function]]
[i[`c16rtomb()` function]]
[i[`c32rtomb()` function]]


|Conversion Function|Description|
|-|-|
|`mbrtoc16()`|Convert a multibyte character to a `char16_t` character.|
|`mbrtoc32()`|Convert a multibyte character to a `char32_t` character.|
|`c16rtomb()`|Convert a `char16_t` character to a multibyte character.|
|`c32rtomb()`|Convert a `char32_t` character to a multibyte character.|

### Bibliotecas de terceros {#utf-3rd-party}

For heavy-duty conversion between different specific encodings, there
are a couple mature libraries worth checking out. Note that I haven't
used either of these.

* [flw[iconv|Iconv]]---Internationalization Conversion, a common
  POSIX-standard API available on the major platforms.
* [fl[ICU|http://site.icu-project.org/]]---International Components for
  Unicode. At least one blogger found this easy to use.

If you have more noteworthy libraries, let me know.

[i[Unicode]>]
