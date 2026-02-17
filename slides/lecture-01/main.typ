#import "../../theme/common.typ": deck, code, code-file, note
#import "@preview/typslides:1.3.2": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()

#show: deck
#codly(display-icon: false, display-name: false, zebra-fill: black.transparentize(96%))
#front-slide(
  title: "JIT-compilers basics",
  subtitle: [Введение в JIT-компиляторы и языковые рантаймы],
  authors: "Ilya Gavrilin, Syntacore",
  info: [MIPT, 2026],
)

#slide(title: "Немного о преподавателе")[#align(horizon)[ #grid(columns: (1fr, 1fr), [
  - Работаю в отделе Runtimes Syntacore
  - Занимаюсь различными рантаймами:
    - OpenJDK
    - V8 (Chromium)
    - AOSP (Android)
  - MailTo: gavrilin.id\@phystech.edu
  ],
  [#align(center)[#image(width:80%, "assets/profile_qr.png")]])
  ]]

#slide(title: "Пара слов о курсе")[#align(horizon)[#grid(columns: (1fr, 1fr),
  [
  - Курс будет состоять из двух семестров, в конце экзамен
  - В лекциях будем изучать динамические компиляторы и рантаймы в целом
  - О системе заданий в конце лекции
  ],
  [#align(center)[#image(width: 80%, "assets/group_qr.jpg")]])
]]

#slide(title: "Как мы обычно исполняем код")[#align(top+left)[
  - В ходе трансляции исходного кода получаем исполняемый файл
  - Используем этот исполняемый файл
  - Такой подход называется *AOT(Ahead-Of-Time)* компиляция
  #align(center)[
    #image("assets/AOT_pipeline.png", width: 80%)
  ]
]]

#slide(title: "Как мы обычно исполняем код")[#align(top+left)[
  - В ходе трансляции исходного кода получаем исполняемый файл
  - Используем этот исполняемый файл
  - Такой подход называется *AOT(Ahead-Of-Time)* компиляция
  #align(center)[
    #image("assets/AOT_pipeline.png", width: 80%)
  ]

  - Видите ли вы проблемы у этого подхода?
]]

#slide(title: "Поговорим о нюансах")[#align(top+left)[
  - Нужно собирать и поддерживать проект для каждого популярного триплета¹

```bash
me@my_laptop:~/$ ./coolest_program_ever.out
# Hello world!

friend@other_laptop:~/$ ./coolest_program_ever.out
bash: cannot execute binary file: Exec format error
```

  #note[
    ¹ Триплет: связка \<архитектура\>-\<ОС\>-\<окружение\>, описывающая таргет машину \
    - В Linux есть возможность автоматического запуска транслятора кода (binfmt)
  ]
]]

#slide(title: "Поговорим о нюансах")[#align(top+left)[
  - Нужно собирать и поддерживать проект для каждого популярного триплета
  - Стоит избегать платформо-зависимого кода

  ```c
#include <immintrin.h>

int main() {
  __m128i x = _mm_setzero_si128();
}
```

  #note[
    - В коде следует избегать зависимости от конкретной платформы, но в больших проектах часто присутствует обратное
  ]
]]

#slide(title: "Поговорим о нюансах")[#align(top+left)[
  - Нужно собирать и поддерживать проект для каждого популярного триплета
  - Стоит избегать платформо-зависимого кода
  - Tradeof: количество поддерживаемых устройств или скорость приложения

  ```bash
me@my_laptop:~/$ clang++ --target=riscv64-unknown-linux-gnu
    -march=rv64gcv -o ./coolest_program_ever.out
friend@other_laptop:~/$ ./coolest_program_ever.out
Illegal instruction (core dumped)
```

  #note[
    - Конечно, вы можете в рантайме узнать какие у вас есть расширения (hwprobe), но при генерации кода эти проверки не добавляются
  ]
]]


#slide(title: "Ищем решение")[#align(top+left)[
  - Собираем и распространяем много вариантов программы

  ```bash
coolest_program_ever-x86_64-win
coolest_program_ever-x86_64-linux
coolest_program_ever-aarch64-linux
coolest_program_ever-riscv64-linux
```

  #note[- Не забывайте, код нужно поддерживать и тестировать на всех платформах]
]]

#slide(title: "Ищем решение")[#align(top+left)[
  - Собираем и распространяем много вариантов программы
  - Распространяем только исходники

  ```bash
$ ninja -C out/Release chrome
[2/28473] CXX obj/v8/src/compiler/turbofan/graph.o
[3/28473] CXX obj/ui/gfx/font_render_params.o
```

  #note[- Есть целые дистрибутивы, основанные на этом подходе (см. Gentoo+Portage)]
]]

#slide(title: "Ищем решение")[#align(top+left)[
  - Собираем и распространяем много вариантов программы
  - Распространяем только исходники
  - Попробуем интерпретировать код
  #v(2em)
  _Early JVMs always interpreted Java bytecodes. This had a large *performance penalty* of between a *factor 10* and *20* for Java versus C in average applications._ - #text(fill: luma(70%))[http://www.shudo.net/jit/perf/]

  #note[- Хороший вариант, но что с производительностью?]
]]

#slide(title: "Ищем решение")[#align(top+left)[
  - Собираем и распространяем много вариантов программы
  - Распространяем только исходники
  - Попробуем интерпретировать код
  #align(center)[#image(width:35%, "assets/mem_lazy.jpg")]
]]


#slide(title: "Ищем решение")[#align(top+left)[
  - Собираем и распространяем много вариантов программы
  - Распространяем только исходники
  - Попробуем интерпретировать код
  - Будем *компилировать* часто исполняемый код *в процессе работы программы*

  #v(2em)
  #align(center)[
    #text(size: 34pt, weight: "bold")[“Write once, run anywhere”]
  ]
  #v(1em)

  #align(bottom + left)[
    #note[#link("https://en.wikipedia.org/wiki/Write_once,_run_anywhere")[Write once, run anywhere (WORA)]]
  ]
  #place(bottom + right)[
    #image("assets/sun_logo.png", height: 2.2em)
  ]
]]

#slide(title: "Что же такое JIT компиляция")[#align(top+left)[
  - *JIT (Just-In-Time) компиляция* - вариант компиляции, при котором трансляция и генерация исполняемого кода происходит одновременно (конкурентно) с исполнением компилируемого кода

  #align(center)[
    #image("assets/JIT_pipeline.png", width: 80%)
  ]
]]

#slide(title: "Это самое вам не то самое")[#align(top+left)[
  Существует большое количество различных библиотек для динамической генерации кода:
  - В инфраструктуре LLVM: LLVM-JIT — On Request Compilation (ORC)
  - В инфраструктуре GNU: Lightning
  - Иные решения: AsmJIT, xbyak, ...

  #v(1em)
  #note[Получается, уже всё написано и этот курс можно заканчивать?]
]]

#slide(title: "Блистай как молния, жаль, что не работает")[#align(top+left)[
  ```c
#include <lightning.h>
typedef int (-fib_fn_t)(int);
jit_prolog();
/- ... emit instructions ... -/
jit_retr(JIT_R0);
fib_fn_t fib = (fib_fn_t)jit_emit();  // machine code pointer
int r = fib(12);
```

  - Код, действительно сгенерирован в процессе исполнения программы
  - Сейчас мы осуществляем "отложенную"(lazy) компиляцию
  - Чего-то не хватает?
]]

#slide(title: "Используем возможности по полной")[#align(top+left)[
  - Хотелось бы иметь интерпретатор, который с момента запуска приложения будет исполнять код
  - Нужен некий менеджер, который бы смог решать, какой код компилировать
  - Желательно, при компиляции обладать информацией о том, как код исполнялся
]]

#slide(title: "Используем возможности по полной")[#align(top+left)[
  - Хотелось бы иметь интерпретатор, который с момента запуска приложения будет исполнять код
  - Нужен некий менеджер, который бы смог решать, какой код компилировать
  - Желательно, при компиляции обладать информацией о том, как код исполнялся

  #v(1.2em)
  #align(center)[
    #text(size: 34pt, weight: "bold")[Вывод: нам нужен runtime]
  ]
]]

#slide(title: "Что такое runtime")[#align(top+left)[
- Runtime — это среда, в которой исполняется программа.
  - Управляет запуском и завершением программы
  - Предоставляет модель памяти и потоков
  - Обрабатывает исключения и ошибки
  - Может интерпретировать или компилировать код

- Вы уже сталкивались с runtime в C++:
  - Ваша программа проходит долгий путь, прежде чем дойдёт до `main()`
  - RTTI: `dynamic_cast` и `typeid`
]]

#slide(title: "Взглянем на С++")[
  #align(top)[
  - Посмотрим на то, как добавляется рантайм
  #codly(highlights: ((line: 2, fill: orange), (line: 4, fill: orange), (line: 3, fill: green), (line: 5, fill: yellow)))
  ```sh
  /bin/ld -o a.out \
  /usr/lib64/lp64d/crt1.o /lib64/lp64d/crti.o /lib64/lp64d/crtbegin.o \
  /tmp/initial-source.o \
  /lib64/lp64d/crtend.o /lib64/lp64d/crtn.o \
  -lc -lgcc -lc
  ```
  - В данном случае, наш код (`initial-source.o`) уже имеет представление подходящее для прямого исполнения на таргет машине
  - Насколько усложнится рантайм, если код представлен в обобщённом виде?
]]
#slide(title: "Посмотрим схематически")[
  #align(horizon)[
  #grid(align: horizon, columns: (1fr, 0.85fr),
  [
    - Инициализация обеспечивается: `crtbegin.o`
    - Завершение обеспечивается: `crtend.o`
    - Взаимодействие с ситемой: `libc`
  ],
    [#image("assets/C_runtime.png", width: 100%)]
  )]]
#slide(title: "Утолщим рантайм")[
  #align(horizon)[
  #grid(align: horizon, columns: (1fr, 1fr),gutter: 1em,
  [
    #image("assets/JVM_runtime.png", width: 100%)
  ],

  [ #v(2em)
    #image("assets/C_runtime.png", width: 100%)]
  )]]

#slide(title: "Утолщим рантайм")[
  #align(horizon)[
  #grid(align: horizon, columns: (1fr, 1fr),gutter: 1em,
  [
    #image("assets/JVM_runtime.png", width: 100%)
  ],

  [
    - Построили ещё один слой абстракции над нашим железом
    - Получившийся рантайм взаимодействует с рантаймом языка Си (зачастую)
    - Получаем унифицированное поведение кода вне зависимости от платформы
  ]
    )]]

#slide(title: "Типичный представитель рантайма")[#align(top)[
  #align(center)[#image(width: 80%, "assets/runtime_scheme.png")]
  - А много ли таких рантаймов нас окружают?
]]

#slide(title: "Современные рантаймы и языки")[
#align(left + top)[
#grid(columns: (1fr, 1fr, 1fr), gutter: 2em,

[
*JVM-экосистема*

JVM языки:

Java, Kotlin, Scala,
Clojure, Groovy и др.

Рантаймы:

- OpenJDK
- Azul Zulu / Prime
- GraalVM
],

[
*Веб-экосистема*

Языки:

JavaScript,
TypeScript,
WebAssembly

Рантаймы:

- V8 (Chromium, Node.js)
- SpiderMonkey (Firefox)
],

[
*Другие миры*

Свои рантаймы есть и у других:

- Python (CPython, PyPy)
- Lua (LuaJIT)


]

)]
#slide(title: "JVM, JRE и JDK")[
#grid(columns: (1fr, 1fr), gutter: 2em,

[
*JDK* — набор для разработки
- компилятор, инструменты, JRE

#v(0.6em)

*JRE* — среда запуска программ
- JVM + стандартные библиотеки

#v(0.6em)

*JVM* — виртуальная машина
- исполняет байткод
- управляет памятью и потоками
],

[
#image(width: 100%, "assets/JDK_infra.jpg")
])

]]

#slide(title: "Ищем решение")[#align(top+left)[
  - Собираем и распространяем много вариантов программы
  - Распространяем только исходники
  - Попробуем интерпретировать код
  - Будем компилировать часто исполняемый код в процессе работы программы

  #v(2em)
  #align(center)[
    #text(size: 34pt, weight: "bold")[“Write once, run anywhere”]
  ]
  #v(1em)

  #align(bottom + left)[
    #note[#link("https://en.wikipedia.org/wiki/Write_once,_run_anywhere")[Write once, run anywhere (WORA)]]
  ]
  #place(bottom + right)[
    #image("assets/sun_logo.png", height: 2.2em)
  ]
]]

#slide(title: "Люблю вид переносимого кода по утрам")[#align(top)[

  ```cpp
inline float rsqrtf ( float x ) {
  const float xhalf = 0.5f * x;
  int i = *(int*) & x;
  i = 0x5f375a86 - ( i >> 1 );

  x = *(float*) & i;
  x = x * ( 1.5f - xhalf * x * x );
  ...
  return x;
}
  ```
  - Вам принесли на ревью такой код, как Вам?


]]

#slide(title: "Люблю вид переносимого кода по утрам")[#align(top)[
  #codly(highlights:((line: 3, start: 11, end: 19, fill: red),(line: 4, start: 7, end: 16, fill: orange)))
  ```cpp
inline float rsqrtf ( float x ) {
  const float xhalf = 0.5f * x;
  int i = *(int*) & x;
  i = 0x5f375a86 - ( i >> 1 );

  x = *(float*) & i;
  x = x * ( 1.5f - xhalf * x * x );
  ...
  return x;
}
  ```
  - Вам принесли на ревью такой код, как Вам?


]]

#slide(title: "Веди себя нормально")[
  #align(top+left)[
  - В C++ множество операций могут привести к Undefined Behavior (UB)
  - После UB компилятор *не обязан* сохранять корректность программы
  - strict aliasing: https://eel.is/c++draft/basic.lval#11
  #v(1em)
  - Помимо UB можем встретить и implementation-defined - поведение может отличаться между платформами
  - _стандартные floating-point типы_: \ https://eel.is/c++draft/basic.fundamental#12
  #v(1em)
  - А что если бы в языке не было бы UB?
]]
#slide(title: "Почему в JVM нет Undefined Behavior")[
- В JVM поведение программ строго задано спецификацией.
- Нет прямого доступа к памяти:
  нельзя читать или писать произвольные адреса.
- В языке отсутствует аналог `reinterpret_cast`
  и произвольное преобразование указателей.
- Все обращения к памяти проходят проверки: \
  выход за границы массива → исключение.
- Переполнение целых чисел определено:
  происходит арифметика по модулю 2ⁿ.

#v(1em)

#text(size: 0.8em)[
Спецификация JVM:
https://docs.oracle.com/javase/specs/jvms/se25/html/

Спецификация Java (переполнение целых):
https://docs.oracle.com/javase/specs/jls/se25/html/jls-4.html#jls-4.2.2
]
]

#slide(title: "Data race и модель памяти Java (JMM)")[ #align(top)[
- Хотя Java избегает классического undefined behavior,
  ошибки возможны при неправильной работе потоков.

- *Data race возникает*, если:
  - несколько потоков читают одну переменную,
  - хотя бы один поток её изменяет, и при этом нет синхронизации.

#v(0.6em)

Что может произойти:
- поток увидит устаревшее значение,
- операции наблюдаются в другом порядке,
- появляются редкие и трудно воспроизводимые ошибки.
]]
#slide(title: "Floating point в Java")[
- Типы: `float` (32 бита) и `double` (64 бита), формат IEEE 754
- Поведение вычислений фиксировано и одинаково на всех JVM
- Переполнение даёт `±Infinity`, недопустимые операции дают `NaN`
- Существуют `+0.0` и `−0.0`, различимые в делении
- Возможны разные `NaN`, но операции возвращают канонический `NaN`

#v(0.5em)
#image(width:100%, "assets/Float_example.png")
#v(0.5em)
#text(size: 0.8em)[
JVMS SE 25, §2.3.2 Floating-Point Types and Values
https://docs.oracle.com/javase/specs/jvms/se25/html/jvms-2.html#jvms-2.3.2
]]
#slide(title: "А меча у тебя тоже два?")[
В Java есть две математические библиотеки:

- `Math` — ориентирован на максимальную производительность
- `StrictMath` — ориентирован на переносимость результатов

`Math` может использовать оптимизации JVM
и аппаратные инструкции процессора.

`StrictMath` использует библиотеку fdlibm,
давая одинаковые результаты на всех платформах.

Итого:
- Math → быстрее
- StrictMath → воспроизводимые вычисления



]
#slide(title: "А меча у тебя тоже два?")[#align(top)[
  ```java
// Math.java
@IntrinsicCandidate
public static double sin(double a) {
  return StrictMath.sin(a); // default impl. delegates to StrictMath
}

//StrictMath.java
public static double sin(double a) {
  return FdLibm.Sin.compute(a);
}
  ```
]
  #align(bottom)[
  #text(size: 0.8em)[
  Java API: Math / StrictMath
  https://docs.oracle.com/en/java/javase/25/docs/api/java.base/java/lang/StrictMath.html
  ]]
]
#slide(title: "Аннотации в Java: что это и как работают")[
- *Аннотация* — это метаданные,
  прикреплённые к элементам программы
  (классам, методам, полям, параметрам).

Пример объявления:
`@interface MyAnno { int value(); }`

Пример использования:
`@MyAnno(42)`

#v(0.6em)

Аннотации могут обрабатываться:
- *компилятором*
  (например `@Override`, проверки и ошибки)
- *annotation processors*
  (генерация кода во время компиляции)
- *во время выполнения*

#note[https://docs.oracle.com/javase/specs/jls/se25/html/jls-9.html#jls-9.6]
]

#slide(title: "Interop с C/C++: зачем это нужно")[#align(top)[
Несмотря на наличие JVM, часто требуется нативный код:

- доступ к системным API,
- GPU, SIMD, драйверы, криптография.

Поэтому Java поддерживает вызов
кода на C/C++ через JNI.

Interop — обязательная часть
реальных Java-систем.

#align(center)[#image(width: 80%, "assets/JNI.png")]

#note[
JNI Overview:
https://docs.oracle.com/javase/8/docs/technotes/guides/jni/
]
]]

#slide(title: "Что происходит при JNI-вызове")[#align(top)[
Вызов native-метода приводит к:

- переходу из JVM в нативный код,
- преобразованию параметров,
- управлению памятью между средами,
- возврату результата обратно в JVM.

Такой переход дорог,
и JIT не может оптимизировать код сквозь него.

Поэтому JNI эффективен
только для крупных операций.

#v(0.6em)

#note[
JVM Spec: Native Methods (§5)
https://docs.oracle.com/javase/specs/jvms/se25/html/
]]
]

#slide(title: "Почему JMH нужен для измерений")[#align(top)[
Обычные тесты времени выполнения некорректны,
потому что JVM во время работы:

- компилирует код в машинный (JIT),
- собирает мусор,
- занимается своими делами.
#v(2em)
Просто бенчмарк запущенный в JVM - не отражает работу реального приложения


#note[
JMH project: https://openjdk.org/projects/code-tools/jmh/
]]
]

#slide(title: "Ну что измерим?")[#align(top)[
  - `Math` - оптимзированная нативная реализация
  - `StrictMath` - корректная и переносимая
```java
public double double1 = Math.PI / 6;
@Benchmark
public double javaMathSin() {
    return Math.sin(double1);
}

@Benchmark
public double javaStrictMathSin() {
    return StrictMath.sin(double1);
}
```
]
]

#slide(title: "Ну что измерим?")[#align(top)[
  - `Math` - оптимзированная нативная реализация
  - `StrictMath` - корректная и переносимая
  #v(2em)
```text
Benchmark           Mode  Cnt       Score       Error   Units
javaMathSin        thrpt   10  183512.822 ±  2216.140  ops/ms
javaStrictMathSin  thrpt   10  756532.775 ± 13314.422  ops/ms
```
#align(bottom)[
- Ой, кажется просчитались
- Но где же мы просчитались?
]]
]

#slide(title: "Ну что измерим?")[#align(top)[
  - `Math` - оптимзированная нативная реализация
  - `StrictMath` - корректная и переносимая
  #v(2em)
```text
Benchmark                       Mode  Cnt   Score    Error   Units
BetterBench.javaMathSin        thrpt   10  49.781 ±  1.559  ops/ms
BetterBench.javaStrictMathSin  thrpt   10   9.865 ±  0.063  ops/ms
```
#align(bottom)[
- Изменили тест и сделали данные на входе случайными
- Всегда смотрите что и как вы измеряете
]]
]

#slide(title: "Система заданий курса")[
#grid(columns: (1fr, 1fr), gutter: 2em, [

Курс предполагает выполнение заданий,
которые оцениваются в баллах.

Баллы суммируются и используются
для дальнейшего ранжирования результатов.

#v(0.6em)

Решения необходимо присылать
в виде ссылки на GitHub-репозиторий.

Отправка решений на почту:
gavrilin.id\@phystech.edu

#v(0.6em)

],

[
  #image(width:100%, "assets/tasks.jpg")
]

)
]

#slide(title: "[T1.1] Минификация Java-кода (до 3 баллов)")[
Задача:
написать минификатор Java-кода,
уменьшающий размер исходного файла.

Минификатор должен:
- удалять лишние пробелы и переносы,
- убирать комментарии,
- сохранять корректность программы.


До:
`int sum(int a, int b) { return a + b; }`

После:
`int sum(int a,int b){return a+b;}`
#note[Для получения полного балла подумайте, как можно сжать код сильнее \ https://mc.yandex.ru/metrika/tag.js]
]

#slide(title: "[T1.2] Оптимизация вычисления sin (2 балла)")[
Задача:
ускорить вычисление sin,
если заранее известны ограничения на входные данные.

Можно:
- взять реализацию из fdlibm,
- переписать её в JIT-генерируемый код,
- упростить алгоритм под нужные диапазоны.
- ограничение принимайте с консоли

Пример ограничения входов:
```cpp
enum InputKind {
  SMALL, NORMAL, DENORMAL
}
```
]

#slide(title: "Links")[#align(top)[
- JVM SE specification: \ https://docs.oracle.com/javase/specs/jvms/se25/html/
- Никита Липский, Владимир Иванов — JVM: краткий курс общей анатомии: #link("https://youtu.be/-fcj6EL9rc4?si=047kAa_C4yeACG59")[youtube]
  - Nikita Lipsky JVM Anatomy 101: #link("https://youtu.be/BeMi8K0AFAc?si=cvQs91sGtWWu3PNN")[youtube]
- Роман Артемьев — Java на Эльбрусе: #link("https://youtu.be/o429h0JoFGo?si=f151v4ftSZGaaZru")[youtube]
]]
