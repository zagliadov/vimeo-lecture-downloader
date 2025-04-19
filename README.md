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

## Использование

### Скачивание видео из iframe (рекомендуемый способ)

1. Создайте файл `iframe.html` и вставьте в него HTML-код iframe:
```html
<iframe id="lect0101" src="https://player.vimeo.com/video/1038888708#t=0m0s?title=0&amp;byline=0&amp;portrait=0" style="position:absolute;top:0;left:0;width:100%;height:100%;" allow="autoplay; fullscreen" allowfullscreen="" frameborder="0"></iframe>
```

2. Замените `src` на реальный src видео из Vimeo 

3. Запустите скрипт:
```bash
./download_videos.sh iframe.html
```

### Скачивание видео по прямому URL

Для некоторых видео Vimeo требуется указать URL страницы, на которой встроено видео. В этом случае используйте команду:

```bash
./download_videos.sh "https://player.vimeo.com/video/ID_ВИДЕО#t=0m0s?title=0&byline=0&portrait=0" "https://online.cnmstudent.com/course/view.php?id=108"
```

Где второй параметр - это URL страницы курса, на которой встроено видео.

## Где найти ID видео

1. Откройте страницу с видео в браузере
2. Найдите iframe с видео
3. В атрибуте `src` найдите часть `video/ЧИСЛО` - это и есть ID видео
4. Скопируйте этот ID и вставьте его в шаблон iframe

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
