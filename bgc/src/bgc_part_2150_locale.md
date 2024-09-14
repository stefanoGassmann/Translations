<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Configuración regional e internacionalización

[i[Locale]<]

_La localización_ es el proceso de preparar tu aplicación para que funcione bien en distintas
localizaciones (o países).

Como sabrás, no todo el mundo utiliza el mismo carácter para los decimales o para los separadores
de miles... o para la moneda.

Estas localizaciones tienen nombres, y puedes seleccionar una para usarla. Por ejemplo,
una configuración regional de EE.UU. podría escribir un número como:

100,000.00

Mientras que en Brasil, lo mismo podría escribirse con las comas y los puntos decimales
intercambiados:

100.000,00

Así es más fácil escribir el código para que se adapte fácilmente a otras nacionalidades.

Bueno, más o menos. Resulta que C sólo tiene una configuración regional incorporada, y es
limitada. La especificación realmente deja mucha ambigüedad aquí; es difícil ser completamente
portable.

Pero haremos lo que podamos.

## Configuración rápida de la localización

Para estas llamadas, incluya [i[fichero de cabecera `locale.h`]] `<locale.h>`.

Hay básicamente una cosa que puedes hacer de forma portable aquí en términos de declarar
una localización específica. Esto es probablemente lo que quieres hacer si vas a hacer
algo de localización:

[i[`setlocale()` function]<]

``` {.c}
setlocale(LC_ALL, "");  // Utiliza la configuración regional
                        // de este entorno para todo
```

Usted querrá llamar a eso para que el programa se inicialice con su configuración regional actual.

Entrando en más detalles, hay una cosa más que puedes hacer y seguir siendo portable:

``` {.c}
setlocale(LC_ALL, "C");  // Utilizar la configuración regional C por defecto.
```

pero se ejecuta por defecto cada vez que se inicia el programa, por lo que no es necesario
que lo hagas tú mismo.

En la segunda cadena, puedes especificar cualquier configuración regional soportada
por tu sistema. Esto depende completamente del sistema, así que variará. En mi sistema,
puedo especificar esto:

``` {.c}
setlocale(LC_ALL, "en_US.UTF-8");  // ¡No portátil!
```

Y funcionará. Pero sólo es portable a sistemas que tengan exactamente el mismo nombre
para la misma localización, y no puedes garantizarlo.

Al pasar una cadena vacía (`""`) como segundo argumento, le estás diciendo a C: "Oye, averigua
cuál es la configuración regional actual en este sistema para que yo no tenga que decírtelo".


[i[`setlocale()` function]>]

## Obtener la configuración regional monetaria

[i[Locale-->money]<]

Porque mover papelitos verdes promete ser la clave de la felicidad^["Este planeta tiene -o más
bien tenía- un problema: la mayoría de las personas que viven en él son infelices durante
casi todo el tiempo. Se sugirieron muchas soluciones para este problema, pero la mayoría
de ellas tenían que ver con el movimiento de pequeños trozos de papel verde, lo cual era extraño
porque, en general, no eran los pequeños trozos de papel verde los que eran infelices." ---La Guía
del Autoestopista Galáctico, Douglas Adams], hablemos de la localización monetaria. Cuando
escribes código portable, tienes que saber qué escribir por dinero, ¿verdad? Ya sea
"$", "€", "¥", o "£".

[i[`localeconv()` function]<]

¿Cómo puedes escribir ese código sin volverte loco? Por suerte, una vez que llames a
`setlocale(LC_ALL, "")`, puedes buscarlas con una llamada a `localeconv()`:

``` {.c}
struct lconv *x = localeconv();
```

Esta función devuelve un puntero a una `struct lconv` estáticamente asignada que contiene
toda la información que estás buscando.

Estos son los campos de `struct lconv` y sus significados.

Primero, algunas convenciones. Un `_p_` significa "positivo", y `_n_` significa "negativo", y
`int_` significa "internacional". Aunque muchos de ellos son del tipo `char` o `char*`, la mayoría
(o las cadenas a las que apuntan) se tratan en realidad como enteros^[Recuerda que `char`
es sólo un entero del tamaño de un byte].

Antes de continuar, debes saber que `CHAR_MAX` (de `<limits.h>`) es el valor máximo que puede
contener un `char`. Y que muchos de los siguientes valores `char` lo usan para indicar
que el valor no está disponible en la localización dada.

|Campo | Descripción
|-----|-----------|
|`char *mon_decimal_point`|Carácter puntero decimal para dinero, por ejemplo `"."`.|
|`char *mon_thousands_sep`|Carácter separador de miles para dinero, por ejemplo `","`.|
|`char *mon_grouping`|Descripción de la agrupación por dinero (véase más abajo).|
|`char *positive_sign`|Signo positivo para el dinero, por ejemplo `"+"` o `""`.|
|`char *negative_sign`|Signo negativo para el dinero, por ejemplo `"-"`.|
|`char *currency_symbol`|Símbolo de moneda, por ejemplo `"$"`.|
|`char frac_digits`|Al imprimir importes monetarios, cuántos dígitos imprimir después del punto decimal, por ejemplo `2`.|
|`char p_cs_precedes`|`1` si el `símbolo_moneda` viene antes del valor de una cantidad monetaria no negativa, `0` si viene después.|
|`char n_cs_precedes`|`1` si el `símbolo_moneda` viene antes del valor para una cantidad monetaria negativa, `0` si viene después.|
|`char p_sep_by_space`|Determina la separación del `símbolo de moneda` del valor para importes no negativos (véase más abajo).|
|`char n_sep_by_space`|Determina la separación del `símbolo de moneda` del valor para los importes negativos (véase más abajo).|
|`char p_sign_posn`|Determina la posición de `positive_sign` para valores no negativos.|
|`char p_sign_posn`|Determina la posición de `positive_sign` para valores negativos.|
|`char *int_curr_symbol`|Símbolo de moneda internacional, por ejemplo `"USD"`.|
|`char int_frac_digits`|Valor internacional para `frac_digits`.|
|`char int_p_cs_precedes`|Valor internacional para `p_cs_precedes`.|
|`char int_n_cs_precedes`|Valor internacional para `n_cs_precedes`.|
|`char int_p_sep_by_space`|Valor internacional para `p_sep_by_space`.|
|`char int_n_sep_by_space`|Valor internacional para `n_sep_by_space`.|
|`char int_p_sign_posn`|Valor internacional para `p_sign_posn`.|
|`char int_n_sign_posn`|Valor internacional para `n_sign_posn`.|

[i[`localeconv()` function]>]

### Agrupación de dígitos monetarios {#monetary-digit-grouping}

[i[`localeconv()` function-->`mon_grouping`]<]

Vale, esto es un poco raro. `mon_grouping` es un `char*`, así que podrías pensar que es una
cadena. Pero en este caso, no, en realidad es un array de `char`s. Siempre debe terminar
en `0` o `CHAR_MAX`.

Estos valores describen cómo agrupar conjuntos de números en moneda a la _izquierda_ del decimal
(la parte del número entero).

Por ejemplo, podríamos tener:

``` {.default}
  2   1   0
 --- --- ---
$100,000,000.00
```

Se trata de grupos de tres. El grupo 0 (justo a la izquierda del decimal) tiene 3 dígitos.
El grupo 1 (el siguiente a la izquierda) tiene 3 dígitos, y el último también tiene 3.

Así que podríamos describir estos grupos, de la derecha (el decimal) a la izquierda
con un montón de valores enteros que representan los tamaños de los grupos:

``` {.default}
3 3 3
```

Y eso funcionaría para valores de hasta 100.000.000 de dólares.

Pero ¿y si tuviéramos más? Podríamos seguir añadiendo `3`s ...

``` {.default}
3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3
```

pero eso es una locura. Por suerte, podemos especificar `0` para indicar que se repite
el tamaño de grupo anterior:

``` {.default}
3 0
```

Lo que significa repetir cada 3. Eso manejaría $100, $1,000, $10,000, $10,000,000,
$100,000,000,000, y así sucesivamente.

Usted puede ir legítimamente loco con estos para indicar algunas agrupaciones extrañas.

Por ejemplo:

``` {.default}
4 3 2 1 0
```

indicaría:

``` {.default}
$1,0,0,0,0,00,000,0000.00
```

Otro valor que puede aparecer es `CHAR_MAX`. Indica que no se debe agrupar más, y puede aparecer
en cualquier parte de la matriz, incluido el primer valor.

``` {.default}
3 2 CHAR_MAX
```

indicaría:

``` {.default}
100000000,00,000.00
```

por ejemplo.

Y el simple hecho de tener `CHAR_MAX` en la primera posición del array te indicaría
que no iba a haber ningún tipo de agrupación.

[i[`localeconv()` function-->`mon_grouping`]>]

### Separadores y posición del cartel

[i[`localeconv()` function-->`sep_by_space`]<]

Todas las variantes de `sep_by_space` se ocupan del espaciado alrededor del signo monetario.
Los valores válidos son:

|Valor|Descripción
|:--:|------------|
|`0`|No hay espacio entre el símbolo de la moneda y el valor.|
|`1`|Separe el símbolo de moneda (y el signo, si existe) del valor con un espacio.|
|`2`|Separe el símbolo de signo del símbolo de moneda (si es adyacente) con un espacio; de lo contrario, separe el símbolo de signo del valor con un espacio.|

Las variantes de `sign_posn` vienen determinadas por los siguientes valores:

|Valor|Descripción|
|:--:|------------|
|`0`|Pon paréntesis alrededor del valor y del símbolo monetario.|
|`1`|Coloque el signo delante del símbolo monetario y del valor.|
|`2`|Poner el signo después del símbolo monetario y del valor.|
|`3`|Poner el signo directamente delante del símbolo de moneda|
|`4`|Coloque el signo directamente detrás del símbolo de moneda.|

[i[`localeconv()` function-->`sep_by_space`]>]
[i[Locale-->money]>]

### Ejemplos de valores

Cuando obtengo los valores en mi sistema, esto es lo que veo (cadena de agrupación mostrada como valores de bytes individuales):

``` {.c}
mon_decimal_point  = "."
mon_thousands_sep  = ","
mon_grouping       = 3 3 0
positive_sign      = ""
negative_sign      = "-"
currency_symbol    = "$"
frac_digits        = 2
p_cs_precedes      = 1
n_cs_precedes      = 1
p_sep_by_space     = 0
n_sep_by_space     = 0
p_sign_posn        = 1
n_sign_posn        = 1
int_curr_symbol    = "USD "
int_frac_digits    = 2
int_p_cs_precedes  = 1
int_n_cs_precedes  = 1
int_p_sep_by_space = 1
int_n_sep_by_space = 1
int_p_sign_posn    = 1
int_n_sign_posn    = 1
```

## Especificidades de localización

Observe cómo pasamos la macro `LC_ALL` a `setlocale()` anteriormente... esto indica que podría
haber alguna variante que le permita ser más preciso sobre qué _partes_ de la configuración
regional está configurando.

Echemos un vistazo a los valores que puede ver para estos:

[i[`setlocale()` function-->`LC_ALL` macro]]
[i[`setlocale()` function-->`LC_COLLATE` macro]]
[i[`setlocale()` function-->`LC_CTYPE` macro]]
[i[`setlocale()` function-->`LC_MONETARY` macro]]
[i[`setlocale()` function-->`LC_NUMERIC` macro]]
[i[`setlocale()` function-->`LC_TIME` macro]]

|Macro|Descripción|
|----|--------------|
|`LC_ALL`|Establece todo lo siguiente a la configuración regional dada.|
|`LC_COLLATE`|Controla el comportamiento de las funciones `strcoll()` y `strxfrm()`.|
|`LC_CTYPE`|Controla el comportamiento de las funciones de tratamiento de caracteres^[Excepto `isdigit()` e `isxdigit()`.]..|
|`LC_MONETARY`|Controla los valores devueltos por `localeconv()`.|
|`LC_NUMERIC`|Controla el punto decimal para la familia de funciones `printf()`.|
|`LC_TIME`|Controla el formato de hora de las funciones de impresión de fecha y hora `strftime()` y `wcsftime()`.|

Es bastante común ver [i[`setlocale()` function-->`LC_ALL` macro]] `LC_ALL`, pero, oye, al menos
tienes opciones.

También debo señalar que [i[`setlocale()` function-->`LC_CTYPE` macro]] `LC_CTYPE` es una
de las más importantes porque se relaciona con los caracteres anchos, una importante
caja de Pandora de la que hablaremos más adelante.
[i[Locale]>]
