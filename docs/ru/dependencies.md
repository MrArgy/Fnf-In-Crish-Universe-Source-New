# Инструменты и зависимости

[English](../en/dependencies.md) · **Русский** · [Документация](index.md)

Ниже перечислены версии из среды разработки, сверенные с метаданными библиотек и [libs.xml](../../libs.xml). Это исходная конфигурация для сборки, а не гарантия совместимости с любой более новой версией.

## Общие инструменты

- **Haxe 4.3.6**, подтверждённый командой `haxe --version`. Унаследованный установщик и CI ссылаются на 4.2.5; локальные проверки ICU из этой документации выполнялись с другой версией.
- **Haxelib** и **Neko**, доступные в `PATH`. Отдельная проверенная версия Neko не зафиксирована.
- **Git** в `PATH` для форков библиотек и их submodules.
- Для нативной Windows-сборки также нужны инструменты MSVC C++ и Windows SDK. См. [Windows](build-windows.md).
- Android-скрипт работает в Windows PowerShell и требует Java и Android tools. См. [Android](build-android.md).

## Версии библиотек

| Библиотека | Обнаруженная версия | Выбор в `libs.xml` |
| --- | --- | --- |
| `openfl` | 9.2.2 | Фиксированная версия |
| `lime` | 8.1.2 | Фиксированная версия |
| `hxvlc` | 1.9.3 | Фиксированная версия, установка зависимостей пропущена |
| `hxcpp` | Windows: 4.3.2; Android: 4.3.175 | Явно не закреплён; Android-скрипт отдельно требует 4.3.175 |
| `flixel` | Метаданные форка: 5.3.0 | Git-форк CodenameCrew |
| `flixel-addons` | Метаданные форка: 3.0.2 | Git-форк CodenameCrew |
| `flxanimate` | Метаданные форка: 3.0.4 | Git-форк CodenameCrew |
| `hscript-improved` | Метаданные форка: 2.4.0 | Git-форк CodenameCrew, ref `custom-classes` |
| `hxdiscord_rpc` | Метаданные форка: 1.1.2 | Git-форк CodenameCrew; в этом проекте только desktop C++ |
| `away3d` | Метаданные форка: 5.1.0 | Git-форк CodenameCrew |
| `format` | 3.8.0 | Версия не указана |
| `markdown` | 1.1.3 | Версия не указана |
| `nape-haxe4` | 2.0.22 | Версия не указана |

Не заменяйте форки CodenameCrew обычными пакетами Haxelib с похожими номерами. Версия в метаданных форка не определяет его код однозначно.

## Подготовка проекта

Скачайте или клонируйте весь репозиторий, включая `source/`, `assets/`, `art/`, `mods/`, `commandline/`, `tools/`, `project.xml` и `libs.xml`. Откройте PowerShell в корне. Подойдёт любой каталог с правом записи; конкретный диск или структура пользовательских папок не требуются.

```powershell
haxe --version
neko -version
git --version
.\update.bat
haxelib install hxcpp 4.3.2
haxelib set hxcpp 4.3.2
haxelib install format 3.8.0
haxelib set format 3.8.0
haxelib install markdown 1.1.3
haxelib set markdown 1.1.3
haxelib install nape-haxe4 2.0.22
haxelib set nape-haxe4 2.0.22
haxelib list
```

`update.bat` запускает `haxe -cp commandline -D analyzer-optimize --run Main setup`. Команда создаёт локальную `.haxelib/` и устанавливает/обновляет записи из `libs.xml`; это не проверка без изменений. Нужен доступ к сети. Проверяйте результат для каждой библиотеки: установщик не останавливается при каждой ошибке дочерней команды. Не запускайте его параллельно со сборкой.

## Git-ревизии и воспроизводимость

В `libs.xml` Git-коммиты не закреплены, а у части пакетов не заданы версии. У локальных библиотек обнаружены следующие HEAD:

| Библиотека | HEAD |
| --- | --- |
| `flixel` | `53bb0d57632a26d6e0eed6dc2ce2cf7b55d91f4e` |
| `flixel-addons` | `5279c743824d4775eb7c916e266e6e682678c4e5` |
| `flxanimate` | `83663e8a2520cc1505ae4c2de7c5d330c8ae628a` |
| `hscript-improved` | `49c90e643439b85043f51ce200fb034b5b08da13` |
| `hxdiscord_rpc` | `aa0edf55115c0cb7222a973af82a39c785c7103e` |
| `away3d` | `04c6696dd5d00fc8557097f8a2b3e8fc02a02185` |

После свежей установки зависимостей этот набор выбирается командами:

```powershell
git -C .haxelib/flixel/git checkout --detach 53bb0d57632a26d6e0eed6dc2ce2cf7b55d91f4e
git -C .haxelib/flixel-addons/git checkout --detach 5279c743824d4775eb7c916e266e6e682678c4e5
git -C .haxelib/flxanimate/git checkout --detach 83663e8a2520cc1505ae4c2de7c5d330c8ae628a
git -C .haxelib/hscript-improved/git checkout --detach 49c90e643439b85043f51ce200fb034b5b08da13
git -C .haxelib/hxdiscord_rpc/git checkout --detach aa0edf55115c0cb7222a973af82a39c785c7103e
git -C .haxelib/away3d/git checkout --detach 04c6696dd5d00fc8557097f8a2b3e8fc02a02185
git -C .haxelib/hxdiscord_rpc/git submodule update --init --recursive
```

Хеши прочитаны из существующих каталогов; свежая сетевая установка на этих ревизиях в рамках оформления документации не проверялась. Они не доказывают отсутствие локальных изменений каждого файла библиотеки и не заменяют полный lock-файл. Если Git не может получить ревизию, зафиксируйте ошибку вместо молчаливой замены на более новую. Повторный `update.bat` может изменить выбранные Git-версии.
