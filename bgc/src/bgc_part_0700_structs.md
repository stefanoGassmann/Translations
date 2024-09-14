<!-- Beej's guide to C

# vim: ts=4:sw=4:nosi:et:tw=72
-->

# Estructuras (Structs) {#structs}

[i[`struct` keyword]<]
En C, tenemos algo llamado `struct`, que es un tipo definible por el usuario, el cual,
contiene múltiples piezas de datos, potencialmente de diferentes tipos.

Es una forma conveniente de agrupar múltiples variables en una sola. Esto puede
ser beneficioso para pasar variables a funciones (así sólo tienes que pasar una en lugar
de muchas), y útil para organizar datos y hacer el código más legible.

Si vienes de otro lenguaje, puede que estés familiarizado con la idea de _clases_ y _objetos_.
Estos no existen en C, de forma nativa^[Aunque en C los elementos individuales en memoria
como `int`s se denominan «objetos», no son objetos en el sentido de la programación orientada
a objetos]. Puedes pensar en una `struct` como una clase con sólo miembros de datos, y
sin métodos.

## Declaración de una estructura

[i[`struct` keyword-->declaring]<]
Puedes declarar una `struct` en tu código de la siguiente manera:

``` {.c}
struct car {
    char *name;
    float price;
    int speed;
};
```

Esto se hace a menudo en el ámbito global, fuera de cualquier función, para que la
«estructura» esté disponible globalmente.

Cuando haces esto, estás creando un nuevo _tipo_. El nombre completo del tipo
es `struct car`. (No sólo `car`---eso no funcionará).

Todavía no hay variables de ese tipo, pero podemos declarar algunas:

``` {.c}
struct car saturn;  // Variable «saturn» de tipo «struct car»
```

Y ahora tenemos una variable no inicializada `saturn`^[El Saturn fue una popular marca
de coches económicos en los Estados Unidos hasta que fue sacada del negocio por el crack
de 2008, tristemente para nosotros los fans.] de tipo `struct car`.

Deberíamos inicializarlo. Pero, ¿cómo establecemos los valores de cada uno de esos campos?

Como en muchos otros lenguajes que lo robaron de C, vamos a usar el operador
punto (`.`) para acceder a los campos individuales.

``` {.c}
saturn.name = "Saturn SL/2";
saturn.price = 15999.99;
saturn.speed = 175;

printf("Name:           %s\n", saturn.name);
printf("Price (USD):    %f\n", saturn.price);
printf("Top Speed (km): %d\n", saturn.speed);
```

Allí en las primeras líneas, establecemos los valores en la `struct car`, y luego
en la siguiente parte, imprimimos esos valores.
[i[`struct` keyword-->declaring]>]

## Inicializadores de estructuras {#struct-initializers}

[i[`struct` keyword-->initializers]<]
El ejemplo de la sección anterior era un poco difícil de manejar. Tiene que haber una
forma mejor de inicializar esa variable `struct`.

Puedes hacerlo con un inicializador, poniendo valores en los campos _en el orden en
que aparecen en la `struct`_, cuando defines la variable. (Esto no funcionará después de
que la variable haya sido definida - tiene que ocurrir en la definición).

``` {.c}
struct car {
    char *name;
    float price;
    int speed;
};

// ¡Ahora con un inicializador! Mismo orden de campos que en la declaración struct:
struct car saturn = {"Saturn SL/2", 16000.99, 175};

printf("Name:      %s\n", saturn.name);
printf("Price:     %f\n", saturn.price);
printf("Top Speed: %d km\n", saturn.speed);
```

El hecho de que los campos del inicializador tengan que estar en el mismo orden, es
un poco raro. Si alguien cambia el orden en `struct car`, ¡podría romper el resto del código!

Podemos ser más específicos con nuestros inicializadores:

``` {.c}
struct car saturn = {.speed=175, .name="Saturn SL/2"};
```

Ahora, es independiente del orden, en la declaración `struct`. Lo que sin duda es un código
más seguro.

De forma similar a los inicializadores de array, cualquier designador de campo que
falte, se inicializa a cero (en este caso, sería `.price`, que he omitido).
[i[`struct` keyword-->initializers]>]

## Paso de estructuras a funciones

[i[`struct` keyword-->passing and returning]<]
Puedes hacer un par de cosas para pasar una `struct` a una función.

1. Pasar la `struct`.
2. Pasar un puntero a la `struct`.

Recuerda que cuando pasas algo a una función, se hace una _copia_ de esa cosa para que
la función opere sobre ella, ya sea una copia de un puntero, un `int`, una `struct`, o
cualquier otra cosa.

Hay básicamente dos casos en los que querrías pasar un puntero a la `struct`:

 1. Necesitas que la función sea capaz de hacer cambios a la `struct` que fue pasada, y
que esos cambios se muestren en la llamada.

 2. La `struct` es algo grande y es más caro copiarla en la pila que copiar un puntero^[Un
puntero es probablemente de 8 bytes en un sistema de 64 bits].

Por estas dos razones, es mucho más común pasar un puntero a una `estructura` es una
función, aunque no es ilegal pasar solamente la `estructura`.

Intentemos pasar un puntero, haciendo una función que nos permita establecer el
campo `.price` de la `struct car`:

``` {.c .numberLines}
#include <stdio.h>

struct car {
    char *name;
    float price;
    int speed;
};

int main(void)
{
    struct car saturn = {.speed=175, .name="Saturn SL/2"};

    // Pasar un puntero a este coche struct, junto con un nuevo,
    // más realista, precio:
    set_price(&saturn, 799.99);

    printf("Price: %f\n", saturn.price);
}
```

Usted debe ser capaz de llegar a la firma de la función para `set_price()` con sólo mirar
los tipos de los argumentos que tenemos.

`saturn` es un `struct car`, así que `&saturn` debe ser la dirección del
`struct car`, es decir, un puntero a un `struct car`, un `struct car*`.

Y `799.99` es un `float`.

Así que la declaración de la función debe tener este aspecto:

``` {.c}
void set_price(struct car *c, float new_price)
```

Sólo tenemos que escribir el cuerpo. Un intento podría ser:

``` {.c}
void set_price(struct car *c, float new_price) {
    c.price = new_price;  // ERROR!!
}
```

Eso no funcionará porque el operador punto sólo funciona en `struct`s... no funciona
en _punteros_ a `struct`s.

Entonces podemos desreferenciar la variable `c` para des-apuntarla y llegar a la
propia `struct`. Dereferenciar una `struct car*` resulta en
la `struct car` a la que apunta el puntero, sobre la que deberíamos poder usar
el operador punto:

``` {.c}
void set_price(struct car *c, float new_price) {
    (*c).price = new_price;  // Funciona, pero es feo y no idiomático :(
}
```

Y funciona. Pero es un poco engorroso teclear todos esos paréntesis y el asterisco. C tiene
un azúcar sintáctico llamado, operador _flecha_ _(arrow)_ que ayuda con eso.
[i[`struct` keyword-->passing and returning]>]

## El operador Arrow / flecha (->) 

[i[`->` arrow operator]<]
El operador flecha ayuda a referirse a campos en punteros a `struct`s.

``` {.c}
void set_price(struct car *c, float new_price) {
    // (*c).price = new_price;  // Funciona, pero no es idiomático :(
    //
    // La línea de arriba es 100% equivalente a la de abajo:

    c->price = new_price;  // ¡Ese es!
}
```

Así que.. cuando accedemos a campos, ¿cuándo usamos punto, y cuándo usamos flecha?

* Si tienes una `struct`, usa punto (`.`).
* Si tienes un puntero a una `struct`, usa arrow/flecha (`->`).
[i[`->` arrow operator]>]

## Copiar y devolver `struct`s

[i[`struct` keyword-->copying]<]
Aquí tienes una fácil.

¡Sólo tienes que asignar de uno a otro!
``` {.c}
struct car a, b;

b = a;  // Copiar la estructura
```

Devolver una `estructura` (en lugar de un puntero a una) desde una función, también hace
una copia similar a la variable receptora.

Esto no es una «copia profunda»^[Una _copia profunda_ sigue a los punteros en la `struct` y
copia también los datos a los que apuntan. Una _copia superficial_ sólo copia los punteros, pero
no las cosas a las que apuntan. C no viene con ninguna funcionalidad de copia profunda
incorporada]. Todos los campos se copian tal cual, incluyendo los punteros a cosas.
[i[`struct` keyword-->copying]>]

## Comparación de `struct`s

[i[`struct` keyword-->comparing]<]
Sólo hay una forma segura de hacerlo: comparar cada campo de uno en uno.

Podrías pensar que podrías utilizar [fl[`memcmp()`|https://beej.us/guide/bgclr/html/split/stringref.html#man-strcmp]], pero eso no maneja el caso de los posibles [bytes de relleno](#struct-padding-bytes) que pueda haber.

Si primero borras la `struct` a cero con
[fl[`memset()`|https://beej.us/guide/bgclr/html/split/stringref.html#man-memset]],
entonces _podría_ funcionar, aunque podría haber elementos extraños que
[fl[puede que no se compare como usted espera|https://stackoverflow.com/questions/141720/how-do-you-compare-structs-for-equality-in-c]].
[i[`struct` keyword-->comparing]>] [i[`struct` keyword]>]
