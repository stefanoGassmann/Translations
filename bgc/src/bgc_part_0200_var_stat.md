<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Variables y Declaraciones

> _"¿Para hacer un mundo se necesitan de todo tipo de personas, ¿no es así, Padre?"_ \
> _"Así es, hijo mío, así es."_
>
> ---El capitán pirata Thomas Bartholomew Red al Padre, Piratas

Puede haber muchas cosas en un programa en C.

Sí.

Y por varias razones, será más fácil para todos nosotros si clasificamos algunos de los tipos de cosas que puedes encontrar en un programa, para que podamos ser claros sobre lo que estamos hablando.


## Variables

[i[Variables]<] Se dice que "las variables contienen valores". Pero otra manera de pensarlo
es que una variable es un nombre legible por humanos que se refiere a algún dato en la memoria.

Vamos a tomarnos un momento para echar un vistazo a los punteros. No te preocupes por esto.

Puedes pensar en la memoria como un gran array de bytes^[Un "byte" es típicamente un número 
binario de 8 bits. Piensa en ello como un entero que solo puede contener valores del 0 al 255, 
inclusive. Técnicamente, C permite que los bytes sean de cualquier número de bits y si quieres 
referirte inequívocamente a un número de 8 bits, deberías usar el término _octeto_. Pero los 
programadores asumirán que te refieres a 8 bits cuando dices "byte" a menos que especifiques 
lo contrario.]. Los datos se almacenan en este "array"^[Estoy simplificando mucho cómo 
funciona la memoria moderna aquí. Pero el modelo mental funciona, así que por favor 
perdóname.]. Si un número es más grande que un solo byte, se almacena en múltiples bytes. 
Debido a que la memoria es como un array, cada byte de memoria puede ser referido por su 
índice. Este índice en la memoria también se llama una _dirección_, o una _ubicación_, o un _
puntero_.

Cuando tienes una variable en C, el valor de esa variable está en la memoria en _algún lugar_, 
en alguna dirección. Por supuesto. Después de todo, ¿dónde más estaría? Pero es un dolor 
referirse a un valor por su dirección numérica, así que le damos un nombre en su lugar, y eso 
es lo que es una variable.

La razón por la que menciono todo esto es doble:

1. Va a hacer que sea más fácil entender las variables de puntero más adelante:
¡son variables que contienen la dirección de otras variables!
2. También va a hacer que sea más fácil entender los punteros más adelante.

Así que una variable es un nombre para algunos datos que están almacenados en la memoria en 
alguna dirección.

### Nombres de las variables

[i[Variables]<] Puedes usar cualquier carácter en el rango 0-9, A-Z, a-z,
y guión bajo para los nombres de variables, con las siguientes reglas:

* No puedes empezar una variable con un dígito del 0-9.
* No puedes empezar un nombre de variable con dos guiones bajos.
* No puedes empezar un nombre de variable con un guión bajo seguido
de una letra mayúscula de la A-Z.

Para Unicode, simplemente pruébalo. Hay algunas reglas en la especificación en §D.2 que
hablan sobre qué rangos de puntos de código Unicode están permitidos en qué partes de los
identificadores, pero eso es demasiado para escribir aquí y probablemente sea algo en lo
que nunca tendrás que pensar de todas formas.[i[Variables]>]

### Tipos de variables

[i[Tipos]] Dependiendo de los lenguajes que ya tengas en tu repertorio, puedes estar
familiarizado o no con la idea de los tipos. Pero C es bastante estricto con ellos, así
que deberíamos hacer un repaso.

Algunos ejemplos de tipos, de los más básicos:

[i[`int` type]][i[`float` type]][i[`char` type]][i[`char *` type]]



|Tipo|Ejemplo|Tipo en C|
|:---|------:|:-----|
|Entero|`3490`|`int`|
|Punto flotante|`3.14159`|`float`^[Estoy siendo un poco impreciso aquí. Técnicamente, `3.14159` es del tipo `double`, pero aún no hemos llegado allí y quiero que asocies `float` con "Punto Flotante", y C convertirá ese tipo felizmente en un `float`. En resumen, no te preocupes por ello hasta más adelante.]|
|Caracter (uno solo)|`'c'`|`char`|
|Texto|`"Hola, mundo!"`|`char *`^[Lee esto como "puntero a un char" o "char pointer". "Char" por carácter. Aunque no puedo encontrar un estudio, parece anecdóticamente que la mayoría de las personas pronuncian esto como "char", una minoría dice "car", y algunos pocos dicen "care". Hablaremos más sobre los punteros más adelante.]|

C hace un esfuerzo por convertir automáticamente entre la mayoría de los tipos numéricos cuando se lo pides, pero, aparte de eso, todas las conversiones son manuales, en particular entre cadenas y números.

Casi todos los tipos en C son variantes de estos tipos básicos.

Antes de poder usar una variable, debes _declarar_ esa variable y decirle a C qué tipo de
datos contiene. Una vez declarada, el tipo de variable no puede cambiarse más tarde durante
la ejecución. Lo que estableces es lo que es, hasta que salga de alcance y sea reabsorbida
en el universo.

Tomemos nuestro código anterior de "Hola, mundo" y agreguemos un par de variables a él:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int i;    // Almacena enteros con signo, por ejemplo, -3, -2, 0, 1, 10.
    float f;  // Almacena números de punto flotante con signo, por ejemplo, -3.1416.

    printf("Hello, World!\n");  // Ah, bendita familiaridad
}
```

¡Listo! Hemos declarado un par de variables. Aún no las hemos usado y ambas
están sin inicializar. Una contiene un número entero y la otra contiene un número
de punto flotante (un número real, si tienes conocimientos de matemáticas).

[i[Variables-->no inicializadas]] Las variables no inicializadas tienen un valor 
indeterminado^[Coloquialmente, decimos que tienen valores "aleatorios", pero no son realmente---ni siquiera pseudo-realmente---números aleatorios.]. Deben ser inicializadas
o de lo contrario debes asumir que contienen algún número absurdo.

> Este es uno de los puntos donde C puede "atraparte". En mi experiencia,
> la mayor parte del tiempo, el valor indeterminado es cero... ¡pero puede
> variar de ejecución en ejecución! Nunca asumas que el valor será cero, incluso
> si ves que lo es. _Siempre_ inicializa explícitamente las variables a algún valor
> antes de usarlas^[Esto no es estrictamente 100% cierto. Cuando aprendamos sobre la
> duración de almacenamiento estática, descubrirás que algunas variables se inicializan
> automáticamente a cero. Pero lo seguro es siempre inicializarlas.].

¿Qué es esto? ¿Quieres almacenar algunos números en esas variables? ¡Locura!

Vamos a hacer eso ahora mismo:
[i[`=` assignment operator]]

``` {.c .numberLines}
int main(void)
{
    int i;

    i = 2; // Asigna el valor 2 dentro de la variable i

    printf("Hello, World!\n");
}
```

Perfecto. Hemos almacenado un valor. Vamos a imprimirlo.

[i[`printf()` function]<]Lo vamos a hacer pasando dos argumentos asombrosos a la función
`printf()`. El primer argumento es una cadena que describe qué imprimir y cómo imprimirlo 
(llamado _cadena de formato_ [_format string_]), y el segundo es el valor a imprimir, es decir,
lo que sea que esté en la variable `i`.

`printf()` busca a través de la cadena de formato en busca de diversas secuencias especiales
que comienzan con un signo de porcentaje (`%`) y que le indican qué imprimir. Por ejemplo,
si encuentra `%d`, busca el siguiente parámetro que se le pasó y lo imprime como un entero.
Si encuentra `%s`, imprime el valor como un flotante. Si encuentra `%s`, imprime una cadena.

De esta manera, podemos imprimir el valor de varios tipos de la siguiente manera:

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int i = 2;
    float f = 3.14;
    char *s = "Hello, world!";  // char * ("Puntero a caracter") es del tipo String
    
    printf("%s  i = %d y f = %f!\n", s, i, f);
}
```

Y la salida será:

``` {.default}
Hello, world!  i = 2 y f = 3.14!
```

De esta manera, `printf()` podría ser similar a varios tipos de cadenas de formato 
o cadenas parametrizadas en otros lenguajes con los que estás familiarizado.
[i[`printf()` function]>]

### Tipo booleano

[i[Boolean types]<]¿C tiene tipos booleanos, verdadero o falso?

`1`!

Históricamente, C no tenía un tipo booleano, y algunos podrían argumentar
que todavía no lo tiene.

En C, `0` significa "falso", y cualquier valor no-cero significa "verdadero".

Entonces `1` es verdadero. Y `-37` es verdadero. Y `0` es falso.

Puedes simplemente declarar tipos booleanos como `int`:

``` {.c}
int x = 1;

if (x) {
    printf("x es verdadero!\n");
}
```

Si incluyes `#include <stdbool.h>`[i[`stdbool.h` header file]], también obtienes acceso
a algunos nombres simbólicos que podrían hacer que las cosas parezcan más familiares, específicamente un tipo `bool`[i[`bool` type]] y los valores `true`[i[`true` value]] y `false`[i[`false` value]]:

``` {.c .numberLines}
#include <stdio.h>
#include <stdbool.h>

int main(void) {
    bool x = true;

    if (x) {
        printf("x es verdadero!\n");
    }
}
```

Pero estos son idénticos a usar valores enteros para verdadero y falso. 
Son solo una fachada para que las cosas luzcan bien. [i[Tipos booleanos]>]


## Operadores y Expresiones {#operadores}

Los operadores de C deberían resultarte familiares si has trabajado con otros
lenguajes. Vamos a repasar algunos de ellos aquí.

(Hay muchos más detalles que estos, pero vamos a cubrir lo suficiente en esta sección
para comenzar).


### Operadores aritméticos

[i[Arithmetic Operators]()]Espero que estos te resulten familiares:
[i[`+` addition operator]] [i[`-` subtraction operator]]
[i[`*` multiplication operator]] [i[`/` division operator]]
[i[`%` modulus operator]]

``` {.c}
i = i + 3;  // Operadores de adición (+) y asignación (=), suma 3 a i
i = i - 8;  // Resta, resta 8 a i
i = i * 9;  // Multiplicación
i = i / 2;  // División
i = i % 5;  // Módulo (resto de la división)
```

Hay variantes abreviadas para todo lo anterior. Cada una de esas líneas podría
escribirse de manera más concisa como:
[i[`+=` assignment operator]] [i[`-=` assignment operator]]
[i[`*=` assignment operator]] [i[`/=` assignment operator]]
[i[`%=` assignment operator]]

``` {.c}
i += 3;  // Es igual que "i = i + 3", Suma 3 a i
i -= 8;  // Es igual que "i = i - 8"
i *= 9;  // Es igual que "i = i * 9"
i /= 2;  // Es igual que "i = i / 2"
i %= 5;  // Es igual que "i = i % 5"
```

No hay operador de exponenciación en C. Tendrás que usar una de las variantes de la función `pow()`[i[pow()]T] de `math.h`.

¡Vamos a adentrarnos en algunas cosas más extrañas que es posible que no encuentres en tus otros lenguajes! [i[Operadores Aritméticos]>]

### Operador ternario

[i[`?:` ternary operator]<]C también incluye el _operador ternario_. Se trata de una expresión cuyo valor depende del resultado de una condición incluida en ella.

``` {.c}
// Si x > 10, suma 17 a y. De lo contrario suma 37 a y.

y += x > 10? 17: 37;
```

¡Qué lío! Te acostumbrarás a medida que lo leas. Para ayudar un poco, reescribiré la expresión anterior usando declaraciones `if`:

``` {.c}
// Esta expresión

y += x > 10? 17: 37;

// es equivalente a esta no-expresión:

if (x > 10)
    y += 17;
else
    y += 37;
```

Compara esos dos hasta que veas cada uno de los componentes del operador ternario.

Otro ejemplo, el cual imprime si un número almacenado en `x` es par o impar sería:

``` {.c}
printf("El número %d es %s.\n", x, x % 2 == 0? "Par :)": "Impar :(");
```

El especificador de formato `%s` en `printf()`[i[printf()]T] significa imprimir una cadena.
Si la expresión `x % 2` se evalúa a `0`, el valor de toda la expresión ternaria se evalúa a la 
cadena `"Par"`. De lo contrario, se evalúa a la cadena `"Impar"`. ¡Bastante genial!


Es importante señalar, que el operador ternario no es de control de flujo, como lo es la 
declaración `if` . Es simplemente una expresión que se evalúa a un valor.[i[`?:` ternary 
operator]>]

### Pre-y-Post Incremento-y-Decremento

[i[`++` increment operator]<] [i[`--` decrement operator]<]
Ahora, vamos a *jugar* con otra cosa que quizás no hayas visto.

Estos son los legendarios operadores de post-incremento y post-decremento:

``` {.c}
i++;        // Suma uno a i (post-incremento)
i--;        // Resta uno a i (post-decremento)
```
Muy comúnmente, estos se utilizan simplemente como versiones más cortas de:

``` {.c}
i += 1;        // Suma 1 a i
i -= 1;        // Resta 1 a i
```
pero los astutos bribones son un poco más sutilmente diferentes que eso.

Echemos un vistazo a esta variante, pre-incremento y pre-decremento:

``` {.c}
++i;        // Suma 1 a i (pre-incremento)
--i;        // Resta 1 a i (pre-decremento)
```

Con el pre-incremento y pre-decremento, el valor de la variable se incrementa o decrementa
_antes_ de evaluar la expresión. Luego, la expresión se evalúa con el nuevo valor.

Con el post-incremento y post-decremento, primero se calcula el valor de la expresión con el 
valor actual, y _luego_ se incrementa o decrementa el valor después de que se haya determinado 
el valor de la expresión.

De hecho, puedes incluirlos en expresiones, así:

``` {.c}
i = 10;
j = 5 + i++;  // Calcula 5 + i, _luego_ incrementa i

printf("%d, %d\n", i, j);  // Imprime 11, 15
```

Comparemos esto con el operador de pre-incremento:

``` {.c}
i = 10;
j = 5 + ++i;  // Incrementa i, _luego_ calcula 5 + i

printf("%d, %d\n", i, j);  // Imprime 11, 16
```

Esta técnica se usa frecuentemente con el acceso y la manipulación de arreglos y punteros.
Te da una manera de usar el valor en una variable y también incrementar o decrementar ese
valor antes o después de que se use.

Pero, con mucho, el lugar más común donde verás esto es en un bucle `for`:

``` {.c}
for (i = 0; i < 10; i++)
    printf("i es %d\n", i);
```

Pero hablaremos más sobre eso más adelante.
[i[`++` increment operator]>] [i[`--` decrement operator]>]

### El operador coma

[i[`,` comma operator]<]
Esta es una forma poco común de separar expresiones que se ejecutarán de
izquierda a derecha:

``` {.c}
x = 10, y = 20;  // Primero asigna 10 a x, luego 20 a y
```

Parece un poco tonto, ¿verdad? Porque podrías simplemente reemplazar la coma, con un punto y coma, ¿no es así?

``` {.c}
x = 10; y = 20;  // Primero asigna 10 a x, luego 20 a y
```

Pero eso es un poco diferente. El segundo caso son dos expresiones separadas, mientras
que el primero es una sola expresión.


Con el operador coma, el valor de la expresión coma es el valor de la expresión más a la
derecha:

``` {.c}
x = (1, 2, 3);

printf("x is %d\n", x);  // Imprime 3, porque 3 es el que está más a la derecha    
                        // de la lista separada por comas
```

Pero incluso eso es bastante forzado. Un lugar común donde se usa el operador coma
es en los bucles `for` para hacer múltiples cosas en cada sección de la declaración:

``` {.c}
for (i = 0, j = 10; i < 100; i++, j++)
    printf("%d, %d\n", i, j);
```

Volveremos sobre eso más tarde.
[i[`,` comma operator]>]


### Operadores condicionales

[i[Conditional Operators]<]
Para valores booleanos, tenemos una serie de operadores estándar:
[i[Comparison operators]] [i[`==` equality operator]]
[i[`!=` inequality operator]] [i[`<` less than operator]]
[i[`>` greater than operator]] [i[`<=` less or equal operator]]
[i[`>=` greater or equal operator]]

``` {.c}
A == B;  // Verdadero si A es equivalente a B
A != B;  // Verdadero si A no es equivalente a B
A < B;   // Verdadero si A es menor que B
A > B;   // Verdadero si A es más grande que B
A <= B;  // Verdadero si A es menor o igual que B
A >= B;  // Verdadero si A es mayor o igual que B
```

¡No mezcles la asignación `=` con la comparación `==`! Usa dos signos iguales para
comparar y uno para asignar.

Podemos usar las expresiones de comparación con declaraciones `if`:

``` {.c}
if (a <= 10)
    printf("Exito!\n");
```
[i[Conditional Operators]>]

### Operadores Booleanos

[i[Boolean Operators]<]
Podemos encadenar o combinar expresiones condicionales con operadores booleanos
para _y_ (and), _o_ (or), y _no_ (not).[i[`&&` boolean AND]]
[i[`!` boolean NOT]]
[i[`||` boolean OR]]

|Operador|Significado booleano|
|:------:|:-------------:|
|`&&`|Y (and)|
|`||`|O (or)|
|`!`|Negación (not)|

Un ejemplo de "y" booleano (and):

``` {.c}
// Haz algo si 'x' es menor que 10 e 'y' es mayor que 20:

if (x < 10 && y > 20)
    printf("¡Haciendo algo!\n");
```

Un ejemplo de "no" booleano (not):

``` {.c}
if (!(x < 12))
    printf("x no es menor que 12"\n");
```

`!` tiene mayor precedencia que los otros operadores booleanos, por lo que debemos
usar paréntesis en ese caso.

Por supuesto, eso es simplemente lo mismo que:

``` {.c}
if (x >= 12)
    printf("x no es menor que 12\n");
```

Pero necesitaba el ejemplo!
[i[Boolean Operators]>]

### El operador `sizeof` {#sizeof-operator}

[i[`sizeof` operator]<]


Este operador le indica el tamaño (en bytes) que una variable o tipo de datos en particular utiliza en la memoria.

Más particularmente, le indica el tamaño (en bytes) que _el tipo de una expresión particular_ (que podría ser solo una variable) usa en la memoria.

Esto puede ser diferente en distintos sistemas, a excepción de `char` (que siempre son de 1 byte). [i[`char` type]]

Y puede que esto no parezca muy útil ahora, pero haremos referencias a ello aquí y allá, por lo que vale la pena cubrirlo.

Dado que esto calcula la cantidad de bytes necesarios para almacenar un tipo, se podría pensar que devolvería un `int`. O... dado que el tamaño no puede ser negativo, tal vez un `unsigned`?

[i[`size_t` type]<]

Pero resulta que C tiene un tipo especial para representar el valor de retorno
de `sizeof`. Es `size_t`, pronunciado "_size tee_"^[El `_t` es abreviatura de `type` (Tipo).].
Todo lo que sabemos es que es un tipo de entero sin signo que puede contener el tamaño
en bytes de cualquier cosa que le des a `sizeof`.

`size_t` aparece en muchos lugares diferentes donde se pasan o devuelven conteos de cosas.
Piénsalo como un valor que representa un conteo.
[i[`size_t` type]>]

Puedes tomar el `sizeof` de una variable o expresión:

``` {.c}
int a = 999;

// %zu es el especificador de formato para el tipo size_t

printf("%zu\n", sizeof a);      // Imprime 4 en mi sistema
printf("%zu\n", sizeof(2 + 7)); // Imprime 4 en mi sistema
printf("%zu\n", sizeof 3.14);   // Imprime 8 en mi sistema

// Si necesitas imprimir valores negativos de size_t, usa %zd
```

Recuerda: es el tamaño en bytes del _tipo_ de la expresión, no el tamaño
de la expresión en sí. Es por eso que el tamaño de `2+7` es el mismo que el
tamaño de `a`---ambos son de tipo `int`. Revisaremos este número `4` en el próximo
bloque de código...

...Donde veremos que puedes obtener el `sizeof` de un tipo (nota que los
paréntesis son requeridos alrededor del nombre de un tipo, a diferencia de una expresión):

``` {.c}
printf("%zu\n", sizeof(int));   // Imprime 4 en mi sistema
printf("%zu\n", sizeof(char));  // Imprime 1 en todos los sistemas
```

Es importante tener en cuenta que `sizeof` es una operación en _tiempo de compilación_
^[Excepto con arreglos de longitud variable---pero eso es una historia para otro momento.].
El resultado de la expresión se determina completamente en tiempo de compilación, no en tiempo 
de ejecución.

Más adelante haremos uso de esto.

[i[`sizeof` operator]>]

## Control de flujo

[i[Flow Control]<]
Los booleanos son buenos, pero por supuesto, no llegaríamos a ninguna parte
si no pudiéramos controlar el flujo del programa. Echemos un vistazo a varios
constructos: `if`, `for`,`while`, y `do-while`.

Primero, una nota general anticipada sobre declaraciones y bloques de declaraciones,
cortesía de tu amigable desarrollador de C local:

Después de algo como una declaración `if` o `while`, puedes colocar ya sea una sola
declaración que se ejecutará, o un bloque de declaraciones que se ejecutarán en secuencia.

[i[`if` statement]<]
Comencemos con una sola declaración:

``` {.c}
if (x == 10) printf("x es 10\n");
```

Esto también a veces se escribe en una línea separada. (Los espacios en blanco
son en gran medida irrelevantes en C---no es como en Python.)


``` {.c}
if (x == 10)
    printf("x es 10\n");
```

Pero ¿qué pasa si quieres que ocurran varias cosas debido a la condición?
Puedes usar llaves para marcar un _bloque_ o _declaración compuesta_.

``` {.c}
if (x == 10) {
    printf("x es 10\n");
    printf("Y también esto ocurre cuando x es 10\n");
}
```

Es un estilo muy común _siempre_ usar llaves incluso si no son necesarias:

``` {.c}
if (x == 10) {
    printf("x es 10\n");
}
```

Algunos desarrolladores sienten que el código es más fácil de leer y evita errores
como este, donde visualmente parece que las cosas están dentro del bloque `if`, pero en 
realidad no lo están.

``` {.c}
// EJEMPLO DE ERROR GRAVE

if (x == 10)
    printf("Esto sucede si x es 10\n");
    printf("Esto sucede SIEMPRE\n"); // ¡Sorpresa! ¡Incondicional!
```

`while`, `for` y los demás constructos de bucles funcionan de la misma manera
que los ejemplos anteriores. Si deseas hacer múltiples cosas en un bucle o después
de un `if`, envuélvelas en llaves.

En otras palabras, el `if` ejecutará lo que esté después de él. Y eso puede ser una sola 
declaración o un bloque de declaraciones.

[i[`if` statement]>]


### El estado `if`-`else` {#ifstat}

[i[`if`-`else` statement]<]
Ya hemos estado usando `if` en varios ejemplos, ya que es probable que lo hayas visto
en algún lenguaje antes, pero aquí tienes otro:

``` {.c}
int i = 10;

if (i > 10) {
    printf("Sí, i es mayor que 10.\n");
    printf("Y esto también se imprimirá si i es mayor que 10.\n");
}

if (i <= 10) printf("i es menor o igual que 10.\n");
```

En el código de ejemplo, el mensaje se imprimirá si `i` es mayor que 10,
de lo contrario, la ejecución continúa en la siguiente línea. Observa las llaves
después de la instrucción `if`; si la condición es verdadera, se ejecutará la primera
instrucción o expresión justo después del if, o bien, se ejecutará el conjunto de código
dentro de las llaves después del if. Este tipo de comportamiento de _bloque de código_ es común
en todas las instrucciones.

Por supuesto, dado que C es divertido de esta manera, también puedes hacer algo si la 
condición es `else` con una cláusula `else` en tu `if`:


``` {.c}
int i = 99;

if (i == 10)
    printf("i es 10!\n");
else {
    printf("i definitivamente no es 10.\n");
    printf("Que, francamente, me irrita un poco.\n");
}
```
Y puedes incluso encadenar estos para probar una variedad de condiciones, como esto:

``` {.c}
int i = 99;

if (i == 10)
    printf("i es 10!\n");

else if (i == 20)
    printf("i es 20!\n");

else if (i == 99) {
    printf("i es 99! Mi favorito\n");
    printf("No puedo decirte lo feliz que estoy.\n");
    printf("En serio.\n");
}
    
else
    printf("i es algún número loco que nunca he escuchado antes.\n");
```
Si vas por ese camino, asegúrate de revisar la declaración [`switch`](#switch-statement)
para una solución potencialmente mejor. La única limitación es que `switch` solo funciona con 
comparaciones de igualdad con números constantes. La cascada `if`-`else` anterior podría 
verificar desigualdades, rangos, variables o cualquier otra cosa que puedas crear en una 
expresión condicional.
[i[`if`-`else` statement]>]


### La declaración `while` {#whilestat}

[i[`while` statement]<]
La declaración `while` es simplemente un bucle promedio y corriente.
Realiza una acción mientras una expresión de condición sea verdadera.

¡Hagamos uno!

``` {.c}
// Imprime la siguiente salida:
//
// i es ahora 0!
// i es ahora 1!
// [ más de lo mismo entre 2 y 7 ]
// i es ahora 8!
// i es ahora 9!

int i = 0;

while (i < 10) {
    printf("i es ahora %d!\n", i);
    i++;
}

printf("¡Todo hecho!\n");
```

Así se obtiene un bucle básico. C también tiene un bucle `for` que habría
sido más limpio para ese ejemplo.

Un uso no poco común de `while` es para bucles infinitos donde se repite mientras es verdadero:

``` {.c}
while (1) {
    printf("1 es siempre cierto, así que esto se repite para siempre.\n");
}
```
[i[`while` statement]>]


### La sentencia `do-while` {#dowhilestat}

[i[`do`-`while` statement]<]
Ahora que ya tenemos la sentencia `while` bajo control, echemos
un vistazo a su prima, `do-while`.

Básicamente son lo mismo, excepto que si la condición del bucle es falsa en el primer paso, `do-while` se ejecutará una vez, pero `while` no se ejecutará en absoluto. En otras palabras, la prueba para ver si se debe ejecutar o no el bloque ocurre al _final_ del bloque con `do-while`. Ocurre al _principio_ del bloque con `while`.

Veámoslo con un ejemplo:

``` {.c}
// Utilizar una sentencia while:

i = 10;

// Esto no se ejecuta, porque i no es menor que 10:
while(i < 10) {
    printf("while: i es %d\n", i);
    i++;
}

// Utilizar una sentencia do-while:

i = 10;

// Se ejecuta una vez, porque la condición del bucle no se comprueba hasta
// después de que se ejecute el cuerpo del bucle:

do {
    printf("do-while: i es %d\n", i);
    i++;
} while (i < 10);

printf("¡Todo hecho!\n");
```

Observa que en ambos casos, la condición del bucle es falsa inmediatamente. Así que
en el `while`, el bucle falla, y el siguiente bloque de código nunca se ejecuta.
Con el `do-while`, sin embargo, la condición se comprueba _después_ de que se ejecute el bloque de código, por lo que siempre se ejecuta al menos una vez. En este caso, imprime el mensaje, incrementa `i`, falla la condición y continúa con la salida "¡Todo hecho!

La moraleja de la historia es la siguiente: si quieres que el bucle se ejecute al menos
una vez, sin importar la condición del bucle, usa `do-while`.

Todos estos ejemplos podrían haberse hecho mejor con un bucle `for`. Hagamos algo menos determinista: ¡repetir hasta que salga un cierto número aleatorio!

``` {.c .numberLines}
#include <stdio.h>   // Para printf
#include <stdlib.h>  // Para rand

int main(void)
{
    int r;

    do {
        r = rand() % 100; // Obtener un número aleatorio entre 0 y 99
        printf("%d\n", r);
    } while (r != 37);    // Repetir hasta que aparezca 37
}
```

Nota al margen: ¿lo has hecho más de una vez? Si lo hiciste, ¿te diste cuenta de que volvió a 
aparecer la misma secuencia de números? Y otra vez. ¿Y otra vez? Esto se debe a que `rand()` 
es un generador de números pseudoaleatorios que debe ser _sembrado_ con un número diferente 
para generar una secuencia diferente. Busque el [fl[`srand()`|https://beej.us/guide/bgclr/html/split/stdlib.html#man-srand]] para más detalles.
[i[`do`-`while` statement]>]

### La sentencia `for {#forstat}

[i[`for` statement]<]

¡Bienvenido a uno de los bucles más populares del mundo! ¡El bucle `for`!

Este es un gran bucle si sabes de antemano el número de veces que quieres hacer el bucle.

Podrías hacer lo mismo usando sólo un bucle `while`, pero el bucle `for` puede ayudar a mantener el código más limpio.

Aquí hay dos trozos de código equivalente---note cómo el bucle `for` es sólo una representación más compacta:

``` {.c}
// Imprime los números entre 0 y 9, ambos inclusive...

// Usando una sentencia while:

i = 0;
while (i < 10) {
    printf("i es %d\n", i);
    i++;
}

//Haz exactamente lo mismo con un bucle for:

for (i = 0; i < 10; i++) {
    printf("i es %d\n", i);
}
```

Así es, hacen exactamente lo mismo. Pero puedes ver cómo la sentencia `for` es un poco
compacta y agradable a la vista. (Los usuarios de JavaScript apreciarán plenamente sus 
orígenes en C en este punto).

Está dividida en tres partes, separadas por punto y coma. La primera es la inicialización, la 
segunda es la condición del bucle, y la tercera es lo que debe ocurrir al final del bloque si 
la condición del bucle es verdadera. Estas tres partes son opcionales.

``` {.c}
for (inicializar cosas; bucle si esto es cierto; hacer esto después de cada bucle)
```

Tenga en cuenta que el bucle no se ejecutará ni una sola vez si la condición del bucle 
comienza siendo falsa.

> **Curiosidad del bucle `for**
>
> Puedes usar el operador coma para hacer múltiples cosas en cada cláusula
> del bucle `for`.
>
> ``` {.c}
> for (i = 0, j = 999; i < 10; i++, j--) {
>     printf("%d, %d\n", i, j);
> }
> ```

Un `for` vacío se ejecutará eternamente:

``` {.c}
for(;;) {  // "for-ever" (para-siempre)
    printf("Imprimiré esto una y otra y otra vez\n" );
    printf("Por toda la eternidad hasta la muerte por calor del universo.\n");

    printf("O hasta que pulses CTRL-C.\n");
}
```
[i[`for` statement]>]

### Declaración `switch` {#switch-statement}

[i[`switch` statement]<]
Dependiendo del lenguaje del que vengas, puede que estés o no familiarizado con `switch`, o 
incluso puede que la versión de C sea más restrictiva de lo que estás acostumbrado. Esta es 
una sentencia que te permite tomar una variedad de acciones dependiendo del valor de una 
expresión entera.

Básicamente, evalúa una expresión a un valor entero, salta al [i[sentencia `case`]<]`case` que 
corresponde a ese valor. La ejecución se reanuda desde ese punto. Si se encuentra una 
sentencia `break`[i[`break` statement]<], la ejecución salta fuera del `switch`.

He aquí un ejemplo en el que, para un número determinado de cabras, imprimimos una intuición de cuántas cabras son.

``` {.c .numberLines}
#include <stdio.h>

int main(void)
{
    int goat_count = 2; // goat_count = contador de cabras

    switch (goat_count) {
        case 0:
            printf("No tienes cabras :(\n");
            break;

        case 1:
            printf("Solo tienes una cabra\n");
            break;

        case 2:
            printf("Tienes un par de cabras\n");
            break;

        default:
            printf("¡Tienes una gran cantidad de cabras!\n");
            break;
    }
}
```
En ese ejemplo, el `switch` saltará al `case 2` y ejecutará desde allí. Cuando (si)
llega a un `break`, salta fuera del `switch`.
[i[`break` statement]>]

Además, puede que veas la etiqueta `default`[i[`default` label]] en la parte inferior.
Esto es lo que ocurre cuando ningún caso coincide.

Cada `case`, incluyendo `default`, es opcional. Y pueden ocurrir en
cualquier orden, pero es realmente típico que `default`, si lo hay, aparezca último.
[i[`case` statement]>]

Así que todo actúa como una cascada `if`-`else`:

``` {.c}
if (goat_count == 0)
    printf("No tienes cabras\n");
else if (goat_count == 1)
    printf("Tienes solo una cabra.\n");
else if (goat_count == 2)
    printf("Tienes un par de cabras.\n");
else
    printf("Tienes una gran cantidad de cabras!\n");
```

Con algunas diferencias clave:

* A menudo, `switch` es más rápido para saltar al código correcto (aunque la especificación no lo garantiza).
* `if`-`else` puede hacer cosas como condicionales relacionales como `<` y `>=` y punto flotante y otros tipos, mientras que `switch` no puede.

Hay una cosa más sobre switch que a veces se ve y que es bastante
interesante: _falla de salida_ (_fall through_).

[i[sentencia `break`]<]
¿Recuerdas que `break` nos hace saltar fuera del switch?

[i[Fall through]<]
Bueno, ¿qué pasa si _no se utiliza_ `break`?

¡Resulta que seguimos con el siguiente `case`! ¡Demo!

``` {.c}
switch (x) {
    case 1:
        printf("1\n");
        // Falla el salto! Sigue ejecutando!
    case 2:
        printf("2\n");
        break;
    case 3:
        printf("3\n");
        break;
}
```

Si `x == 1`, el `switch` irá primero al `caso 1`, imprimirá el `1`, pero luego
simplemente continúa con la siguiente línea de código... ¡que imprime `2`!

Y entonces, por fin, llegamos a un `break` así que saltamos del `switch`.

si `x == 2`, entonces simplemente entramos dentro del `case 2`, imprimimos `2`, y `break` como
es normal.

Al no tener un `break` se _falla la salida_.

Consejo de experto: _Siempre_ ponga un comentario en el código en el que tiene intención de
fallar la salida, como he hecho yo más arriba. Evitará que otros programadores se pregunten si 
realmente querías hacer eso. [i[Fall through]>]

De hecho, este es uno de los lugares comunes para introducir errores en los programas en C: 
olvidar poner un `break` en tu `case`. Tienes que hacerlo si no quieres simplemente pasar al 
siguiente caso^[Esto se consideró tal peligro que los diseñadores del Lenguaje de Programación 
Go hicieron `break` por defecto; tienes que usar explícitamente la sentencia `fallthrough 
(fallar la salida)` de Go si quieres pasar al siguiente caso]. [i[`break` statement]>]

Antes dije que `switch` funciona con tipos enteros-- mantenlo así. No utilices tipos de coma 
flotante o cadenas. Una laguna legal aquí es que puedes usar tipos de caracteres porque estos son secretamente números enteros. Por lo tanto, esto es perfectamente aceptable:

``` {.c}
char c = 'b';

switch (c) {
    case 'a':
        printf("La letra es 'a'!\n");
        break;

    case 'b':
        printf("La letra es 'b'!\n");
        break;

    case 'c':
        printf("La letra es 'c'!\n");
        break;
}
```

Finalmente, puedes usar [i[`enum` keyword]]`enum` en `switch` ya que también son tipos
enteros. Pero más sobre esto en el capítulo `enum`.

[i[`switch` statement]>] [i[`break` statement]>] [i[Flow Control]>]
