<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Caracteres y Strings II

Ya hemos hablado de cómo los tipos `char` son en realidad tipos de enteros pequeños...
pero es lo mismo para un carácter entre comillas simples.

Pero una cadena entre comillas dobles es del tipo `const char *`.

Resulta que hay algunos tipos más de cadenas y caracteres, y esto nos lleva a uno de
los agujeros de conejo más infames del lenguaje: todo el asunto multibyte/ancho/Unicode/localización.

Vamos a asomarnos a esa madriguera de conejo, pero sin entrar. ...¡Todavía!

## Secuencias de escape

[i[Escape sequences]<]

Estamos acostumbrados a cadenas y caracteres con letras, signos de puntuación y
números normales:

``` {.c}
char *s = "Hello!";
char t = 'c';
```

Pero, ¿y si queremos introducir algún carácter especial que no podemos escribir con el 
teclado porque no existe (por ejemplo, "€"), o incluso si queremos un carácter que sea
una comilla simple? Está claro que no podemos hacerlo:

``` {.c}
char t = ''';
```

[i[`\` backslash escape]<]

Para hacer estas cosas, utilizamos algo llamado _secuencias de escape_. Se trata del
carácter barra invertida (`\`) seguido de otro carácter. Los dos (o más) caracteres
juntos tienen un significado especial.

Para nuestro ejemplo de carácter de comilla simple, podemos poner un escape (es decir,
`\`) delante de la comilla simple central para resolverlo:

[i[`\'` single quote]<]

``` {.c}
char t = '\'';
```

Ahora C sabe que `\'` significa sólo una comilla normal que queremos imprimir, no el
final de la secuencia de caracteres.

[i[`\'` single quote]>]

Puedes decir "barra invertida" o "escape" en este contexto ("escape esa comilla") y
los desarrolladores de C sabrán de qué estás hablando. Además, "escape" en este
contexto es diferente de la tecla `Esc` o del código ASCII `ESC`.

### Escapes de uso frecuente

En mi humilde opinión, estos caracteres de escape constituyen el 99,2%^[me acabo de
inventar esa cifra, pero probablemente no esté muy lejos] de todos los escapes.

[i[`\n` newline]]
[i[`\'` single quote]]
[i[`\"` double quote]]
[i[`\\` backslash]]

|Codigo|Descripción|
|--|------------|
|`\n`|Carácter de nueva línea---cuando se imprime, continúa la salida subsiguiente en la línea siguiente|
|`\'`|Comilla simple: se utiliza para una constante de carácter de comilla simple.|
|`\"`|Comilla doble: se utiliza para una comilla doble en una cadena literal.|
|`\\`|Barra diagonal inversa---utilizada para un literal `\` en una cadena o carácter|

Estos son algunos ejemplos de los escapes y lo que muestran cuando se imprimen.

``` {.c}
printf("Use \\n for newline\n");  // Usar \n para nueva línea
printf("Say \"hello\"!\n");       // Diga "hello"!
printf("%c\n", '\'');             // '
```

### Escapes poco utilizados

Pero hay más escapes. Sólo que no se ven tan a menudo.

[i[`\a` alert]]
[i[`\b` backspace]]
[i[`\f` formfeed]]
[i[`\r` carriage return]]
[i[`\t` tab]]
[i[`\v` vertical tab]]
[i[`\?` question mark]]

|Código|Description|
|--|------------|
|`\a`|Alerta. Esto hace que el terminal emita un sonido o un destello, ¡o ambos!|
|`\b`|Retroceso. Desplaza el cursor un carácter hacia atrás. No borra el carácter.|
|`\f`|Alimentar formulario. Esto se mueve a la siguiente "página", pero eso no tiene mucho significado moderno. En mi sistema, esto se comporta como `\v`.|
|`\r`|Volver. Desplazarse al principio de la misma línea.|
|`\t`|Tabulador horizontal. Se mueve al siguiente tabulador horizontal. En mi máquina, esto se alinea en columnas que son múltiplos de 8, pero YMMV.|
|`\v`|Tabulación vertical. Se mueve al siguiente tabulador vertical. En mi máquina, esto se mueve a la misma columna en la línea siguiente.|
|`\?`|Signo de interrogación literal. A veces es necesario para evitar los trígrafos, como se muestra a continuación.|

#### Actualizaciones de estado de línea única

[i[`\b` backspace]<]
[i[`\r` carriage return]<]

Un caso de uso para `\b` o `\r` es mostrar actualizaciones de estado que aparecen en la misma línea en la pantalla y no causan que la pantalla se desplace. Aquí hay un ejemplo que hace una cuenta atrás desde 10. (Si tu compilador no soporta threading, puedes usar la función POSIX no estándar `sleep()` de `<unistd.h>`---si no estás en un Unix-like, busca tu plataforma y `sleep` para el equivalente).

``` {.c .numberLines}
#include <stdio.h>
#include <threads.h>

int main(void)
{
    for (int i = 10; i >= 0; i--) {
        printf("\rT minutos %d segundo%s... \b", i, i != 1? "s": "");

        fflush(stdout);  // Forzar la actualización de la salida

        // Sleep for 1 second
        thrd_sleep(&(struct timespec){.tv_sec=1}, NULL);
    }

    printf("\rLiftoff!             \n");
}
```

En la línea 7 ocurren varias cosas. En primer lugar, empezamos con un `\r` para llegar
al principio de la línea actual, luego sobrescribimos lo que haya allí con la cuenta atrás
actual. (Hay un operador ternario para asegurarnos de que imprimimos `1 segundo` en lugar
de `1 segundos`).

Además, hay un espacio después de `...` Eso es para que sobrescribamos correctamente
el último `.` cuando `i` baje de `10` a `9` y tengamos una columna más estrecha. Pruébalo
sin el espacio para ver a qué me refiero.

Y lo envolvemos con un `\b` para retroceder sobre ese espacio para que el cursor se sitúe
en el final exacto de la línea de una manera estéticamente agradable.

[i[`\b` backspace]>]

Observe que la línea 14 también tiene un montón de espacios al final para sobrescribir
los caracteres que ya estaban allí desde la cuenta atrás.

Finalmente, tenemos un extraño `fflush(stdout)` ahí, sea lo que sea lo que signifique.
La respuesta corta es que la mayoría de los terminales están _line buffered_ por defecto,
lo que significa que no muestran nada hasta que se encuentra un carácter de nueva línea. Dado
que no tenemos una nueva línea (sólo tenemos `\r`), sin esta línea, el programa se quedaría
ahí hasta `¡Liftoff!` y entonces imprimiría todo en un instante. `fflush()` anula este
comportamiento y fuerza la salida a suceder _ahora_.

[i[`\r` carriage return]>]

#### La fuga de los signos de interrogación

[i[`\?` question mark]<]

¿Por qué molestarse con esto? Al fin y al cabo, esto funciona
muy bien:

``` {.c}
printf("Doesn't it?\n");
```

Y también funciona bien con el escape:

``` {.c}
printf("Doesn't it\?\n");   // Note \?
```

Entonces, ¿qué sentido tiene?

[i[Trigraphs]<]

Seamos más enfáticos con otro signo de interrogación y exclamación:

``` {.c}
printf("Doesn't it??!\n");
```

Cuando compilo esto, recibo esta advertencia:

``` {.zsh}
foo.c: In function ‘main’:
foo.c:5:23: warning: trigraph ??! converted to | [-Wtrigraphs]
    5 |     printf("Doesn't it??!\n");
      |    
```

Y ejecutarlo da este resultado improbable:

``` {.default}
Doesn't it|
```

¿Así que _trigrafías_? ¿Qué diablos es esto?

Estoy seguro de que volveremos sobre este rincón polvoriento del lenguaje más adelante, pero
el resumen es que el compilador busca ciertas tripletas de caracteres que empiezan por `??` y
las sustituye por otros caracteres. Así que si estás en un terminal antiguo sin el símbolo
de la tubería (`|`) en el teclado, puedes escribir `??!` en su lugar.

Puedes arreglar esto escapando el segundo signo de interrogación, así:

``` {.c}
printf("Doesn't it?\?!\n");
```

Y entonces se compila y funciona como se esperaba.

Hoy en día, por supuesto, nadie utiliza los trígrafos. Pero ese `??!` completo aparece a veces si
decides usarlo en una cadena para darle énfasis.
[i[Trigraphs]>]
[i[`\?` question mark]>]

### Escapes numéricos

Además, hay formas de especificar constantes numéricas u otros valores de caracteres dentro
de cadenas o constantes de caracteres.

Si conoce la representación octal o hexadecimal de un byte, puede incluirla en una cadena
o constante de caracteres.

La siguiente tabla contiene números de ejemplo, pero se puede utilizar cualquier número
hexadecimal u octal. Rellene con ceros a la izquierda si es necesario para leer el recuento
de dígitos correcto.

[i[`\123` octal value]]
[i[`\x12` hexadecimal value]]
[i[`\u` Unicode escape]]
[i[`\U` Unicode escape]]

|Código|Description|
|--|------------|
|`\123`|Incrusta el byte con valor octal `123`, 3 dígitos exactamente.|
|`\x4D`|Incrusta el byte con valor hexadecimal `4D`, 2 dígitos.|
|`\u2620`|Incrusta el carácter Unicode en el punto de código con valor hexadecimal `2620`, 4 dígitos.|
|`\U0001243F`|Incrusta el carácter Unicode en el punto de código con valor hexadecimal `1243F`, 8 dígitos.|

He aquí un ejemplo de la notación octal, menos utilizada, para representar la letra "B"
entre "A" y "C". Normalmente esto se usaría para algún tipo de carácter especial no imprimible,
pero tenemos otras formas de hacerlo, más abajo, y esto es sólo una demostración octal:

[i[`\123` octal value]<]

``` {.c}
printf("A\102C\n");  // 102 es `B` en ASCII/UTF-8
```

Tenga en cuenta que no hay cero a la izquierda en el número octal cuando se incluye de esta
manera. Pero tiene que tener tres caracteres, así que rellénalo con ceros a la izquierda
si es necesario.

[i[`\123` octal value]>]

[i[`\x12` hexadecimal value]<]

Pero mucho más común es utilizar constantes hexadecimales en estos días. Aquí tienes una
demostración que no deberías usar, pero que muestra cómo incrustar los bytes UTF-8 0xE2, 0x80 y
0xA2 en una cadena, lo que corresponde al carácter Unicode "bullet" (-).

``` {.c}
printf("\xE2\x80\xA2 Bullet 1\n");
printf("\xE2\x80\xA2 Bullet 2\n");
printf("\xE2\x80\xA2 Bullet 3\n");
```


Produce la siguiente salida si estás en una consola UTF-8 (o probablemente basura
si no lo estás):

``` {.default}
• Bullet 1
• Bullet 2
• Bullet 3
```

[i[`\x12` hexadecimal value]>]


[i[`\u` Unicode escape]<]
[i[`\U` Unicode escape]<]

Pero esa es una forma deficiente de hacer Unicode. Puedes usar los escapes `\u` (16 bits) o
`\U` (32 bits) para referirte a Unicode por el número de punto de código. La viñeta es `2022`
(hexadecimal) en Unicode, así que puedes hacer esto y obtener resultados más portables:

``` {.c}
printf("\u2022 Bullet 1\n");
printf("\u2022 Bullet 2\n");
printf("\u2022 Bullet 3\n");
```

Asegúrese de rellenar "u" con suficientes ceros a la izquierda para llegar a cuatro caracteres, y
"U" con suficientes ceros a la izquierda para llegar a ocho.

[i[`\u` Unicode escape]>]

Por ejemplo, esa viñeta podría hacerse con "U" y cuatro ceros a la izquierda:

``` {.c}
printf("\U00002022 Bullet 1\n");
```

[i[`\U` Unicode escape]>]

Pero, ¿quién tiene tiempo para ser tan verborreico?

[i[`\` backslash escape]>]
[i[Escape sequences]>]
