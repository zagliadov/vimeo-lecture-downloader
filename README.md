# Vimeo Course Downloader

Скрипт для скачивания видео с Vimeo, встроенных в платформу Moodle/CNM Student.

## Установка

1. Убедитесь, что у вас установлен Homebrew:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Установите зависимости:
```bash
brew install yt-dlp jq curl grep
```

3. Сделайте скрипт исполняемым:
```bash
chmod +x download_videos.sh
```

## Как получить URL видео

### Способ 1: Через iframe (рекомендуемый)

1. Откройте страницу с видео в браузере
2. Нажмите правой кнопкой мыши на видео и выберите "Просмотреть код" (или нажмите F12)
3. Найдите тег `<iframe>` в HTML-коде
4. Скопируйте значение атрибута `src` из iframe
5. Создайте файл `iframe.html` и вставьте в него HTML-код iframe:
```html
<iframe id="lect0101" src="https://player.vimeo.com/video/1038888708#t=0m0s?title=0&amp;byline=0&amp;portrait=0" style="position:absolute;top:0;left:0;width:100%;height:100%;" allow="autoplay; fullscreen" allowfullscreen="" frameborder="0"></iframe>
```

### Способ 2: Через прямую ссылку

1. Откройте страницу с видео в браузере
2. Нажмите правой кнопкой мыши на видео и выберите "Просмотреть код" (или нажмите F12)
3. Найдите тег `<iframe>` в HTML-коде
4. Скопируйте значение атрибута `src` из iframe
5. URL будет выглядеть примерно так:
```
https://player.vimeo.com/video/1038888708#t=0m0s?title=0&byline=0&portrait=0
```

## Использование

### Скачивание видео из iframe (рекомендуемый способ)

1. Создайте файл `iframe.html` и вставьте в него HTML-код iframe (см. выше)
2. Запустите скрипт:
```bash
./download_videos.sh iframe.html
```

### Скачивание видео по прямому URL

Для скачивания видео по прямой ссылке вам понадобится два URL:
1. URL видео (из атрибута src iframe)
2. URL страницы курса, на которой встроено видео

Пример команды:
```bash
./download_videos.sh "https://player.vimeo.com/video/1038888708#t=0m0s?title=0&byline=0&portrait=0" "https://online.cnmstudent.com/course/view.php?id=108"
```

Где:
- Первый параметр - URL видео из iframe
- Второй параметр - URL страницы курса, на которой встроено видео

## Где найти URL страницы курса

1. Откройте страницу с видео в браузере
2. Скопируйте URL из адресной строки браузера
3. URL должен выглядеть примерно так:
```
https://online.cnmstudent.com/course/view.php?id=108
```

## Особенности

- Скрипт автоматически создает директорию `downloads` для сохранения видео
- Видео скачиваются в наилучшем доступном качестве
- Поддерживается скачивание субтитров (если доступны)
- Автоматически извлекается URL из iframe
- Используются cookies из браузера для авторизации
- Для некоторых видео требуется указать URL страницы встраивания

## Примеры

### Пример iframe для скачивания
```html
<iframe id="lect0101" src="https://player.vimeo.com/video/1038888708#t=0m0s?title=0&amp;byline=0&amp;portrait=0" style="position:absolute;top:0;left:0;width:100%;height:100%;" allow="autoplay; fullscreen" allowfullscreen="" frameborder="0"></iframe>
```

### Примеры команд
```bash
# Скачать видео из iframe (рекомендуемый способ)
./download_videos.sh iframe.html

# Скачать видео по прямому URL с указанием страницы встраивания
./download_videos.sh "https://player.vimeo.com/video/1038888708#t=0m0s?title=0&byline=0&portrait=0" "https://online.cnmstudent.com/course/view.php?id=108"
```

## Примечания

- Убедитесь, что вы авторизованы в браузере Chrome перед запуском скрипта
- Видео сохраняются в директории `downloads` с оригинальными названиями
- Если видео защищено, убедитесь, что у вас есть доступ к нему через браузер
- Для некоторых видео требуется указать URL страницы, на которой встроено видео
- Рекомендуется использовать способ с iframe, так как он автоматически определяет все необходимые параметры
