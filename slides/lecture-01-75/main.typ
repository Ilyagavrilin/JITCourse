#import "../../theme/common.typ": deck, code, code-file, note
#import "@preview/typslides:1.3.2": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
#show: codly-init.with()

#show: deck
#codly(display-icon: false, display-name: false, zebra-fill: black.transparentize(96%))
#front-slide(
  title: "JIT-compilers basics",
  subtitle: [Механизмы взаимодействия с JVM],
  authors: "Ilya Gavrilin, Syntacore",
  info: [MIPT, 2026],
)

#slide(title:"Закрываю неточности")[#align(top)[
- Срок сдачи заданий:
  - полный балл - 1 месяц с дня получения
  - половина баллов - до конца курса
- Репозиторий с кодом и слайдами: ...

- Расширяем тесты с прошлого занятия:
  - Как справится JIT если в массиве из одинаковых чисел будет выброс?
  - Посмотрим на `Math.sin` и `StrictMath.sin` при:
    - 1 случайном значении и 2047 фиксированных
    - 1024 случайных значений и 1024 фиксированных
#note[\*Положение случайных значение также случайное]
]]

#slide(title:"Закрываю неточности")[#align(top)[
- Расширяем тесты с прошлого занятия:
```text
Benchmark   (COUNT)  (SIZE)   Mode  Cnt    Score    Error   Units
javaMathSin        1   2048  thrpt   10   53.284 ±  0.725  ops/ms
javaMathSinMixed   1   2048  thrpt   10   87.851 ±  4.261  ops/ms
javaMathSinMixed 1024  2048  thrpt   10   65.495 ±  0.814  ops/ms
javaMathSinSame    1   2048  thrpt   10   89.846 ±  1.219  ops/ms

StrictMathSin      1    2048  thrpt   10    9.640 ±  0.565  ops/ms
StrictMathSinMixed 1    2048  thrpt   10  175.259 ±  6.762  ops/ms
StrictMathSinMixed 1024 2048  thrpt   10   19.708 ±  1.076  ops/ms
StrictMathSinSame  1    2048  thrpt   10  369.712 ±  5.086  ops/ms
```
]]

#slide(title: "Когда пропадает абстракция?")[#align(top)[
  - Как вы считаете, когда пора уходить от объектной модели?
  - Должны ли объекты доходить до уровня ISA процессора?
  #v(3em)
  #image("object_file.png")
  #note[Rekursiv: https://en.wikipedia.org/wiki/Rekursiv]
]]


#slide(title: "Когда пропадает абстракция?")[#align(top)[
  - Как вы считаете, когда пора уходить от объектной модели?
  - Должны ли объекты доходить до уровня ISA процессора?
  - Не стоит принимать инструкции, заменяющие последовательность с объектами:
  ```text
  LD4 (vector, single structure) (A64)
  Load single 4-element structure to one lane of four registers.

  LD4  {Vt.B, Vt2.B, Vt3.B, Vt4.B }[index], [Xn|SP] ; 8-bit
  ```
  #v(2em)
  - Мы так и не поговорили, что является исполняемым файлом в JVM
  #note[Rekursiv: https://en.wikipedia.org/wiki/Rekursiv]
]]




#slide(title: "Я многое не договаривал...")[#align(top)[
```java
package com.example.hello;

public class Main {
    public static void main(String[] args) {
        Greeter.sayHi();
    }
}

class Greeter {
    public static void sayHi() { System.out.println("Hi!"); }
}
```
- Посмотрим, как работает вся эта система классов
]]
#slide(title: "Всё таки он компилируемый")[#align(top)[
```c
ClassFile {
  // system info
  u2 interfaces_count;
  u2 interfaces[];
  u2 fields_count;
  field_info fields[];
  u2 methods_count;
  method_info methods[];
}
```

- строго бинарный формат
- classfile demo: https://javap.yawk.at/#p6GrZk

]]
#slide(title:"Пакеты в java")[#align(top)[

```text
project/
└─ src/
   └─ com/example/hello/
      └─ Main.java
```
#v(2em)

```bash
javac -d out src/com/*.java
java -cp out com.example.hello.Main
```
- `-cp out` - корень, относительно которого ищется `Main.class`
- JVM строит путь: `out/com/example/hello/Main.class`
- JAR - архив в котором находится приложение

]]

#slide(title: "Проблема bootstrap")[#align(top)[
- Нам бы хотелось использовать язык, который мы придумали, чтобы писать инструменты для него
- Почему бы не переписать всё на язык, который мы придумали?
- GraalVM Native Image: нативный код из Java\
 https://www.graalvm.org/latest/reference-manual/native-image/
 #v(3em)
#image("bootstrap.png")
]]
#slide(title: "Проблема bootstrap")[#align(top)[
- Нам бы хотелось использовать язык, который мы придумали, чтобы писать инструменты для него
- Почему бы не переписать всё на язык, который мы придумали?
- GraalVM Native Image: нативный код из Java\
 https://www.graalvm.org/latest/reference-manual/native-image/
 #v(2em)
- Не всегда можно портировать абсолютно всё: \
https://www.graalvm.org/latest/reference-manual/native-image/metadata/Compatibility/
]]
#slide(title:"Нативный лаунчер")[#align(top)[

- `java` — это нативный launcher
- Внутри него используется `libjli` (Java Launcher Interface)
- JLI создаёт JVM через JNI
```cpp
int main(int argc, char** argv)
  return JLI_Launch(
      argc, argv,              // аргументы из main()
      "21.0.1",                // VERSION_STRING
      "21",                    // DOT_VERSION
      "java",                  // имя программы
      "openjdk",               // имя launcher'а
      ...
  );
```
]]
#slide(title: "Metaspace — память классов")[
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
  #text(weight: "semibold", size: 24pt, )[#align(center)[Heap]]

  #rect(
    width: 100%,
    height: 120pt,
    inset: 10pt
  )[
    - объекты
    - можно попасть через new
  ]
  ],

  [
  #text(weight: "semibold", size: 24pt)[#align(center)[Metaspace]]

  #rect(
    width: 100%,
    height: 120pt,

    inset: 10pt
  )[
    - metadata классов
    - method info
    - runtime annotations
  ]
  ]
)

#v(1em)

- Вне heap
- Освобождается при GC ClassLoader
- Утечка loader → утечка Metaspace
]
#slide(title:"Промежуточные итоги")[#align(top)[

- ClassLoader - отвечает за загрузку классов в память и подготовку их к исполнению
- Bootstrap ClassLoader - для всего стандартного и точки входа в вашу программу
- Далее вы вольны писать их сами
#image("classloading.png")
#v(2em)
- *А как отличать загруженные классы?*

]]
#slide(title: "ClassLoader — изоляция и делегирование")[
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,

  [
  #text(weight: "semibold", size: 24pt)[Иерархия]

```
        Bootstrap
             │
         Platform
             │
         Application
             │
      ┌──────┴──────┐
   PluginA       PluginB
  ```

  ],

  [
  #text(weight: "semibold", size: 24pt)[Семантика типа]

  - Класс определяется парой:
    #text(weight: "semibold")[`(ClassLoader, ClassfileName)`]

  - Один и тот же `app.Greeter`:
    - разные loader -> разные типы

```java
loadA.loadClass("app.Greeter")
loadB.loadClass("app.Greeter")
```
  ]
)
]
#slide(title:"Промежуточные итоги")[#align(top)[

- classfile - способ платформонезависимо хранить информацию о java коде
- один classfile - один class, линковка - classloader
- classfile - содержит почти полную информацию о сохранённых в нём объектах

#v(2em)
- *А как нам может помочь эта информация?*

]]
#slide(title: "А что мы хотим знать о программе")[
#grid(
  columns: (1fr, 1fr),
  gutter: 3em,

  [
```c
struct {
    char* name;
    int age;
} User;

void printUser(User* u) {
 printf("name=%s age=%d\n",
        u->name, u->age);
}
```

  ],

  [
  #text(weight: "semibold")[Проблема]

  - Добавили поле = меняем функцию
  - Нет информации о структуре в runtime
  - Нет способа пройтись по полям автоматически

  #v(1em)

  #text(weight: "semibold")[
  Как это автоматизировать?
  ]
  ]
)
]
#slide(title: "Рефлексия")[
#align(left)[
#text(size: 24pt, weight: "semibold")[
Рефлексия — это способность программы получать,
анализировать и использовать метаинформацию
о собственной структуре.
]
]

#v(2em)

#grid(
  columns: (1fr, 1fr),
  gutter: 3em,

  [
  #text(size: 22pt, weight: "semibold")[Статическая]

  - Работает во время компиляции
  - Анализирует типы до запуска
  - Генерирует новый код
  - Не имеет runtime-стоимости

  ],

  [
  #text(size: 22pt, weight: "semibold")[Динамическая]

  - Работает во время выполнения
  - Использует метаданные типов
  - Позволяет создавать объекты по имени
  ]
)
]
#slide(title:"Статическая рефлексия в D")[#align(top)[
```D
struct User { string name; int age; }

string toString(T)(T obj) {
    string result;
    foreach (member; __traits(allMembers, T)) {
    static if (__traits(compiles, mixin("obj." ~ member))) {
      result ~= member ~ "=" ~ to!string(mixin("obj." ~ member))
      }
    }
    return result;
}
```
- godbolt: https://godbolt.org/z/Ev3djzj9Y
]]
#slide(title:"Динамическая рефлексия в Java")[#align(top)[


```java
Class<?> cls = Class.forName("app.User");

Object obj = cls.getDeclaredConstructor().newInstance();

for (var field : cls.getDeclaredFields()) {
    System.out.println(field.getName());
}```

- Загрузка класса по имени, доступ к полям


- Основано на объекте:
  `java.lang.Class`

- Реализация:
  https://github.com/openjdk/jdk/blob/master/src/java.base/share/classes/java/lang/Class.java

]]

#slide(title: "Стучимся к файлам")[#align(top)[
  ```java
    public static void main(String[] args) throws Exception {

        FileInputStream fis = new FileInputStream("Main.java");
        Field fdField = FileDescriptor.class.getDeclaredField("fd");
        fdField.setAccessible(true);
        int rawFd = fdField.getInt(fis.getFD());
    }

  ```
  - Иногда нам может понадобиться доступ к сырому файловому дескриптору
  - Но можно очень неприятно споткнуться...
]]
#slide(title: "Java Modules - это было странно")[
#text(size: 22pt, weight: "semibold")[module-info.java]

```java
module com.example.app {
    requires java.sql;
    requires com.example.lib;

    exports com.example.app.api;
}
```


- `module` — объявление модуля
- `requires` — зависимости
- `exports` — какие пакеты видны наружу
- Остальные пакеты скрыты по умолчанию

#v(1em)


]
#slide(title: "Всё таки он компилируемый")[#align(top)[
- Используем модули
  ```bash
java --module-path mods \
     --module com.example.app
```
- Тихо избавляемся от модулей
```sh
java --add-opens java.base/java.io=ALL-UNNAMED
```
]]
#slide(title: "Всё таки он компилируемый")[#align(top)[
- Используем модули
  ```bash
java --module-path mods \
     --module com.example.app
```
- Тихо избавляемся от модулей
```sh
java --add-opens java.base/java.io=ALL-UNNAMED
```
#v(2em)
- Мы многое умеем с объектами, но чего-то не хватает?
- Как бы вы реализовали отладку своего языка программирования?
]]
#slide(title: "JVMTI: фазы работы агента")[
#grid(
  columns: (1fr, 1fr),
  gutter: 3em,

  [
  #text(size: 22pt, weight: "semibold")[OnLoad phase]

  - Агент загружается вместе с JVM
  - VM ещё не полностью инициализирована
  - Можно запрашивать capabilities
  - Можно регистрировать callbacks
  - Можно перехватывать загрузку классов
  ],

  [
  #text(size: 22pt, weight: "semibold")[Live phase]

  - VM полностью запущена
  - Приложение выполняется
  - Доступ к потокам и heap
  - Инспекция стека
  - Установка breakpoint
  ]
)

#v(1.5em)

#align(center)[
#text(fill: gray)[Не все возможности доступны во всех фазах]
]
]
#slide(title: "Фичи JVMTI")[
#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 3em,

  [
  #text(size: 22pt, weight: "semibold")[Обязательные]

  - method / field info
  - thread info
  - get stack trace
  - force GC
  - get object size
  - raw monitors
  - add to classpath
  ],

  [
  #text(size: 22pt, weight: "semibold")[Capabilities
  #text(size: 16pt, fill: gray)[(в любой момент)]]

  - get bytecodes
  - get constant pool
  - tag objects
  - monitor events
  - GC events
  - redefine classes
  ],

  [
  #text(size: 22pt, weight: "semibold")[Capabilities
  #text(size: 16pt, fill: gray)[(только в OnLoad)]]

  - access local variables
  - exception events
  - method entry / exit
  - field access events
  - breakpoints
  ]
)
]
#slide(title: "JVMTI Agent: точки входа")[
#text(size: 22pt, weight: "semibold")[Загрузка при старте JVM]

```c
JNIEXPORT jint JNICALL
Agent_OnLoad(JavaVM* vm, char* options, void* reserved);
```

- Вызывается при `-agentpath:libagent.so`
- JVM ещё в ранней фазе


#text(size: 22pt, weight: "semibold")[Attach к уже работающей JVM]

```c
JNIEXPORT jint JNICALL
Agent_OnAttach(JavaVM* vm, char* options, void* reserved);
               ```

- Вызывается через Attach API
- JVM уже в Live phase
]

#slide(title: "Запрос Capabilities")[
```c
jvmtiCapabilities caps = {0};

caps.can_generate_method_entry_events = 1;
caps.can_access_local_variables = 1;
caps.can_tag_objects = 1;

(*jvmti)->AddCapabilities(jvmti, &caps);
```

- Без запроса capability функция работать не будет
- Некоторые capabilities доступны только в OnLoad
- Некоторые нельзя отменить
]
#slide(title: "Регистрация callbacks")[
```c
void JNICALL
MethodEntry(jvmtiEnv* jvmti,
            JNIEnv* env,
            jthread thread,
            jmethodID method) {}
jvmtiEventCallbacks callbacks = {0};
callbacks.MethodEntry = &MethodEntry;
(*jvmti)->SetEventCallbacks(
    jvmti,
    &callbacks,
    sizeof(callbacks));
    ```
]
#slide(title: "Небольшие выводы")[#align(top)[
  - JVM хранит в себе очень много информации о загруженных объектах
  - Мы можем доступаться до них разными способами: как из java так и из native
  - Почти любой переход в нативный код и из нативного кода - JNI
  - Работать с интерфейсами JVM надо крайне аккуратно, ровно как и следить, кто ими пользуется в ваших VM
  #v(2em)
  - *Задач на дом не будет!*
]]
#slide(title: "Список литературы")[#align(top)[
  - JVM SE specification: \ https://docs.oracle.com/javase/specs/jvms/se25/html/
  - JVMTI specification 25: \ https://docs.oracle.com/en/java/javase/25/docs/specs/jvmti.html
  - Андрей Паньгин — JVM TI как сделать «плагин» для виртуальной машины #link("https://youtu.be/aiuKiE5-0g4?si=77KkTsib2PuaZ58D")[youtube]
  - Project Panama: Interconnecting the Java Virtual Machine and Native Code #link("https://youtu.be/M57l4DMcADg?si=4MxjPv2u56nUrQgy")[youtube]
]]
