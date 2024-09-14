<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Tipos II: ¡Muchos más tipos!

Estamos acostumbrados a los tipos `char`, `int` y `float`, pero ha llegado el momento
de pasar al siguiente nivel y ver qué más tenemos en el departamento de tipos.

## Enteros con y sin signo

[i[Types-->signed and unsigned]<]
Hasta ahora hemos utilizado `int` como un tipo _signed (signado)_, es decir, un valor que puede
ser negativo o positivo. Pero C también tiene tipos enteros _unsigned (sin signo)_
que sólo pueden contener números positivos.

Estos tipos van precedidos de la palabra clave [i[`unsigned` type]<]`unsigned`.

``` {.c}
int a; // con signo
signed int a; // con signo
signed a; // con signo, «abreviatura» de «int» o «signed int», poco frecuente
unsigned int b; // sin signo
unsigned c; // unsigned, abreviatura de «unsigned int».
```

¿Por qué? ¿Por qué decidiste que sólo querías contener números positivos?

Respuesta: puedes obtener números más grandes en una variable sin signo que en una con signo.

Pero, ¿por qué?

Puedes pensar que los números enteros están representados por un cierto número
de _bits_^[«Bit» es la abreviatura de _dígito binario_. El binario es otra forma
de representar números. En lugar de los dígitos 0-9 a los que estamos acostumbrados, son
los dígitos 0-1]. En mi ordenador, un `int` se representa con 64 bits.

Y cada permutación de bits que son `1` o `0` representa un número. Podemos decidir
cómo repartir estos números.

Con los números con signo, utilizamos (aproximadamente) la mitad de las permutaciones
para representar números negativos, y la otra mitad para representar números positivos.

Con números sin signo, usamos _todas_ las permutaciones para representar números positivos.

En mi ordenador con `int`s de 64 bits que utiliza el [flw[complemento a dos|Two%27s_complement]]
para representar números sin signo, tengo los siguientes límites en el rango de enteros:


|Tipo|Mínimo|Máximo|
|:-|-:|-:|
|`int`|`-9,223,372,036,854,775,808`|`9,223,372,036,854,775,807`|
|`unsigned int`|`0`|`18,446,744,073,709,551,615`|

Fíjate en que el mayor `unsigned int` positivo es aproximadamente el doble de grande
que el mayor `int` positivo. Así que puedes tener cierta flexibilidad.
[i[`unsigned` type]>]
[i[Types-->signed and unsigned]>]

## Tipos de caracteres

[i[Types-->character]<]
[i[`char` type]<]
¿Recuerdas `char`? ¿El tipo que podemos utilizar para contener un único carácter?

``` {.c}
char c = 'B';

printf("%c\n", c);  // "B"
```

Tengo una sorpresa para ti: en realidad es un número entero.

``` {.c}
char c = 'B';

// Cambia esto de %c a %d:
printf("%d\n", c);  // 66 (!!)
```

En el fondo, `char` no es más que un pequeño `int`, es decir, un entero que utiliza
un único byte de espacio, limitando su rango a...

Aquí la especificación C se pone un poco rara. Nos asegura que un `char` es un único
byte, es decir, `sizeof(char) == 1`. Pero entonces en C11 §3.6¶3 se sale de su camino
para decir:

> Un byte está compuesto por una secuencia contigua de bits, cuyo número está definido
> por la implementación.

Espera... ¿qué? Algunos de ustedes pueden estar acostumbrados a la noción de que un byte
es de 8 bits, ¿verdad? Quiero decir, eso es lo que es, ¿verdad? Y la respuesta es: «Casi
seguro»^[El término industrial para una secuencia de exactamente, indiscutiblemente 8 bits
es un _octeto_]. Pero C es un lenguaje antiguo, y las máquinas de antes tenían, digamos,
una opinión más _relajada_ sobre cuántos bits había en un byte. Y a lo largo de los años, C
ha conservado esta flexibilidad.

Pero asumiendo que tus bytes en C son de 8 bits, como lo son en prácticamente todas
las máquinas del mundo que verás, el rango de un `char` es...

[i[`unsigned char` type]<]
[i[`signed char` type]<]
---Así que antes de que pueda decírtelo, resulta que `char`s puede ser con o sin
signo dependiendo de tu compilador. A menos que lo especifiques explícitamente.

En muchos casos, sólo tener `char`s está bien porque no te importa el signo de los datos.
Pero si necesitas `char`s con signo o sin signo, _debes_ ser específico:

``` {.c}
char a; // Puede ser con o sin signo
signed char b; // Definitivamente con signo
unsigned char c; // Definitivamente sin signo
```

OK, ahora, finalmente, podemos averiguar el rango de números si asumimos que un `char` es
de 8 bits y su sistema utiliza la virtualmente universal representación de complemento a dos
para con signo y sin signo^[En general, f usted tiene un $n$ bit número de complemento a dos,
el rango con signo es $-2^{n-1}$ a $2^{n-1}-1$. Y el rango sin signo es de $0$ a $2^n-1$].

Así que, asumiendo esas limitaciones, por fin podemos calcular nuestros rangos:

|Tipo `char` |Mínimo|Máximo|
|:-|-:|-:|
|`signed char`|`-128`|`127`|
|`unsigned char`|`0`|`255`|

Y los rangos para `char` están definidos por la implementación.
[i[`unsigned char` type]>]
[i[`signed char` type]>]

A ver si lo entiendo. `char` es en realidad un número, así que ¿podemos hacer matemáticas
con él?

Sí. Sólo recuerda mantener las cosas dentro del rango de un `char`.
//Nota del traductor, esto es **extremadamente importante**, no lo olvides

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    char a = 10, b = 20;

    printf("%d\n", a + b);  // 30!
}
```

[i[`'` single quote]<]
¿Qué ocurre con los caracteres constantes entre comillas simples, como `'B'`? ¿Cómo puede
eso tener un valor numérico?

La especificación también es imprecisa en este caso, ya que C no está diseñado para
ejecutarse en un único tipo de sistema subyacente.

Pero asumamos por el momento que su juego de caracteres está basado en [flw[ASCII|ASCII]]para
al menos los primeros 128 caracteres. En ese caso, la constante de carácter se convertirá
en un `char` cuyo valor es el mismo que el valor ASCII del carácter.

Eso ha sido un trabalenguas. Pongamos un ejemplo:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    char a = 10;
    char b = 'B';  // Valor en ASCII 66

    printf("%d\n", a + b);  // 76!
}
```

Esto depende de su entorno de ejecución y del [flw[juego de caracteres utilizado | List_of 
information_system_character_sets]].
Uno de los conjuntos de caracteres más populares hoy en día es [flw[Unicode|Unicode]] (que es
un superconjunto de ASCII), por lo que para tus 0-9, A-Z, a-z y signos de puntuación básicos,
casi seguro que obtendrás los valores ASCII.

[i[`'` single quote]>]
[i[`char` type]>]
[i[Types-->character]>]

## Más tipos de enteros: `short`, `long`, `long long`

Hasta ahora hemos estado utilizando generalmente dos tipos enteros:

* `char`
* `int`

y recientemente hemos aprendido sobre las variantes sin signo de los tipos enteros. Y
aprendimos que `char` era secretamente un pequeño `int` disfrazado. Así que sabemos que
los `int`s pueden venir en múltiples tamaños de bit.

Pero hay un par de tipos enteros más que deberíamos ver, y los valores _mínimo_ _minímo_ y _máximo_
que pueden contener.

Sí, he dicho «mínimo» dos veces. La especificación dice que estos tipos contendrán números
de _al menos_ estos tamaños, así que tu implementación puede ser diferente. El fichero de
cabecera `<limits.h>` define macros que contienen los valores enteros mínimo y máximo; confíe
en ello para estar seguro, y _nunca codifique o asuma estos valores_.
[i[`short` type]<]
[i[`long` type]<]
[i[`long long` type]<]
Estos tipos adicionales son `short int`, `long int` y `long long int`. Normalmente, cuando
se utilizan estos tipos, los desarrolladores de C omiten la parte `int` (por ejemplo,
`long long`), y el compilador no tiene ningún problema.

``` {.c}
// Estas dos líneas son equivalentes:
long long int x;
long long x;

// Y estos también:
short int x;
short x;
```

Veamos los tipos y tamaños de datos enteros en orden ascendente, agrupados por signatura.

|Tipo|Bytes mínimos|Valor mínimo|Valor máximo|
|:-|-:|-:|-:|
|`char`|1|-127 or 0|127 or 255^[Depende de si el valor por defecto de `char` es `signed char` o `unsigned char`].|
|`signed char`|1|-127|127|
|`short`|2|-32767|32767|
|`int`|2|-32767|32767|
|`long`|4|-2147483647|2147483647|
|`long long`|8|-9223372036854775807|9223372036854775807|
|`unsigned char`|1|0|255|
|`unsigned short`|2|0|65535|
|`unsigned int`|2|0|65535|
|`unsigned long`|4|0|4294967295|
|`unsigned long long`|8|0|18446744073709551615|

No existe el tipo `long long long`. No puedes seguir añadiendo `long`s así. No seas tonto.

> Los aficionados a los complementos a dos habrán notado algo raro en esos números.
> ¿Por qué, por ejemplo, el `signed char` se detiene en -127 en lugar de -128? 
> Recuerde: estos son sólo los mínimos requeridos por la especificación.
> Algunas representaciones numéricas (como [flw[signo y magnitud|Signed_number_representations#Signed_magnitude_representation]]) 
>tienen un máximo de ±127.

Ejecutemos la misma tabla en mi sistema de 64 bits y complemento a dos y veamos qué sale:

|Tipo|Mis Bytes|Valor mínimo|Valor máximo|
|:-|-:|-:|-:|
|`char`|1|-128|127^[Mi `char` está con signo.]|
|`signed char`|1|-128|127|
|`short`|2|-32768|32767|
|`int`|4|-2147483648|2147483647|
|`long`|8|-9223372036854775808|9223372036854775807|
|`long long`|8|-9223372036854775808|9223372036854775807|
|`unsigned char`|1|0|255|
|`unsigned short`|2|0|65535|
|`unsigned int`|4|0|4294967295|
|`unsigned long`|8|0|18446744073709551615|
|`unsigned long long`|8|0|18446744073709551615|

Eso es un poco más sensato, pero podemos ver cómo mi sistema tiene límites mayores
que los mínimos de la especificación.

[Entonces, ¿qué son las macros en `<limits.h>`?]{#limits-macros}

|Tipo|Macro mínima|Macro máxima|
|:-|:-|:-|
|`char`|`CHAR_MIN`|`CHAR_MAX`|
|`signed char`|`SCHAR_MIN`|`SCHAR_MAX`|
|`short`|`SHRT_MIN`|`SHRT_MAX`|
|`int`|`INT_MIN`|`INT_MAX`|
|`long`|`LONG_MIN`|`LONG_MAX`|
|`long long`|`LLONG_MIN`|`LLONG_MAX`|
|`unsigned char`|`0`|`UCHAR_MAX`|
|`unsigned short`|`0`|`USHRT_MAX`|
|`unsigned int`|`0`|`UINT_MAX`|
|`unsigned long`|`0`|`ULONG_MAX`|
|`unsigned long long`|`0`|`ULLONG_MAX`|

Fíjate que hay una forma oculta de determinar si un sistema utiliza `char`s con signo
o sin signo. Si `CHAR_MAX == UCHAR_MAX`, debe ser sin signo.

Fíjate también en que no hay macro mínima para las variantes «sin signo»: son simplemente «0».
[i[`short` type]>]
[i[`long` type]>]
[i[`long long` type]>]

## Más Float: `double` y `long double`.

Veamos qué dice la especificación sobre los números de coma flotante en
§5.2.4.2.2¶1-2:

>Los siguientes parámetros se utilizan para definir el modelo para cada
>tipo de punto flotante:
>
> |Parametro|Definición|
> |:-|:-|
> |$s$|signo ($\pm1$)|
> |$b$|base o radix de la representación del exponente (un entero $> 1$)|
> |$e$|exponente (un número entero entre un mínimo $e_{min}$ y un máximo $e_{max}$)|
> |$p$|precisión (el número de dígitos de base-$b$ en el significando)|
> |$f_k$|enteros no negativos menores que $b$ (los dígitos significantes)|
>
> Un _número de punto flotante_ ($x$) se define mediante el siguiente modelo:
>
>> $x=sb^e\sum\limits_{k=1}^p f_kb^{-k},$\ \ \ \ $e_{min}\le e\le e_{max}$


Espero que eso te lo haya aclarado.

De acuerdo. Retrocedamos un poco y veamos qué es práctico.

Nota: nos referimos a un montón de macros en esta sección. Se pueden encontrar
en la cabecera `<float.h>`.

Los números en coma flotante se codifican en una secuencia específica de bits
([flw[Formato IEEE-754 |IEEE_754]] es tremendamente popular) en bytes.

Profundizando un poco más, el número se representa básicamente como el _significando_ (que es
la parte numérica--los dígitos significativos propiamente dichos, también llamados a veces
la _mantisa_) y el _exponente_, que es a qué potencia elevar los dígitos. Recordemos que
un exponente negativo puede hacer que un número sea más pequeño.

Imaginemos que usamos $10$ como número a elevar por un exponente. Podríamos representar
los siguientes números utilizando un significando de $12345$, y exponentes de $-3$, $4$, y $0$
para codificar los siguientes valores en coma flotante:

$12345\times10^{-3}=12.345$

$12345\times10^4=123450000$

$12345\times10^0=12345$

Para todos esos números, el significante sigue siendo el mismo. La única diferencia
es el exponente.

En tu máquina, la base para el exponente es probablemente $2$, no $10$, ya que
a los ordenadores les gusta el binario. Puedes comprobarlo imprimiendo la macro `FLT_RADIX`.

Así que tenemos un número que está representado por un número de bytes, codificados
de alguna manera. Como hay un número limitado de patrones de bits, se puede representar
un número limitado de números en coma flotante.

Pero más concretamente, sólo se puede representar con precisión un cierto número
de dígitos decimales significativos.

¿Cómo conseguir más? Utilizando tipos de datos más grandes.

Y tenemos un par de ellos. Ya conocemos `float`, pero para más precisión tenemos `double`.
Y para aún más precisión, tenemos `long double` (no relacionado con `long int` excepto
por el nombre).

La especificación no especifica cuántos bytes de almacenamiento debe ocupar cada tipo, pero
en mi sistema podemos ver los incrementos de tamaño relativos:

[i[`double` type]<]
[i[`long double` type]<]

|Tipo|`sizeof`|
|:-|-:|
|`float`|4|
|`double`|8|
|`long double`|16|

Así que cada uno de los tipos (en mi sistema) utiliza esos bits adicionales para obtener
más precisión.

¿Pero de cuánta precisión estamos hablando? ¿Cuántos números decimales pueden
ser representados por estos valores?

Bueno, C nos proporciona un montón de macros en `<float.h>` para ayudarnos a averiguarlo.

La cosa se complica un poco si estás usando un sistema de base-2 (binario) para almacenar
los números (que es prácticamente todo el mundo en el planeta, probablemente incluyéndote
a ti), pero ten paciencia conmigo mientras lo resolvemos.
[i[`double` type]>]
[i[`long double` type]>]

### ¿Cuántas cifras decimales?

[i[Significant digits]<]
La pregunta del millón es: «¿Cuántos dígitos decimales significativos puedo almacenar
en un determinado tipo de coma flotante para que me salga el mismo número decimal
al imprimirlo?».

El número de dígitos decimales que puedes almacenar en un tipo de coma flotante y obtener
con seguridad el mismo número al imprimirlo viene dado por estas macros:

[i[`FLT_DIG` macro]<]
[i[`DBL_DIG` macro]<]
[i[`LDBL_DIG` macro]<]

|Tipo|Dígitos decimales que puede almacenar|Mínimo|Mi sistema|
|:-|-:|-:|
|`float`|`FLT_DIG`|6|6|
|`double`|`DBL_DIG`|10|15|
|`long double`|`LDBL_DIG`|10|18|

[i[`DBL_DIG` macro]>]
[i[`LDBL_DIG` macro]>]

En mi sistema, `FLT_DIG` es 6, así que puedo estar seguro de que si imprimo un `float`
de 6 dígitos, obtendré lo mismo de vuelta. (Podrían ser más dígitos---algunos números
volverán correctamente con más dígitos. Pero sin duda me devolverá 6).

Por ejemplo, imprimiendo `float`s siguiendo este patrón de dígitos crecientes,
aparentemente llegamos a 8 dígitos antes de que algo vaya mal, pero después de eso
volvemos a 7 dígitos correctos.

``` {.default}
0.12345
0.123456
0.1234567
0.12345678
0.123456791  <-- Las cosas empiezan a ir mal
0.1234567910
```

Hagamos otra demostración. En este código tendremos dos `float`s que contendrán
números que tienen `FLT_DIG` dígitos decimales significativos^[Este programa se ejecuta
como indican sus comentarios en un sistema con `FLT_DIG` de `6` que utiliza números
en coma flotante IEEE-754 base-2. De lo contrario podrías obtener una salida diferente].
Luego los sumamos, para lo que
deberían ser 12 dígitos decimales significativos. Pero eso es más de lo que podemos
almacenar en un `float` y recuperar correctamente como una cadena---así que vemos
que cuando lo imprimimos, las cosas empiezan a ir mal después del 7º dígito significativo.


``` {.c .numberLines}
#include <stdio.h>
#include <float.h>

int main(void)
{
    // Ambos números tienen 6 dígitos significativos, por lo que pueden ser
    // almacenados con precisión en un float:

    float f = 3.14159f;
    float g = 0.00000265358f;

    printf("%.5f\n", f);   // 3.14159       -- Correcto!
    printf("%.11f\n", g);  // 0.00000265358 -- Correcto!

    // Ahora súmalos
    f += g;                // 3.14159265358 es lo que f _debería_ ser

    printf("%.11f\n", f);  // 3.14159274101 -- ¡Mal!
}
```

(El código anterior tiene una `f` después de las constantes numéricas---esto indica
que la constante es de tipo `float`, en oposición al valor por defecto de `double`.
Más sobre esto más adelante).

Recuerde que `FLT_DIG` es el número seguro de dígitos que puede almacenar
en un `float` y recuperar correctamente.

A veces puedes sacar uno o dos más. Pero otras veces sólo recuperarás dígitos `FLT_DIG`.
Lo más seguro: si almacenas cualquier número de dígitos hasta e incluyendo `FLT_DIG`
en un `float`, seguro que los recuperas correctamente.

Así que ésa es la historia de `FLT_DIG`. Fin.
[i[`FLT_DIG` macro]>]

...¿O no?

### Conversión a decimal y viceversa

Pero almacenar un número de base 10 en un número de coma flotante y recuperarlo
es sólo la mitad de la historia.

Resulta que los números de coma flotante pueden codificar números que requieren más decimales
para imprimirse completamente. Lo que ocurre es que tu número decimal grande puede no
corresponder a uno de esos números.

Es decir, cuando miras los números de coma flotante de uno a otro, hay un hueco. Si
intentas codificar un número decimal en ese hueco, usará el número de coma flotante
más cercano. Por eso sólo puedes codificar `FLT_DIG` para un `float`.

¿Pero qué pasa con los números de coma flotante que _no_ están en el hueco? ¿Cuántos
lugares necesita para imprimirlos con precisión?

Otra forma de formular esta pregunta es, para cualquier número en coma flotante,
¿cuántos dígitos decimales tengo que conservar si quiero volver a convertir el número
decimal en un número idéntico en coma flotante? Es decir, ¿cuántos dígitos tengo que
imprimir en base 10 para recuperar **todos** los dígitos en base 2 del número original?

A veces pueden ser sólo unos pocos. Pero para estar seguro, querrás convertir a decimal
con un cierto número seguro de decimales. Ese número está codificado en las siguientes macros:

[i[`FLT_DECMIAL_DIG` macro]<]
[i[`DBL_DECMIAL_DIG` macro]<]
[i[`LDBL_DECMIAL_DIG` macro]<]
[i[`DECMIAL_DIG` macro]<]

|Macro|Descripción|
|-----------|---------------------------------------------------|
|`FLT_DECIMAL_DIG`|Número de dígitos decimales codificados en un `float`.|
|`DBL_DECIMAL_DIG`|Número de dígitos decimales codificados en un `double`.|
|`LDBL_DECIMAL_DIG`|Número de dígitos decimales codificados en un `long double`.|
|`DECIMAL_DIG`|Igual que la codificación más amplia, `LDBL_DECIMAL_DIG`.|


[i[`LDBL_DECMIAL_DIG` macro]>]
[i[`DECMIAL_DIG` macro]>]

Veamos un ejemplo en el que `DBL_DIG` es 15 (por lo que es todo lo que podemos
tener en una constante), pero `DBL_DECIMAL_DIG` es 17 (por lo que tenemos que convertir
a 17 números decimales para conservar todos los bits del `double` original).

Asignemos el número de 15 dígitos significativos `0.123456789012345` a `x`, y asignemos
el número de 1 dígito significativo `0.0000000000000006` a `y`.

``` {.default}
x es exactamente: 0.12345678901234500    Impreso con 17 decimales
y es exactamente: 0.00000000000000060
```

Pero sumémoslos. Esto debería dar `0.1234567890123456`, pero es más que `DBL_DIG`,
así que podrían pasar cosas raras... veamos:

``` {.default}
x + y no es del todo correcto: 0.12345678901234559    ¡Debería terminar en 4560!
```

Eso nos pasa por imprimir más que `DBL_DIG`, ¿no? Pero fíjate... ¡ese número de
arriba es exactamente representable tal cual!

Si asignamos `0.12345678901234559` (17 dígitos) a `z` y lo imprimimos, obtenemos:

``` {.default}
z es exactamente: 0.12345678901234559   ¡17 dígitos correctos! ¡Más que DBL_DIG!
```

Si hubiéramos truncado `z` a 15 dígitos, no habría sido el mismo número. Por eso,
para conservar todos los bits de un `doble`, necesitamos `DBL_DECIMAL_DIG` y no sólo
el menor `DBL_DIG`.

[i[`DBL_DECMIAL_DIG` macro]>]

Dicho esto, está claro que cuando estamos jugando con números decimales en general, no es
seguro imprimir más de [i[`FLT_DIG` macro]]`FLT_DIG`, [i[`DBL_DIG` macro]]`DBL_DIG`, o
[i[`LDBL_DIG` macro]]`LDBL_DIG` dígitos para ser sensato en relación con los números
originales de base 10 y cualquier matemática posterior.

Pero cuando convierta de `float` a una representación decimal y _de vuelta_ a `float`,
use definitivamente `FLT_DECIMAL_DIG` para hacerlo, de forma que todos los bits se
conserven exactamente. [i[`FLT_DECMIAL_DIG` macro]>]

[i[Significant digits]>]

## Tipos numéricos constantes

Cuando escribes un número constante, como `1234`, tiene un tipo. Pero, ¿de qué tipo es?
Veamos cómo decide C qué tipo es la constante, y cómo forzarle a elegir un tipo específico.

### Hexadecimal y octal

Además de los viejos decimales como los que cocía la abuela, C también admite
constantes de diferentes bases.

[i[`0x` hexadecimal]<]

Si encabeza un número con `0x`, se lee como un número hexadecimal:

``` {.c}
int a = 0x1A2B;   // Hexadecimal
int b = 0x1a2b;   // Las mayúsculas y minúsculas
                  // no importan para los dígitos hexadecimales

printf("%x", a);  // Imprime un número hexadecimal, «1a2b»
```

[i[`0x` hexadecimal]>]


[i[`0` octal]<]
Si precede un número con un `0`, se lee como un número octal:

``` {.c}
int a = 012;

printf("%o\n", a);  // Imprime un número octal, «12»
```

Esto es especialmente problemático para los programadores principiantes que tratan
de rellenar los números decimales a la izquierda con «0» para alinear las cosas bien
y bonito, cambiando inadvertidamente la base del número:

``` {.c}
int x = 11111;  // Decimal 11111
int y = 00111;  // Decimal 73 (Octal 111)
int z = 01111;  // Decimal 585 (Octal 1111)
```

[i[`0` octal]>]

#### Nota sobre el binario

[i[`0b` binary]<]

Una extensión no oficial^[Realmente me sorprende que C no tenga esto en la especificación
todavía. En el documento C99 Rationale, escriben: «Una propuesta para añadir constantes
binarias fue rechazada por falta de precedentes y utilidad insuficiente». Lo que parece
una tontería a la luz de algunas de las otras características que han incluido. Apuesto a que
una de las próximas versiones lo tiene.] en muchos compiladores de C permite representar
un número binario con un prefijo `0b`:

``` {.c}
int x = 0b101010;    // Número binario 101010

printf("%d\n", x);   // Imprime 42 en decimal
```

No existe un especificador de formato `printf()` para imprimir un número binario.
Hay que hacerlo carácter a carácter con operadores bit a bit.

[i[`0b` binary]>]

### Constantes enteras

[i[Integer constants]<]

Puedes forzar que un entero constante sea de un tipo determinado añadiéndole
un sufijo que indique el tipo.

Haremos algunas asignaciones para demostrarlo, pero la mayoría de los desarrolladores
omiten los sufijos a menos que sea necesario para ser precisos. El compilador
es bastante bueno asegurándose de que los tipos son compatibles.

[i[`U` unsigned constant]<]
[i[`L` long constant]<]
[i[`LL` long long constant]<]
[i[`UL` unsigned long constant]<]
[i[`ULL` unsigned long long constant]<]

``` {.c}
int           x = 1234;
long int      x = 1234L;
long long int x = 1234LL

unsigned int           x = 1234U;
unsigned long int      x = 1234UL;
unsigned long long int x = 1234ULL;
```

El sufijo puede ser mayúscula o minúscula. Y la `U` y la `L` o `LL` pueden aparecer 
indistintamente en primer lugar.

|Tipo|Sufijo|
|:-|:-|
|`int`|Sin sufijo|
|`long int`|`L`|
|`long long int`|`LL`|
|`unsigned int`|`U`|
|`unsigned long int`|`UL`|
|`unsigned long long int`|`ULL`|

En la tabla mencioné que «sin sufijo» significa `int`... pero en realidad
es más complejo que eso.

Entonces, ¿qué sucede cuando usted tiene un número sin sufijo como:

``` {.c}
int x = 1234;
```

¿Qué tipo es?

Lo que C hace generalmente es elegir el tipo más pequeño a partir de `int` que pueda
contener el valor.

Pero específicamente, eso depende de la base del número (decimal, hexadecimal, o octal).

La especificación tiene una gran tabla que indica qué tipo se utiliza para cada valor
no fijo. De hecho, voy a copiarla íntegramente aquí.

C11 §6.4.4.1¶5 dice: «El tipo de una constante entera es el primero de la lista 
correspondiente en la que se puede representar su valor».

Y luego pasa a mostrar esta tabla:

+----------------+------------------------+-------------------------+
|Sufijo          |Constante decimal       |Constante/               |
|                |                        |Octal o Hexadecimal      |
+:===============+:=======================+:========================+
|Sin sufijo      |`int`\                  |`int`\                   |
|                |`long int`              |`unsigned int`\          |
|                |                        |`long int`\              |
|                |                        |`unsigned long int`\     |
|                |                        |`long long int`\         |
|                |                        |`unsigned long long int`\|
|                |                        |                         |
+----------------+------------------------+-------------------------+
|`u` o  `U`      |`unsigned int`\         |`unsigned int`\          |
|                |`unsigned long int`\    |`unsigned long int`\     |
|                |`unsigned long long int`|`unsigned long long int`\|
|                |                        |                         |
+----------------+------------------------+-------------------------+
|`l` o  `L`      |`long int`\             |`long int`\              |
|                |`long long int`         |`unsigned long int`\     |
|                |                        |`long long int`\         |
|                |                        |`unsigned long long int`\|
|                |                        |                         |
+----------------+------------------------+-------------------------+
|Ambos `u` o `U`\|`unsigned long int`\    |`unsigned long int`\     |
|y `l` o `L`     |`unsigned long long int`|`unsigned long long int`\|
|                |                        |                         |
+----------------+------------------------+-------------------------+
|`ll` o  `LL`    |`long long int`         |`long long int`\         |
|                |                        |`unsigned long long int`\|
|                |                        |                         |
+----------------+------------------------+-------------------------+
|Ambos `u` o `U`\|`unsigned long long int`|`unsigned long long int` |
|y `ll` o `LL`   |                        |                         |
+----------------+------------------------+-------------------------+

[i[`L` long constant]>]
[i[`LL` long long constant]>]
[i[`UL` unsigned long constant]>]
[i[`ULL` unsigned long long constant]>]

Lo que esto quiere decir es que, por ejemplo, si especificas un número como
`123456789U`, primero C verá si puede ser `unsigned int`. Si no cabe ahí, probará
con `unsigned long int`. Y luego `unsigned long long int`. Usará el tipo más pequeño
que pueda contener el número.
[i[`U` unsigned constant]>]

[i[Integer constants]>]

### Constantes en coma flotante

[i[Floating point constants]<]

Uno pensaría que una constante en coma flotante como `1.23` tendría un tipo por defecto
`float`, ¿verdad?

¡Sorpresa! ¡Resulta que los números de coma flotante sin sufijo son del tipo `double`!
¡Feliz cumpleaños atrasado!

[i[`F` float constant]<]
[i[`L` long double constant]<]

Puede forzar que sea de tipo `float` añadiendo una `f` (o `F`---no distingue mayúsculas
de minúsculas). Puedes forzar que sea del tipo `long double` añadiendo `l` (o `L`).

|Tipo|Sufijo|
|:-|:-|
|`float`|`F`|
|`double`|None|
|`long double`|`L`|

Por ejemplo:

``` {.c}
float x       = 3.14f;
double x      = 3.14;
long double x = 3.14L;
```

[i[`F` float constant]>]
[i[`L` long double constant]>]

Todo este tiempo, sin embargo, hemos estado haciendo esto, ¿verdad?

``` {.c}
float x = 3.14;
```

¿No es la izquierda un `float` y la derecha un `double`? Sí. Pero C es bastante bueno
con las conversiones numéricas automáticas, así que es más común tener una constante
de coma flotante fijada que no fijada. Más adelante hablaremos de ello.

[i[Floating point constants]>]

#### Notación científica

[i[Scientific notation]<]

¿Recuerdas que antes hablamos de cómo se puede representar un número en coma flotante
mediante un significando, una base y un exponente?

Bueno, hay una forma común de escribir un número de este tipo, que se muestra aquí
seguido de su equivalente más reconocible, que es lo que obtienes
cuando ejecutas las matemáticas:

$1.2345\times10^3 = 1234.5$

Escribir números de la forma $s\times b^e$ se denomina [flw[_notación_científica_|
Scientific_notation]]. En C, se escriben utilizando la «notación E», por lo que
son equivalentes:

|Notación científica|Notación E|
|:-|:-|
|$1.2345\times10^{-3}=0.0012345$|`1.2345e-3`|
|$1.2345\times10^8=123450000$|`1.2345e+8`|

Puede imprimir un número en esta notación con `%e`:

``` {.c}
printf("%e\n", 123456.0);  // Impresiones 1,234560e+05
```

Un par de datos curiosos sobre la notación científica:

* No tienes que escribirlos con un solo dígito antes del punto decimal. 
Cualquier número de cifras puede ir delante.

  ``` {.c}
  double x = 123.456e+3;  // 123456
  ```

 Sin embargo, al imprimirlo, cambiará el exponente para que haya sólo un dígito
delante del punto decimal.

* El más se puede dejar fuera del exponente, ya que es por defecto, pero esto es poco común
en la práctica por lo que he visto.

  ``` {.c}
  1.2345e10 == 1.2345e+10
  ```
* Puede aplicar los sufijos `F` o `L` a las constantes de anotación E:

  ``` {.c}
  1.2345e10F
  1.2345e10L
  ```

[i[Scientific notation]>]

#### Constantes hexadecimales en coma flotante

[i[Hex floating point constants]<]

Pero espera, ¡todavía hay que flotar más!

Resulta que también existen constantes hexadecimales de coma flotante.

Funcionan de forma similar a los números decimales en coma flotante, pero empiezan
por «0x», igual que los números enteros.

El truco es que _debes_ especificar un exponente, y este exponente produce una potencia
de 2. Es decir: $2^x$.

Y entonces se usa una `p` en lugar de una `e` al escribir el número:

Así que `0xa.1p3` es $10.0625\times2^3 == 80.5$.

Cuando usamos constantes hexadecimales en coma flotante, 
Podemos imprimir notación científica hexadecimal con `%a`:

``` {.c}
double x = 0xa.1p3;

printf("%a\n", x);  // 0x1.42p+6
printf("%f\n", x);  // 80.500000
```

[i[Hex floating point constants]>]

